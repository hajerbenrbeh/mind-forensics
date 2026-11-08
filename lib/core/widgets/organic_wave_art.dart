import 'package:flutter/material.dart';
import '../../app/theme/lab_colors.dart';

/// Organic landscape artwork with rolling wavy hills and glowing sun.
/// Matches the "Your current phase: Balanced" card on Phone 2 of the master reference.
class OrganicWaveArt extends StatelessWidget {
  const OrganicWaveArt({
    super.key,
    this.height = 140,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          size: Size(double.infinity, height),
          painter: _OrganicWavePainter(),
        ),
      ),
    );
  }
}

class _OrganicWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft atmospheric ivory gradient background
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFF0E8D9),
          const Color(0xFFE2D6C3),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // 2. Subtle glowing sun circle on the top right
    final sunCenter = Offset(w * 0.78, h * 0.32);
    final sunGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFFDF5).withValues(alpha: 0.85),
          const Color(0xFFFFF0D0).withValues(alpha: 0.40),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: h * 0.45));
    canvas.drawCircle(sunCenter, h * 0.45, sunGlowPaint);

    final sunCorePaint = Paint()
      ..color = const Color(0xFFFFF9E6).withValues(alpha: 0.70);
    canvas.drawCircle(sunCenter, h * 0.16, sunCorePaint);

    // 3. Distant soft ridge (light olive)
    final ridge1 = Path()
      ..moveTo(0, h * 0.65)
      ..cubicTo(w * 0.25, h * 0.50, w * 0.55, h * 0.70, w, h * 0.48)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final ridge1Paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF9EAA8E).withValues(alpha: 0.85),
          const Color(0xFF7E8C6F),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.48, w, h * 0.52));
    canvas.drawPath(ridge1, ridge1Paint);

    // 4. Middle rolling hill (secondary olive)
    final ridge2 = Path()
      ..moveTo(0, h * 0.74)
      ..cubicTo(w * 0.30, h * 0.62, w * 0.60, h * 0.78, w, h * 0.60)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final ridge2Paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF5E6C50),
          const Color(0xFF4A583E),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.60, w, h * 0.40));
    canvas.drawPath(ridge2, ridge2Paint);

    // 5. Foreground deep hill (deep forest green #303A29)
    final ridge3 = Path()
      ..moveTo(0, h * 0.86)
      ..cubicTo(w * 0.35, h * 0.76, w * 0.70, h * 0.88, w, h * 0.78)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final ridge3Paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          LabColors.forestGreen, // #303A29
          const Color(0xFF222B1C),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.76, w, h * 0.24));
    canvas.drawPath(ridge3, ridge3Paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

