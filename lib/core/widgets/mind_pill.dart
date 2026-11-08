import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/lab_colors.dart';
import '../../app/theme/mind_tokens.dart';
import 'mind_pressable.dart';

/// Reusable pill component for time selectors, category tags, and filter chips.
/// Matches the master reference specification (Phones 3, 4, 7).
class MindPill extends StatelessWidget {
  const MindPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.fontSize = 12.5,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeBg = isDark ? tokens.accent : LabColors.forestGreen;
    final activeFg = isDark ? LabColors.darkForestBackground : Colors.white;
    final inactiveBg = isDark ? LabColors.darkForestSurface : LabColors.secondaryIvory;
    final inactiveFg = isDark ? LabColors.darkTextSecondary : LabColors.secondaryText;
    final borderColor = isDark ? LabColors.darkForestBorder : LabColors.borderIvory;

    return MindPressable(
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: padding,
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeBg : borderColor,
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeBg.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: fontSize + 1,
                color: isSelected ? activeFg : inactiveFg,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? activeFg : inactiveFg,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

