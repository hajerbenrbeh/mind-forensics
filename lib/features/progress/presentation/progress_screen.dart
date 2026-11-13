import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/lab_colors.dart';
import '../../../app/theme/lab_theme.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../mind_trace/presentation/widgets/trace_entry_detail_sheet.dart';
import '../data/progress_analytics_service.dart';
import '../domain/progress_analytics_model.dart';

/// My Progress: A sophisticated, non-judgmental personal psychological history.
///
/// Features:
/// - The Thought Trace: Editorial timeline mapping real daily reflections.
/// - Emotional Overview: Frequency distribution, emotional granularity, intensity timeline.
/// - Somatic & Sleep Insights: Empirical observations (energy, sleep duration, sleep quality, tension).
/// - Calendar Map & Entry History: Non-punitive calendar with open, edit, and delete options.
/// - Reflection Archive: Searchable chronological archive of user reflections across the app.
/// - Journey History & Reflective Milestones: Cumulative milestones honoring self-awareness without streaks.
/// - Patterns Worth Exploring: Transparent local heuristic observations with dismiss option.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _reflectionSearchController = TextEditingController();

  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  MindTraceModel? _selectedCalendarTrace;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reflectionSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);
    final analytics = ref.watch(progressAnalyticsProvider);
    final selectedWindow = ref.watch(selectedTimeWindowProvider);

    final bg = isDark ? LabColors.nightBackground : LabColors.daylightBackground;
    final surfaceColor = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final borderColor = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary = isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary = isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          strings.progressTitle,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: textPrimary,
          ),
        ),
        actions: const [
          SupportButton(),
          SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: context.tokens.accent,
          labelColor: context.tokens.accent,
          unselectedLabelColor: textSecondary,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: strings.progressTabThoughtTrace),
            Tab(text: strings.progressTabCalendar),
            Tab(text: strings.progressTabReflections),
            Tab(text: strings.progressTabMilestones),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Quote & Time Window Selector
            _buildHeaderControls(
              selectedWindow: selectedWindow,
              isDark: isDark,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              strings: strings,
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 0: Thought Trace & Overview
                  _buildThoughtTraceAndOverviewTab(
                    analytics: analytics,
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    strings: strings,
                  ),

                  // Tab 1: Calendar & Entries
                  _buildCalendarAndEntriesTab(
                    analytics: analytics,
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    strings: strings,
                  ),

                  // Tab 2: Reflection Archive
                  _buildReflectionArchiveTab(
                    analytics: analytics,
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    strings: strings,
                  ),

                  // Tab 3: Milestones & Journey
                  _buildMilestonesAndJourneyTab(
                    analytics: analytics,
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    strings: strings,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // HEADER CONTROLS (QUOTE & TIME WINDOW)
  // ===========================================================================
  Widget _buildHeaderControls({
    required ProgressTimeWindow selectedWindow,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required AppStrings strings,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Framing psychological quote
          Text(
            '"${strings.progressQuote}"',
            style: LabTheme.editorialSerif(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: context.tokens.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),

          // Time Period Selector Row
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ProgressTimeWindow.values.map((window) {
                      final isSelected = selectedWindow == window;
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: BouncingWidget(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref.read(selectedTimeWindowProvider.notifier).setWindow(window);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.tokens.accentSoft
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? context.tokens.accent : borderColor,
                                width: isSelected ? 1.2 : 0.8,
                              ),
                            ),
                            child: Text(
                              window.label(strings),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                letterSpacing: 0.4,
                                color: isSelected ? context.tokens.accent : textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Active Date Range Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.tokens.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor, width: 0.6),
                ),
                child: Text(
                  selectedWindow.formattedDateRange(DateTime.now(), strings),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 0: THOUGHT TRACE & OVERVIEW
  // ===========================================================================
  Widget _buildThoughtTraceAndOverviewTab({
    required ProgressAnalyticsModel analytics,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required AppStrings strings,
  }) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // 1. The Thought Trace (Signature Centerpiece)
        _buildThoughtTraceSummaryCard(
          analytics: analytics,
          isDark: isDark,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          strings: strings,
        ),

        const SizedBox(height: 16),

        // 2. Key Metrics Row (Entries, Days, Emotion Selections)
        _buildKeyMetricsRow(
          analytics: analytics,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          strings: strings,
        ),

        const SizedBox(height: 16),

        // 3. Emotional Frequency Spectrum
        _buildEmotionalSpectrumCard(
          analytics: analytics,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          strings: strings,
        ),

        const SizedBox(height: 16),

        // 4. Emotional Granularity / Variety Card
        _buildEmotionalGranularityCard(
          analytics: analytics,
          isDark: isDark,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          strings: strings,
        ),

        const SizedBox(height: 16),

        // 5. Mood Intensity Timeline
        _buildMoodIntensityTimelineCard(
          analytics: analytics,
          isDark: isDark,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          strings: strings,
        ),

        const SizedBox(height: 16),

        // 6. Somatic & Sleep Empirical Insights
        _buildSomaticAndSleepCard(
          analytics: analytics,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          strings: strings,
        ),

        // 7. Patterns Worth Exploring (Cautious Local Insights)
        if (analytics.insights.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildPatternsWorthExploringSection(
            insights: analytics.insights,
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            strings: strings,
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildThoughtTraceSummaryCard({
    required ProgressAnalyticsModel analytics,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required AppStrings strings,
  }) {
    final traces = analytics.chronologicalTraces;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.fingerprint_rounded, size: 16, color: context.tokens.accent),
                    const SizedBox(width: 8),
                    Text(
                      strings.thoughtTraceTitle.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: context.tokens.accent,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${traces.length} ${strings.isArabic ? 'أثر' : (strings.isFrench ? 'Empreintes' : 'Traces')}',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: textSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              strings.thoughtTraceQuote,
              style: LabTheme.editorialSerif(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (traces.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      strings.thoughtTraceWaitingTitle,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: LabColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings.thoughtTraceWaitingSub,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.push(AppRouter.mindTrace),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LabColors.textPrimary,
                        foregroundColor: LabColors.surface0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: Text(
                        strings.recordTodayTraceBtn,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Latest 3 traces in an editorial mini-timeline
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: traces.reversed.take(3).map((trace) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: BouncingWidget(
                      onTap: () {
                        ThoughtTraceDetailSheet.show(
                          context,
                          trace: trace,
                          onEdit: () => context.push(AppRouter.mindTrace),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? LabColors.surface0 : const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor, width: 0.8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  trace.dateKey,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: textSecondary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: context.tokens.accentSoft,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: context.tokens.accent.withValues(alpha: 0.3), width: 0.6),
                                  ),
                                  child: Text(
                                    '${trace.overallMood.toUpperCase()} • ${trace.moodIntensity}/10',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: context.tokens.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '“${trace.thoughtPreview}”',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 12.5,
                                fontStyle: FontStyle.italic,
                                color: textPrimary,
                                height: 1.35,
                              ),
                            ),
                            if (trace.selectedEmotions.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                children: trace.selectedEmotions.take(3).map((e) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: context.tokens.surfaceSecondary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      e,
                                      style: TextStyle(fontSize: 9.5, color: textSecondary),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Button to open full The Thought Trace in Mind Trace screen
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => context.push(AppRouter.mindTrace),
                  icon: Icon(Icons.timeline_rounded, size: 14, color: context.tokens.accent),
                  label: Text(
                    strings.isArabic
                        ? 'فتح الخط الزمني الكامل لأثر الأفكار'
                        : (strings.isFrench
                            ? 'OUVRIR LA CHRONOLOGIE COMPLÈTE'
                            : 'OPEN FULL THOUGHT TRACE TIMELINE'),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: context.tokens.accent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKeyMetricsRow({
    required ProgressAnalyticsModel analytics,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required AppStrings strings,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: strings.totalEntriesMetric,
            value: '${analytics.totalEntries}',
            subtitle: strings.isArabic
                ? 'تدوينات مسجلة'
                : (strings.isFrench ? 'Entrées enregistrées' : 'Logged entries'),
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: strings.uniqueDaysMetric,
            value: '${analytics.uniqueDaysCount}',
            subtitle: strings.isArabic
                ? 'أيام مميزة'
                : (strings.isFrench ? 'Jours distincts' : 'Unique days'),
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: strings.emotionSelectionsMetric,
            value: '${analytics.totalEmotionSelections}',
            subtitle: strings.isArabic
                ? 'تحديدات للمشاعر'
                : (strings.isFrench ? 'Étiquettes émotionnelles' : 'Emotion tags'),
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              color: textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionalSpectrumCard({
    required ProgressAnalyticsModel analytics,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required AppStrings strings,
  }) {
    final entries = analytics.emotionFrequencies.entries.take(5).toList();
    final total = analytics.totalEntries > 0 ? analytics.totalEntries : 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(context.tokens.cardRadius),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.emotionalSpectrumTitle,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: textSecondary,
                ),
              ),
              Text(
                '${analytics.emotionalVarietyCount} ${strings.isArabic ? 'مشاعر مختلفة' : (strings.isFrench ? 'Identifiées' : 'Identified')}',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: context.tokens.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text(
              strings.isArabic
                  ? 'لا توجد مشاعر مفصلة مسجلة في هذه الفترة الزمنية.'
                  : (strings.isFrench
                      ? 'Aucune émotion spécifique enregistrée sur cette période.'
                      : 'No specific emotions tagged in this timeframe.'),
              style: TextStyle(fontSize: 11.5, color: textSecondary),
            )
          else
            ...entries.map((entry) {
              final ratio = (entry.value / total).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          '${(ratio * 100).toInt()}% (${entry.value})',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 5,
                        backgroundColor: context.tokens.surfaceSecondary,
                        valueColor: AlwaysStoppedAnimation<Color>(context.tokens.accent),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmotionalGranularityCard({
    required ProgressAnalyticsModel analytics,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required AppStrings strings,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(context.tokens.cardRadius),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.tokens.accentSoft,
              border: Border.all(color: context.tokens.accent.withValues(alpha: 0.35), width: 0.8),
            ),
            child: Icon(
              Icons.palette_outlined,
              size: 20,
              color: context.tokens.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.emotionalVarietyTitle,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: context.tokens.accent,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  strings.distinctEmotionsCount(analytics.emotionalVarietyCount),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  strings.isArabic
                      ? 'التمييز الدقيق بين المشاعر ينشط القشرة الجبهية ويعزز التنظيم الانفعالي.'
                      : (strings.isFrench
                          ? 'Nommer ses émotions avec finesse réduit la réactivité du système limbique.'
                          : 'Granular emotional naming activates prefrontal regulation and dampens limbic arousal.'),
                  style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodIntensityTimelineCard({
    required ProgressAnalyticsModel analytics,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required AppStrings strings,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.intensityTimelineTitle,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: textSecondary,
                ),
              ),
              Text(
                '${analytics.averageIntensity.toStringAsFixed(1)} / 10',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: context.tokens.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            strings.intensityMinMax(analytics.minIntensity, analytics.maxIntensity),
            style: TextStyle(fontSize: 10.5, color: textSecondary),
          ),
          const SizedBox(height: 14),

          // Micro timeline bars
          if (analytics.intensityTimeline.isEmpty)
            Text(
              strings.isArabic
                  ? 'لا توجد بيانات كافية لعرض المنحنى.'
                  : (strings.isFrench
                      ? 'Aucune donnée d’intensité sur cette période.'
                      : 'No intensity data in this timeframe.'),
              style: TextStyle(fontSize: 11.5, color: textSecondary),
            )
          else ...[
            SizedBox(
              height: 56,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: analytics.intensityTimeline.map((item) {
                  final heightRatio = (item.intensity / 10.0).clamp(0.1, 1.0);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Tooltip(
                        message: '${item.date.month}/${item.date.day}: ${item.mood} (${item.intensity}/10)',
                        child: Container(
                          height: 56 * heightRatio,
                          decoration: BoxDecoration(
                            color: item.intensity >= 7
                                ? context.tokens.safetyWarmth.withValues(alpha: 0.75)
                                : context.tokens.accent.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${analytics.intensityTimeline.first.date.month}/${analytics.intensityTimeline.first.date.day}',
                  style: TextStyle(fontSize: 9.5, color: textSecondary),
                ),
                Text(
                  '${analytics.intensityTimeline.last.date.month}/${analytics.intensityTimeline.last.date.day}',
                  style: TextStyle(fontSize: 9.5, color: textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSomaticAndSleepCard({
    required ProgressAnalyticsModel analytics,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required AppStrings strings,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bedtime_outlined, size: 16, color: LabColors.warmBeige),
              const SizedBox(width: 8),
              Text(
                strings.energyAndSleepTitle,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: LabColors.warmBeige,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 Empirical Metric Pills
          Row(
            children: [
              Expanded(
                child: _buildSubMetricPill(
                  label: strings.avgEnergyMetric,
                  value: analytics.averageEnergy != null
                      ? '${analytics.averageEnergy!.toStringAsFixed(1)}/10'
                      : '--',
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSubMetricPill(
                  label: strings.avgSleepMetric,
                  value: analytics.averageSleepDuration != null
                      ? '${analytics.averageSleepDuration!.toStringAsFixed(1)}h'
                      : '--',
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSubMetricPill(
                  label: strings.avgQualityMetric,
                  value: analytics.averageSleepQuality != null
                      ? '${analytics.averageSleepQuality!.toStringAsFixed(1)}/5'
                      : '--',
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
            ],
          ),

          if (analytics.sleepTensionObservation != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.tokens.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    analytics.sleepTensionObservation!,
                    style: TextStyle(fontSize: 11.5, color: textPrimary, height: 1.35),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.empiricalDisclaimer,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: textSecondary.withValues(alpha: 0.8),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubMetricPill({
    required String label,
    required String value,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.tokens.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternsWorthExploringSection({
    required List<PersonalInsightItem> insights,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required AppStrings strings,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.patternsWorthExploringTitle,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strings.patternsSub,
          style: TextStyle(fontSize: 11, color: textSecondary),
        ),
        const SizedBox(height: 12),
        ...insights.map((ins) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(ins.icon, size: 16, color: context.tokens.accent),
                        const SizedBox(width: 8),
                        Text(
                          ins.title,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref.read(dismissedInsightsProvider.notifier).dismiss(ins.id);
                      },
                      child: Text(
                        strings.dismissInsight,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ins.description,
                  style: TextStyle(fontSize: 12, color: textPrimary, height: 1.35),
                ),
                const SizedBox(height: 6),
                Text(
                  ins.caveat,
                  style: TextStyle(fontSize: 10, color: textSecondary, height: 1.25),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // TAB 1: CALENDAR & ENTRIES
  // ===========================================================================
  Widget _buildCalendarAndEntriesTab({
    required ProgressAnalyticsModel analytics,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required AppStrings strings,
  }) {
    final traces = ref.watch(mindTraceControllerProvider).value ?? [];
    final monthTraces = traces.where((t) {
      return t.date.year == _calendarMonth.year && t.date.month == _calendarMonth.month;
    }).toList();

    final loggedMap = <String, MindTraceModel>{
      for (final t in traces) t.dateKey: t,
    };

    final daysInMonth = DateUtils.getDaysInMonth(_calendarMonth.year, _calendarMonth.month);
    final firstDayOffset = DateTime(_calendarMonth.year, _calendarMonth.month, 1).weekday - 1; // Mon = 0

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // 1. Month Calendar Heatmap
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month Switcher Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 16, color: context.tokens.accent),
                      const SizedBox(width: 8),
                      Text(
                        '${_getMonthName(_calendarMonth.month, strings).toUpperCase()} ${_calendarMonth.year}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: context.tokens.accent,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20),
                        color: textPrimary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1);
                            _selectedCalendarTrace = null;
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20),
                        color: textPrimary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          final nextMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1);
                          final now = DateTime.now();
                          if (nextMonth.isBefore(DateTime(now.year, now.month + 1))) {
                            setState(() {
                              _calendarMonth = nextMonth;
                              _selectedCalendarTrace = null;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                strings.calendarNoBreaksNote,
                style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
              ),
              const SizedBox(height: 16),

              // Day of week labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
                  return SizedBox(
                    width: 32,
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              // Calendar Days Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: daysInMonth + firstDayOffset,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  if (index < firstDayOffset) {
                    return const SizedBox.shrink();
                  }
                  final day = index - firstDayOffset + 1;
                  final dayKey =
                      '${_calendarMonth.year.toString().padLeft(4, '0')}-${_calendarMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                  final matchedTrace = loggedMap[dayKey];
                  final isLogged = matchedTrace != null;
                  final now = DateTime.now();
                  final isToday = day == now.day &&
                      _calendarMonth.month == now.month &&
                      _calendarMonth.year == now.year;
                  final isSelected = _selectedCalendarTrace?.dateKey == dayKey;

                  return BouncingWidget(
                    onTap: isLogged
                        ? () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedCalendarTrace = matchedTrace);
                          }
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.tokens.accent
                            : (isLogged
                                ? context.tokens.accentSoft
                                : context.tokens.surfaceSecondary),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isToday
                              ? context.tokens.accent
                              : (isSelected
                                  ? context.tokens.accent
                                  : (isLogged
                                      ? context.tokens.accent.withValues(alpha: 0.35)
                                      : borderColor)),
                          width: isToday || isSelected ? 1.5 : 0.8,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isLogged || isToday ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? context.tokens.background : Colors.white)
                                : (isLogged
                                    ? context.tokens.accent
                                    : (isToday ? textPrimary : textSecondary.withValues(alpha: 0.5))),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Selected Calendar Entry Inspect Card
              if (_selectedCalendarTrace != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.tokens.surfaceSecondary,
                    borderRadius: BorderRadius.circular(context.tokens.cardRadius),
                    border: Border.all(color: context.tokens.accent.withValues(alpha: 0.45)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                _selectedCalendarTrace!.dateKey,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: context.tokens.accent,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.tokens.surface,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _selectedCalendarTrace!.overallMood.toUpperCase(),
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: textPrimary),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Intensity: ${_selectedCalendarTrace!.moodIntensity}/10',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: textSecondary),
                          ),
                        ],
                      ),
                      if (_selectedCalendarTrace!.journalText != null &&
                          _selectedCalendarTrace!.journalText!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '"${_selectedCalendarTrace!.journalText!}"',
                          style: LabTheme.editorialSerif(fontSize: 11.5, fontStyle: FontStyle.italic, color: textPrimary),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Delete action
                          TextButton(
                            onPressed: () => _confirmDeleteTrace(context, _selectedCalendarTrace!, strings),
                            style: TextButton.styleFrom(
                              foregroundColor: LabColors.cherryRedGlow,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(strings.deleteEntryBtn, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 12),
                          // Open full trace detail
                          ElevatedButton(
                            onPressed: () {
                              TraceEntryDetailSheet.show(
                                context,
                                trace: _selectedCalendarTrace!,
                                onEdit: () => context.push(AppRouter.mindTrace),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.tokens.accent,
                              foregroundColor: isDark ? context.tokens.background : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(strings.reopenTraceAction, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Timeline List of Recorded Traces in this Month
        Text(
          strings.isArabic
              ? 'سجل تدوينات هذا الشهر'
              : (strings.isFrench
                  ? 'TRACES ENREGISTRÉES CE MOIS-CI'
                  : 'RECORDED TRACES THIS MONTH'),
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 10),

        if (monthTraces.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: Text(
                strings.isArabic
                    ? 'لم يتم تسجيل أي آثار في هذا الشهر.'
                    : 'No traces recorded in this calendar month.',
                style: TextStyle(fontSize: 11.5, color: textSecondary),
              ),
            ),
          )
        else
          ...monthTraces.map((trace) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.tokens.accentSoft,
                      border: Border.all(color: context.tokens.accent.withValues(alpha: 0.35), width: 0.8),
                    ),
                    child: Center(
                      child: Text(
                        '${trace.date.day}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: context.tokens.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              trace.overallMood.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${trace.moodIntensity} / 10',
                              style: TextStyle(fontSize: 10.5, color: textSecondary),
                            ),
                          ],
                        ),
                        if (trace.selectedEmotions.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            trace.selectedEmotions.join(' · '),
                            style: TextStyle(fontSize: 10.5, color: textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 12),
                    color: textSecondary,
                    onPressed: () {
                      TraceEntryDetailSheet.show(
                        context,
                        trace: trace,
                        onEdit: () => context.push(AppRouter.mindTrace),
                      );
                    },
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: 24),
      ],
    );
  }

  void _confirmDeleteTrace(BuildContext context, MindTraceModel trace, AppStrings strings) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(strings.deleteTraceConfirmTitle),
        content: Text(strings.deleteTraceConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await ref.read(mindTraceControllerProvider.notifier).deleteCheckIn(trace.id);
              setState(() => _selectedCalendarTrace = null);
            },
            style: TextButton.styleFrom(foregroundColor: LabColors.cherryRedGlow),
            child: Text(strings.deleteEntryBtn),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: REFLECTION ARCHIVE
  // ===========================================================================
  Widget _buildReflectionArchiveTab({
    required ProgressAnalyticsModel analytics,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required AppStrings strings,
  }) {
    final query = ref.watch(reflectionSearchQueryProvider).toLowerCase().trim();
    final sourceFilter = ref.watch(selectedReflectionSourceFilterProvider);

    final filteredReflections = analytics.allReflections.where((item) {
      if (sourceFilter != null && item.sourceType != sourceFilter) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesText = item.text.toLowerCase().contains(query);
        final matchesTitle = item.sourceTitle.toLowerCase().contains(query);
        return matchesText || matchesTitle;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Search & Source Filters Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
          ),
          child: Column(
            children: [
              // Search field
              TextField(
                controller: _reflectionSearchController,
                onChanged: (val) => ref.read(reflectionSearchQueryProvider.notifier).setQuery(val),
                style: TextStyle(fontSize: 12, color: textPrimary),
                decoration: InputDecoration(
                  hintText: strings.searchReflectionsHint,
                  hintStyle: TextStyle(fontSize: 11.5, color: textSecondary.withValues(alpha: 0.6)),
                  prefixIcon: Icon(Icons.search, size: 16, color: context.tokens.accent),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 14),
                          onPressed: () {
                            _reflectionSearchController.clear();
                            ref.read(reflectionSearchQueryProvider.notifier).setQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: context.tokens.surfaceSecondary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSourceFilterChip(
                      label: strings.filterAllSources,
                      isSelected: sourceFilter == null,
                      onTap: () => ref.read(selectedReflectionSourceFilterProvider.notifier).setFilter(null),
                      isDark: isDark,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(width: 8),
                    ...ReflectionSourceType.values.map((type) {
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: _buildSourceFilterChip(
                          label: type.label(strings),
                          icon: type.icon,
                          isSelected: sourceFilter == type,
                          onTap: () => ref.read(selectedReflectionSourceFilterProvider.notifier).setFilter(type),
                          isDark: isDark,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Reflections List View
        Expanded(
          child: filteredReflections.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      analytics.allReflections.isEmpty ? strings.noReflectionsEmpty : strings.noReflectionsFound,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredReflections.length,
                  itemBuilder: (context, index) {
                    final item = filteredReflections[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(item.sourceType.icon, size: 14, color: context.tokens.accent),
                                  const SizedBox(width: 6),
                                  Text(
                                    item.sourceTitle,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                      color: context.tokens.accent,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                item.formattedDate,
                                style: TextStyle(fontSize: 9.5, color: textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '"${item.text}"',
                            style: LabTheme.editorialSerif(
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                              color: textPrimary,
                              height: 1.4,
                            ),
                          ),
                          if (item.originalTrace != null) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: InkWell(
                                onTap: () {
                                  TraceEntryDetailSheet.show(
                                    context,
                                    trace: item.originalTrace!,
                                    onEdit: () => context.push(AppRouter.mindTrace),
                                  );
                                },
                                child: Text(
                                  strings.viewFullTraceBtn.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: context.tokens.accent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSourceFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return BouncingWidget(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? context.tokens.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? context.tokens.accent : borderColor,
            width: isSelected ? 1.0 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: isSelected ? context.tokens.accent : textSecondary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? context.tokens.accent : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 3: MILESTONES & JOURNEY
  // ===========================================================================
  Widget _buildMilestonesAndJourneyTab({
    required ProgressAnalyticsModel analytics,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required AppStrings strings,
  }) {
    final journeyRatio = analytics.totalJourneyActivities > 0
        ? (analytics.journeyActivitiesExplored / analytics.totalJourneyActivities).clamp(0.0, 1.0)
        : 0.0;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // 1. Journey Curriculum Exploration Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.journeyProgressTitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: textSecondary,
                    ),
                  ),
                  Text(
                    strings.activitiesExplored(
                      analytics.journeyActivitiesExplored,
                      analytics.totalJourneyActivities,
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.tokens.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: journeyRatio,
                  minHeight: 6,
                  backgroundColor: context.tokens.surfaceSecondary,
                  valueColor: AlwaysStoppedAnimation<Color>(context.tokens.accent),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                strings.isArabic
                    ? 'أنشطة استكشافية تتناول الأفكار التلقائية والتنظيم الانفعالي وبناء خطة المرونة بوتيرتك الخاصة.'
                    : (strings.isFrench
                        ? 'Activités explorant pensées automatiques, régulation émotionnelle et résilience à votre rythme.'
                        : 'Activities exploring automatic loops, emotional regulation, and resilience planning at your natural pace.'),
                style: TextStyle(fontSize: 11.5, color: textSecondary, height: 1.35),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Celestial Milestones Header
        Text(
          strings.milestonesTitle,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strings.milestonesSub,
          style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
        ),
        const SizedBox(height: 14),

        // Milestones List
        ...analytics.milestones.map((m) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: m.isUnlocked
                  ? context.tokens.accentSoft
                  : context.tokens.surfaceSecondary,
              borderRadius: BorderRadius.circular(context.tokens.cardRadius),
              border: Border.all(
                color: m.isUnlocked ? context.tokens.accent.withValues(alpha: 0.45) : borderColor,
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: m.isUnlocked
                        ? context.tokens.accentSoft
                        : context.tokens.surface,
                    border: Border.all(
                      color: m.isUnlocked ? context.tokens.accent : borderColor,
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    m.isUnlocked ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 16,
                    color: m.isUnlocked ? context.tokens.accent : textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            m.title,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: m.isUnlocked ? textPrimary : textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.tokens.surface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              m.symbolName,
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        m.description,
                        style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  m.isUnlocked ? 'Unlocked' : '${m.currentValue}/${m.targetValue}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: m.isUnlocked ? context.tokens.accent : textSecondary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 24),
      ],
    );
  }

  String _getMonthName(int month, AppStrings strings) {
    if (strings.isArabic) {
      const names = [
        'جانفي', 'فيفري', 'مارس', 'أفريل', 'ماي', 'جوان',
        'جويلية', 'أوت', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];
      return names[(month - 1).clamp(0, 11)];
    } else if (strings.isFrench) {
      const names = [
        'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
      ];
      return names[(month - 1).clamp(0, 11)];
    } else {
      const names = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return names[(month - 1).clamp(0, 11)];
    }
  }
}
