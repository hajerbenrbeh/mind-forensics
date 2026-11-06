import 'package:flutter/foundation.dart';
import '../../mind_trace/domain/mind_trace_model.dart';

/// Represents an individual's self-reported personal baseline.
///
/// Strictly abides by Part 7.1:
/// - Never assumes one person's normal is another person's normal.
/// - Computed entirely from the user's own historical observations over 14-30 days.
@immutable
class PersonalBaseline {
  const PersonalBaseline({
    required this.totalRecordedDays,
    required this.hasSufficientData,
    required this.averageSleepHours,
    required this.averageEnergyLevel,
    required this.averageMoodIntensity,
    required this.commonEmotions,
    required this.recurringSymptoms,
    required this.recurringTriggers,
    required this.windowStartDate,
    required this.windowEndDate,
  });

  final int totalRecordedDays;
  final bool hasSufficientData;
  final double averageSleepHours;
  final double averageEnergyLevel;
  final double averageMoodIntensity;
  final List<String> commonEmotions;
  final List<String> recurringSymptoms;
  final List<String> recurringTriggers;
  final DateTime? windowStartDate;
  final DateTime? windowEndDate;

  static const PersonalBaseline empty = PersonalBaseline(
    totalRecordedDays: 0,
    hasSufficientData: false,
    averageSleepHours: 7.0,
    averageEnergyLevel: 5.0,
    averageMoodIntensity: 5.0,
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
    final cutoff = now.subtract(Duration(days: baselineDays));
    final windowTraces = traces.where((t) => t.date.isAfter(cutoff)).toList();

    if (windowTraces.isEmpty) return PersonalBaseline.empty;

    final uniqueDays = windowTraces.map((t) => t.dateKey).toSet().length;
    final hasEnough = uniqueDays >= 3; // Minimum 3 distinct observation days

    // Sleep calculation
    final sleepValues = windowTraces
        .map((t) => t.sleepHours)
        .whereType<double>()
        .where((h) => h > 0)
        .toList();
    final avgSleep = sleepValues.isNotEmpty
        ? sleepValues.reduce((a, b) => a + b) / sleepValues.length
        : 7.0;

    // Energy calculation
    final energyValues = windowTraces.map((t) => t.energyLevel).toList();
    final avgEnergy = energyValues.isNotEmpty
        ? energyValues.reduce((a, b) => a + b) / energyValues.length
        : 5.0;

    // Mood intensity
    final moodValues = windowTraces.map((t) => t.moodIntensity).toList();
    final avgMood = moodValues.isNotEmpty
        ? moodValues.reduce((a, b) => a + b) / moodValues.length
        : 5.0;

    // Emotion frequencies
    final emotionCounts = <String, int>{};
    for (final t in windowTraces) {
      for (final e in t.selectedEmotions) {
        emotionCounts[e] = (emotionCounts[e] ?? 0) + 1;
      }
    }
    final sortedEmotions = emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final commonEmotions = sortedEmotions.take(5).map((e) => e.key).toList();

    // Symptoms frequencies
    final symptomCounts = <String, int>{};
    for (final t in windowTraces) {
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
    for (final t in windowTraces) {
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
      averageSleepHours: double.parse(avgSleep.toStringAsFixed(1)),
      averageEnergyLevel: double.parse(avgEnergy.toStringAsFixed(1)),
      averageMoodIntensity: double.parse(avgMood.toStringAsFixed(1)),
      commonEmotions: commonEmotions,
      recurringSymptoms: recurringSymptoms,
      recurringTriggers: recurringTriggers,
      windowStartDate: cutoff,
      windowEndDate: now,
    );
  }
}

