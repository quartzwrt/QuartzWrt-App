# 交接说明 · 路由器 tab 前端（W6.9–W6.11 待开工）

**日期**：2026-10-19　**给谁**：接手「路由器 tab」前端的新对话
**先读**：`/home/nrxboat/WORKPLAN.md`（状态权威）→ 本文件 → `docs/IA-V2-DISCUSSION.md`（定案 §13 决策、§14 字段清单）→ `docs/W6.12-CELLULAR-DESIGN.md`（同架构的前一个域，照抄结构）

> 本文只写**怎么接着干**与**哪些坑已经踩过**；进度状态以 WORKPLAN §1/§2 为准。

---

## 1. 已经做完的部分（不要重做）

| 层 | 状态 | 位置 / 证据 |
| :--- | :--- | :--- |
| **配置面 API**（本轮新增，已 VM 验收 17/17） | ✅ | `QuartzWrt-Packages/utils/quartz-app-api/src/internal/uciconf/`；验收 `dev/vm-accept-config.sh` |
| 试点注册表：`network.lan/wan`、`wireless @wifi-device/@wifi-iface`、`dhcp @dnsmasq/@dhcp`、`system @system` | ✅ | `internal/uciconf/registry.go` |
| 配置面会话模型（login 开启保留会话、sid 持久化、logout/revoke 销毁） | ✅ | `internal/auth/auth.go`（`OpenSession`/`SessionCloser`）+ `cmd/.../main.go` |
| 蜂窝域（数据面/转发条目/App 六页） | ✅ | 提交 Packages `ed95016`、App `ea8a097`；验收 18/18 + e2e 19 项 |
| IA v2 定案（tab 命名「路由器」、配置面路线、apply/rollback 安全网） | ✅ | `docs/IA-V2-DISCUSSION.md` §13 |
| 配置面字段提取方法与试点清单 | ✅ | 同上 §14（**接口/无线两张表**，字段名即 UCI 键） |

**四个仓库当前状态**：全部已提交、**未推送**——Packages `ed95016`、App `ea8a097`、ThirdParty `9924cba`、Builder `52d1227`。

---

## 2. 配置面 API 契约（App 侧照此调用）

方法都在 `quartz-app-api` 对象上（不是 `action`），全部要 `access_token`。

### 2.1 方法

| 方法 | 参数 | 返回 `ok:true` 载荷 |
| :--- | :--- | :--- |
| `config.read` | `{config, section?, option?}` | `{config, section, option, value}` |
| `config.write` | `{config, section, option, value}` | `{changes:{changes:[…]}}` |
| `config.changes` | `{config}` | `{changes:[…]}` |
| `config.revert` | `{config}` | `{reverted:<config>}` |
| `config.apply` | `{rollback?:bool=true, timeout?:int=90}` | `{applied:true, rollback, timeout}` |
| `config.confirm` | — | `{confirmed:true}` |

### 2.2 `value` 的三种形状（**已踩过坑**）

- 指定 `option` → **标量**（rpcd 原样是 `{"value":["…"]}`，服务端已解包；未设置 → `null`）
- 指定 `section` 不给 `option` → `{option: value, …}`（**仅注册表内的字段**）
- 都不给（整配置）→ `{sectionName: {option: value}}`（section 键形如 `@system[0]` / `lan`）

### 2.3 安全网（App 必须实现）

`write` 只**暂存**；`apply{rollback:true,timeout:90}` 才提交，且 **90 秒内不 `confirm` 会自动回滚**（VM 实测）。
App 的交互：保存 → apply → 显示倒计时确认条（"保留更改" → `confirm`；超时/断连 → 自动回滚）。**改 LAN IP / 无线密码 / DHCP 范围时必须走这条**，否则会把自己踢下线且回不来。

### 2.4 错误语义（App 侧文案映射）

| code | 场景 | App 行为 |
| :--- | :--- | :--- |
| `forbidden_action` | 配置/section/选项未注册（如 `firewall`） | 隐藏入口或提示"该页尚未支持" |
| `bad_request` | 值类型/枚举/范围/字符集不符 | 行内报错，保留用户输入 |
| `data_unavailable` | 配置会话缺失/过期（消息含"重新登录"）/ uci 不可用 | 提示"请重新登录以启用配置" |
| `action_failed` | uci 执行失败（detail 带上游原因） | 展示 detail，刷新 |

### 2.5 敏感字段

`wireless.@wifi-iface[*].key`、`network.wan.password` 读面返回 `"__masked__"`；**回写掩码占位符会被拒**（`bad_request`）——App 显示为"已设置"占位，用户不改就不提交该字段。

---

## 3. 前端工作清单（按依赖顺序）

### 3.1 tab 改名（先做，10 分钟）

- `l10n/app_zh.arb`：`navNetwork` 文案改「路由器」（en: Router）；`lib/features/shell/shell.dart` 图标换路由器字形（可参考预览页 ① 的 icon path）。
- **不要**改路由路径 `/network`（已发布语义；改名只动文案/图标）。
- 首页（`lib/features/network/network_page.dart`）重构为**分组入口列表**：参考 `design/ia-v2-preview.html` 屏 ① —— 网络（接口/无线/DHCP 与 DNS/静态路由）、安全（防火墙）、系统（系统/管理权/启动项/计划任务·挂载点·LED）、局域网（上网设备）。
- 每行右侧用 chip 标注实现档位：`原生` / `通用表单` / `只读` / `分轮`；**未实现的页不要放可点入口**（可放 disabled 行 + "W6.11"）。

### 3.2 系统页（第一个真正用上 `config.*` 的页面）

- 字段（已注册）：`system.@system[0]` 的 `hostname` / `description` / `timezone` / `zonename` / `log_size` / `log_proto` / `conloglevel`。
- 读：`config.read {config:"system"}`；写：逐字段 `config.write` → `apply` → 确认条 → `confirm`。
- 时区建议做选择器：`ubus call luci getTimezones`（**注意**：`luci` 对象尚未进 app-api 转发条目——见 §5 待办）。

### 3.3 接口页（最高频，也最危险）

- 读：`config.read {config:"network"}`（返回 lan/wan 两节已注册字段）。
- 写：`network.lan` 的 `ipaddr`/`netmask`/`gateway`/`dns`/`ip6addr`、`network.wan` 的 `proto`/`username`/`password`/`dns`/`device`。
- **必须**：改动前弹危险说明（"改 LAN 地址会断开本机"）+ apply 后倒计时确认；断线重连后 App 尝试 `confirm`（若仍有 pending apply）。
- DNS 是列表：`config.write value: ["223.5.5.5","1.1.1.1"]` 或空格串均可（服务端归一）。

### 3.4 无线页

- 读：`config.read {config:"wireless"}` → `@wifi-device[*]` + `@wifi-iface[*]`。
- 写：`ssid`/`encryption`/`key`/`channel`/`htmode`/`txpower`/`country`/`hidden`/`isolate`/`network`。
- `key` 掩码规则见 §2.5；改 `ssid`/`key` 同样走 90s 确认（会断开所有终端）。
- **已知未注册**：MAC 过滤（`macfilter`/`maclist`）、漫游段（802.11r/k/v）——W6.11 再扩注册表。

### 3.5 启动项页（不需要 `config.*`，走 `luci` 对象）

- 数据/动作在 `luci` ubus 对象：`getInitList`（无参）→ `{init:[{name,enabled,running,…}]}`；`setInitAction {name, action}`（enable/disable/start/stop/restart）。
- **接入方式**：往 `internal/ubusfwd` 加两条条目（object=`luci`）+ 方法表 + ACL 三处登记（见 §6 坑位 1）。
- 这是设备 tab 里**最便宜的一页**，建议在系统页之后立刻做，用它打通"新对象 + 三处登记"的管线。

### 3.6 暂不做的页（W6.11+）

防火墙（zone/rule/redirect）、静态路由、管理权（密码/SSH）、计划任务/挂载/LED、接口状态页（`iwinfo`/`network.interface` 只读）。
**扩展注册表的方法**：从 LuCI 定义提取（`feeds/luci/modules/luci-mod-network/.../view/network/*.js` 与 `protocols/luci-proto-*/protocol/*.js`），按「节」完整登记，**不做散点键**——见 §14。

---

## 4. 代码结构照抄哪儿

蜂窝域是同架构的完整样板：

| 要做的事 | 照抄 |
| :--- | :--- |
| 新 feature 目录 | `lib/features/cellular/` |
| API 客户端（带 action/读条目） | `lib/features/cellular/qmodem_client.dart`（`config.*` 直接走 `TokenManager.call('config.write', …)`，不必包新 client） |
| 模型容错解析 | `lib/api/cellular.dart` + `Snapshot` 访问器 |
| 条件 tab / 路由 | `lib/features/shell/shell.dart`、`lib/app.dart`（`_fadeUpPage` 详情过渡） |
| 危险确认层 | `lib/widgets/quartz.dart` 的 `showConfirmSheet(..., danger: true)` |
| 卡片/行/分段 | `QuartzCard`/`KvRow`/`SegmentBar`/`SectionLabel`/`InfoBanner` |
| i18n | `lib/l10n/app_{zh,en}.arb` + `flutter gen-l10n`（新增键两者都要加；带 `{}` 占位符的在 en 里要写 `@key.placeholders`） |
| 单测 | `test/cellular_test.dart` |

---

## 5. 待办（跨层登记，按优先级）

1. **`net.wan.ipv6` 契约加法**（daemon 取首个全局单播，跳过 fe80::/ULA/临时；App/概览/dashboard 三处显示）——IA 定案 D9′，尚未实现。
2. **`luci` 对象条目**：`getInitList`/`setInitAction`（启动项）+ `getTimezones`（时区选择）→ ubusfwd + 方法表 + ACL。
3. **注册表扩展**：防火墙/路由/管理权/挂载（W6.11）。
4. **qmodem fork 推送**（ThirdParty 的 `lang` 适配只在镜像；推送前勿单独 `sync-mirrors.sh qmodem`）+ 打 tag `v3.4.0_rc3-quartz2`。
5. **推送四仓**（等用户指令；推送顺序建议 Packages → App → ThirdParty → Builder）。
6. **真机验收**（蜂窝真数据 + 硬件卸载；GNet3399 带模组）。

---

## 6. 踩过的坑（照做能省半天）

1. **新增 app-api 方法要改三处**，漏一处就是"方法不存在"或 `-32002 Access denied`：
   - `cmd/quartz-app-api/main.go` 的 `methodList()`（rpcd 方法表）
   - `files/acl.d/quartz-app-api.json`（ACL 的 `unauthenticated` 方法列表）
   - `switch method` 里的分发分支
   本轮 `config.*` 就是先漏了前两处，VM 上表现为 `-32002`/方法不存在。
2. **无参 uci 调用必须传 `{}`**：`json.Marshal(nil)` 得到 `null`，rpcd 报 "Parsing message data failed"。
3. **`uci get` 带 `option` 返回 `{"value":[…]}`**（值被数组包了一层），不带 option 才是 `{"values":{…}}`。
4. **配置面必须有 rpcd 会话**：`session create` 出来的是空 ACL（写 uci 被拒）；只有 `session login`（管理员凭据）的会话有全量 ACL，且 `apply`/`confirm` 必须与 `set` 同 sid。app-api 每次调用是新进程 → sid 持久化在 `state.json` 的设备记录里。
5. **`killall -HUP rpcd` 后有重载窗口**：紧接着的第一次调用会失败——验收脚本要加重试（见 `vm-accept-config.sh` 的登录重试）。
6. **`apk add` 同版本号不会重装**：改包必须 bump `PKG_RELEASE`（本轮 r2→r8 就是这么来的）。
7. **`vm-ssh.py` 输出带 CR**：`[ "$OUT" -eq 0 ]` 会报 "integer expression expected" → `tr -d '\r\n'`。
8. **rpcd `/ubus` 是扁平参数形态** `[sid, object, method, args]`；用老的嵌套 `[sid,"call",{…}]` 会得到 `-32700 Parse error`（写验收脚本前先读 `dev/vm-accept.sh` 的 `call()`）。
9. **构建树 `feeds.conf.extra` 里 quartz 是 `src-link`** → 本地 Packages 改动直接生效；thirdparty 是**锁 SHA** → 镜像改动要提交并 bump 锁定才会进镜像。

---

## 7. 验收命令速查

```bash
# Go 侧（app-api / daemon）
cd QuartzWrt-Packages/utils/quartz-app-api/src && ~/go-sdk/bin/go test ./... && ~/go-sdk/bin/gofmt -l .
# Flutter 侧
export PATH="$HOME/flutter-sdk/flutter/bin:$PATH"; flutter analyze && flutter test
# VM：预览台 + 热装（宿主 HTTP → guest 192.168.1.2 拉包）
QuartzWrt-Builder/scripts/test-in-vm.sh --detach        # 8080→80 / 2222→22 / 8443→443；root/quartz
# 配置面 / 蜂窝验收
QuartzWrt-Packages/utils/quartz-app-api/dev/vm-accept-config.sh
QuartzWrt-Packages/utils/quartz-daemon/dev/vm-accept-cellular.sh
# App 端到端（真固件）
QuartzWrt-App && dart run tool/e2e_vm.dart
# 设计预览（改预览页后重出评审图）
cd QuartzWrt-App && python3 design/shot_ia_v2.py   # → design/shots/ia-v2/
```

**提交约定**：`WP-N: 简述`；四个仓库各自独立提交；WORKPLAN §2 状态表与 §1 快照**必须**同步回写；推送等用户指令。
