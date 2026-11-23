# 无电池设备概览假电池卡：复现与验收（2026-11-24）

设备：NLnet XiGuaPi V3（NL68K，无电池），路由器 daemon r15（仍输出
`battery.available=false` 的整节）。

| 截图 | App | 固件数据 | 结果 |
| :--- | :--- | :--- | :--- |
| `01-v072-fake-battery-card.png` | v0.7.2（构建 18） | daemon r15 | **复现**：概览底部出现 `Battery` 原始字段卡 |
| `03-head-app-no-card.png` | HEAD（电池条件卡） | daemon r15 | 无电池卡 |
| `04-v073-r15-no-card.png` | **v0.7.3（构建 19，正式 Release）** | daemon r15 | **验收**：电池卡消失 |

v0.7.3 的修复：电池节由专属条件卡消费（`available === true` 才渲染）；通用兜底
额外跳过显式 `available=false` 的未知节。`02-v072-after-daemon-fix.png` 是排查阶段
用 patched daemon（无电池时整节省略）验证旧客户端的辅助证据，最终发布未采用该
daemon 改动。
