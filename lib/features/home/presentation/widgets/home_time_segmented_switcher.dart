import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/mind_tokens.dart';

/// A modern capsule pill segmented switcher ("Month | Week | Day").
///
/// Designed with generous 30.0px corner rounding and smooth sliding pill
/// selection adhering to the project's Earth/Sage design system.
class HomeTimeSegmentedSwitcher extends StatelessWidget {
  const HomeTimeSegmentedSwitcher({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    required this.labels,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final trackBg = isDark ? tokens.surfaceSecondary : const Color(0xFFE5ECE6);
    final activePillBg = isDark ? const Color(0xFF303E37) : const Color(0xFF34443B);
    final activeTextColor = isDark ? const Color(0xFFF0F2EC) : Colors.white;
    final inactiveTextColor = tokens.textSecondary;

    return Container(
      height: 44.0,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: trackBg,
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isSelected) {
                  HapticFeedback.selectionClick();
                  onChanged(index);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? activePillBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(26.0),
                  boxShadow: isSelected && !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4.0,
                            offset: const Offset(0, 1.5),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? activeTextColor : inactiveTextColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

