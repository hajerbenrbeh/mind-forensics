import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/app_strings.dart';
import '../../app/theme/lab_colors.dart';
import '../../features/investigation/domain/label_type.dart';

/// Minimalist, accessible badge representing Fact, Assumption, or Interpretation.
///
/// Geometric precision: 6px radius, hairline border, no emoji, high contrast.
/// Trilingual: Displays authentic localized label names (AR / FR / EN).
class LabelBadge extends ConsumerWidget {
  const LabelBadge({
    super.key,
    required this.label,
    this.showText = true,
    this.compact = false,
  });

  final LabelType label;
  final bool showText;
  final bool compact;

  IconData _iconForLabel() {
    switch (label) {
      case LabelType.fact:
        return Icons.check_circle_outline_rounded;
      case LabelType.assumption:
        return Icons.help_outline_rounded;
      case LabelType.interpretation:
        return Icons.lightbulb_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);
    final fgColor = LabColors.forLabel(label);
    final bgColor = LabColors.labelBackground(label, isDark: isDark);
    final borderColor = LabColors.labelBorder(label, isDark: isDark);

    final localizedName = strings.localizedLabelName(label);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 2.5 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Letter indicator (F, A, or I)
          Text(
            label.letter,
            style: TextStyle(
              fontSize: compact ? 10.5 : 11.5,
              fontWeight: FontWeight.w800,
              color: fgColor,
            ),
          ),
          const SizedBox(width: 4),
          // Icon indicator for non-color accessibility
          Icon(
            _iconForLabel(),
            size: compact ? 11 : 13,
            color: fgColor,
          ),
          if (showText) ...[
            const SizedBox(width: 5),
            Text(
              localizedName,
              style: TextStyle(
                fontSize: compact ? 10.5 : 11.5,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
