import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../../mind_trace/domain/mind_trace_model.dart';

/// Clean, low-cognitive-load Daily Check-in Card for [HomeScreen].
///
/// Strictly options-first: responsive wrapped plain-language mood pills,
/// tactile 1-10 intensity slider, optional today's note, and zero telemetry
/// jargon or raw hex literals.
class HomeDailyCheckInCard extends StatelessWidget {
  const HomeDailyCheckInCard({
    super.key,
    required this.tokens,
    required this.strings,
    required this.isDark,
    required this.todayTrace,
    required this.traces,
    required this.selectedMoodIndex,
    required this.moodIntensity,
    required this.todayNoteController,
    required this.moodOptions,
    required this.onMoodSelected,
    required this.onIntensityChanged,
    required this.onSave,
    required this.getMoodLabel,
    required this.getMoodColor,
  });

  final MindTokens tokens;
  final AppStrings strings;
  final bool isDark;
  final MindTraceModel? todayTrace;
  final List<MindTraceModel> traces;
  final int selectedMoodIndex;
  final double moodIntensity;
  final TextEditingController todayNoteController;
  final List<({String key, IconData icon})> moodOptions;
  final ValueChanged<int> onMoodSelected;
  final ValueChanged<double> onIntensityChanged;
  final VoidCallback onSave;
  final String Function(String key, AppStrings strings) getMoodLabel;
  final Color Function(String key) getMoodColor;

  @override
  Widget build(BuildContext context) {
    final activeMood = moodOptions[selectedMoodIndex].key;
    final activeMoodColor = getMoodColor(activeMood);
    final hasLoggedToday = todayTrace != null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // Retrieve previous historical trace if today is not yet logged
    final previousTrace = traces.firstOrNull;
    final viewLabel = strings.isArabic
        ? 'عرض'
        : (strings.isFrench ? 'VOIR' : 'VIEW');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(color: tokens.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Authentic History Indicator: Today's recorded status or previous trace
          if (hasLoggedToday) ...[
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 4, 6),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: tokens.accentSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tokens.accent.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 16, color: tokens.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${strings.todayCheckInRecorded}: ${getMoodLabel(todayTrace!.overallMood, strings)} (${todayTrace!.moodIntensity}/10)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                  MindPressable(
                    onPressed: () => context.go(AppRouter.track),
                    semanticLabel: viewLabel,
                    borderRadius: BorderRadius.circular(10),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Center(
                          child: Text(
                            viewLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: tokens.accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (previousTrace != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: tokens.surfaceSecondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 15, color: tokens.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text:
                            '${strings.lastMoodLabel}: ${getMoodLabel(previousTrace.overallMood, strings)} (${previousTrace.moodIntensity}/10)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                        ),
                        children: [
                          if (previousTrace.journalText != null &&
                              previousTrace.journalText!.isNotEmpty)
                            TextSpan(
                              text: '  •  "${previousTrace.journalText!}"',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.italic,
                                color: tokens.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Header row: plain Intensity label + current state icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${strings.moodIntensityLabel.toUpperCase()}: ${moodIntensity.toInt()}/10',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.6,
                    color: tokens.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                moodOptions[selectedMoodIndex].icon,
                size: 20,
                color: activeMoodColor,
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Tactile 1-10 Intensity Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: activeMoodColor,
              thumbColor: activeMoodColor,
              inactiveTrackColor: tokens.surfaceSecondary,
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            ),
            child: Slider(
              value: moodIntensity,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                onIntensityChanged(val);
              },
            ),
          ),

          const SizedBox(height: 12),

          // Options-First Mood Pills (Wrapped cleanly — zero horizontal clipping)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(moodOptions.length, (index) {
              final option = moodOptions[index];
              final isSelected = index == selectedMoodIndex;
              final label = getMoodLabel(option.key, strings);
              final moodColor = getMoodColor(option.key);

              return MindPressable(
                onPressed: () => onMoodSelected(index),
                semanticLabel: label,
                borderRadius: BorderRadius.circular(tokens.chipRadius),
                child: AnimatedContainer(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? tokens.accentSoft : tokens.surface,
                    borderRadius: BorderRadius.circular(tokens.chipRadius),
                    border: Border.all(
                      color: isSelected ? moodColor : tokens.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        option.icon,
                        size: 16,
                        color: isSelected ? moodColor : tokens.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? tokens.textPrimary : tokens.textSecondary,
                          ),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: tokens.accent,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 14),

          // Optional "Today's note" field (Step 6 specification — never compulsory)
          TextField(
            controller: todayNoteController,
            maxLines: 2,
            minLines: 1,
            style: TextStyle(
              fontSize: 13.5,
              color: tokens.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: strings.isArabic
                  ? 'ملاحظة اليوم (اختياري)...'
                  : (strings.isFrench
                      ? 'Note du jour (optionnel)...'
                      : "Today's note (optional)..."),
              hintStyle: TextStyle(
                fontSize: 13,
                color: tokens.textTertiary,
              ),
              filled: true,
              fillColor: tokens.surfaceSecondary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: tokens.border, width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: tokens.border, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: tokens.accent, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Save / Update Primary Action Button (48dp minimum height, single hero CTA)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSave,
              icon: Icon(
                hasLoggedToday ? Icons.refresh_rounded : Icons.check_circle_outline_rounded,
                size: 18,
              ),
              label: Text(
                hasLoggedToday ? strings.updateCheckInButton : strings.saveCheckInButton,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: isDark ? tokens.background : Colors.white,
                minimumSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(tokens.buttonRadius),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
