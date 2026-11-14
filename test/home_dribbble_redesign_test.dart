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

  group('Home Screen Step 2 Clean & Calm Layout Tests', () {
    testWidgets('Renders clean 4-block Home without chart/switcher clutter', (tester) async {
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

      // 2. Redundant Analytics/Switchers removed from Home
      expect(find.byType(HomeTimeSegmentedSwitcher), findsNothing);
      expect(find.byType(HomeWeekMoodTracker), findsNothing);
      expect(find.byType(HomeMetricSparkline), findsNothing);
      expect(find.byType(HomeStressBarChart), findsNothing);

      // 3. Step 6 Daily check-in card (plain human affect labels + intensity, zero telemetry waveform)
      expect(find.textContaining('INTENSITY'), findsOneWidget);
      expect(find.text('Calm'), findsOneWidget);
      expect(find.text('Anxious'), findsOneWidget);
      expect(find.text('Log Daily Check-in'), findsOneWidget);

      // 4. Investigation CTA & Recent Investigations
      expect(find.text('RECENT SESSIONS'), findsOneWidget);

      // 5. Exercises for you card with organic vector pebble art (ZERO emojis)
      expect(find.text('Exercises for you'), findsOneWidget);
      expect(find.byType(HomeOrganicExerciseArt), findsOneWidget);
      expect(find.text('Relieve stress'), findsOneWidget);
      expect(find.text('Breathing practice'), findsOneWidget);
      expect(find.text('5 min'), findsOneWidget);
    });

    testWidgets('Reflects today check-in summary calmly on Home when logged', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final now = DateTime.now();
      final repo = container.read(mindTraceRepositoryProvider);
      await repo.saveTrace(MindTraceModel(
        id: 'trace_today_home',
        userId: 'test_user',
        date: now,
        overallMood: 'calm',
        moodIntensity: 7,
        energyLevel: 7,
        anxietyLevel: 3,
        journalText: 'Steady breath after afternoon walk',
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

      expect(find.textContaining('Calm (7/10)'), findsOneWidget);
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

    testWidgets('Entering optional note in Home check-in persists note to journalText', (tester) async {
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

      final noteField = find.byType(TextField);
      expect(noteField, findsOneWidget);
      await tester.ensureVisible(noteField);
      await tester.enterText(noteField, 'Felt peaceful during evening walk');
      await tester.pumpAndSettle();

      final saveBtn = find.text('Log Daily Check-in');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      final todayTrace = container.read(todayTraceProvider);
      expect(todayTrace, isNotNull);
      expect(todayTrace?.journalText, equals('Felt peaceful during evening walk'));
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
      await tester.ensureVisible(exerciseCard);
      await tester.pumpAndSettle();
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
  });
}
