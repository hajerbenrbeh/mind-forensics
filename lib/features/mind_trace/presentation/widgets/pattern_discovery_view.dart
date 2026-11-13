import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_colors.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../controllers/mind_trace_controller.dart';
import '../../domain/mind_trace_model.dart';
import '../../domain/trace_milestone.dart';

/// Weekly and monthly pattern discovery and positive milestone tracking.
///
/// Strictly abides by Section 5 & 6 directives:
/// - Strictly empirical: based only on user entries.
/// - Never claim definitive psychological causation. Frame as observations, not diagnoses.
/// - Clearly distinguish: user-reported info, calculated statistics, AI observations.
/// - Non-punitive, positive milestone achievements.
/// - 0 emojis.
class PatternDiscoveryView extends ConsumerStatefulWidget {
  const PatternDiscoveryView({
    super.key,
    required this.traces,
  });

  final List<MindTraceModel> traces;

  @override
  ConsumerState<PatternDiscoveryView> createState() =>
      _PatternDiscoveryViewState();
}

class _PatternDiscoveryViewState extends ConsumerState<PatternDiscoveryView> {
  int _selectedWindowDays = 7; // 7, 30, or 0 (all)

  List<MindTraceModel> _getFilteredTraces() {
    if (_selectedWindowDays == 0 || widget.traces.isEmpty) {
      return widget.traces;
    }
    final cutoff = DateTime.now().subtract(Duration(days: _selectedWindowDays));
    return widget.traces.where((t) => t.date.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);
    final unlockedMilestones = ref.watch(unlockedMilestonesProvider);

    final surfaceColor =
        isDark ? LabColors.surface1 : LabColors.daylightSurface;
    final borderColor =
        isDark ? LabColors.borderSubtle : LabColors.daylightBorder;
    final textPrimary =
        isDark ? LabColors.textPrimary : LabColors.daylightTextPrimary;
    final textSecondary =
        isDark ? LabColors.textSecondary : LabColors.daylightTextSecondary;

    final filtered = _getFilteredTraces();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // Time window filters
        Row(
          children: [
            _buildWindowPill(7, '7 DAYS', isDark, textPrimary, textSecondary, borderColor),
            const SizedBox(width: 8),
            _buildWindowPill(30, '30 DAYS', isDark, textPrimary, textSecondary, borderColor),
            const SizedBox(width: 8),
            _buildWindowPill(0, 'ALL TIME', isDark, textPrimary, textSecondary, borderColor),
          ],
        ),

        const SizedBox(height: 16),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              strings.isArabic
                  ? 'لا توجد بيانات مسجلة في هذه الفترة الزمنية. ابدأ بتسجيل أثرك اليوم.'
                  : (strings.isFrench
                      ? 'Aucune trace sur cette période. Enregistrez votre trace du jour.'
                      : 'No traces recorded for this timeframe yet. Log today\'s trace to begin discovering patterns.'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
            ),
          )
        else ...[
          // Summary Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'AVG INTENSITY',
                  value: _calculateAverage(filtered.map((t) => t.moodIntensity)),
                  suffix: '/10',
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'AVG ENERGY',
                  value: _calculateAverage(filtered.map((t) => t.energyLevel).whereType<int>()),
                  suffix: '/10',
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'AVG SLEEP',
                  value: _calculateAverageSleep(filtered),
                  suffix: 'h',
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Emotional Frequency Distribution
          _buildEmotionFrequencyCard(
            filtered,
            surfaceColor,
            borderColor,
            textPrimary,
            textSecondary,
            strings,
          ),

          const SizedBox(height: 18),

          // Recurring Context & Behavioral Responses
          _buildThoughtContextThemesCard(
            filtered,
            surfaceColor,
            borderColor,
            textPrimary,
            textSecondary,
            strings,
          ),

          const SizedBox(height: 18),

          // Empirical Sleep vs. Tension Observation
          _buildSleepTensionObservationCard(
            filtered,
            surfaceColor,
            borderColor,
            textPrimary,
            textSecondary,
            strings,
          ),
        ],

        const SizedBox(height: 24),

        // Personal Thought Trace Milestones
        Text(
          strings.isArabic ? 'محطات أثر الأفكار المكتشفة' : (strings.isFrench ? 'JALONS RÉFLEXIFS' : 'THOUGHT & REFLECTION MILESTONES'),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strings.isArabic
              ? 'محطات استبصار لطيفة بدون ضغط أو سلاسل سلبية.'
              : (strings.isFrench
                  ? 'Repères bienveillants, sans calcul de séries punitives.'
                  : 'Gentle milestones of awareness, with zero negative streaks or pressure.'),
          style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
        ),
        const SizedBox(height: 12),

        ...TraceMilestone.allMilestones.map((m) {
          final isUnlocked = unlockedMilestones.any((um) => um.id == m.id);
          return _buildMilestoneTile(
            milestone: m,
            isUnlocked: isUnlocked,
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          );
        }),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildWindowPill(
    int days,
    String label,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    final isSelected = _selectedWindowDays == days;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedWindowDays = days);
      },
      borderRadius: BorderRadius.circular(context.tokens.chipRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? context.tokens.accentSoft
              : Colors.transparent,
          borderRadius: BorderRadius.circular(context.tokens.chipRadius),
          border: Border.all(
            color: isSelected ? context.tokens.accent : borderColor,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.5,
            color: isSelected ? context.tokens.accent : textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String suffix,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                suffix,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionFrequencyCard(
    List<MindTraceModel> traces,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    AppStrings strings,
  ) {
    final counts = <String, int>{};
    for (final t in traces) {
      for (final e in t.selectedEmotions) {
        counts[e] = (counts[e] ?? 0) + 1;
      }
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.isArabic ? 'توزيع المشاعر المعاشة' : (strings.isFrench ? 'RÉPARTITION DES ÉMOTIONS' : 'REPORTED EMOTIONAL SPECTRUM'),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (sorted.isEmpty)
            Text(
              strings.isArabic
                  ? 'لم يتم تحديد مشاعر مفصلة في هذه الفترة.'
                  : 'No specific emotions tagged in this timeframe.',
              style: TextStyle(fontSize: 11.5, color: textSecondary),
            )
          else
            ...sorted.take(5).map((entry) {
              final ratio = entry.value / traces.length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 5,
                        backgroundColor: context.tokens.surfaceSecondary,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.tokens.accent,
                        ),
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

  Widget _buildThoughtContextThemesCard(
    List<MindTraceModel> traces,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    AppStrings strings,
  ) {
    // Extract user-reported situations and behavioral responses
    final reportedSituations = traces
        .map((t) => t.situation?.trim())
        .where((s) => s != null && s.isNotEmpty)
        .cast<String>()
        .toList();

    final reportedCoping = traces
        .map((t) => t.behavioralResponse?.trim())
        .where((b) => b != null && b.isNotEmpty)
        .cast<String>()
        .toList();

    final totalInvestigated = traces.where((t) => t.isInvestigated).length;

    return Container(
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
            children: [
              Icon(Icons.psychology_outlined,
                  size: 14, color: context.tokens.accent),
              const SizedBox(width: 6),
              Text(
                strings.isArabic
                    ? 'أنماط السياق والاستجابة'
                    : (strings.isFrench
                        ? 'THÈMES DE CONTEXTE & D’ADAPTATION'
                        : 'RECURRING CONTEXT & COPING THEMES'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: context.tokens.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            strings.isArabic
                ? 'استكشاف تجريبي للمواقف المسجلة واستجاباتك السلوكية ($totalInvestigated فكرة تم فحصها).'
                : (strings.isFrench
                    ? 'Revue empirique de vos situations et actions enregistrées ($totalInvestigated pensées explorées).'
                    : 'Empirical review of your recorded situations and coping actions ($totalInvestigated deconstructed thoughts).'),
            style: TextStyle(fontSize: 11.5, color: textSecondary, height: 1.35),
          ),
          const SizedBox(height: 12),

          if (reportedSituations.isEmpty && reportedCoping.isEmpty)
            Text(
              strings.isArabic
                  ? 'لم يتم تسجيل مواقف أو استجابات سلوكية كافية في هذا الإطار الزمني.'
                  : (strings.isFrench
                      ? 'Ajoutez des contextes ou explorez une pensée pour révéler vos schémas récurrents.'
                      : 'Add contextual triggers or deconstruct thoughts to uncover recurring behavioral patterns.'),
              style: TextStyle(fontSize: 11, color: textSecondary.withValues(alpha: 0.8)),
            )
          else ...[
            if (reportedSituations.isNotEmpty) ...[
              Text(
                strings.isArabic
                    ? 'عوامل السياق المسجلة'
                    : (strings.isFrench
                        ? 'CONTEXTES & DÉCLENCHEURS RAPPORTÉS'
                        : 'USER-REPORTED CONTEXT / TRIGGERS'),
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              ...reportedSituations.take(3).map((sit) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: LabColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Text(
                      '• $sit',
                      style: TextStyle(fontSize: 11.5, color: textPrimary),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],

            if (reportedCoping.isNotEmpty) ...[
              Text(
                strings.isArabic
                    ? 'الاستجابات السلوكية المسجلة'
                    : (strings.isFrench
                        ? 'RÉPONSES COMPORTEMENTALES RAPPORTÉES'
                        : 'REPORTED COPING & BEHAVIORAL RESPONSES'),
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              ...reportedCoping.take(3).map((act) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: LabColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Text(
                      '• $act',
                      style: TextStyle(fontSize: 11.5, color: textPrimary),
                    ),
                  ),
                );
              }),
            ],
          ],

          const SizedBox(height: 8),
          Text(
            strings.isArabic
                ? '* هذه الملاحظات وصفية ولا تقدم أحكاماً أو تشخيصات نفسية قطعية.'
                : '* These observations are descriptive based on your inputs and do not imply clinical causality.',
            style: TextStyle(fontSize: 10, color: textSecondary, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepTensionObservationCard(
    List<MindTraceModel> traces,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    AppStrings strings,
  ) {
    final validSleep = traces.where((t) => t.sleepHours != null && t.physicalTension != null).toList();

    String observation;
    if (validSleep.length < 2) {
      observation = strings.isArabic
          ? 'الملاحظات التجريبية بين النوم والتوتر ستظهر تلقائياً مع تسجيل المزيد من البيانات.'
          : 'Somatic & sleep correlations will formulate as you record more check-ins.';
    } else {
      final lowSleep = validSleep.where((t) => t.sleepHours! < 6.5).toList();
      final goodSleep = validSleep.where((t) => t.sleepHours! >= 6.5).toList();

      if (lowSleep.isNotEmpty && goodSleep.isNotEmpty) {
        final avgLowTension = (lowSleep.map((t) => t.physicalTension!).reduce((a, b) => a + b) / lowSleep.length).toStringAsFixed(1);
        final avgGoodTension = (goodSleep.map((t) => t.physicalTension!).reduce((a, b) => a + b) / goodSleep.length).toStringAsFixed(1);

        observation = strings.isArabic
            ? 'ملاحظة بيانات: في الأيام التي قل فيها النوم عن 6.5 ساعات، بلغ متوسط التوتر الجسدي $avgLowTension/10، مقارنة بـ $avgGoodTension/10 في أيام النوم الكافي.'
            : 'Data observation: On days with sleep under 6.5 hours, physical tension averaged $avgLowTension/10, compared to $avgGoodTension/10 on nights with sufficient rest.';
      } else {
        observation = strings.isArabic
            ? 'تتواصل الملاحظة: النوم والتوتر يسجلان مستويات متقاربة حالياً.'
            : 'Observations show consistent somatic and rest rhythms across this timeframe.';
      }
    }

    return Container(
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
            children: [
              Icon(Icons.insights_rounded, size: 14, color: LabColors.warmBeige),
              const SizedBox(width: 6),
              Text(
                strings.isArabic ? 'ملاحظة الترابط التجريبي' : (strings.isFrench ? 'OBSERVATION DE CORRÉLATION' : 'EMPIRICAL OBSERVATION'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: LabColors.warmBeige,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            observation,
            style: TextStyle(fontSize: 12, height: 1.4, color: textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            strings.isArabic
                ? '* تصف هذه الملاحظة ترابطات إحصائية في سجلاتك فقط، ولا تعني بالضرورة وجود علاقة سببية حتمية.'
                : '* This observation reflects self-reported data correlations only and does not imply definitive medical causality.',
            style: TextStyle(fontSize: 10, color: textSecondary, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneTile({
    required TraceMilestone milestone,
    required bool isUnlocked,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? context.tokens.accent
                : borderColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked
                    ? context.tokens.accentSoft
                    : context.tokens.surfaceSecondary,
                border: Border.all(
                  color: isUnlocked ? context.tokens.accent : borderColor,
                  width: 0.8,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                isUnlocked ? Icons.bookmark_added_rounded : Icons.bookmark_border_rounded,
                size: 16,
                color: isUnlocked ? context.tokens.accent : textSecondary,
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
                        milestone.title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: context.tokens.surfaceSecondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          milestone.symbolName,
                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    milestone.description,
                    style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateAverage(Iterable<int> values) {
    if (values.isEmpty) return '0.0';
    final sum = values.reduce((a, b) => a + b);
    return (sum / values.length).toStringAsFixed(1);
  }

  String _calculateAverageSleep(List<MindTraceModel> list) {
    final valid = list.where((t) => t.sleepHours != null).map((t) => t.sleepHours!);
    if (valid.isEmpty) return '--';
    final sum = valid.reduce((a, b) => a + b);
    return (sum / valid.length).toStringAsFixed(1);
  }
}
