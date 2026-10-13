# QuartzWrt App

QuartzWrt 专属移动端（Flutter）：局域网 mDNS 自动发现、安全配对、状态展示与白名单设备控制，经 Tailscale/ZeroTier 远程管理。

**当前状态**: W6.1 工程骨架（Flutter 工程 + CI + 主题/i18n 基座）；设计规范 [`docs/DESIGN.md`](docs/DESIGN.md) v1.0（定案）。

## 依赖与边界

- 路由器侧 `quartz-app-api`（[WP-5](https://github.com/quartzwrt/QuartzWrt-Packages)）+ `quartz-daemon`；数据契约 `AGGREGATE-API v1`（与 Dashboard 同源）。
- 接口面：ubus 对象 `quartz-app-api` 八方法（info/login/refresh/logout/status/action/devices/revoke），HTTPS 443 `/ubus` JSON-RPC。

## 开发（DESIGN §9-D10：WSL 内构建，与 CI 一致）

```sh
# Flutter SDK: stable 3.47.7（与 .github/workflows/build.yml 的 FLUTTER_VERSION 对齐）
flutter pub get
flutter analyze
flutter test
flutter build apk --release        # 需要本机 Android SDK/JDK；CI 亦有此步
```

- 真机/模拟器调试：Windows 侧 Android Studio 或真机安装 `build/app/outputs/flutter-apk/` 产物。
- VM 联调：`QuartzWrt-Builder/scripts/test-in-vm.sh --detach`（宿主 8443→VM:443 即 API）。

## 目录

```
lib/
├── main.dart        # 应用入口 + 未连接态首页（W6.2 接入发现/配对）
├── core/            # 主题 token（与 WP-2 同源）/ 常量
├── api/             # transport（dio + 信封解析）/ auth（W6.2）
├── l10n/            # arb（en/zh）+ 生成物
└── （discovery/ data/ features/ 随 W6.2+ 落地，DESIGN §2.2 分层）
```

## 发布

- CI：push/PR → analyze + test；tag `v*` 或手动 → release APK 附件到 GitHub Release。
- 签名：仓库 Secrets（`KEYSTORE_BASE64/KEY_ALIAS/KEY_PASSWORD/STORE_PASSWORD`）存在即用；缺席回落 debug 签名（仅内部验证）。
