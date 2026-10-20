# Changelog

## 0.7.1 — 2026-10-19

- **蜂窝首页中文化**：射频参数 / 小区与 SIM / 连接 / 硬件四栏的字段名全部改为中文
  （频段、频点、物理小区、上下行带宽、子载波间隔、双工方式、跟踪区、小区 ID、SIM 状态/槽位、
  可切换、CQI/AMBR 上下行、USB 拨号模式、网络偏好、厂商、版本、AT 端口、电压、温度、连接状态）。
- **状态值中文化**：SIM `ready` → 就绪；`Yes/No` → 是/否；连接状态 `Yes/No/connected`
  → 已连接/未连接；邻区 `unlock/locked` → 未锁定/已锁定，`intra/inter` → 同频/异频。
- 技术缩写（PCI/ARFCN/MCC/MNC/TDD/NR/LTE/CQI/AMBR）保留原文。analyze 零告警、99 测试全绿。
- **外观壁纸修复**：壁纸路径接入应用全局背景（此前只在设置页预览生效）；同一路径换图后失效图片缓存；超过 2 MB 的图片拒绝保存并给出提示。
- **UI 门禁补齐**：蜂窝高级页 USB 模式选择由 Material `ChoiceChip` 改为 `QzChoiceChip`；`tool/ui_lint.dart` 增补 ChoiceChip/FilterChip/Checkbox/Radio/Slider/DropdownButton/Card 等禁用项，防止同类回归。

## 0.7.0 — 2026-10-19

- **QModem 功能层级对齐网页端**：蜂窝首页入口改为「拨号 / 高级模组设置 / 短信与 SIM」分组
  （拨号日志、网络配置、邻区信息、AT 调试、模组维护、短信、SIM），不再使用平铺宫格；
  与网页端 QModem Information / Dial Overview / Advance Modem Settings / SMS / SIM 的层级对应。
- **AT 调试补齐（网页端 AT Debug 同款能力）**：端口选择包含 `ports` / `other_ttys` 并标注
  “无效/非本模组”；预置命令与网页端同源；发送、二次确认、累积输出（命令 + 端口 + 响应 +
  错误）、清空输出、清空命令。加载拆为「快照 `at_port` + `tty_ports` 快路径」与后台 `at_cfg`，
  避免上游端口探测慢时整页白屏；预置命令随后补齐。
- **邻区信息页**：读取 `qmodem.neighborcell`，按 LTE/NR 展示 PCI/ARFCN/RSRP/RSRQ 与锁小区状态；
  App 只读（小区锁定仍归网页端）。
- **流量重置计划**：模组维护页新增启用/每天/每月/小时/日设置，写
  `qmodem.set_traffic_reset_schedule`，实时回显并刷新概览卡的重置计划文案。
- **InfoBanner 修复**：圆角 + 非均匀边框在 Flutter 中直接抛
  `A borderRadius can only be given on borders with uniform colors`，导致提示框整块白底不显示文字；
  改为统一边框 + 内层左侧色条，AT/邻区/防火墙/维护等提示恢复正常。
- **路由器 tab VM 验收**：VM 升级到 app-api r13（cron/firewall/fstab/dropbear 注册表）；
  `vm-accept-config.sh` 17/17、`vm-accept-router.sh` 15/15；AVD 逐页走查接口/无线/DHCP/静态路由/
  防火墙/系统/启动项/挂载/计划任务/LED/上网设备，并在 VM 实测计划任务写入 + 清理。
- 验证：analyze 零告警、99 测试全绿；App v0.7.0 (16)。

## 0.6.2 — 2026-10-19

- **蜂窝 KPI 等高**：概览蜂窝卡与蜂窝 tab 的「信号 / 速率」及「本月用量 / 服务小区」两行改为
  `IntrinsicHeight + stretch`，同一行两张卡底边对齐；信号卡多出的副文本/RSRP 曲线不再把速率卡压短。
- **IP 展示对齐 Dashboard `IpValue`**：新增 `QzIpValue`（虚线底、点按展开/收起、Tooltip），
  打码口径改为 Dashboard 同款（IPv4 `10.9.*.*`、IPv6 前两组 + `:*:*:*:*:*:*`）。
  接入概览 Hero WAN、网络卡 IPv4/IPv6、蜂窝详情 IPv4 与拨号卡；`maskAddress` 委托 `maskIp`。
- 验证：analyze 零告警、99 测试全绿；AVD 实测点按 IPv4/IPv6 展开与收起、两处 KPI 等高。

## 0.6.1 — 2026-10-19

- **系统卡对齐与占比条**：`KvRow` 非占比行改为「标签 + 右侧自适应值列」，负载/进程/交换/温度
  与 CPU/内存/存储数值统一右缘；三条占比条固定同一起止点；存储条改回 accent（不再用绿色）；
  数值列用 `FittedBox` 缩放兜底，长值不截断；补交换分区行（未启用灰显）。
- **概览卡补齐 Dashboard 数据密度**：Bandix 卡增加连接（TCP/UDP）与 DNS 摘要，设备行改为
  「名称 + 策略 + 下行/上行/累计」；Docker 卡增加引擎状态/版本/驱动/根目录、容器列表
  （名称/镜像/状态/状态文本）；服务卡补 quartz-daemon（采集周期/耗时）；蜂窝概览卡速率拆为
  下行/上行两列并对齐 Dashboard（运营商 PLMN → 名称、重置计划文案、信号单位）。
- **蜂窝 tab 与 Dashboard QModem 卡对齐**：状态头显示运营商名称；速率 KPI 拆下行/上行；
  信号副行带单位并固定两行；本月用量显示重置计划；IPv4 在 dial 为空时回退 WAN IPv4；
  详情四栏补 UL/DL BW、CQI、AMBR、MCC/MNC、TAC、Cell ID、AT Port、Voltage、Connect Status。
  数据模型补齐 daemon 2026-10-19 加法字段（`cell_info`、`network_type`、`at_port` 等）。
- **文本框白底修复**：`QzField` 的 `CupertinoTextField` 显式 `decoration: null`，去掉内层
  默认白底圆角框，仅保留 Quartz 外框；深/浅双模表单实测一致。
- 验证：`flutter analyze` 零告警；`flutter test` 99/99；`dart run tool/ui_lint.dart` 通过；
  AVD 深/浅双模复核（概览上/中/下、蜂窝、管理权表单）。

## 0.6.0 — 2026-10-19

- **UI 基座重建（Dashboard 卡面）**：token/主题改为显式色板 + 系统/等宽/衬线字体栈；卡片统一
  `panel + 1px 描边 + 12px 圆角 + 14/16 padding`，标题 13/600 次级色；Hero 改衬线主机名 +
  Uptime/WAN/Collected；系统/网络卡改 KV 行 + 内联 6px 占比条 + 等宽数值；网络卡大号上下行 +
  EMA/降采样/Catmull-Rom 平滑曲线；蜂窝新增概览卡（KPI 2×2）；底部 tab 改平底 chrome。
- **Quartz UI kit**：按钮/输入/选择/开关/复选/页签/分段/chip/占比条/滑块/加载/下拉刷新/底部层/
  Toast/图标全部走 `lib/widgets/quartz/`；feature 层 Material 可见组件由 `tool/ui_lint.dart` 拦截。
- **本机外观设置**（`/settings/appearance`）：外观模式（跟随系统/深色/浅色）、界面不透明度
  50–100%、模糊强度 0–40px、本机壁纸（选择/更换/移除，≤1920px/JPEG/≤2MB，默认石英噪点）；
  实时预览；**不写路由器 `/etc/config/quartz`、不上传壁纸**。`image_picker` + 应用私有目录。
- 动效：按压 90ms scale .975/opacity .9、开关 180ms、复选/单选 140–160ms、页签 180ms、
  底部层 240/180ms、Toast 160/180ms、页面 220/160ms、进度 300ms；无 Material ripple。
- 验证：`flutter analyze` 零告警、`flutter test` 96/96；AVD 深/浅双模走查（概览/路由器/应用/
  蜂窝/设置/外观）。

版本与 `pubspec.yaml` `version`、`lib/core/version.dart` 同步维护（DESIGN §9）。

## 0.4.0 — 2026-10-17

- **bandix 流量面（WP-8 bridge 链路 L2/L3）**：应用列表 bandix 行富化（在线设备数，
  数据 = 快照 `bandix` 节，与 Dashboard 同字节）；应用详情新增「流量与限速」卡
  （在线/速率/连接/DNS 摘要 + 动作条目）；新增**流量明细页**（`/apps/bandix`：
  摘要 + 设备流量 Top≤8 + 下拉刷新）。
- **动作条目（WP-5「ubus 转发项」链路）**：默认限速（KB/s 显示 → Byte/s 转发）、
  限速白名单（开关 + 增删）、主机名绑定（从在线设备快选 MAC）三个底部对话框；
  当前值经唯一读条目 `bandix.limits` 读取；写动作经 `bandix.*` 转发项。
- 机制：`lib/features/registry.dart`（UI-DESIGN §4.2 `ServiceRowSpec` 首个落地——
  列表富化 / 详情扩展单点注册）；模型层 `Snapshot.bandix/bandixTop` 容忍解析。
- **限速策略轮（用户反馈）**：详情卡与流量明细页删「WAN 速率」行（与概览「网络」卡
  重复）；新增**总体限速策略**（默认限速 ↓/↑ + 白名单开关 + 规则/配额/设备计数，
  数据 = 快照 `bandix.limits`）；设备列表改「速率（设备侧 WAN，B/s 口径）+ 累计·占比
  + 限速策略徽标」（白名单/限速 N/配额/默认，优先级取值；完整规则在网页 Bandix 页）。
- 测试 77 项（模型容忍/富化行文本/详情卡与不可用态/流量页与不可用态/速率与策略徽标）；
  App v0.4.0（构建 5）。

## 0.3.0 — 2026-10-14

- **软件包管理面（WP-5 `packages` 扩展的 App 侧落地）**：应用 tab「软件包」子段——可升级
  （版本 diff + 单包/全部升级）/ 已安装（版本·大小，行内升级/卸载）/ 全部（名称搜索，含
  已安装徽标）；「刷新索引」（apk update）；「操作记录」页（升级/卸载/刷新结果与失败原因，
  近 30 条，失败附 apk 错误摘录）；应用详情新增「软件包」卡（版本/占用/可升级→单包升级）。
- 数据层 `lib/api/packages.dart`（契约容忍解析：错类型/缺字段降级不抛）；危险动作（卸载、
  全部升级）走底部确认层；分页「加载更多」。
- 旧固件（quartz-app-api < v1.1，无 packages 方法）→ 软件包面降级说明卡（行为保持）。
- 测试 71 项（新增 14：模型容忍/分页累积/四态渲染/动作链路/错误分类）；`tool/e2e_vm.dart` 增软件包
  四 scope 链路与 history 形态断言；对真固件 ALL PASS。
- **走查修复**：重刷固件换证书后，严格 pin 的握手失败被 Dio 归为通用传输错误（'transport'）
  → 只弹「连接中断」自动重试、不提示重配对。现按底层 `HandshakeException` 判定为
  `bad_certificate` 并映射 needRepair（「配对已失效，请重新配对」横幅）——DESIGN §3.4 阻断语义补齐。

## 0.2.0 — 2026-10-13

- **内嵌直连（实验）**：App 进程内嵌 tailnet 节点（tsnet userspace）+ 本地 CONNECT 代理——
  手机无需安装 Tailscale 客户端即可经 tailnet 远程管理路由器；设置→远程访问新增开关与登录引导；
  远程端点连接顺序 = 内嵌代理 → 直连 → 局域网回退。发布只带 arm64-v8a；`native/tailnet/`
  引擎（c-shared，Dart FFI）+ `scripts/build-native.sh`；`config.json` 为本地联调钩子。
- 远程访问页新增「内嵌直连」卡（可用性/状态/本机 tailnet 地址/登录按钮/复制链接）。
- 版本 0.2.0（构建 2）；新增 `THIRD_PARTY_NOTICES.md`（BSD-3-Clause 等的分发声明）。

## 0.1.0 — 2026-10-13

首个开发版（W6.1–W6.6；W6.7 真机验收待做）：

- **W6.1** 工程骨架与 CI（analyze/test；tag 出 release APK + Release 附件）；主题 token（WP-2 同源）；zh/en i18n。
- **W6.2** 局域网发现（mDNS `_quartz-app._tcp`）；配对（TOFU + sha256(DER) 证书 pin + 管理员密码一次输入）；令牌（access 内存 / refresh 安全存储 / 单飞刷新防旋转复用自吊销）。
- **W6.3–W6.4** 四 tab 界面（概览/网络/应用/设置）与快照轮询（前台 5s / 后台停取 / 四态降级）；应用页双子段（控制面 + 软件包面降级）；控制面动作（重启/服务启停/设备吊销）。
- **W6.5 远程链路**：远程访问引导页（路由器端 Tailscale 真实状态与 tailnet 地址、四步引导）；手动添加 tailnet 远程地址（严格 pin 的 `info` 测试后保存）；**远程识别徽标**（已连接 · 局域网 / 远程）；端点传输级失败自动切换（局域网优先、回前台探测切回）。
- **W6.6 打磨**：品牌启动图标（切面宝石，自适应/单色/遗留位图）与启动屏（双模底色）；tab 状态保留（`StatefulShellRoute.indexedStack`）；详情页上滑淡入过渡；次要文字对比度与 tab 语义标注；文案定稿；版本单一来源 + 本 CHANGELOG。
