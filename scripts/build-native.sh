#!/usr/bin/env bash
# 构建内嵌 tailnet 引擎（libtailnet.so）→ android/app/src/main/jniLibs/<abi>/
#
# 用法: scripts/build-native.sh [arm64-v8a|x86_64|all]   （缺省 all）
# 依赖: Go（GO 可覆盖，默认 ~/go-sdk/bin/go）+ Android NDK（ANDROID_NDK_HOME 或 ~/android-sdk/ndk/*）
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/native/tailnet"
OUT="$ROOT/android/app/src/main/jniLibs"

# Go 解析（WP-9 修）：显式 GO > PATH 里的 go（CI actions/setup-go）> 本地 SDK 目录
# 注意：原实现默认写死 $HOME/go-sdk/bin/go（本地 WSL 布局）——CI 里 setup-go 只把 go 放进
# PATH，于是 tag 触发的 APK 构建一直在"未找到 go"处失败（App 仓库此前无任何 Release）。
GO="${GO:-}"
if [ -z "$GO" ]; then
  if command -v go >/dev/null 2>&1; then
    GO="$(command -v go)"
  elif [ -x "$HOME/go-sdk/bin/go" ]; then
    GO="$HOME/go-sdk/bin/go"
  else
    echo "未找到 go（设置 GO=<path>）" >&2; exit 1
  fi
fi
echo "使用 go：$GO（$("$GO" version 2>/dev/null || echo '?'）)"
# go.mod 声明的 toolchain（tailscale 依赖要求 ≥1.27.1）；auto 会用本地缓存或自动下载
export GOTOOLCHAIN="${GOTOOLCHAIN:-auto}"
export GOFLAGS="${GOFLAGS:--mod=mod}"

NDK="${ANDROID_NDK_HOME:-}"
if [ -z "$NDK" ]; then
	NDK="$(ls -d "$HOME"/android-sdk/ndk/* 2>/dev/null | sort -V | tail -1 || true)"
fi
[ -n "$NDK" ] && [ -d "$NDK" ] || { echo "未找到 Android NDK（设置 ANDROID_NDK_HOME）" >&2; exit 1; }
TOOLCHAIN="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin"

TARGET="${1:-all}"
case "$TARGET" in
	arm64-v8a) ABIS=(arm64-v8a) ;;
	x86_64)    ABIS=(x86_64) ;;
	all)       ABIS=(arm64-v8a x86_64) ;;
	*) echo "未知 ABI: $TARGET（arm64-v8a|x86_64|all）" >&2; exit 1 ;;
esac

for abi in "${ABIS[@]}"; do
	case "$abi" in
		arm64-v8a) GOARCH=arm64; CC_BIN=aarch64-linux-android24-clang ;;
		x86_64)    GOARCH=amd64; CC_BIN=x86_64-linux-android24-clang ;;
	esac
	mkdir -p "$OUT/$abi"
	echo "==> $abi（GOARCH=$GOARCH）"
	(
		cd "$SRC"
		CGO_ENABLED=1 GOOS=android GOARCH="$GOARCH" CC="$TOOLCHAIN/$CC_BIN" \
			"$GO" build -buildmode=c-shared -trimpath -ldflags="-s -w" \
			-o "$OUT/$abi/libtailnet.so" ./csdk
	)
	rm -f "$OUT/$abi/libtailnet.h"   # c-shared 会顺手出 .h；jniLibs 只留 .so
	ls -la "$OUT/$abi/libtailnet.so" | awk '{printf "    %s  %s\n", $5, $9}'
done
echo "==> 完成（jniLibs 已就位；flutter build apk 将自动打包）"
