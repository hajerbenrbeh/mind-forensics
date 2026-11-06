import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/features/insights/data/pattern_awareness_service.dart';
import 'package:mind_forensics/features/insights/domain/pattern_divergence_model.dart';
import 'package:mind_forensics/features/insights/domain/personal_baseline_model.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';

void main() {
  group('Personal Baseline Engine Tests', () {
    test('Empty traces returns empty baseline with hasSufficientData=false', () {
      final baseline = PersonalBaseline.fromTraces([]);
      expect(baseline.totalRecordedDays, equals(0));
      expect(baseline.hasSufficientData, isFalse);
      expect(baseline.commonEmotions, isEmpty);
      expect(baseline.recurringSymptoms, isEmpty);
    });

    test('Fewer than 3 distinct days marks hasSufficientData=false', () {
      final now = DateTime.now();
      final traces = [
        MindTraceModel(
          id: 't1',
          date: now,
          createdAt: now,
          updatedAt: now,
          sleepHours: 7.5,
          energyLevel: 6,
          moodIntensity: 5,
        ),
        MindTraceModel(
          id: 't2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 8.0,
          energyLevel: 5,
          moodIntensity: 4,
        ),
      ];

      final baseline = PersonalBaseline.fromTraces(traces);
      expect(baseline.totalRecordedDays, equals(2));
      expect(baseline.hasSufficientData, isFalse);
    });

    test('Computes rolling baseline correctly with 4 days of telemetry', () {
      final now = DateTime.now();
      final traces = [
        MindTraceModel(
          id: 't1',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 8.0,
          energyLevel: 5,
          moodIntensity: 6,
          selectedEmotions: const ['calm', 'focused'],
          symptomsAndExperiences: 'Headache, Fatigue',
          situation: 'Work project',
        ),
        MindTraceModel(
          id: 't2',
          date: now.subtract(const Duration(days: 2)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 7.0,
          energyLevel: 5,
          moodIntensity: 5,
          selectedEmotions: const ['calm'],
          symptomsAndExperiences: 'Fatigue',
          situation: 'Work project',
        ),
        MindTraceModel(
          id: 't3',
          date: now.subtract(const Duration(days: 3)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 7.5,
          energyLevel: 6,
          moodIntensity: 5,
          selectedEmotions: const ['grounded'],
          situation: 'Family gathering',
        ),
        MindTraceModel(
          id: 't4',
          date: now.subtract(const Duration(days: 4)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 7.5,
          energyLevel: 4,
          moodIntensity: 4,
          selectedEmotions: const ['calm'],
        ),
      ];

      final baseline = PersonalBaseline.fromTraces(traces);
      expect(baseline.totalRecordedDays, equals(4));
      expect(baseline.hasSufficientData, isTrue);
      expect(baseline.averageSleepHours, equals(7.5));
      expect(baseline.averageEnergyLevel, equals(5.0));
      expect(baseline.averageMoodIntensity, equals(5.0));
      expect(baseline.commonEmotions.first, equals('calm'));
      expect(baseline.recurringSymptoms.first, equals('Fatigue'));
      expect(baseline.recurringTriggers.first, equals('Work project'));
    });
  });

  group('Pattern Awareness & Divergence Detection Tests', () {
    test('Detects Elevated Activation when sleep drops >= 1.5h and energy surges', () {
      final now = DateTime.now();
      const baseline = PersonalBaseline(
        totalRecordedDays: 14,
        hasSufficientData: true,
        averageSleepHours: 8.0,
        averageEnergyLevel: 5.0,
        averageMoodIntensity: 5.0,
        commonEmotions: ['calm'],
        recurringSymptoms: [],
        recurringTriggers: [],
        windowStartDate: null,
        windowEndDate: null,
      );

      final recentTraces = [
        MindTraceModel(
          id: 'r1',
          date: now.subtract(const Duration(hours: 12)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 4.5,
          energyLevel: 8,
          moodIntensity: 7,
          racingThoughts: 8,
        ),
        MindTraceModel(
          id: 'r2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 5.0,
          energyLevel: 7,
          moodIntensity: 6,
          racingThoughts: 7,
        ),
      ];

      final divergences = PatternAwarenessService.detectDivergences(
        traces: recentTraces,
        baseline: baseline,
      );

      expect(divergences, isNotEmpty);
      final div = divergences.firstWhere((d) => d.category == DivergenceCategory.elevatedActivation);
      expect(div.title, contains('Energy & Sleep'));
      expect(div.contributingObservations, isNotEmpty);
      expect(div.uncertaintyStatement, contains('not a clinical diagnosis'));
      expect(div.userCheckInQuestion, contains('routine'));
      expect(div.supportPlanPrompt, isNotEmpty);
    });

    test('Detects Low Activation when energy drops significantly with heavy mood', () {
      final now = DateTime.now();
      const baseline = PersonalBaseline(
        totalRecordedDays: 14,
        hasSufficientData: true,
        averageSleepHours: 7.5,
        averageEnergyLevel: 6.0,
        averageMoodIntensity: 5.5,
        commonEmotions: ['calm'],
        recurringSymptoms: [],
        recurringTriggers: [],
        windowStartDate: null,
        windowEndDate: null,
      );

      final recentTraces = [
        MindTraceModel(
          id: 'r1',
          date: now.subtract(const Duration(hours: 10)),
          createdAt: now,
          updatedAt: now,
          overallMood: 'heavy',
          energyLevel: 2,
          moodIntensity: 3,
        ),
        MindTraceModel(
          id: 'r2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          overallMood: 'heavy',
          energyLevel: 3,
          moodIntensity: 2,
        ),
      ];

      final divergences = PatternAwarenessService.detectDivergences(
        traces: recentTraces,
        baseline: baseline,
      );

      expect(divergences, isNotEmpty);
      final div = divergences.firstWhere((d) => d.category == DivergenceCategory.lowActivation);
      expect(div.title, contains('Drop in Energy'));
      expect(div.uncertaintyStatement, isNotEmpty);
    });

    test('Detects Elevated Tension when somatic ratings >= 7 on multiple days', () {
      final now = DateTime.now();
      const baseline = PersonalBaseline(
        totalRecordedDays: 14,
        hasSufficientData: true,
        averageSleepHours: 7.5,
        averageEnergyLevel: 5.0,
        averageMoodIntensity: 5.0,
        commonEmotions: ['calm'],
        recurringSymptoms: [],
        recurringTriggers: [],
        windowStartDate: null,
        windowEndDate: null,
      );

      final recentTraces = [
        MindTraceModel(
          id: 'r1',
          date: now.subtract(const Duration(hours: 8)),
          createdAt: now,
          updatedAt: now,
          physicalTension: 8,
          anxietyLevel: 7,
          energyLevel: 5,
        ),
        MindTraceModel(
          id: 'r2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          physicalTension: 7,
          anxietyLevel: 8,
          energyLevel: 5,
        ),
      ];

      final divergences = PatternAwarenessService.detectDivergences(
        traces: recentTraces,
        baseline: baseline,
      );

      expect(divergences, isNotEmpty);
      final div = divergences.firstWhere((d) => d.category == DivergenceCategory.elevatedTension);
      expect(div.title, contains('Physical Tension'));
      expect(div.supportPlanPrompt, contains('breathing'));
    });
  });

  group('Weekly Therapist Summary Report Tests', () {
    test('Generates structured weekly summary with evidence and discussion topics', () {
      final now = DateTime.now();
      const baseline = PersonalBaseline(
        totalRecordedDays: 20,
        hasSufficientData: true,
        averageSleepHours: 7.5,
        averageEnergyLevel: 5.0,
        averageMoodIntensity: 5.0,
        commonEmotions: ['calm'],
        recurringSymptoms: ['Tension'],
        recurringTriggers: ['Deadlines'],
        windowStartDate: null,
        windowEndDate: null,
      );

      final weekTraces = [
        MindTraceModel(
          id: 'w1',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 5.5,
          moodIntensity: 4,
          symptomsAndExperiences: 'Tension, Headache',
        ),
        MindTraceModel(
          id: 'w2',
          date: now.subtract(const Duration(days: 3)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 6.0,
          moodIntensity: 5,
          symptomsAndExperiences: 'Tension',
        ),
      ];

      final report = WeeklySummaryReport.generate(traces: weekTraces, baseline: baseline);
      expect(report.totalEntriesThisWeek, equals(2));
      expect(report.whatChangedSummary, isNotEmpty);
      expect(report.sleepTrend, contains('down'));
      expect(report.topSymptoms, contains('Tension (2x)'));
      expect(report.suggestedTherapyTopics, isNotEmpty);
    });
  });
}

