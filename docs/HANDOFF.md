# 交接说明（2026-10-19；下一轮：App「路由器 tab」前端）

**读者**：接手 WP-6 后续工作的新对话。
**先读**：`/home/nrxboat/WORKPLAN.md`（§1 快照 / §2 状态表 / §4 文件所有权）、
`docs/IA-V2-DISCUSSION.md`（IA v2 **定案 v1.0**：§13 决策记录、§14 配置面字段清单试点）、
`docs/W6.12-CELLULAR-DESIGN.md`（蜂窝轮设计 v1.4）。本文件只写"现在到哪了 / 下一步怎么接"。

---

## 1. 当前状态（已提交、**未推送**）

| 仓库 | 提交 | 内容 |
| :--- | :--- | :--- |
| QuartzWrt-Packages | `ed95016` | daemon `cellular` 节（r4）+ app-api `qmodem.*` 转发条目 + **配置面 `config.*`（r8）** + 契约 §3.9 / 两份 DESIGN |
| QuartzWrt-App | `ea8a097` | 蜂窝 tab W6.12–W6.14 + IA v2 定案稿/设计稿/预览 + e2e 与 89 项测试 |
| QuartzWrt-ThirdParty | `9924cba` | qmodem 镜像 `lang` 适配（**fork 待推送**） |
| QuartzWrt-Builder | `52d1227` | TDD §5 模式 A/B 实践判据 |

四仓工作树干净；`git push` 等用户指令（ThirdParty 推送前先把 fork 的 `quartz` 分支推了并打 `v3.4.0_rc3-quartz2`，否则下次 `sync-mirrors.sh qmodem` 会覆盖镜像适配）。

**已完成的能力**：
- **蜂窝域全链路**：daemon 慢车道节（10s，qmodem 读方法）→ app-api 转发条目（写 15/读 14，含短信独立对象 `qmodem.sms`）→ App 蜂窝 tab（首页/网络配置/SIM/短信/AT 调试/高级/拨号日志，6 格入口全通）。
- **配置面底座**：app-api `config.read/write/changes/revert/apply/confirm`（`internal/uciconf`），**试点注册表**覆盖 `network.lan/wan`、`wireless`（device+iface）、`dhcp`（dnsmasq+dhcp）、`system`；敏感字段读面掩码；apply+rollback 安全网。
- **VM 验收**：蜂窝 `vm-accept-cellular.sh` **18/18**；配置面 `vm-accept-config.sh` **17/17**（含 apply→生效→10s 未确认自动回滚→confirm→现场复原）；App e2e 对真固件 **19 项 ALL PASS**。

**当前 App 的一个"半态"（重要）**：`lib/features/shell/shell.dart` 的第二个 tab **标签已改成「路由器」**（用 `l10n.navRouter`），但页面仍是旧的 `NetworkPage`（WAN/无线汇总/上网设备/网络服务），路由仍是 `/network`。下一轮要把它替换成 IA v2 的「路由器 tab」。

---

## 2. 下一步任务：App「路由器 tab」前端（W6.9–W6.11）

目标（IA v2 定案）：tab = **路由器侧全量入口**（网页端 Network + System），分组 → 列表 → 页面；配置写入走 `config.*`，**必须**配「apply + 90s 倒计时确认」安全网。

### 2.1 建议顺序（每步可独立验收）

1. **路由器首页（W6.9）**：分组入口列表（网络：接口/无线/DHCP 与 DNS/静态路由；安全：防火墙；系统：系统/管理权/启动项；局域网：上网设备）；每行 chip 标实现档位（原生/通用表单/只读/分轮）。设计参照 `design/ia-v2-preview.html` 第 ① 屏。
2. **启动项页（W6.9，最便宜）**：数据/动作在 rpcd `luci` 对象（`getInitList` / `setInitAction`）——**需先在 app-api `ubusfwd` 加条目**（object `luci`，方法与参数见 VM：`ubus -v list luci`）。
3. **系统页（W6.10）**：`config.read/write system`（hostname/description/timezone/zonename/log_* 已在注册表）；保存流程 = write → apply(rollback,90) → 倒计时条 → confirm / 回滚。
4. **接口页（W6.10）**：`network.lan/wan`（proto/静态/DHCP/PPPoE 字段已注册）；改 LAN IP 类字段必须弹「本机将断开」+ 回滚确认。
5. **无线页（W6.10）**：`wireless` device+iface（ssid/加密/key/信道/功率…已注册）；**读到的 key 是掩码 `__masked__`，未修改时不要回写**（回写掩码会被拒，这是有意的）。
6. **DHCP·DNS（W6.10/11）**：`dhcp.@dnsmasq/@dhcp` 已注册；**静态租约（host）需要 `config.add/delete`，机制尚未实现**（见 §3 待补）。
7. **防火墙/路由/管理权/计划任务/挂载/LED（W6.11）**：需扩注册表（字段清单提取方法见 IA v2 §14；防火墙 zone/rule/redirect 是最大一块）。
8. **`net.wan.ipv6`**：契约加法 + daemon `netFast` 取首个公网 GUA（跳过 fe80::/ULA/临时）+ 概览/网络卡展示（打码 + 点击展开）。

### 2.2 App 侧需要的通用机制

- **表单控件**：值/枚举/布尔/列表四类（与注册表 `kStr/kEnum/kBool/kUint/kIPList/kList` 对应）；建议一个 `ConfigField` widget + 页面描述表。
- **应用流程**：`config.write` 多个字段 → `config.apply{rollback:true,timeout:90}` → 显示倒计时确认条（复用 `showConfirmSheet` 的视觉，但常驻）→ `config.confirm` 或 `config.revert`；断线重连后优先尝试 `confirm`。
- **危险分级**：改 LAN IP / 无线 key / 防火墙 / DHCP 范围 = 危险（回滚确认 + 「本机可能失联」文案）。
- **l10n**：新增文案走 `lib/l10n/app_*.arb` + `flutter gen-l10n`（纪律：用户可见文案全量本地化）。

### 2.3 app-api 需补的条目（下一轮先做，约 1–2 小时）

- `luci.*` 转发条目（启动项/时区/改密）：对象 `luci`，方法 `getInitList` / `setInitAction`（`{name,action}`）/ `getTimezones` / `setLocaltime{localtime}` / `setPassword{username,password}`（**危险**）。
- `config.add` / `config.delete`（静态租约、防火墙规则必需）：按注册表声明「允许的 section 类型 + 字段」，机制同 `config.write`。
- 可选：`config.read` 支持一次读多配置（减少往返）。

---

## 3. 已知事实与坑（下次别再踩）

### 3.1 机制（VM 实测）

- **rpcd `/ubus` 用扁平参数形态** `[sid, object, method, args]`；嵌套 `[sid,"call",{…}]` 会得 `-32700 Parse error`。
- **uci 写入/apply/confirm 必须同一条 `ubus_rpc_session`**；`session create` 得到**空 ACL** 会话（写 uci 被拒）；只有 `session login`（管理员凭据）的会话有全量 ACL。
- app-api 是 **rpcd exec 插件，每次调用都是新进程** → 配置会话 sid **必须持久化**（已落在 `store.Device.ConfigSID/ConfigSIDExp`，login 时开启、logout/revoke 销毁）。
- `uci get` **带 `option`** 返回 `{"value":["<v>"]}`（数组包装，未设置空数组）；**不带 option** 返回 `{"values":{…}}`。
- `uci apply{rollback:true,timeout}` 后未 `confirm` → 到点自动回滚（VM 实测 5s/10s 窗口均生效）。
- **无参 uci 方法要传 `{}`**，传 `null` 会被 rpcd 判 "Parsing message data failed"。
- **新方法要登记三处**，漏一处就是 `-32002`/方法不存在：① `methodList()`（`cmd/quartz-app-api/main.go`）② `files/acl.d/quartz-app-api.json` ③ 分发 `switch`。

### 3.2 qmodem 上游（读源码核实）

- `dial_status` 返回**字符串** `"true"/"false"`；generic 桩恒回 `get_stats.available=0`、`supportSwitch="0"`（按能力门控，别把 0 当数据）。
- `set_mode` = **USB 拨号模式**（qmi/ecm/mbim/rndis/ncm），**不是**网络模式；`set_network_prefer` 收**数组**；`get_lockband` 是 `{band_class, lock_band}` 方言。
- **短信页数据源是独立对象 `qmodem.sms`**（`list/send/delete/mark_read/sync/storage_get/set`，结构化消息），不是 `qmodem.get_sms`（tom_modem 原始输出）；该对象模组参数名是 **`modem_id`**（app-api 条目用 `sectionKey` 声明）。
- 速率单位：`MB/s` = 字节、`Mbps` = 比特（按大小写区分，跨 8 倍）。

### 3.3 VM 验收工具链

- 构建树 `/home/nrxboat/quartzwrt/build/immortalwrt`：quartz feed 是 **`src-link` 指向本地 Packages**；thirdparty 锁旧提交。
- 包级编译：`make package/<包>/clean && make -j16 package/<包>/compile`（结果在 `bin/packages/x86_64/quartz/`）。
- 推包：宿主 `python3 -m http.server 8891 --bind 127.0.0.1 --directory <apk 目录>`，VM 内 `wget http://192.168.1.2:8891/<apk>`（slirp 主机别名）→ `apk add --allow-untrusted`。
- **同版本 apk 不会升级**：改了代码必须 **bump `PKG_RELEASE`**（这轮踩过两次）。
- VM SSH：`python3 utils/quartz-daemon/dev/vm-ssh.py '<cmd>'`（输出**带 CR**，整数比较要 `tr -d '\r\n'`）；`--fetch` 取文件。
- `killall -HUP rpcd` 后**有重载窗口**：紧接着的登录会失败 → 脚本里要重试（`vm-accept-config.sh` 已有）。
- 验收脚本模板：`utils/quartz-app-api/dev/vm-accept-config.sh`（PASS/FAIL 汇总 + 日志 + 现场复原）、`utils/quartz-daemon/dev/vm-accept-cellular.sh`。

### 3.4 App 侧

- `flutter analyze` / `flutter test`（当前 **89 项**）、`dart run tool/e2e_vm.dart`（对真固件，**19 项**）。
- Flutter SDK：`$HOME/flutter-sdk/flutter/bin`；改 arb 后要 `flutter gen-l10n`。
- 蜂窝门控：`PairedRouter.cellularSeen`（粘性）+ `snapshot.cellular.shown`；tab 索引表随显隐重算。
- 模型层纪律：未知字段容忍、缺失即隐藏（`traffic.available=false` 不显示 0 值）。

---

## 4. 交付门槛（沿用本轮）

1. Go：`go test ./...` 全绿、`gofmt -l` 干净（app-api 有 **两个历史文件** `actions_test.go`/`store.go` 本就不合规，不是本轮引入）、`GOOS=linux GOARCH=arm64|mipsle go build ./...`。
2. App：`flutter analyze` 零告警 + `flutter test` 全绿 + `tool/e2e_vm.dart` ALL PASS。
3. 配置面改动：VM 内跑 `config.*` 验收（含回滚安全网），**改动必须现场复原**。
4. 真机（带模组）验收是蜂窝真数据的唯一门槛（FNet3399 + 5G 模组）。

## 5. 协作约定

- 提交信息 `WP-N: 简述`；WORKPLAN §2 状态表与 §1 快照**必须回写**；跨 WP 改文件要在 §4 登记并通知。
- 不推送除非用户明确说；不主动 commit 到别人的仓库分支。
- 文档同步：契约改动 → `AGGREGATE-API.md`（§3.x + 变更记录）；注册表/机制改动 → 对应包的 `docs/DESIGN.md`；界面结构 → `docs/UI-DESIGN.md`（IA v2 定案并入后升 v2.0）。
