import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/journey/domain/journey_activity.dart';
import 'package:mind_forensics/features/journey/domain/journey_phase.dart';
import 'package:mind_forensics/features/journey/domain/journey_state_model.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/progress/data/progress_analytics_service.dart';
import 'package:mind_forensics/features/progress/domain/progress_analytics_model.dart';
import 'package:mind_forensics/features/progress/presentation/progress_screen.dart';

void main() {
  group('ProgressTimeWindow Tests', () {
    test('verifies durations and labels in all 3 languages', () {
      const stringsEn = AppStrings('en');
      const stringsFr = AppStrings('fr');
      const stringsAr = AppStrings('ar');

      expect(ProgressTimeWindow.sevenDays.durationInDays, equals(7));
      expect(ProgressTimeWindow.thirtyDays.durationInDays, equals(30));
      expect(ProgressTimeWindow.ninetyDays.durationInDays, equals(90));
      expect(ProgressTimeWindow.allTime.durationInDays, isNull);

      expect(ProgressTimeWindow.sevenDays.label(stringsEn), equals('7 DAYS'));
      expect(ProgressTimeWindow.sevenDays.label(stringsFr), equals('7 JOURS'));
      expect(ProgressTimeWindow.sevenDays.label(stringsAr), equals('7 أيام'));

      final dateRangeEn = ProgressTimeWindow.sevenDays.formattedDateRange(DateTime(2026, 11, 6), stringsEn);
      expect(dateRangeEn, contains('2026'));

      final allTimeAr = ProgressTimeWindow.allTime.formattedDateRange(DateTime(2026, 11, 6), stringsAr);
      expect(allTimeAr, equals('كامل السجل التاريخي المسجل'));
    });
  });

  group('ProgressAnalyticsCalculator Pure Engine Tests', () {
    late DateTime now;
    late List<MindTraceModel> sampleTraces;
    late List<CaseModel> sampleCases;
    late JourneyStateModel sampleJourney;
    const strings = AppStrings('en');

    setUp(() {
      now = DateTime.now();

      sampleTraces = [
        MindTraceModel(
          id: 't1',
          date: now.subtract(const Duration(days: 1)),
          overallMood: 'calm',
          selectedEmotions: const ['Calm', 'Grateful'],
          moodIntensity: 4,
          energyLevel: 7,
          sleepHours: 8.0,
          sleepQuality: 4,
          physicalTension: 2,
          journalText: 'Felt grounded and present today.',
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
        MindTraceModel(
          id: 't2',
          date: now.subtract(const Duration(days: 2)),
          overallMood: 'anxious',
          selectedEmotions: const ['Anxious', 'Restless', 'Overwhelmed'],
          moodIntensity: 8,
          energyLevel: 4,
          sleepHours: 5.5,
          sleepQuality: 2,
          physicalTension: 8,
          journalText: 'Deadline pressure caused bodily tightness.',
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now.subtract(const Duration(days: 2)),
        ),
        MindTraceModel(
          id: 't3',
          date: now.subtract(const Duration(days: 2, hours: 2)), // Same day as t2
          overallMood: 'reflective',
          selectedEmotions: const ['Calm'],
          moodIntensity: 5,
          energyLevel: 6,
          sleepHours: 7.0,
          sleepQuality: 3,
          physicalTension: 3,
          journalText: 'Took an evening walk and calmed down.',
          createdAt: now.subtract(const Duration(days: 2, hours: 2)),
          updatedAt: now.subtract(const Duration(days: 2, hours: 2)),
        ),
        MindTraceModel(
          id: 't4',
          date: now.subtract(const Duration(days: 45)), // Outside 30 days
          overallMood: 'heavy',
          selectedEmotions: const ['Exhausted', 'Numb'],
          moodIntensity: 7,
          energyLevel: 3,
          sleepHours: 4.5,
          sleepQuality: 1,
          physicalTension: 7,
          journalText: 'A distant memory from last month.',
          createdAt: now.subtract(const Duration(days: 45)),
          updatedAt: now.subtract(const Duration(days: 45)),
        ),
      ];

      sampleCases = [
        CaseModel(
          id: 'case_1',
          caseNumber: 'CASE 01',
          title: 'Meeting confrontation',
          createdAt: now.subtract(const Duration(days: 3)),
          updatedAt: now.subtract(const Duration(days: 3)),
          currentStage: CaseStage.conclusion,
          incidentDescription: 'Colleague questioned my presentation.',
          userConclusion: 'Their question was curiosity, not hostility.',
          isCompleted: true,
        ),
      ];

      sampleJourney = JourneyStateModel(
        activities: [
          JourneyActivity(
            id: 'act_1',
            phase: JourneyPhase.phase1SelfDiscovery,
            title: 'Deconstructing Thought Loops',
            purpose: 'Identify automatic assumptions',
            shortExplanation: 'Recognize cognitive patterns',
            guidedInstructions: const ['Notice', 'Label'],
            reflectionQuestions: const ['What did you discover?'],
            isCompleted: true,
            completedAt: now.subtract(const Duration(days: 4)),
            personalNotes: 'Discovered my mind jumps to worst-case scenarios quickly.',
          ),
          const JourneyActivity(
            id: 'act_2',
            phase: JourneyPhase.phase1SelfDiscovery,
            title: 'Somatic Anchoring',
            purpose: 'Calm the body',
            shortExplanation: 'Breathing exercises',
            guidedInstructions: ['Breathe in', 'Breathe out'],
            reflectionQuestions: ['How does your body feel?'],
            isCompleted: false,
          ),
        ],
        updatedAt: now,
      );
    });

    test('handles empty data gracefully without division by zero', () {
      final analytics = ProgressAnalyticsCalculator.computeAnalytics(
        allTraces: const [],
        allCases: const [],
        journeyState: null,
        timeWindow: ProgressTimeWindow.thirtyDays,
        dismissedInsightIds: const {},
        strings: strings,
      );

      expect(analytics.isEmpty, isTrue);
      expect(analytics.totalEntries, equals(0));
      expect(analytics.uniqueDaysCount, equals(0));
      expect(analytics.totalEmotionSelections, equals(0));
      expect(analytics.averageIntensity, equals(0.0));
      expect(analytics.averageEnergy, isNull);
      expect(analytics.averageSleepDuration, isNull);
      expect(analytics.allReflections, isEmpty);
      expect(analytics.milestones.every((m) => !m.isUnlocked), isTrue);
    });

    test('filters traces correctly by time window', () {
      // 30 Days window: should include t1, t2, t3 (3 entries), excluding t4
      final analytics30d = ProgressAnalyticsCalculator.computeAnalytics(
        allTraces: sampleTraces,
        allCases: sampleCases,
        journeyState: sampleJourney,
        timeWindow: ProgressTimeWindow.thirtyDays,
        dismissedInsightIds: const {},
        strings: strings,
      );

      expect(analytics30d.totalEntries, equals(3));
      // t2 and t3 occurred on the same date key, so unique days = 2
      expect(analytics30d.uniqueDaysCount, equals(2));

      // All Time window: should include all 4 entries
      final analyticsAll = ProgressAnalyticsCalculator.computeAnalytics(
        allTraces: sampleTraces,
        allCases: sampleCases,
        journeyState: sampleJourney,
        timeWindow: ProgressTimeWindow.allTime,
        dismissedInsightIds: const {},
        strings: strings,
      );

      expect(analyticsAll.totalEntries, equals(4));
      expect(analyticsAll.uniqueDaysCount, equals(3));
    });

    test('calculates emotional frequencies, selections and variety accurately', () {
      final analytics = ProgressAnalyticsCalculator.computeAnalytics(
        allTraces: sampleTraces,
        allCases: sampleCases,
        journeyState: sampleJourney,
        timeWindow: ProgressTimeWindow.thirtyDays,
        dismissedInsightIds: const {},
        strings: strings,
      );

      // t1 has 2, t2 has 3, t3 has 1 -> totalSelections = 6
      expect(analytics.totalEmotionSelections, equals(6));

      // Distinct emotions: Calm (2), Grateful (1), Anxious (1), Restless (1), Overwhelmed (1) -> 5 distinct
      expect(analytics.emotionalVarietyCount, equals(5));
      expect(analytics.emotionFrequencies['Calm'], equals(2));
      expect(analytics.emotionFrequencies['Anxious'], equals(1));
    });

    test('computes mood intensity stats and chronological timeline', () {
      final analytics = ProgressAnalyticsCalculator.computeAnalytics(
        allTraces: sampleTraces,
        allCases: sampleCases,
        journeyState: sampleJourney,
        timeWindow: ProgressTimeWindow.thirtyDays,
        dismissedInsightIds: const {},
        strings: strings,
      );

      // Intensities in 30d: 4, 8, 5 -> avg = (4+8+5)/3 = 5.67
      expect(analytics.minIntensity, equals(4));
      expect(analytics.maxIntensity, equals(8));
      expect(analytics.averageIntensity, closeTo(5.66, 0.05));
      expect(analytics.intensityTimeline.length, equals(3));
    });

    test('computes somatic indicators and non-causal sleep vs tension observation', () {
      final analytics = ProgressAnalyticsCalculator.computeAnalytics(
        allTraces: sampleTraces,
        allCases: sampleCases,
        journeyState: sampleJourney,
        timeWindow: ProgressTimeWindow.thirtyDays,
        dismissedInsightIds: const {},
        strings: strings,
      );

      // Energy: 7, 4, 6 -> avg = 5.67
      expect(analytics.averageEnergy, closeTo(5.66, 0.05));

      // Sleep: 8.0, 5.5, 7.0 -> avg = 6.83
      expect(analytics.averageSleepDuration, closeTo(6.83, 0.05));

      // Sleep vs tension: t2 (<6.5h) tension=8; t1 and t3 (>=6.5h) tensions=2, 3 -> avg=2.5
      expect(analytics.sleepTensionObservation, isNotNull);
      expect(analytics.sleepTensionObservation, contains('8.0/10'));
      expect(analytics.sleepTensionObservation, contains('2.5/10'));
    });

    test('gathers and sorts reflections across Traces, Cases, and Journey', () {
      final analytics = ProgressAnalyticsCalculator.computeAnalytics(
        allTraces: sampleTraces,
        allCases: sampleCases,
        journeyState: sampleJourney,
        timeWindow: ProgressTimeWindow.thirtyDays,
        dismissedInsightIds: const {},
        strings: strings,
      );

      // All 4 traces have journal text + 1 case has userConclusion + 1 journey activity has personalNotes = 6
      expect(analytics.allReflections.length, equals(6));

      // Verify source types are present
      final sources = analytics.allReflections.map((r) => r.sourceType).toSet();
      expect(sources, contains(ReflectionSourceType.dailyTrace));
      expect(sources, contains(ReflectionSourceType.investigation));
      expect(sources, contains(ReflectionSourceType.journeyActivity));

      // Verify newest date first
      for (var i = 0; i < analytics.allReflections.length - 1; i++) {
        expect(
          analytics.allReflections[i].date.isAfter(analytics.allReflections[i + 1].date) ||
              analytics.allReflections[i].date.isAtSameMomentAs(analytics.allReflections[i + 1].date),
          isTrue,
        );
      }
    });

    test('evaluates milestone unlocks accurately based on cumulative exploration', () {
      final analytics = ProgressAnalyticsCalculator.computeAnalytics(
        allTraces: sampleTraces,
        allCases: sampleCases,
        journeyState: sampleJourney,
        timeWindow: ProgressTimeWindow.thirtyDays,
        dismissedInsightIds: const {},
        strings: strings,
      );

      final milestoneMap = {for (final m in analytics.milestones) m.id: m};

      // 4 total traces:
      expect(milestoneMap['ms_first_star']!.isUnlocked, isTrue);
      expect(milestoneMap['ms_triad_weaver']!.isUnlocked, isTrue);
      expect(milestoneMap['ms_seven_cluster']!.isUnlocked, isFalse);

      // Unique emotions across all 4 traces: Calm, Grateful, Anxious, Restless, Overwhelmed, Exhausted, Numb -> 7 unique
      expect(milestoneMap['ms_emotional_granularity']!.isUnlocked, isTrue);

      // 1 completed case:
      expect(milestoneMap['ms_forensic_inquirer']!.isUnlocked, isTrue);

      // 1 completed journey activity:
      expect(milestoneMap['ms_journey_pioneer']!.isUnlocked, isTrue);
    });

    test('dismissing an insight excludes it from the returned insights', () {
      final initialAnalytics = ProgressAnalyticsCalculator.computeAnalytics(
        allTraces: sampleTraces,
        allCases: sampleCases,
        journeyState: sampleJourney,
        timeWindow: ProgressTimeWindow.thirtyDays,
        dismissedInsightIds: const {},
        strings: strings,
      );

      expect(initialAnalytics.insights, isNotEmpty);
      final firstInsightId = initialAnalytics.insights.first.id;

      final updatedAnalytics = ProgressAnalyticsCalculator.computeAnalytics(
        allTraces: sampleTraces,
        allCases: sampleCases,
        journeyState: sampleJourney,
        timeWindow: ProgressTimeWindow.thirtyDays,
        dismissedInsightIds: {firstInsightId},
        strings: strings,
      );

      expect(updatedAnalytics.insights.any((ins) => ins.id == firstInsightId), isFalse);
    });
  });

  group('ProgressScreen Widget Integration Tests', () {
    testWidgets('renders ProgressScreen with 4 tabs and header quote', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProgressScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check title and framing quote
      expect(find.text('MY PROGRESS'), findsOneWidget);
      expect(find.textContaining('Every entry tells a story'), findsOneWidget);

      // Check all 4 tab labels
      expect(find.text('THOUGHT TRACE & OVERVIEW'), findsOneWidget);
      expect(find.text('CALENDAR & ENTRIES'), findsOneWidget);
      expect(find.text('REFLECTIONS ARCHIVE'), findsOneWidget);
      expect(find.text('MILESTONES & JOURNEY'), findsOneWidget);

      // Switch to Calendar tab
      await tester.tap(find.text('CALENDAR & ENTRIES'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
      expect(find.textContaining('Each highlighted point marks an observed day'), findsOneWidget);

      // Switch to Reflections Archive tab
      await tester.tap(find.text('REFLECTIONS ARCHIVE'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('All Sources'), findsOneWidget);

      // Switch to Milestones & Journey tab
      await tester.tap(find.text('MILESTONES & JOURNEY'));
      await tester.pumpAndSettle();
      expect(find.text('JOURNEY CURRICULUM EXPLORATION'), findsOneWidget);
      expect(find.text('CELESTIAL MILESTONES'), findsOneWidget);
    });
  });
}
