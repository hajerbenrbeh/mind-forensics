import 'package:flutter/material.dart';

import '../../app/theme/mind_tokens.dart';
import 'mind_pressable.dart';

/// Calm pill-based segmented selector built against [MindTokens].
///
/// Enforces minimum 48dp tap targets per option, non-color selection cues
/// (surface fill + border + font weight), reduced-motion safety, and RTL layout.
class MindSegmented extends StatelessWidget {
  const MindSegmented({
    super.key,
    required this.index,
    required this.labels,
    required this.onChanged,
  }) : assert(labels.length >= 2, 'MindSegmented requires at least two options');

  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final innerRadius = (tokens.buttonRadius - 4).clamp(6.0, 16.0);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: tokens.surfaceSecondary,
        borderRadius: BorderRadius.circular(tokens.buttonRadius),
        border: Border.all(color: tokens.border, width: 1.0),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: index == i,
                label: labels[i],
                child: MindPressable(
                  onPressed: () => onChanged(i),
                  borderRadius: BorderRadius.circular(innerRadius),
                  child: AnimatedContainer(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: index == i ? tokens.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(innerRadius),
                      border: index == i
                          ? Border.all(color: tokens.border, width: 1.0)
                          : null,
                      boxShadow: index == i && !isDark
                          ? [
                              BoxShadow(
                                color: tokens.textPrimary.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        height: 1.2,
                        fontWeight:
                            index == i ? FontWeight.w700 : FontWeight.w600,
                        color: index == i
                            ? tokens.textPrimary
                            : tokens.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

