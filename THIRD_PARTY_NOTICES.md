# 第三方组件与许可声明（QuartzWrt App）

本应用随包分发以下第三方组件。完整许可文本随各自源码分发；发布物（GitHub Release 附件/APK）
应保持本清单同步更新。

## 内嵌 tailnet 引擎（`native/tailnet` → `libtailnet.so`）

内嵌引擎基于 Tailscale 的开源客户端构建（`tailscale.com`，Go 模块），以 **userspace 模式**
（tsnet）在应用进程内提供 tailnet 连接；本应用与 Tailscale, Inc. 无隶属或背书关系。

| 组件 | 许可 | 说明 |
| :--- | :--- | :--- |
| `tailscale.com` | **BSD-3-Clause** | 客户端核心（tsnet / wgengine / netstack 集成等） |
| `gvisor.dev/gvisor` | Apache-2.0 | userspace TCP/IP 网络栈（netstack） |
| `golang.zx2c4.com/wireguard`（wireguard-go，经 tailscale 依赖） | MIT | WireGuard 用户态实现 |
| `golang.org/x/{crypto,net,sys,text,...}` | BSD-3-Clause | Go 官方扩展库 |
| `filippo.io/edwards25519`、`github.com/…`（见 `go.sum`） | 各自开源许可（多为 BSD-3/MIT/Apache-2.0） | 传递依赖 |

完整依赖树与版本锁定：`native/tailnet/go.mod` / `go.sum`。BSD-3-Clause 要求保留版权声明与免责
条款——发布 APK 时请附带本文件；如需逐依赖完整文本，可在构建机上执行
`go run github.com/google/go-licenses@latest report ./csdk`（需联网）生成全量表。

## Flutter 侧

| 组件 | 许可 |
| :--- | :--- |
| Flutter SDK（引擎运行时） | BSD-3-Clause |
| `flutter_riverpod` / `go_router` / `dio` / `multicast_dns` / `flutter_secure_storage` / `shared_preferences` / `path_provider` / `url_launcher` / `ffi` / `intl` / `crypto` | 各自开源许可（MIT / BSD-3-Clause / Apache-2.0） |

详见 `pubspec.lock` 与各包仓库。

## 商标

「Tailscale」为 Tailscale Inc. 的商标。本应用在界面上以「内嵌直连（基于 Tailscale）」等
描述性措辞说明其技术来源，不表示任何官方关联或背书。
