import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/lab_colors.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/botanical_emblem.dart';
import '../../../core/widgets/mind_badge.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
import '../../../core/widgets/mind_pill.dart';
import '../../../core/widgets/smooth_spline_chart.dart';
import '../../case_file/presentation/clinical_export_preview_sheet.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../investigation/domain/case_model.dart';
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

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);
    final baseline = ref.watch(personalBaselineProvider);
    final divergences = ref.watch(patternDivergencesProvider);
    final weeklySummary = ref.watch(weeklySummaryProvider);
    final cases = ref.watch(savedCasesProvider).value ?? [];

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        backgroundColor: tokens.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Insights',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? LabColors.darkTextPrimary : LabColors.primaryText,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today_outlined, size: 20, color: tokens.textPrimary),
            tooltip: 'Calendar',
            onPressed: () {},
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
            // 1. Time Horizon Filter (Phone 4)
            Row(
              children: ['1W', '1M', '3M', '6M'].map((r) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: MindPill(
                    label: r,
                    isSelected: _selectedRange == r,
                    onTap: () => setState(() => _selectedRange = r),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 18),

          // 2. Mood Trends Section (Phone 4)
          Text(
            'Mood Trends',
            style: TextStyle(
              color: isDark ? LabColors.darkTextPrimary : LabColors.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          _buildMoodTrendsCard(context, tokens, isDark),
          const SizedBox(height: 20),

          // 3. Your Patterns Section (Phone 4)
          _buildYourPatternsSection(context, tokens, isDark),
          const SizedBox(height: 16),

          // 4. Botanical Encouragement Banner (Phone 4)
          _buildEncouragementCard(context, tokens, isDark),
          const SizedBox(height: 24),

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

  Widget _buildMoodTrendsCard(BuildContext context, MindTokens tokens, bool isDark) {
    // 7 data points reflecting the smooth curve in Phone 4
    final chartValues = [0.45, 0.65, 0.50, 0.75, 0.60, 0.85, 0.70];

    return MindCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      backgroundColor: isDark ? LabColors.darkForestCard : LabColors.cardIvory,
      borderColor: isDark ? LabColors.darkForestBorder : LabColors.borderIvory,
      child: Row(
        children: [
          // Y-axis faces (Happy, Neutral, Sad)
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
          // Spline chart with callout tooltip matching Phone 4
          Expanded(
            child: SmoothSplineChart(
              values: chartValues,
              height: 120,
              activePointIndex: 5,
              activePointLabel: 'Nov 8\nCalm',
              lineColor: isDark ? LabColors.lightOlive : LabColors.forestGreen,
              showDots: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYourPatternsSection(BuildContext context, MindTokens tokens, bool isDark) {
    final patterns = [
      (
        icon: Icons.nightlight_outlined,
        title: 'Mood dips',
        subtitle: 'Often linked to poor sleep',
      ),
      (
        icon: Icons.menu_book_outlined,
        title: 'Higher anxiety',
        subtitle: 'During study periods',
      ),
      (
        icon: Icons.eco_outlined,
        title: 'More balance',
        subtitle: 'On days with self-care',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Patterns',
              style: TextStyle(
                color: isDark ? LabColors.darkTextPrimary : LabColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/progress'),
              child: Text(
                'View all →',
                style: TextStyle(
                  color: isDark ? LabColors.lightOlive : LabColors.secondaryOlive,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...patterns.map((p) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MindCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              backgroundColor: isDark ? LabColors.darkForestCard : LabColors.cardIvory,
              borderColor: isDark ? LabColors.darkForestBorder : LabColors.borderIvory,
              onTap: () => context.go('/progress'),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                    ),
                    child: Icon(
                      p.icon,
                      size: 19,
                      color: isDark ? LabColors.lightOlive : LabColors.forestGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          style: TextStyle(
                            color: isDark ? LabColors.darkTextPrimary : LabColors.primaryText,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.subtitle,
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

  Widget _buildEncouragementCard(BuildContext context, MindTokens tokens, bool isDark) {
    return MindCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      backgroundColor: isDark ? LabColors.darkForestCard : LabColors.cardIvory,
      borderColor: isDark ? LabColors.darkForestBorder : LabColors.borderIvory,
      child: Row(
        children: [
          BotanicalEmblem(
            size: 34,
            color: isDark ? LabColors.lightOlive : LabColors.forestGreen,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're doing well.",
                  style: TextStyle(
                    color: isDark ? LabColors.darkTextPrimary : LabColors.primaryText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Keep taking care of your mind.',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontStyle: FontStyle.italic,
                    color: tokens.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
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
              MindBadge(
                label: baseline.statusLabel,
                backgroundColor: baseline.hasEstablishedBaseline
                    ? tokens.accentSoft
                    : tokens.surfaceSecondary,
                textColor: baseline.hasEstablishedBaseline
                    ? tokens.accent
                    : (baseline.hasSufficientData ? tokens.textPrimary : tokens.textSecondary),
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
                  'TYPICAL SLEEP',
                  baseline.averageSleepHours != null ? '${baseline.averageSleepHours}h' : '—',
                  tokens,
                ),
                _buildStatColumn(
                  'TYPICAL ENERGY',
                  baseline.averageEnergyLevel != null ? '${baseline.averageEnergyLevel}/10' : '—',
                  tokens,
                ),
                _buildStatColumn(
                  'MOOD INTENSITY',
                  baseline.averageMoodIntensity != null ? '${baseline.averageMoodIntensity}/10' : '—',
                  tokens,
                ),
              ],
            ),
            if (baseline.commonEmotions.isNotEmpty) ...[
              const Divider(height: 24, thickness: 0.5),
              Text(
                'FREQUENT EMOTIONS: ${baseline.commonEmotions.join(', ')}',
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
            'SUGGESTED FOR THERAPY DISCUSSION:',
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
