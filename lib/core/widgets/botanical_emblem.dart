import 'package:flutter/material.dart';
import '../../app/theme/lab_colors.dart';

/// Organic botanical leaf / sprout illustration matching the master reference.
/// Used in avatars, encouragement banners, and section ornaments.
class BotanicalEmblem extends StatelessWidget {
  const BotanicalEmblem({
    super.key,
    this.size = 32,
    this.color,
    this.backgroundColor,
  });

  final double size;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leafColor = color ?? (isDark ? LabColors.lightOlive : LabColors.secondaryOlive);

    final emblem = ExcludeSemantics(
      child: CustomPaint(
        size: Size(size, size),
        painter: _BotanicalLeafPainter(color: leafColor),
      ),
    );

    if (backgroundColor == null) {
      return emblem;
    }

    return Container(
      width: size * 1.6,
      height: size * 1.6,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: emblem,
    );
  }
}

class _BotanicalLeafPainter extends CustomPainter {
  const _BotanicalLeafPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Central graceful stem curve
    final stem = Path()
      ..moveTo(w * 0.45, h * 0.95)
      ..cubicTo(w * 0.45, h * 0.70, w * 0.52, h * 0.40, w * 0.50, h * 0.12);
    canvas.drawPath(stem, paint);

    // Primary central top leaf
    final topLeaf = Path()
      ..moveTo(w * 0.50, h * 0.12)
      ..cubicTo(w * 0.62, h * 0.22, w * 0.60, h * 0.38, w * 0.50, h * 0.42)
      ..cubicTo(w * 0.40, h * 0.38, w * 0.38, h * 0.22, w * 0.50, h * 0.12);
    canvas.drawPath(topLeaf, fillPaint);
    canvas.drawPath(topLeaf, paint);

    // Left lower leaf
    final leftLeaf = Path()
      ..moveTo(w * 0.48, h * 0.55)
      ..cubicTo(w * 0.28, h * 0.45, w * 0.22, h * 0.60, w * 0.26, h * 0.70)
      ..cubicTo(w * 0.38, h * 0.70, w * 0.46, h * 0.62, w * 0.48, h * 0.55);
    canvas.drawPath(leftLeaf, fillPaint);
    canvas.drawPath(leftLeaf, paint);

    // Right middle leaf
    final rightLeaf = Path()
      ..moveTo(w * 0.51, h * 0.42)
      ..cubicTo(w * 0.70, h * 0.36, w * 0.76, h * 0.50, w * 0.72, h * 0.60)
      ..cubicTo(w * 0.60, h * 0.60, w * 0.52, h * 0.52, w * 0.51, h * 0.42);
    canvas.drawPath(rightLeaf, fillPaint);
    canvas.drawPath(rightLeaf, paint);
  }

  @override
  bool shouldRepaint(covariant _BotanicalLeafPainter oldDelegate) =>
      oldDelegate.color != color;
}

