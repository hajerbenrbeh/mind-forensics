import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/mind_badge.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
import '../../../core/widgets/mind_pill.dart';
import '../../../core/widgets/smooth_spline_chart.dart';
import '../../case_file/presentation/clinical_export_preview_sheet.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../investigation/domain/case_model.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../progress/data/progress_analytics_service.dart';
import '../../progress/domain/progress_analytics_model.dart';
import '../data/pattern_awareness_service.dart';
import '../domain/pattern_divergence_model.dart';
import '../domain/personal_baseline_model.dart';

/// Insights destination: Turns self-observation into personal understanding.
/// Matches Phone 4 in the master reference with mood trends spline, pattern cards,
/// botanical encouragement, and clinical baseline analytics.
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  String _selectedRange = '1M';

  List<MindTraceModel> _filterTracesByRange(List<MindTraceModel> traces) {
    final now = DateTime.now();
    final Duration window;
    switch (_selectedRange) {
      case '1W':
        window = const Duration(days: 7);
        break;
      case '3M':
        window = const Duration(days: 90);
        break;
      case '6M':
        window = const Duration(days: 180);
        break;
      case '1M':
      default:
        window = const Duration(days: 30);
        break;
    }
    final cutoff = now.subtract(window);
    return traces.where((t) => !t.date.isBefore(cutoff)).toList();
  }

  void _showRangeOverviewSheet(
    BuildContext context,
    List<MindTraceModel> filteredTraces,
    MindTokens tokens,
    AppStrings strings,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: tokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.calendarTitle,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                  MindBadge(label: _selectedRange),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                strings.isArabic
                    ? '${filteredTraces.length} ملاحظات في هذه الفترة المحددة.'
                    : (strings.isFrench
                        ? '${filteredTraces.length} observations sur la période sélectionnée.'
                        : '${filteredTraces.length} observations recorded in this $_selectedRange window.'),
                style: TextStyle(fontSize: 13, color: tokens.textSecondary),
              ),
              const SizedBox(height: 16),
              MindButton(
                text: strings.progressTabCalendar,
                isFullWidth: true,
                leadingIcon: Icons.calendar_month_outlined,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.push('/progress');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final baseline = ref.watch(personalBaselineProvider);
    final divergences = ref.watch(patternDivergencesProvider);
    final weeklySummary = ref.watch(weeklySummaryProvider);
    final cases = ref.watch(savedCasesProvider).value ?? [];
    final allTraces = ref.watch(mindTraceControllerProvider).value ?? [];
    final traces = _filterTracesByRange(allTraces);
    final analytics = ref.watch(progressAnalyticsProvider);

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        backgroundColor: tokens.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          strings.navInsights,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today_outlined, size: 20, color: tokens.textPrimary),
            tooltip: strings.calendarTitle,
            onPressed: () {
              HapticFeedback.lightImpact();
              _showRangeOverviewSheet(context, traces, tokens, strings);
            },
          ),
          IconButton(
            icon: Icon(Icons.share_outlined, size: 20, color: tokens.textPrimary),
            tooltip: strings.exportSummaryButton,
            onPressed: () {
              HapticFeedback.lightImpact();
              ClinicalExportPreviewSheet.show(context, cases);
            },
          ),
          const SupportButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Time Horizon Filter (Wired to trace filtering)
            Row(
              children: ['1W', '1M', '3M', '6M'].map((r) {
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: MindPill(
                    label: r,
                    isSelected: _selectedRange == r,
                    onTap: () => setState(() => _selectedRange = r),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 18),

          // 2. Mood Trends Section
          Text(
            strings.moodTrendsHeader,
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          _buildMoodTrendsCard(context, tokens, traces, strings),
          const SizedBox(height: 20),

          // 3. Your Patterns Section
          _buildYourPatternsSection(context, tokens, analytics, strings),
          const SizedBox(height: 18),

          // 4. Context & Mood Links (Trigger + Helper local heuristics)
          _buildContextMoodLinksCard(context, traces, tokens, strings),
          const SizedBox(height: 20),

          // 5. Personal Baseline Card (Preserved Core)
          _buildBaselineCard(context, baseline, tokens, strings),
          const SizedBox(height: 20),

          // 6. Pattern Awareness Divergences (if any detected)
          if (divergences.isNotEmpty) ...[
            Text(
              strings.patternAwarenessTitle.toUpperCase(),
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            ...divergences.map((d) => _buildDivergenceCard(context, d, tokens, strings)),
            const SizedBox(height: 20),
          ],

          // 7. Weekly Therapist Summary Card (Preserved Core)
          _buildWeeklyTherapistSummaryCard(context, weeklySummary, cases, tokens, strings),
          const SizedBox(height: 20),

          // 8. Detailed Analytics Deep-Dive Button (Preserved Core)
          MindCard(
            padding: const EdgeInsets.all(16),
            onTap: () => context.go('/progress'),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tokens.accentSoft,
                    borderRadius: BorderRadius.circular(tokens.chipRadius),
                  ),
                  child: Icon(Icons.analytics_outlined, size: 20, color: tokens.accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Full Progress & Longitudinal Trends',
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Detailed emotion breakdown, somatic radar & milestone archive',
                        style: TextStyle(color: tokens.textSecondary, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: tokens.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    ),
  );
}

  Widget _buildMoodTrendsCard(
    BuildContext context,
    MindTokens tokens,
    List<MindTraceModel> traces,
    AppStrings strings,
  ) {
    if (traces.length < 2) {
      return MindCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tokens.surfaceSecondary,
              ),
              child: Icon(Icons.show_chart_rounded, size: 20, color: tokens.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.isArabic
                        ? 'منحنى المزاج قيد المعايرة'
                        : (strings.isFrench
                            ? 'Courbe d’humeur en calibration'
                            : 'Mood curve calibrating'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    strings.isArabic
                        ? 'سجل يومين على الأقل من الملاحظات لرسم منحنى المزاج الخاص بك.'
                        : (strings.isFrench
                            ? 'Au moins 2 jours d’observations sont requis pour tracer votre courbe personnelle.'
                            : 'At least 2 days of observations needed to render your personal mood curve.'),
                    style: TextStyle(fontSize: 11.5, color: tokens.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final sortedTraces = [...traces]..sort((a, b) => a.date.compareTo(b.date));
    final recentTraces = sortedTraces.length > 14
        ? sortedTraces.sublist(sortedTraces.length - 14)
        : sortedTraces;
    final chartValues = recentTraces
        .map((t) => (t.moodIntensity / 10.0).clamp(0.05, 0.95))
        .toList();
    final lastTrace = recentTraces.last;
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final activeLabel =
        '${monthNames[lastTrace.date.month - 1]} ${lastTrace.date.day}\n${lastTrace.overallMood.toUpperCase()}';

    return MindCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.sentiment_satisfied_outlined,
                size: 19,
                color: tokens.textSecondary,
              ),
              const SizedBox(height: 22),
              Icon(
                Icons.sentiment_neutral_outlined,
                size: 19,
                color: tokens.textSecondary,
              ),
              const SizedBox(height: 22),
              Icon(
                Icons.sentiment_dissatisfied_outlined,
                size: 19,
                color: tokens.textSecondary,
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SmoothSplineChart(
              values: chartValues,
              height: 120,
              activePointIndex: chartValues.length - 1,
              activePointLabel: activeLabel,
              lineColor: tokens.accent,
              showDots: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYourPatternsSection(
    BuildContext context,
    MindTokens tokens,
    ProgressAnalyticsModel analytics,
    AppStrings strings,
  ) {
    final insights = analytics.insights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                strings.yourPatternsHeader,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push('/progress'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text(
                    '${strings.viewAllArrowLabel} →',
                    style: TextStyle(
                      color: tokens.accent,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (insights.isEmpty)
          MindCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_outlined, size: 20, color: tokens.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    strings.isArabic
                        ? 'الأنماط قيد المعايرة: مع استمرارك في تسجيل الملاحظات اليومية، ستظهر هنا روابط دقيقة بين النوم والمزاج.'
                        : 'Patterns calibrating: As you log observations over time, correlations between sleep, mood, and stress will appear here.',
                    style: TextStyle(fontSize: 12, color: tokens.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          )
        else
          ...insights.take(3).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MindCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                onTap: () => context.push('/progress'),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tokens.accentSoft,
                      ),
                      child: Icon(
                        item.icon,
                        size: 19,
                        color: tokens.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: tokens.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.description,
                            style: TextStyle(
                              color: tokens.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: tokens.textTertiary,
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildContextMoodLinksCard(
    BuildContext context,
    List<MindTraceModel> traces,
    MindTokens tokens,
    AppStrings strings,
  ) {
    final triggerStats = <String, List<int>>{};
    final helpedStats = <String, int>{};

    for (final t in traces) {
      if (t.situation != null && t.situation!.isNotEmpty) {
        for (final raw in t.situation!.split(',')) {
          final tag = raw.trim();
          if (tag.isEmpty) continue;
          triggerStats.putIfAbsent(tag, () => []).add(t.moodIntensity);
        }
      }
      if (t.behavioralResponse != null && t.behavioralResponse!.isNotEmpty) {
        for (final raw in t.behavioralResponse!.split(',')) {
          final tag = raw.trim();
          if (tag.isEmpty) continue;
          helpedStats[tag] = (helpedStats[tag] ?? 0) + 1;
        }
      }
    }

    final topTriggers = triggerStats.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final topHelpers = helpedStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return MindCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hub_outlined, size: 17, color: tokens.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.triggerMoodCorrelationsTitle,
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              MindBadge(label: _selectedRange),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            strings.triggerMoodCorrelationsSub,
            style: TextStyle(fontSize: 11.5, color: tokens.textSecondary, height: 1.35),
          ),
          if (topTriggers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topTriggers.take(4).map((e) {
                final avg = (e.value.reduce((a, b) => a + b) / e.value.length).toStringAsFixed(1);
                return MindBadge(
                  label: '${e.key} • $avg/10 (${e.value.length}x)',
                  backgroundColor: tokens.surfaceSecondary,
                );
              }).toList(),
            ),
          ],
          if (topHelpers.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topHelpers.take(3).map((e) {
                return MindBadge(
                  icon: Icons.spa_outlined,
                  label: '${e.key} (${e.value}x)',
                  backgroundColor: tokens.accentSoft,
                  textColor: tokens.accent,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBaselineCard(
    BuildContext context,
    PersonalBaseline baseline,
    MindTokens tokens,
    AppStrings strings,
  ) {
    return MindCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.straighten_outlined, size: 16, color: tokens.accent),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        strings.personalBaselineTitle.toUpperCase(),
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: MindBadge(
                  label: baseline.statusLabel,
                  backgroundColor: baseline.hasEstablishedBaseline
                      ? tokens.accentSoft
                      : tokens.surfaceSecondary,
                  textColor: baseline.hasEstablishedBaseline
                      ? tokens.accent
                      : (baseline.hasSufficientData ? tokens.textPrimary : tokens.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!baseline.hasSufficientData) ...[
            Text(
              strings.baselineNeedsMoreData,
              style: TextStyle(color: tokens.textSecondary, fontSize: 12.5),
            ),
          ] else ...[
            Text(
              'Your rolling normal over the past 30 days of self-observation:',
              style: TextStyle(color: tokens.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildStatColumn(
                  strings.typicalSleepLabel,
                  baseline.averageSleepHours != null ? '${baseline.averageSleepHours}h' : '—',
                  tokens,
                ),
                _buildStatColumn(
                  strings.typicalEnergyLabel,
                  baseline.averageEnergyLevel != null ? '${baseline.averageEnergyLevel}/10' : '—',
                  tokens,
                ),
                _buildStatColumn(
                  strings.moodIntensityShortLabel,
                  baseline.averageMoodIntensity != null ? '${baseline.averageMoodIntensity}/10' : '—',
                  tokens,
                ),
              ],
            ),
            if (baseline.commonEmotions.isNotEmpty) ...[
              const Divider(height: 24, thickness: 0.5),
              Text(
                '${strings.frequentEmotionsLabel}: ${baseline.commonEmotions.join(', ')}',
                style: TextStyle(color: tokens.textTertiary, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, MindTokens tokens) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: tokens.textTertiary, fontSize: 9.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivergenceCard(
    BuildContext context,
    PatternDivergence d,
    MindTokens tokens,
    AppStrings strings,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MindCard(
        borderColor: tokens.accent,
        backgroundColor: tokens.accentSoft.withValues(alpha: 0.35),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_outlined, size: 16, color: tokens.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    d.title,
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                MindBadge(label: d.timeWindow),
              ],
            ),
            const SizedBox(height: 10),
            ...d.contributingObservations.map((obs) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: tokens.accent, fontSize: 13)),
                      Expanded(
                        child: Text(
                          obs,
                          style: TextStyle(color: tokens.textPrimary, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(tokens.chipRadius),
                border: Border.all(color: tokens.border, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.userCheckInQuestion,
                    style: TextStyle(color: tokens.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    d.supportPlanPrompt,
                    style: TextStyle(color: tokens.textSecondary, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              d.uncertaintyStatement,
              style: TextStyle(
                color: tokens.textTertiary,
                fontSize: 10.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTherapistSummaryCard(
    BuildContext context,
    WeeklySummaryReport report,
    List<CaseModel> cases,
    MindTokens tokens,
    AppStrings strings,
  ) {
    return MindCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.weeklySummaryTitle.toUpperCase(),
                  style: TextStyle(
                    color: tokens.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              MindBadge(label: report.weekRange),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.whatChangedSummary,
            style: TextStyle(color: tokens.textPrimary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            report.sleepTrend,
            style: TextStyle(color: tokens.textSecondary, fontSize: 12.5),
          ),
          if (report.topSymptoms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Recorded Symptoms: ${report.topSymptoms.join(', ')}',
              style: TextStyle(color: tokens.textTertiary, fontSize: 11.5),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            strings.suggestedTherapyLabel,
            style: TextStyle(
              color: tokens.accent,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          ...report.suggestedTherapyTopics.map((topic) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('— ', style: TextStyle(color: tokens.accent, fontSize: 12)),
                    Expanded(
                      child: Text(
                        topic,
                        style: TextStyle(color: tokens.textPrimary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          MindButton(
            text: strings.exportSummaryButton,
            variant: MindButtonVariant.secondary,
            isFullWidth: true,
            leadingIcon: Icons.description_outlined,
            onPressed: () {
              HapticFeedback.lightImpact();
              ClinicalExportPreviewSheet.show(context, cases);
            },
          ),
        ],
      ),
    );
  }
}
