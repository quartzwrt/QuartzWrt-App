# bandix App 面模拟器走查证据（2026-10-17，WP-6 L2/L3）

**环境**：Windows 侧 Android Studio SDK 模拟器（`D:\Software\AndroidStudioSDK`，AVD
`Medium_Phone_API_37.0`，android-37.0 google_apis_playstore x86_64，WHPX 硬件加速），
App `v0.4.0 (4)` release APK，配对到 WSL 内 VM 路由器（手动地址 `10.0.2.2:8443`，
root/quartz；`10.0.2.2` = Windows 宿主环回 → WSL localhost 转发 → QEMU 端口转发）。

**判定**：WP-8 P2 的 App 侧（L2 富化行 + 详情卡 + 三对话框 + L3 流量明细页）在真实
固件数据上全部可用；写动作走通 App → `quartz-app-api` → bridge → 核心全链路。
**2026-10-18 限速策略轮**：01–04 已按新口径重出（去 WAN 速率重复行；加总体限速策略；
设备行显示速率与限速策略徽标）；同时验证**换镜像换证书后的重配对流程**（移除 → 按地址
添加 → 配对，新构建标识 `20261018T113041Z-4822f40` 上屏）。

| # | 截图 | 内容 |
| :--- | :--- | :--- |
| 01 | `01-overview-zh.png` | 概览（真数据：QuartzWrt 构建标识 / CPU / WAN / 设备；底部 Apps 卡含 bandix） |
| 02 | `02-apps-enrichment-row.png` | 应用列表 **L2 富化行**：`Bandix / 运行中 · 0.12.11 · 在线 2/2` |
| 03 | `03-detail-bandix-card.png` | 详情页「Bandix 流量与限速」卡：在线设备 2/2、**默认限速 ↓不限·↑不限**、**白名单 关·规则 0·配额 0·设备 0**、连接/DNS 未启用 + 四个动作入口（原 WAN 速率行已按用户指令删除） |
| 04 | `04-traffic-page.png` | **L3 流量明细页（限速策略轮）**：摘要含总体限速；设备行 = 速率（设备侧 WAN）+ 累计·占比 + 策略徽标（本机未配策略 → 「默认」）+ 动作 |
| 05 | `05-limit-sheet-read.png` | 「默认限速」对话框：当前值 0/0 **经唯一读条目 `bandix.limits` 读出** |
| 06 | `06-limit-filled-128.png` | 输入下行 128 KB/s |
| 07 | `07-limit-saved.png` | 保存后（写链路：App → app-api 转发项 → bridge → 核心） |
| 08 | `08-whitelist-sheet.png` | 「限速白名单」对话框：开关 + MAC 增删 |

**写往返硬证据**（路由器侧日志与状态，走查期间采集）：

```
# App 保存 128 KB/s 后（app-api 审计 + 核心状态）
logread: quartz-app-api[…]: fwd action=bandix.limit_default_set target=quartz.bandix.limit_default_set ok dur_ms=154
ubus call quartz.bandix limits → default_wan_rx_rate_limit = 131072   (= 128 × 1024)
# App 再改回 0 后
ubus call quartz.bandix limits → default_wan_rx_rate_limit = 0
```

**驱动要点（下次照抄）**：
- `adb.exe` 用 SDK 自带（`D:\Software\AndroidStudioSDK\platform-tools\adb.exe`）；
  `adb exec-out screencap -p` 出图，**但 `input tap` 的坐标以 `uiautomator dump` 的
  bounds 为准**（与截图像素不是同一坐标系，直接按截图坐标点会偏）；
- 底部对话框在**输入法弹出后会被顶起**（`viewInsets` 参与底部内边距）——点按钮前重新
  dump 取当前坐标（本次 `保存` 从 y≈2285 移到 y≈1402）；
- **全新覆盖层的 VM 没有 root 密码** → `quartz-app-api` 拒绝配对（`password_set=false`）；
  先按验收脚本同款 `sed /etc/shadow` 设 `quartz` 再配对；
- 模拟器 Locale 用 App 内设置页「语言 → 中文」切（`persist.sys.locale` 对 Flutter 的
  `AppL10n` 不生效场景实测如此）。
