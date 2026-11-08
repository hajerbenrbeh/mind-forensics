import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Luminous 3D wireframe brain illustration with orbital planetary rings.
/// Matches Phone 1 (Splash) and Phone 5 (Inner Observatory) in the master reference.
class NeuralBrainWireframe extends StatefulWidget {
  const NeuralBrainWireframe({
    super.key,
    this.size = 220,
    this.animate = true,
  });

  final double size;
  final bool animate;

  @override
  State<NeuralBrainWireframe> createState() => _NeuralBrainWireframeState();
}

class _NeuralBrainWireframeState extends State<NeuralBrainWireframe>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    final isTest = const bool.fromEnvironment('FLUTTER_TEST') ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (widget.animate && !isTest) {
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
          painter: _BrainWireframePainter(rotation: _controller.value),
        );
      },
    );
  }
}

class _BrainWireframePainter extends CustomPainter {
  const _BrainWireframePainter({required this.rotation});

  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width * 0.38;

    // 1. Ambient central golden/olive glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFD9D4A7).withValues(alpha: 0.30),
          const Color(0xFF92977D).withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius * 1.6));
    canvas.drawCircle(Offset(cx, cy), radius * 1.6, glowPaint);

    // 2. Orbital planetary rings
    final ringPaint = Paint()
      ..color = const Color(0xFFC7CDAD).withValues(alpha: 0.45)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-0.35 + (rotation * 0.1));
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: radius * 2.3, height: radius * 0.75),
      ringPaint,
    );
    canvas.restore();

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(0.40 - (rotation * 0.08));
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: radius * 2.1, height: radius * 0.65),
      ringPaint..color = const Color(0xFFE2E7CB).withValues(alpha: 0.35),
    );
    canvas.restore();

    // 3. Brain silhouette curves and cortical folds
    final linePaint = Paint()
      ..color = const Color(0xFFE8ECD4).withValues(alpha: 0.75)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final thinLinePaint = Paint()
      ..color = const Color(0xFFB4BC9B).withValues(alpha: 0.50)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Left hemisphere contour
    final leftHemisphere = Path()
      ..moveTo(cx - 4, cy + radius * 0.70)
      ..cubicTo(cx - radius * 0.7, cy + radius * 0.70, cx - radius * 0.95, cy + radius * 0.25, cx - radius * 0.95, cy - radius * 0.10)
      ..cubicTo(cx - radius * 0.95, cy - radius * 0.65, cx - radius * 0.55, cy - radius * 0.85, cx - 4, cy - radius * 0.85);
    canvas.drawPath(leftHemisphere, linePaint);

    // Right hemisphere contour
    final rightHemisphere = Path()
      ..moveTo(cx + 4, cy + radius * 0.70)
      ..cubicTo(cx + radius * 0.7, cy + radius * 0.70, cx + radius * 0.95, cy + radius * 0.25, cx + radius * 0.95, cy - radius * 0.10)
      ..cubicTo(cx + radius * 0.95, cy - radius * 0.65, cx + radius * 0.55, cy - radius * 0.85, cx + 4, cy - radius * 0.85);
    canvas.drawPath(rightHemisphere, linePaint);

    // Cortical internal sulci and gyri (neural flow lines)
    final sulcus1 = Path()
      ..moveTo(cx - radius * 0.80, cy)
      ..cubicTo(cx - radius * 0.50, cy - radius * 0.2, cx - radius * 0.30, cy + radius * 0.2, cx - 10, cy);
    canvas.drawPath(sulcus1, thinLinePaint);

    final sulcus2 = Path()
      ..moveTo(cx + radius * 0.80, cy)
      ..cubicTo(cx + radius * 0.50, cy - radius * 0.2, cx + radius * 0.30, cy + radius * 0.2, cx + 10, cy);
    canvas.drawPath(sulcus2, thinLinePaint);

    final sulcus3 = Path()
      ..moveTo(cx - radius * 0.60, cy - radius * 0.45)
      ..cubicTo(cx - radius * 0.35, cy - radius * 0.60, cx - radius * 0.20, cy - radius * 0.35, cx - 8, cy - radius * 0.50);
    canvas.drawPath(sulcus3, thinLinePaint);

    final sulcus4 = Path()
      ..moveTo(cx + radius * 0.60, cy - radius * 0.45)
      ..cubicTo(cx + radius * 0.35, cy - radius * 0.60, cx + radius * 0.20, cy - radius * 0.35, cx + 8, cy - radius * 0.50);
    canvas.drawPath(sulcus4, thinLinePaint);

    // Brainstem / Cerebellum
    final stem = Path()
      ..moveTo(cx - radius * 0.25, cy + radius * 0.65)
      ..cubicTo(cx - radius * 0.15, cy + radius * 0.95, cx - radius * 0.08, cy + radius * 1.05, cx, cy + radius * 1.1)
      ..cubicTo(cx + radius * 0.08, cy + radius * 1.05, cx + radius * 0.15, cy + radius * 0.95, cx + radius * 0.25, cy + radius * 0.65);
    canvas.drawPath(stem, linePaint);

    // 4. Shimmering node particles
    final nodePaint = Paint()
      ..color = const Color(0xFFFBFEE6)
      ..style = PaintingStyle.fill;

    final nodes = [
      Offset(cx - radius * 0.6, cy - radius * 0.3),
      Offset(cx + radius * 0.55, cy - radius * 0.4),
      Offset(cx - radius * 0.3, cy + radius * 0.2),
      Offset(cx + radius * 0.4, cy + radius * 0.25),
      Offset(cx, cy - radius * 0.7),
      Offset(cx - radius * 0.8, cy + radius * 0.1),
      Offset(cx + radius * 0.75, cy + radius * 0.05),
    ];

    for (int i = 0; i < nodes.length; i++) {
      final pulse = math.sin(rotation * 2 * math.pi + i) * 0.8 + 1.2;
      canvas.drawCircle(nodes[i], 2.2 * pulse, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BrainWireframePainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}

