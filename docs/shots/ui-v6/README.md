# UI v6 走查（2026-10-19）

Dashboard 卡面 + 本机外观落地后的 AVD 实机截图（Android AVD + 真路由器数据）。
第二轮（v0.6.1）聚焦系统卡对齐、概览卡数据密度、蜂窝 tab 与 Dashboard QModem 卡对齐、
文本框内层白底修复。

- `01-overview-dark.png` / `02-overview-light.png`：Dashboard Hero、系统卡（数值统一右缘、
  三条占比条等长、交换分区行）、网络卡（IP 打码 + 虚线，点按展开）、平底 tab。
- `03-router-dark.png`：路由器入口卡（无图标块、能力 chip、chevron）。
- `04-apps-dark.png`：应用 tab（下划线页签 + 服务行）。
- `05-cellular-dark.png` / `12-cellular-light.png`：蜂窝页（中文字段名、运营商名称、下行/上行标签、
  信号单位、重置计划、IPv4 WAN 回退且可点按展开、Radio/Cell & SIM/Connection/Hardware 四栏；
  信号/速率、本月用量/服务小区两张卡同行等高）。
- `06-settings-light.png`：设置页（外观入口）。
- `07-appearance-light.png` / `08-appearance-dark.png`：外观页（预览/模式/材质滑杆/本机壁纸/恢复默认）。
- `09-appearance-opacity-82.png`：拖动不透明度到 82% 后的实时预览与卡片材质。
- `10-overview-mid-light.png`：蜂窝概览卡（2×2 KPI、运营商/型号、下行/上行标签）与在线设备表。
- `11-overview-bottom-light.png` / `15-overview-bottom-dark.png`：Bandix（连接 TCP/UDP、DNS、
  设备下行/上行/累计/策略）、服务与核心（含 quartz-daemon）、Docker（引擎/版本/驱动/根目录、
  统计格、容器列表）。
- `13-admin-form-light.png` / `14-admin-form-dark.png`：管理权表单；`QzField` 已去掉
  CupertinoTextField 默认白底内框，深/浅双模均只保留 Quartz 外框。
- `16-ip-revealed-light.png`：网络卡 IPv4/IPv6 点按展开后的完整地址（再点收起）。
- `17-qmodem-hierarchy.png`：蜂窝入口按网页端 QModem 层级分组（拨号 / 高级模组设置 / 短信与 SIM）。
- `18-qmodem-at-debug.png`：AT 调试（端口、预置命令、输入、输出区）。
- `19-qmodem-at-output.png`：AT 调试累积输出（`ATI` 命令 + 端口 + Quectel 响应 + OK）。
- `20-qmodem-neighbor.png`：邻区信息（LTE/NR 测量只读 + 锁小区状态）。
- `21-qmodem-traffic-reset.png`：模组维护内的流量重置计划（启用/每天或每月/小时/日）。

已知：选择器已能打开；AVD 无照片，实际选图落盘未走查。路由器 tab 的 VM 走查证据在
`docs/HANDOFF.md`（app-api r13；config 17/17、router 15/15）。App v0.7.1 (17)。
