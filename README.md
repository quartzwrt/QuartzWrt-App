# QuartzWrt App

QuartzWrt 专属移动端（Flutter）：局域网 mDNS 自动发现、安全配对、状态展示与白名单设备控制，经 Tailscale/ZeroTier 远程管理。

**当前状态**: **v0.5.0（构建 10）** —— 发现/配对/令牌 · 内嵌直连（tsnet）· 蜂窝 tab（W6.12–W6.14）· **路由器 tab W6.9/W6.10**（首页/系统/启动项/接口/无线/DHCP·DNS + `config.*` 90s 确认条）。W6.11（防火墙/静态路由/管理权/挂载/计划任务/LED/静态租约）与 W6.7 真机验收待做。设计规范 [`docs/DESIGN.md`](docs/DESIGN.md) v1.1 / UI 设计 [`docs/UI-DESIGN.md`](docs/UI-DESIGN.md) **v2.0（IA v2）**；交接见 [`docs/HANDOFF.md`](docs/HANDOFF.md)。

- **远程链路（W6.5）**：路由器端 Tailscale 状态/tailnet 地址直读快照真数据（设置 →「远程访问」引导页）；手动添加 tailnet 地址（严格 pin 实测连通才保存）；概览/设置显示「局域网｜远程」识别徽标；连接传输级失败自动切换端点、回前台探测切回。
- **内嵌直连（实验）**：`native/tailnet/` 引擎（tsnet userspace + 本地 CONNECT 代理，c-shared `libtailnet.so`，Dart FFI）——手机不装 Tailscale 客户端也能经 tailnet 远程访问路由器；无 VPN 权限/不改系统网络。开关在设置→远程访问。本地构建：`scripts/build-native.sh`（Go + NDK，产物入 `android/app/src/main/jniLibs/`）；spike 依据与选型见 `dev/spike/tailscale/RESULTS.md`，许可声明见 `THIRD_PARTY_NOTICES.md`。

## 依赖与边界

- 路由器侧 `quartz-app-api`（[WP-5](https://github.com/quartzwrt/QuartzWrt-Packages)）+ `quartz-daemon`；数据契约 `AGGREGATE-API v1`（与 Dashboard 同源）。
- 接口面：ubus 对象 `quartz-app-api`（info/login/refresh/logout/status/action/devices/revoke/packages + `config.*`），HTTPS 443 `/ubus` JSON-RPC；配置面 `config.apply` + 90s 确认条（`config.rollback` 立即回滚）。

## 开发（DESIGN §9-D10：WSL 内构建，与 CI 一致）

```sh
# Flutter SDK: stable 3.47.7（与 .github/workflows/build.yml 的 FLUTTER_VERSION 对齐）
flutter pub get
flutter analyze
flutter test
flutter build apk --release        # 需要本机 Android SDK/JDK；CI 亦有此步
```

- 真机/模拟器调试：Windows 侧 Android Studio 或真机安装 `build/app/outputs/flutter-apk/` 产物（WSL 内 AVD 走查记录见 `design/shots/emu-w65/`）。
- VM 联调：`QuartzWrt-Builder/scripts/test-in-vm.sh --detach`（宿主 8443→VM:443 即 API）。
- 内嵌引擎构建：`ANDROID_NDK_HOME=<ndk> scripts/build-native.sh`（缺省 arm64-v8a + x86_64）；本地 E2E 工具见 `native/tailnet/e2e/`（headscale + mock 路由器）。

## 目录

```
lib/
├── main.dart        # 应用入口
├── core/            # 主题 token（与 WP-2 同源）/ 版本单一来源
├── api/             # transport（dio+信封解析）/ 端点与故障切换 / 模型 / config.* / luci.*
├── auth/            # 配对（TOFU+pin）/ 令牌（单飞刷新）
├── discovery/       # mDNS 发现
├── storage/         # 路由器注册表 + 令牌安全存储
├── state/           # Riverpod providers（端点/令牌/快照轮询/外观）
├── features/        # tab：overview / router / apps / cellular（条件）/ settings（含远程访问 ⑬）/ shell
├── widgets/         # Quartz 通用组件（卡片/状态点/Segment/确认层）
└── l10n/            # arb（en/zh）+ 生成物
design/              # 设计预览 + 截图脚本（shot.py / gen_icons.py）
dev/spike/tailscale/ # 内嵌 tailscale spike（probe / androidlib / cmdlib / RESULTS.md）
tool/e2e_vm.dart     # 对 VM 真固件的端到端链路验证
```

## 发布

- CI：push/PR → analyze + test；tag `v*` 或手动 → release APK 附件到 GitHub Release。
- 签名：仓库 Secrets（`KEYSTORE_BASE64/KEY_ALIAS/KEY_PASSWORD/STORE_PASSWORD`）存在即用；缺席回落 debug 签名（仅内部验证）。
