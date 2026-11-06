import 'package:flutter/material.dart';

/// A smooth, minimalist bezier sparkline chart for the Home dashboard.
///
/// Draws a tranquil trend curve without harsh axes or busy grids.
/// Strictly renders real user points without fabricating peaks or valleys.
/// Displays a calm, flat reference baseline when insufficient data exists.
class HomeMetricSparkline extends StatelessWidget {
  const HomeMetricSparkline({
    super.key,
    required this.values,
    required this.lineColor,
    this.height = 46.0,
  });

  final List<double> values;
  final Color lineColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          lineColor: lineColor,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.lineColor,
  });

  final List<double> values;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    // If fewer than 2 entries exist, render a calm calibrating baseline guide
    if (values.length < 2) {
      final guidePaint = Paint()
        ..color = lineColor.withValues(alpha: 0.28)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      // Draw dashed reference baseline
      const dashWidth = 5.0;
      const dashSpace = 4.0;
      double startX = 0;
      final y = size.height / 2;

      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(startX + dashWidth, y),
          guidePaint,
        );
        startX += dashWidth + dashSpace;
      }

      // Draw center calibration anchor dot
      final anchorPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.width / 2, y), 3.0, anchorPaint);
      return;
    }

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).abs() < 0.01 ? 1.0 : (maxVal - minVal);

    final points = <Offset>[];
    final dx = size.width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      // Invert Y so higher values appear higher on screen, with padding
      final normalizedY = (values[i] - minVal) / range;
      final y = size.height - (normalizedY * (size.height - 12)) - 6;
      points.add(Offset(i * dx, y));
    }

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );
    }

    canvas.drawPath(path, paint);

    // Draw a subtle glowing dot on the last point
    final last = points.last;
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(last, 3.5, dotPaint);

    final glowPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(last, 6.0, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.lineColor != lineColor;
  }
}
