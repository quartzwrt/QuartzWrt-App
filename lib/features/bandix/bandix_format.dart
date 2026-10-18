// bandix 展示口径（面板 / 流量明细页 / 对话框共用；2026-10-17 限速策略轮）。
//
// 数据来源 = 快照 `bandix.limits` 与 `bandix.top[]`（契约 §3.7）。
// 语义提醒：上游限速分三层——全局默认限速、时段限速规则（仅其时间窗内生效）、
// 周期配额，白名单豁免限速；本层只做紧凑标记，完整规则在网页 Bandix 页。
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../format.dart';
import '../../l10n/app_localizations.dart';

/// 总体默认限速文本：`↓ 128 KB/s · ↑ 不限`。
String bandixDefaultLimitText(AppL10n l10n, Map<String, dynamic> lim) {
  String one(num? v) => (v == null || v == 0) ? l10n.bandixUnlimited : formatRate(v);
  return '↓ ${one(lim['default_rx_bps'] as num?)} · ↑ ${one(lim['default_tx_bps'] as num?)}';
}

/// 白名单状态 + 策略计数：`开 · 规则 3 · 配额 1 · 设备 1`（排除路由器自身时不区分）。
String bandixPolicyCountsText(AppL10n l10n, Map<String, dynamic> lim) {
  final on = lim['whitelist_enabled'] == true ? l10n.bandixOn : l10n.bandixOff;
  return '$on · ${l10n.bandixRulesCount((lim['schedule_count'] as num?)?.toInt() ?? 0)}'
      ' · ${l10n.bandixQuotasCount((lim['quota_count'] as num?)?.toInt() ?? 0)}'
      ' · ${l10n.bandixWlDevicesCount((lim['whitelist_count'] as num?)?.toInt() ?? 0)}';
}

/// 单设备限速策略标记（优先级：白名单 > 时段限速 > 配额 > 默认）；
/// 返回 (文本, 是否高亮——高亮 = 有显式策略)。
(String, bool) bandixDevicePolicy(AppL10n l10n, Map<String, dynamic> it) {
  if (it['wl'] == true) return (l10n.bandixPolicyWhitelisted, true);
  final sch = (it['sch'] as num?)?.toInt() ?? 0;
  if (sch > 0) return (l10n.bandixPolicyLimits(sch), true);
  if (it['q'] == true) return (l10n.bandixPolicyQuota, true);
  return (l10n.bandixPolicyDefault, false);
}

/// 设备策略徽标（白名单=绿，限速/配额=琥珀，默认=灰）。
Widget bandixPolicyBadge(AppL10n l10n, ThemeData theme, Map<String, dynamic> it) {
  final (text, hot) = bandixDevicePolicy(l10n, it);
  final color = it['wl'] == true
      ? QuartzColors.ok
      : hot
          ? QuartzColors.warn
          : theme.colorScheme.onSurface.withValues(alpha: .45);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: .35)),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11.5, fontWeight: hot ? FontWeight.w600 : FontWeight.w400, color: color),
    ),
  );
}
