# native/tailnet —— App 内嵌 tailnet 引擎

「内嵌直连」的 Go 引擎：**tsnet（userspace 网络栈）** 在 App 进程内起一个 tailnet 节点，
并暴露一个 **127.0.0.1 HTTP CONNECT 代理**；Dart 侧把目标 HttpClient 的 `findProxy`
指向该代理即可经 tailnet 访问路由器（100.x / MagicDNS）。**无需 VpnService、无 root、
不接管整机流量；TLS 与证书 pin 由 Dart 侧端到端完成。**

- 机制与选型依据：`dev/spike/tailscale/RESULTS.md`（c-shared 与 gomobile 双路实测）
- 依赖：`tailscale.com`（BSD-3-Clause，见仓库 `THIRD_PARTY_NOTICES.md`）；
  商标合规：UI 措辞「内嵌直连（基于 Tailscale）」，不得暗示官方背书

## 布局

```
tailnet.go       # 引擎：节点生命周期 / 状态查询 / CONNECT 代理 / 测试配置钩子
csdk/main.go     # c-shared 导出（libtailnet.so 的 C ABI，Dart FFI 直载）
probe/main.go    # 本机联调探针（go run ./probe，打印 AuthURL/状态）
```

## 构建（NDK 交叉编译 → Flutter jniLibs）

```sh
# 一次构建当前验证所需的 ABIs（arm64-v8a 发布目标 + x86_64 模拟器）
scripts/build-native.sh            # 在仓库根执行
scripts/build-native.sh arm64-v8a  # 只出发布 ABI
```

产物写入 `android/app/src/main/jniLibs/<abi>/libtailnet.so`（Flutter 自动打包）。
首次构建需 `GOOS=android GOARCH=<arch> go mod tidy`（build-native.sh 已内置）。

## Android 平台适配（实测踩坑，实现已内建）

Android 应用 UID 受限，tsnet 直接跑会失败，三处均已处理：

1. **netlink 被禁**（`tsnet.Up: route ip+net: netlinkrib: permission denied`）：`netmon` 枚举本机接口走 netlink → SELinux 拒绝。
   解法：`TailnetSetInterfaces(json)`（Dart 用 `dart:io` 的 getifaddrs 采集 name/index/地址）→ Go 侧注册
   `netmon.RegisterInterfaceGetter`（MTU/MAC/状态从 sysfs 尽力补齐；SELinux 禁 sysfs 时以「有地址即 up」兜底）。
   **必须在 `TailnetStart` 之前调用一次**。
2. **无 /tmp**：`logpolicy` 日志状态选址在 Android 全部落空（systemd/state dir 无、cwd=/、`MkdirTemp("")` 因 /tmp 不存在失败）→
   `panic: no safe place found to store log state`（SIGABRT）。解法：引擎把 `TMPDIR`/`XDG_CACHE_HOME` 指向状态目录下（`prepareEnv`）。
3. **SELinux 禁 `/proc/net/*` 与 `/sys/class/net`**（avc denied）：前缀长度/MTU/MAC 推导降级为 best-effort
   （前缀回退 /32、/128）；对 DERP 中继路径无影响，直连路径在真机以平台通道补全为后续项。

## 测试钩子（`config.json`，仅本地联调/排障；App UI 不写）

状态目录（Android：应用私有 `files/tailnet`）下的可选文件：

```json
{ "control_url": "http://<host>:8080", "auth_key": "<preauth key>", "hostname": "quartz-app-x" }
```

- `control_url`：指向本地 headscale 等自建控制面（缺省=官方控制面，交互式登录 URL）
- `auth_key`：无人值守登录（preauth/auth key）
- 真机排障：`adb shell run-as <app-id> sh -c 'cat > files/tailnet/config.json'`（debug 构建）

## 许可与注意

- 嵌入的 tailscale 客户端代码为 BSD-3-Clause；发布物需随附许可声明。
- 节点的 tailnet 设备标识（node key）存于状态目录（应用私有），App 卸载即清除。
