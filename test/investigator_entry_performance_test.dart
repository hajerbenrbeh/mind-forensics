import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/data/local_case_repository.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/conversation_mode.dart';
import 'package:mind_forensics/features/investigation/domain/label_type.dart';
import 'package:mind_forensics/features/investigation/domain/statement.dart';
import 'package:mind_forensics/features/investigation/presentation/flash_case_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Investigator Entry Performance & Stabilization Suite', () {
    testWidgets('1. FlashCaseScreen renders dialogue immediately without Hub flicker',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashCaseScreen(),
          ),
        ),
      );

      // On the initial frame before long async settles, Hub view should NOT be shown
      expect(find.text('AI HUB'), findsNothing);
      expect(find.text('6 MODES'), findsNothing);

      await tester.pumpAndSettle();

      // Dialogue is smoothly active
      expect(find.text('AI GUIDE'), findsAtLeastNWidgets(1));
      expect(find.text('Talk with your companion...'), findsOneWidget);
      expect(find.text('AI HUB'), findsNothing);
    });

    testWidgets('2. No layout overflow near Session label on narrow viewport (320px)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      FlutterErrorDetails? caughtError;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.toString().contains('overflowed')) {
          caughtError = details;
        }
        originalOnError?.call(details);
      };

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashCaseScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(caughtError, isNull, reason: 'Expected zero layout overflows near Session label');
      expect(find.text('AI GUIDE'), findsAtLeastNWidgets(1));
      expect(find.text('SESSION 01'), findsOneWidget);
    });

    testWidgets('3. Repeated navigation preserves active investigation without duplicate sessions',
        (WidgetTester tester) async {
      final repo = LocalCaseRepository();
      final container = ProviderContainer(
        overrides: [
          caseRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final initialCase = await container
          .read(activeCaseControllerProvider.notifier)
          .startNewCase('First incident exploration');

      expect(initialCase.caseNumber, equals('SESSION 01'));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: FlashCaseScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final currentCase = container.read(activeCaseControllerProvider).value;
      expect(currentCase?.id, equals(initialCase.id));
      expect(currentCase?.caseNumber, equals('SESSION 01'));

      final allCases = await repo.getAllCases();
      expect(allCases.length, equals(1));
    });

    testWidgets('4. Hub view is explicitly toggled by user and returns to active session',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FlashCaseScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Talk with your companion...'), findsOneWidget);
      expect(find.text('AI HUB'), findsNothing);

      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pumpAndSettle();

      expect(find.text('AI HUB'), findsOneWidget);
      expect(find.text('6 MODES'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Talk with your companion...'), findsOneWidget);
      expect(find.text('AI HUB'), findsNothing);
    });

    test('5. Session numbering lock guarantees unique IDs under concurrent rapid creation',
        () async {
      final repo = LocalCaseRepository();

      // Launch 5 concurrent requests simultaneously in the exact same event tick
      final results = await Future.wait([
        repo.getNextCaseNumber(),
        repo.getNextCaseNumber(),
        repo.getNextCaseNumber(),
        repo.getNextCaseNumber(),
        repo.getNextCaseNumber(),
      ]);

      expect(results, equals([
        'SESSION 01',
        'SESSION 02',
        'SESSION 03',
        'SESSION 04',
        'SESSION 05',
      ]));

      // Verify all 5 are distinct
      final uniqueSet = results.toSet();
      expect(uniqueSet.length, equals(5));
    });

    test('6. Session numbering continuity across fresh repository instances (app restarts)',
        () async {
      // Simulate Session 01 and Session 02 in initial instance
      final repo1 = LocalCaseRepository();
      final n1 = await repo1.getNextCaseNumber();
      final n2 = await repo1.getNextCaseNumber();
      expect(n1, equals('SESSION 01'));
      expect(n2, equals('SESSION 02'));

      // Simulate app kill and cold restart: brand new instance of LocalCaseRepository
      final repo2 = LocalCaseRepository();
      final n3 = await repo2.getNextCaseNumber();
      expect(n3, equals('SESSION 03'));
    });

    testWidgets('7. Hydration restores active uncompleted case with historical statements intact',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final historicalCase = CaseModel(
        id: 'historical-active-case-001',
        userId: 'test_user',
        caseNumber: 'SESSION 07',
        title: 'Preserved Ongoing Case',
        conversationMode: ConversationMode.psychologicalAnalysis,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        currentStage: CaseStage.evidence,
        incidentDescription: 'Original incident text',
        sessionSummary: 'SESSION PROGRESSION: User explored cognitive distortions.',
        statements: [
          Statement(
            id: 'stmt-001',
            text: 'I felt overwhelmed during the review.',
            speaker: StatementSpeaker.user,
            label: LabelType.assumption,
            timestamp: now.subtract(const Duration(hours: 2)),
          ),
          Statement(
            id: 'stmt-002',
            text: 'What facts support that feeling?',
            speaker: StatementSpeaker.investigator,
            timestamp: now.subtract(const Duration(hours: 2, minutes: 58)),
          ),
        ],
      );

      final repo = LocalCaseRepository();
      await repo.saveCase(historicalCase);

      final container = ProviderContainer(
        overrides: [
          caseRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      // Mount FlashCaseScreen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: FlashCaseScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify active investigation was hydrated without creating a new blank case
      final active = container.read(activeCaseControllerProvider).value;
      expect(active, isNotNull);
      expect(active!.id, equals(historicalCase.id));
      expect(active.caseNumber, equals('SESSION 07'));
      expect(active.title, equals('Preserved Ongoing Case'));
      expect(active.sessionSummary, equals(historicalCase.sessionSummary));
      expect(active.statements.length, equals(2));
      expect(active.statements.first.text, equals('I felt overwhelmed during the review.'));

      // Verify the screen displays the historical statement
      expect(find.text('I felt overwhelmed during the review.'), findsOneWidget);
      expect(find.text('SESSION 07'), findsOneWidget);

      // Verify no duplicate cases were written to repository
      final allCases = await repo.getAllCases();
      expect(allCases.length, equals(1));
    });

    testWidgets('8. Measured render latency benchmarks for initial mount and re-entry',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Benchmark 1: First entry mount time
      final initialStopwatch = Stopwatch()..start();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: FlashCaseScreen(),
          ),
        ),
      );
      final firstFrameElapsedMs = initialStopwatch.elapsedMilliseconds;
      await tester.pumpAndSettle();
      final totalInitialSettleMs = initialStopwatch.elapsedMilliseconds;
      initialStopwatch.stop();

      // Simulate navigating away to Home
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: Text('Home Screen')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Benchmark 2: Re-entry mount time back into FlashCaseScreen
      final reEntryStopwatch = Stopwatch()..start();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: FlashCaseScreen(),
          ),
        ),
      );
      final reEntryFirstFrameMs = reEntryStopwatch.elapsedMilliseconds;
      await tester.pumpAndSettle();
      final totalReEntrySettleMs = reEntryStopwatch.elapsedMilliseconds;
      reEntryStopwatch.stop();

      // Log verified measured timings
      debugPrint('[PERF MEASUREMENT] Initial mount Frame 1: ${firstFrameElapsedMs}ms, Settle: ${totalInitialSettleMs}ms');
      debugPrint('[PERF MEASUREMENT] Re-entry mount Frame 1: ${reEntryFirstFrameMs}ms, Settle: ${totalReEntrySettleMs}ms');

      // Both initial and re-entry first frames must render within responsive test execution thresholds (<450ms)
      expect(firstFrameElapsedMs, lessThan(450));
      expect(reEntryFirstFrameMs, lessThan(450));
    });
  });
}
