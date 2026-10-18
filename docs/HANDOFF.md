# 交接说明（2026-10-19 第二轮；路由器 tab W6.9/W6.10 已落地）

**读者**：接手 WP-6 后续工作的新对话。
**先读**：`/home/nrxboat/WORKPLAN.md`（§1 快照 / §2 状态表 / §4 文件所有权）→
`docs/IA-V2-DISCUSSION.md`（IA v2 **定案 v1.0**：§13 决策记录、§14 配置面字段清单）→
`docs/W6.12-CELLULAR-DESIGN.md`（蜂窝域设计，已完成；同族机制范本）→ 本文件。
**前一轮交接**：`docs/W6.10-ROUTER-TAB-HANDOFF.md`（W6.10 后端契约与坑位，仍有效；其 §3 前端待办 1–6 已执行）。

---

## 1. 当前状态（已提交、**未推送**）

| 仓库 | 提交 | 内容 |
| :--- | :--- | :--- |
| QuartzWrt-Packages | `ed95016` → **`3b5b2a6`** | 蜂窝 `cellular` + app-api `qmodem.*` + 配置面 `config.*`（r8）；本轮：**`config.rollback`（r9）+ `luci.init_list/init_action/timezones` 转发条目** + DESIGN/验收脚本 |
| QuartzWrt-App | `ea8a097` → **`cc25739`** | 蜂窝 tab + **路由器 tab W6.9/W6.10**（首页/系统/启动项/接口/无线/DHCP·DNS）+ 配置面客户端/确认条 + 96 项测试 |
| QuartzWrt-ThirdParty | `9924cba` | qmodem `lang` 适配（**fork `quartz` 分支仍待推送**；推送前勿单独 `sync-mirrors.sh qmodem`） |
| QuartzWrt-Builder | `52d1227` | TDD §5 模式 A/B 实践判据 |

四仓工作树干净（本轮提交后），`git push` 等用户指令。App 版本 **v0.5.0（构建 6）**。

**本轮完成的能力**：
- **路由器 tab**：`/router`（旧 `/network` 深链重定向）；分组入口页（已实现页「可用」/未实现「待后续版本」chip）。
- **页面**：系统（hostname/描述/时区选择器/日志/串口登录）、启动项（`luci.getInitList`/`setInitAction`，启停/重启 + 危险确认）、接口（LAN/WAN，协议驱动字段可见性）、无线（device/iface 两段，敏感 key 掩码）、DHCP·DNS（dnsmasq + dhcp 节）。
- **配置安全网**：`config.read` → 本地编辑 → `config.write`（暂存）→ `config.apply{rollback:true,timeout:90}` → 90s 倒计时确认条（保留更改 / 立即回滚）。**立即回滚 = `config.rollback`**（见 §4 坑位 1）。
- **验收**：Flutter `analyze` 零告警、`test` **96 项全过**；Go 全仓测试全绿 + arm64/mipsle 交叉编译；VM 配置面 **17/17**、路由器后端 **15/15**；App e2e **23 项 ALL PASS**。

---

## 2. 下一步任务

### 2.1 W6.11：路由器 tab 剩余页面（按优先级）

| # | 项 | 需要补的后端 |
| :-- | :--- | :--- |
| 1 | 防火墙（zone/forward/rule/redirect） | `uciconf` 注册表扩 `firewall`；规则子表需 `config.add/delete` |
| 2 | 静态路由（route/rule） | 注册表扩 `network.route`/`network.rule` + `config.add/delete` |
| 3 | 静态租约（dhcp host） | `config.add/delete`（机制同 write；声明允许的 section 类型 + 字段） |
| 4 | 管理权（改密/SSH） | `luci.setPassword`（危险动作，需二次确认 + 审计）；SSH 字段走 `dropbear` 配置注册表 |
| 5 | 计划任务/挂载/LED | 注册表按节扩展；计划任务可能需要 `cron` 文件动作（非 UCI） |
| 6 | 时区/时间的系统级生效 | 目前写 `system.timezone/zonename` + apply；如真机发现时间未刷新，再补 `luci.setLocaltime`（已核实方法存在） |

字段清单提取方法见 `docs/IA-V2-DISCUSSION.md` §14（从 LuCI 定义提取；**按节完整注册**，不要散点键白名单）。

### 2.2 其它待办

- **`net.wan.ipv6` 契约加法**（WP-4）：daemon `netFast` 取首个公网 GUA（跳过 fe80::/ULA/临时），概览/网络卡展示（打码 + 点击展开）。
- **真机验收**（FNet3399）：路由器 tab 真数据（无线页真实 radio/iface、接口页真实 WAN 协议）；改 LAN IP 的「断开 → 自动回滚」路径；启动项启停；蜂窝真数据（信号/拨号/短信/AT）。
- **推送**：四仓 + qmodem fork `quartz` 分支（先推 fork 并打 tag `v3.4.0_rc3-quartz2`，再推 ThirdParty，否则镜像适配会被覆盖）。
- **W6.7 真机验收**（含远程客户端过 tailnet 防火墙链）。

---

## 3. 关键机制与坑（本轮新增/更新）

1. **`config.revert` ≠ 立即回滚（最重要）**：VM 实测 apply 后调 `uci revert` 不会撤销已生效配置，而且会解除回滚计时器（配置漂在生效态）。立即回滚必须调 **`config.rollback`**（app-api r9 新增，内部 `uci rollback` + 同会话）。App 的确认条已按此实现。
2. **`luci.*` 走 `action` 转发条目**：`luci.init_list`（无参）、`luci.init_action`（`{name, action}`，name 严格字符集 + 禁止 `..`，action 枚举 enable/disable/start/stop/restart）、`luci.timezones`（无参）。上游成功回 `{}`，错误回 `{"error":"…"}`；`init_action` 的 `name` 会进入 init 调用，**不得放宽字符集**。
3. **配置面会话**：uci 写入/apply/confirm/rollback 必须同一条 `ubus_rpc_session`；app-api 每次调用是新进程 → sid 在 login 时开启并持久化（12h），logout/revoke 销毁。`session create` 是空 ACL，只有 `session login` 可用。
4. **apply 是 rpcd 全局单例**：同一时刻只能有一处挂起 apply；网页端有未确认更改时 App apply 会失败（提示「网页端有未确认的更改」）。App 侧已有串行确认条；不要并发调用。
5. **`config.read` 的三种 `value` 形状**：全量 `{section:{option:value}}` / 单节 `{option:value}` / 单选项标量；`uci get` 带 option 的 rpcd 原始形态是 `{"value":[…]}`，服务端已解包。无参 uci 方法传 `{}`，传 `null` 会解析失败。
6. **敏感字段**：`wireless.@wifi-iface[].key`、`network.wan.password` 读面为 `__masked__`；**未修改则不要发该字段**（回写掩码会被 `bad_request` 拒绝，这是有意的）。App 的 `ConfigDraft` 已处理「留空 = 保持」。
7. **新方法三处登记**（漏一处即 `-32002`/方法不存在）：`cmd/quartz-app-api/main.go` 的 `methodList()`、`files/acl.d/quartz-app-api.json`、分发 `switch`。本轮 `config.rollback` 已登记。
8. **方法面断言**：`cmd/quartz-app-api/main_test.go` 的 `TestMethodListSurface` 之前仍写死 9 个方法（配置面加入后必然失败）；本轮已扩到 16 并显式列出。以后加方法记得同步。
9. **VM 工具链**：包级编译 `make package/quartz-app-api/{clean,compile}`（runtime 包 r9）；推包 `python3 -m http.server <port> --bind 127.0.0.1 --directory bin/packages/x86_64/quartz` + VM 内 `wget http://192.168.1.2:<port>/…` + `apk add --allow-untrusted`；**同版本 apk 不会升级**，改代码必须 bump `PKG_RELEASE`；`killall -HUP rpcd` 后有重载窗口，登录脚本要重试。
10. **`vm-ssh.py` 输出带 CR**：整数/字符串比较前 `tr -d '\r\n'`；多行输出会被拼接。
11. **VM 无无线硬件/无模组**：无线页只能验空态；接口页有真实 lan/wan；蜂窝真数据只能上 FNet3399。
12. **App 路由兼容**：旧 `/network`、`/network/clients` 已重定向到 `/router`、`/router/clients`；新增页面都走 `/router/*`。
13. **不要并行打开两个配置页**：apply 全局单例 + 90s 确认条是页面级 modal；即使技术上能堆栈，也会互相抢 apply。W6.11 如需跨页保存，先做全局 apply 协调器。

---

## 4. 测试与验收命令

```bash
# Go：单测 + 交叉编译
cd QuartzWrt-Packages/utils/quartz-app-api/src
~/go-sdk/bin/go test ./...
~/go-sdk/bin/gofmt -l .
GOOS=linux GOARCH=arm64 ~/go-sdk/bin/go build ./...
GOOS=linux GOARCH=mipsle ~/go-sdk/bin/go build ./...

# App：静态分析 + 全量测试
cd QuartzWrt-App
export PATH="$HOME/flutter-sdk/flutter/bin:$PATH"
flutter analyze
flutter test                 # 96 项

# 包级编译（构建树对 quartz feed 是 src-link）
cd /home/nrxboat/quartzwrt/build/immortalwrt
make package/quartz-app-api/{clean,compile}
# 产物 bin/packages/x86_64/quartz/quartz-app-api-0.1.0-r9.apk

# 推入 VM（宿主 HTTP + slirp 别名）
(cd bin/packages/x86_64/quartz && python3 -m http.server 8892 --bind 127.0.0.1 &)
python3 ../../QuartzWrt-Packages/utils/quartz-daemon/dev/vm-ssh.py \
  'cd /tmp && wget -q http://192.168.1.2:8892/quartz-app-api-0.1.0-r9.apk -O q.apk && apk add --allow-untrusted q.apk && killall -HUP rpcd'

# VM 验收
cd QuartzWrt-Packages/utils/quartz-app-api/dev
bash vm-accept-config.sh     # 17/17
bash vm-accept-router.sh     # 15/15（luci + config.rollback）

# App e2e（对真固件/VM）
cd QuartzWrt-App && dart run tool/e2e_vm.dart   # 23 项 ALL PASS
```

**环境事实**：VM 由 `QuartzWrt-Builder/scripts/test-in-vm.sh --detach` 起，宿主转发 `8080→80 / 2222→22 / 8443→443`，root 密码 `quartz`；构建树 `/home/nrxboat/quartzwrt/build/immortalwrt`。

---

## 5. 交付门槛（沿用）

1. Go：`go test ./...` 全绿、`gofmt -l` 干净、arm64/mipsle 交叉编译通过。
2. App：`flutter analyze` 零告警 + `flutter test` 全绿 + `dart run tool/e2e_vm.dart` ALL PASS。
3. 配置面改动：VM 跑 `vm-accept-config.sh` + `vm-accept-router.sh`，**改动必须现场复原**（`description` 等无害字段）。
4. 真机（带无线/模组）是无线/蜂窝真数据的唯一门槛（FNet3399）。

## 6. 协作约定

- 提交信息 `WP-N: 简述`；WORKPLAN §2 状态表与 §1 快照**必须回写**；跨 WP 改文件要在 §4 登记并通知。
- 不推送除非用户明确说；不主动 commit 到别人的仓库分支。
- 文档同步：契约改动 → `AGGREGATE-API.md`（§3.x + 变更记录）；app-api 方法/机制 → `utils/quartz-app-api/docs/DESIGN.md`；界面结构 → `docs/UI-DESIGN.md`；本轮已完成 app-api DESIGN §5.2 与 UI-DESIGN v1.4 回写。
