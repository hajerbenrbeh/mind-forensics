import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A soothing organic vector art illustration for the "Exercises for you" card.
///
/// Directly inspired by the calm, friendly rounded pebble character in the
/// reference design. Uses pure canvas vector math with ZERO emojis.
class HomeOrganicExerciseArt extends StatelessWidget {
  const HomeOrganicExerciseArt({
    super.key,
    this.size = 64.0,
    this.isDark = false,
  });

  final double size;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PebbleArtPainter(isDark: isDark),
      ),
    );
  }
}

class _PebbleArtPainter extends CustomPainter {
  _PebbleArtPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;

    // Organic pebble body path (slightly squashy and rounded)
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFDA4AF), // Soft light rose
          Color(0xFFF43F5E), // Rose coral
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.88,
        height: size.height * 0.82,
      ),
      Radius.circular(radius * 0.75),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Subtle inner shadow / depth
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(bodyRect.deflate(2.0), highlightPaint);

    // Two calm spiral eyes / mindfulness concentric ripples
    final strokePaint = Paint()
      ..color = const Color(0xFF881337)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final leftEye = Offset(center.dx - radius * 0.38, center.dy - radius * 0.05);
    final rightEye = Offset(center.dx + radius * 0.38, center.dy - radius * 0.05);

    _drawCalmSpiral(canvas, leftEye, radius * 0.20, strokePaint);
    _drawCalmSpiral(canvas, rightEye, radius * 0.20, strokePaint);

    // Calm neutral mouth line
    final mouthPaint = Paint()
      ..color = const Color(0xFF881337)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - 6.0, center.dy + radius * 0.34),
      Offset(center.dx + 6.0, center.dy + radius * 0.34),
      mouthPaint,
    );
  }

  void _drawCalmSpiral(Canvas canvas, Offset center, double maxR, Paint paint) {
    final path = Path();
    const loops = 1.6;
    const steps = 30;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final angle = t * loops * 2 * math.pi;
      final r = t * maxR;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PebbleArtPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

