import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/data/direct_gemini_investigator_service.dart';
import 'package:mind_forensics/features/investigation/data/direct_groq_investigator_service.dart';
import 'package:mind_forensics/features/investigation/data/mock_investigator_service.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/conversation_mode.dart';
import 'package:mind_forensics/features/investigation/domain/forensic_chain.dart';
import 'package:mind_forensics/features/investigation/domain/label_type.dart';
import 'package:mind_forensics/features/investigation/presentation/widgets/ai_engine_config_sheet.dart';
import 'package:mind_forensics/features/mind_trace/data/mind_trace_ai_service.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/observatory/data/observatory_ai_service.dart';
import 'package:mind_forensics/features/observatory/domain/symptom_entry.dart';
import 'package:mind_forensics/features/profile/domain/condition_type.dart';
import 'package:mind_forensics/features/profile/domain/diagnostic_status.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  CaseModel buildSampleCase({bool isPrivate = false}) {
    return CaseModel(
      id: 'case-isolation-test',
      caseNumber: 'ISO-01',
      title: 'Provider Isolation Verification',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      currentStage: CaseStage.incident,
      incidentDescription: 'I received an urgent message from management and felt my throat tighten.',
      isPrivate: isPrivate,
      chain: const ForensicChain(
        trigger: 'Urgent message notification',
        thought: 'I will definitely be reprimanded or terminated.',
        thoughtLabel: LabelType.assumption,
        emotion: 'Dread',
        emotionIntensity: 8,
        behavior: 'Froze, checked phone repeatedly, paced room.',
      ),
    );
  }

  PsychologicalProfileModel buildConsentedProfile({
    bool shareWithAi = true,
    bool allowPersonalization = true,
  }) {
    return PsychologicalProfileModel(
      updatedAt: DateTime.now(),
      consentVersion: 1,
      shareWithAiCompanion: shareWithAi,
      allowAiPersonalization: allowPersonalization,
      preferredName: 'Nadia',
      conditions: const [
        UserConditionEntry(
          condition: ConditionType.generalizedAnxiety,
          status: DiagnosticStatus.selfIdentifiedExploring,
        ),
      ],
      notesForAiCompanion: 'Prefers somatic grounding techniques',
    );
  }

  group('Stage 6.1A.3 — External AI Provider Isolation & Zero Remote Transmission', () {
    const liveGeminiKey = 'AIzaSyLiveProductionGeminiKey_12345';
    const liveGroqKey = 'gsk_liveProductionGroqKey_67890';

    test('1. DirectGeminiInvestigatorService testConnection returns disabled and makes zero network requests', () async {
      var clientFactoryCalls = 0;
      final service = DirectGeminiInvestigatorService(
        apiKey: liveGeminiKey,
        clientFactory: () {
          clientFactoryCalls++;
          throw const SocketException('Should never be called');
        },
        onRequestAttempted: (_, _) => fail('Gemini request attempted during testConnection'),
      );

      final result = await service.testConnection();

      expect(result.success, isFalse);
      expect(result.message, contains('External AI is currently unavailable'));
      expect(result.message, contains('Gemini is not supported'));
      expect(result.message, contains('local reflection and support engine is active'));
      expect(service.networkRequestsAttempted, equals(0));
      expect(clientFactoryCalls, equals(0));
    });

    test('2. DirectGeminiInvestigatorService dialogue, hypotheses, cross-exam, and summary make zero requests', () async {
      var clientFactoryCalls = 0;
      final service = DirectGeminiInvestigatorService(
        apiKey: liveGeminiKey,
        clientFactory: () {
          clientFactoryCalls++;
          throw const SocketException('Should never be called');
        },
        onRequestAttempted: (_, _) => fail('Gemini request attempted during clinical operation'),
      );

      final testCase = buildSampleCase();
      final profile = buildConsentedProfile();

      // Dialogue inquiry
      final nextQ = await service.getNextQuestion(
        currentCase: testCase,
        conversationHistory: const [],
        profile: profile,
        conversationMode: ConversationMode.exploreThought,
      );
      expect(nextQ.isNotEmpty, isTrue);
      expect(service.lastCallWasLive, isFalse);
      expect(service.networkRequestsAttempted, equals(0));
      expect(clientFactoryCalls, equals(0));

      // Hypotheses generation
      final hypotheses = await service.generateHypotheses(
        currentCase: testCase,
        profile: profile,
      );
      expect(hypotheses.isNotEmpty, isTrue);
      expect(hypotheses.length, greaterThanOrEqualTo(2));
      expect(service.networkRequestsAttempted, equals(0));
      expect(clientFactoryCalls, equals(0));

      // Cross-examination questions
      final questions = await service.generateCrossExaminationQuestions(
        currentCase: testCase,
        hypothesis: hypotheses.first,
        profile: profile,
      );
      expect(questions.isNotEmpty, isTrue);
      expect(service.networkRequestsAttempted, equals(0));
      expect(clientFactoryCalls, equals(0));

      // Summary synthesis
      final summary = await service.summarizeFindings(
        currentCase: testCase,
        profile: profile,
      );
      expect(summary.isNotEmpty, isTrue);
      expect(service.networkRequestsAttempted, equals(0));
      expect(clientFactoryCalls, equals(0));
    });

    test('3. DirectGroqInvestigatorService testConnection returns disabled and makes zero network requests', () async {
      var clientFactoryCalls = 0;
      final service = DirectGroqInvestigatorService(
        apiKey: liveGroqKey,
        proxyUrl: 'https://proxy.custom.internal/v1',
        clientFactory: () {
          clientFactoryCalls++;
          throw const SocketException('Should never be called');
        },
        onRequestAttempted: (_, _) => fail('Groq request attempted during testConnection'),
      );

      final result = await service.testConnection();

      expect(result.success, isFalse);
      expect(result.message, contains('External AI is currently unavailable'));
      expect(result.message, contains('Groq is not supported'));
      expect(result.message, contains('local reflection and support engine is active'));
      expect(service.networkRequestsAttempted, equals(0));
      expect(clientFactoryCalls, equals(0));
    });

    test('4. DirectGroqInvestigatorService dialogue, hypotheses, cross-exam, and summary make zero requests', () async {
      var clientFactoryCalls = 0;
      final service = DirectGroqInvestigatorService(
        apiKey: liveGroqKey,
        clientFactory: () {
          clientFactoryCalls++;
          throw const SocketException('Should never be called');
        },
        onRequestAttempted: (_, _) => fail('Groq request attempted during clinical operation'),
      );

      final testCase = buildSampleCase();
      final profile = buildConsentedProfile();

      // Dialogue inquiry
      final nextQ = await service.getNextQuestion(
        currentCase: testCase,
        conversationHistory: const [],
        profile: profile,
      );
      expect(nextQ.isNotEmpty, isTrue);
      expect(service.lastCallWasLive, isFalse);
      expect(service.networkRequestsAttempted, equals(0));
      expect(clientFactoryCalls, equals(0));

      // Hypotheses generation
      final hypotheses = await service.generateHypotheses(
        currentCase: testCase,
        profile: profile,
      );
      expect(hypotheses.isNotEmpty, isTrue);
      expect(service.networkRequestsAttempted, equals(0));
      expect(clientFactoryCalls, equals(0));

      // Cross-examination questions
      final questions = await service.generateCrossExaminationQuestions(
        currentCase: testCase,
        hypothesis: hypotheses.first,
        profile: profile,
      );
      expect(questions.isNotEmpty, isTrue);
      expect(service.networkRequestsAttempted, equals(0));
      expect(clientFactoryCalls, equals(0));

      // Summary synthesis
      final summary = await service.summarizeFindings(
        currentCase: testCase,
        profile: profile,
      );
      expect(summary.isNotEmpty, isTrue);
      expect(service.networkRequestsAttempted, equals(0));
      expect(clientFactoryCalls, equals(0));
    });

    test('5. MindTraceAiService executes local reflection with zero network calls regardless of API key or consent', () async {
      final service = MindTraceAiService(
        apiKey: liveGeminiKey,
        modelName: 'gemini-3.5-flash',
      );

      final trace = MindTraceModel(
        id: 'trace-iso-01',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        overallMood: 'anxious',
        moodIntensity: 8,
        selectedEmotions: const ['Tense', 'Worried'],
        physicalTension: 7,
      );

      final reflection = await service.generateDailyReflection(
        currentTrace: trace,
        history: const [],
        profile: buildConsentedProfile(),
        languageCode: 'en',
      );

      expect(reflection.isNotEmpty, isTrue);
      expect(service.lastCallWasLive, isFalse);
      expect(service.lastError, isNull);
    });

    test('6. ObservatoryAiService executes local Socratic analysis with zero network calls regardless of API key or consent', () async {
      final service = ObservatoryAiService(
        apiKey: liveGeminiKey,
        modelName: 'gemini-3.5-flash',
      );

      final symptoms = [
        const SymptomEntry(
          id: 'sym-anx',
          domain: SymptomDomain.anxiety,
          titleEn: 'Racing thoughts',
          titleFr: 'Pensées agitées',
          titleAr: 'أفكار متسارعة',
          descriptionEn: 'Mind jumping rapidly',
          descriptionFr: 'Esprit agité',
          descriptionAr: 'تسارع الذهن',
        ),
      ];

      final analysis = await service.analyzeSymptoms(
        selectedSymptoms: symptoms,
        intensity: 8,
        contextTrigger: 'Upcoming deadline',
        somaticLocation: 'Shoulders',
        userAdaptiveAnswer: 'Took a short pause',
        baseline: null,
        profile: buildConsentedProfile(),
        languageCode: 'en',
      );

      expect(analysis.analysis.isNotEmpty, isTrue);
      expect(analysis.stabilizingStrategy.isNotEmpty, isTrue);
      expect(service.lastCallWasLive, isFalse);
      expect(service.lastError, isNull);
    });

    test('7. No provider cross-fallback: Gemini failure never calls Groq, Groq failure never calls Gemini', () async {
      final testCase = buildSampleCase();
      final profile = buildConsentedProfile();

      final gemini = DirectGeminiInvestigatorService(apiKey: liveGeminiKey);
      final geminiReply = await gemini.getNextQuestion(
        currentCase: testCase,
        conversationHistory: const [],
        profile: profile,
      );
      expect(geminiReply.isNotEmpty, isTrue);
      expect(gemini.networkRequestsAttempted, equals(0));

      final groq = DirectGroqInvestigatorService(apiKey: liveGroqKey);
      final groqReply = await groq.getNextQuestion(
        currentCase: testCase,
        conversationHistory: const [],
        profile: profile,
      );
      expect(groqReply.isNotEmpty, isTrue);
      expect(groq.networkRequestsAttempted, equals(0));
    });

    test('8. Full consent quadrant produces strictly local behavior across all 4 pathways until Grok implementation', () async {
      final testCase = buildSampleCase();
      final trace = MindTraceModel(
        id: 'trace-matrix',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        overallMood: 'calm',
        moodIntensity: 5,
      );
      final symptoms = [
        const SymptomEntry(
          id: 'sym-mood',
          domain: SymptomDomain.mood,
          titleEn: 'Low energy',
          titleFr: 'Énergie basse',
          titleAr: 'طاقة منخفضة',
          descriptionEn: 'Feeling depleted',
          descriptionFr: 'Épuisé',
          descriptionAr: 'شعور بالإرهاق',
        ),
      ];

      final quadrants = [
        (sharing: false, pers: false),
        (sharing: false, pers: true),
        (sharing: true, pers: false),
        (sharing: true, pers: true),
      ];

      for (final q in quadrants) {
        final profile = buildConsentedProfile(
          shareWithAi: q.sharing,
          allowPersonalization: q.pers,
        );

        // 1. Gemini AI Companion
        final gemini = DirectGeminiInvestigatorService(apiKey: liveGeminiKey);
        final gAns = await gemini.getNextQuestion(
          currentCase: testCase,
          conversationHistory: const [],
          profile: profile,
        );
        expect(gAns.isNotEmpty, isTrue);
        expect(gemini.networkRequestsAttempted, equals(0));
        expect(gemini.lastCallWasLive, isFalse);

        // 2. Groq AI Companion
        final groq = DirectGroqInvestigatorService(apiKey: liveGroqKey);
        final grAns = await groq.getNextQuestion(
          currentCase: testCase,
          conversationHistory: const [],
          profile: profile,
        );
        expect(grAns.isNotEmpty, isTrue);
        expect(groq.networkRequestsAttempted, equals(0));
        expect(groq.lastCallWasLive, isFalse);

        // 3. Mind Trace AI
        final traceService = MindTraceAiService(apiKey: liveGeminiKey);
        final trAns = await traceService.generateDailyReflection(
          currentTrace: trace,
          history: const [],
          profile: profile,
          languageCode: 'en',
        );
        expect(trAns.isNotEmpty, isTrue);
        expect(traceService.lastCallWasLive, isFalse);

        // 4. Observatory AI
        final obsService = ObservatoryAiService(apiKey: liveGeminiKey);
        final obsAns = await obsService.analyzeSymptoms(
          selectedSymptoms: symptoms,
          intensity: 5,
          contextTrigger: 'Normal day',
          somaticLocation: null,
          userAdaptiveAnswer: null,
          baseline: null,
          profile: profile,
          languageCode: 'en',
        );
        expect(obsAns.analysis.isNotEmpty, isTrue);
        expect(obsService.lastCallWasLive, isFalse);
      }
    });

    test('9. Revoking sharing prevents external transmission and persists across serialization', () async {
      var profile = buildConsentedProfile(shareWithAi: true, allowPersonalization: true);

      // User revokes sharing
      profile = profile.copyWith(
        shareWithAiCompanion: false,
        updatedAt: DateTime.now(),
      );

      final json = profile.toJson();
      final restored = PsychologicalProfileModel.fromJson(json);

      expect(restored.shareWithAiCompanion, isFalse);
      expect(restored.allowAiPersonalization, isTrue);

      final gemini = DirectGeminiInvestigatorService(apiKey: liveGeminiKey);
      await gemini.getNextQuestion(
        currentCase: buildSampleCase(),
        conversationHistory: const [],
        profile: restored,
      );
      expect(gemini.networkRequestsAttempted, equals(0));
    });
  });

  group('Stage 6.1A.4 — AI Provider UI Truthfulness & Final Isolation Audit', () {
    test('1. Gemini and Groq cannot be selected as active providers (Active engine remains local)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(aiConfigProvider.notifier);
      expect(container.read(aiConfigProvider).provider, equals(AiEngineProvider.local));

      // Attempt to set Groq
      await notifier.setProvider(AiEngineProvider.groq);
      expect(container.read(aiConfigProvider).provider, equals(AiEngineProvider.local));

      // Attempt to set Gemini
      await notifier.setProvider(AiEngineProvider.gemini);
      expect(container.read(aiConfigProvider).provider, equals(AiEngineProvider.local));

      // Attempt to set Grok (planned, not implemented yet)
      await notifier.setProvider(AiEngineProvider.grok);
      expect(container.read(aiConfigProvider).provider, equals(AiEngineProvider.local));
    });

    test('2. isLiveActive is strictly false and investigatorServiceProvider always resolves to MockInvestigatorService', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(aiConfigProvider.notifier);

      // Default state
      expect(container.read(aiConfigProvider).isLiveActive, isFalse);
      expect(container.read(aiConfigProvider).isLocalAiAvailable, isTrue);
      expect(container.read(aiConfigProvider).isExternalAiAvailable, isFalse);
      expect(container.read(aiConfigProvider).isGrokPlanned, isTrue);
      expect(container.read(investigatorServiceProvider), isA<MockInvestigatorService>());

      // With Groq key saved
      await notifier.setApiKey('gsk_test_groq_key_999', provider: AiEngineProvider.groq);
      expect(container.read(aiConfigProvider).isLiveActive, isFalse);
      expect(container.read(investigatorServiceProvider), isA<MockInvestigatorService>());

      // With Gemini key saved
      await notifier.setApiKey('AIzaSyTestGeminiKey_888', provider: AiEngineProvider.gemini);
      expect(container.read(aiConfigProvider).isLiveActive, isFalse);
      expect(container.read(investigatorServiceProvider), isA<MockInvestigatorService>());
    });

    test('3. Direct provider testConnection returns truthful offline status without making requests', () async {
      final gemini = DirectGeminiInvestigatorService(apiKey: 'AIzaSySampleKey_123');
      final gResult = await gemini.testConnection();
      expect(gResult.success, isFalse);
      expect(gResult.message, contains('External AI is currently unavailable'));
      expect(gResult.message, contains('Gemini is not supported'));
      expect(gResult.message, contains('local reflection and support engine is active'));
      expect(gemini.networkRequestsAttempted, equals(0));

      final groq = DirectGroqInvestigatorService(apiKey: 'gsk_sampleKey_456');
      final grResult = await groq.testConnection();
      expect(grResult.success, isFalse);
      expect(grResult.message, contains('External AI is currently unavailable'));
      expect(grResult.message, contains('Groq is not supported'));
      expect(grResult.message, contains('local reflection and support engine is active'));
      expect(groq.networkRequestsAttempted, equals(0));
    });

    testWidgets('4. AiEngineConfigSheet displays truthful 4-part availability matrix and omits obsolete controls', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: AiEngineConfigSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Truthful 4-part matrix
      expect(find.text('Local Reflection & Support Engine'), findsOneWidget);
      expect(find.text('AVAILABLE & ACTIVE'), findsOneWidget);

      expect(find.text('External Cloud AI'), findsOneWidget);
      expect(find.text('UNAVAILABLE'), findsOneWidget);

      expect(find.text('xAI Grok'), findsOneWidget);
      expect(find.text('PLANNED'), findsOneWidget);

      expect(find.text('Google Gemini & Groq'), findsOneWidget);
      expect(find.text('NOT SUPPORTED'), findsOneWidget);

      // Obsolete selection and activation controls are gone
      expect(find.text('Groq (Free Llama)'), findsNothing);
      expect(find.text('Google Gemini'), findsNothing);
      expect(find.text('SAVE & ACTIVATE'), findsNothing);
      expect(find.text('LIVE GROQ'), findsNothing);
      expect(find.text('LIVE GEMINI'), findsNothing);
    });

    testWidgets('5. AiEngineConfigSheet connection test reports truthful local processing status with 0 requests', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: AiEngineConfigSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TEST CONNECTION'), findsOneWidget);
      await tester.tap(find.text('TEST CONNECTION'));
      await tester.pumpAndSettle();

      expect(
        find.text('External AI is currently unavailable. Gemini and Groq are not supported; local reflection and support engine is active.'),
        findsOneWidget,
      );
    });

    test('6. Purging historical keys clears secure storage while keeping local AI active', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(aiConfigProvider.notifier);
      await notifier.setApiKey('AIzaSyGeminiKeyToPurge', provider: AiEngineProvider.gemini);
      await notifier.setApiKey('gsk_GroqKeyToPurge', provider: AiEngineProvider.groq);

      expect(container.read(aiConfigProvider).apiKey, equals('AIzaSyGeminiKeyToPurge'));
      expect(container.read(aiConfigProvider).groqApiKey, equals('gsk_GroqKeyToPurge'));

      await notifier.clearAllHistoricalKeys();

      expect(container.read(aiConfigProvider).apiKey, isEmpty);
      expect(container.read(aiConfigProvider).groqApiKey, isEmpty);
      expect(container.read(aiConfigProvider).isLiveActive, isFalse);
      expect(container.read(aiConfigProvider).provider, equals(AiEngineProvider.local));
      expect(container.read(investigatorServiceProvider), isA<MockInvestigatorService>());
    });

    testWidgets('7. Purge historical keys confirmation dialog - Cancel leaves stored keys untouched', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(aiConfigProvider.notifier);
      await notifier.setApiKey('AIzaSyKeepThisKey_111', provider: AiEngineProvider.gemini);
      await notifier.setApiKey('gsk_KeepThisKey_222', provider: AiEngineProvider.groq);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: AiEngineConfigSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap purge button
      final purgeBtn = find.text('Purge Stored Historical Keys');
      expect(purgeBtn, findsOneWidget);
      await tester.ensureVisible(purgeBtn);
      await tester.tap(purgeBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog is shown
      expect(find.text('Purge Stored API Keys?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm Purge'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog dismissed, keys untouched!
      expect(container.read(aiConfigProvider).apiKey, equals('AIzaSyKeepThisKey_111'));
      expect(container.read(aiConfigProvider).groqApiKey, equals('gsk_KeepThisKey_222'));
    });

    testWidgets('8. Purge historical keys confirmation dialog - Confirm clears only legacy keys, preserves master key', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final keyManager = container.read(secureKeyManagerProvider);
      final masterKeyBefore = await keyManager.getMasterKey();
      final masterExportBefore = await keyManager.exportMasterRecoveryKey();

      final notifier = container.read(aiConfigProvider.notifier);
      await notifier.setApiKey('AIzaSyPurgeMe_333', provider: AiEngineProvider.gemini);
      await notifier.setApiKey('gsk_PurgeMe_444', provider: AiEngineProvider.groq);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: AiEngineConfigSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap purge button
      final purgeBtn = find.text('Purge Stored Historical Keys');
      await tester.ensureVisible(purgeBtn);
      await tester.tap(purgeBtn);
      await tester.pumpAndSettle();

      // Dialog is shown
      expect(find.text('Purge Stored API Keys?'), findsOneWidget);

      // Tap Confirm Purge
      await tester.tap(find.text('Confirm Purge'));
      await tester.pumpAndSettle();

      // Legacy keys cleared
      expect(container.read(aiConfigProvider).apiKey, isEmpty);
      expect(container.read(aiConfigProvider).groqApiKey, isEmpty);

      // Master encryption key and recovery material remain 100% intact and untouched
      final masterKeyAfter = await keyManager.getMasterKey();
      final masterExportAfter = await keyManager.exportMasterRecoveryKey();
      expect(masterKeyAfter, equals(masterKeyBefore));
      expect(masterExportAfter, equals(masterExportBefore));
      expect(container.read(aiConfigProvider).isLiveActive, isFalse);
      expect(container.read(aiConfigProvider).provider, equals(AiEngineProvider.local));
    });

    testWidgets('9. Purge confirmation dialog renders correctly in Arabic RTL locale', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          appStringsProvider.overrideWith((ref) => const AppStrings('ar')),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(aiConfigProvider.notifier);
      await notifier.setApiKey('AIzaSyArabicKey', provider: AiEngineProvider.gemini);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('ar'),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(body: AiEngineConfigSheet()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In Arabic RTL
      final purgeBtn = find.text('مسح المفاتيح التاريخية المخزنة');
      expect(purgeBtn, findsOneWidget);
      await tester.ensureVisible(purgeBtn);
      await tester.tap(purgeBtn);
      await tester.pumpAndSettle();

      // Localized Arabic dialog
      expect(find.text('مسح مفاتيح API المخزنة؟'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
      expect(find.text('تأكيد المسح'), findsOneWidget);

      // Verify Directionality is RTL in dialog
      final textDirection = Directionality.of(tester.element(find.text('مسح مفاتيح API المخزنة؟')));
      expect(textDirection, equals(TextDirection.rtl));
    });
  });
}
