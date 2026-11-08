import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../mind_trace/domain/mind_trace_model.dart';

/// Represents an individual's self-reported personal baseline.
///
/// Strictly abides by Part 7.1 & Clinical Guardrails:
/// - Never assumes one person's normal is another person's normal.
/// - Computed entirely from the user's own historical observations over 14-30 days.
/// - Calculates each metric independently with explicit observation counts.
/// - Never manufactures or fabricates missing values when unrecorded.
/// - Employs both mean and robust statistics (median) to protect against outlier skews.
/// - Computes variability (standard deviation) to reflect natural routine stability.
@immutable
class PersonalBaseline {
  const PersonalBaseline({
    required this.totalRecordedDays,
    required this.hasSufficientData,
    this.averageSleepHours,
    this.medianSleepHours,
    this.sleepVariability,
    this.sleepObservationCount = 0,
    this.averageEnergyLevel,
    this.medianEnergyLevel,
    this.energyVariability,
    this.energyObservationCount = 0,
    this.averageMoodIntensity,
    this.medianMoodIntensity,
    this.moodVariability,
    this.moodObservationCount = 0,
    this.averageAnxietyLevel,
    this.medianAnxietyLevel,
    this.anxietyObservationCount = 0,
    this.averageTensionLevel,
    this.medianTensionLevel,
    this.tensionObservationCount = 0,
    this.commonEmotions = const [],
    this.recurringSymptoms = const [],
    this.recurringTriggers = const [],
    this.windowStartDate,
    this.windowEndDate,
  });

  /// Total distinct calendar days logged in the observation window.
  final int totalRecordedDays;

  /// True if at least 3 distinct observation days exist to form an initial observation sample.
  /// (Minimal statistical requirement for non-empty medians and preliminary comparison).
  final bool hasSufficientData;

  /// True if at least 14 distinct days are observed over the 30-day window,
  /// representing a longitudinal established personal baseline.
  bool get hasEstablishedBaseline => totalRecordedDays >= 14;

  /// True if at least 3 distinct observation days exist for preliminary comparison.
  bool get hasInitialObservations => totalRecordedDays >= 3;

  /// Clear, non-clinical status label distinguishing observation history depth:
  /// - Calibrating (< 3 days): Insufficient observation history
  /// - Preliminary observations (3-13 days): Initial observation sample
  /// - Established personal baseline (>= 14 days): Sufficient longitudinal history
  String get statusLabel {
    if (totalRecordedDays < 3) {
      return 'Calibrating ($totalRecordedDays/3d)';
    } else if (totalRecordedDays < 14) {
      return 'Preliminary Observations (${totalRecordedDays}d)';
    } else {
      return 'Established Baseline (${totalRecordedDays}d)';
    }
  }

  /// Evaluates whether a metric exhibits low observed numerical variability (consistency) across entries.
  /// Note: This describes numerical consistency in self-reports (SD <= 0.5), NOT psychological ground truth.
  static bool hasLowObservedVariability(double? variability) {
    return variability != null && variability <= 0.5;
  }

  // 1. Sleep Metrics (Calculated independently)
  final double? averageSleepHours;
  final double? medianSleepHours;
  final double? sleepVariability;
  final int sleepObservationCount;
  bool get hasSleepData => sleepObservationCount >= 3;

  // 2. Energy Metrics (Calculated independently)
  final double? averageEnergyLevel;
  final double? medianEnergyLevel;
  final double? energyVariability;
  final int energyObservationCount;
  bool get hasEnergyData => energyObservationCount >= 3;

  // 3. Mood Intensity Metrics (Calculated independently)
  final double? averageMoodIntensity;
  final double? medianMoodIntensity;
  final double? moodVariability;
  final int moodObservationCount;
  bool get hasMoodData => moodObservationCount >= 3;

  // 4. Anxiety & Stress Metrics (Calculated independently, optional)
  final double? averageAnxietyLevel;
  final double? medianAnxietyLevel;
  final int anxietyObservationCount;
  bool get hasAnxietyData => anxietyObservationCount >= 3;

  // 5. Somatic Tension Metrics (Calculated independently, optional)
  final double? averageTensionLevel;
  final double? medianTensionLevel;
  final int tensionObservationCount;
  bool get hasTensionData => tensionObservationCount >= 3;

  // Qualitative Recurring Categorical Patterns
  final List<String> commonEmotions;
  final List<String> recurringSymptoms;
  final List<String> recurringTriggers;

  final DateTime? windowStartDate;
  final DateTime? windowEndDate;

  static const PersonalBaseline empty = PersonalBaseline(
    totalRecordedDays: 0,
    hasSufficientData: false,
    averageSleepHours: null,
    medianSleepHours: null,
    sleepVariability: null,
    sleepObservationCount: 0,
    averageEnergyLevel: null,
    medianEnergyLevel: null,
    energyVariability: null,
    energyObservationCount: 0,
    averageMoodIntensity: null,
    medianMoodIntensity: null,
    moodVariability: null,
    moodObservationCount: 0,
    averageAnxietyLevel: null,
    medianAnxietyLevel: null,
    anxietyObservationCount: 0,
    averageTensionLevel: null,
    medianTensionLevel: null,
    tensionObservationCount: 0,
    commonEmotions: [],
    recurringSymptoms: [],
    recurringTriggers: [],
    windowStartDate: null,
    windowEndDate: null,
  );

  /// Computes a rolling baseline from historical traces (defaulting to past 30 days).
  factory PersonalBaseline.fromTraces(List<MindTraceModel> traces, {int baselineDays = 30}) {
    if (traces.isEmpty) return PersonalBaseline.empty;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    // Exact calendar-day window: includes today and exactly (baselineDays - 1) preceding days.
    // For baselineDays = 30, this spans from (today - 29 days) 00:00:00 up to tomorrow 00:00:00 exclusive
    // = strictly and exactly 30 calendar dates.
    final earliestIncludedDate = todayStart.subtract(Duration(days: baselineDays - 1));
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final windowTraces = traces.where((t) => !t.date.isBefore(earliestIncludedDate) && t.date.isBefore(tomorrowStart)).toList();

    if (windowTraces.isEmpty) return PersonalBaseline.empty;

    // Deduplicate to latest entry per calendar day so multiple check-ins
    // on a single day do not inflate distinct-day counts or skew means/medians.
    final Map<String, MindTraceModel> dailyMap = {};
    for (final t in windowTraces) {
      final key = t.dateKey;
      if (!dailyMap.containsKey(key) || t.updatedAt.isAfter(dailyMap[key]!.updatedAt)) {
        dailyMap[key] = t;
      }
    }
    final dailyTraces = dailyMap.values.toList();
    final uniqueDays = dailyMap.keys.length;
    final hasEnough = uniqueDays >= 3; // Technical pattern-detection heuristic (min 3 distinct days)

    // 1. Independent Sleep Calculation (strictly includes 0.0h sleeplessness)
    final sleepValues = dailyTraces
        .map((t) => t.sleepHours)
        .whereType<double>()
        .where((h) => h >= 0.0 && h <= 24.0)
        .toList();
    final avgSleep = _calculateMean(sleepValues);
    final medSleep = _calculateMedian(sleepValues);
    final varSleep = _calculateStandardDeviation(sleepValues);

    // 2. Independent Energy Calculation (valid scale: 1–10; null represents unrecorded)
    final energyValues = dailyTraces
        .map((t) => t.energyLevel)
        .whereType<int>()
        .where((e) => e >= 1 && e <= 10)
        .toList();
    final avgEnergy = _calculateMean(energyValues);
    final medEnergy = _calculateMedian(energyValues);
    final varEnergy = _calculateStandardDeviation(energyValues);

    // 3. Independent Mood Intensity Calculation (valid scale: 1–10)
    final moodValues = dailyTraces
        .map((t) => t.moodIntensity)
        .where((m) => m >= 1 && m <= 10)
        .toList();
    final avgMood = _calculateMean(moodValues);
    final medMood = _calculateMedian(moodValues);
    final varMood = _calculateStandardDeviation(moodValues);

    // 4. Independent Anxiety Level Calculation (strictly includes 0 anxiety / calm)
    final anxietyValues = dailyTraces
        .map((t) => t.anxietyLevel)
        .whereType<int>()
        .where((a) => a >= 0 && a <= 10)
        .toList();
    final avgAnxiety = _calculateMean(anxietyValues);
    final medAnxiety = _calculateMedian(anxietyValues);

    // 5. Independent Tension Level Calculation (strictly includes 0 tension / relaxed)
    final tensionValues = dailyTraces
        .map((t) => t.physicalTension)
        .whereType<int>()
        .where((t) => t >= 0 && t <= 10)
        .toList();
    final avgTension = _calculateMean(tensionValues);
    final medTension = _calculateMedian(tensionValues);

    // Emotion frequencies
    final emotionCounts = <String, int>{};
    for (final t in dailyTraces) {
      for (final e in t.selectedEmotions) {
        if (e.trim().isNotEmpty) {
          emotionCounts[e.trim()] = (emotionCounts[e.trim()] ?? 0) + 1;
        }
      }
    }
    final sortedEmotions = emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final commonEmotions = sortedEmotions.take(5).map((e) => e.key).toList();

    // Symptoms frequencies
    final symptomCounts = <String, int>{};
    for (final t in dailyTraces) {
      final s = t.symptomsAndExperiences;
      if (s != null && s.trim().isNotEmpty) {
        final parts = s.split(RegExp(r'[,;\n]')).map((p) => p.trim()).where((p) => p.isNotEmpty);
        for (final part in parts) {
          symptomCounts[part] = (symptomCounts[part] ?? 0) + 1;
        }
      }
    }
    final sortedSymptoms = symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final recurringSymptoms = sortedSymptoms.take(5).map((e) => e.key).toList();

    // Trigger frequencies from situation descriptions
    final triggerCounts = <String, int>{};
    for (final t in dailyTraces) {
      final sit = t.situation;
      if (sit != null && sit.trim().isNotEmpty) {
        triggerCounts[sit.trim()] = (triggerCounts[sit.trim()] ?? 0) + 1;
      }
    }
    final sortedTriggers = triggerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final recurringTriggers = sortedTriggers.take(4).map((e) => e.key).toList();

    return PersonalBaseline(
      totalRecordedDays: uniqueDays,
      hasSufficientData: hasEnough,
      averageSleepHours: avgSleep,
      medianSleepHours: medSleep,
      sleepVariability: varSleep,
      sleepObservationCount: sleepValues.length,
      averageEnergyLevel: avgEnergy,
      medianEnergyLevel: medEnergy,
      energyVariability: varEnergy,
      energyObservationCount: energyValues.length,
      averageMoodIntensity: avgMood,
      medianMoodIntensity: medMood,
      moodVariability: varMood,
      moodObservationCount: moodValues.length,
      averageAnxietyLevel: avgAnxiety,
      medianAnxietyLevel: medAnxiety,
      anxietyObservationCount: anxietyValues.length,
      averageTensionLevel: avgTension,
      medianTensionLevel: medTension,
      tensionObservationCount: tensionValues.length,
      commonEmotions: commonEmotions,
      recurringSymptoms: recurringSymptoms,
      recurringTriggers: recurringTriggers,
      windowStartDate: dailyTraces.isEmpty
          ? earliestIncludedDate
          : dailyTraces.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b),
      windowEndDate: dailyTraces.isEmpty
          ? todayStart
          : dailyTraces.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b),
    );
  }

  static double? _calculateMean<T extends num>(List<T> values) {
    if (values.isEmpty) return null;
    double sum = 0.0;
    for (final v in values) {
      sum += v.toDouble();
    }
    return double.parse((sum / values.length).toStringAsFixed(1));
  }

  static double? _calculateMedian<T extends num>(List<T> values) {
    if (values.isEmpty) return null;
    final sorted = List<T>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return double.parse(sorted[mid].toDouble().toStringAsFixed(1));
    }
    final avgMid = (sorted[mid - 1].toDouble() + sorted[mid].toDouble()) / 2.0;
    return double.parse(avgMid.toStringAsFixed(1));
  }

  static double? _calculateStandardDeviation<T extends num>(List<T> values) {
    if (values.length < 2) return null;
    double sum = 0.0;
    for (final v in values) {
      sum += v.toDouble();
    }
    final mean = sum / values.length;
    double sumSqDiff = 0.0;
    for (final v in values) {
      final diff = v.toDouble() - mean;
      sumSqDiff += diff * diff;
    }
    final variance = sumSqDiff / values.length;
    return double.parse(math.sqrt(variance).toStringAsFixed(1));
  }
}
