# Changelog

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
