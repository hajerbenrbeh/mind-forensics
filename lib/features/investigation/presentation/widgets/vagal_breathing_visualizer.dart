import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/lab_colors.dart';

/// Luxury concentric bio-luminescent vagal breathing visualizer.
///
/// Features fluid ripple waves and phase-dependent colors that breathe
/// organically with the user to downregulate the autonomic nervous system.
class VagalBreathingVisualizer extends StatefulWidget {
  const VagalBreathingVisualizer({
    super.key,
    required this.phase,
    required this.secondsLeft,
    required this.phaseText,
    required this.isDark,
  });

  final int phase; // 0: Inhale, 1: Hold, 2: Exhale, 3: Hold
  final int secondsLeft;
  final String phaseText;
  final bool isDark;

  @override
  State<VagalBreathingVisualizer> createState() => _VagalBreathingVisualizerState();
}

class _VagalBreathingVisualizerState extends State<VagalBreathingVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Color get _phaseAccentColor {
    switch (widget.phase) {
      case 0: // Inhale - Warm Beige / Cream life
        return widget.isDark ? LabColors.warmBeige : LabColors.warmBeigeDark;
      case 1: // Hold - Warm Gold / Amber balance
        return LabColors.assumptionAmber;
      case 2: // Exhale - Soothing Cherry Red release
        return widget.isDark ? LabColors.cherryRedGlow : LabColors.cherryRed;
      case 3: // Hold - Sage / Stillness
      default:
        return widget.isDark ? LabColors.sageGreenGlow : LabColors.sageGreen;
    }
  }

  Color get _phaseBgColor {
    switch (widget.phase) {
      case 0:
        return widget.isDark ? LabColors.warmBeigeBgDark : LabColors.warmBeigeBgLight;
      case 1:
        return widget.isDark
            ? LabColors.assumptionBackgroundDark.withValues(alpha: 0.4)
            : LabColors.assumptionBackgroundLight;
      case 2:
        return widget.isDark ? LabColors.cherryBgDark : LabColors.cherryBgLight;
      case 3:
      default:
        return widget.isDark ? LabColors.sageBgDark : LabColors.sageBgLight;
    }
  }

  double get _targetScale {
    switch (widget.phase) {
      case 0: // Inhale
        return 1.25;
      case 1: // Hold Full
        return 1.25;
      case 2: // Exhale
        return 0.85;
      case 3: // Hold Empty
      default:
        return 0.85;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _phaseAccentColor;
    final bg = _phaseBgColor;
    final isDark = widget.isDark;

    return Center(
      child: SizedBox(
        width: 190,
        height: 190,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outward Breathing Aura Rings
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(190, 190),
                  painter: _BreathingRipplesPainter(
                    progress: _waveController.value,
                    color: accent,
                    phase: widget.phase,
                    isDark: isDark,
                  ),
                );
              },
            ),

            // Physical Interactive Breathing Core
            AnimatedScale(
              scale: _targetScale,
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bg,
                  border: Border.all(color: accent, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: isDark ? 0.35 : 0.2),
                      blurRadius: 22,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.secondsLeft}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: accent,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.phaseText.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: accent.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreathingRipplesPainter extends CustomPainter {
  const _BreathingRipplesPainter({
    required this.progress,
    required this.color,
    required this.phase,
    required this.isDark,
  });

  final double progress;
  final Color color;
  final int phase;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + (i * 0.33)) % 1.0;
      final radius = 52.0 + (ringProgress * (maxRadius - 52.0));
      final opacity = (1.0 - ringProgress) * (isDark ? 0.30 : 0.20);

      final paint = Paint()
        ..color = color.withValues(alpha: math.max(0.0, opacity))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BreathingRipplesPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.phase != phase ||
        oldDelegate.isDark != isDark;
  }
}

