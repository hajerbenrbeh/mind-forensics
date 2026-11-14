import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/core/safety/crisis_keywords.dart';
import 'package:mind_forensics/core/widgets/mind_pressable.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/data/mock_investigator_service.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_repository.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/conversation_mode.dart';
import 'package:mind_forensics/features/investigation/domain/hypothesis.dart';
import 'package:mind_forensics/features/investigation/domain/statement.dart';
import 'package:mind_forensics/features/investigation/presentation/widgets/live_dialogue_view.dart';
import 'package:mind_forensics/features/journal/domain/journal_memory_model.dart';
import 'package:mind_forensics/features/journey/domain/journey_state_model.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpyInvestigatorService extends MockInvestigatorService {
  int getNextQuestionCallCount = 0;
  int generateHypothesesCallCount = 0;
  int generateCrossExaminationCallCount = 0;
  int summarizeFindingsCallCount = 0;

  @override
  Future<String> getNextQuestion({
    required CaseModel currentCase,
    required List<Statement> conversationHistory,
    bool includePastCaseSummaries = true,
    String? languageCode,
    PsychologicalProfileModel? profile,
    JourneyStateModel? journey,
    ConversationMode? conversationMode,
    MindTraceModel? latestTrace,
    List<MindTraceModel>? historicalTraces,
    List<JournalMemoryModel>? compressedMemories,
    String? sessionSummary,
  }) async {
    getNextQuestionCallCount++;
    return 'Mock Question';
  }

  @override
  Future<List<Hypothesis>> generateHypotheses({
    required CaseModel currentCase,
    String? languageCode,
    PsychologicalProfileModel? profile,
  }) async {
    generateHypothesesCallCount++;
    return [];
  }

  @override
  Future<List<String>> generateCrossExaminationQuestions({
    required CaseModel currentCase,
    required Hypothesis hypothesis,
    String? languageCode,
    PsychologicalProfileModel? profile,
  }) async {
    generateCrossExaminationCallCount++;
    return [];
  }

  @override
  Future<String> summarizeFindings({
    required CaseModel currentCase,
    String? languageCode,
    PsychologicalProfileModel? profile,
  }) async {
    summarizeFindingsCallCount++;
    return 'Mock Summary';
  }
}

class FakeCaseRepository implements CaseRepository {
  CaseModel? savedCase;
  bool shouldFailOnStatementSave = false;
  bool shouldFailOnPauseSave = false;
  int saveCount = 0;

  @override
  Future<void> saveCase(CaseModel caseModel) async {
    saveCount++;
    final hasAccidentalStatement = caseModel.statements.any((s) =>
        s.text.contains('accidentally') ||
        s.text.contains('ghalat') ||
        s.text.contains('erreur'));

    if (shouldFailOnStatementSave &&
        hasAccidentalStatement &&
        !caseModel.isPausedForSafety) {
      throw Exception('Simulated Disk I/O Failure: Statement Save');
    }
    if (shouldFailOnPauseSave && caseModel.isPausedForSafety) {
      throw Exception('Simulated Disk I/O Failure: Safety Pause Save');
    }
    savedCase = caseModel;
  }

  @override
  Future<List<CaseModel>> getAllCases() async =>
      savedCase != null ? [savedCase!] : [];

  @override
  Future<CaseModel?> getCaseById(String id) async =>
      savedCase?.id == id ? savedCase : null;

  @override
  Future<void> deleteCase(String id) async {
    if (savedCase?.id == id) savedCase = null;
  }

  @override
  Future<void> renameCase(String id, String newTitle) async {
    if (savedCase?.id == id) {
      savedCase = savedCase!.copyWith(title: newTitle);
    }
  }

  @override
  Future<void> deleteAllCases() async {
    savedCase = null;
  }

  @override
  Future<void> toggleCasePrivacy(String id) async {
    if (savedCase?.id == id) {
      savedCase = savedCase!.copyWith(isPrivate: !savedCase!.isPrivate);
    }
  }

  @override
  Future<String> getNextCaseNumber() async => 'SESSION 01';
}

class TestActiveCaseController extends ActiveCaseController {
  TestActiveCaseController(this.initialCase);

  final CaseModel? initialCase;

  @override
  AsyncValue<CaseModel?> build() {
    return AsyncValue.data(initialCase);
  }
}

Future<void> _runAccidentalIngestionWidgetScenario({
  required WidgetTester tester,
  required String scenario,
  required bool failStatement,
  required bool failPause,
}) async {
  final fakeRepo = FakeCaseRepository()
    ..shouldFailOnStatementSave = failStatement
    ..shouldFailOnPauseSave = failPause;

  final spyAi = SpyInvestigatorService();
  final testCase = CaseModel(
    id: 'test_case_$scenario',
    caseNumber: 'SESSION 01',
    title: 'Accidental Ingestion Test',
    incidentDescription: 'Active session',
    currentStage: CaseStage.incident,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  fakeRepo.savedCase = testCase;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        caseRepositoryProvider.overrideWithValue(fakeRepo),
        investigatorServiceProvider.overrideWithValue(spyAi),
        activeCaseControllerProvider.overrideWith(
          () => TestActiveCaseController(testCase),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: LiveDialogueView(caseModel: testCase),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final inputField = find.byType(TextField);
  expect(inputField, findsOneWidget);

  await tester.enterText(
    inputField,
    'I accidentally took more medication than prescribed.',
  );
  await tester.pumpAndSettle();

  final sendButton = find.byType(MindPressable).last;
  await tester.tap(sendButton);
  await tester.pumpAndSettle();

  final strings = AppStrings('en');
  expect(
    find.text(strings.accidentalOverdoseTitle),
    findsOneWidget,
    reason: 'Medical guidance title must appear in scenario: $scenario',
  );
  expect(
    find.text(strings.accidentalOverdoseBody),
    findsOneWidget,
    reason: 'Medical guidance body must appear in scenario: $scenario',
  );

  expect(find.text(strings.callSamu190Btn), findsOneWidget);
  expect(find.text(strings.returnToCaseBtn), findsOneWidget);

  // 0 AI calls
  expect(spyAi.getNextQuestionCallCount, equals(0));
  expect(spyAi.generateHypothesesCallCount, equals(0));
  expect(spyAi.generateCrossExaminationCallCount, equals(0));
  expect(spyAi.summarizeFindingsCallCount, equals(0));

  // No false indication of saving
  expect(find.text('Takeaway saved to your profile'), findsNothing);
  expect(find.text('Statement saved'), findsNothing);
  expect(find.text('Note saved'), findsNothing);

  // User can dismiss without lockout
  await tester.tap(find.text(strings.returnToCaseBtn));
  await tester.pumpAndSettle();

  expect(find.text(strings.accidentalOverdoseTitle), findsNothing);

  // Synthesis must remain hidden and blocked even after dismissing the medical dialog
  expect(find.text(strings.saveTakeawayReportBtn), findsNothing);
  expect(find.text(strings.suggestedReplySaveTakeaway), findsNothing);
  expect(spyAi.summarizeFindingsCallCount, equals(0));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Stage 5.5: Accidental Ingestion Persistence & Safety Routing Tests', () {
    // ── Test 1: Successful statement persistence & pause ─────────────────────
    test('1. Successful statement persistence and safety pause in controller', () async {
      final fakeRepo = FakeCaseRepository();
      final container = ProviderContainer(
        overrides: [
          caseRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeCaseControllerProvider.notifier);
      final initialCase = await notifier.startNewCase('Medication Check');
      expect(initialCase.statements.length, equals(1));

      await notifier.addStatement(
        'I accidentally took more medication than prescribed.',
        StatementSpeaker.user,
        isSafetyStatement: true,
      );

      final stateWithStatement = container.read(activeCaseControllerProvider).value;
      expect(stateWithStatement?.statements.length, equals(2));
      expect(stateWithStatement?.statements.last.text,
          equals('I accidentally took more medication than prescribed.'));
      expect(fakeRepo.savedCase?.statements.length, equals(2));

      final pauseResult = await notifier.pauseCaseForSafety();
      expect(pauseResult, isTrue);

      final statePaused = container.read(activeCaseControllerProvider).value;
      expect(statePaused?.isPausedForSafety, isTrue);
      expect(fakeRepo.savedCase?.isPausedForSafety, isTrue);
    });

    // ── Test 2: Persistence failure on statement ─────────────────────────────
    test('2. Statement persistence failure keeps volatile state and rethrows to caller', () async {
      final fakeRepo = FakeCaseRepository()..shouldFailOnStatementSave = true;
      final container = ProviderContainer(
        overrides: [
          caseRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeCaseControllerProvider.notifier);
      await notifier.startNewCase('Medication Check');

      // addStatement with isSafetyStatement: true updates volatile state, then throws on repository save
      expect(
        () => notifier.addStatement(
          'I accidentally took too many pills by mistake.',
          StatementSpeaker.user,
          isSafetyStatement: true,
        ),
        throwsA(isA<Exception>()),
      );

      // Verify statement is safely retained in volatile memory
      final inMemoryCase = container.read(activeCaseControllerProvider).value;
      expect(inMemoryCase?.statements.length, equals(2));
      expect(inMemoryCase?.statements.last.text,
          equals('I accidentally took too many pills by mistake.'));
    });

    // ── Test 3: Session-pause persistence failure ────────────────────────────
    test('3. Session-pause failure returns false but enforces fail-closed pause in volatile memory', () async {
      final fakeRepo = FakeCaseRepository()..shouldFailOnPauseSave = true;
      final container = ProviderContainer(
        overrides: [
          caseRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeCaseControllerProvider.notifier);
      await notifier.startNewCase('Medication Check');

      final pauseResult = await notifier.pauseCaseForSafety();
      // Should fail closed: returns false to indicate disk failure
      expect(pauseResult, isFalse);

      // CRITICAL GUARANTEE: In-memory state MUST be paused to prevent AI routing
      final inMemoryCase = container.read(activeCaseControllerProvider).value;
      expect(inMemoryCase?.isPausedForSafety, isTrue);
    });

    // ── Test 4: Both statement and pause persistence failure ─────────────────
    test('4. Both statement and pause persistence failures fail closed in volatile memory', () async {
      final fakeRepo = FakeCaseRepository()
        ..shouldFailOnStatementSave = true
        ..shouldFailOnPauseSave = true;
      final container = ProviderContainer(
        overrides: [
          caseRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeCaseControllerProvider.notifier);
      await notifier.startNewCase('Medication Check');

      // 1. Statement throws on disk save
      expect(
        () => notifier.addStatement(
          'chrabt dwe bel ghalat',
          StatementSpeaker.user,
          isSafetyStatement: true,
        ),
        throwsA(isA<Exception>()),
      );

      // 2. Pause returns false
      final pauseResult = await notifier.pauseCaseForSafety();
      expect(pauseResult, isFalse);

      // Both maintained in volatile memory
      final inMemoryCase = container.read(activeCaseControllerProvider).value;
      expect(inMemoryCase?.statements.length, equals(2));
      expect(inMemoryCase?.isPausedForSafety, isTrue);
    });

    // ── Test 5a: Widget test — Success scenario ──────────────────────────────
    testWidgets('5a. Medical guidance appears and 0 AI calls made on successful persistence',
        (tester) async {
      await _runAccidentalIngestionWidgetScenario(
        tester: tester,
        scenario: 'success',
        failStatement: false,
        failPause: false,
      );
    });

    // ── Test 5b: Widget test — Statement save failure scenario ───────────────
    testWidgets('5b. Medical guidance appears and 0 AI calls made on statement persistence failure',
        (tester) async {
      await _runAccidentalIngestionWidgetScenario(
        tester: tester,
        scenario: 'statement_fail',
        failStatement: true,
        failPause: false,
      );
    });

    // ── Test 5c: Widget test — Pause save failure scenario ───────────────────
    testWidgets('5c. Medical guidance appears and 0 AI calls made on pause persistence failure',
        (tester) async {
      await _runAccidentalIngestionWidgetScenario(
        tester: tester,
        scenario: 'pause_fail',
        failStatement: false,
        failPause: true,
      );
    });

    // ── Test 5d: Widget test — Both statement and pause failure scenario ─────
    testWidgets('5d. Medical guidance appears and 0 AI calls made when both statement and pause fail',
        (tester) async {
      await _runAccidentalIngestionWidgetScenario(
        tester: tester,
        scenario: 'both_fail',
        failStatement: true,
        failPause: true,
      );
    });

    // ── Test 6: Synthesis blocked when case is paused for safety ─────────────
    testWidgets('6. Synthesis action is hidden and blocked when case is paused for safety',
        (tester) async {
      final fakeRepo = FakeCaseRepository();
      final spyAi = SpyInvestigatorService();
      final pausedCase = CaseModel(
        id: 'test_paused_case',
        caseNumber: 'SESSION 01',
        title: 'Safety Paused Case',
        incidentDescription: 'Active session',
        currentStage: CaseStage.incident,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPausedForSafety: true,
        statements: [
          Statement(
            id: 'stmt_user',
            text: 'I took too many pills by accident',
            speaker: StatementSpeaker.user,
            timestamp: DateTime.now(),
          ),
        ],
      );
      fakeRepo.savedCase = pausedCase;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            caseRepositoryProvider.overrideWithValue(fakeRepo),
            investigatorServiceProvider.overrideWithValue(spyAi),
            activeCaseControllerProvider.overrideWith(
              () => TestActiveCaseController(pausedCase),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: LiveDialogueView(caseModel: pausedCase),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final strings = AppStrings('en');
      // Synthesis actions must be completely hidden when paused
      expect(find.text(strings.saveTakeawayReportBtn), findsNothing);
      expect(find.text(strings.suggestedReplySaveTakeaway), findsNothing);

      // Verify zero AI calls
      expect(spyAi.summarizeFindingsCallCount, equals(0));
      expect(spyAi.getNextQuestionCallCount, equals(0));
    });

    // ── Test 7: Synthesis available for ordinary unpaused case ───────────────
    testWidgets('7. Synthesis action is visible and succeeds for ordinary unpaused case',
        (tester) async {
      final fakeRepo = FakeCaseRepository();
      final spyAi = SpyInvestigatorService();
      final unpausedCase = CaseModel(
        id: 'test_unpaused_case',
        caseNumber: 'SESSION 01',
        title: 'Normal Case',
        incidentDescription: 'Active session',
        currentStage: CaseStage.incident,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPausedForSafety: false,
        statements: [
          Statement(
            id: 'stmt_user_normal',
            text: 'I felt anxious during my presentation today',
            speaker: StatementSpeaker.user,
            timestamp: DateTime.now(),
          ),
        ],
      );
      fakeRepo.savedCase = unpausedCase;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            caseRepositoryProvider.overrideWithValue(fakeRepo),
            investigatorServiceProvider.overrideWithValue(spyAi),
            activeCaseControllerProvider.overrideWith(
              () => TestActiveCaseController(unpausedCase),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: LiveDialogueView(caseModel: unpausedCase),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final strings = AppStrings('en');
      // Synthesis action must be present for active case with user messages
      expect(find.text(strings.saveTakeawayReportBtn), findsOneWidget);
      expect(find.text(strings.suggestedReplySaveTakeaway), findsOneWidget);

      // Tap synthesis button
      await tester.tap(find.text(strings.saveTakeawayReportBtn));
      await tester.pumpAndSettle();

      // Exactly 1 AI summary call executed
      expect(spyAi.summarizeFindingsCallCount, equals(1));
    });

    // ── Test 11: Dismissing medical dialog does not re-enable synthesis ───────
    testWidgets('11. Dismissing medical dialog does not re-enable synthesis',
        (tester) async {
      final fakeRepo = FakeCaseRepository();
      final spyAi = SpyInvestigatorService();
      final initialCase = CaseModel(
        id: 'test_case_dismiss',
        caseNumber: 'SESSION 01',
        title: 'Accidental Ingestion Test',
        incidentDescription: 'Active session',
        currentStage: CaseStage.incident,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      fakeRepo.savedCase = initialCase;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            caseRepositoryProvider.overrideWithValue(fakeRepo),
            investigatorServiceProvider.overrideWithValue(spyAi),
            activeCaseControllerProvider.overrideWith(
              () => TestActiveCaseController(initialCase),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: LiveDialogueView(caseModel: initialCase),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final inputField = find.byType(TextField);
      await tester.enterText(
        inputField,
        'I accidentally took more medication than prescribed.',
      );
      await tester.pumpAndSettle();

      final sendButton = find.byType(MindPressable).last;
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      final strings = AppStrings('en');
      expect(find.text(strings.accidentalOverdoseTitle), findsOneWidget);

      // Dismiss dialog via Return to case
      await tester.tap(find.text(strings.returnToCaseBtn));
      await tester.pumpAndSettle();

      expect(find.text(strings.accidentalOverdoseTitle), findsNothing);

      // Synthesis must remain hidden
      expect(find.text(strings.saveTakeawayReportBtn), findsNothing);
      expect(find.text(strings.suggestedReplySaveTakeaway), findsNothing);
      expect(spyAi.summarizeFindingsCallCount, equals(0));

      // Input field remains disabled
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    // ── Test 12: Navigation and rebuilds do not bypass pause ──────────────────
    testWidgets('12. Navigation and widget rebuilds do not bypass the safety pause',
        (tester) async {
      final fakeRepo = FakeCaseRepository();
      final spyAi = SpyInvestigatorService();
      final pausedCase = CaseModel(
        id: 'test_rebuild_case',
        caseNumber: 'SESSION 01',
        title: 'Safety Paused Case',
        incidentDescription: 'Active session',
        currentStage: CaseStage.incident,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPausedForSafety: true,
        statements: [
          Statement(
            id: 'stmt_user',
            text: 'I took extra medication by mistake',
            speaker: StatementSpeaker.user,
            timestamp: DateTime.now(),
          ),
        ],
      );
      fakeRepo.savedCase = pausedCase;

      final controller = TestActiveCaseController(pausedCase);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            caseRepositoryProvider.overrideWithValue(fakeRepo),
            investigatorServiceProvider.overrideWithValue(spyAi),
            activeCaseControllerProvider.overrideWith(() => controller),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: LiveDialogueView(caseModel: pausedCase),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final strings = AppStrings('en');
      expect(find.text(strings.saveTakeawayReportBtn), findsNothing);

      // Simulate a route change or complete widget tree rebuild
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            caseRepositoryProvider.overrideWithValue(fakeRepo),
            investigatorServiceProvider.overrideWithValue(spyAi),
            activeCaseControllerProvider.overrideWith(() => controller),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox.expand(
                child: LiveDialogueView(caseModel: pausedCase),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // State remains strictly fail-closed
      expect(find.text(strings.saveTakeawayReportBtn), findsNothing);
      expect(find.text(strings.suggestedReplySaveTakeaway), findsNothing);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
      expect(spyAi.summarizeFindingsCallCount, equals(0));
      expect(spyAi.getNextQuestionCallCount, equals(0));
    });

    // ── Test 13a: Missing or unavailable active case blocks synthesis ────────
    testWidgets('13a. Missing or unavailable active case blocks synthesis and yields zero AI calls',
        (tester) async {
      final fakeRepo = FakeCaseRepository();
      final spyAi = SpyInvestigatorService();
      final normalCase = CaseModel(
        id: 'test_normal_case',
        caseNumber: 'SESSION 01',
        title: 'Normal Case',
        incidentDescription: 'Active session',
        currentStage: CaseStage.incident,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPausedForSafety: false,
        statements: [
          Statement(
            id: 'stmt_user_normal',
            text: 'I felt overwhelmed at work today',
            speaker: StatementSpeaker.user,
            timestamp: DateTime.now(),
          ),
        ],
      );

      // Provide null active case (simulating uninitialized or loading state)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            caseRepositoryProvider.overrideWithValue(fakeRepo),
            investigatorServiceProvider.overrideWithValue(spyAi),
            activeCaseControllerProvider.overrideWith(
              () => TestActiveCaseController(null),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: LiveDialogueView(caseModel: normalCase),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final strings = AppStrings('en');
      // Synthesis must be blocked/hidden when active case is unavailable
      expect(find.text(strings.saveTakeawayReportBtn), findsNothing);
      expect(find.text(strings.suggestedReplySaveTakeaway), findsNothing);
      expect(spyAi.summarizeFindingsCallCount, equals(0));
    });

    // ── Test 13b: Stale unpaused widget data cannot override a paused active state
    testWidgets('13b. Stale unpaused widget data cannot override a paused active state',
        (tester) async {
      final fakeRepo = FakeCaseRepository();
      final spyAi = SpyInvestigatorService();

      // Stale widget model that thinks it is unpaused
      final staleWidgetCase = CaseModel(
        id: 'case_1',
        caseNumber: 'SESSION 01',
        title: 'Stale Case',
        incidentDescription: 'Active session',
        currentStage: CaseStage.incident,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPausedForSafety: false,
        statements: [
          Statement(
            id: 'stmt_1',
            text: 'I feel stressed',
            speaker: StatementSpeaker.user,
            timestamp: DateTime.now(),
          ),
        ],
      );

      // Real active case in controller is paused
      final realActivePausedCase = staleWidgetCase.copyWith(
        isPausedForSafety: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            caseRepositoryProvider.overrideWithValue(fakeRepo),
            investigatorServiceProvider.overrideWithValue(spyAi),
            activeCaseControllerProvider.overrideWith(
              () => TestActiveCaseController(realActivePausedCase),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: LiveDialogueView(caseModel: staleWidgetCase),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final strings = AppStrings('en');
      // Synthesis must be hidden based on the active controller state, ignoring stale widget data
      expect(find.text(strings.saveTakeawayReportBtn), findsNothing);
      expect(find.text(strings.suggestedReplySaveTakeaway), findsNothing);
      expect(spyAi.summarizeFindingsCallCount, equals(0));
    });

    // ── Test 14: Hydration restores pause from persisted urgent safety statement ──
    test('14. Persisted urgent safety statement with missing pause flag restores safety pause on hydration',
        () async {
      final fakeRepo = FakeCaseRepository();
      // Case on disk has isPausedForSafety: false (simulating failed pause write),
      // but statements list contains a Level 2 imminent crisis statement
      final caseWithUnpausedCrisis = CaseModel(
        id: 'persisted_crisis_case',
        caseNumber: 'SESSION 01',
        title: 'Crisis Case',
        incidentDescription: 'Active session',
        currentStage: CaseStage.incident,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPausedForSafety: false,
        statements: [
          Statement(
            id: 'stmt_crisis',
            text: "I don't want to die, but I've decided to take all my medication.",
            speaker: StatementSpeaker.user,
            timestamp: DateTime.now(),
          ),
        ],
      );
      fakeRepo.savedCase = caseWithUnpausedCrisis;

      final container = ProviderContainer(
        overrides: [
          caseRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeCaseControllerProvider.notifier);
      final hydratedCase = await notifier.ensureHydrated();

      expect(hydratedCase, isNotNull);
      // Safety pause MUST be restored offline
      expect(hydratedCase!.isPausedForSafety, isTrue);
      expect(container.read(activeCaseControllerProvider).value?.isPausedForSafety, isTrue);
      // Disk state healed
      expect(fakeRepo.savedCase?.isPausedForSafety, isTrue);
    });

    // ── Test 15: Hydration restores pause from persisted accidental ingestion ──
    test('15. Persisted accidental ingestion with missing pause flag restores safety pause on hydration',
        () async {
      final fakeRepo = FakeCaseRepository();
      final caseWithAccidentalIngestion = CaseModel(
        id: 'persisted_accidental_case',
        caseNumber: 'SESSION 01',
        title: 'Accidental Ingestion Case',
        incidentDescription: 'Active session',
        currentStage: CaseStage.incident,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPausedForSafety: false,
        statements: [
          Statement(
            id: 'stmt_accidental',
            text: 'I accidentally took more medication than prescribed.',
            speaker: StatementSpeaker.user,
            timestamp: DateTime.now(),
          ),
        ],
      );
      fakeRepo.savedCase = caseWithAccidentalIngestion;

      final container = ProviderContainer(
        overrides: [
          caseRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeCaseControllerProvider.notifier);
      final hydratedCase = await notifier.ensureHydrated();

      expect(hydratedCase, isNotNull);
      expect(hydratedCase!.isPausedForSafety, isTrue);
      expect(container.read(activeCaseControllerProvider).value?.isPausedForSafety, isTrue);
    });

    // ── Test 16: Hydration does NOT pause for ordinary intrusive thoughts ──
    test('16. Persisted ordinary intrusive thoughts do not trigger an emergency pause on hydration',
        () async {
      final fakeRepo = FakeCaseRepository();
      final caseWithIntrusiveThought = CaseModel(
        id: 'persisted_intrusive_case',
        caseNumber: 'SESSION 01',
        title: 'Intrusive Thought Case',
        incidentDescription: 'Active session',
        currentStage: CaseStage.incident,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPausedForSafety: false,
        statements: [
          Statement(
            id: 'stmt_intrusive',
            text: 'I have intrusive thoughts about swallowing pills, but I do not want to do it.',
            speaker: StatementSpeaker.user,
            timestamp: DateTime.now(),
          ),
        ],
      );
      fakeRepo.savedCase = caseWithIntrusiveThought;

      final container = ProviderContainer(
        overrides: [
          caseRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeCaseControllerProvider.notifier);
      final hydratedCase = await notifier.ensureHydrated();

      expect(hydratedCase, isNotNull);
      // Ordinary intrusive thoughts MUST NOT trigger emergency pause
      expect(hydratedCase!.isPausedForSafety, isFalse);
      expect(container.read(activeCaseControllerProvider).value?.isPausedForSafety, isFalse);
    });

    // ── Test 17: Hydration does not reactivate completed historical cases ──
    test('17. Completed historical cases are not hydrated as active sessions',
        () async {
      final fakeRepo = FakeCaseRepository();
      final completedCrisisCase = CaseModel(
        id: 'completed_crisis_case',
        caseNumber: 'SESSION 01',
        title: 'Old Concluded Case',
        incidentDescription: 'Past session',
        currentStage: CaseStage.conclusion,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        isCompleted: true,
        isPausedForSafety: true,
        statements: [
          Statement(
            id: 'stmt_old',
            text: 'I took pills to hurt myself',
            speaker: StatementSpeaker.user,
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
      );
      fakeRepo.savedCase = completedCrisisCase;

      final container = ProviderContainer(
        overrides: [
          caseRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeCaseControllerProvider.notifier);
      final hydratedCase = await notifier.ensureHydrated();

      // Completed case is not hydrated as active session
      expect(hydratedCase, isNull);
      expect(container.read(activeCaseControllerProvider).value, isNull);
    });

    // ── Test 18: Zero AI calls during hydration and synthesis blocked post-hydration ──
    testWidgets('18. Zero AI/network calls during hydration and synthesis blocked post-hydration',
        (tester) async {
      final fakeRepo = FakeCaseRepository();
      final spyAi = SpyInvestigatorService();
      final caseWithAccidental = CaseModel(
        id: 'hydrate_accidental_case',
        caseNumber: 'SESSION 01',
        title: 'Accidental Ingestion Test',
        incidentDescription: 'Active session',
        currentStage: CaseStage.incident,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPausedForSafety: false,
        statements: [
          Statement(
            id: 'stmt_accidental',
            text: 'I accidentally took more medication than prescribed.',
            speaker: StatementSpeaker.user,
            timestamp: DateTime.now(),
          ),
        ],
      );
      fakeRepo.savedCase = caseWithAccidental;

      final container = ProviderContainer(
        overrides: [
          caseRepositoryProvider.overrideWithValue(fakeRepo),
          investigatorServiceProvider.overrideWithValue(spyAi),
        ],
      );
      addTearDown(container.dispose);

      // Hydrate
      final notifier = container.read(activeCaseControllerProvider.notifier);
      final hydratedCase = await notifier.ensureHydrated();
      expect(hydratedCase?.isPausedForSafety, isTrue);

      // Zero AI calls made during hydration
      expect(spyAi.getNextQuestionCallCount, equals(0));
      expect(spyAi.generateHypothesesCallCount, equals(0));
      expect(spyAi.generateCrossExaminationCallCount, equals(0));
      expect(spyAi.summarizeFindingsCallCount, equals(0));

      // Now render LiveDialogueView with this container
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: LiveDialogueView(caseModel: hydratedCase!),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final strings = AppStrings('en');
      // Synthesis actions must remain blocked post-hydration
      expect(find.text(strings.saveTakeawayReportBtn), findsNothing);
      expect(find.text(strings.suggestedReplySaveTakeaway), findsNothing);
      expect(spyAi.summarizeFindingsCallCount, equals(0));
    });

    // ── Test 8: Intentional harmful ingestion emergency route ─────────────────
    test('8. Intentional harmful ingestion follows immediateMedicalEmergency route, not accidental', () {
      const intentionalPhrases = [
        'I took pills to hurt myself',
        'swallowed all my pills to harm myself',
        'chrabt dweyet bch nmout',
        'J’ai pris des médicaments pour me faire du mal',
      ];

      for (final text in intentionalPhrases) {
        final classification = CrisisKeywords.classifyText(text);
        expect(
          classification,
          equals(SafetyClassification.immediateMedicalEmergency),
          reason: 'Intentional harm must classify as immediateMedicalEmergency: $text',
        );
        expect(
          classification == SafetyClassification.accidentalIngestionAlert,
          isFalse,
        );
      }
    });

    // ── Test 9: Unwanted intrusive thoughts do not trigger accidental route ───
    test('9. Unwanted intrusive thoughts decouple and do not trigger accidental ingestion route', () {
      const intrusiveInputs = [
        'I keep having intrusive thoughts about swallowing pills.',
        'I have intrusive thoughts about swallowing pills.',
        'J’ai des pensées intrusives qui me disent d’avaler des pilules.',
        'أفكار اقتحامية تتردد في راسي عن شرب دواء.',
        'afkar i9ti7amia bch nochrob dwe.',
      ];

      for (final text in intrusiveInputs) {
        final classification = CrisisKeywords.classifyText(text);
        expect(
          classification,
          equals(SafetyClassification.unwantedIntrusiveThoughts),
          reason: 'Intrusive thoughts must classify as unwantedIntrusiveThoughts: $text',
        );
        expect(
          classification == SafetyClassification.accidentalIngestionAlert,
          isFalse,
          reason: 'Intrusive thoughts must not trigger accidental ingestion alert: $text',
        );
      }
    });

    // ── Test 10: Normal prescribed medication statements unaffected ───────────
    test('10. Normal prescribed medication statements remain classified as normal', () {
      const normalMedicationInputs = [
        'I took my prescribed medication with breakfast this morning.',
        'Took my blood pressure pill as directed by my doctor.',
        'J’ai pris mon médicament habituel à midi.',
        'chrabt dweya mta3 essbe7 3adi',
      ];

      for (final text in normalMedicationInputs) {
        final classification = CrisisKeywords.classifyText(text);
        expect(
          classification,
          equals(SafetyClassification.normal),
          reason: 'Normal medication taking must classify as normal: $text',
        );
        expect(
          classification == SafetyClassification.accidentalIngestionAlert,
          isFalse,
        );
      }
    });
  });
}
