// Sparkline（net.series 折线；空/单点 → 平线占位）。
import 'package:flutter/material.dart';

class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.data,
    required this.color,
    this.height = 54,
  });

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
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        line..color = color.withValues(alpha: .35),
      );
      return;
    }

    final smoothed = _ema(data.map((e) => e.toDouble()).toList(), .3);
    final points = _downsample(smoothed, 13);
    var min = double.infinity;
    var max = double.negativeInfinity;
    for (final d in points) {
      if (d < min) min = d;
      if (d > max) max = d;
    }
    final span = (max - min).abs() < 1e-9 ? 1.0 : (max - min);
    final stepX = size.width / (points.length - 1);
    final coords = <Offset>[
      for (var i = 0; i < points.length; i++)
        Offset(
          stepX * i,
          // 上留 15% 下留 10% 余量
          size.height * .9 - ((points[i] - min) / span) * size.height * .75,
        ),
    ];
    final path = _catmullRom(coords);
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, fill);
    canvas.drawPath(path, line);
  }

  List<double> _ema(List<double> input, double alpha) {
    if (input.isEmpty) return const [];
    final out = <double>[input.first];
    for (var i = 1; i < input.length; i++) {
      out.add(alpha * input[i] + (1 - alpha) * out[i - 1]);
    }
    return out;
  }

  List<double> _downsample(List<double> input, int target) {
    if (input.length <= target || target < 2) return input;
    final out = <double>[];
    for (var i = 0; i < target; i++) {
      final start = (i * input.length / target).floor();
      final end = ((i + 1) * input.length / target).ceil().clamp(
        start + 1,
        input.length,
      );
      var sum = 0.0;
      for (var j = start; j < end; j++) {
        sum += input[j];
      }
      out.add(sum / (end - start));
    }
    return out;
  }

  Path _catmullRom(List<Offset> p) {
    final path = Path()..moveTo(p.first.dx, p.first.dy);
    for (var i = 0; i < p.length - 1; i++) {
      final p0 = i == 0 ? p[i] : p[i - 1];
      final p1 = p[i];
      final p2 = p[i + 1];
      final p3 = i + 2 < p.length ? p[i + 2] : p2;
      final c1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final c2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.data != data || old.color != color;
}
