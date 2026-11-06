import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../domain/pattern_divergence_model.dart';
import '../domain/personal_baseline_model.dart';

/// Pure computation service for detecting meaningful multi-day divergences
/// from the user's personal baseline.
///
/// Strictly abides by Part 7.2 & Clinical Guardrails:
/// - Never labels as mania, hypomania, or depression.
/// - Never predicts relapse.
/// - Clearly cites evidence and communicates uncertainty.
class PatternAwarenessService {
  static List<PatternDivergence> detectDivergences({
    required List<MindTraceModel> traces,
    required PersonalBaseline baseline,
  }) {
    if (!baseline.hasSufficientData || traces.length < 2) {
      return [];
    }

    final now = DateTime.now();
    final past3DaysCutoff = now.subtract(const Duration(days: 4));
    final recentTraces = traces.where((t) => t.date.isAfter(past3DaysCutoff)).toList();

    if (recentTraces.length < 2) {
      return [];
    }

    recentTraces.sort((a, b) => a.date.compareTo(b.date));
    final List<PatternDivergence> divergences = [];

    // 1. Check for Elevated Activation Pattern
    // (Reduced sleep + elevated energy or racing thoughts over recent entries)
    final recentSleeps = recentTraces
        .map((t) => t.sleepHours)
        .whereType<double>()
        .where((h) => h > 0)
        .toList();
    final recentAvgSleep = recentSleeps.isNotEmpty
        ? recentSleeps.reduce((a, b) => a + b) / recentSleeps.length
        : baseline.averageSleepHours;

    final recentAvgEnergy = recentTraces.map((t) => t.energyLevel).reduce((a, b) => a + b) /
        recentTraces.length;
    final hasRacingThoughts = recentTraces.any((t) => (t.racingThoughts ?? 0) >= 6);

    final sleepDeficit = baseline.averageSleepHours - recentAvgSleep;
    final energySurge = recentAvgEnergy - baseline.averageEnergyLevel;

    if (sleepDeficit >= 1.5 && (energySurge >= 1.5 || hasRacingThoughts)) {
      final List<String> observations = [];
      observations.add(
        'Recorded sleep averaged ${recentAvgSleep.toStringAsFixed(1)} hours (baseline: ${baseline.averageSleepHours.toStringAsFixed(1)} hours).',
      );
      observations.add(
        'Reported energy averaged ${recentAvgEnergy.toStringAsFixed(1)}/10 (baseline: ${baseline.averageEnergyLevel.toStringAsFixed(1)}/10).',
      );
      if (hasRacingThoughts) {
        observations.add('Elevated racing thoughts were noted on recent check-ins.');
      }

      divergences.add(
        PatternDivergence(
          id: 'div_activation_${now.millisecondsSinceEpoch}',
          category: DivergenceCategory.elevatedActivation,
          title: 'Shift in Energy & Sleep Pattern',
          timeWindow: 'Past 3–4 days',
          contributingObservations: observations,
          baselineComparison:
              'Sleep is lower by ${sleepDeficit.toStringAsFixed(1)}h while reported energy is higher by ${energySurge.toStringAsFixed(1)} points compared to your usual baseline.',
          uncertaintyStatement:
              'This observation reflects numbers and sensations you logged. It is an exploration of pattern shifts, not a clinical diagnosis or confirmed episode.',
          userCheckInQuestion:
              'Do you recognize this increase in energy and reduced rest in your routine over the last few days?',
          supportPlanPrompt:
              'Consider reviewing your personal early-warning signs, evening wind-down routine, or calming activities.',
          therapistPrompt:
              'If you feel ungrounded or this pattern continues, reviewing these logs with your doctor or therapist could be helpful.',
          detectedAt: now,
        ),
      );
    }

    // 2. Check for Low Activation & Withdrawal Pattern
    final recentAvgIntensity = recentTraces.map((t) => t.moodIntensity).reduce((a, b) => a + b) /
        recentTraces.length;
    final hasHeavyOrLowMood = recentTraces.any((t) => t.overallMood == 'heavy' || t.overallMood == 'frustrated');
    final energyDrop = baseline.averageEnergyLevel - recentAvgEnergy;

    if (energyDrop >= 2.0 && (recentAvgIntensity <= 3.5 || hasHeavyOrLowMood)) {
      final List<String> observations = [
        'Reported energy averaged ${recentAvgEnergy.toStringAsFixed(1)}/10 (baseline: ${baseline.averageEnergyLevel.toStringAsFixed(1)}/10).',
        'Recorded mood state reflected lower energy or heavier sensations across recent entries.',
      ];

      divergences.add(
        PatternDivergence(
          id: 'div_low_${now.millisecondsSinceEpoch}',
          category: DivergenceCategory.lowActivation,
          title: 'Sustained Drop in Energy & Mood',
          timeWindow: 'Past 3–4 days',
          contributingObservations: observations,
          baselineComparison:
              'Energy is lower by ${energyDrop.toStringAsFixed(1)} points compared to your 30-day baseline.',
          uncertaintyStatement:
              'Fluctuations in vitality and mood are a natural part of living. This observation highlights a dip from your typical level.',
          userCheckInQuestion:
              'Have you been feeling drained, carrying extra weight, or feeling less motivated lately?',
          supportPlanPrompt:
              'Gentle pacing, prioritizing basic rest, and small manageable steps can help without putting pressure on yourself.',
          therapistPrompt:
              'If this feeling persists, bringing this observation to your therapist can provide support tailored to your needs.',
          detectedAt: now,
        ),
      );
    }

    // 3. Check for Elevated Tension / Stress Pattern
    final highTensionDays = recentTraces.where((t) => (t.physicalTension ?? 0) >= 7).length;
    final highAnxietyDays = recentTraces.where((t) => (t.anxietyLevel ?? 0) >= 7).length;

    if (highTensionDays >= 2 || highAnxietyDays >= 2) {
      divergences.add(
        PatternDivergence(
          id: 'div_tension_${now.millisecondsSinceEpoch}',
          category: DivergenceCategory.elevatedTension,
          title: 'Elevated Physical Tension & Stress',
          timeWindow: 'Past 3–4 days',
          contributingObservations: [
            'Physical tension or stress levels were rated 7/10 or higher on multiple recent days.',
            'Somatic markers indicate your nervous system may be carrying accumulated strain.',
          ],
          baselineComparison:
              'Tension and stress ratings are higher than your typical resting baseline.',
          uncertaintyStatement:
              'Stress responses often reflect external demands or physical fatigue.',
          userCheckInQuestion:
              'Are you noticing tightness in your body, shallow breathing, or heightened stress?',
          supportPlanPrompt:
              'A few minutes of vagal breathing, progressive muscle relaxation, or a quiet walk can help signal safety to your body.',
          therapistPrompt: null,
          detectedAt: now,
        ),
      );
    }

    return divergences;
  }
}

/// Therapist-ready weekly clinical summary answering Part 7.3.
class WeeklySummaryReport {
  const WeeklySummaryReport({
    required this.weekRange,
    required this.totalEntriesThisWeek,
    required this.whatChangedSummary,
    required this.topSymptoms,
    required this.sleepTrend,
    required this.recurringTriggers,
    required this.divergencePoints,
    required this.suggestedTherapyTopics,
  });

  final String weekRange;
  final int totalEntriesThisWeek;
  final String whatChangedSummary;
  final List<String> topSymptoms;
  final String sleepTrend;
  final List<String> recurringTriggers;
  final List<String> divergencePoints;
  final List<String> suggestedTherapyTopics;

  factory WeeklySummaryReport.generate({
    required List<MindTraceModel> traces,
    required PersonalBaseline baseline,
  }) {
    final now = DateTime.now();
    final weekCutoff = now.subtract(const Duration(days: 7));
    final weekTraces = traces.where((t) => t.date.isAfter(weekCutoff)).toList();

    if (weekTraces.isEmpty) {
      return const WeeklySummaryReport(
        weekRange: 'Past 7 days',
        totalEntriesThisWeek: 0,
        whatChangedSummary: 'No entries recorded in the past 7 days to evaluate trends.',
        topSymptoms: [],
        sleepTrend: 'Insufficient data',
        recurringTriggers: [],
        divergencePoints: [],
        suggestedTherapyTopics: ['Establish a daily observation routine with 1-minute check-ins.'],
      );
    }

    final sleepList = weekTraces.map((t) => t.sleepHours).whereType<double>().toList();
    final avgSleepThisWeek = sleepList.isNotEmpty
        ? sleepList.reduce((a, b) => a + b) / sleepList.length
        : baseline.averageSleepHours;

    final avgMoodThisWeek =
        weekTraces.map((t) => t.moodIntensity).reduce((a, b) => a + b) / weekTraces.length;

    // What changed
    final moodDiff = avgMoodThisWeek - baseline.averageMoodIntensity;
    final sleepDiff = avgSleepThisWeek - baseline.averageSleepHours;

    String whatChanged = 'This week, mood intensity averaged ${avgMoodThisWeek.toStringAsFixed(1)}/10 ';
    if (moodDiff.abs() >= 1.0) {
      whatChanged += moodDiff > 0
          ? '(+${moodDiff.toStringAsFixed(1)} higher than typical baseline). '
          : '(${moodDiff.toStringAsFixed(1)} lower than typical baseline). ';
    } else {
      whatChanged += '(consistent with your baseline). ';
    }

    String sleepTrendStr = 'Average sleep was ${avgSleepThisWeek.toStringAsFixed(1)}h/night ';
    if (sleepDiff.abs() >= 1.0) {
      sleepTrendStr += sleepDiff > 0
          ? '(up by ${sleepDiff.toStringAsFixed(1)}h from typical baseline).'
          : '(down by ${sleepDiff.abs().toStringAsFixed(1)}h from typical baseline).';
    } else {
      sleepTrendStr += '(stable with baseline).';
    }

    // Top symptoms
    final symCounts = <String, int>{};
    for (final t in weekTraces) {
      final s = t.symptomsAndExperiences;
      if (s != null && s.isNotEmpty) {
        for (final p in s.split(RegExp(r'[,;\n]')).map((x) => x.trim()).where((x) => x.isNotEmpty)) {
          symCounts[p] = (symCounts[p] ?? 0) + 1;
        }
      }
    }
    final topSymptoms = (symCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .take(4)
        .map((e) => '${e.key} (${e.value}x)')
        .toList();

    // Topics to discuss with therapist
    final topics = <String>[];
    if (sleepDiff.abs() >= 1.5) {
      topics.add('Review recent sleep shifts (${avgSleepThisWeek.toStringAsFixed(1)}h/night vs ${baseline.averageSleepHours.toStringAsFixed(1)}h baseline).');
    }
    if (topSymptoms.isNotEmpty) {
      topics.add('Discuss recurring experiences logged: ${topSymptoms.take(2).join(', ')}.');
    }
    if (baseline.recurringTriggers.isNotEmpty) {
      topics.add('Explore coping strategies for common triggers: ${baseline.recurringTriggers.take(2).join(', ')}.');
    }
    if (topics.isEmpty) {
      topics.add('General check-in on routine consistency and emotional balance.');
    }

    return WeeklySummaryReport(
      weekRange: 'Past 7 days (${weekTraces.length} check-ins)',
      totalEntriesThisWeek: weekTraces.length,
      whatChangedSummary: whatChanged,
      topSymptoms: topSymptoms,
      sleepTrend: sleepTrendStr,
      recurringTriggers: baseline.recurringTriggers,
      divergencePoints: [],
      suggestedTherapyTopics: topics,
    );
  }
}

// Providers
final personalBaselineProvider = Provider<PersonalBaseline>((ref) {
  final traces = ref.watch(mindTraceControllerProvider).value ?? [];
  return PersonalBaseline.fromTraces(traces);
});

final patternDivergencesProvider = Provider<List<PatternDivergence>>((ref) {
  final traces = ref.watch(mindTraceControllerProvider).value ?? [];
  final baseline = ref.watch(personalBaselineProvider);
  return PatternAwarenessService.detectDivergences(traces: traces, baseline: baseline);
});

final weeklySummaryProvider = Provider<WeeklySummaryReport>((ref) {
  final traces = ref.watch(mindTraceControllerProvider).value ?? [];
  final baseline = ref.watch(personalBaselineProvider);
  return WeeklySummaryReport.generate(traces: traces, baseline: baseline);
});
