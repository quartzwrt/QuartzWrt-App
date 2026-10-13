# Changelog

版本与 `pubspec.yaml` `version`、`lib/core/version.dart` 同步维护（DESIGN §9）。

## 0.1.0 — 2026-10-13

首个开发版（W6.1–W6.6；W6.7 真机验收待做）：

- **W6.1** 工程骨架与 CI（analyze/test；tag 出 release APK + Release 附件）；主题 token（WP-2 同源）；zh/en i18n。
- **W6.2** 局域网发现（mDNS `_quartz-app._tcp`）；配对（TOFU + sha256(DER) 证书 pin + 管理员密码一次输入）；令牌（access 内存 / refresh 安全存储 / 单飞刷新防旋转复用自吊销）。
- **W6.3–W6.4** 四 tab 界面（概览/网络/应用/设置）与快照轮询（前台 5s / 后台停取 / 四态降级）；应用页双子段（控制面 + 软件包面降级）；控制面动作（重启/服务启停/设备吊销）。
- **W6.5 远程链路**：远程访问引导页（路由器端 Tailscale 真实状态与 tailnet 地址、四步引导）；手动添加 tailnet 远程地址（严格 pin 的 `info` 测试后保存）；**远程识别徽标**（已连接 · 局域网 / 远程）；端点传输级失败自动切换（局域网优先、回前台探测切回）。
- **W6.6 打磨**：品牌启动图标（切面宝石，自适应/单色/遗留位图）与启动屏（双模底色）；tab 状态保留（`StatefulShellRoute.indexedStack`）；详情页上滑淡入过渡；次要文字对比度与 tab 语义标注；文案定稿；版本单一来源 + 本 CHANGELOG。
