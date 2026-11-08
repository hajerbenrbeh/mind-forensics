import 'package:flutter/material.dart';

import '../../../../app/theme/lab_colors.dart';

/// A 7-bar weekly mini chart showing stress and activation distribution.
///
/// Strictly renders authentic tracked observations for each day of the week.
/// Unrecorded days are rendered as subtle resting placeholder slots rather
/// than fabricated bars.
class HomeStressBarChart extends StatelessWidget {
  const HomeStressBarChart({
    super.key,
    required this.values,
    required this.isDark,
    this.height = 46.0,
  });

  /// 7 values for Monday through Sunday, where null indicates an unrecorded day.
  final List<double?> values;
  final bool isDark;
  final double height;

  static const List<Color> _barColors = [
    LabColors.moodAnxious,    // Warm Sand / Dune (replaces bright pink)
    LabColors.moodCalm,       // Soft Sage
    LabColors.moodHeavy,      // Soft Iris
    Color(0xFF819D8B),        // Muted Sage Mist
    LabColors.moodRestless,   // Soft Mineral Sky
    LabColors.moodCalm,       // Soft Sage
    LabColors.moodFrustrated, // Soft Amber
  ];

  @override
  Widget build(BuildContext context) {
    // Pad or trim to exactly 7 days
    final effectiveValues = List<double?>.generate(7, (i) {
      if (i < values.length) return values[i];
      return null;
    });

    final placeholderColor = isDark
        ? const Color(0xFF303E37)
        : const Color(0xFFD6DDD7);

    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final val = effectiveValues[index];
          final hasData = val != null;

          if (!hasData) {
            // Unrecorded day slot: small calm resting capsule
            return Container(
              width: 7.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: placeholderColor,
                borderRadius: BorderRadius.circular(2.0),
              ),
            );
          }

          final normalized = (val > 1.0 ? val / 10.0 : val).clamp(0.18, 1.0);
          final barColor = _barColors[index % _barColors.length];

          return Container(
            width: 7.0,
            height: height * normalized,
            decoration: BoxDecoration(
              color: barColor.withValues(alpha: isDark ? 0.85 : 0.95),
              borderRadius: BorderRadius.circular(4.0),
            ),
          );
        }),
      ),
    );
  }
}
