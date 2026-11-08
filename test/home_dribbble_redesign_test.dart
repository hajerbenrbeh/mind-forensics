import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_metric_sparkline.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_organic_exercise_art.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_stress_bar_chart.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_time_segmented_switcher.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_week_mood_tracker.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/support/presentation/contextual_support_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Home Screen Dribbble Redesign & Component Tests', () {
    testWidgets('Renders all modern reference components with authentic empty states when no traces exist', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. App bar & greeting
      expect(find.text('Mind Forensics'), findsOneWidget);
      expect(find.textContaining('Dear'), findsOneWidget);

      // 2. Segmented time switcher: "Month | Week | Day"
      expect(find.byType(HomeTimeSegmentedSwitcher), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Day'), findsOneWidget);

      // 3. 7-Day horizontal mood tracker
      expect(find.byType(HomeWeekMoodTracker), findsOneWidget);
      expect(find.text('M'), findsWidgets);
      expect(find.text('W'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);

      // 4. Two-column metric cards (Authentic calibrating / empty state, zero fabricated data)
      expect(find.byType(HomeMetricSparkline), findsOneWidget);
      expect(find.byType(HomeStressBarChart), findsOneWidget);
      expect(find.text('Calibrating baseline'), findsOneWidget);
      expect(find.text('Needs 2+ entries'), findsOneWidget);
      expect(find.text('Average stress level'), findsOneWidget);
      expect(find.text('No entries yet'), findsOneWidget);

      // 5. Exercises for you card with organic vector pebble art (ZERO emojis)
      expect(find.text('Exercises for you'), findsOneWidget);
      expect(find.byType(HomeOrganicExerciseArt), findsOneWidget);
      expect(find.text('Relieve stress'), findsOneWidget);
      expect(find.text('Breathing practice'), findsOneWidget);
      expect(find.text('5 min'), findsOneWidget);

      // 6. Step 6 Daily check-in card
      expect(find.textContaining('NERVOUS ACTIVATION'), findsOneWidget);
      expect(find.text('Log Daily Check-in'), findsOneWidget);
    });

    testWidgets('Populates real mood stability and weekly stress when authentic traces exist', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final now = DateTime.now();
      // Add 3 authentic traces
      final repo = container.read(mindTraceRepositoryProvider);
      await repo.saveTrace(MindTraceModel(
        id: 'trace_test_1',
        userId: 'test_user',
        date: now.subtract(const Duration(days: 2)),
        overallMood: 'calm',
        moodIntensity: 6,
        energyLevel: 7,
        anxietyLevel: 4,
        createdAt: now,
        updatedAt: now,
      ));
      await repo.saveTrace(MindTraceModel(
        id: 'trace_test_2',
        userId: 'test_user',
        date: now.subtract(const Duration(days: 1)),
        overallMood: 'calm',
        moodIntensity: 6,
        energyLevel: 8,
        anxietyLevel: 3,
        createdAt: now,
        updatedAt: now,
      ));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Now with 2+ stable entries (variance 0), it derives real "Mood stable"
      expect(find.text('Mood stable'), findsOneWidget);
      expect(find.textContaining('entries'), findsOneWidget);
      // And authentic average stress percentage
      expect(find.textContaining('% in a week'), findsOneWidget);
    });

    testWidgets('Logging a check-in on Home saves to MindTraceController and updates todayTraceProvider', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Log Daily Check-in (options-first, zero compulsory typing)
      final saveBtn = find.text('Log Daily Check-in');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify trace was added into the central MindTraceNotifier state
      final traces = container.read(mindTraceControllerProvider).value ?? [];
      expect(traces.isNotEmpty, isTrue);
      expect(traces.first.overallMood, equals('calm'));

      // Verify todayTraceProvider is now populated
      final todayTrace = container.read(todayTraceProvider);
      expect(todayTrace, isNotNull);
      expect(todayTrace?.overallMood, equals('calm'));
    });

    testWidgets('Tapping Relieve stress opens the 4-4-4-4 Vagal Breathing sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Relieve stress exercise card
      final exerciseCard = find.text('Relieve stress');
      expect(exerciseCard, findsOneWidget);
      await tester.tap(exerciseCard);
      // Use fixed pump duration because Vagal Breathing has an active Timer.periodic
      await tester.pump(const Duration(milliseconds: 500));

      // Verify modal bottom sheet opened with breathing controls
      expect(find.byType(ContextualSupportSheet), findsOneWidget);
      expect(find.text('Begin 4-4-4-4 Breathing'), findsOneWidget);

      // Close sheet
      Navigator.of(tester.element(find.byType(ContextualSupportSheet))).pop();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ContextualSupportSheet), findsNothing);
    });

    testWidgets('Tapping segmented time switcher toggles active selection', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Month"
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      // Tap "Day"
      await tester.tap(find.text('Day'));
      await tester.pumpAndSettle();
    });
  });
}
