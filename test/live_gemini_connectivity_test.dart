@Timeout(Duration(minutes: 2))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/features/investigation/data/direct_gemini_investigator_service.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/conversation_mode.dart';
import 'package:mind_forensics/features/investigation/domain/statement.dart';
import 'package:mind_forensics/features/mind_trace/data/mind_trace_ai_service.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/observatory/data/observatory_ai_service.dart';
import 'package:mind_forensics/features/observatory/domain/symptom_entry.dart';
import 'package:mind_forensics/features/profile/domain/condition_type.dart';
import 'package:mind_forensics/features/profile/domain/diagnostic_status.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';

import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
  });

  const String apiKey = String.fromEnvironment('GEMINI_API_KEY');

  group('Live Gemini AI Verification Suite (Phase 2 & Phase 4)', () {
    final hasLiveKey = apiKey.isNotEmpty && apiKey != 'DEV_MOCK_GEMINI_KEY';

    test('1. DirectGeminiInvestigatorService testConnection succeeds with supported model', () async {
      if (!hasLiveKey) {
        // Skip in offline test environments
        return;
      }

      final service = DirectGeminiInvestigatorService(
        apiKey: apiKey,
        modelName: 'gemini-3.5-flash',
      );

      final sw = Stopwatch()..start();
      final result = await service.testConnection();
      sw.stop();

      // ignore: avoid_print
      print('[Live testConnection] Time: ${sw.elapsedMilliseconds}ms, Model: ${service.lastModelUsed}, Success: ${result.success}');

      expect(result.success, isTrue, reason: 'Failed with message: ${result.message}');
      final isSupported = DirectGeminiInvestigatorService.fallbackModels
          .any((m) => result.message.contains(m));
      expect(isSupported, isTrue,
          reason: 'Expected connection message to mention supported model, got: ${result.message}');
    });

    test('2. Live Multi-Turn Dialogue in AI Companion returns genuine Gemini response', () async {
      if (!hasLiveKey) return;

      final service = DirectGeminiInvestigatorService(
        apiKey: apiKey,
        modelName: 'gemini-3.5-flash',
      );

      final profile = PsychologicalProfileModel(
        preferredName: 'Tester',
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        conditions: const [
          UserConditionEntry(
            condition: ConditionType.generalizedAnxiety,
            status: DiagnosticStatus.selfIdentifiedExploring,
          ),
        ],
        updatedAt: DateTime.now(),
      );

      final testCase = CaseModel(
        id: 'live-case-01',
        caseNumber: 'CASE-01',
        title: 'Project Presentation',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentStage: CaseStage.incident,
        incidentDescription: 'I have a high stakes presentation tomorrow morning.',
        conversationMode: ConversationMode.exploreThought,
        statements: [
          Statement(
            id: 's1',
            text: 'I keep thinking I will freeze when everyone looks at me.',
            speaker: StatementSpeaker.user,
            timestamp: DateTime.now(),
          ),
        ],
      );

      final sw = Stopwatch()..start();
      final reply = await service.getNextQuestion(
        currentCase: testCase,
        conversationHistory: testCase.statements,
        profile: profile,
        conversationMode: ConversationMode.exploreThought,
        languageCode: 'en',
      );
      sw.stop();

      // ignore: avoid_print
      print('[Live AI Companion] Time: ${sw.elapsedMilliseconds}ms, Model: ${service.lastModelUsed}, Live: ${service.lastCallWasLive}');

      expect(reply.isNotEmpty, isTrue);
      expect(service.lastCallWasLive, isTrue, reason: 'Expected live response, got fallback');
      expect(service.lastErrorMessage, isNull);
    });

    test('3. Mind Assistant forensic hypothesis generation generates authentic hypotheses', () async {
      if (!hasLiveKey) return;

      final service = DirectGeminiInvestigatorService(
        apiKey: apiKey,
        modelName: 'gemini-3.5-flash',
      );

      final profile = PsychologicalProfileModel(
        preferredName: 'Tester',
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: DateTime.now(),
      );

      final testCase = CaseModel(
        id: 'assistant-live-01',
        caseNumber: 'CASE-02',
        title: 'Interview Feedback',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentStage: CaseStage.hypotheses,
        incidentDescription: 'I received an email stating they chose someone else.',
      );

      final sw = Stopwatch()..start();
      final hypotheses = await service.generateHypotheses(
        currentCase: testCase,
        languageCode: 'en',
        profile: profile,
      );
      sw.stop();

      // ignore: avoid_print
      print('[Live Mind Assistant] Time: ${sw.elapsedMilliseconds}ms, Model: ${service.lastModelUsed}, Live: ${service.lastCallWasLive}');

      expect(hypotheses.isNotEmpty, isTrue);
      expect(service.lastCallWasLive, isTrue, reason: 'Expected live response, got fallback');
      expect(service.lastErrorMessage, isNull);
    });

    test('4. Mind Trace daily reflection generates authentic live Gemini reflection', () async {
      if (!hasLiveKey) return;

      final traceService = MindTraceAiService(
        apiKey: apiKey,
        modelName: 'gemini-3.5-flash',
      );

      final profile = PsychologicalProfileModel(
        preferredName: 'Tester',
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: DateTime.now(),
      );

      final trace = MindTraceModel(
        id: 'trace-live-01',
        userId: 'user_live',
        date: DateTime.now(),
        overallMood: 'anxious',
        moodIntensity: 7,
        selectedEmotions: const ['Worried', 'Tense'],
        physicalTension: 6,
        sleepHours: 5.5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final sw = Stopwatch()..start();
      final reflection = await traceService.generateDailyReflection(
        currentTrace: trace,
        history: const [],
        profile: profile,
        languageCode: 'en',
      );
      sw.stop();

      // ignore: avoid_print
      print('[Live Mind Trace] Time: ${sw.elapsedMilliseconds}ms, Model: ${traceService.lastModelUsed}, Live: ${traceService.lastCallWasLive}');

      expect(reflection.isNotEmpty, isTrue);
      expect(traceService.lastCallWasLive, isTrue, reason: 'Trace error: ${traceService.lastError}');
      expect(traceService.lastError, isNull);
    });

    test('5. Inner Observatory symptom analysis generates structured JSON via supported model', () async {
      if (!hasLiveKey) return;

      final observatoryService = ObservatoryAiService(
        apiKey: apiKey,
        modelName: 'gemini-3.5-flash',
      );

      final profile = PsychologicalProfileModel(
        preferredName: 'Tester',
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: DateTime.now(),
      );

      final symptoms = [
        const SymptomEntry(
          id: 'sym_muscle_tension',
          domain: SymptomDomain.somatic,
          titleEn: 'Physical muscle tightness',
          titleFr: 'Tension musculaire',
          titleAr: 'شد عضلي',
          descriptionEn: 'Tightness in shoulders or neck',
          descriptionFr: 'Tension',
          descriptionAr: 'شد',
        ),
      ];

      final sw = Stopwatch()..start();
      final analysis = await observatoryService.analyzeSymptoms(
        selectedSymptoms: symptoms,
        intensity: 7,
        contextTrigger: 'Approaching deadline',
        somaticLocation: 'Shoulders and neck',
        userAdaptiveAnswer: 'Started after the team sync',
        baseline: null,
        profile: profile,
        languageCode: 'en',
      );
      sw.stop();

      // ignore: avoid_print
      print('[Live Inner Observatory] Time: ${sw.elapsedMilliseconds}ms, Model: ${observatoryService.lastModelUsed}, Live: ${observatoryService.lastCallWasLive}');

      expect(analysis.analysis.isNotEmpty, isTrue);
      expect(analysis.stabilizingStrategy.isNotEmpty, isTrue);
      expect(observatoryService.lastCallWasLive, isTrue, reason: 'Observatory error: ${observatoryService.lastError}');
      expect(observatoryService.lastError, isNull);
    });
  });
}
