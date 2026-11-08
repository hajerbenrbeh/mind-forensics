import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/features/insights/data/pattern_awareness_service.dart';
import 'package:mind_forensics/features/insights/domain/pattern_divergence_model.dart';
import 'package:mind_forensics/features/insights/domain/personal_baseline_model.dart';
import 'package:mind_forensics/features/investigation/data/mock_investigator_service.dart';
import 'package:mind_forensics/features/investigation/domain/ai_companion_context_selector.dart';
import 'package:mind_forensics/features/investigation/domain/ai_companion_system_prompt.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/conversation_mode.dart';
import 'package:mind_forensics/features/mind_trace/data/mind_trace_ai_service.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/profile/domain/condition_type.dart';
import 'package:mind_forensics/features/profile/domain/diagnostic_status.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';

void main() {
  group('Phase 3 Step 3.1: Context & Personal Baseline Intelligence Bridge', () {
    // -------------------------------------------------------------------------
    // Requirement 1: Strict Consent Enforcement (shareWithAiCompanion & allowAiPersonalization)
    // -------------------------------------------------------------------------
    test('1. Consent disabled strictly transmits zero context and zero telemetry', () {
      final profileNoShare = PsychologicalProfileModel(
        preferredName: 'Alice',
        shareWithAiCompanion: false,
        allowAiPersonalization: true,
        updatedAt: DateTime(2026, 1, 1),
      );

      final profileNoPersonalization = PsychologicalProfileModel(
        preferredName: 'Bob',
        shareWithAiCompanion: true,
        allowAiPersonalization: false,
        updatedAt: DateTime(2026, 1, 1),
      );

      final dummyTrace = MindTraceModel(
        id: 'trace-1',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        overallMood: 'anxious',
        moodIntensity: 8,
        energyLevel: 4,
        sleepHours: 5.0,
      );

      // shareWithAiCompanion == false
      final context1 = AiCompanionContextSelector.buildContext(
        profile: profileNoShare,
        latestTrace: dummyTrace,
        historicalTraces: [dummyTrace],
        journey: null,
      );
      expect(context1, isEmpty);

      // allowAiPersonalization == false
      final context2 = AiCompanionContextSelector.buildContext(
        profile: profileNoPersonalization,
        latestTrace: dummyTrace,
        historicalTraces: [dummyTrace],
        journey: null,
      );
      expect(context2, isEmpty);

      // forceDisablePersonalization == true override
      final profileWithConsent = PsychologicalProfileModel(
        preferredName: 'Charlie',
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: DateTime(2026, 1, 1),
      );
      final context3 = AiCompanionContextSelector.buildContext(
        profile: profileWithConsent,
        latestTrace: dummyTrace,
        historicalTraces: [dummyTrace],
        journey: null,
        forceDisablePersonalization: true,
      );
      expect(context3, isEmpty);
    });

    // -------------------------------------------------------------------------
    // Requirement 2: Consent Enabled & Raw Journal Text Protection
    // -------------------------------------------------------------------------
    test('2. Consent enabled includes permitted telemetry, but NEVER transmits raw journal text', () {
      const privateJournal = 'This is deeply personal and must never reach any AI server.';
      final profile = PsychologicalProfileModel(
        preferredName: 'Samira',
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: DateTime(2026, 1, 1),
        conditions: const [
          UserConditionEntry(
            condition: ConditionType.generalizedAnxiety,
            status: DiagnosticStatus.selfIdentifiedExploring,
          ),
        ],
        selectedSymptoms: const ['Restlessness'],
      );

      final now = DateTime.now();
      final trace = MindTraceModel(
        id: 'trace-priv',
        date: now,
        createdAt: now,
        updatedAt: now,
        overallMood: 'calm',
        moodIntensity: 6,
        energyLevel: 5,
        sleepHours: 7.5,
        selectedEmotions: const ['reflective', 'grounded'],
        journalText: privateJournal,
      );

      final context = AiCompanionContextSelector.buildContext(
        profile: profile,
        latestTrace: trace,
        historicalTraces: [trace],
        journey: null,
      );

      // Permitted data is present
      expect(context, contains('Samira'));
      expect(context, contains('Generalized Anxiety'));
      expect(context, contains('Restlessness'));
      expect(context, contains('calm (Intensity: 6/10)'));
      expect(context, contains('reflective, grounded'));

      // Raw journal text MUST be absent
      expect(context, isNot(contains(privateJournal)));
      expect(context.toLowerCase(), isNot(contains('deeply personal')));
    });

    // -------------------------------------------------------------------------
    // Requirement 3: Zero Observations Behavior (No invented baseline)
    // -------------------------------------------------------------------------
    test('3. Zero observations produces empty baseline with zero manufactured values', () {
      final baseline = PersonalBaseline.fromTraces([]);
      expect(baseline.totalRecordedDays, equals(0));
      expect(baseline.hasSufficientData, isFalse);
      expect(baseline.hasSleepData, isFalse);
      expect(baseline.hasEnergyData, isFalse);
      expect(baseline.hasMoodData, isFalse);
      expect(baseline.averageSleepHours, isNull);
      expect(baseline.medianSleepHours, isNull);
      expect(baseline.averageEnergyLevel, isNull);
      expect(baseline.medianEnergyLevel, isNull);
      expect(baseline.averageMoodIntensity, isNull);
      expect(baseline.sleepObservationCount, equals(0));
      expect(baseline.energyObservationCount, equals(0));

      final profile = PsychologicalProfileModel(
        preferredName: 'Tarek',
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: DateTime(2026, 1, 1),
      );

      final context = AiCompanionContextSelector.buildContext(
        profile: profile,
        latestTrace: null,
        historicalTraces: [],
        journey: null,
      );

      // Baseline section must not be injected when traces is empty
      expect(context, isNot(contains('PERSONAL BASELINE (Self-Reported')));
    });

    // -------------------------------------------------------------------------
    // Requirement 4: Insufficient Observations (< 3 Days) Suppresses Baseline Claims
    // -------------------------------------------------------------------------
    test('4. Fewer than 3 days marks status as Calibrating and suppresses baseline claims', () {
      final now = DateTime.now();
      final traces = [
        MindTraceModel(
          id: 't1',
          date: now,
          createdAt: now,
          updatedAt: now,
          sleepHours: 7.0,
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
          moodIntensity: 6,
        ),
      ];

      final baseline = PersonalBaseline.fromTraces(traces);
      expect(baseline.totalRecordedDays, equals(2));
      expect(baseline.hasSufficientData, isFalse);

      final profile = PsychologicalProfileModel(
        preferredName: 'Maya',
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: DateTime(2026, 1, 1),
      );

      final context = AiCompanionContextSelector.buildContext(
        profile: profile,
        latestTrace: traces.first,
        historicalTraces: traces,
        journey: null,
      );

      expect(context, contains('PERSONAL BASELINE STATUS:'));
      expect(context, contains('Status: Calibrating (2/3 days observed).'));
      expect(context, contains('Insufficient longitudinal data. Do not make claims about the user\'s usual baseline'));
      expect(context, isNot(contains('Average 7.5h')));
    });

    // -------------------------------------------------------------------------
    // Requirement 5: Missing Sleep Telemetry (Zero Fabrication)
    // -------------------------------------------------------------------------
    test('5. Missing sleep data is never fabricated or defaulted to 7.0h', () {
      final now = DateTime.now();
      final traces = [
        MindTraceModel(
          id: 't1',
          date: now,
          createdAt: now,
          updatedAt: now,
          energyLevel: 6,
          moodIntensity: 7,
          sleepHours: null, // Unrecorded
        ),
        MindTraceModel(
          id: 't2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          energyLevel: 5,
          moodIntensity: 6,
          sleepHours: null, // Unrecorded
        ),
        MindTraceModel(
          id: 't3',
          date: now.subtract(const Duration(days: 2)),
          createdAt: now,
          updatedAt: now,
          energyLevel: 7,
          moodIntensity: 8,
          sleepHours: null, // Unrecorded
        ),
      ];

      final baseline = PersonalBaseline.fromTraces(traces);
      expect(baseline.hasSufficientData, isTrue);
      expect(baseline.hasSleepData, isFalse);
      expect(baseline.sleepObservationCount, equals(0));
      expect(baseline.averageSleepHours, isNull);
      expect(baseline.medianSleepHours, isNull);

      final profile = PsychologicalProfileModel(
        preferredName: 'Nour',
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: DateTime(2026, 1, 1),
      );

      final context = AiCompanionContextSelector.buildContext(
        profile: profile,
        latestTrace: traces.first,
        historicalTraces: traces,
        journey: null,
      );

      expect(context, contains('Sleep: Not tracked (0 recorded entries)'));
      expect(context, contains('Do not make claims about sleep patterns'));
      expect(context, isNot(contains('7.0h')));
    });

    // -------------------------------------------------------------------------
    // Requirement 6: Missing Energy Telemetry (Zero Fabrication)
    // -------------------------------------------------------------------------
    test('6. Missing energy data is never fabricated or defaulted to 5.0', () {
      final now = DateTime.now();
      final traces = [
        MindTraceModel(
          id: 't1',
          date: now,
          createdAt: now,
          updatedAt: now,
          sleepHours: 8.0,
          moodIntensity: 6,
          energyLevel: null, // Truly unrecorded
        ),
        MindTraceModel(
          id: 't2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 7.5,
          moodIntensity: 7,
          energyLevel: null, // Truly unrecorded
        ),
        MindTraceModel(
          id: 't3',
          date: now.subtract(const Duration(days: 2)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 8.5,
          moodIntensity: 6,
          energyLevel: null, // Truly unrecorded
        ),
      ];

      final baseline = PersonalBaseline.fromTraces(traces);
      expect(baseline.hasSufficientData, isTrue);
      expect(baseline.hasEnergyData, isFalse);
      expect(baseline.energyObservationCount, equals(0));
      expect(baseline.averageEnergyLevel, isNull);
      expect(baseline.medianEnergyLevel, isNull);

      final profile = PsychologicalProfileModel(
        preferredName: 'Karim',
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: DateTime(2026, 1, 1),
      );

      final context = AiCompanionContextSelector.buildContext(
        profile: profile,
        latestTrace: traces.first,
        historicalTraces: traces,
        journey: null,
      );

      expect(context, contains('Energy Level: Not tracked (0 recorded entries)'));
      expect(context, contains('Do not make claims about typical energy'));
    });

    // -------------------------------------------------------------------------
    // Requirement 7: Valid Baseline Calculation (Independent metrics, medians & counts)
    // -------------------------------------------------------------------------
    test('7. Valid baseline computes averages, medians, and observation counts accurately', () {
      final now = DateTime.now();
      // 4 days with varied values to test median vs average
      // Sleep: [6.0, 7.0, 8.0, 9.0] -> avg = 7.5, median = (7.0+8.0)/2 = 7.5
      // Energy: [3, 4, 7, 10] -> avg = 6.0, median = (4+7)/2 = 5.5
      // Mood: [4, 5, 5, 6] -> avg = 5.0, median = 5.0
      final traces = [
        MindTraceModel(
          id: 't1',
          date: now,
          createdAt: now,
          updatedAt: now,
          sleepHours: 6.0,
          energyLevel: 3,
          moodIntensity: 4,
          physicalTension: 6,
          anxietyLevel: 5,
        ),
        MindTraceModel(
          id: 't2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 7.0,
          energyLevel: 4,
          moodIntensity: 5,
          physicalTension: 5,
          anxietyLevel: 4,
        ),
        MindTraceModel(
          id: 't3',
          date: now.subtract(const Duration(days: 2)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 8.0,
          energyLevel: 7,
          moodIntensity: 5,
          physicalTension: 4,
          anxietyLevel: 3,
        ),
        MindTraceModel(
          id: 't4',
          date: now.subtract(const Duration(days: 3)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 9.0,
          energyLevel: 10,
          moodIntensity: 6,
          physicalTension: 5,
          anxietyLevel: 4,
        ),
      ];

      final baseline = PersonalBaseline.fromTraces(traces);
      expect(baseline.totalRecordedDays, equals(4));
      expect(baseline.hasSufficientData, isTrue);

      // Sleep
      expect(baseline.sleepObservationCount, equals(4));
      expect(baseline.averageSleepHours, equals(7.5));
      expect(baseline.medianSleepHours, equals(7.5));

      // Energy
      expect(baseline.energyObservationCount, equals(4));
      expect(baseline.averageEnergyLevel, equals(6.0));
      expect(baseline.medianEnergyLevel, equals(5.5));

      // Mood
      expect(baseline.moodObservationCount, equals(4));
      expect(baseline.averageMoodIntensity, equals(5.0));
      expect(baseline.medianMoodIntensity, equals(5.0));

      // Tension & Anxiety
      expect(baseline.tensionObservationCount, equals(4));
      expect(baseline.averageTensionLevel, equals(5.0));
      expect(baseline.anxietyObservationCount, equals(4));
      expect(baseline.averageAnxietyLevel, equals(4.0));

      final profile = PsychologicalProfileModel(
        preferredName: 'Amina',
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: DateTime(2026, 1, 1),
      );

      final context = AiCompanionContextSelector.buildContext(
        profile: profile,
        latestTrace: traces.first,
        historicalTraces: traces,
        journey: null,
      );

      expect(context, contains('Sleep: Average 7.5h, Median 7.5h (4 nights recorded)'));
      expect(context, contains('Energy Level: Average 6.0/10, Median 5.5/10 (4 entries recorded)'));
      expect(context, contains('Mood Intensity: Average 5.0/10, Median 5.0/10 (4 entries recorded)'));
      expect(context, contains('Physical Tension: Average 5.0/10 (4 entries recorded)'));
      expect(context, contains('Anxiety / Stress: Average 4.0/10 (4 entries recorded)'));
    });

    // -------------------------------------------------------------------------
    // Requirement 8: Meaningful Numerical Deviation Without Clinical Claims
    // -------------------------------------------------------------------------
    test('8. Numerical deviations communicate observations without diagnostic claims', () {
      final now = DateTime.now();
      const baseline = PersonalBaseline(
        totalRecordedDays: 14,
        hasSufficientData: true,
        averageSleepHours: 8.0,
        medianSleepHours: 8.0,
        averageEnergyLevel: 5.0,
        medianEnergyLevel: 5.0,
        averageMoodIntensity: 5.0,
        medianMoodIntensity: 5.0,
        sleepObservationCount: 14,
        energyObservationCount: 14,
        moodObservationCount: 14,
        commonEmotions: ['calm'],
        recurringSymptoms: [],
        recurringTriggers: [],
      );

      // Recent 2 days have steep sleep drop and high energy
      final recentTraces = [
        MindTraceModel(
          id: 'dev1',
          date: now,
          createdAt: now,
          updatedAt: now,
          sleepHours: 4.5, // 3.5h below baseline
          energyLevel: 8,  // +3.0 above baseline
          moodIntensity: 7,
          racingThoughts: 8,
        ),
        MindTraceModel(
          id: 'dev2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 4.0, // 4.0h below baseline
          energyLevel: 8,
          moodIntensity: 7,
          racingThoughts: 7,
        ),
      ];

      final divergences = PatternAwarenessService.detectDivergences(
        traces: recentTraces,
        baseline: baseline,
      );

      expect(divergences, isNotEmpty);
      final div = divergences.firstWhere(
        (d) => d.category == DivergenceCategory.elevatedActivation,
      );

      // Verify empirical non-clinical content
      expect(div.title, contains('Energy & Sleep'));
      expect(div.uncertaintyStatement, contains('not a clinical diagnosis'));
      expect(div.contributingObservations.any((o) => o.contains('Recorded sleep averaged')), isTrue);
      expect(div.baselineComparison, contains('Sleep is lower by'));

      // Must NOT contain clinical diagnoses or relapse declarations
      expect(div.title.toLowerCase(), isNot(contains('hypomania')));
      expect(div.title.toLowerCase(), isNot(contains('mania')));
      expect(div.title.toLowerCase(), isNot(contains('bipolar relapse')));
      expect(div.baselineComparison.toLowerCase(), isNot(contains('relapse predicted')));
      expect(div.uncertaintyStatement.toLowerCase(), isNot(contains('relapse predicted')));

      // Verify prompt inclusion with guardrails
      final profile = PsychologicalProfileModel(
        preferredName: 'Sami',
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: DateTime(2026, 1, 1),
      );

      final baselineHistoryTraces = List.generate(
        10,
        (i) => MindTraceModel(
          id: 'base_$i',
          date: now.subtract(Duration(days: i + 3)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 8.0,
          energyLevel: 5,
          moodIntensity: 5,
        ),
      );
      final allTraces = [...recentTraces, ...baselineHistoryTraces];

      final context = AiCompanionContextSelector.buildContext(
        profile: profile,
        latestTrace: recentTraces.first,
        historicalTraces: allTraces,
        journey: null,
      );

      expect(context, contains('never as a clinical diagnosis, episode confirmation, or relapse prediction'));
      expect(context, contains('Frame any shift strictly as a self-reported difference in logged data'));
    });

    // -------------------------------------------------------------------------
    // Requirement 9: All 6 Conversation Modes Preserve Integrity with Context
    // -------------------------------------------------------------------------
    test('9. All 6 conversation modes integrate context while preserving mode distinction', () {
      final profile = PsychologicalProfileModel(
        preferredName: 'Fatma',
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: DateTime(2026, 1, 1),
      );

      final contextSnippet = AiCompanionContextSelector.buildContext(
        profile: profile,
        latestTrace: null,
        historicalTraces: null,
        journey: null,
      );

      for (final mode in ConversationMode.values) {
        final prompt = AiCompanionSystemPrompt.buildFullPrompt(
          mode: mode,
          languageCode: 'en',
          conditions: const [ConditionType.adhd],
          contextualUserPrompt: contextSnippet,
        );

        // Core instructions present
        expect(prompt, contains('CURRENT CONVERSATION MODE: ${mode.displayName.toUpperCase()}'));
        expect(prompt, contains('Fatma'));
        expect(prompt, contains('ADHD & ATTENTION'));
        expect(prompt, contains('5. Evidence-Based Personal Baseline & Pattern Grounding:'));

        // Mode specific opening question matches
        expect(mode.openingQuestion, isNotEmpty);
      }
    });

    // -------------------------------------------------------------------------
    // Requirement 10: Mock/Offline AI Behavior Remains Fully Functional
    // -------------------------------------------------------------------------
    test('10. MockInvestigatorService runs offline and accepts historicalTraces smoothly', () async {
      final mockService = MockInvestigatorService();

      final now = DateTime.now();
      final traces = [
        MindTraceModel(
          id: 'm1',
          date: now,
          createdAt: now,
          updatedAt: now,
          sleepHours: 7.0,
          energyLevel: 5,
        ),
      ];

      final currentCase = CaseModel(
        id: 'test-case-1',
        userId: 'local_user',
        caseNumber: 'CASE-001',
        title: 'Test Session',
        createdAt: now,
        updatedAt: now,
        conversationMode: ConversationMode.grounding,
        currentStage: CaseStage.incident,
        incidentDescription: 'Test incident',
      );

      // Grounding mode
      final q1 = await mockService.getNextQuestion(
        currentCase: currentCase,
        conversationHistory: const [],
        conversationMode: ConversationMode.grounding,
        historicalTraces: traces,
      );
      expect(q1, isNotNull);
      expect(q1, contains('breath'));

      // Understand Emotion mode
      final q2 = await mockService.getNextQuestion(
        currentCase: currentCase,
        conversationHistory: const [],
        conversationMode: ConversationMode.understandEmotion,
        historicalTraces: traces,
      );
      expect(q2, isNotNull);
      expect(q2, contains('emotion without judging'));

      // Psychological Analysis mode
      final q3 = await mockService.getNextQuestion(
        currentCase: currentCase,
        conversationHistory: const [],
        conversationMode: ConversationMode.psychologicalAnalysis,
        historicalTraces: traces,
      );
      expect(q3, isNotNull);
      expect(q3, contains('connections'));
    });

    // -------------------------------------------------------------------------
    // Audit & Regression Group: Zero vs Missing Data & Non-Arbitrary Shifts
    // -------------------------------------------------------------------------
    test('11. Zero sleep (0.0h) is preserved as a valid observation and not treated as missing', () {
      final now = DateTime.now();
      final traces = [
        MindTraceModel(
          id: 'z_sleep_1',
          date: now,
          createdAt: now,
          updatedAt: now,
          sleepHours: 0.0, // Total sleeplessness
          energyLevel: 2,
          moodIntensity: 3,
        ),
        MindTraceModel(
          id: 'z_sleep_2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 4.0,
          energyLevel: 4,
          moodIntensity: 4,
        ),
        MindTraceModel(
          id: 'z_sleep_3',
          date: now.subtract(const Duration(days: 2)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 8.0,
          energyLevel: 6,
          moodIntensity: 5,
        ),
      ];

      final baseline = PersonalBaseline.fromTraces(traces);
      // 0.0h must be included in count: 3 nights
      expect(baseline.sleepObservationCount, equals(3));
      expect(baseline.hasSleepData, isTrue);
      // Average: (0.0 + 4.0 + 8.0) / 3 = 4.0h
      expect(baseline.averageSleepHours, equals(4.0));
      expect(baseline.medianSleepHours, equals(4.0));

      final profile = PsychologicalProfileModel(
        preferredName: 'Zayd',
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: DateTime(2026, 1, 1),
      );

      final context = AiCompanionContextSelector.buildContext(
        profile: profile,
        latestTrace: traces.first,
        historicalTraces: traces,
        journey: null,
      );

      // Latest trace with 0.0 hours sleep MUST be present in daily check-in section
      expect(context, contains('• Sleep Duration: 0.0 hours'));
    });

    test('12. Zero anxiety (0/10) is preserved as valid calm rating and not treated as missing', () {
      final now = DateTime.now();
      final traces = [
        MindTraceModel(
          id: 'z_anx_1',
          date: now,
          createdAt: now,
          updatedAt: now,
          anxietyLevel: 0, // Zero anxiety / completely calm
          moodIntensity: 6,
        ),
        MindTraceModel(
          id: 'z_anx_2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          anxietyLevel: 0,
          moodIntensity: 7,
        ),
        MindTraceModel(
          id: 'z_anx_3',
          date: now.subtract(const Duration(days: 2)),
          createdAt: now,
          updatedAt: now,
          anxietyLevel: 3,
          moodIntensity: 5,
        ),
      ];

      final baseline = PersonalBaseline.fromTraces(traces);
      // 0 anxiety must be counted: 3 observations
      expect(baseline.anxietyObservationCount, equals(3));
      expect(baseline.hasAnxietyData, isTrue);
      // Average: (0 + 0 + 3) / 3 = 1.0
      expect(baseline.averageAnxietyLevel, equals(1.0));

      final profile = PsychologicalProfileModel(
        preferredName: 'Salma',
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: DateTime(2026, 1, 1),
      );

      final context = AiCompanionContextSelector.buildContext(
        profile: profile,
        latestTrace: traces.first,
        historicalTraces: traces,
        journey: null,
      );

      // Latest trace with anxiety = 0 MUST be present
      expect(context, contains('• Anxiety Level: 0/10'));
    });

    test('13. Zero physical tension (0/10) is preserved as valid observation and not treated as missing', () {
      final now = DateTime.now();
      final traces = [
        MindTraceModel(
          id: 'z_ten_1',
          date: now,
          createdAt: now,
          updatedAt: now,
          physicalTension: 0, // Zero tension / completely relaxed
          moodIntensity: 6,
        ),
        MindTraceModel(
          id: 'z_ten_2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          physicalTension: 2,
          moodIntensity: 5,
        ),
        MindTraceModel(
          id: 'z_ten_3',
          date: now.subtract(const Duration(days: 2)),
          createdAt: now,
          updatedAt: now,
          physicalTension: 4,
          moodIntensity: 5,
        ),
      ];

      final baseline = PersonalBaseline.fromTraces(traces);
      expect(baseline.tensionObservationCount, equals(3));
      expect(baseline.hasTensionData, isTrue);
      // Average: (0 + 2 + 4) / 3 = 2.0
      expect(baseline.averageTensionLevel, equals(2.0));

      final profile = PsychologicalProfileModel(
        preferredName: 'Ines',
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: DateTime(2026, 1, 1),
      );

      final context = AiCompanionContextSelector.buildContext(
        profile: profile,
        latestTrace: traces.first,
        historicalTraces: traces,
        journey: null,
      );

      expect(context, contains('• Physical Tension: 0/10'));
    });

    test('14. Missing data (null) is distinguished from 0 and does not distort averages', () {
      final now = DateTime.now();
      final traces = [
        MindTraceModel(
          id: 'm_null_1',
          date: now,
          createdAt: now,
          updatedAt: now,
          sleepHours: null, // Untracked sleep
          anxietyLevel: null, // Untracked anxiety
          energyLevel: null, // Untracked energy
          moodIntensity: 6,
        ),
        MindTraceModel(
          id: 'm_null_2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 6.0,
          anxietyLevel: 2,
          energyLevel: 4,
          moodIntensity: 6,
        ),
        MindTraceModel(
          id: 'm_null_3',
          date: now.subtract(const Duration(days: 2)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 8.0,
          anxietyLevel: 4,
          energyLevel: 6,
          moodIntensity: 6,
        ),
      ];

      final baseline = PersonalBaseline.fromTraces(traces);
      // Only 2 observations for sleep, anxiety, energy (day 1 was null)
      expect(baseline.sleepObservationCount, equals(2));
      expect(baseline.anxietyObservationCount, equals(2));
      expect(baseline.energyObservationCount, equals(2));
      expect(baseline.moodObservationCount, equals(3)); // mood was recorded on all 3

      // Average sleep must be (6.0 + 8.0) / 2 = 7.0h (NOT divided by 3, which would be 4.67h!)
      expect(baseline.averageSleepHours, equals(7.0));
      expect(baseline.averageAnxietyLevel, equals(3.0));
      expect(baseline.averageEnergyLevel, equals(5.0));
    });

    test('15. Multiple check-ins on a single calendar day do not inflate distinct days or skew averages', () {
      final now = DateTime.now();
      final day1 = now.subtract(const Duration(days: 2));
      final day2 = now.subtract(const Duration(days: 1));
      final day3 = now;

      // Day 1 has 3 entries; the latest updated entry has sleep = 7.0h
      final traces = [
        MindTraceModel(
          id: 'd1_e1',
          date: day1,
          createdAt: day1,
          updatedAt: day1.add(const Duration(hours: 1)),
          sleepHours: 4.0,
          energyLevel: 3,
        ),
        MindTraceModel(
          id: 'd1_e2',
          date: day1,
          createdAt: day1,
          updatedAt: day1.add(const Duration(hours: 2)),
          sleepHours: 5.0,
          energyLevel: 4,
        ),
        MindTraceModel(
          id: 'd1_e3', // latest for Day 1
          date: day1,
          createdAt: day1,
          updatedAt: day1.add(const Duration(hours: 3)),
          sleepHours: 7.0,
          energyLevel: 6,
        ),
        MindTraceModel(
          id: 'd2_e1',
          date: day2,
          createdAt: day2,
          updatedAt: day2,
          sleepHours: 7.0,
          energyLevel: 6,
        ),
        MindTraceModel(
          id: 'd3_e1',
          date: day3,
          createdAt: day3,
          updatedAt: day3,
          sleepHours: 7.0,
          energyLevel: 6,
        ),
      ];

      final baseline = PersonalBaseline.fromTraces(traces);
      // Total distinct recorded days must be exactly 3, despite 5 total traces
      expect(baseline.totalRecordedDays, equals(3));
      expect(baseline.sleepObservationCount, equals(3));
      expect(baseline.energyObservationCount, equals(3));

      // With deduplication using the latest entry of day 1 (7.0h), average is (7+7+7)/3 = 7.0
      expect(baseline.averageSleepHours, equals(7.0));
      expect(baseline.averageEnergyLevel, equals(6.0));
    });

    test('16. Boundary Test: Exact 30-day baseline window includes today and 29 preceding days, excluding 30th day ago', () {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // Create boundary traces:
      // T (today) -> must be included
      final todayTrace = MindTraceModel(
        id: 't_today',
        date: todayStart.add(const Duration(hours: 10)),
        createdAt: now,
        updatedAt: now,
        sleepHours: 7.0,
      );

      // T-29 (29 days ago, earliest included calendar date) -> must be included
      final earliestTrace = MindTraceModel(
        id: 't_earliest_29',
        date: todayStart.subtract(const Duration(days: 29)).add(const Duration(hours: 8)),
        createdAt: now,
        updatedAt: now,
        sleepHours: 7.0,
      );

      // T-30 (30 days ago, first excluded calendar date) -> must be excluded
      final outsidePastTrace = MindTraceModel(
        id: 't_outside_30',
        date: todayStart.subtract(const Duration(days: 30)).add(const Duration(hours: 23)),
        createdAt: now,
        updatedAt: now,
        sleepHours: 12.0, // If included, it would skew average
      );

      // T+1 (tomorrow) -> must be excluded
      final outsideFutureTrace = MindTraceModel(
        id: 't_outside_future',
        date: todayStart.add(const Duration(days: 1, hours: 2)),
        createdAt: now,
        updatedAt: now,
        sleepHours: 12.0,
      );

      // In-between day (T-15) -> must be included
      final midTrace = MindTraceModel(
        id: 't_mid_15',
        date: todayStart.subtract(const Duration(days: 15)),
        createdAt: now,
        updatedAt: now,
        sleepHours: 7.0,
      );

      final traces = [
        outsidePastTrace,
        earliestTrace,
        midTrace,
        todayTrace,
        outsideFutureTrace,
      ];

      final baseline = PersonalBaseline.fromTraces(traces, baselineDays: 30);

      // Only today, T-15, and T-29 should be included (exactly 3 distinct dates)
      expect(baseline.totalRecordedDays, equals(3));
      expect(baseline.hasSufficientData, isTrue);
      // Average must be (7.0 + 7.0 + 7.0) / 3 = 7.0h (12.0h past and future traces excluded)
      expect(baseline.averageSleepHours, equals(7.0));

      // 30 distinct days test
      final all35Days = List.generate(35, (i) {
        final d = todayStart.subtract(Duration(days: i));
        return MindTraceModel(
          id: 'day_$i',
          date: d,
          createdAt: now,
          updatedAt: now,
          sleepHours: 8.0,
        );
      });

      final fullWindowBaseline = PersonalBaseline.fromTraces(all35Days, baselineDays: 30);
      // Must contain exactly 30 distinct calendar dates (Day 0 through Day 29)
      expect(fullWindowBaseline.totalRecordedDays, equals(30));
    });

    test('17. Energy Scale Consistency: Strictly 1–10 scale; null denotes missing; 0 is excluded', () {
      final now = DateTime.now();
      final traces = [
        MindTraceModel(
          id: 'e1',
          date: now,
          createdAt: now,
          updatedAt: now,
          energyLevel: 5, // Valid: 5/10
          moodIntensity: 6,
        ),
        MindTraceModel(
          id: 'e2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          energyLevel: 9, // Valid: 9/10
          moodIntensity: 6,
        ),
        MindTraceModel(
          id: 'e3',
          date: now.subtract(const Duration(days: 2)),
          createdAt: now,
          updatedAt: now,
          energyLevel: 0, // Out-of-scale (interface supports 1-10) -> excluded
          moodIntensity: 6,
        ),
        MindTraceModel(
          id: 'e4',
          date: now.subtract(const Duration(days: 3)),
          createdAt: now,
          updatedAt: now,
          energyLevel: null, // Missing / unrecorded -> excluded
          moodIntensity: 6,
        ),
      ];

      final baseline = PersonalBaseline.fromTraces(traces);
      // Only e1 (5) and e2 (9) are valid energy observations
      expect(baseline.energyObservationCount, equals(2));
      expect(baseline.averageEnergyLevel, equals(7.0)); // (5 + 9) / 2 = 7.0
      expect(baseline.medianEnergyLevel, equals(7.0));
    });

    test('18. Independent Shift: Sleep difference is reported independently when energy does NOT change', () {
      final now = DateTime.now();
      const baseline = PersonalBaseline(
        totalRecordedDays: 14,
        hasSufficientData: true,
        averageSleepHours: 8.0,
        averageEnergyLevel: 5.0,
        averageMoodIntensity: 5.0,
        sleepObservationCount: 14,
        energyObservationCount: 14,
        moodObservationCount: 14,
      );

      // Sleep drops significantly to 4.5h, but energy stays exactly at baseline (5/10)
      final recentTraces = [
        MindTraceModel(
          id: 's_only_1',
          date: now,
          createdAt: now,
          updatedAt: now,
          sleepHours: 4.5, // 3.5h below baseline
          energyLevel: 5,  // Exact baseline (no surge)
          moodIntensity: 5,
        ),
        MindTraceModel(
          id: 's_only_2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 4.5, // 3.5h below baseline
          energyLevel: 5,  // Exact baseline
          moodIntensity: 5,
        ),
      ];

      final divergences = PatternAwarenessService.detectDivergences(
        traces: recentTraces,
        baseline: baseline,
      );

      // Sleep shift MUST NOT be hidden just because energy didn't surge
      expect(divergences, isNotEmpty);
      final sleepDiv = divergences.firstWhere(
        (d) => d.category == DivergenceCategory.sleepDisruption,
      );
      expect(sleepDiv.title, contains('Sleep Duration'));
      expect(sleepDiv.observationType, equals(ObservationType.individualMetricShift));
      expect(sleepDiv.baselineComparison, contains('lower by 3.5h'));
    });

    test('19. Co-Occurring Combinations: Grouped when multiple metrics shift simultaneously', () {
      final now = DateTime.now();
      const baseline = PersonalBaseline(
        totalRecordedDays: 14,
        hasSufficientData: true,
        averageSleepHours: 8.0,
        averageEnergyLevel: 5.0,
        averageMoodIntensity: 5.0,
        sleepObservationCount: 14,
        energyObservationCount: 14,
        moodObservationCount: 14,
      );

      // Sleep drops AND energy surges
      final recentTraces = [
        MindTraceModel(
          id: 'comb_1',
          date: now,
          createdAt: now,
          updatedAt: now,
          sleepHours: 5.0,
          energyLevel: 8,
          moodIntensity: 6,
        ),
        MindTraceModel(
          id: 'comb_2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 5.0,
          energyLevel: 8,
          moodIntensity: 6,
        ),
      ];

      final divergences = PatternAwarenessService.detectDivergences(
        traces: recentTraces,
        baseline: baseline,
      );

      // Combined shift must be identified with ObservationType.combinedMetricShift
      final combinedDiv = divergences.firstWhere(
        (d) => d.category == DivergenceCategory.elevatedActivation,
      );
      expect(combinedDiv.observationType, equals(ObservationType.combinedMetricShift));
      expect(combinedDiv.title, contains('Shift in Energy & Sleep'));
    });

    test('20. Repeated Patterns vs Single Observations: Distinguishes 1-day vs multi-day elevations', () {
      final now = DateTime.now();
      const baseline = PersonalBaseline(
        totalRecordedDays: 14,
        hasSufficientData: true,
        averageSleepHours: 8.0,
        averageEnergyLevel: 5.0,
        averageMoodIntensity: 5.0,
        averageTensionLevel: 3.0,
        tensionObservationCount: 14,
      );

      // Single day high tension
      final singleDayTraces = [
        MindTraceModel(
          id: 'ten_single_1',
          date: now,
          createdAt: now,
          updatedAt: now,
          physicalTension: 8,
        ),
        MindTraceModel(
          id: 'ten_single_2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          physicalTension: 3,
        ),
      ];

      final divsSingle = PatternAwarenessService.detectDivergences(
        traces: singleDayTraces,
        baseline: baseline,
      );
      final singleDiv = divsSingle.firstWhere((d) => d.category == DivergenceCategory.elevatedTension);
      expect(singleDiv.observationType, equals(ObservationType.individualMetricShift));
      expect(singleDiv.title, contains('Physical Tension'));

      // Multi-day observations (across 2 separate days)
      final multiDayTraces = [
        MindTraceModel(
          id: 'ten_multi_1',
          date: now,
          createdAt: now,
          updatedAt: now,
          physicalTension: 8,
        ),
        MindTraceModel(
          id: 'ten_multi_2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          physicalTension: 8,
        ),
      ];

      final divsMulti = PatternAwarenessService.detectDivergences(
        traces: multiDayTraces,
        baseline: baseline,
      );
      final multiDiv = divsMulti.firstWhere((d) => d.category == DivergenceCategory.elevatedTension);
      expect(multiDiv.observationType, equals(ObservationType.longitudinalPattern));
      expect(multiDiv.title, contains('Across 2 Days'));
    });

    // -------------------------------------------------------------------------
    // Requirement 21: Exclusive Upper Date Boundary Regression Test
    // -------------------------------------------------------------------------
    test('21. Regression Test: Trace exactly at midnight tomorrow is strictly excluded by exclusive upper boundary', () {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final tomorrowStart = todayStart.add(const Duration(days: 1)); // Exactly midnight tomorrow (00:00:00.000)

      final traces = [
        // Trace today at 23:59:59.999 -> Included
        MindTraceModel(
          id: 't_today_late',
          date: todayStart.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 8.0,
          energyLevel: 6,
          moodIntensity: 6,
        ),
        // Trace exactly at 00:00:00.000 tomorrow -> MUST BE EXCLUDED
        MindTraceModel(
          id: 't_tomorrow_midnight',
          date: tomorrowStart,
          createdAt: now,
          updatedAt: now,
          sleepHours: 2.0, // If included, this would distort baseline average
          energyLevel: 1,
          moodIntensity: 1,
        ),
        // Two past traces within the 30-day window to satisfy minimum 3 days data requirement
        MindTraceModel(
          id: 't_yesterday',
          date: todayStart.subtract(const Duration(days: 1, hours: -12)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 8.0,
          energyLevel: 6,
          moodIntensity: 6,
        ),
        MindTraceModel(
          id: 't_2days_ago',
          date: todayStart.subtract(const Duration(days: 2, hours: -12)),
          createdAt: now,
          updatedAt: now,
          sleepHours: 8.0,
          energyLevel: 6,
          moodIntensity: 6,
        ),
      ];

      final baseline = PersonalBaseline.fromTraces(traces, baselineDays: 30);

      // Only today, yesterday, and 2 days ago must be included (exactly 3 days)
      expect(baseline.totalRecordedDays, equals(3));
      // Average sleep must be 8.0h; if midnight tomorrow were included, it would be (8+8+8+2)/4 = 6.5h
      expect(baseline.averageSleepHours, equals(8.0));
      expect(baseline.averageEnergyLevel, equals(6.0));
      expect(baseline.averageMoodIntensity, equals(6.0));
    });

    // -------------------------------------------------------------------------
    // Requirement 22: Median Calculations for Anxiety & Tension (Independent Computation)
    // -------------------------------------------------------------------------
    test('22. Anxiety and Tension calculate medians independently from their observations', () {
      final now = DateTime.now();
      final traces = [
        MindTraceModel(
          id: 'med_1',
          date: now,
          createdAt: now,
          updatedAt: now,
          anxietyLevel: 2, // 2, 4, 9 -> median 4, mean (15/3)=5.0
          physicalTension: 3, // 3, 5, 8 -> median 5, mean (16/3)=5.3
        ),
        MindTraceModel(
          id: 'med_2',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          anxietyLevel: 9, // Outlier anxiety day
          physicalTension: 8,
        ),
        MindTraceModel(
          id: 'med_3',
          date: now.subtract(const Duration(days: 2)),
          createdAt: now,
          updatedAt: now,
          anxietyLevel: 4,
          physicalTension: 5,
        ),
      ];

      final baseline = PersonalBaseline.fromTraces(traces);
      expect(baseline.hasAnxietyData, isTrue);
      expect(baseline.hasTensionData, isTrue);
      expect(baseline.anxietyObservationCount, equals(3));
      expect(baseline.tensionObservationCount, equals(3));

      // Robust medians protect against single-day spikes
      expect(baseline.averageAnxietyLevel, equals(5.0));
      expect(baseline.medianAnxietyLevel, equals(4.0));

      expect(baseline.averageTensionLevel, equals(5.3));
      expect(baseline.medianTensionLevel, equals(5.0));
    });

    // -------------------------------------------------------------------------
    // Requirement 23: Variability (Standard Deviation) Correctly Computed
    // -------------------------------------------------------------------------
    test('23. Variability correctly computes standard deviation across observations', () {
      final now = DateTime.now();

      // Case A: Identical values -> variability must be exactly 0.0
      final consistentTraces = [
        MindTraceModel(id: 'c1', date: now, createdAt: now, updatedAt: now, sleepHours: 8.0, energyLevel: 6, moodIntensity: 7),
        MindTraceModel(id: 'c2', date: now.subtract(const Duration(days: 1)), createdAt: now, updatedAt: now, sleepHours: 8.0, energyLevel: 6, moodIntensity: 7),
        MindTraceModel(id: 'c3', date: now.subtract(const Duration(days: 2)), createdAt: now, updatedAt: now, sleepHours: 8.0, energyLevel: 6, moodIntensity: 7),
      ];
      final consistentBaseline = PersonalBaseline.fromTraces(consistentTraces);
      expect(consistentBaseline.sleepVariability, equals(0.0));
      expect(consistentBaseline.energyVariability, equals(0.0));
      expect(consistentBaseline.moodVariability, equals(0.0));

      // Case B: Fluctuating sleep: [6.0, 8.0, 10.0] -> mean 8.0, sqDiffs: [4, 0, 4] -> variance = 8/3 = 2.666... -> stdDev = 1.6
      final fluctuatingTraces = [
        MindTraceModel(id: 'f1', date: now, createdAt: now, updatedAt: now, sleepHours: 6.0, energyLevel: 4, moodIntensity: 5),
        MindTraceModel(id: 'f2', date: now.subtract(const Duration(days: 1)), createdAt: now, updatedAt: now, sleepHours: 8.0, energyLevel: 6, moodIntensity: 7),
        MindTraceModel(id: 'f3', date: now.subtract(const Duration(days: 2)), createdAt: now, updatedAt: now, sleepHours: 10.0, energyLevel: 8, moodIntensity: 9),
      ];
      final fluctuatingBaseline = PersonalBaseline.fromTraces(fluctuatingTraces);
      expect(fluctuatingBaseline.sleepVariability, equals(1.6));
      expect(fluctuatingBaseline.energyVariability, equals(1.6));
      expect(fluctuatingBaseline.moodVariability, equals(1.6));

      // Case C: Fewer than 2 observations -> variability is null
      final singleTrace = [
        MindTraceModel(id: 's1', date: now, createdAt: now, updatedAt: now, sleepHours: 7.5),
      ];
      final singleBaseline = PersonalBaseline.fromTraces(singleTrace);
      expect(singleBaseline.sleepVariability, isNull);
    });

    // -------------------------------------------------------------------------
    // Requirement 24: Stable vs Insufficient Baseline Distinction
    // -------------------------------------------------------------------------
    test('24. Distinguishes stable baseline (low variability) from calibrating history', () {
      final now = DateTime.now();

      // 2 days -> Insufficient / Calibrating
      final calibratingTraces = [
        MindTraceModel(id: 'cal_1', date: now, createdAt: now, updatedAt: now, sleepHours: 8.0),
        MindTraceModel(id: 'cal_2', date: now.subtract(const Duration(days: 1)), createdAt: now, updatedAt: now, sleepHours: 8.0),
      ];
      final calBaseline = PersonalBaseline.fromTraces(calibratingTraces);
      expect(calBaseline.hasSufficientData, isFalse);
      expect(calBaseline.hasSleepData, isFalse); // < 3 entries

      // 4 days with consistent values -> Initial observation sample, low observed variability
      final stableTraces = [
        MindTraceModel(id: 'st_1', date: now, createdAt: now, updatedAt: now, sleepHours: 7.5, energyLevel: 5, moodIntensity: 6),
        MindTraceModel(id: 'st_2', date: now.subtract(const Duration(days: 1)), createdAt: now, updatedAt: now, sleepHours: 7.5, energyLevel: 5, moodIntensity: 6),
        MindTraceModel(id: 'st_3', date: now.subtract(const Duration(days: 2)), createdAt: now, updatedAt: now, sleepHours: 8.0, energyLevel: 6, moodIntensity: 6),
        MindTraceModel(id: 'st_4', date: now.subtract(const Duration(days: 3)), createdAt: now, updatedAt: now, sleepHours: 7.5, energyLevel: 5, moodIntensity: 6),
      ];
      final stableBaseline = PersonalBaseline.fromTraces(stableTraces);
      expect(stableBaseline.hasSufficientData, isTrue);
      expect(stableBaseline.hasSleepData, isTrue);
      expect(stableBaseline.sleepVariability, lessThanOrEqualTo(0.5)); // Low variability confirms routine consistency
    });

    // -------------------------------------------------------------------------
    // Requirement 25: Baseline Status Semantics (Calibrating vs Preliminary vs Established)
    // -------------------------------------------------------------------------
    test('25. Baseline status semantics distinguish Calibrating, Preliminary, and Established Longitudinal Baselines', () {
      final now = DateTime.now();

      // Case A: 2 days (< 3 days) -> Calibrating (insufficient observation history)
      final calTraces = [
        MindTraceModel(id: 'c1', date: now, createdAt: now, updatedAt: now, moodIntensity: 5),
        MindTraceModel(id: 'c2', date: now.subtract(const Duration(days: 1)), createdAt: now, updatedAt: now, moodIntensity: 6),
      ];
      final calBaseline = PersonalBaseline.fromTraces(calTraces);
      expect(calBaseline.hasSufficientData, isFalse);
      expect(calBaseline.hasInitialObservations, isFalse);
      expect(calBaseline.hasEstablishedBaseline, isFalse);
      expect(calBaseline.statusLabel, equals('Calibrating (2/3d)'));

      // Case B: 5 days (3–13 days) -> Preliminary Observations (initial sample, not established baseline)
      final prelimTraces = List.generate(
        5,
        (i) => MindTraceModel(
          id: 'p$i',
          date: now.subtract(Duration(days: i)),
          createdAt: now,
          updatedAt: now,
          moodIntensity: 6,
          sleepHours: 7.5,
        ),
      );
      final prelimBaseline = PersonalBaseline.fromTraces(prelimTraces);
      expect(prelimBaseline.hasSufficientData, isTrue);
      expect(prelimBaseline.hasInitialObservations, isTrue);
      expect(prelimBaseline.hasEstablishedBaseline, isFalse);
      expect(prelimBaseline.statusLabel, equals('Preliminary Observations (5d)'));

      // Case C: 15 days (>= 14 days) -> Established Personal Baseline (longitudinal history)
      final establishedTraces = List.generate(
        15,
        (i) => MindTraceModel(
          id: 'e$i',
          date: now.subtract(Duration(days: i)),
          createdAt: now,
          updatedAt: now,
          moodIntensity: 6,
          sleepHours: 7.5,
        ),
      );
      final estBaseline = PersonalBaseline.fromTraces(establishedTraces);
      expect(estBaseline.hasSufficientData, isTrue);
      expect(estBaseline.hasInitialObservations, isTrue);
      expect(estBaseline.hasEstablishedBaseline, isTrue);
      expect(estBaseline.statusLabel, equals('Established Baseline (15d)'));
    });

    // -------------------------------------------------------------------------
    // Requirement 26: Low Observed Variability Semantics (SD <= 0.5)
    // -------------------------------------------------------------------------
    test('26. Low observed variability represents numerical consistency without asserting psychological stability', () {
      // Numerical consistency check (SD <= 0.5)
      expect(PersonalBaseline.hasLowObservedVariability(0.0), isTrue);
      expect(PersonalBaseline.hasLowObservedVariability(0.3), isTrue);
      expect(PersonalBaseline.hasLowObservedVariability(0.5), isTrue);

      // Higher fluctuations
      expect(PersonalBaseline.hasLowObservedVariability(0.6), isFalse);
      expect(PersonalBaseline.hasLowObservedVariability(1.5), isFalse);
      expect(PersonalBaseline.hasLowObservedVariability(null), isFalse);
    });

    // -------------------------------------------------------------------------
    // Requirement 27: AI Consent Bypass Audit across MindTraceAiService
    // -------------------------------------------------------------------------
    test('27. MindTraceAiService strictly enforces consent for both shareWithAiCompanion and allowAiPersonalization', () async {
      final now = DateTime.now();
      final currentTrace = MindTraceModel(
        id: 'trace_today',
        date: now,
        createdAt: now,
        updatedAt: now,
        overallMood: 'anxious',
        moodIntensity: 8,
        physicalTension: 8,
        journalText: 'Confidential personal journal reflection text.',
      );

      final history = [
        MindTraceModel(
          id: 'trace_hist_1',
          date: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          overallMood: 'overwhelmed',
          moodIntensity: 9,
          physicalTension: 8,
        ),
      ];

      final service = MindTraceAiService(apiKey: 'TEST_KEY');

      // Test Case A: shareWithAiCompanion = false
      final profileNoShare = PsychologicalProfileModel(
        preferredName: 'Yassine',
        shareWithAiCompanion: false,
        allowAiPersonalization: true,
        updatedAt: DateTime(2026, 1, 1),
      );

      final reflectionNoShare = await service.generateDailyReflection(
        currentTrace: currentTrace,
        history: history,
        profile: profileNoShare,
        languageCode: 'en',
      );

      expect(reflectionNoShare, isNotEmpty);
      // History should not be linked or mentioned because consent was denied
      expect(reflectionNoShare, isNot(contains('across several recent check-ins')));

      // Test Case B: allowAiPersonalization = false
      final profileNoPersonalize = PsychologicalProfileModel(
        preferredName: 'Yassine',
        shareWithAiCompanion: true,
        allowAiPersonalization: false,
        updatedAt: DateTime(2026, 1, 1),
      );

      final reflectionNoPers = await service.generateDailyReflection(
        currentTrace: currentTrace,
        history: history,
        profile: profileNoPersonalize,
        languageCode: 'en',
      );

      expect(reflectionNoPers, isNotEmpty);
      expect(reflectionNoPers, isNot(contains('across several recent check-ins')));

      // Test Case C: profile = null (strict fallback to local generator, zero history leak)
      final reflectionNullProfile = await service.generateDailyReflection(
        currentTrace: currentTrace,
        history: history,
        profile: null,
        languageCode: 'en',
      );

      expect(reflectionNullProfile, isNotEmpty);
      expect(reflectionNullProfile, isNot(contains('across several recent check-ins')));
    });

    // -------------------------------------------------------------------------
    // Requirement 28: Zero Raw Journal Text in any AI Prompt Pipeline
    // -------------------------------------------------------------------------
    test('28. Raw journal text is never transmitted or injected under any prompt path', () {
      final now = DateTime.now();
      const secretJournalText = 'VERY_SECRET_RAW_DIARY_ENTRY_12345';

      final traceWithDiary = MindTraceModel(
        id: 'trace_with_diary',
        date: now,
        createdAt: now,
        updatedAt: now,
        overallMood: 'reflective',
        moodIntensity: 5,
        journalText: secretJournalText,
        sleepHours: 7.5,
        energyLevel: 6,
      );

      final profileWithConsent = PsychologicalProfileModel(
        preferredName: 'Salma',
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: DateTime(2026, 1, 1),
      );

      // Path 1: Context selector
      final context = AiCompanionContextSelector.buildContext(
        profile: profileWithConsent,
        latestTrace: traceWithDiary,
        historicalTraces: [traceWithDiary],
        journey: null,
      );

      expect(context, isNot(contains(secretJournalText)));
      expect(context, isNot(contains('VERY_SECRET')));

      // Path 2: Full system prompt
      final fullPrompt = AiCompanionSystemPrompt.buildFullPrompt(
        mode: ConversationMode.exploreThought,
        languageCode: 'en',
        contextualUserPrompt: context,
      );

      expect(fullPrompt, isNot(contains(secretJournalText)));
      expect(fullPrompt, isNot(contains('VERY_SECRET')));
    });

    // -------------------------------------------------------------------------
    // Requirement 29: AI Clinical Non-Diagnostic Guardrails
    // -------------------------------------------------------------------------
    test('29. AI Companion system prompt strictly embeds non-diagnostic boundaries', () {
      final prompt = AiCompanionSystemPrompt.reasoningGuidelines;

      // Verifies non-diagnostic boundary guidelines
      expect(prompt, contains('NEVER diagnose mental health conditions'));
      expect(prompt, contains('NEVER claim or suggest that a user is entering a bipolar episode'));
      expect(prompt, contains('NEVER interpret isolated or short-term sleep changes as mania'));
      expect(prompt, contains('NEVER interpret self-reported anxiety, stress, or somatic tension ratings as clinical ground truth'));
      expect(prompt, contains('NEVER turn observed correlations or co-occurrences into definitive causal explanations'));
      expect(prompt, contains('Present all hypotheses and observations as gentle possibilities'));
      expect(prompt, contains('encourage professional clinical support warmly'));
    });
  });
}

