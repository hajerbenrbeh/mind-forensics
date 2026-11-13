import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/features/investigation/data/local_case_repository.dart';
import 'package:mind_forensics/features/investigation/domain/ai_companion_context_selector.dart';
import 'package:mind_forensics/features/investigation/domain/ai_companion_system_prompt.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/conversation_mode.dart';
import 'package:mind_forensics/features/investigation/presentation/ai_companion_hub_view.dart';
import 'package:mind_forensics/features/investigation/presentation/flash_case_screen.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/profile/domain/condition_type.dart';
import 'package:mind_forensics/features/profile/domain/diagnostic_status.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Companion System Prompt & Clinical Intelligence Tests', () {
    test('System prompt version is 1.2.0 and contains core identity text', () {
      expect(AiCompanionSystemPrompt.promptVersion, '1.2.0');
      expect(
        AiCompanionSystemPrompt.coreIdentityPrompt,
        contains('You are the AI Companion inside Mind Forensics.'),
      );
      expect(
        AiCompanionSystemPrompt.coreIdentityPrompt,
        contains('You are an AI system, not a licensed therapist, psychiatrist, or medical professional.'),
      );
      expect(
        AiCompanionSystemPrompt.coreIdentityPrompt,
        contains('Your purpose is to help users explore and understand their experiences with clarity, curiosity, and respect.'),
      );
    });

    test('Reasoning guidelines enforce differentiation and forbid emojis', () {
      expect(
        AiCompanionSystemPrompt.reasoningGuidelines,
        contains('Thoughts (mental events, automatic phrases).'),
      );
      expect(
        AiCompanionSystemPrompt.reasoningGuidelines,
        contains('Avoid reassurance loops:'),
      );
      expect(
        AiCompanionSystemPrompt.reasoningGuidelines,
        contains('Strictly NO emojis anywhere in your response.'),
      );
    });

    test('Condition-aware safety guidelines are dynamically assembled', () {
      final ocdGuidance = AiCompanionSystemPrompt.buildConditionGuidelines([ConditionType.ocd]);
      expect(ocdGuidance, contains('OCD & INTRUSIVE THOUGHTS'));
      expect(ocdGuidance, contains('Strictly avoid offering reassurance loops'));

      final bipolarGuidance = AiCompanionSystemPrompt.buildConditionGuidelines([ConditionType.bipolarI]);
      expect(bipolarGuidance, contains('BIPOLAR SPECTRUM'));

      final eatingGuidance = AiCompanionSystemPrompt.buildConditionGuidelines([ConditionType.eatingDisorders]);
      expect(eatingGuidance, contains('Strictly never comment on weight, calorie intake'));
    });

    test('buildFullPrompt combines mode, language, condition and context safely', () {
      final prompt = AiCompanionSystemPrompt.buildFullPrompt(
        mode: ConversationMode.exploreThought,
        languageCode: 'en',
        conditions: [ConditionType.generalizedAnxiety],
        contextualUserPrompt: 'User preferred name: Alex',
      );

      expect(prompt, contains('CURRENT CONVERSATION MODE: EXPLORE A THOUGHT'));
      expect(prompt, contains('ANXIETY SPECTRUM'));
      expect(prompt, contains('User preferred name: Alex'));
      expect(prompt, contains('Respond in warm, clear, attentive, and psychologically informed English'));
    });
  });

  group('AI Companion Personalization & Context Selection Tests', () {
    test('Strictly omits profile data when shareWithAiCompanion is false', () {
      final profileWithoutConsent = PsychologicalProfileModel(
        preferredName: 'SecretName',
        shareWithAiCompanion: false,
        updatedAt: DateTime(2026, 1, 1),
        conditions: const [
          UserConditionEntry(
              condition: ConditionType.depression,
              status: DiagnosticStatus.professionallyDiagnosed),
        ],
      );

      final context = AiCompanionContextSelector.buildContext(
        profile: profileWithoutConsent,
        latestTrace: null,
        journey: null,
      );

      expect(context, isNot(contains('SecretName')));
      expect(context, isNot(contains('Depression')));
      expect(context, isNot(contains('USER PROFILE CONTEXT')));
    });

    test('Injects profile, trace and journey context when consent is enabled', () {
      final profileWithConsent = PsychologicalProfileModel(
        preferredName: 'Leila',
        shareWithAiCompanion: true,
        updatedAt: DateTime(2026, 1, 1),
        conditions: const [
          UserConditionEntry(
              condition: ConditionType.generalizedAnxiety,
              status: DiagnosticStatus.selfIdentifiedExploring),
        ],
        selectedSymptoms: const ['Racing heart', 'Restlessness'],
        selectedGoals: const ['Understand emotional triggers'],
        personalContext: 'Looking for a calm, non-judgmental space.',
        communicationTone: 'Warm & reflective',
      );

      final trace = MindTraceModel(
        id: 'trace-1',
        date: DateTime.now(),
        overallMood: 'reflective',
        moodIntensity: 7,
        selectedEmotions: const ['Hopeful', 'Anxious'],
        energyLevel: 6,
        journalText: 'A thoughtful morning.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final context = AiCompanionContextSelector.buildContext(
        profile: profileWithConsent,
        latestTrace: trace,
        journey: null,
      );

      expect(context, contains('Leila'));
      expect(context, contains('Generalized Anxiety'));
      expect(context, contains('Racing heart'));
      expect(context, contains('Understand emotional triggers'));
      expect(context, contains('Looking for a calm, non-judgmental space.'));
      expect(context, contains('Warm & reflective'));
      expect(context, contains('DAILY MIND TRACE (Recent Check-in):'));
      expect(context, contains('reflective (Intensity: 7/10)'));
    });

    test('forceDisablePersonalization completely clears all injected context', () {
      final profile = PsychologicalProfileModel(
        preferredName: 'Nadia',
        shareWithAiCompanion: true,
        updatedAt: DateTime(2026, 1, 1),
      );

      final context = AiCompanionContextSelector.buildContext(
        profile: profile,
        latestTrace: null,
        journey: null,
        forceDisablePersonalization: true,
      );

      expect(context, isEmpty);
    });
  });

  group('ConversationMode & Starters Tests', () {
    test('All 6 conversation modes have valid metadata and starters', () {
      expect(ConversationMode.values.length, 6);

      for (final mode in ConversationMode.values) {
        expect(mode.displayName, isNotEmpty);
        expect(mode.openingQuestion, isNotEmpty);
        expect(mode.description, isNotEmpty);
        expect(mode.suggestedStarters, isNotEmpty);
        expect(mode.suggestedStarters.length, greaterThanOrEqualTo(4));
        expect(mode.localizedArabicName, isNotEmpty);
        expect(mode.localizedFrenchName, isNotEmpty);
      }
    });

    test('Specific opening questions match specification', () {
      expect(
        ConversationMode.exploreThought.openingQuestion,
        'Is there a thought that has been occupying your mind lately?',
      );
      expect(
        ConversationMode.understandEmotion.openingQuestion,
        'What are you feeling right now, and what does it feel like in your body?',
      );
      expect(
        ConversationMode.grounding.openingQuestion,
        'Let us take a quiet pause together. Would you like to try a simple, gentle grounding exercise?',
      );
    });
  });

  group('LocalCaseRepository & Multi-User Isolation Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Saves, renames, retrieves, and isolates cases by userId', () async {
      final userRepoA = LocalCaseRepository(userId: 'user_alpha');
      final userRepoB = LocalCaseRepository(userId: 'user_beta');

      final now = DateTime.now();
      final caseA = CaseModel(
        id: 'case-a-1',
        userId: 'user_alpha',
        caseNumber: 'SESSION 01',
        title: 'Alpha Session',
        conversationMode: ConversationMode.exploreThought,
        createdAt: now,
        updatedAt: now,
        currentStage: CaseStage.incident,
        incidentDescription: 'Alpha thoughts',
      );

      await userRepoA.saveCase(caseA);

      // Verify User A has 1 case and User B has 0 cases (isolation)
      final allA = await userRepoA.getAllCases();
      final allB = await userRepoB.getAllCases();
      expect(allA.length, 1);
      expect(allA.first.title, 'Alpha Session');
      expect(allB.isEmpty, isTrue);

      // Test rename
      await userRepoA.renameCase('case-a-1', 'Renamed Alpha Session');
      final updated = await userRepoA.getCaseById('case-a-1');
      expect(updated?.title, 'Renamed Alpha Session');

      // Test delete
      await userRepoA.deleteCase('case-a-1');
      final afterDelete = await userRepoA.getAllCases();
      expect(afterDelete.isEmpty, isTrue);
    });
  });

  group('AI Companion UI & Widgets Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('AiCompanionHubView renders identity header, all 6 modes, and starters',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AiCompanionHubView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header and introduction
      expect(find.text('AI COMPANION'), findsOneWidget);
      expect(find.text('“An intelligent space to explore what is happening within you.”'), findsOneWidget);

      // Verify 6 modes are listed
      expect(find.text('Explore a Thought'), findsOneWidget);
      expect(find.text('Understand an Emotion'), findsOneWidget);
      expect(find.text('Psychological Analysis'), findsOneWidget);
      expect(find.text('Guided Reflection'), findsOneWidget);
      expect(find.text('Just Talk'), findsOneWidget);
      expect(find.text('Grounding'), findsOneWidget);

      // Verify Start New Conversation CTA
      expect(find.text('NEW CONVERSATION'), findsOneWidget);

      // Verify Suggested Starters section
      expect(find.text('SUGGESTED STARTERS'), findsOneWidget);
    });

    testWidgets('FlashCaseScreen supports switching between Hub and Live Dialogue',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashCaseScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially active conversation dialogue is open
      expect(find.text('AI GUIDE'), findsAtLeastNWidgets(1));
      expect(find.text('Talk with your companion...'), findsOneWidget);

      // Tap grid icon in AppBar to toggle Hub view
      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pumpAndSettle();

      // Verify Hub view is now presented
      expect(find.text('AI HUB'), findsOneWidget);
      expect(find.text('6 MODES'), findsOneWidget);
      expect(find.text('Explore a Thought'), findsAtLeastNWidgets(1));

      // Tap back button in AppBar to return to chat
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // Verify returned to dialogue
      expect(find.text('Talk with your companion...'), findsOneWidget);
    });
  });
}
