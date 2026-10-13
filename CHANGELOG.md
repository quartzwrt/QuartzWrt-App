# Changelog

版本与 `pubspec.yaml` `version`、`lib/core/version.dart` 同步维护（DESIGN §9）。

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
