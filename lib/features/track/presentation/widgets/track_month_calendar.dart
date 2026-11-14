import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../../mind_trace/domain/mind_trace_model.dart';
import 'track_mood_utils.dart';

/// Compact interactive month mood calendar embedded in Track -> History & Calendar.
///
/// Renders logged days with mood-colored dots and highlights, supports month
/// paging, and displays a selected-day summary strip with quick clear-filter.
class TrackMonthCalendar extends StatelessWidget {
  const TrackMonthCalendar({
    super.key,
    required this.month,
    required this.traces,
    required this.selectedDateKey,
    required this.strings,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.canGoNextMonth,
    required this.onSelectDateKey,
    this.onInspectTrace,
  });

  final DateTime month;
  final List<MindTraceModel> traces;
  final String? selectedDateKey;
  final AppStrings strings;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final bool canGoNextMonth;
  final ValueChanged<String?> onSelectDateKey;
  final ValueChanged<MindTraceModel>? onInspectTrace;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstDayOffset = DateTime(month.year, month.month, 1).weekday - 1;
    final now = DateTime.now();

    final loggedByDayKey = <String, MindTraceModel>{};
    for (final t in traces) {
      if (t.date.year == month.year && t.date.month == month.month) {
        loggedByDayKey[t.dateKey] = t;
      }
    }

    final selectedTrace =
        selectedDateKey != null ? loggedByDayKey[selectedDateKey] : null;
    final weekdays = strings.weekdayShortLabels;

    return MindCard(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_outlined, size: 17, color: tokens.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${strings.monthName(month.month)} ${month.year}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              IconButton(
                tooltip: strings.previousMonthTooltip,
                icon: Icon(
                  isRtl
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  size: 22,
                ),
                color: tokens.textPrimary,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: onPreviousMonth,
              ),
              IconButton(
                tooltip: strings.nextMonthTooltip,
                icon: Icon(
                  isRtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 22,
                ),
                color: canGoNextMonth ? tokens.textPrimary : tokens.textTertiary,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: canGoNextMonth ? onNextMonth : null,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            strings.calendarNoBreaksNote,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              height: 1.35,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((dayLabel) {
              return Expanded(
                child: Center(
                  child: Text(
                    dayLabel,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth + firstDayOffset,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 6,
              mainAxisExtent: 48,
            ),
            itemBuilder: (context, index) {
              if (index < firstDayOffset) {
                return const SizedBox.shrink();
              }
              final day = index - firstDayOffset + 1;
              final dayKey =
                  '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
              final matchedTrace = loggedByDayKey[dayKey];
              final isLogged = matchedTrace != null;
              final isSelected = selectedDateKey == dayKey;
              final isToday = day == now.day &&
                  month.month == now.month &&
                  month.year == now.year;

              final moodStyle = isLogged
                  ? trackMoodOptionFor(matchedTrace.overallMood)
                  : null;

              return MindPressable(
                semanticLabel: isLogged
                    ? '$dayKey ${trackMoodLabel(matchedTrace.overallMood, strings)}'
                    : dayKey,
                enabled: isLogged,
                borderRadius: BorderRadius.circular(10),
                onPressed: isLogged
                    ? () => onSelectDateKey(isSelected ? null : dayKey)
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tokens.accentSoft
                        : (isLogged
                            ? moodStyle!.color.withValues(alpha: 0.14)
                            : tokens.surfaceSecondary.withValues(alpha: 0.45)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? tokens.accent
                          : (isToday
                              ? tokens.accent.withValues(alpha: 0.7)
                              : (isLogged
                                  ? moodStyle!.color.withValues(alpha: 0.55)
                                  : tokens.border)),
                      width: isSelected || isToday ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isLogged || isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? tokens.accent
                              : (isLogged
                                  ? tokens.textPrimary
                                  : tokens.textSecondary),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (isLogged)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: moodStyle!.color,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (selectedDateKey != null) ...[
            const SizedBox(height: 12),
            _buildSelectedDayStrip(
              tokens: tokens,
              dateKey: selectedDateKey!,
              trace: selectedTrace,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedDayStrip({
    required MindTokens tokens,
    required String dateKey,
    required MindTraceModel? trace,
  }) {
    final moodStyle =
        trace != null ? trackMoodOptionFor(trace.overallMood) : null;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: tokens.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          if (trace != null && moodStyle != null) ...[
            Icon(moodStyle.icon, size: 17, color: moodStyle.color),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: InkWell(
              onTap: trace != null && onInspectTrace != null
                  ? () => onInspectTrace!(trace)
                  : null,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trace != null
                          ? '$dateKey • ${trackMoodLabel(trace.overallMood, strings)} (${trace.moodIntensity}/10)'
                          : strings.filteredByDateLabel(dateKey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (trace?.journalText != null &&
                        trace!.journalText!.trim().isNotEmpty)
                      Text(
                        trace.journalText!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: tokens.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          MindPressable(
            semanticLabel: strings.showAllEntriesBtn,
            borderRadius: BorderRadius.circular(10),
            onPressed: () => onSelectDateKey(null),
            child: Container(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              child: Text(
                strings.showAllEntriesBtn,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: tokens.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
