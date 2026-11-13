import 'package:flutter/material.dart';

import '../../../../app/theme/lab_colors.dart';

/// A serene botanical wave-ring emblem for the "Exercises for you" card.
///
/// Uses pure vector geometry harmonized with [LabColors] tokens (zero emojis,
/// zero cartoonish facial features).
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
        painter: _BotanicalRipplePainter(isDark: isDark),
      ),
    );
  }
}

class _BotanicalRipplePainter extends CustomPainter {
  _BotanicalRipplePainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.44;

    // Grounded organic enclosure (Mineral Forest / Obsidian Slate)
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [
                LabColors.nightSurfaceElevated,
                LabColors.nightAccentSoft,
              ]
            : const [
                LabColors.daylightAccentSoft,
                LabColors.daylightSurfaceSubtle,
              ],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius))
      ..style = PaintingStyle.fill;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.88,
        height: size.height * 0.88,
      ),
      Radius.circular(size.width * 0.28),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    final borderPaint = Paint()
      ..color = (isDark ? LabColors.nightBorder : LabColors.daylightBorder)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(bodyRect, borderPaint);

    // Layered concentric botanical breath rings
    final ringAccent = isDark ? LabColors.nightAccent : LabColors.daylightAccent;
    final radiiScales = [0.33, 0.23, 0.13];
    final alphas = [0.28, 0.52, 0.85];

    for (var i = 0; i < radiiScales.length; i++) {
      final ringPaint = Paint()
        ..color = ringAccent.withValues(alpha: alphas[i])
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == radiiScales.length - 1 ? 1.8 : 1.3;
      canvas.drawCircle(center, size.width * radiiScales[i], ringPaint);
    }

    // Quiet central calm dot
    final corePaint = Paint()
      ..color = ringAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.055, corePaint);
  }

  @override
  bool shouldRepaint(covariant _BotanicalRipplePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
