# QuartzWrt-App 设计规范

**版本**: v1.0 —— **定案**（2026-10-12 用户拍板「按推荐案实施」；v0.1 为讨论稿）
**日期**: 2026-10-12
**状态**: 设计定案；实现按 §11 W6.x 实施（W6.1 起，开工时点跟随 WP-5 落地；远端仓库创建待明确指令）
**依据**: TDD §3.4（App 与通信架构）/ §1（核心交付物 2）；WORKPLAN §3 WP-6；
WP-5 `utils/quartz-app-api/docs/DESIGN.md`（接口面、pin 规则、动作集）；
WP-4 `quartz-daemon/docs/DESIGN.md` §12.3（App 侧义务）；契约 `AGGREGATE-API.md`（冻结 v1）
**验收（WORKPLAN §3 WP-6）**: 真机连路由器完成核心链路（发现 → 认证 → 数据展示）；
局域网 mDNS 自动发现；基础设备控制；Tailscale/ZeroTier 远程链路打通

---

## 0. 定位与范围

QuartzWrt 专属移动端：局域网自动发现路由器、安全配对、展示与 Dashboard 同源的实时状态、
执行白名单控制动作、经 Tailscale/ZeroTier 远程管理。

**v1 功能清单**：发现/配对/认证（多路由器）、概览（hero + 系统/网络/设备/服务/Docker 卡）、
设备管理与吊销、基础控制（对齐 WP-5 §5 动作集）、远程手动地址接入、设置（双模 / 语言 zh·en / 关于）。

**v1 不做**（防蔓延）：

| 不做 | 理由 / 归属 |
| :--- | :--- |
| 消息推送 | TDD §8 待决；通道定案前不做（WP-5 D9 同款） |
| 固件 OTA / 升级 | WP-9 |
| 深度 Tailscale/ZeroTier 管理（登录、状态面板） | v1 引导用户完成路由器侧安装；深度集成经 WP-5 动作表后置 |
| 历史图表 / 本地数据库 | 快照为实时窗口（series ≤60 点）；持久化需求出现再评估 |
| iOS 交付、桌面端 | iOS 需 macOS 构建链（D2）；桌面端 Tauri 仅 TDD 备选，不启动 |
| 应用商店分发 | v1 走 GitHub Releases（APK）；商店后置 |

## 1. 前提与事实

| 项 | 内容 | 出处 |
| :--- | :--- | :--- |
| 接口面 | 仅 `quartz-app-api` 八方法（info/login/refresh/logout/status/action/devices/revoke）+ `/ubus` JSON-RPC 信封 | WP-5 DESIGN §4 |
| 数据契约 | `status.snapshot` = AGGREGATE-API v1 原文；消费义务：未知字段容忍、null 节降级、`errors[]` 弱提示、series 缺失自累积 | 契约 §5 |
| App 侧义务 | 轮询降频 / 后台不取数 / 未知 `v` 提示升级 | WP-4 §12.3 |
| TLS | 自签 DER 证书；pin = sha256(DER)；mDNS TXT `fp` 提供带外比对；证书变化（重刷）→ 强制重配对 | WP-5 §6.2/§6.3 |
| 发现 | umdns（基座包，随 WP-5 依赖进入固件）；服务 `_quartz-app._tcp`，TXT：`v/path/fp/rel/name` | WP-5 §6.3 |
| 远程 | Tailscale 1.98.3、ZeroTier（均基座可得，无需第三方收录）；无 luci-app-tailscale；防火墙需引导（接口并入策略） | WP-5 §1.4 |
| 开发环境 | 本机 WSL **未装 Flutter/Dart**——dev 环境为决策项（D10） | 实机检查 2026-10-12 |

## 2. 技术栈与架构

### 2.1 选型（均待 D3/D4 拍板）

| 层 | 选型 | 理由 |
| :--- | :--- | :--- |
| 框架 | **Flutter**（TDD 已定；锁定当时 stable，CI 固定版本） | TDD §3.4/§8 |
| 状态管理 | **Riverpod** | 编译期安全、测试友好、无 BuildContext 依赖 |
| 路由 | go_router | 声明式、深链（未来通知跳转）友好 |
| 网络 | **dio** | 拦截器统一处理信封/错误码/自动 refresh 重试 |
| mDNS | **multicast_dns**（Dart 官方，纯 Dart） | 免插件；iOS 需 Info.plist 声明、Android 部分机型需 MulticastLock（实现期处理） |
| 凭据存储 | **flutter_secure_storage** | Keychain / Android Keystore |
| 图表 | **CustomPainter**（自绘 sparkline，不引图表库） | 需求仅 series 折线；与 WP-3 自绘同思路，体积小 |
| i18n | intl + arb（zh_Hans / en） | 用户可读文案全量本地化；错误码→文案映射表 |

### 2.2 分层

```
features（UI：Overview/Devices/Services/System/Settings…）
   ▲
repository（快照轮询 + 四态降级 + series 累积）      auth（令牌生命周期 + 单飞刷新队列）
   ▲                                                    ▲
transport（dio：JSON-RPC 封装 / 信封判 ok / 错误码映射 / 重试策略）  token store（secure storage）
   ▲
discovery（multicast_dns 浏览 _quartz-app._tcp）+ 手动地址录入
```

- **API 客户端契约**：所有方法经统一 `call(method, args)`；`token_expired` → 单飞 refresh 后重放一次；
  `device_revoked`/`token_invalid` → 清凭据 + 引导重配对；其余错误码 → 文案表 + 可上报。
- Token 不入普通 SharedPreferences（**仅 secure storage 存 refresh**；access 仅内存）。

### 2.3 目录结构（草案）

```
app/                      # Flutter 工程（或仓库根，W6.1 定）
├── lib/
│   ├── main.dart
│   ├── core/             # 主题 token / i18n / 常量
│   ├── api/              # transport + auth + 错误码
│   ├── discovery/
│   ├── data/             # repository + models（契约 v1，含未知容忍解析）
│   └── features/…
├── test/                 # 单测 + widget 测
├── integration_test/     # 对 VM 真路由器的端到端
├── docs/DESIGN.md        # 本文件
└── .github/workflows/build.yml
```

## 3. 发现与配对

1. **发现**：mDNS 浏览 `_quartz-app._tcp.local` → 列表卡片显示 `name/model/rel`；TXT 含 `fp` 则标「可验证」。
2. **信任建立**（首次配对）：TLS 握手取证书 → 与 TXT `fp` 比对（有则强校验；无则 TOFU，标注「未验证」）；
   通过后**记录 pin**（路由器记录：名称/地址/fp/device_id）。
3. **认证**：弹出管理员密码输入（+ 设备名，默认取机型）→ `login` → 成功即入库；失败按 `rate_limited.retry_after` 倒计时。
4. **后续连接**：pin 必须一致；不一致（如重刷固件）→ **阻断 + 提示重新配对**（防降级 MITM）。
5. **手动添加**：IP/主机名 + 端口（443 默认）——mDNS 不可用（跨网段/关闭广播）与远程（tailnet 地址）均走此入口。
6. **多路由器**：并行管理；首页可切换；每路由器独立凭据与 pin。

> 安全声明（如实）：首次配对属 TOFU——局域网投毒的 mDNS/TLS 面在「录入密码」一瞬间存在理论 MITM 窗口；
> v1 以「密码 + 设备名核对」缓解，配对码（SAS）列为 v1.1（与 WP-5 D4 同步演进）。

## 4. 认证与令牌（App 侧）

- access 仅内存；refresh 入 secure storage；App 冷启 → 直接尝试 `refresh`（无感续期）→ 失败才回配对页。
- 并发请求统一走**单飞刷新队列**（防多请求各自 refresh 触发旋转复用检测——**这是与旋转策略配套的硬要求**）。
- 退出登录 = `logout` + 清本地；「移除路由器」= 本地清除（可选同时 `revoke` 自身）。
- 设置页展示 device_id 与已配对设备（调用 `devices`/`revoke`）。

## 5. 数据面

- **前台可见**：5s 轮询 `status`（契约 §5 同款节奏）；切后台停止、回前台立即补一次（TDD 义务）。
- **降级四态**（对齐 Dashboard 语义）：`data_unavailable` → 顶部横幅「采集器未运行」；
  snapshot 节 null → 卡内「—/不可用」；`errors[]` → 卡角弱提示；解析异常 → 「数据损坏」。
- **series**：缺失时自轮询累积（开页后逐点成形）；不持久化（v1 冷启动首屏即取数）。
- 断网/超时：指数退避（5s→10s→30s 上限），恢复即时刷新；不弹错误风暴。

## 6. 控制面

- 动作集 = WP-5 §5 白名单（service.{start,stop,restart} / system.reboot / docker.container.*）；UI 入口按 snapshot 能力显示（服务卡操作钮、系统页重启钮）。
- **危险动作二次确认**（重启路由器 / 停止服务含「可能断开本机连接」提示）；执行中 loading、失败展示 `action_failed.detail`。
- 执行成功 → ≤2s 内轮询自然反映新状态（无需专用回读）。

## 7. 远程链路（Tailscale / ZeroTier）

**✅ W6.5 已实现并真环境验证（2026-10-13；VM `quartzwrt-vm` 真 tailnet 100.118.170.8 + 模拟器走查，证据 `design/shots/emu-w65/`）**：

- **数据面（远程识别）**：`PairedRouter` 带两个端点——局域网（配对地址）+ 远程（手动添加的 tailnet 地址）。`FailoverTransport`：当前端点**传输级**失败（超时/拒连/证书不匹配）→ 换另一端点重试一次并固化；应用级错误不切换；远程在用且回前台时探测局域网、通即切回（`info` 未认证探测，无需令牌）。**远程识别徽标**：概览 hero 与设置配对卡显示 `已连接/已配对 · 局域网｜远程`（远程带云标与强调色）。
- **App 侧（v1）**：设置 →「远程访问」引导页承载：①**真数据状态卡**——路由器端 Tailscale 状态与 tailnet 地址直读快照 `services.tailscale`（daemon 内置探针，WP-4/WP-10 真数据，不装/未启/未登录三态都有明确呈现）与「使用此地址添加远程连接」一键带出；②四步引导（路由器装启用 → 登录 tailnet → 手机装 Tailscale 客户端 → 在本页添加地址）；③远程地址管理（添加/修改/测试/移除）——添加时以**已配对证书指纹严格 pin** 调 `info` 实测连通（同一台路由器同一张证书，pin 复用），失败即时报因（含 `bad_certificate`=可能不是你的路由器）。
- **后置**：tailscale 登录 URL / 一键配置经 WP-5 `action` 表接入；**「App 内封 tailscale」（进程内 tsnet 节点，免装移动端 App）已 spike 验证可行**——见 `dev/spike/tailscale/RESULTS.md`（推荐 tsnet userspace + 本地 CONNECT 代理，无 VPN 权限；定位 v1.5+）。

### 7.1 内嵌直连（tsnet，2026-10-13 用户拍板走此路线 → 已实现，实验特性）

- **路线**：`tsnet` userspace 节点 + **127.0.0.1 CONNECT 代理**（`native/tailnet/`，c-shared `libtailnet.so`，Dart FFI）。**无 VpnService/整机 VPN、无 root、不接管系统流量**；TLS 与证书 pin 仍在 Dart 侧端到端完成。
- **开关语义**：设置→远程访问→「内嵌直连（实验）」开关（持久化，默认关）。开启后远程端点连接顺序 = **代理 → 直连 → 另一端点（局域网）**（`FailoverTransport.attempts()`；仅远程端点可走代理——结构性约束）。
- **登录**：交互式 URL（应用内打开浏览器/复制链接）；节点身份存 App 私有目录（卸载即清）。`config.json` 为本地联调/排障钩子（control_url/auth_key/hostname），App UI 不写。
- **发布面**：release APK 只带 arm64-v8a（`abiFilters`）；x86_64 供模拟器。构建 `scripts/build-native.sh`（CI release 任务已接入 Go+NDK）。合规：tailscale.com BSD-3-Clause，见 `THIRD_PARTY_NOTICES.md`；界面措辞「基于 Tailscale」，不暗示背书。
- **验证（2026-10-13 全通过）**：宿主 `e2e/client` 对**真 tailnet**（官方控制面 + auth key）+ mock 路由器（真 API 子集）——登录→代理→拨 peer→HTTPS→重启免登录持久化全 PASS；模拟器实机（Android 16/x86_64）——内嵌节点 Running（自有 tailnet IP，无 VpnService）、远程地址经内嵌代理探测/保存/「使用中」、徽标「已连接 · 远程」+ 真数据、关闭开关自动回退局域网。工具：`native/tailnet/e2e/`；证据 `design/shots/emu-embed/`。**Android 平台适配三件套**（netlink 禁 → 接口注入 / 无 /tmp → TMPDIR / SELinux sysfs → best-effort）见 `native/tailnet/README.md`。

## 8. UI 与视觉

**UI 设计（已定案）见 [`UI-DESIGN.md`](UI-DESIGN.md)**：预览页 `design/preview.html`（十一屏，评审图 `design/shots/`）。要点：

- 信息架构（2026-10-13 定案）：底部四 tab——**概览**（hero + 系统/网络/上网设备/应用摘要卡）/ **网络**（网络管理·无线·上网设备 + 网络控制）/ **应用**（路由器安装的软件包，行→详情）/ **设置**（系统设置〔路由器/设备控制〕+ 应用设置〔本机〕）；**第 5 tab 位预留隐藏**。
- 控制按域归口：设备控制 → 系统设置；网络控制 → 网络页；单应用控制 → 应用详情（能力注册表驱动）。
- 可扩展性：四层扩展阶梯（数据容忍→泛化渲染→注册表增强→页面模块）+ 卡片/服务/动作三张注册表（UI-DESIGN §4）。
- 双模：随系统 + 手动覆盖；色彩/圆角/材质对齐 WP-2 主题 token（暗色为原生，浅色派生）。
- 字体系统栈；无 webfont；图标线稿风格与侧边栏一致。

## 9. 工程规范与 CI

- 仓库：`QuartzWrt-App`（D1）；Flutter 工程位置（根 or `app/`）随目录结构定案。
- 版本：semver + CHANGELOG；`lib/core/version.dart` 单一来源。
- CI（GitHub Actions，随 tag 触发 Release 附件）：`flutter analyze` + `flutter test` → `flutter build apk --release`（keystore 入 Secrets）；
  iOS 构建不列入 CI（D2）。
- 测试：单测（信封/错误码/令牌状态机/契约模型未知容忍）；widget 测（四态降级渲染）；integration_test 对 **VM 真路由器**（发现→配对→数据）——与 WP-5 验收链共用 VM 预览台。
- 开发环境（D10）：推荐 WSL 内装 Flutter（Linux 工具链，与 CI 一致）产出 APK + Windows 侧模拟器/真机安装调试；备选纯 Windows 开发。

## 10. 决策记录（v1.0 定案：十项按推荐案实施）

| # | 决策 | 定案 | 备选与理由 |
| :--- | :--- | :--- | :--- |
| D1 | 仓库名与可见性 | **`QuartzWrt-App`，公开**（与既有三仓一致；远端创建待批准） | 私有：与发行版「可审计」姿态不一致 |
| D2 | 平台范围 v1 | **Android 优先**（iOS 源码兼容但不交付，构建链后置） | 双平台并列：macOS 构建链与签名成本高 |
| D3 | 状态管理/路由 | **Riverpod + go_router** | Bloc：样板重；Provider：能力弱 |
| D4 | 网络/存储/mDNS 栈 | **dio + flutter_secure_storage + multicast_dns** | http 包 + 自写重试：refresh 单飞等逻辑将重复造 |
| D5 | 配对信任 | **mDNS + TOFU(密码) + pin 记录**（WP-5 D4 对齐）；配对码 v1.1 | 直接要求配对码：UX 成本先于威胁验证 |
| D6 | 数据节奏 | 前台 5s / 后台停 / 断网退避 | 更快轮询：无收益（快照 2s 粒度已够） |
| D7 | 控制面范围 | 与 WP-5 §5 对齐（UI 三组） | — |
| D8 | 远程接入 | **手动 tailnet 地址 + 应用内引导**（W6.5 ✅，含远程徽标与端点故障切换）；深度集成后置 | 集成 tailscale SDK：原判 No-Go（依赖其移动端登录体系）——**2026-10-13 spike 推翻该理由**：tsnet userspace 路线交互式登录 URL 即可、免 VPN 权限免移动端 App，转 v1.5+ 候选（`dev/spike/tailscale/RESULTS.md`） |
| D9 | 推送 | **v1 不做**（TDD §8 待决） | — |
| D10 | 开发环境与发布 | WSL CLI 构建（对齐 CI）+ Windows 调试；Releases 发 APK | 纯 Windows：与 CI 环境差异大 |

## 11. W6.x 分解（拍板后）

| 序号 | 内容 | 依赖 |
| :--- | :--- | :--- |
| W6.0 | 设计定案 + 本地仓库骨架（本稿已在本地草稿，远端创建待批准） | 用户拍板 |
| W6.1 | ✅ 工程骨架 + CI（analyze/test/apk）+ 主题/i18n 基座 | W6.0 |
| W6.2 | ✅ discovery + transport + auth（配对/令牌/单飞刷新） | W6.1、WP-5 可用 |
| W6.3 | ✅ 数据面 UI（概览五卡 + 四态降级 + series） | W6.2 |
| W6.4 | ✅ 应用页（控制面；**软件包管理面 W6.8 落地**）+ 网络页控制 + 控制面动作 | W6.3 |
| W6.5 | ✅ 设置页（多路由器/吊销/双模/语言）+ **远程链路**（引导页/远程地址/识别徽标/端点切换） | W6.4 |
| W6.6 | ✅ 打磨（图标/启动屏/过渡/tab 状态保留/对比度/文案） | W6.5 |
| W6.7 | 真机验收（VM 全链 + R4S 真机：发现→认证→数据展示→控制） | W6.6、WP-5 完成 |
| W6.8 | ✅ **软件包管理面**（WP-5 `packages` v1.1 消费）：软件包子段三视图（可升级/已安装/全部搜索）+ 刷新索引/单包·全部升级/卸载（确认层）+ 分页；操作记录页（`scope=history` 真数据）；应用详情「软件包」卡；旧固件降级说明卡。App v0.3.0；`tool/e2e_vm.dart` 增软件包链路（真固件 ALL PASS）；测试 68 项 | W6.7 前哨、WP-5 v1.1 |

## 12. 同步项与跨 WP 登记

| 项 | 动作 | 归属 |
| :--- | :--- | :--- |
| WP-5 | 接口变化（方法/错误码/动作集）必须同步本稿 §1/§4/§6；契约加法则同步模型层 | 双向登记 |
| WP-5（**应用管理面扩展，已确认**） | 读方法 `packages`（`scope=installed\|upgradable\|available\|history`，分页）+ 动作 `packages.refresh/upgrade/remove`（卸载=危险动作）——供 App 应用页/操作记录；见 UI-DESIGN §5 | 登记（WP-5 侧实施），WP-6 消费 |
| WP-2/WP-3 | 视觉 token 与卡片语义对齐（只读引用，不改对方仓库） | 登记通知 |
| WP-7 | 远程链路依赖 tailscale/zerotier 基座包（无需第三方收录）；若后续收录 luci-app-tailscale 再评估深度集成 | 登记通知 |
| WORKPLAN | W6.x 状态回写 + 本文档路径登记 | 本对话 |

## 13. 变更记录

*v0.1 2026-10-12 —— 首稿（讨论稿）：范围（§0）、前提事实（§1）、技术栈/分层（§2）、发现与配对（§3）、认证令牌（§4）、数据面（§5）、控制面（§6）、远程链路（§7）、UI 视觉（§8）、工程与 CI（§9）、待拍板十项（§10）、W6.x 分解（§11）、同步项（§12）。*
*v1.0 2026-10-12 —— 用户拍板「就先按这个方案来」：§10 十项按推荐案定案（D1 仓库名 `QuartzWrt-App` 公开〔**远端创建待明确指令**〕/ D2 Android 优先 / D3 Riverpod+go_router / D4 dio+secure_storage+multicast_dns / D5 TOFU+pin / D6 5s 轮询 / D7 动作三组 / D8 手动 tailnet 地址 / D9 推送不做 / D10 WSL 构建 + Releases 发 APK）。*
*v1.1 2026-10-13 —— W6.5/W6.6 定案落地 + 内嵌 tailscale spike：§7 重写（远程链路实现：引导页真数据/远程地址严格 pin 测试/远程识别徽标/端点传输级故障切换与回前台切回；证据 `design/shots/emu-w65/`）；D8 更新（tsnet spike 推翻 No-Go 理由，转 v1.5+ 候选 `dev/spike/tailscale/RESULTS.md`）；§11 状态标注 W6.1–W6.6 ✅；新增 CHANGELOG.md 与 lib/core/version.dart 版本单一来源。*
