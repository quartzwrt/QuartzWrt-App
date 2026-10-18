# QuartzWrt App · IA v2 定案（路由器 / 应用 / 蜂窝）

**状态**：**定案 v1.0**（2026-10-18 R4 拍板；待并入 `UI-DESIGN.md` v2.0 与 `DESIGN.md`，本地**未提交**）——用户提出三处规划更改，本稿做可行性核实、路线权衡与工程量分解，供拍板。
**拍板后去向**：并入 `UI-DESIGN.md`（v2.0，IA 与 tab 结构）、`DESIGN.md`（§8/§11/§12），并回写 WORKPLAN（WP-5/WP-6/WP-7/WP-11 登记）。
**预览**：`design/ia-v2-preview.html`（八屏 + tab 显隐对比；评审图 `design/shots/ia-v2/`，`python3 design/shot_ia_v2.py` 可复跑）。

---

## 1. 用户指令（原文归纳）

| # | 指令 | 本稿对应 |
| :-- | :--- | :--- |
| 1 | **「网络」tab 改「设备」tab**：在 App 内实现网页端**接口 / 无线 / 路由 / DHCP / DNS / 防火墙 / 系统 / 管理权 / 启动项**等页面功能的**完整控制** | §3 |
| 2 | **「应用」tab**：应用管理 = 把网页端的服务/功能搬到手机（bandix / docker / openclash 等**完整控制**）；软件包 = 网页端软件包功能的**完整实现** | §4 |
| 3 | **新增「蜂窝」tab**：配合 qmodem 做 5G 模组的**信息查看与完整控制**；**未安装 qmodem 则不显示**；可能需 qmodem 专属适配 | §5 |
| 4 | 「工程量较大，规划不一定对，请给建议，必要时做演示页面」 | §6 待拍板 / §7 工作量 / 预览页 |

---

## 2. 现状核实（本稿依据，逐条可验证）

### 2.1 App 现状（`lib/` 实读）

| 项 | 现状 | 与本次改动的关系 |
| :--- | :--- | :--- |
| tab 结构 | 4 显（概览/网络/应用/设置）+ **第 5 位预留隐藏**（`features/shell/shell.dart`） | 「蜂窝」将**花掉预留位**（见 §5.2） |
| 网络页 | WAN 卡 + 无线汇总卡（由 `clients.iface` 派生）+ 上网设备卡 + 「网络服务」两行（DNS 重启、WAN 重连=规划中） | 内容 = 契约 v1 快照的**只读投影**，**没有任何配置面** |
| 应用页 | 双子段：「应用」（服务列表 + 详情 + bandix L2/L3）+「软件包」（三视图 + 操作记录页） | 与指令 2 的方向一致，缺「第三方应用的深度控制」 |
| 动作面 | `ActionSpec` 注册表；实际条目 = `service.start/stop/restart`、`system.reboot`、`packages.*`、`bandix.*` | WP-5 白名单动作，**无配置类动作** |
| 数据面 | 契约 v1：`host/system/net/docker/clients/services/bandix/errors`（`AGGREGATE-API.md`） | **无 wireless / interfaces / firewall 节**（无线卡是派生近似） |

### 2.2 路由器侧可用机制（**关键发现：网页端的能力面早已存在，缺的是「受控暴露」**）

对锁定基座（ImmortalWrt 25.12 / apk）+ 本地构建树逐项核实：

| 机制 | 出处（实证） | 覆盖的网页端功能 |
| :--- | :--- | :--- |
| **ubus `uci` 对象** | rpcd 内置（`build_dir/…/rpcd-2026.10.04~d99f703e/uci.c`）；方法：`configs/get/state/add/set/delete/rename/order/changes/revert/commit/apply/confirm/rollback/reload_config` | **全部配置面**（接口/无线/DHCP/DNS/防火墙/系统/管理权/静态路由…），含 **LuCI 文档式「应用 + 回滚」安全网** |
| **ubus `luci` 对象** | `luci-base/root/usr/share/rpcd/ucode/luci`（rpcd-mod-ucode 载入） | `getInitList`/`setInitAction`=**启动项**；`setPassword`=**管理权·改密**；`getTimezones`/`setLocaltime`=系统时间；`getLEDs`/`getMountPoints`/`getBlockDevices`/`getUSBDevices`/`getRealtimeStats`/`getConntrackList`/`getProcessList`/`getTempInfo`/`getOnlineUsers`/`getFeatures`… |
| **ubus `iwinfo`** | `rpcd-mod-iwinfo`（manifest 实证在固件内） | 无线**状态与扫描**（信道/噪声/关联客户端/scan） |
| **`network` / `network.interface`**（netifd） | 基座常驻 | 接口状态、协议处理器、`renew`/`up`/`down` 等 |
| **ubus `qmodem` / `qmodem.sms`** | `QuartzWrt-ThirdParty/qmodem/docs/qmodem-rpcd-interface.md` + `luci/luci-app-qmodem-next/root/usr/share/rpcd/acl.d/*.json` | **蜂窝域全套**（见 §5.1） |
| 现有固件包 | manifest：`rpcd` `rpcd-mod-ucode` `rpcd-mod-file` `rpcd-mod-iwinfo` `rpcd-mod-luci` `luci-mod-network` `luci-mod-system` `luci-app-firewall` 均在 | 上述机制**无需新增固件包** |

**因此指令 1/3 的瓶颈不在路由器侧，而在两处**：① App 只有 `quartz-app-api` 一条受控通道（设计如此，安全模型），② App 没有「配置表单」这一类 UI 机制。

### 2.3 App 侧缺口清单

| 缺口 | 说明 |
| :--- | :--- |
| 配置读写通道 | app-api 无 UCI 读写方法；且**禁止任意透传**（WP-5 §5.1 纪律） |
| 配置页 UI 机制 | 现有页面全是「卡片 + 行」，没有表单控件（输入/选择/开关/列表编辑）、没有「保存并应用」流程 |
| 危险配置安全网 | 改 LAN IP / 无线密码 / DHCP 范围 / 防火墙会**当场断开手机自己**——必须照抄网页端的「应用 + N 秒内确认，否则自动回滚」 |
| 安全面 | 会话/回滚机制要求**每设备一条 rpcd 会话**（见 §3.3 实测细节） |

---

## 3. 「设备」tab（原「网络」）

### 3.1 内容盘点（网页端菜单 → 三面归类）

网页端（LuCI）Network + System 两菜单逐页拆解，按**实现面**归类——这决定成本：

| 网页端页面 | 只读状态 | 配置面（UCI） | 动作面（命令/ubus） | App 归属 |
| :--- | :--- | :--- | :--- | :--- |
| 接口（Interfaces） | `network.interface` dump | `network`（proto/ipaddr/netmask/gw/dns…） | `renew`/`up`/`down`（WAN 重连） | 设备·网络 |
| 无线（Wireless） | `iwinfo`（信道/噪声/客户端） | `wireless`（SSID/加密/信道/功率/开关） | `wifi reload/up/down`、scan | 设备·网络 |
| DHCP/DNS | 租约表 / `dhcp` 汇总 | `dhcp`（范围/租期/DNS 转发/静态租约/主机名） | `dnsmasq` reload | 设备·网络 |
| 路由（静态路由/路由表） | `ip route` 类数据（daemon 加节即可） | `network.route/rule` | — | 设备·网络 |
| 防火墙 | `fw4` 规则计数（可选） | `firewall`（区域/转发/规则/NAT） | `fw4 reload` | 设备·安全 |
| 诊断（ping/traceroute/nslookup） | — | — | 需路由器侧执行（**后置**） | 设备·工具（P2） |
| 系统（主机名/时区/NTP/日志） | `luci.getUnixtime/getTimezones` | `system` | `setLocaltime` | 设备·系统 |
| 管理权（密码/SSH/密钥） | — | `rpcd`/`dropbear` | `luci.setPassword` | 设备·系统 |
| 启动项（Startup） | — | `rc` 启用态（`luci.getInitList` 已含） | `luci.setInitAction`（enable/disable/start/stop/restart） | 设备·系统（**最便宜，先做**） |
| 计划任务 / 挂载点 / LED | 部分只读 | `crontab`/`fstab` | — | 设备·系统（P2） |
| 备份/恢复、固件升级 | — | — | sysupgrade | **归 WP-9（OTA）**，不双开 |
| 上网设备（客户端） | 契约 `clients`（已有） | `dhcp` host 静态绑定 | — | 设备·终端（现卡平迁） |

> 命名提醒：App 内「上网设备」与 tab 名「设备」语义撞车（前者指 LAN 终端）。建议 **tab「设备」= 这台路由器**，列表统一改称**「终端」**（`navDevices` / `clientsTitle` 文案层）。

### 3.2 三条路线与推荐

| 路线 | 做法 | 成本 | 结论 |
| :--- | :--- | :--- | :--- |
| **A 逐页原生复刻** | 每页手写 Flutter 表单 + 每字段一条 API | 极高；且上游页面随包变化，永远追不完 | **不做全量** |
| **B 受控配置面 + 注册表驱动** | app-api 增设 `config.*` 方法族（读白名单 + 写注册表 + apply/rollback）；App 侧手写高频页，长尾页用**注册表元数据驱动的通用表单**渲染 | 一次性机制投入大，之后**每页 ≈ 注册表若干行 + 1 个页面** | **推荐**（与 bandix 转发项同思路：机制先行、条目便宜） |
| **C WebView 兜底** | 内嵌网页端（会话注入） | 低（但有会话/ACL/安全面） | **仅作长尾兜底**：更推荐「在浏览器中打开」深链（零会话注入，用户用已有网页端凭据）；内嵌 WebView 与现行纪律（UI-DESIGN §4.4 不做 webview 化）冲突，需单独拍板 |

**推荐组合**：B 为主 + C（深链）兜底 + A 只用于**四个高频页**（接口 / 无线 / DHCP·DNS / 启动项）。

> **v0.2 修订（R1 反馈）**：用户要求「网页端能改的、App 能做好的尽量做，不做半吊子」→ 两条硬约束随之落地：
> ① **注册表按「节」完整注册**（每个 section 的全字段类型表，如完整 `network.lan`、完整 `wireless.@wifi-iface[N]`、完整 `firewall` 区域/规则/重定向），**不允许散点式键白名单**——否则「有的字段能改有的不能」本身就是半成品；
> ② **深链兜底只用于「确实没有 API」的对象**（第三方插件），不用于「我们懒得做/先不做」的页面。分轮次只是交付顺序，不是能力裁剪。详见 §9-R1。

### 3.3 配置面机制设计（B 路线细节，含实测约束）

1. **通道**：app-api 增方法族 `config.read` / `config.write` / `config.apply` / `config.confirm` / `config.changes`（`config.revert`）。
2. **写白名单 = 注册表**：键形 `config.section.option`（如 `network.lan.ipaddr`、`wireless.@wifi-iface[0].ssid`），每条带**类型/枚举/范围/字符集**校验（复用 `internal/ubusfwd` 的写法）。**未注册键 → `forbidden_action`**——与现有「无任意透传」纪律一致。
3. **安全网（照抄网页端语义）**：`uci.apply{rollback:true, timeout:90}` + `config.confirm`。
   - **实测（rpcd `uci.c` 源码）**：`apply` **必须带 `ubus_rpc_session`**；staged 改动住在**会话私有目录** `/tmp/.uci/sessions/<sid>`；apply 时快照受影响配置文件，`confirm` 需同一 sid；超时未确认 → 自动回滚（`rpc_uci_apply_timeout`）。
   - **⇒ app-api 必须为每台设备持有一条自有 rpcd 会话**（它在 login 路径已在用 `ubus call session login`，机制现成）。这同时带来：与网页端**互斥**（rpcd 的 `apply_sid` 是**全局单例**，两处同时挂起 apply 时后者 `PERMISSION_DENIED`）→ App 侧配置应用必须**串行化**，并在冲突时提示「网页端有未确认的更改」。
4. **生效方式**：`uci commit` 后 rpcd 会发 `config.change` 事件，netifd/dnsmasq/fw4 等 procd 服务自 reload（= 网页端行为）；少数页需显式 `wifi reload`/`network reload`（写进该页注册表声明）。
5. **失联防护**（必须进设计，否则会「自己把手机踢下线」）：改 `network.lan.*` / `wireless.*` / `dhcp` 范围 / `firewall` 时，App 必须显示**倒计时确认条**（90s）+ 断连文案，且 App 断线重连后优先尝试 `config.confirm`（有 pending apply 时）。
6. **只读面**：优先把 `luci.getInitList` / `iwinfo` / `network.interface` 的**聚合读**放进 app-api 的 `config.read` 或新增 `sysinfo` 读方法（一次往返拿全）；无线状态可另加 daemon `wireless` 节（L1→L2 富化路径），但**不必**为配置面开 daemon 节。

### 3.4 分轮建议（设备 tab）

| 轮次 | 内容 | 依赖 | 规模 |
| :--- | :--- | :--- | :--- |
| W6.9 | 设备 tab 骨架（分组入口 + 只读状态页：接口/无线/防火墙概览/终端）+ 「启动项」页（`luci.getInitList/setInitAction` 现成）+ WAN 重连动作 | 无（纯加法） | M |
| W6.10 | 配置面机制（`config.*` + 注册表 + apply/rollback + 会话）+ 四高频页（接口/无线/DHCP·DNS/系统） | W6.9；app-api 新方法族 | L |
| W6.11 | 防火墙（区域/端口转发/规则）、静态路由、管理权、挂载/LED/计划任务；长尾页转通用表单渲染 | W6.10 | M–L |

---

## 4. 「应用」tab 深化

### 4.1 能力三级模型（建议作为「应用」子段的新表述）

| 级 | 含义 | 实现 | 例 |
| :--- | :--- | :--- | :--- |
| **完整** | 原生页面级控制（列表/详情/动作/配置） | 上游 rpcd ubus 面 或 我方 bridge + App L2/L3 | bandix ✅（已有）；qmodem（§5）；docker（待做） |
| **常用** | 状态 + 启停 + 少量关键动作 + 关键配置 | 厂商 ubus / bridge / 动作白名单 | openclash（启停、配置切换、核心/规则更新）；mosdns、passwall（同类） |
| **只读** | 状态可见 + 「在浏览器中打开」兜底 | 快照 `services` + 深链 | 无 API 的第三方插件 |

纪律不变：**不解析插件私有文件、不嵌网页**；缺能力就补 API（bridge 或上游 rpcd）。

### 4.2 现状与缺口

| 应用 | 现状 | 缺口 / 建议 |
| :--- | :--- | :--- |
| bandix | 完整（列表富化 + 详情卡 + 三对话框 + 流量明细页） | 无 |
| docker | 仅有 `docker.container.start/stop/restart` 动作 | **建议加适配器**：容器列表/详情/日志/启停/删除/镜像列表（Docker Engine API 走 `/var/run/docker.sock`，语义稳定）；出厂未装 → `available=false` 常态，属 L1 条件卡已有机制 |
| openclash | 快照 `services.openclash`（核心版本/更新） | 建议：启停/重启、配置文件切换、核心与规则更新触发（WP-7 §4.4 遗留项）；**节点选择类**不做（属网页端 dashboard 专长）→ 深链兜底 |
| mosdns / passwall / fancontrol … | 探针可见（`services` 开放映射） | 泛化行 → 详情 → 「在浏览器中打开」 |

### 4.3 软件包面

已完整（可升级/已安装/全部搜索/刷新/升级/卸载/操作记录/详情卡）。**剩一项**：安装新包 = 可用源浏览 + `packages.install`（WP-5 侧 v1 后置项），本轮可一并拍板做不做。

---

## 5. 「蜂窝」tab（qmodem）

### 5.1 上游能力核实（`qmodem/docs/qmodem-rpcd-interface.md`，478 行）

**读**：`base_info` `cell_info` `info` `network_info` `sim_info` `get_at_cfg` `get_copyright` `get_disabled_features` `get_dns` `get_imei` `get_lockband` `get_mode` `get_neighborcell` `get_network_prefer` `get_current_band`（+`get_current_band_capabilities`）`get_reboot_caps` `get_stats` `get_sms` `get_traffic_reset_schedule`

**写**：`modem_dial` `modem_hang` `modem_redial` `scan_all/scan_pcie/scan_usb` `set_mode` `set_lockband` `set_network_prefer` `set_neighborcell` `send_at` `send_sms` `send_raw_pdu` `delete_sms` `set_sms_storage` `set_imei` `do_reboot` `clear_stats` `clear_dial_log` `set_traffic_reset_schedule`

**ACL 已在包内**（`luci-app-qmodem-next` 的 acl.d）。另：`qmodem.sms` 第二对象（`status/sync/list/send/delete/mark_read/storage_get`…）+ 独立包 `qmodem-smsd` / `sms-forwarder-next`。

**⇒ 蜂窝域是三个域里 ROI 最高的**：数据结构化、读写成对、多机型（Quectel/Fibocom…）已在上游做了兼容与能力声明。

### 5.2 设计与门控

- **显隐门控**：`services.qmodem`（探针 `procd qmodem_init`，`quartz-runtime-resources` 已有）为真 **且** 探测到 ≥1 个模组 section。
  - **粘性**：一旦确认存在，即持久化标记，此后**仅**在「重新配对到另一台路由器」时重算——避免临时断网/daemon 降级导致 tab 忽隐忽现。
  - 这是**第 5 个 tab 位**（预留位被用掉）：此后再有功能域只能落「卡 / 行 / 详情页」，IA 纪律需要用户确认接受。
- **多模组**：`config_section=modem1/modem2…` → 顶部模组切换器（1 个时不显示）。
- **能力协商**：`get_disabled_features` + `*_capabilities`（如 `get_current_band_capabilities`、`get_stats` 仅 Quectel、`get_reboot_caps`）→ 不支持项**灰显并注明原因**，不静默消失。
- **页面分组**（建议）：① 状态（注册/信号 RSRP·RSRQ·SINR·RSSI/频段与 CA/运营商/SIM/温度）② 拨号（状态/时长/IP/断开·重拨/拨号日志）③ 网络设置（模式/频段锁定/网络偏好/邻区）④ SIM（切换/存储）⑤ 短信（会话/发送/删除/转发规则）⑥ 流量（累计/重置计划）⑦ 高级（IMEI/重启模组/AT 调试，**折叠 + 危险确认**）。

### 5.3 专属适配层（建议：上游字段不进 App）

| 面 | 做法 |
| :--- | :--- |
| 读 | **v0.2 修订**：改走 **daemon 慢车道新增 `cellular` 节**（10s，与 qmodem 上游缓存默认 10s 同拍——`qmodem-rpcd-interface.md` §Caching 已核实）→ **Dashboard 卡 / App 概览卡 / App 蜂窝页三者同源**，App **不再新增读方法**；上游字段映射收敛在 daemon 的 `cellular` 采集器（= 「专属适配层」的新落点，原地保留「上游改字段不动 App」的性质） |
| 写 | 复用 WP-5 §5.1「ubus 转发项」机制：逐条注册 `qmodem.*` 条目（数值参数走 `data` 包装，经验同 bridge 坑位 #61） |
| 版本 | 探针加 `core` 版本（`qmodem` 包版本），App 显示 + 能力差异留痕 |
| 节奏 | **不进 2s 主刷新，进 10s 慢车道**（与 bandix 同机制；上游自身 10s 缓存，不放大 AT 压力）；蜂窝页显示「最后采集 x 秒前」并支持下拉触发快照立即重取 |

### 5.4 安全与合规

- `send_at` = **任意 AT 指令**（可改 IMEI/锁频段/清 NV）→ 默认**不进 v1 UI**，或藏于「高级 → 开发者」并二次确认 + 审计。
- `set_imei` 在多国有法律风险 → 默认灰显 + 免责说明（与 `qmodem-seal` 的取向一致，需要时按设备开关）。
- 短信属隐私数据：本地不落盘（页面内存态），会话列表需显式刷新。

### 5.5 验收约束（重要）

**VM 无 5G 模组** → 只能验：接口契约、空态（未插模组/未装 qmodem 隐藏 tab）、多模组切换逻辑、错误映射。**真机验收必须一台带模组的设备**（FNet3399 已预装 qmodem 链，`devices/erya_fnet-3399/preinstall.config`），需与 WP-11 协调排期。

### 5.6 分轮建议

| 轮次 | 内容 | 规模 |
| :--- | :--- | :--- |
| W6.12 | app-api `cellular` 读适配器 + 转发条目（读/写）+ 探针版本 → App 蜂窝 tab（状态/拨号/网络设置/流量） | M–L |
| W6.13 | 短信面（会话/发送/删除/转发规则）+ SIM 切换 + 能力协商细化 | M |
| W6.14 | 高级（IMEI 策略、AT 调试门控、模组重启/统计重置/复位计划） | S–M |

---

## 6. 待拍板项（建议稿）

| # | 事项 | 建议 |
| :--- | :--- | :--- |
| D1 | tab 命名 | 「设备」接受；App 内终端列表改称「终端」（避免与 tab 撞名） |
| D2 | 设置 tab 定位 | 收窄为**纯本机**（外观/语言/关于/已配对路由器/远程访问）；「系统设置·设备控制（重启路由器等）」**迁入设备 tab·系统** |
| D3 | 设备 tab 实现路线 | **B（受控配置面 + 注册表）为主**，A 只做四高频页，C 用**深链**兜底（内嵌 WebView 单独拍板，默认不做） |
| D4 | 配置安全网 | 强制 `apply(rollback, 90s) + 倒计时确认`；配置写入串行化并处理与网页端的 apply 互斥 |
| D5 | 蜂窝 tab 门控 | `services.qmodem` + 有模组；**粘性**；接受用掉第 5 tab 位 |
| D6 | 蜂窝适配层 | 读=`cellular` 适配器（稳定契约）；写=转发条目；独立刷新节奏（不进 daemon 快照） |
| D7 | AT 调试 / IMEI | v1 默认不做 / 灰显；如要做，走「高级 + 双重确认 + 审计」 |
| D8 | 应用控制分级 | 完整（bandix/docker/qmodem）、常用（openclash 等）、只读+深链（其余）三档 |
| D9 | docker 适配器 | 做（容器列表/详情/日志/启停/删/镜像），出厂未装为常态 |
| D10 | 安装新包（`packages.install`） | 与配置面同轮做或后置（待定） |
| D11 | 轮次顺序 | 建议：**蜂窝 W6.12 先行**（API 现成、域独立、真机排期可并行）→ 设备 W6.9–W6.11 → 应用深化 |

---

## 7. 工作量与跨 WP 登记

- **粗略量级**（非承诺）：蜂窝 v1 ≈ **1 个读适配器 + ~20 转发条目 + 4–6 个页面**；设备 tab 全量 ≈ **1 个配置方法族 + 注册表 + 10–15 个页面**（分三轮）；应用深化 ≈ docker 适配器 + openclash 控制。
- **跨 WP**：WP-5（`config.*`/`cellular`/转发条目/白名单动作）、WP-4（可选 `wireless` 节、路由/租约只读节）、WP-7（openclash 触发项、bridge 兜底）、WP-11（qmodem 真机验收）、WP-9（系统·固件升级不双开）、WORKPLAN §2/§4 登记。

## 8. 变更记录

*v0.1 2026-10-18 —— 首稿（讨论稿）：用户三处 IA 更改的可行性核实（§2）、设备 tab 三路线权衡与配置面机制（§3）、应用能力分级（§4）、蜂窝 tab 与 qmodem 适配（§5）、待拍板十一项（§6）；预览 `design/ia-v2-preview.html` 八屏 + tab 显隐对比。*

---

## 9. R1 反馈评估（2026-10-18 用户反馈 → 逐条评估与落点）

| # | 用户反馈 | 评估 | 建议 / 落点 |
| :-- | :--- | :--- | :--- |
| R1 | **网页端能改的、App 能做好的尽量做，不做半吊子** | **同意，且这条改变了取舍**：半吊子的真正来源往往不在 UI，而在「API 只开了一半」。原「四页原生 + 长尾通用表单 + 深链」的隐含风险是注册表散点化 | 注册表改为**按节完整注册**（§3.2 v0.2 修订）；深链降级为「仅无 API 场景」；设备 tab 目标 = 列出核心页**全部可改**（分轮只影响顺序） |
| R2 | **无线页加「已连接设备」显示** | 同意，成本低 | 每射频卡片下直出关联终端（名称 / IP / 信号 dBm / 协商速率 / 在线时长），数据 = `iwinfo` assoclist（固件已有 rpcd-mod-iwinfo）；不做二级页 |
| R3 | **无 API 的应用 → 跳转网页端** | 确认，与原判断一致 | 保留为「只读 + 深链」档；有 API 的一律原生做好（bandix ✅ / docker / qmodem / tailscale） |
| R4 | **数据尽量图形化**（如 qmodem 信号） | 同意——这正是概览「不如网页端」的一部分原因 | 图形清单：**信号质量段条 + 60 点信号历史曲线**（daemon 10s 采样）、**WAN 双序列 sparkline**（对齐 dashboard 的 下行/上行 双线）、系统资源条（已有）、流量占比条、无线客户端信号条。纪律不变：**零图表库**、自绘（App = CustomPainter）、≤60 点、无动画（WP-2 §5.2 同源） |
| R5 | **蜂窝的功能控制参考 qmodem 的 tab 分类** | 同意，且省事（上游分类 = 用户已熟悉的分类） | 映射：qmodem 菜单（Overview / Network Configuration / SIM Switch / SMS / SMS Forwarder / AT Debug / Advanced / Settings）→ App 蜂窝 tab「概览页 + 入口宫格」；见预览 ⑥ |
| R6 | **概览不如网页端 dashboard** | 同意，贵在**密度与口径**，不是配色 | 概览 v2 = **dashboard 卡片集的移动端再渲染**（同卡、同口径、同降级语义）：hero（型号/版本/内核 + 运行时间/采集时刻）、网络吞吐（双序列 sparkline + 大数字+单位）、系统（条 + 温度/负载）、**蜂窝卡（新）**、**Tailscale 卡（新）**、流量明细摘要、终端摘要、服务与核心（状态点 + 版本 + 深链）；见预览 ⑨ |
| R7 | **qmodem 专属卡片也要上 dashboard 与 App 概览** | **采纳，并修正 §5.3 架构**：三端要同源，读面就必须进 daemon 慢车道（新增 `cellular` 节，10s） | daemon `cellular`（WP-4）→ Dashboard 卡（WP-3，`span 4/6`，`available!==true` 隐藏）→ App 概览卡 + 蜂窝页（WP-6）；App 无新读方法 |
| R8 | **应用页 / dashboard / 概览加路由器侧 Tailscale** | 采纳；数据面已具备（`services.tailscale` 探针含 `ip` extra） | 建议**探针加 2–3 个 extras**（`dns_name` / `backend_state` / `peers_online`，零 daemon 改动，同 WP-10 既有机制）；三处呈现：App 应用行（状态 + tailnet 地址 + 配置直达）、App 概览卡、Dashboard 卡 |
| R9 | **App 设置里的 Tailscale 移到「连接路由器」页** | 采纳——「连接（含远程）」应聚在一处，设置只留本机偏好 + 已配对路由器管理 | 连接页新增「远程连接 · Tailscale」段（内嵌 tsnet 开关 / 登录 / 同 tailnet 路由器直达）；设置页移除该入口（地址增删改一并迁入连接页） |
| R10 | **启动逻辑改为先「连接路由器」页，点选后才进控制界面** | 采纳，但建议加一个边界：**冷启动才显示连接页，后台回前台保留当前会话**（否则每次切回都要重连，体验倒挂） | 连接页三区：「最近使用」（一键连）/「局域网发现」/「远程连接 · Tailscale」；配对前与已配对共用同一页（配对前只有发现区） |

**R7 带来的机制修订（重要）**：蜂窝读面走 daemon `cellular` 节后，
- ✅ 三处消费同源（Dashboard / App 概览 / App 蜂窝页）；
- ✅ 上游字段映射收敛在 daemon 采集器（专属适配层落点）；
- ⚠️ 代价：daemon 每 10s 调 4–6 个 qmodem 方法（上游 10s 缓存内命中，实测开销入验收项）；
- ⚠️ 一致性：`available=false`（未装/无模组）→ 三处一起隐藏（与 bandix 同款条件卡语义）。

## 10. 变更记录

*v0.2 2026-10-18 —— **R1 反馈轮**（用户 10 条反馈 → §9 逐条评估）：配置面注册表改「按节完整注册」；深链兜底限定为无 API 场景；无线页加关联终端；新增图形化清单（信号段条/历史曲线/双序列 sparkline）；蜂窝 tab 按 qmodem 分类重构；概览 v2 对齐 dashboard 密度与口径 + 新增蜂窝/Tailscale 卡；**蜂窝读面改走 daemon 10s 慢车道（§5.3 修订）**；Tailscale 三处呈现 + 探针 extras；连接页吸收 Tailscale 与远程能力；启动流改「先连接页、点选进入」（冷启动限定）。预览 `design/ia-v2-preview.html` 扩至 **十一屏 + dashboard 卡示意 + tab 对比**。*

---

## 10. R2 反馈评估（2026-10-18 第二轮 → 逐条评估与落点）

| # | 用户反馈 | 评估与核实 | 建议 / 落点 |
| :-- | :--- | :--- | :--- |
| R11 | **AT 命令页要有 qmodem 的预置命令，且与网页端对得上** | **机制已核实**：网页端「Quick Commands」= `qmodem get_at_cfg` 返回的 `cmds[{name,value}]`（rpcd 脚本拼装 `/usr/share/qmodem/at_commands_{zh,en}.json`：**通用段 + 本机厂商/平台段**，按厂商脚本 `dynamic_load.json` 选 vendor） | App **不硬编码命令表**，直读同一次调用 → 天然逐条一致、厂商/机型差异自动跟随；UI：端口选择（`ports`/`using_port`）+ 输入 + 发送 + 等宽响应（耗时/可复制）+ 快捷命令分组（通用 / 厂商·平台）；**任意 AT 有真实风险**（写 NV / 改 IMEI / 锁频）→ 发送前二次确认 + logd 审计。**新发现问题**：上游按**路由器** LuCI 语言选 zh/en 文件 → 中文 App 在英文路由器上会拿到英文命令名。**建议在受控 fork 加 `lang` 参数**（或同时返回两份，向后兼容加法；归 WP-7 fork 维护） |
| R12 | dashboard 其他卡片向新增两卡的风格趋近 | 同意——现状差异是**同类信息多种画法**（表格/大数字/色块混排） | 定为 WP-3 一轮**风格统一**：所有卡统一为「状态点 + 键值行 + 等宽数值 + 占比条 + 链接行」一套 KV 规格；数值口径与单位写法统一；卡片标题统一「域 · 对象 · 补充」三段式。演示见预览 ⑬ |
| R13 | tab 栏改**悬浮 + 毛玻璃/模糊 + 小白条适配** | 采纳，纯前端改动，无数据面影响 | 规格：左右内缩 14、圆角 22、高 62、`backdrop-filter: blur(22px) saturate(1.7)`、半透明面板色 + 1px 描边 + 投影；**安全区**：iOS Home Indicator / Android 手势条由底部留白让位（预览已画小白条）；确认层、悬浮操作条同样用毛玻璃（三处一致）。预览全屏已按此绘制 |
| R14 | dashboard 流量折线**折角尖锐**，要圆润 | 同意，定位到实现：`frontend/src/components/primitives.js` 的 `Sparkline` 用 `<polyline>` | 改 `<path>` + **Catmull-Rom → 三次贝塞尔**平滑 + `stroke-linejoin/linecap: round`（同一组数据的两种画法对比见预览 ⑬ 底部）。App 侧 CustomPainter 同步平滑。**需改 WP-3 DESIGN §5.2 措辞**（现写「polyline」）与基线截图 |
| R15 | 概览 / dashboard 网络卡显示 **IPv4/v6**，默认部分显示、点击展开完整 | 采纳；核实：契约 §3.3 仅有 `wan.ipv4`（daemon `net.go` 用 Go 原生 `InterfaceByName` 取 IPv4） | 契约加法 **`net.wan.ipv6`**（取首个全局单播，跳过 fe80::，优先 GUA 于 ULA；daemon 侧十余行，与既有 `ifaceIPv4` 同法）；两端统一交互：**默认打码**（`100.64.7.…` / `240e:3a1:…:d1f`）、点击展开完整、长按复制 |
| R16 | 避免换行后第二行只剩一两个字（孤字） | 同意——**本预览自己也犯了这毛病**（蜂窝卡「…RSRP -78 dBm」尾行只剩 dBm、TS 卡「线」），已在 v0.3 修正 | 定为排版硬规则：① 键值行**一行一项**（不要把两个长串挤在一行）；② 长文案控制在「换行后不出现 1–2 字尾行」；③ 网页端 `text-wrap: pretty` 兜底，App 侧靠短文案 + 显式换行；④ 评审基线增加「孤字检查」项 |

**R11 的连带影响**：AT 页把「蜂窝」从只读+控制升级为**调试面**，需要 app-api 的动作条目再加 `qmodem.send_at`（参数：`config_section`/`at`/`port`，字符集与长度校验、超时、审计），并按能力协商隐藏（部分机型 `get_at_cfg` 无可用端口）。

## 11. 变更记录

*v0.3 2026-10-18 —— **R2 反馈轮**（用户 6 条反馈 → §10 逐条评估）：AT 调试页（预置命令与网页端同源 `get_at_cfg.cmds`，含语言坑与 fork 建议）；dashboard 卡片风格统一；**悬浮 tab 栏 + 毛玻璃 + 小白条**（预览全屏生效）；折线改 Catmull-Rom 平滑（附同数据两种画法对比条）；概览/dashboard 网络卡加 IPv4/v6 打码显示（需契约加法 `net.wan.ipv6`）；孤字换行列为排版硬规则并修正预览自身两处。预览扩至 **十三屏 + dashboard v2 看板 + 对比条**。*

---

## 11. R3 反馈评估（2026-10-18 第三轮 → 逐条评估与落点）

| # | 用户反馈 | 评估 | 建议 / 落点 |
| :-- | :--- | :--- | :--- |
| R17 | **折线还是丑，「像树枝」；要整体很圆滑的曲线** | **我的 R14 方案只对了一半**——只把折角插值成曲线，噪声本身还在，插值越平滑越像树枝。根因是**没有对数据做平滑/降采样** | 三步走：① **先 EMA 平滑原始序列**（α≈0.3）；② **等距降采样**到 ~13 点（60 点环形缓冲 → 每 4–5 点均值）；③ 再做 Catmull-Rom → 三次贝塞尔 + `round` 端点。预览 ⑬ 底部对比条即「原始噪声 + polyline」vs「EMA+降采样+曲线」同一组数据。WP-3 `primitives.js` 的 `Sparkline` 增加「平滑窗口」参数；App `CustomPainter` 同法 |
| R18 | **dashboard 的 bandix 卡片把之前确定的功能弄丢了** | **属实，是我简化过度**：漏掉了连接/DNS 摘要、默认限速、白名单·规则·配额计数、五列设备表（下行/上行/累计/限速策略）与脚注深链 | 以 `BandixCard.vue` 现有实现为准**整卡恢复**（预览 ⑬ 流量明细卡逐项对齐：在线 9/12 · 连接 128（TCP 96·UDP 32）· DNS 45231 · 默认限速 ↓1.0 Mbps ↑不限 · 白名单 开·规则 3·配额 1·设备 1 · 表 4 行 + 策略徽标 + 脚注）。**规则加固**：以后改 dashboard 卡面，一律以 `frontend/src/components/cards/*.vue` 为唯一事实源，先读源码再画 |
| R19 | **App 概览与 dashboard 的 qmodem 信息太简略** | 同意——蜂窝是这类设备（FNet3399 是 5G CPE）的主 WAN，信息密度应当高于普通卡片 | App 概览卡：模组型号 + 温度、注册态 + 质量条、**RSRP/RSRQ/SINR/RSSI 四指标条**、RSRP 历史曲线、服务小区、拨号时长与地址、上下行速率与本月流量（预览 ⑩）。Dashboard 卡（宽屏）：四栏——**信号**（质量条 + 四指标 + 曲线）/ **服务小区**（PCC LTE B3 · ARFCN 1300 · PCI 293、LTE 带宽、NSA NR n78 · ARFCN 627264、NR 带宽 · SCS、邻区、模式偏好）/ **拨号**（状态 · 时长、IPv4、速率、APN、DNS、MTU）/ **流量与 SIM**（本月、重置计划、SIM、短信存储、未读、模组页深链），标题行带型号与固件（预览 ⑬）。字段全部来自 `qmodem` 既有读方法，无需新 API |
| R20 | **tab 栏做成胶囊样式** | 采纳（在 R13 悬浮 + 毛玻璃基础上） | 外层整条 = 全圆角胶囊（`border-radius: 999px`，左右内缩 14、高 62）；**选中项 = 内层小胶囊**（accent 16% 淡底 + 34% 描边），未选中无底色；底部为小白条留白（预览全屏已生效） |

**连带结论**：R17 的算法修正同时改变了 R14 的验收口径——**验收看的是「曲线整体是否柔和」而不是「折角是否被抹平」**，因此 WP-3 的基线截图与 §5.2 硬规则需同步改写为「EMA 平滑 + 降采样 + 圆滑插值」。

## 12. 变更记录

*v0.4 2026-10-18 —— **R3 反馈轮**（用户 4 条 → §11 逐条评估）：折线改为 **EMA 平滑 + 等距降采样 + 圆滑插值**（R17，附同数据对比条）；**整卡恢复 Bandix 卡**全部既有字段（R18，并加固「以 .vue 源码为唯一事实源」的规则）；**qmodem 信息加详**（R19：App 概览四指标 + 曲线 + 小区/拨号/流量；dashboard 四栏 + 型号固件）；tab 栏改**胶囊**样式（R20：外层胶囊 + 选中内层胶囊）。预览扩至 **十三屏 + dashboard v2 看板 + 折线对比条**。*

---

## 13. 决策记录（2026-10-18 R4 拍板：全部闭环）

| # | 事项 | 拍板 |
| :-- | :--- | :--- |
| D1′ | tab 命名 | **「路由器」**（原「网络」）；App 内**「上网设备」保留原名**（不再改「终端」） |
| D2′ | 配置面路线 | **按推荐**：受控注册表（**按节完整注册**）+ 仅对「确实无 API 的插件」用网页端深链兜底；不内嵌 WebView |
| D3′ | 启动流 | **按推荐**：冷启动进连接页、点选后进控制界面；**后台回前台保留当前会话** |
| D4′ | AT 调试开放度 | v1 **藏进「高级」 + 二次确认 + logd 审计**；**命令面不缩水**——网页端能发的 App 都能发（含 IMEI 等），界面**只做风险警告**（用户自担风险，我们只提供既有的工具） |
| D5′ | Docker | **适配器要做**（容器 / 镜像 / 日志 / 启停 / 删除） |
| D6′ | OpenClash | **只做容易实现且不易出错的**：启停 / 配置切换 / 核心与规则更新；节点选择等留给网页端 |
| D7′ | 安装新包 | **与网页端软件包页贴合**（按名搜索可用源 + 安装 + 依赖结果回显 + 记入操作记录） |
| D8′ | 多模组切换 | **顶部切换器**（segmented，1 个模组时隐藏） |
| D9′ | IPv6 展示 | **取分配的公网地址（GUA）**，不取 ULA / 临时地址 |
| D10′ | 其余 | 按推荐：蜂窝门控**粘性**、接受占用第 5 tab 位、蜂窝**先行**、qmodem 读面走 daemon 慢车道、跨 WP 登记、推送/通知 **v1 不做（仅 RFC 层面定通道）**、概览「编辑」保持后置（机制先支持）、毛玻璃浅色/壁纸复核归 WP-2 |

## 14. 配置面字段清单（试点：接口 / 无线）——口径与首个切片

**提取方法（保证与网页端同源）**：字段清单不手写，从 LuCI 自身定义提取——
`feeds/luci/modules/luci-mod-network/htdocs/luci-static/resources/view/network/*.js` 的 `s.tab()` / `s.taboption()`，
协议字段取自 `feeds/luci/protocols/luci-proto-*/.../protocol/<proto>.js`，
默认值以基座 UCI 配置（`package/network/config/*/files/etc/config/*`）为准。

**三条结构性结论（决定注册表形态）**：

1. **接口页字段 = 协议的函数**：`network.<iface>.proto` 一变，可见字段整组替换（静态 / DHCP / PPPoE / QMI / MBIM …）。⇒ 注册表必须**按「协议 × 字段」注册**，且只注册固件实装的协议模块（出厂含 `luci-proto-ppp`、`luci-proto-ipv6`；`qmi/mbim/ncm` 等随 qmodem 链进设备层）。
2. **无线页分两段**：**无线电（device）**与**接口（iface）**，前者含**复合控件**（`band` + `channel` + `htmode` 三合一；可用信道来自运行时 regdb/iwinfo）与运行时枚举（`txpower`、`country` 列表）。⇒ 注册表要支持 `composite` 类型与「运行时枚举提供者」。
3. **并非都是值字段**：扫描、状态弹层、QR 分享、切换协议按钮等是**动作/自定义控件**。⇒ 条目分四类：`value`（文本/数值）/ `enum`（ListValue/RichListValue）/ `bool`（Flag）/ `action`（按钮与命令），另加 `composite`。

**试点切片（接口 · 通用段，字段名即 UCI 键）**：

| 分组（对应网页端 tab） | 字段（类型） |
| :--- | :--- |
| 常规设置 | `proto`（enum，**驱动整组字段**）、`device`（设备选择）、`disabled`（bool）、`auto`（bool，"开机自动启用"） |
| 高级设置 | `delegate`（bool，内置 IPv6 管理）、`force_link`（bool） |
| 物理设置 | `_net_device`（设备选择）、桥接端口 / 桥接 VLAN（复合子表） |
| 防火墙设置 | `_zone`（区域选择，写入 `firewall` 配置） |
| DHCP 服务器 | 见下方 DHCP/DNS 节（该 tab 直接编辑 `dhcp` 配置的对应 section） |
| 协议字段（静态） | `ipaddr` / `netmask` / `gateway` / `dns`（值/列表）、`ip6addr` / `ip6gw` / `ip6prefix`（IPv6 组） |
| 协议字段（DHCP 客户端） | `hostname` / `clientid` / `vendorid` / `broadcast` / `reqopts` / `defaultreqopts`（值/bool）、`peerdns` / `dns`（bool/列表）、`ipv6` / `reqaddress` / `reqprefix`（IPv6 组） |

**试点切片（无线）**：

| 段 | 分组 | 字段（类型） |
| :--- | :--- | :--- |
| 无线电 device | 常规 | `disabled`（bool）、`txpower`（运行时枚举）、`country`（运行时枚举）、`legacy_rates`（bool）、`band` + `channel` + `htmode`（**composite**，可用信道运行时枚举） |
| 无线电 device | 高级 | `cell_density`（enum）、`distance` / `frag` / `rts` / `beacon_int`（值）、`noscan` / `vendor_vht` / `rxldpc` / `ldpc`（bool） |
| 接口 iface | 常规 | `mode`（enum：ap/client/mesh/adhoc/monitor）、`ssid` / `bssid`（值）、`network`（网络选择）、`hidden` / `wmm`（bool）、`mesh_id`（值） |
| 接口 iface | 加密 | `encryption`（enum，驱动密钥字段组）、`cipher`（enum）、`key`（值，**敏感**）、`ppsk`、RADIUS 组（`auth_server` / `auth_port` / `auth_secret` / `acct_*`）、`dynamic_vlan` 等（enum/bool/值） |
| 接口 iface | MAC 过滤 | `macfilter`（enum）、`maclist`（列表） |
| 接口 iface | 高级 | `isolate` / `bridge_isolate` / `short_preamble` / `disassoc_low_ack` / `skip_inactivity_poll`（bool）、`dtim_period` / `wpa_group_rekey` / `max_inactivity` / `max_listen_interval`（值）、`ifname` / `macaddr`（值） |
| 接口 iface | 漫游 | 802.11r/k/v 组（`ieee80211r` / `ieee80211k` / `ieee80211v`、`nasid`、` mobility_domain`、`r0kh` / `r1kh` 列表等） |

**剩余节的处理**（同一方法，逐个提取并评审）：DHCP/DNS（`dhcp` 配置：`start`/`limit`/`leasetime`/`dhcp_option`/`ra_*`/`dhcpv6*`/`ndp`/`dns`/`domain`/静态租约 `host` 子表）、防火墙（`firewall` 配置：zone / forward / rule / redirect / `defaults`）、系统（`system`：`hostname` / `timezone` / `zonename` / `log_*` / `ntp` / `led` / `cronloglevel`）、管理权（rpcd/dropbear/密码 —— 密码与密钥走**动作**而非字段）、启动项（`rc` 启用态 —— 全动作，无字段）、静态路由（`route`/`rule` 子表）。

**待办**：以上清单评审通过后，即作为 `config.*` 注册表的实现输入（WP-5），并作为 App 侧表单页的字段对照表（WP-6）。

## 15. 变更记录

*v1.0 2026-10-18 —— **R4 拍板，全部决策闭环**（§13 十条）：tab 定名「**路由器**」、上网设备保留原名；配置面按推荐（按节完整注册 + 无 API 才深链）；启动流按推荐（冷启动进连接页）；AT 调试「藏高级 + 二次确认 + 审计 + 风险警告，**命令面不缩水**」；Docker 适配器做；OpenClash 只做低风险子集；安装新包贴合网页端；多模组顶部切换；IPv6 取公网 GUA；其余按推荐。新增 **§14 配置面字段清单（试点：接口 / 无线）** 与提取方法、三条结构性结论（协议驱动字段组 / 复合控件与运行时枚举 / 值-枚举-布尔-动作四类）；预览同步改名与决策标注。*
