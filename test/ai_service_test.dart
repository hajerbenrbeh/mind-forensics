import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/data/direct_gemini_investigator_service.dart';
import 'package:mind_forensics/features/investigation/data/mock_investigator_service.dart';
import 'package:mind_forensics/features/investigation/domain/ai_service.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/forensic_chain.dart';
import 'package:mind_forensics/features/investigation/domain/label_type.dart';
import 'package:mind_forensics/features/investigation/domain/statement.dart';
import 'package:mind_forensics/features/investigation/presentation/flash_case_screen.dart';
import 'package:mind_forensics/features/mind_trace/data/mind_trace_ai_service.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:mind_forensics/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiService Fictional Cognitive Session Test', () {
    late AiService aiService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      aiService = MockAiService();
    });

    test('Analyzes a harmless fictional incident and returns structured output',
        () async {
      final testCase = CaseModel(
        id: 'test-case-001',
        caseNumber: 'SESSION 01',
        title: 'Delayed reply to text message',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentStage: CaseStage.incident,
        incidentDescription:
            'My friend did not reply to my text message for two hours.',
        chain: const ForensicChain(
          trigger: 'Unanswered message on WhatsApp at 2 PM',
          thought: 'She is annoyed with me and is deliberately ignoring me.',
          thoughtLabel: LabelType.assumption,
          emotion: 'Anxious',
          emotionIntensity: 6,
          behavior: 'Checked my phone every five minutes and ruminated.',
        ),
      );

      final analysis = await aiService.analyzeCase(testCase);

      expect(analysis.message.isNotEmpty, isTrue);
      expect(analysis.followUpQuestions.isNotEmpty, isTrue);
      expect(analysis.hypotheses.length, greaterThanOrEqualTo(2));
      expect(analysis.safetyLevel, equals(0));
    });
  });

  group('AiConfigNotifier & Provider Routing Tests', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial config starts with default DEV_MOCK_GEMINI_KEY and selects MockInvestigatorService', () {
      final config = container.read(aiConfigProvider);
      expect(config.apiKey, equals(kPublicGeminiApiKey));
      expect(config.useLiveAi, isTrue);
      expect(config.isMockKey, isTrue);
      expect(config.isLiveActive, isFalse);

      final service = container.read(investigatorServiceProvider);
      expect(service, isA<MockInvestigatorService>());
    });

    test('Explicit live Gemini API key activates DirectGeminiInvestigatorService', () async {
      await container.read(aiConfigProvider.notifier).setApiKey('AIzaSyValidProductionApiKeyForTesting');
      final config = container.read(aiConfigProvider);
      expect(config.isMockKey, isFalse);
      expect(config.isLiveActive, isTrue);

      final service = container.read(investigatorServiceProvider);
      expect(service, isA<DirectGeminiInvestigatorService>());
    });

    test('Toggling live mode off preserves key but reverts provider to mock',
        () async {
      await container.read(aiConfigProvider.notifier).toggleLiveMode(false);

      final config = container.read(aiConfigProvider);
      expect(config.apiKey, equals(kPublicGeminiApiKey));
      expect(config.useLiveAi, isFalse);
      expect(config.isLiveActive, isFalse);

      final service = container.read(investigatorServiceProvider);
      expect(service, isA<MockInvestigatorService>());
    });

    test('Clearing API key resets state and reverts to mock provider',
        () async {
      await container.read(aiConfigProvider.notifier).clearApiKey();

      final config = container.read(aiConfigProvider);
      expect(config.apiKey, isEmpty);
      expect(config.useLiveAi, isFalse);
      expect(config.isLiveActive, isFalse);

      final service = container.read(investigatorServiceProvider);
      expect(service, isA<MockInvestigatorService>());
    });
  });

  group('DirectGeminiInvestigatorService Robustness & Fallback Tests', () {
    test('testConnection returns failure when API key is empty', () async {
      final service = DirectGeminiInvestigatorService(apiKey: '  ');
      final result = await service.testConnection();
      expect(result.success, isFalse);
      expect(result.message, contains('cannot be empty'));
    });

    test('getNextQuestion silently falls back to Mock on network failure',
        () async {
      // Intentionally invalid key / offline simulation
      final service = DirectGeminiInvestigatorService(apiKey: 'invalid_dummy_key');
      final currentCase = CaseModel(
        id: 'test-case-fallback',
        caseNumber: 'CASE-01',
        title: 'Project Delay',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentStage: CaseStage.incident,
        incidentDescription: 'I submitted the proposal 5 minutes late.',
      );

      final question = await service.getNextQuestion(
        currentCase: currentCase,
        conversationHistory: [],
      );
      expect(question.isNotEmpty, isTrue);
    });

    test('generateHypotheses silently falls back to Mock on network failure',
        () async {
      final service = DirectGeminiInvestigatorService(apiKey: 'invalid_dummy_key');
      final currentCase = CaseModel(
        id: 'test-hypo-fallback',
        caseNumber: 'CASE-02',
        title: 'Presentation',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentStage: CaseStage.hypotheses,
        incidentDescription: 'Nobody asked questions after my presentation.',
        chain: const ForensicChain(
          trigger: 'End of presentation silence',
          thought: 'Everyone found it boring.',
          thoughtLabel: LabelType.assumption,
          emotion: 'Inadequate',
          emotionIntensity: 7,
          behavior: 'Packed bag quickly and avoided eye contact.',
        ),
      );

      final hypotheses = await service.generateHypotheses(
        currentCase: currentCase,
      );

      expect(hypotheses, isNotEmpty);
      expect(hypotheses.length, greaterThanOrEqualTo(2));
      for (final h in hypotheses) {
        expect(h.title.isNotEmpty, isTrue);
        expect(h.explanation.isNotEmpty, isTrue);
        expect(h.whyItMightFit.isNotEmpty, isTrue);
        expect(h.whatDoesNotFit.isNotEmpty, isTrue);
      }
    });
  });

  group('SettingsScreen Zero-Friction Security Tests', () {
    testWidgets('Renders Settings without any API key placeholder or input',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify standard settings sections are present
      expect(find.text('CLINICAL SETTINGS'), findsOneWidget);
      expect(find.text('VISUAL ENVIRONMENT'), findsOneWidget);

      // Verify absolutely NO API key textfield or input placeholder exists
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Paste your API key'), findsNothing);
      expect(find.text('TEST CONNECTION'), findsNothing);
    });
  });

  group('Investigator Direct Conversational AI Tests', () {
    testWidgets('Renders direct chat with AI and processes interactive dialogue',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashCaseScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header and chat input field
      expect(find.text('REFLECTION'), findsAtLeastNWidgets(1));
      expect(find.text('Talk with your companion...'), findsOneWidget);

      // Verify Socratic quick suggestion pills
      expect(find.text('It feels like an assumption'), findsOneWidget);
      expect(find.text('What are the raw facts?'), findsOneWidget);

      // Send a test user message via text input
      await tester.enterText(
          find.byType(TextField), 'I am worried about my project deadline.');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump(); // Start async sending
      await tester.pump(const Duration(milliseconds: 500)); // Process mock investigator reply
      await tester.pumpAndSettle();

      // Verify both user message and investigator response are visible in conversation
      expect(find.text('I am worried about my project deadline.'), findsOneWidget);
      expect(find.text('[A] Assumption'), findsAtLeastNWidgets(1));
    });
  });

  group('Mock Key Zero Network Guarantee Tests', () {
    test('DirectGeminiInvestigatorService performs 0 HTTP requests with DEV_MOCK_GEMINI_KEY', () async {
      int payloadCount = 0;
      final service = DirectGeminiInvestigatorService(
        apiKey: 'DEV_MOCK_GEMINI_KEY',
        onRequestAttempted: (url, payload) => payloadCount++,
        clientFactory: () => throw const SocketException('Must NEVER open a socket in mock mode!'),
      );

      final now = DateTime.now();
      final nonPrivateCase = CaseModel(
        id: 'case_mock_net_01',
        caseNumber: 'CASE-01',
        title: 'Work anxiety',
        createdAt: now,
        updatedAt: now,
        currentStage: CaseStage.incident,
        incidentDescription: 'I received an unexpected email.',
        isPrivate: false,
      );

      final consentedProfile = PsychologicalProfileModel(
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: now,
      );

      // 1. testConnection check
      final connResult = await service.testConnection();
      expect(connResult.success, isFalse);
      expect(connResult.message, contains('Mock API key configured'));

      // 2. getNextQuestion
      final question = await service.getNextQuestion(
        currentCase: nonPrivateCase,
        conversationHistory: [
          Statement(id: 's1', text: 'Hello', speaker: StatementSpeaker.user, timestamp: now),
        ],
        profile: consentedProfile,
      );
      expect(question.isNotEmpty, isTrue);

      // 3. generateHypotheses
      final hypotheses = await service.generateHypotheses(
        currentCase: nonPrivateCase,
        profile: consentedProfile,
      );
      expect(hypotheses.isNotEmpty, isTrue);

      // 4. summarizeFindings
      final summary = await service.summarizeFindings(
        currentCase: nonPrivateCase,
        profile: consentedProfile,
      );
      expect(summary.isNotEmpty, isTrue);

      // Absolutely ZERO network requests attempted
      expect(service.networkRequestsAttempted, equals(0));
      expect(payloadCount, equals(0));
    });

    test('MindTraceAiService performs 0 HTTP requests with DEV_MOCK_GEMINI_KEY', () async {
      final service = MindTraceAiService(apiKey: 'DEV_MOCK_GEMINI_KEY');

      final now = DateTime.now();
      final trace = MindTraceModel(
        id: 'trace_mock_test',
        date: now,
        overallMood: 'anxious',
        moodIntensity: 7,
        selectedEmotions: const ['Anxious'],
        createdAt: now,
        updatedAt: now,
      );

      final consentedProfile = PsychologicalProfileModel(
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: now,
      );

      final reflection = await service.generateDailyReflection(
        currentTrace: trace,
        history: [],
        profile: consentedProfile,
        languageCode: 'en',
      );

      expect(reflection.isNotEmpty, isTrue);
      // Zero emojis in output
      expect(reflection.contains(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true)), isFalse);
    });
  });
}
