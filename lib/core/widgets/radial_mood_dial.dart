import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/lab_colors.dart';
import 'mind_pressable.dart';

class MoodItem {
  const MoodItem({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

/// Radial Mood Selector Dial with glowing ripples and centered active face.
/// Matches Phone 3 ("Track Your Mood") in the master reference.
class RadialMoodDial extends StatelessWidget {
  const RadialMoodDial({
    super.key,
    required this.moods,
    required this.selectedIndex,
    required this.onChanged,
    this.showActiveLabel = true,
  });

  final List<MoodItem> moods;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool showActiveLabel;

  @override
  Widget build(BuildContext context) {
    final activeMood = moods[selectedIndex.clamp(0, moods.length - 1)];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Radial glowing dial area
        SizedBox(
          height: 180,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Concentric soft ripples
              CustomPaint(
                size: const Size(260, 180),
                painter: _RadialRipplesPainter(isDark: isDark),
              ),

              // Horizontal row of mood selections
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(moods.length, (index) {
                  final isSelected = index == selectedIndex;
                  final item = moods[index];

                  if (isSelected) {
                    // Center active large circular dial
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? LabColors.forestGreen : const Color(0xFF4A583E),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? LabColors.forestGreen : const Color(0xFF4A583E))
                                  .withValues(alpha: 0.35),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          item.icon,
                          size: 38,
                          color: const Color(0xFFF5EEE3),
                        ),
                      ),
                    );
                  }

                  // Surrounding subtle secondary faces
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: MindPressable(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onChanged(index);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                          border: Border.all(
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10),
                            width: 1.0,
                          ),
                        ),
                        child: Icon(
                          item.icon,
                          size: 22,
                          color: isDark ? LabColors.darkTextSecondary : LabColors.secondaryText,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),

        if (showActiveLabel) ...[
          const SizedBox(height: 12),
          // Bold active mood label
          Text(
            activeMood.label,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? LabColors.darkTextPrimary : LabColors.primaryText,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ],
    );
  }
}

class _RadialRipplesPainter extends CustomPainter {
  const _RadialRipplesPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rings = [48.0, 72.0, 100.0, 130.0];
    final alphas = [0.15, 0.10, 0.06, 0.03];

    for (int i = 0; i < rings.length; i++) {
      ringPaint.color = (isDark ? const Color(0xFFC7CDAD) : const Color(0xFF687157))
          .withValues(alpha: alphas[i]);
      canvas.drawCircle(center, rings[i], ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadialRipplesPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

