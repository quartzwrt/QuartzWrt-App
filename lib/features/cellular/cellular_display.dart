// 蜂窝展示口径（与 Dashboard QModem 卡同源）：运营商 PLMN 名称、信号单位、
// 流量重置计划。数据缺省一律显示 "—"，不把 0/空串当有效值。
import '../../api/cellular.dart';
import '../../l10n/app_localizations.dart';

String cellularOperatorText(AppL10n l10n, CellularModem m) {
  final raw = m.operator.isNotEmpty ? m.operator : (m.sim?.isp ?? '');
  if (raw.isEmpty) return '';
  final name = switch (raw) {
    '46000' ||
    '46002' ||
    '46004' ||
    '46007' ||
    '46008' => l10n.cellularOperatorChinaMobile,
    '46001' || '46006' || '46009' => l10n.cellularOperatorChinaUnicom,
    '46003' || '46005' || '46011' => l10n.cellularOperatorChinaTelecom,
    _ => null,
  };
  return name == null ? raw : '$raw · $name';
}

String cellularResetText(AppL10n l10n, CellularTraffic? t) {
  if (t == null || !t.available) return '—';
  if (!t.resetEnabled) return l10n.cellularNoResetPlan;
  final time = '${t.resetHour.toString().padLeft(2, '0')}:00';
  return switch (t.resetType) {
    'monthly' => l10n.cellularResetMonthly(
      t.resetDay <= 0 ? 1 : t.resetDay,
      time,
    ),
    'weekly' => l10n.cellularResetWeekly(time),
    'daily' => l10n.cellularResetDaily(time),
    final type when type.isNotEmpty => '$type · $time',
    _ => l10n.cellularNoResetPlan,
  };
}

String cellularSignalText(CellularSignal? sig, {bool compact = false}) {
  if (sig == null) return '—';
  String withUnit(double? v, String unit) =>
      v == null ? '—' : '${v.toStringAsFixed(0)} $unit';
  final main = [
    'RSRQ ${withUnit(sig.rsrq, 'dB')}',
    'SINR ${withUnit(sig.sinr, 'dB')}',
  ].join(' · ');
  // 蜂窝卡半宽，RSSI 单独一行，避免行尾只剩一个分隔点。
  return compact ? main : '$main\nRSSI ${withUnit(sig.rssi, 'dBm')}';
}

String cellularCqiText(CellularModem m) {
  if (m.cqiUl == null && m.cqiDl == null) return '—';
  return '${m.cqiUl ?? '—'} / ${m.cqiDl ?? '—'}';
}

String cellularAmbrText(CellularModem m) {
  if (m.ambrUl == null && m.ambrDl == null) return '—';
  return '${m.ambrUl ?? '—'} / ${m.ambrDl ?? '—'} Mbps';
}
