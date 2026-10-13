// Sparkline（net.series 折线；空/单点 → 平线占位）。
import 'package:flutter/material.dart';

class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.data, required this.color, this.height = 54});

  final List<num> data;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _SparkPainter(data, color)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.data, this.color);

  final List<num> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = color;
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: .13);

    if (data.length < 2) {
      // 数据不足 → 平线占位（不报错、不空黑）
      final y = size.height * .8;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line..color = color.withValues(alpha: .35));
      return;
    }

    var min = double.infinity;
    var max = double.negativeInfinity;
    for (final v in data) {
      final d = v.toDouble();
      if (d < min) min = d;
      if (d > max) max = d;
    }
    final span = (max - min).abs() < 1e-9 ? 1.0 : (max - min);
    final stepX = size.width / (data.length - 1);
    final path = Path();
    final area = Path();
    for (var i = 0; i < data.length; i++) {
      final x = stepX * i;
      // 上留 15% 下留 10% 余量
      final y = size.height * .9 - ((data[i] - min) / span) * size.height * .75;
      if (i == 0) {
        path.moveTo(x, y);
        area.moveTo(x, size.height);
        area.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        area.lineTo(x, y);
      }
    }
    area.lineTo(size.width, size.height);
    area.close();
    canvas.drawPath(area, fill);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.data != data || old.color != color;
}
