import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/home/presentation/widgets/exercise_breathing_modal_sheet.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_week_mood_tracker.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const outputDir = r'C:\Users\HAJER\.gemini\antigravity\brain\100c2c6a-b7d8-4885-b5e6-8d8002edd3bd\screenshots';

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> saveScreenshot(WidgetTester tester, GlobalKey repaintKey, String filename) async {
    await tester.runAsync(() async {
      final boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final outPath = '$outputDir\\$filename';
      final file = File(outPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(pngBytes);
    });
  }

  group('Visual Screenshot Capture Suite', () {
    testWidgets('Capture 1: Home Screen in Light Mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final now = DateTime.now();
      final repo = container.read(mindTraceRepositoryProvider);
      await repo.saveTrace(MindTraceModel(
        id: 'trace_1',
        userId: 'test_user',
        date: now.subtract(const Duration(days: 2)),
        overallMood: 'calm',
        moodIntensity: 6,
        energyLevel: 8,
        anxietyLevel: 3,
        createdAt: now,
        updatedAt: now,
      ));
      await repo.saveTrace(MindTraceModel(
        id: 'trace_2',
        userId: 'test_user',
        date: now.subtract(const Duration(days: 1)),
        overallMood: 'calm',
        moodIntensity: 7,
        energyLevel: 7,
        anxietyLevel: 4,
        createdAt: now,
        updatedAt: now,
      ));

      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: LabTheme.daylightTheme,
            home: RepaintBoundary(
              key: repaintKey,
              child: const HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await saveScreenshot(tester, repaintKey, '01_home_screen_light.png');
    });

    testWidgets('Capture 2: Home Screen in Dark Mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final now = DateTime.now();
      final repo = container.read(mindTraceRepositoryProvider);
      await repo.saveTrace(MindTraceModel(
        id: 'trace_1',
        userId: 'test_user',
        date: now.subtract(const Duration(days: 2)),
        overallMood: 'calm',
        moodIntensity: 6,
        energyLevel: 8,
        anxietyLevel: 3,
        createdAt: now,
        updatedAt: now,
      ));

      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: LabTheme.nightTheme,
            home: RepaintBoundary(
              key: repaintKey,
              child: const HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await saveScreenshot(tester, repaintKey, '02_home_screen_dark.png');
    });

    testWidgets('Capture 3: Daily Check-in Card (Step 6 Detail)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: LabTheme.daylightTheme,
            home: RepaintBoundary(
              key: repaintKey,
              child: const HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to display the Daily Check-in card and save button
      await tester.drag(find.byType(HomeScreen), const Offset(0, -350));
      await tester.pumpAndSettle();

      await saveScreenshot(tester, repaintKey, '03_daily_checkin_detail.png');
    });

    testWidgets('Capture 4: 4-4-4-4 Vagal Breathing Modal Sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          theme: LabTheme.daylightTheme,
          home: Scaffold(
            backgroundColor: const Color(0xFFF7F8F5),
            body: Center(
              child: RepaintBoundary(
                key: repaintKey,
                child: const ExerciseBreathingModalSheet(strings: AppStrings('en')),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await saveScreenshot(tester, repaintKey, '04_breathing_exercise_sheet.png');
    });

    testWidgets('Capture 5: Weekly Mood Visualization Component', (tester) async {
      tester.view.physicalSize = const Size(1080, 600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final repaintKey = GlobalKey();
      final now = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          theme: LabTheme.daylightTheme,
          home: Scaffold(
            backgroundColor: const Color(0xFFF7F8F5),
            body: Center(
              child: RepaintBoundary(
                key: repaintKey,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  color: Colors.white,
                  child: HomeWeekMoodTracker(
                    selectedDay: now,
                    recordedMoodDays: {
                      '${now.year}-${now.month.toString().padLeft(2, '0')}-${(now.day - 2).toString().padLeft(2, '0')}': const Color(0xFF91AD9A),
                      '${now.year}-${now.month.toString().padLeft(2, '0')}-${(now.day - 1).toString().padLeft(2, '0')}': const Color(0xFFFB7185),
                      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}': const Color(0xFFA78BFA),
                    },
                    onDaySelected: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await saveScreenshot(tester, repaintKey, '05_weekly_mood_tracker.png');
    });
  });
}
