# 「App 内封 tailscale」Spike — 实测结果（2026-10-13）

**结论先行：可行（Go 路线），推荐 tsnet（userspace 网络栈）+ 本地 CONNECT 代理。**
tailnet 节点可以直接活在我们 App 的进程里、只服务 App 自己的连接：**不需要 VpnService / 整机 VPN、不需要 root，也不需要用户安装 Tailscale 移动端 App**（交互式登录 URL 在应用内完成）。DESIGN §10 **D8 当年「No-Go：依赖其移动端登录体系」的理由被实测推翻**——登录只依赖浏览器，不依赖 Tailscale App。
定位：**v1.5+ 增强项**（v1 已交付的「手动 tailnet 地址 + 手机 Tailscale 客户端」仍是默认路径，见 W6.5）；本 spike 只出结论与集成设计，不在 v1 落地。

## 四条机制性发现（本机实测，非文档推断）

1. **tsnet 在进程内起真节点并产出交互式登录 URL**（`probe/`，linux/amd64，`tailscale.com v1.104.1`）：
   `BackendState=NeedsLogin` → `AUTH_URL=https://login.tailscale.com/a/…`（一次运行日志两行见下），全程无 VPN 权限、无守护进程、无 Tailscale App。
   ```
   tsnet starting with hostname "quartz-app-spike"
   LocalBackend state is NeedsLogin; running StartLoginInteractive...
   AUTH_URL=https://login.tailscale.com/a/d4be9c0015ac2   →   RESULT=LOGIN_URL_OK
   ```
   实测该调用在用户的 tailnet 管理台生成一条**待批准设备**记录（未完成登录，可忽略/删除）。
2. **交叉编译到 Android arm64 成立且产物可直接用**：`cmdlib/`（NDK clang + `go build -buildmode=c-shared`）产出
   `libtailnet.so`：**未剥符号 30.4 MB / `llvm-strip` 后 21.7 MB**（arm64 单 ABI）；`llvm-nm -D` 核验导出
   `TailnetStart/LoginURL/State/LastError/Stop`；`libtailnet.h` 同出。Dart FFI（`DynamicLibrary.open`）或
   Android `jniLibs` 均可直接加载，无需 Java 胶水。
3. **两条打包路线都跑通，但 gomobile 摩擦明显、c-shared 更干净**：
   - `cmdlib/`（NDK clang + `go build -buildmode=c-shared`）→ `libtailnet.so`，**strip 后 21.7 MB**（arm64），
     `llvm-nm -D` 核验导出 `TailnetStart/LoginURL/State/LastError/Stop`；Dart FFI（`DynamicLibrary.open`）
     或 Android `jniLibs` 直接加载，零 Java 胶水。
   - gomobile bind → `tailnet.aar` **15.2 MB**（arm64，含 .so + classes.jar）**最终可用**，但踩了三处环境坑：
     ①绑定签名限「至多一个返回值 + error」（三返回值直接报 `too many result values`，已按此改签名）；
     ②Go 1.24+ 的 tool-dependency 规则下需 `go get golang.org/x/mobile` + `go run …/gomobile bind`（裸 `gomobile bind` 报 `missing golang.org/x/mobile dependency`）；
     ③gomobile 依赖系统 `javac`，而本机 `/usr/bin/javac` 是 JRE 残桩 → 报 `ClassNotFoundException: org.eclipse.jdt.internal.compiler.batch.Main`，把真 JDK（Temurin 21）放在 PATH 最前即通过。
     **结论：可打包，但环境敏感；自研路线优先 c-shared（或现成 Dart 包），gomobile 仅在需要 Java/Kotlin 绑定时才值得。**
4. **Android 上「整机 VPN」路线（官方 libtailscale）成本高且非我们所需**：libtailscale 是 tsnet 的 C 封装，
   在 Android 的第三方嵌入实践（如 BARGHEST-ngo/MESH）需要 `VpnService` + `BIND_VPN_SERVICE` 权限 +
   VPN fd → TUN 桥（multiTUN 式重实现）+ targetSdk 30 netlink 规避（tailscale#8126 / #7757 仍未收口）。
   我们只要 **App 自己**连路由器 → userspace 路线零权限、零平台胶水，语义也更准确（不接管整机流量）。

## 集成设计（推荐案，v1.5）

```
Flutter App 进程
├─ Dart 侧（业务面不变）
│   ├─ 端点含 100.x / MagicDNS 时：Dio 的 HttpClient.findProxy → 'PROXY 127.0.0.1:<port>'
│   ├─ TLS/证书 pin 端到端仍在 Dart 侧（与 W6.5 完全一致；代理只转发字节流）
│   └─ 登录页：展示 AuthURL（浏览器打开一次）→ 轮询 State() 直到 Running
└─ Go 侧（内嵌，一次随包编译）
    ├─ tsnet.Server（Hostname=quartz-app-<device>，Dir=App 私有目录存节点身份）
    ├─ 127.0.0.1 CONNECT 代理（s.Dial 出站，MagicDNS 在栈内解析，无需系统 DNS）
    └─ API：Start / LoginURL / State / Stop（c-shared 五函数，已核验导出）
```

- **登录**：交互式 URL（本 spike 验证的最小闭环）或 auth key / OAuth（后两者供高级用户/无人值守）。
- **不变量**：不请求 VPN/网络类权限；不改系统网络栈；失败可无缝回退到 W6.5 的手动地址路径。
- **依赖与合规**：`tailscale.com` 为 **BSD-3-Clause**（可嵌入商业应用）；**不得用 Tailscale 商标暗示背书**——UI 措辞用「内嵌直连（基于 Tailscale）」，产品名保持 QuartzWrt。
- **体积**：arm64 单 ABI `.so` 21.7 MB（strip 后；AAR 含 Java 胶水 15.2 MB 实测同量级）。APK 内 `extractNativeLibs=false` + 压缩后预计净增 **约 8–12 MB**（落地时实测）。若双 ABI 需 +2 倍。
- **构建链**：需要 Go（≥ 本 spike 的 1.25.4）+ NDK（本机 28.2）。现 CI 只有 Flutter → 建议仅在 tag/release 任务加装工具链；日常调试用预编译 `.so` 缓存。
- **备选（省自研）**：pub.dev **`tailscale` 0.9.0**（MIT；FFI + 原生构建钩子内嵌上游 tsnet；Android 12+ 支持持久节点；构建要求 Go ≥ 1.26）。取舍：省自研封装与维护 vs 引入 pre-1.0 三方依赖 + 构建链约束（Go 版本将被迫升级）；本 spike 的 c-shared 路线则完全自控。

## Android 实测补记（2026-10-13 落地实现时；上游 spike 未覆盖的平台层）

内嵌节点在模拟器（Android 16, x86_64）实跑暴露三处平台问题，生产实现（`native/tailnet/`）已全部内建修复：

1. `tsnet.Up: route ip+net: netlinkrib: permission denied` —— Android 禁应用 netlink（tailscale#2293/#8126）。
   修复：Dart(getifaddrs) → `TailnetSetInterfaces` → `netmon.RegisterInterfaceGetter`（与官方 Android 客户端同路）。
2. `panic: no safe place found to store log state`（logpolicy 无 /tmp 可写 → abort）。修复：`TMPDIR`/`XDG_CACHE_HOME` 指向状态目录。
3. SELinux 禁 `/proc/net/*`、`/sys/class/net`（avc denied）→ 前缀/MTU/MAC 推导 best-effort。

端到端验证（真 tailnet + mock 路由器 + 模拟器）：内嵌节点 Running（自有 tailnet IP，无 VpnService）→ 远程地址 100.x:443
经内嵌代理探测/保存/「使用中」→ 徽标「已连接 · 远程」+ 真数据 → 关闭开关自动回退局域网。
工具与复跑：`native/tailnet/e2e/`（mockrouter + client + run-local-e2e.sh）；证据 `design/shots/emu-embed/`。

## 复现步骤

```sh
cd dev/spike/tailscale
# ① 进程内节点 + 登录 URL（linux，需联网）
go run ./probe

# ② Android arm64 动态库（NDK 交叉编译）
CC=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android24-clang \
  CGO_ENABLED=1 GOOS=android GOARCH=arm64 go build -buildmode=c-shared -o libtailnet.so ./cmdlib
# 剥符号（体积 30.4MB → 21.7MB）
$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip --strip-unneeded libtailnet.so
```

注：首次需 `GOOS=android GOARCH=arm64 go mod tidy`（拉齐 Android 平台专属依赖），否则 c-shared 构建报 go.sum 缺项。

## 对后续的落地要求

- **DESIGN §7 / D8 修订**：D8 的 No-Go 理由更新为「v1 不做内嵌；spike 已验证可行，v1.5 以 tsnet userspace 路线评估落地」。
- **v1.5 触发条件**：用户反馈「不想装 Tailscale App」或需要免手动配置的远程直连；需先补 ACL/审批文档与体积实测。
- **CI 登记**：release 任务加 Go + NDK（仅 tag 路径），日常构建不引入。
- **与 WP-10 的关系**：路由器侧零改动（仍是标准 tailscale 服务端）；内嵌节点只是同一 tailnet 的又一个设备。
