import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/bouncing_widget.dart';
import '../../../../core/widgets/neural_waveform_visualizer.dart';
import '../../../mind_trace/domain/mind_trace_model.dart';

/// Clean, modular Daily Check-in Card for HomeScreen.
/// Strictly options-first: emotion pills, tactile 1-10 intensity slider,
/// real-time neural waveform visualizer, and optional today's note.
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

    // Retrieve previous historical trace if today is not yet logged
    final previousTrace = traces.firstOrNull;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: tokens.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Authentic History Indicator: Today's recorded status or previous trace
          if (hasLoggedToday) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF26322C) : const Color(0xFFE5ECE6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tokens.accent.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 15, color: tokens.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${strings.todayCheckInRecorded}: ${getMoodLabel(todayTrace!.overallMood, strings)} (${todayTrace!.moodIntensity}/10)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/mind-trace'),
                    child: Text(
                      (strings.isArabic
                              ? 'عرض'
                              : (strings.isFrench ? 'VOIR' : 'VIEW'))
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (previousTrace != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF26322C) : const Color(0xFFE5ECE6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 15, color: tokens.accent),
                  const SizedBox(width: 8),
                  Text(
                    '${strings.lastMoodLabel.toUpperCase()}: ${getMoodLabel(previousTrace.overallMood, strings)} (${previousTrace.moodIntensity}/10)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                  if (previousTrace.journalText != null && previousTrace.journalText!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '•  "${previousTrace.journalText!}"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${strings.moodIntensityLabel.toUpperCase()}: ${moodIntensity.toInt()}/10',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.5,
                  color: tokens.textSecondary,
                ),
              ),
              Icon(
                moodOptions[selectedMoodIndex].icon,
                size: 20,
                color: activeMoodColor,
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: activeMoodColor,
              thumbColor: activeMoodColor,
              inactiveTrackColor: isDark ? const Color(0xFF303E37) : const Color(0xFFE5ECE6),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
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
          const SizedBox(height: 10),

          // Real-time animated neural waveform canvas
          NeuralWaveformVisualizer(
            intensity: moodIntensity,
            moodColor: activeMoodColor,
            isDark: isDark,
            strings: strings,
          ),

          const SizedBox(height: 14),

          // Emotion selector pills (24px radius)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(moodOptions.length, (index) {
                final option = moodOptions[index];
                final isSelected = index == selectedMoodIndex;
                final label = getMoodLabel(option.key, strings);
                final moodColor = getMoodColor(option.key);

                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: BouncingWidget(
                    onTap: () => onMoodSelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFF303E37) : const Color(0xFFE5ECE6))
                            : tokens.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected ? moodColor : tokens.border,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            option.icon,
                            size: 15,
                            color: isSelected ? moodColor : tokens.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? tokens.textPrimary : tokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 14),

          // Optional "Today's note" field (Step 6 specification)
          TextField(
            controller: todayNoteController,
            maxLines: 2,
            minLines: 1,
            style: TextStyle(
              fontSize: 12.5,
              color: tokens.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: strings.isArabic
                  ? 'ملاحظة اليوم (اختياري)...'
                  : (strings.isFrench
                      ? 'Note du jour (optionnel)...'
                      : "Today's note (optional)..."),
              hintStyle: TextStyle(
                fontSize: 12,
                color: tokens.textTertiary,
              ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF1E2824)
                  : const Color(0xFFF3EFE6),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tokens.border, width: 0.8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tokens.border, width: 0.8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tokens.accent, width: 1.2),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Save / Update Action Button (20px pill radius)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              onPressed: onSave,
              icon: Icon(
                hasLoggedToday ? Icons.refresh_rounded : Icons.check_circle_outline_rounded,
                size: 16,
              ),
              label: Text(hasLoggedToday ? strings.updateCheckInButton : strings.saveCheckInButton),
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? tokens.accent : const Color(0xFF34443B),
                foregroundColor: isDark ? const Color(0xFF151B19) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

