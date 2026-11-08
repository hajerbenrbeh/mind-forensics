import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/mind_tokens.dart';

/// A 7-day horizontal mood status row showing authentic weekly check-in records.
///
/// Displays day letters (M, T, W, T, F, S, S) above circular badges with real
/// calendar dates. Only days with authentic user entries are colored; unrecorded
/// days are clearly indicated with neutral resting surfaces.
class HomeWeekMoodTracker extends StatelessWidget {
  const HomeWeekMoodTracker({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
    this.recordedMoodDays = const {},
  });

  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  /// Map of date key ('yyyy-MM-dd') to authentic recorded mood color.
  final Map<String, Color> recordedMoodDays;

  static const List<String> _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  List<DateTime> _getCurrentWeekDates() {
    final now = DateTime.now();
    // Monday as day 1 of the week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) => DateTime(monday.year, monday.month, monday.day + i));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weekDates = _getCurrentWeekDates();
    final today = DateTime.now();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final date = weekDates[index];
        final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
        final isSelected = date.year == selectedDay.year &&
            date.month == selectedDay.month &&
            date.day == selectedDay.day;

        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final recordedColor = recordedMoodDays[dateKey];
        final isRecorded = recordedColor != null;

        // Authentic coloring: only recorded days get the mood tint;
        // selected unrecorded days get a subtle theme-accent tint.
        final circleBg = isRecorded
            ? recordedColor
            : (isSelected
                ? tokens.accentSoft
                : tokens.surfaceSecondary);

        final textColor = isRecorded
            ? Colors.white
            : (isSelected || isToday ? tokens.textPrimary : tokens.textSecondary);

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _dayLetters[index],
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isToday || isSelected ? tokens.textPrimary : tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 7),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onDaySelected(date);
                },
                child: Container(
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: circleBg,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: tokens.accent,
                            width: 2.2,
                          )
                        : (isToday
                            ? Border.all(
                                color: isDark ? const Color(0xFFF0F2EC) : const Color(0xFF34443B),
                                width: 1.8,
                              )
                            : (isRecorded
                                ? null
                                : Border.all(
                                    color: tokens.border.withValues(alpha: 0.7),
                                    width: 1.0,
                                  ))),
                    boxShadow: isRecorded
                        ? [
                            BoxShadow(
                              color: recordedColor.withValues(alpha: 0.24),
                              blurRadius: 4.0,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: isRecorded || isToday ? FontWeight.w700 : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
