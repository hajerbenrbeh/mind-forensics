import 'package:flutter/material.dart';
import '../../app/theme/lab_colors.dart';

/// Smooth cubic Bezier spline chart with gradient area fill and active tooltip.
/// Matches "Your Mind at a Glance" (Phone 2) and "Mood Trends" (Phone 4).
class SmoothSplineChart extends StatelessWidget {
  const SmoothSplineChart({
    super.key,
    required this.values,
    this.height = 110,
    this.lineColor,
    this.fillColors,
    this.activePointIndex,
    this.activePointLabel,
    this.showDots = true,
  });

  final List<double> values;
  final double height;
  final Color? lineColor;
  final List<Color>? fillColors;
  final int? activePointIndex;
  final String? activePointLabel;
  final bool showDots;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strokeColor = lineColor ?? (isDark ? LabColors.lightOlive : LabColors.forestGreen);

    final areaColors = fillColors ??
        [
          strokeColor.withValues(alpha: 0.20),
          strokeColor.withValues(alpha: 0.02),
        ];

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: _SplineChartPainter(
          values: values,
          lineColor: strokeColor,
          fillColors: areaColors,
          activePointIndex: activePointIndex,
          activePointLabel: activePointLabel,
          showDots: showDots,
        ),
      ),
    );
  }
}

class _SplineChartPainter extends CustomPainter {
  const _SplineChartPainter({
    required this.values,
    required this.lineColor,
    required this.fillColors,
    this.activePointIndex,
    this.activePointLabel,
    required this.showDots,
  });

  final List<double> values;
  final Color lineColor;
  final List<Color> fillColors;
  final int? activePointIndex;
  final String? activePointLabel;
  final bool showDots;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final w = size.width;
    final h = size.height;
    final padTop = activePointLabel != null ? 32.0 : 12.0;
    final padBottom = 16.0;
    final chartHeight = h - padTop - padBottom;

    final n = values.length;
    final dx = w / (n - 1);

    final points = <Offset>[];
    for (int i = 0; i < n; i++) {
      final normY = (values[i].clamp(0.0, 1.0));
      final py = padTop + chartHeight * (1.0 - normY);
      final px = i * dx;
      points.add(Offset(px, py));
    }

    // Build smooth cubic Bezier path
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < n - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY1 = p0.dy;
      final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY2 = p1.dy;
      path.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
    }

    // Gradient fill area
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, h)
      ..lineTo(points.first.dx, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: fillColors,
      ).createShader(Rect.fromLTWH(0, padTop, w, chartHeight + padBottom));
    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // Data points & active tooltip
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final dotHolePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    if (showDots) {
      for (int i = 0; i < points.length; i++) {
        final pt = points[i];
        final isActive = activePointIndex == i;

        if (isActive) {
          // Larger highlight dot with halo
          canvas.drawCircle(pt, 6, dotPaint);
          canvas.drawCircle(pt, 3, dotHolePaint);

          // Tooltip balloon
          if (activePointLabel != null) {
            _drawTooltip(canvas, pt, activePointLabel!);
          }
        } else {
          canvas.drawCircle(pt, 3.5, dotPaint);
          canvas.drawCircle(pt, 1.8, dotHolePaint);
        }
      }
    }
  }

  void _drawTooltip(Canvas canvas, Offset target, String label) {
    final textSpan = TextSpan(
      text: label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final tooltipW = textPainter.width + 16;
    final tooltipH = textPainter.height + 8;
    final tooltipCenter = Offset(target.dx.clamp(tooltipW / 2, 400 - tooltipW / 2), target.dy - 22);

    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: tooltipCenter, width: tooltipW, height: tooltipH),
      const Radius.circular(8),
    );

    final bgPaint = Paint()..color = LabColors.forestGreen;
    canvas.drawRRect(rrect, bgPaint);

    textPainter.paint(
      canvas,
      Offset(tooltipCenter.dx - textPainter.width / 2, tooltipCenter.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _SplineChartPainter oldDelegate) => true;
}

