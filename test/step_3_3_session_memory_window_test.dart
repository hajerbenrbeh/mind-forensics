import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/data/direct_gemini_investigator_service.dart';
import 'package:mind_forensics/features/investigation/data/mock_investigator_service.dart';
import 'package:mind_forensics/features/investigation/domain/ai_companion_system_prompt.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/conversational_pacing_enforcer.dart';
import 'package:mind_forensics/features/investigation/domain/conversation_mode.dart';
import 'package:mind_forensics/features/investigation/domain/hypothesis.dart';
import 'package:mind_forensics/features/investigation/domain/label_type.dart';
import 'package:mind_forensics/features/investigation/domain/session_dialogue_compressor.dart';
import 'package:mind_forensics/features/investigation/domain/session_memory_window.dart';
import 'package:mind_forensics/features/investigation/domain/statement.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Step 3.3: Boundary Algorithm & Reciprocal Turn-Pair Coherence', () {
    test('1. Empty statements returns boundary 0 and empty window', () {
      final window = SessionMemoryWindowManager.partition(const []);
      expect(window.olderStatements, isEmpty);
      expect(window.verbatimStatements, isEmpty);
      expect(window.hasOlderContext, isFalse);
    });

    test('2. Statements <= nominal size (6) are all in verbatim window', () {
      final statements = List.generate(
        5,
        (i) => Statement(
          id: 's$i',
          text: 'Message $i',
          speaker: i.isEven ? StatementSpeaker.user : StatementSpeaker.investigator,
          timestamp: DateTime.now().add(Duration(minutes: i)),
        ),
      );

      final window = SessionMemoryWindowManager.partition(statements, nominalSize: 6);
      expect(window.olderStatements, isEmpty);
      expect(window.verbatimStatements.length, equals(5));
      expect(window.hasOlderContext, isFalse);
    });

    test('3. Boundary preserves reciprocal turn pair when cut lands on User response to Investigator', () {
      // 8 alternating statements: U0, I1, U2, I3, U4, I5, U6, I7
      // Nominal cut: 8 - 6 = index 2 (U2).
      // U2 was answering I1.
      // Invariant moves boundary back to index 1 (I1) so the exchange (I1 -> U2) is intact!
      final statements = List.generate(
        8,
        (i) => Statement(
          id: 's$i',
          text: 'Turn $i',
          speaker: i.isEven ? StatementSpeaker.user : StatementSpeaker.investigator,
          timestamp: DateTime.now().add(Duration(minutes: i)),
        ),
      );

      final boundary = SessionMemoryWindowManager.computeBoundaryIndex(statements, nominalSize: 6);
      expect(boundary, equals(1));

      final window = SessionMemoryWindowManager.partition(statements, nominalSize: 6);
      expect(window.olderStatements.length, equals(1)); // s0
      expect(window.olderStatements.first.id, equals('s0'));
      expect(window.verbatimStatements.length, equals(7)); // s1..s7
      expect(window.verbatimStatements.first.id, equals('s1'));
      expect(window.verbatimStatements.first.speaker, equals(StatementSpeaker.investigator));
    });

    test('4. Boundary preserves reciprocal turn pair when cut lands on Investigator response to User', () {
      // 9 alternating statements: I0, U1, I2, U3, I4, U5, I6, U7, I8
      // Nominal cut: 9 - 6 = index 3 (U3).
      // U3 was answering I2.
      // Boundary moves back to index 2 (I2) so the exchange (I2 -> U3) is intact!
      final statements = List.generate(
        9,
        (i) => Statement(
          id: 's$i',
          text: 'Turn $i',
          speaker: i.isOdd ? StatementSpeaker.user : StatementSpeaker.investigator,
          timestamp: DateTime.now().add(Duration(minutes: i)),
        ),
      );

      final boundary = SessionMemoryWindowManager.computeBoundaryIndex(statements, nominalSize: 6);
      expect(boundary, equals(2));

      final window = SessionMemoryWindowManager.partition(statements, nominalSize: 6);
      expect(window.olderStatements.length, equals(2)); // s0, s1
      expect(window.verbatimStatements.length, equals(7)); // s2..s8
      expect(window.verbatimStatements.first.id, equals('s2'));
    });

    test('5. Contiguous speaker block is preserved intact and expands window > 7', () {
      // Sequence: U0, I1, U2, U3, U4, I5, U6, I7, U8 (9 statements)
      // Nominal cut: 9 - 6 = index 3 (U3, middle of user block U2, U3, U4)
      // Block preservation moves back to index 2 (U2).
      // U2 was answering I1, so reciprocal coherence moves back to index 1 (I1).
      // Window expands to 8 statements (s1..s8) without splitting the user's contiguous block!
      final statements = [
        Statement(id: 's0', text: 'U0', speaker: StatementSpeaker.user, timestamp: DateTime.now()),
        Statement(id: 's1', text: 'I1', speaker: StatementSpeaker.investigator, timestamp: DateTime.now()),
        Statement(id: 's2', text: 'U2', speaker: StatementSpeaker.user, timestamp: DateTime.now()),
        Statement(id: 's3', text: 'U3', speaker: StatementSpeaker.user, timestamp: DateTime.now()),
        Statement(id: 's4', text: 'U4', speaker: StatementSpeaker.user, timestamp: DateTime.now()),
        Statement(id: 's5', text: 'I5', speaker: StatementSpeaker.investigator, timestamp: DateTime.now()),
        Statement(id: 's6', text: 'U6', speaker: StatementSpeaker.user, timestamp: DateTime.now()),
        Statement(id: 's7', text: 'I7', speaker: StatementSpeaker.investigator, timestamp: DateTime.now()),
        Statement(id: 's8', text: 'U8', speaker: StatementSpeaker.user, timestamp: DateTime.now()),
      ];

      final boundary = SessionMemoryWindowManager.computeBoundaryIndex(statements, nominalSize: 6);
      expect(boundary, equals(1));

      final window = SessionMemoryWindowManager.partition(statements, nominalSize: 6);
      expect(window.verbatimStatements.length, equals(8));
      expect(window.olderStatements.length, equals(1));
      expect(window.verbatimStatements.map((s) => s.id).toList(), equals(['s1', 's2', 's3', 's4', 's5', 's6', 's7', 's8']));
    });

    test('6. Invariant check: zero duplication, zero loss, order strictly preserved', () {
      final statements = List.generate(
        12,
        (i) => Statement(
          id: 's$i',
          text: 'Text $i',
          speaker: (i % 3 == 0) ? StatementSpeaker.investigator : StatementSpeaker.user,
          timestamp: DateTime.now().add(Duration(minutes: i)),
        ),
      );

      final window = SessionMemoryWindowManager.partition(statements, nominalSize: 6);
      final combined = [...window.olderStatements, ...window.verbatimStatements];

      expect(combined.length, equals(statements.length));
      for (int i = 0; i < statements.length; i++) {
        expect(combined[i].id, equals(statements[i].id));
      }
    });
  });

  group('Step 3.3: Epistemic Attribution & Session Dialogue Compressor', () {
    test('7. Classifies statements under User-Labelled Facts, Assumptions, and Interpretations without promotion', () {
      final olderStatements = [
        Statement(
          id: 'o1',
          text: 'The meeting was scheduled at 2:00 PM.',
          speaker: StatementSpeaker.user,
          label: LabelType.fact,
          timestamp: DateTime.now(),
        ),
        Statement(
          id: 'o2',
          text: 'Nobody wants to work with me.',
          speaker: StatementSpeaker.user,
          label: LabelType.assumption,
          timestamp: DateTime.now(),
        ),
        Statement(
          id: 'o3',
          text: 'This means I am incompetent.',
          speaker: StatementSpeaker.user,
          label: LabelType.interpretation,
          timestamp: DateTime.now(),
        ),
      ];

      final currentCase = CaseModel(
        id: 'c1',
        caseNumber: 'SESSION 01',
        title: 'Work stress',
        currentStage: CaseStage.incident,
        incidentDescription: 'I arrived late to the team meeting.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        statements: olderStatements,
      );

      final summary = SessionDialogueCompressor.recomputeSummary(
        olderStatements: olderStatements,
        currentCase: currentCase,
      );

      expect(summary, isNotNull);
      // Fact is explicitly attributed as User-Labelled, NOT app-verified
      expect(summary, contains('User-Labelled Facts [F] (Classified by user as observable)'));
      expect(summary, contains('User stated: "The meeting was scheduled at 2:00 PM."'));
      expect(summary, isNot(contains('Application verified')));
      expect(summary, isNot(contains('Confirmed Facts')));

      // Assumptions and interpretations remain in their respective sections
      expect(summary, contains('Unverified Assumptions [A] (Reported by user as unverified thoughts)'));
      expect(summary, contains('User stated: "Nobody wants to work with me."'));
      expect(summary, contains('Subjective Interpretations [I] (Personal meaning attributed by user)'));
      expect(summary, contains('User stated: "This means I am incompetent."'));
    });

    test('8. Preserves candidate hypotheses and counter-evidence correctly', () {
      final olderStatements = [
        Statement(
          id: 'o1',
          text: 'Manager did not smile during check-in.',
          speaker: StatementSpeaker.user,
          label: LabelType.fact,
          timestamp: DateTime.now(),
        ),
      ];

      final currentCase = CaseModel(
        id: 'c1',
        caseNumber: 'SESSION 02',
        title: 'Feedback review',
        currentStage: CaseStage.hypotheses,
        incidentDescription: 'Manager seemed quiet.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        statements: olderStatements,
        hypotheses: const [
          Hypothesis(
            id: 'h1',
            title: 'Defensive Anticipation',
            explanation: 'Expecting criticism to avoid disappointment.',
            whyItMightFit: 'Matches feeling of dread.',
            whatDoesNotFit: 'Manager gave a positive written evaluation yesterday.',
          ),
        ],
      );

      final summary = SessionDialogueCompressor.recomputeSummary(
        olderStatements: olderStatements,
        currentCase: currentCase,
      );

      expect(summary, contains('Candidate Hypotheses Explored (Recorded Counter-Evidence):'));
      expect(summary, contains('"Defensive Anticipation": Expecting criticism to avoid disappointment.'));
      expect(summary, contains('Recorded Counter-Evidence: Manager gave a positive written evaluation yesterday.'));
      // Never promoted to an unquestioned fact
      expect(summary, isNot(contains('Confirmed Hypothesis')));
    });

    test('9. Accurately reports all three inquiry-resolution states', () {
      // Scenario A: Inquiry with no subsequent user response
      final statementsA = [
        Statement(
          id: 'i1',
          text: 'What did you notice in your body right then?',
          speaker: StatementSpeaker.investigator,
          timestamp: DateTime.now(),
        ),
      ];
      final caseA = CaseModel(
        id: 'ca',
        caseNumber: 'SESSION 03',
        title: 'Panic',
        currentStage: CaseStage.evidence,
        incidentDescription: 'Heart racing',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        statements: statementsA,
      );
      final summaryA = SessionDialogueCompressor.recomputeSummary(
        olderStatements: statementsA,
        currentCase: caseA,
      );
      expect(summaryA, contains('Status: No subsequent user response recorded'));

      // Scenario B: Inquiry followed by a user statement (resolution undetermined)
      final statementsB = [
        Statement(
          id: 'i2',
          text: 'What concrete evidence supports that thought?',
          speaker: StatementSpeaker.investigator,
          timestamp: DateTime.now(),
        ),
        Statement(
          id: 'u2',
          text: 'He looked at his watch twice.',
          speaker: StatementSpeaker.user,
          label: LabelType.fact,
          timestamp: DateTime.now().add(const Duration(minutes: 1)),
        ),
      ];
      final caseB = CaseModel(
        id: 'cb',
        caseNumber: 'SESSION 03',
        title: 'Meeting glance',
        currentStage: CaseStage.evidence,
        incidentDescription: 'Watch checking',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        statements: statementsB,
      );
      final summaryB = SessionDialogueCompressor.recomputeSummary(
        olderStatements: statementsB,
        currentCase: caseB,
      );
      expect(summaryB, contains('Status: Response recorded — resolution undetermined'));
      expect(summaryB, contains('Subsequent User Statement: "He looked at his watch twice."'));
      expect(summaryB, isNot(contains('Pending clarification (unresolved)'))); // Not forced as pending

      // Scenario C: Explicitly resolved via Case Conclusion / Structured Findings
      final caseC = caseB.copyWith(
        userConclusion: 'Looking at his watch simply meant he had another appointment.',
        isCompleted: true,
      );
      final summaryC = SessionDialogueCompressor.recomputeSummary(
        olderStatements: statementsB,
        currentCase: caseC,
      );
      expect(summaryC, contains('Status: Explicitly resolved via Case Conclusion / Structured Findings'));
    });
  });

  group('Step 3.3: Multilingual Tokenizer & Conversational Pacing Enforcer', () {
    test('10. Sentence tokenizer handles decimals and ellipses without splitting', () {
      const text = 'Your recorded sleep averaged 5.4 hours... How did you feel waking up?';
      final sentences = ConversationalPacingEnforcer.tokenizeSentences(text);
      expect(sentences.length, equals(2));
      expect(sentences[0], equals('Your recorded sleep averaged 5.4 hours...'));
      expect(sentences[1], equals('How did you feel waking up?'));
    });

    test('11. Sentence tokenizer handles medical/common abbreviations without splitting', () {
      const textEn = 'Dr. Martin noted an improvement of 7.5 pts. That is encouraging.';
      final sentencesEn = ConversationalPacingEnforcer.tokenizeSentences(textEn);
      expect(sentencesEn.length, equals(2));

      const textFr = 'M. Dupont a mentionné ce fait le 12 mai. Que remarquez-vous ?';
      final sentencesFr = ConversationalPacingEnforcer.tokenizeSentences(textFr);
      expect(sentencesFr.length, equals(2));
    });

    test('12. Sentence tokenizer does NOT split on mid-sentence Tunisian Arabic interrogatives', () {
      // 'علاش' and 'شنوة' occur mid-sentence
      const textAr = 'ما نعرفش علاش حسيت روحي مخنوق وقتها. كي سألتني شنوة صار ما لقيت ما نجاوب؟';
      final sentencesAr = ConversationalPacingEnforcer.tokenizeSentences(textAr);
      expect(sentencesAr.length, equals(2));
      expect(sentencesAr[0], contains('علاش'));
      expect(sentencesAr[1], contains('شنوة'));
      expect(sentencesAr[1].endsWith('؟'), isTrue);
    });

    test('13. Response validator enforces mode bounds with +1 tolerance margin', () {
      // Explore thought: target 3 sentences (tolerance allows up to 4)
      const fourSentences = 'First sentence. Second sentence. Third sentence. Fourth sentence.';
      final val4 = ConversationalPacingEnforcer.validateResponse(
        fourSentences,
        ConversationMode.exploreThought,
      );
      expect(val4.isValid, isTrue); // 4 is within +1 margin
      expect(val4.sentenceCount, equals(4));

      const sixSentences = 'One. Two. Three. Four. Five. Six.';
      final val6 = ConversationalPacingEnforcer.validateResponse(
        sixSentences,
        ConversationMode.exploreThought,
      );
      expect(val6.isValid, isFalse); // 6 exceeds target (3) + 1
      expect(val6.sentenceCount, equals(6));
    });

    test('14. Absolute Safety Immunity: Hotlines, distress phrases, and grounding cues are 100% exempt', () {
      const hotlineResponse = 'Please stay safe. If you feel overwhelmed, call 80 10 50 50 or SAMU 190. Emergency help is always available right here for you whenever needed.';
      final validationHotline = ConversationalPacingEnforcer.validateResponse(
        hotlineResponse,
        ConversationMode.grounding, // Grounding normally targets 2 sentences
      );
      expect(validationHotline.isValid, isTrue);
      expect(validationHotline.isExempt, isTrue);

      const groundingResponse = 'Take a slow vagal breath. Settle into 5-4-3-2-1 somatic awareness. Feel your feet flat on the ground. Release tension in your shoulders. Notice your breath flowing gently.';
      final validationGrounding = ConversationalPacingEnforcer.validateResponse(
        groundingResponse,
        ConversationMode.grounding,
      );
      expect(validationGrounding.isValid, isTrue);
      expect(validationGrounding.isExempt, isTrue);
    });
  });

  group('Step 3.3: CaseModel Persistence, System Prompt & Mock Service Parity', () {
    test('15. CaseModel serializes sessionSummary and deserializes cleanly with backward compatibility', () {
      final caseWithSummary = CaseModel(
        id: 'c-test',
        caseNumber: 'SESSION 05',
        title: 'Persistence Test',
        currentStage: CaseStage.evidence,
        incidentDescription: 'Test incident',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sessionSummary: 'SESSION PROGRESSION: Fact [F] recorded.',
      );

      final json = caseWithSummary.toJson();
      expect(json['sessionSummary'], equals('SESSION PROGRESSION: Fact [F] recorded.'));

      // Deserialize with sessionSummary
      final restored = CaseModel.fromJson(json);
      expect(restored.sessionSummary, equals('SESSION PROGRESSION: Fact [F] recorded.'));

      // Backward compatibility: deserialize legacy JSON without sessionSummary key
      final legacyJson = Map<String, dynamic>.from(json)..remove('sessionSummary');
      final legacyRestored = CaseModel.fromJson(legacyJson);
      expect(legacyRestored.sessionSummary, isNull);
    });

    test('16. AiCompanionSystemPrompt contains prompt version and injects session summary block', () {
      expect(AiCompanionSystemPrompt.promptVersion, equals('1.2.0'));

      final prompt = AiCompanionSystemPrompt.buildFullPrompt(
        mode: ConversationMode.exploreThought,
        languageCode: 'en',
        sessionSummary: '• User-Labelled Facts [F]: Meeting was at 2pm.',
      );

      expect(prompt, contains('ACTIVE SESSION CONTINUITY & HISTORICAL CONTEXT:'));
      expect(prompt, contains('• User-Labelled Facts [F]: Meeting was at 2pm.'));
      expect(prompt, contains('Conversational Pacing, Brevity & Naturalness (Step 3.3 Standard)'));
    });

    test('17. MockInvestigatorService accepts sessionSummary and adheres to mode pacing', () async {
      final mock = MockInvestigatorService();
      final currentCase = CaseModel(
        id: 'mock-c',
        caseNumber: 'SESSION 06',
        title: 'Mock Case',
        currentStage: CaseStage.incident,
        incidentDescription: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Explore Thought in Arabic
      final replyAr = await mock.getNextQuestion(
        currentCase: currentCase,
        conversationHistory: [],
        sessionSummary: 'SESSION PROGRESSION SUMMARY',
        conversationMode: ConversationMode.exploreThought,
        languageCode: 'ar',
      );
      expect(replyAr, isNotEmpty);
      final validationAr = ConversationalPacingEnforcer.validateResponse(replyAr, ConversationMode.exploreThought);
      expect(validationAr.isValid, isTrue);

      // Grounding in French
      final replyFr = await mock.getNextQuestion(
        currentCase: currentCase,
        conversationHistory: [],
        sessionSummary: 'SESSION PROGRESSION SUMMARY',
        conversationMode: ConversationMode.grounding,
        languageCode: 'fr',
      );
      expect(replyFr, isNotEmpty);
      final validationFr = ConversationalPacingEnforcer.validateResponse(replyFr, ConversationMode.grounding);
      expect(validationFr.isValid, isTrue);

      // Understand Emotion in English
      final replyEn = await mock.getNextQuestion(
        currentCase: currentCase,
        conversationHistory: [],
        sessionSummary: 'SESSION PROGRESSION SUMMARY',
        conversationMode: ConversationMode.understandEmotion,
        languageCode: 'en',
      );
      expect(replyEn, isNotEmpty);
      final validationEn = ConversationalPacingEnforcer.validateResponse(replyEn, ConversationMode.understandEmotion);
      expect(validationEn.isValid, isTrue);
    });
  });

  group('Step 3.3: Safety State Persistence & ActiveCaseController Integration', () {
    test('18. Pausing a case for safety sets isPausedForSafety = true and commits to repository', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeCaseControllerProvider.notifier);
      final initialCase = await notifier.startNewCase('Safety incident test');
      expect(initialCase.isPausedForSafety, isFalse);

      final pauseResult = await notifier.pauseCaseForSafety();
      expect(pauseResult, isTrue);

      final pausedCase = container.read(activeCaseControllerProvider).value;
      expect(pausedCase?.isPausedForSafety, isTrue);

      // Verify persisted in repository
      final repo = container.read(caseRepositoryProvider);
      final fetched = await repo.getCaseById(initialCase.id);
      expect(fetched?.isPausedForSafety, isTrue);
    });

    test('19. Ordinary dialogue actions cannot bypass paused case, while safety statements persist', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeCaseControllerProvider.notifier);
      await notifier.startNewCase('Pause bypass test');
      await notifier.pauseCaseForSafety();

      final statementCountBefore = container.read(activeCaseControllerProvider).value!.statements.length;

      // Normal user statement is rejected when paused
      await notifier.addStatement('Normal follow up thought', StatementSpeaker.user);
      final statementCountAfterNormal = container.read(activeCaseControllerProvider).value!.statements.length;
      expect(statementCountAfterNormal, equals(statementCountBefore));

      // Safety statement is allowed to record the crisis trigger before aborting
      await notifier.addStatement(
        'I want to end this pain',
        StatementSpeaker.user,
        label: LabelType.assumption,
        isSafetyStatement: true,
      );
      final statementCountAfterSafety = container.read(activeCaseControllerProvider).value!.statements.length;
      expect(statementCountAfterSafety, equals(statementCountBefore + 1));
      expect(container.read(activeCaseControllerProvider).value!.isPausedForSafety, isTrue);
    });

    test('20. ActiveCaseController automatically populates sessionSummary when statements exceed nominal window', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeCaseControllerProvider.notifier);
      await notifier.startNewCase('Window trigger incident');

      // Add 8 statements
      for (int i = 0; i < 8; i++) {
        await notifier.addStatement(
          'Message $i in long dialogue',
          i.isEven ? StatementSpeaker.user : StatementSpeaker.investigator,
          label: i.isEven ? LabelType.fact : null,
        );
      }

      final active = container.read(activeCaseControllerProvider).value;
      expect(active, isNotNull);
      expect(active!.statements.length, greaterThan(6));
      expect(active.sessionSummary, isNotNull);
      expect(active.sessionSummary, contains('SESSION PROGRESSION & CONTEXT'));
      expect(active.sessionSummary, contains('User-Labelled Facts [F]'));
    });

    test('21. Deleting a case purges its sessionSummary and all data from repository', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeCaseControllerProvider.notifier);
      final c = await notifier.startNewCase('Delete purge test');

      // Add statements to populate summary
      for (int i = 0; i < 8; i++) {
        await notifier.addStatement('Statement $i', i.isEven ? StatementSpeaker.user : StatementSpeaker.investigator);
      }

      final repo = container.read(caseRepositoryProvider);
      expect(await repo.getCaseById(c.id), isNotNull);

      await notifier.deleteCase(c.id);

      expect(container.read(activeCaseControllerProvider).value, isNull);
      expect(await repo.getCaseById(c.id), isNull);
    });
  });

  group('Step 3.3: Privacy Gate, Cloud Consent & Private Case Isolation', () {
    final now = DateTime.now();

    final consentedProfile = PsychologicalProfileModel(
      updatedAt: now,
      shareWithAiCompanion: true,
      allowAiPersonalization: true,
    );

    final noShareProfile = PsychologicalProfileModel(
      updatedAt: now,
      shareWithAiCompanion: false,
      allowAiPersonalization: true,
    );

    final bothFalseProfile = PsychologicalProfileModel(
      updatedAt: now,
      shareWithAiCompanion: false,
      allowAiPersonalization: false,
    );

    final noPersonalizeProfile = PsychologicalProfileModel(
      updatedAt: now,
      shareWithAiCompanion: true,
      allowAiPersonalization: false,
    );

    final regularCase = CaseModel(
      id: 'case_public',
      caseNumber: 'SESSION 10',
      title: 'Public Case',
      currentStage: CaseStage.incident,
      incidentDescription: 'Public case description',
      statements: const [],
      hypotheses: const [],
      createdAt: now,
      updatedAt: now,
      isPrivate: false,
    );

    final privateCase = CaseModel(
      id: 'case_private',
      caseNumber: 'SESSION 11',
      title: 'Private Case',
      currentStage: CaseStage.incident,
      incidentDescription: 'Highly sensitive confidential thought',
      statements: const [],
      hypotheses: const [],
      createdAt: now,
      updatedAt: now,
      isPrivate: true,
    );

    test('22. Both cloud consents true & non-private case isolates Gemini transmission (zero network requests in Stage 6.1A.3)', () async {
      int payloadCount = 0;
      final service = DirectGeminiInvestigatorService(
        apiKey: 'test-api-key',
        onRequestAttempted: (url, payload) => payloadCount++,
        clientFactory: () => throw const SocketException('Simulated offline test environment'),
      );

      expect(DirectGeminiInvestigatorService.canTransmitCaseData(
        currentCase: regularCase,
        profile: consentedProfile,
        checkProfileConsent: true,
      ), isTrue);

      final question = await service.getNextQuestion(
        currentCase: regularCase,
        conversationHistory: [
          Statement(id: 's1', text: 'Hello', speaker: StatementSpeaker.user, timestamp: now),
        ],
        profile: consentedProfile,
      );

      // Stage 6.1A.3: Gemini transmission is permanently disabled (zero network requests)
      expect(service.networkRequestsAttempted, equals(0));
      expect(payloadCount, equals(0));
      expect(service.lastCallWasLive, isFalse);
      expect(question, isNotEmpty);
    });

    test('23. shareWithAiCompanion == false routes to local fallback and transmits zero bytes', () async {
      int payloadCount = 0;
      final service = DirectGeminiInvestigatorService(
        apiKey: 'test-api-key',
        onRequestAttempted: (url, payload) => payloadCount++,
        clientFactory: () => throw const SocketException('Should never be called'),
      );

      expect(DirectGeminiInvestigatorService.canTransmitCaseData(
        currentCase: regularCase,
        profile: noShareProfile,
        checkProfileConsent: true,
      ), isFalse);

      final question = await service.getNextQuestion(
        currentCase: regularCase,
        conversationHistory: [
          Statement(id: 's1', text: 'Distressing thought', speaker: StatementSpeaker.user, timestamp: now),
        ],
        profile: noShareProfile,
        sessionSummary: 'SECRET SUMMARY',
      );

      // Crucial: ZERO external requests attempted
      expect(service.networkRequestsAttempted, equals(0));
      expect(payloadCount, equals(0));
      expect(question, isNotEmpty); // MockInvestigatorService responded locally
    });

    test('24. allowAiPersonalization == false with shareWithAiCompanion == true isolates external AI and executes local-only behavior', () async {
      int payloadCount = 0;
      Map<String, dynamic>? capturedPayload;
      final service = DirectGeminiInvestigatorService(
        apiKey: 'test-api-key',
        onRequestAttempted: (url, payload) {
          payloadCount++;
          capturedPayload = payload;
        },
        clientFactory: () => throw const SocketException('Simulated offline test environment'),
      );

      expect(DirectGeminiInvestigatorService.canTransmitCaseData(
        currentCase: regularCase,
        profile: noPersonalizeProfile,
        checkProfileConsent: true,
      ), isTrue);

      final question = await service.getNextQuestion(
        currentCase: regularCase,
        conversationHistory: [
          Statement(id: 's1', text: 'Distressing thought', speaker: StatementSpeaker.user, timestamp: now),
        ],
        profile: noPersonalizeProfile,
      );

      // Stage 6.1A.3: Gemini network transmission is permanently disabled (zero requests attempted)
      expect(service.networkRequestsAttempted, equals(0));
      expect(payloadCount, equals(0));
      expect(capturedPayload, isNull);
      expect(service.lastCallWasLive, isFalse);
      expect(question, isNotEmpty);
    });

    test('25. Missing profile (null) routes to local fallback and transmits zero bytes', () async {
      int payloadCount = 0;
      final service = DirectGeminiInvestigatorService(
        apiKey: 'test-api-key',
        onRequestAttempted: (url, payload) => payloadCount++,
        clientFactory: () => throw const SocketException('Should never be called'),
      );

      expect(DirectGeminiInvestigatorService.canTransmitCaseData(
        currentCase: regularCase,
        profile: null,
        checkProfileConsent: true,
      ), isFalse);

      final question = await service.getNextQuestion(
        currentCase: regularCase,
        conversationHistory: [
          Statement(id: 's1', text: 'Distressing thought', speaker: StatementSpeaker.user, timestamp: now),
        ],
        profile: null,
      );

      expect(service.networkRequestsAttempted, equals(0));
      expect(payloadCount, equals(0));
      expect(question, isNotEmpty);
    });

    test('26. Private case (isPrivate == true) in getNextQuestion routes to local fallback even if consented', () async {
      int payloadCount = 0;
      final service = DirectGeminiInvestigatorService(
        apiKey: 'test-api-key',
        onRequestAttempted: (url, payload) => payloadCount++,
        clientFactory: () => throw const SocketException('Should never be called'),
      );

      expect(DirectGeminiInvestigatorService.canTransmitCaseData(
        currentCase: privateCase,
        profile: consentedProfile,
        checkProfileConsent: true,
      ), isFalse);

      final question = await service.getNextQuestion(
        currentCase: privateCase,
        conversationHistory: [
          Statement(id: 's1', text: 'Secret case statement', speaker: StatementSpeaker.user, timestamp: now),
        ],
        profile: consentedProfile,
        sessionSummary: 'PRIVATE SUMMARY DATA',
      );

      expect(service.networkRequestsAttempted, equals(0));
      expect(payloadCount, equals(0));
      expect(question, isNotEmpty);
    });

    test('27. All 4 investigation operations enforce strict private-case isolation with 0 network calls', () async {
      int payloadCount = 0;
      final service = DirectGeminiInvestigatorService(
        apiKey: 'test-api-key',
        onRequestAttempted: (url, payload) => payloadCount++,
        clientFactory: () => throw const SocketException('Should never be called'),
      );

      // 1. getNextQuestion
      final q = await service.getNextQuestion(
        currentCase: privateCase,
        conversationHistory: const [],
        profile: consentedProfile,
      );
      expect(q, isNotEmpty);

      // 2. generateHypotheses
      final hyp = await service.generateHypotheses(
        currentCase: privateCase,
        languageCode: 'en',
      );
      expect(hyp, isNotEmpty);

      // 3. generateCrossExaminationQuestions
      const testHyp = Hypothesis(
        id: 'h1',
        title: 'Cognitive reframe',
        explanation: 'Alternative explanation',
        whyItMightFit: 'Context',
        whatDoesNotFit: 'Facts',
      );
      final cross = await service.generateCrossExaminationQuestions(
        currentCase: privateCase,
        hypothesis: testHyp,
        languageCode: 'en',
      );
      expect(cross, isNotEmpty);

      // 4. summarizeFindings
      final summary = await service.summarizeFindings(
        currentCase: privateCase,
        languageCode: 'en',
      );
      expect(summary, isNotEmpty);

      // Total network requests attempted for all 4 operations must remain ZERO
      expect(service.networkRequestsAttempted, equals(0));
      expect(payloadCount, equals(0));
    });

    test('28. MockInvestigatorService executes purely local logic with zero HTTP or network calls', () async {
      final mockService = MockInvestigatorService();

      // Test all 4 methods on mock directly
      final q = await mockService.getNextQuestion(
        currentCase: privateCase,
        conversationHistory: const [],
      );
      expect(q, isNotEmpty);

      final h = await mockService.generateHypotheses(currentCase: privateCase);
      expect(h, isNotEmpty);

      final c = await mockService.generateCrossExaminationQuestions(
        currentCase: privateCase,
        hypothesis: const Hypothesis(id: 'h1', title: 'T', explanation: 'E', whyItMightFit: 'W', whatDoesNotFit: 'N'),
      );
      expect(c, isNotEmpty);

      final s = await mockService.summarizeFindings(currentCase: privateCase);
      expect(s, isNotEmpty);
    });

    test('29. generateHypotheses blocks Gemini transmission on missing profile, disabled consents, or private case', () async {
      int payloadCount = 0;
      final service = DirectGeminiInvestigatorService(
        apiKey: 'test-api-key',
        onRequestAttempted: (url, payload) => payloadCount++,
        clientFactory: () => throw const SocketException('Should never be called'),
      );

      // 1. Missing profile (null)
      final r1 = await service.generateHypotheses(currentCase: regularCase, profile: null);
      expect(r1, isNotEmpty);
      expect(service.networkRequestsAttempted, equals(0));
      expect(payloadCount, equals(0));

      // 2. shareWithAiCompanion == false
      final r2 = await service.generateHypotheses(currentCase: regularCase, profile: noShareProfile);
      expect(r2, isNotEmpty);
      expect(service.networkRequestsAttempted, equals(0));
      expect(payloadCount, equals(0));

      // 3. both false (shareWithAiCompanion == false, allowAiPersonalization == false)
      final r3 = await service.generateHypotheses(currentCase: regularCase, profile: bothFalseProfile);
      expect(r3, isNotEmpty);
      expect(service.networkRequestsAttempted, equals(0));
      expect(payloadCount, equals(0));

      // 4. Private case (isPrivate == true) with consented profile
      final r4 = await service.generateHypotheses(currentCase: privateCase, profile: consentedProfile);
      expect(r4, isNotEmpty);
      expect(service.networkRequestsAttempted, equals(0));
      expect(payloadCount, equals(0));
    });

    test('30. generateCrossExaminationQuestions blocks Gemini transmission on missing profile, disabled consents, or private case', () async {
      int payloadCount = 0;
      final service = DirectGeminiInvestigatorService(
        apiKey: 'test-api-key',
        onRequestAttempted: (url, payload) => payloadCount++,
        clientFactory: () => throw const SocketException('Should never be called'),
      );

      const testHyp = Hypothesis(
        id: 'h1',
        title: 'Cognitive reframe',
        explanation: 'Alternative explanation',
        whyItMightFit: 'Context',
        whatDoesNotFit: 'Facts',
      );

      // 1. Missing profile (null)
      final r1 = await service.generateCrossExaminationQuestions(currentCase: regularCase, hypothesis: testHyp, profile: null);
      expect(r1, isNotEmpty);
      expect(service.networkRequestsAttempted, equals(0));
      expect(payloadCount, equals(0));

      // 2. shareWithAiCompanion == false
      final r2 = await service.generateCrossExaminationQuestions(currentCase: regularCase, hypothesis: testHyp, profile: noShareProfile);
      expect(r2, isNotEmpty);
      expect(service.networkRequestsAttempted, equals(0));
      expect(payloadCount, equals(0));

      // 3. both false (shareWithAiCompanion == false, allowAiPersonalization == false)
      final r3 = await service.generateCrossExaminationQuestions(currentCase: regularCase, hypothesis: testHyp, profile: bothFalseProfile);
      expect(r3, isNotEmpty);
      expect(service.networkRequestsAttempted, equals(0));
      expect(payloadCount, equals(0));

      // 4. Private case (isPrivate == true) with consented profile
      final r4 = await service.generateCrossExaminationQuestions(currentCase: privateCase, hypothesis: testHyp, profile: consentedProfile);
      expect(r4, isNotEmpty);
      expect(service.networkRequestsAttempted, equals(0));
      expect(payloadCount, equals(0));
    });

    test('31. summarizeFindings blocks Gemini transmission on missing profile, disabled consents, or private case', () async {
      int payloadCount = 0;
      final service = DirectGeminiInvestigatorService(
        apiKey: 'test-api-key',
        onRequestAttempted: (url, payload) => payloadCount++,
        clientFactory: () => throw const SocketException('Should never be called'),
      );

      // 1. Missing profile (null)
      final r1 = await service.summarizeFindings(currentCase: regularCase, profile: null);
      expect(r1, isNotEmpty);
      expect(service.networkRequestsAttempted, equals(0));
      expect(payloadCount, equals(0));

      // 2. shareWithAiCompanion == false
      final r2 = await service.summarizeFindings(currentCase: regularCase, profile: noShareProfile);
      expect(r2, isNotEmpty);
      expect(service.networkRequestsAttempted, equals(0));
      expect(payloadCount, equals(0));

      // 3. both false (shareWithAiCompanion == false, allowAiPersonalization == false)
      final r3 = await service.summarizeFindings(currentCase: regularCase, profile: bothFalseProfile);
      expect(r3, isNotEmpty);
      expect(service.networkRequestsAttempted, equals(0));
      expect(payloadCount, equals(0));

      // 4. Private case (isPrivate == true) with consented profile
      final r4 = await service.summarizeFindings(currentCase: privateCase, profile: consentedProfile);
      expect(r4, isNotEmpty);
      expect(service.networkRequestsAttempted, equals(0));
      expect(payloadCount, equals(0));
    });

    test('32. Consented, non-private cases isolate Gemini transmission for all 3 secondary operations (zero network requests in Stage 6.1A.3)', () async {
      int payloadCount = 0;
      final service = DirectGeminiInvestigatorService(
        apiKey: 'test-api-key',
        onRequestAttempted: (url, payload) => payloadCount++,
        clientFactory: () => throw const SocketException('Simulated offline test environment'),
      );

      const testHyp = Hypothesis(
        id: 'h1',
        title: 'Cognitive reframe',
        explanation: 'Alternative explanation',
        whyItMightFit: 'Context',
        whatDoesNotFit: 'Facts',
      );

      // 1. generateHypotheses
      final h = await service.generateHypotheses(currentCase: regularCase, profile: consentedProfile);
      expect(h, isNotEmpty);
      expect(service.networkRequestsAttempted, equals(0));
      expect(payloadCount, equals(0));

      // 2. generateCrossExaminationQuestions
      final c = await service.generateCrossExaminationQuestions(currentCase: regularCase, hypothesis: testHyp, profile: consentedProfile);
      expect(c, isNotEmpty);
      expect(service.networkRequestsAttempted, equals(0));
      expect(payloadCount, equals(0));

      // 3. summarizeFindings
      final s = await service.summarizeFindings(currentCase: regularCase, profile: consentedProfile);
      expect(s, isNotEmpty);
      expect(service.networkRequestsAttempted, equals(0));
      expect(payloadCount, equals(0));
    });
  });
}
