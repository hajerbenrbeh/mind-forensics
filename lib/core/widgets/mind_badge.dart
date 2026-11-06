import 'package:flutter/material.dart';
import '../../app/theme/mind_tokens.dart';

/// Semantic pill/badge for Mind Forensics. Zero emojis, vector outline or text only.
class MindBadge extends StatelessWidget {
  const MindBadge({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.isSelected = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBg = isSelected
        ? (isDark ? tokens.accent : tokens.textPrimary)
        : (backgroundColor ?? tokens.surfaceSecondary);
    final defaultFg = isSelected
        ? (isDark ? const Color(0xFF151B19) : Colors.white)
        : (textColor ?? tokens.textPrimary);
    final defaultBorder = isSelected
        ? Colors.transparent
        : (borderColor ?? tokens.border);

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: defaultBg,
        borderRadius: BorderRadius.circular(tokens.chipRadius),
        border: Border.all(color: defaultBorder, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: defaultFg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: defaultFg,
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: Semantics(
          button: true,
          selected: isSelected,
          label: label,
          child: badge,
        ),
      );
    }

    return badge;
  }
}

