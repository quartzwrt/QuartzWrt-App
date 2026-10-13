#!/usr/bin/env bash
# 一键 E2E：mock 路由器（LAN + tailnet 双监听）→ 宿主客户端（生产引擎 → 本地代理 → tailnet）。
#
# 控制面（二选一）：
#   ① 真 tailnet（推荐）：export TS_AUTHKEY=tskey-auth-...（可复用 key；两个节点各注册一台设备）
#   ② 本地 headscale：export HS_BIN=/path/headscale HS_DIR=~/hs（脚本会建用户/发 key）
# 用法: native/tailnet/e2e/run-local-e2e.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
LOG=/tmp/qt-e2e-logs
BIN=/tmp/qt-e2e-bin
mkdir -p "$LOG" "$BIN"

PIDS=()
cleanup() { for p in "${PIDS[@]:-}"; do kill "$p" 2>/dev/null || true; done; }
trap cleanup EXIT

# 预编译（直接跑二进制：kill 能命中真进程；go run 的子进程杀不干净）
(cd "$ROOT/native/tailnet" && go build -o "$BIN/mockrouter" ./e2e/mockrouter && go build -o "$BIN/e2eclient" ./e2e/client)

CTRL_ARGS=()
KEY_MOCK="${TS_AUTHKEY:-}"
KEY_CLIENT="${TS_AUTHKEY:-}"

if [ -n "${HS_BIN:-}" ]; then
	HS_DIR="${HS_DIR:-$HOME/qs-e2e/hs}"
	HOST_IP="${HOST_IP:-$(ip -4 addr show eth0 | awk '/inet /{print $2}' | cut -d/ -f1 | head -1)}"
	CTRL="http://$HOST_IP:8080"
	CTRL_ARGS=(-control "$CTRL")
	echo "==> headscale（$CTRL）"
	"$HS_BIN" serve --config "$HS_DIR/config.yaml" >"$LOG/headscale.log" 2>&1 &
	PIDS+=($!)
	for i in $(seq 1 30); do curl -sf "$CTRL/health" >/dev/null 2>&1 && break; sleep 1; done
	curl -sf "$CTRL/health" >/dev/null || { echo "headscale 未就绪" >&2; tail -20 "$LOG/headscale.log"; exit 1; }
	"$HS_BIN" users create quartz --config "$HS_DIR/config.yaml" >/dev/null 2>&1 || true
	KEY_MOCK=$("$HS_BIN" preauthkeys create --user 1 --expiration 1h --config "$HS_DIR/config.yaml" | tail -1)
	KEY_CLIENT=$("$HS_BIN" preauthkeys create --user 1 --expiration 1h --config "$HS_DIR/config.yaml" | tail -1)
elif [ -n "$KEY_MOCK" ]; then
	echo "==> 真 tailnet（官方控制面；auth key 仅经环境变量传递，不入 argv/仓库）"
else
	echo "需要 TS_AUTHKEY（或 HS_BIN 走本地 headscale）" >&2
	exit 1
fi

echo "==> mock 路由器（LAN :4450 + tailnet :443）"
TS_AUTHKEY="$KEY_MOCK" "$BIN/mockrouter" ${CTRL_ARGS[@]+"${CTRL_ARGS[@]}"} -lan "0.0.0.0:4450" -dir /tmp/qt-mock-router >"$LOG/mock.log" 2>&1 &
PIDS+=($!)
for i in $(seq 1 90); do grep -aq MOCK_READY "$LOG/mock.log" && break; sleep 1; done
grep -aq MOCK_READY "$LOG/mock.log" || { echo "mock 未就绪：$LOG/mock.log" >&2; tail -25 "$LOG/mock.log"; exit 1; }
MOCK_IP=$(grep -ao 'tailnet_ip=[0-9.]*' "$LOG/mock.log" | head -1 | cut -d= -f2)
echo "    mock tailnet IP = $MOCK_IP（LAN :4450 供模拟器配对）"

echo "==> 宿主客户端（生产引擎 → 代理 → tailnet → mock）"
CLIENT_DIR=/tmp/qt-e2e-client
# 默认复用节点身份（避免每次跑注册新设备）；QT_E2E_FRESH=1 时重建
if [ "${QT_E2E_FRESH:-}" = "1" ]; then rm -rf "$CLIENT_DIR"; fi
mkdir -p "$CLIENT_DIR"
if [ -n "${HS_BIN:-}" ]; then
	printf '{"control_url":"%s","auth_key":"%s"}\n' "$CTRL" "$KEY_CLIENT" >"$CLIENT_DIR/config.json"
else
	printf '{"auth_key":"%s"}\n' "$KEY_CLIENT" >"$CLIENT_DIR/config.json"
fi
"$BIN/e2eclient" -dir "$CLIENT_DIR" -target "$MOCK_IP"
echo "==> 完成（logs: $LOG/）"
