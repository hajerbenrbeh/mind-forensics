import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_colors.dart';
import '../../../insights/data/pattern_awareness_service.dart';
import '../../controllers/observatory_controllers.dart';
import '../../domain/symptom_entry.dart';
import '../../domain/symptom_report.dart';

class LongitudinalAnalysisView extends ConsumerStatefulWidget {
  const LongitudinalAnalysisView({super.key});

  @override
  ConsumerState<LongitudinalAnalysisView> createState() =>
      _LongitudinalAnalysisViewState();
}

class _LongitudinalAnalysisViewState
    extends ConsumerState<LongitudinalAnalysisView> {
  int _selectedWindowDays = 14; // 7, 14, 30

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);
    final isAr = strings.isArabic;

    final surfaceColor = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final borderColor = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary = isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary = isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    final baseline = ref.watch(personalBaselineProvider);
    final divergences = ref.watch(patternDivergencesProvider);
    final reportsAsync = ref.watch(symptomReportsControllerProvider);
    final allSymptoms = ref.watch(symptomListControllerProvider).value ?? [];

    return reportsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(strokeWidth: 2, color: LabColors.sageGreen),
        ),
      ),
      error: (e, st) => Center(
        child: Text(
          isAr
              ? 'تعذر تحميل بيانات التحليل'
              : (strings.isFrench
                  ? 'Impossible de charger les données d’analyse'
                  : 'Unable to load analysis telemetry'),
          style: TextStyle(color: textSecondary),
        ),
      ),
      data: (reports) {
        final cutoff = DateTime.now().subtract(Duration(days: _selectedWindowDays));
        final recentReports =
            reports.where((r) => r.createdAt.isAfter(cutoff)).toList();

        // Calculate frequency map
        final Map<String, int> frequencies = {};
        for (final r in recentReports) {
          for (final id in r.symptomIds) {
            frequencies[id] = (frequencies[id] ?? 0) + 1;
          }
        }

        final sortedFrequencies = frequencies.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Window Switcher (7d | 14d | 30d)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr
                        ? 'التحليل الطولي للأعراض'
                        : (strings.isFrench
                            ? 'ANALYSE LONGITUDINALE'
                            : 'LONGITUDINAL SYMPTOM ANALYSIS'),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: textSecondary,
                    ),
                  ),
                  Row(
                    children: [7, 14, 30].map((days) {
                      final isSelected = _selectedWindowDays == days;
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () => setState(() => _selectedWindowDays = days),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? LabColors.sageGreen.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected ? LabColors.sageGreen : borderColor,
                              ),
                            ),
                            child: Text(
                              '${days}d',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                color: isSelected ? textPrimary : textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 1. Personal Baseline Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune_outlined, size: 16, color: LabColors.sageGreen),
                        const SizedBox(width: 8),
                        Text(
                          isAr
                              ? 'المرجع الشخصي الأساسي'
                              : (strings.isFrench
                                  ? 'RÉFÉRENCE PERSONNELLE'
                                  : 'PERSONAL BASELINE TELEMETRY'),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: LabColors.sageGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            baseline.statusLabel,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: LabColors.sageGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildMetricCol(
                          label: isAr
                              ? 'أيام الرصد'
                              : (strings.isFrench ? 'Jours observés' : 'Days Observed'),
                          value: '${baseline.totalRecordedDays}d',
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        _buildMetricCol(
                          label: isAr
                              ? 'المزاج المرجعي'
                              : (strings.isFrench ? 'Humeur de base' : 'Baseline Mood'),
                          value: baseline.averageMoodIntensity != null
                              ? '${baseline.averageMoodIntensity!.toStringAsFixed(1)}/10'
                              : '—',
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        _buildMetricCol(
                          label: isAr
                              ? 'متوسط النوم'
                              : (strings.isFrench ? 'Sommeil moyen' : 'Avg Sleep'),
                          value: baseline.averageSleepHours != null
                              ? '${baseline.averageSleepHours!.toStringAsFixed(1)}h'
                              : '—',
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. Pattern Awareness Divergence Banner
              if (divergences.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: LabColors.assumptionAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: LabColors.assumptionAmber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.radar_outlined, size: 16, color: LabColors.assumptionAmber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              divergences.first.title,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        divergences.first.baselineComparison,
                        style: TextStyle(fontSize: 11.5, color: textSecondary, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 3. Frequency Distribution
              Text(
                isAr
                    ? 'الأعراض الأكثر تكراراً في النافذة المحددة:'
                    : (strings.isFrench
                        ? 'Ressentis les plus fréquents sur la période :'
                        : 'Most frequent experiences in window:'),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textSecondary),
              ),
              const SizedBox(height: 10),
              if (sortedFrequencies.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: Text(
                      isAr
                          ? 'لا توجد تقارير أعراض مسجلة في نافذة $_selectedWindowDays يوماً الماضية.'
                          : (strings.isFrench
                              ? 'Aucun rapport enregistré sur les $_selectedWindowDays derniers jours.'
                              : 'No symptom reports logged in the past ${_selectedWindowDays}d window.'),
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ),
                )
              else
                ...sortedFrequencies.take(6).map((entry) {
                  final symptom = allSymptoms.firstWhere(
                    (s) => s.id == entry.key,
                    orElse: () => SymptomEntry(
                      id: entry.key,
                      titleEn: entry.key,
                      titleFr: entry.key,
                      titleAr: entry.key,
                      descriptionEn: '',
                      descriptionFr: '',
                      descriptionAr: '',
                      domain: SymptomDomain.mood,
                    ),
                  );
                  final count = entry.value;
                  final percentage = count / recentReports.length;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                symptom.title(strings),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                isAr
                                    ? '$count مرات'
                                    : (strings.isFrench ? '$count fois' : '$count times'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: LabColors.sageGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: percentage.clamp(0.05, 1.0),
                              backgroundColor: borderColor,
                              valueColor: const AlwaysStoppedAnimation(LabColors.sageGreen),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 16),

              // 4. Chronological Reports History
              Text(
                isAr
                    ? 'سجل تقارير الأعراض:'
                    : (strings.isFrench
                        ? 'Historique des bilans :'
                        : 'Symptom Assessment History:'),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textSecondary),
              ),
              const SizedBox(height: 10),
              if (reports.isEmpty)
                Text(
                  isAr
                      ? 'لم تسجل أي تقارير بعد.'
                      : (strings.isFrench
                          ? 'Aucun bilan enregistré pour le moment.'
                          : 'No symptom reports logged yet.'),
                  style: TextStyle(fontSize: 12, color: textSecondary),
                )
              else
                ...reports.take(5).map((r) => _buildReportTile(r, allSymptoms, strings, isDark, surfaceColor, borderColor, textPrimary, textSecondary)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCol({
    required String label,
    required String value,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary)),
        ],
      ),
    );
  }

  Widget _buildReportTile(
    SymptomReport report,
    List<dynamic> allSymptoms,
    AppStrings strings,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                report.dateKey,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: textSecondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: LabColors.sageGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${report.intensity}/10',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: LabColors.sageGreen),
                ),
              ),
            ],
          ),
          if (report.aiAnalysis != null) ...[
            const SizedBox(height: 6),
            Text(
              report.aiAnalysis!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: textPrimary, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}
