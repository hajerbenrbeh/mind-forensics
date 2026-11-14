import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../../../core/widgets/mind_pressable.dart';
import 'track_mood_utils.dart';

/// Two-column symmetric mood grid shared across Track Check-In Today and
/// past-entry editing sheets.
class TrackMoodPicker extends StatelessWidget {
  const TrackMoodPicker({
    super.key,
    required this.selectedMoodKey,
    required this.strings,
    required this.onSelect,
  });

  final String? selectedMoodKey;
  final AppStrings strings;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final normalizedSelected = selectedMoodKey?.trim().toLowerCase();

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final colWidth = ((constraints.maxWidth - spacing) / 2).clamp(
          112.0,
          360.0,
        );

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: trackCoreMoods.map((option) {
            final isSelected = normalizedSelected == option.key;
            final label = trackMoodLabel(option.key, strings);

            return SizedBox(
              width: colWidth,
              child: Semantics(
                button: true,
                selected: isSelected,
                label: label,
                child: MindPressable(
                  borderRadius: BorderRadius.circular(14),
                  onPressed: () => onSelect(option.key),
                  child: AnimatedContainer(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    constraints: const BoxConstraints(minHeight: 56),
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      12,
                      10,
                      12,
                      10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? option.color.withValues(alpha: 0.14)
                          : tokens.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? option.color : tokens.border,
                        width: isSelected ? 1.6 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: option.color.withValues(
                              alpha: isSelected ? 0.22 : 0.12,
                            ),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            option.icon,
                            size: 17,
                            color: option.color,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13.5,
                              height: 1.2,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: tokens.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: option.color,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Accessible 1-10 intensity slider with localized calm/overwhelmed anchors
/// and tabular live value readout.
class TrackIntensitySlider extends StatelessWidget {
  const TrackIntensitySlider({
    super.key,
    required this.value,
    required this.strings,
    required this.onChanged,
    this.inCard = true,
  });

  final double value;
  final AppStrings strings;
  final ValueChanged<double> onChanged;
  final bool inCard;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final clamped = value.clamp(1.0, 10.0);
    final rounded = clamped.round();

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                strings.moodIntensityLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tokens.accentSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: tokens.accent.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                '$rounded/10',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: tokens.accent,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Semantics(
          label: strings.moodIntensityLabel,
          value: '$rounded/10',
          slider: true,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: tokens.accent,
              inactiveTrackColor: tokens.border,
              thumbColor: tokens.textPrimary,
              overlayColor: tokens.accent.withValues(alpha: 0.12),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: clamped,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (next) {
                HapticFeedback.selectionClick();
                onChanged(next);
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  strings.calmScaleAnchor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: tokens.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  strings.overwhelmedScaleAnchor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: tokens.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!inCard) {
      return body;
    }

    return MindCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: body,
    );
  }
}

