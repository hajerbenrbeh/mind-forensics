import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/lab_colors.dart';

/// Minimalist, interactive somatosensory anatomical body scanner.
///
/// Allows the user to physically tap where the nervous system registers distress
/// (Head, Jaw, Throat, Chest, Gut, Hands) with biometric glowing halos and haptic pulses.
class SomaticBodyRadar extends StatefulWidget {
  const SomaticBodyRadar({
    super.key,
    required this.selectedSensation,
    required this.onSensationSelected,
    required this.isDark,
    required this.arousalIntensity,
  });

  final String? selectedSensation;
  final ValueChanged<String> onSensationSelected;
  final bool isDark;
  final double arousalIntensity;

  @override
  State<SomaticBodyRadar> createState() => _SomaticBodyRadarState();
}

class _SomaticBodyRadarState extends State<SomaticBodyRadar> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  static const List<({String id, String label, double normX, double normY, IconData icon})> _nodes = [
    (id: 'cranial', label: 'Cranial / Head', normX: 0.50, normY: 0.16, icon: Icons.psychology_outlined),
    (id: 'jaw', label: 'Jaw / Cervical', normX: 0.50, normY: 0.30, icon: Icons.sentiment_neutral_outlined),
    (id: 'throat', label: 'Throat / Larynx', normX: 0.50, normY: 0.42, icon: Icons.graphic_eq_rounded),
    (id: 'chest', label: 'Thoracic / Chest', normX: 0.50, normY: 0.58, icon: Icons.favorite_outline_rounded),
    (id: 'gut', label: 'Solar Plexus / Gut', normX: 0.50, normY: 0.74, icon: Icons.radio_button_checked_rounded),
    (id: 'extremities', label: 'Extremities / Hands', normX: 0.22, normY: 0.84, icon: Icons.touch_app_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  void _syncAnimation() {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!isTest && !reduceMotion) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
      }
      _pulseController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool _isNodeActive(String nodeId) {
    final sel = widget.selectedSensation?.toLowerCase() ?? '';
    switch (nodeId) {
      case 'cranial':
        return sel.contains('head') || sel.contains('pressure') || sel.contains('tête') || sel.contains('رأس');
      case 'jaw':
        return sel.contains('jaw') || sel.contains('teeth') || sel.contains('mâchoire') || sel.contains('فك');
      case 'throat':
        return sel.contains('throat') || sel.contains('knot') || sel.contains('gorge') || sel.contains('حلق');
      case 'chest':
        return sel.contains('chest') || sel.contains('heart') || sel.contains('poitrine') || sel.contains('صدر') || sel.contains('pulse');
      case 'gut':
        return sel.contains('stomach') || sel.contains('ventre') || sel.contains('بطن') || sel.contains('gut') || sel.contains('nausea');
      case 'extremities':
        return sel.contains('hand') || sel.contains('arm') || sel.contains('mains') || sel.contains('يد') || sel.contains('tremor');
      default:
        return false;
    }
  }

  Color get _activeAccentColor {
    return widget.arousalIntensity >= 7
        ? LabColors.cherryRed
        : (widget.arousalIntensity >= 4 ? LabColors.warmBeige : LabColors.factBlue);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final surfaceColor = isDark ? const Color(0xFF0C0C0C) : const Color(0xFFF9FAFB);
    final borderColor = isDark ? const Color(0xFF222222) : const Color(0xFFE4E4E7);
    final accent = _activeAccentColor;

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            // Architectural Grid Background
            ExcludeSemantics(
              child: CustomPaint(
                size: Size.infinite,
                painter: _SilhouettePainter(isDark: isDark, activeAccent: accent),
              ),
            ),

            // Interactive Bio-Points Layer
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                final reduceMotion = MediaQuery.disableAnimationsOf(context);

                return Stack(
                  children: _nodes.map((node) {
                    final isActive = _isNodeActive(node.id);
                    final px = node.normX * w;
                    final py = node.normY * h;

                    return Positioned(
                      left: px - 24,
                      top: py - 24,
                      child: Semantics(
                        button: true,
                        selected: isActive,
                        label: node.label,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onSensationSelected(node.label);
                          },
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              final scale = (isActive && !reduceMotion)
                                  ? _pulseAnimation.value
                                  : 1.0;
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Glowing Halo when Active
                                if (isActive)
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: accent.withValues(alpha: isDark ? 0.35 : 0.25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accent.withValues(alpha: isDark ? 0.6 : 0.4),
                                          blurRadius: 14,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),

                                // Precision Vector Node Point
                                Container(
                                  width: isActive ? 18 : 12,
                                  height: isActive ? 18 : 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isActive
                                        ? accent
                                        : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFD4D4D8)),
                                    border: Border.all(
                                      color: isActive
                                          ? Colors.white
                                          : (isDark ? const Color(0xFF404040) : const Color(0xFFA1A1AA)),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isActive ? Colors.black : Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    );
                  }).toList(),
                );
              },
            ),

            // Top Status Label
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'SOMATOSENSORY RADAR',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: isDark ? const Color(0xFF888888) : const Color(0xFF71717A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TAP TO LOCATE',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? const Color(0xFF555555) : const Color(0xFFA1A1AA),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Architectural Minimalist Human Silhouette Painter.
class _SilhouettePainter extends CustomPainter {
  const _SilhouettePainter({required this.isDark, required this.activeAccent});

  final bool isDark;
  final Color activeAccent;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = (isDark ? const Color(0xFF1B1B1B) : const Color(0xFFE4E4E7))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final centerX = size.width * 0.5;

    // Draw subtle grid crosshairs
    canvas.drawLine(Offset(centerX, 20), Offset(centerX, size.height - 20), linePaint);
    canvas.drawLine(Offset(size.width * 0.2, size.height * 0.5), Offset(size.width * 0.8, size.height * 0.5), linePaint);

    final bodyPaint = Paint()
      ..color = (isDark ? const Color(0xFF262626) : const Color(0xFFD4D4D8))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Head Contour
    final headRect = Rect.fromCenter(center: Offset(centerX, size.height * 0.16), width: 34, height: 42);
    canvas.drawOval(headRect, bodyPaint);

    // Neck Contour
    canvas.drawLine(Offset(centerX - 8, size.height * 0.21), Offset(centerX - 9, size.height * 0.32), bodyPaint);
    canvas.drawLine(Offset(centerX + 8, size.height * 0.21), Offset(centerX + 9, size.height * 0.32), bodyPaint);

    // Shoulders & Torso Contours
    final torsoPath = Path()
      ..moveTo(centerX - 9, size.height * 0.32)
      ..lineTo(centerX - 52, size.height * 0.40) // Left shoulder
      ..lineTo(centerX - 46, size.height * 0.72) // Left flank
      ..lineTo(centerX - 36, size.height * 0.88) // Left hip
      ..lineTo(centerX + 36, size.height * 0.88) // Right hip
      ..lineTo(centerX + 46, size.height * 0.72) // Right flank
      ..lineTo(centerX + 52, size.height * 0.40) // Right shoulder
      ..lineTo(centerX + 9, size.height * 0.32);

    canvas.drawPath(torsoPath, bodyPaint);

    // Left Arm Contour (Towards extremities point)
    final armPaint = Paint()
      ..color = (isDark ? const Color(0xFF202020) : const Color(0xFFE4E4E7))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(centerX - 52, size.height * 0.40), Offset(size.width * 0.22, size.height * 0.82), armPaint);
    canvas.drawLine(Offset(centerX + 52, size.height * 0.40), Offset(size.width * 0.78, size.height * 0.82), armPaint);
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.activeAccent != activeAccent;
  }
}

