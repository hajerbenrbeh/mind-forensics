import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/lab_colors.dart';

/// A delicate visual signature combining concentric fingerprint ridges
/// and abstract flowing neural threads.
///
/// Embodies the Mind Forensics visual identity:
/// "Every thought leaves a trace. Every emotion tells a story."
class FingerprintThreadSignature extends StatefulWidget {
  const FingerprintThreadSignature({
    super.key,
    this.size = 64.0,
    this.primaryColor = LabColors.champagneGold,
    this.accentColor = LabColors.deepBurgundy,
    this.animated = false,
  });

  final double size;
  final Color primaryColor;
  final Color accentColor;
  final bool animated;

  @override
  State<FingerprintThreadSignature> createState() =>
      _FingerprintThreadSignatureState();
}

class _FingerprintThreadSignatureState extends State<FingerprintThreadSignature>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    if (widget.animated) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _FingerprintPainter(
            progress: widget.animated ? _controller.value : 0.0,
            primaryColor: widget.primaryColor,
            accentColor: widget.accentColor,
          ),
        );
      },
    );
  }
}

class _FingerprintPainter extends CustomPainter {
  _FingerprintPainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
  });

  final double progress;
  final Color primaryColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // 1. Concentric delicate fingerprint ridges
    final ridgeCount = 5;
    for (int i = 1; i <= ridgeCount; i++) {
      final radius = (maxRadius * (i / ridgeCount)) * 0.9;
      final opacity = 0.25 + (0.5 * (1 - (i / ridgeCount)));
      final paint = Paint()
        ..color = primaryColor.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round;

      // Draw subtle broken arcs representing fingerprint swirls
      final startAngle = -math.pi / 2 + (i * 0.3) + (math.sin(progress * 2 * math.pi) * 0.1);
      final sweepAngle = math.pi * 1.5 - (i * 0.2);

      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }

    // 2. Flowing neural thread connecting through the center
    final threadPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;

    final path = Path();
    final startX = center.dx - maxRadius * 0.8;
    final endX = center.dx + maxRadius * 0.8;

    path.moveTo(startX, center.dy);
    final waveOffset = math.sin(progress * 2 * math.pi) * (maxRadius * 0.15);

    path.cubicTo(
      center.dx - maxRadius * 0.3,
      center.dy - maxRadius * 0.4 + waveOffset,
      center.dx + maxRadius * 0.3,
      center.dy + maxRadius * 0.4 - waveOffset,
      endX,
      center.dy,
    );

    canvas.drawPath(path, threadPaint);

    // 3. Central luminous focal point
    final coreGlow = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, 2.5, coreGlow);

    final coreDot = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 1.2, coreDot);
  }

  @override
  bool shouldRepaint(covariant _FingerprintPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor;
  }
}
