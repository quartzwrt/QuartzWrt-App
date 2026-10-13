// 展示格式化（tabular 数字语义；单位 ≤4 字符，与 Web 端口径一致）。
import 'package:intl/intl.dart';

final _int = NumberFormat('#,###');

String formatCount(num n) => _int.format(n);

/// 字节：B/KB/MB/GB（两位有效小数，去除多余 0）。
String formatBytes(num bytes) {
  if (bytes < 1024) return '${bytes.round()} B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var v = bytes.toDouble();
  var u = -1;
  while (v >= 1024 && u < units.length - 1) {
    v /= 1024;
    u++;
  }
  return '${_trim(v)} ${units[u]}';
}

/// 速率：字节/秒。
String formatRate(num bps) => '${formatBytes(bps)}/s';

String _trim(double v) {
  if (v >= 100) return v.toStringAsFixed(0);
  if (v >= 10) return v.toStringAsFixed(1);
  return v.toStringAsFixed(2);
}

/// 百分比（一位小数）。
String formatPct(num pct) => '${(pct * 10).round() / 10}%';

/// 温度（无传感器 → null 由调用方展示「不可用」）。
String formatTemp(num? c) => c == null ? '' : '${(c * 10).round() / 10} °C';

/// uptime 拆解（天/时/分）——组合文案走 l10n。
(int days, int hours, int minutes) uptimeParts(int seconds) {
  final d = seconds ~/ 86400;
  final h = (seconds % 86400) ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  return (d, h, m);
}

/// 相对时间（「刚刚 / N 分钟前 / N 小时前」）——文案由调用方映射。
(String unit, int value) relativeTime(int epochSeconds, {DateTime? now}) {
  final n = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
  final diff = (n - epochSeconds).clamp(0, 1 << 31);
  if (diff < 60) return ('now', diff);
  if (diff < 3600) return ('min', diff ~/ 60);
  if (diff < 86400) return ('hour', diff ~/ 3600);
  return ('day', diff ~/ 86400);
}
