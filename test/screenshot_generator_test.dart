import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/insights/presentation/insights_screen.dart';
import 'package:mind_forensics/features/investigation/presentation/ai_companion_hub_view.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/profile/controllers/profile_controller.dart';
import 'package:mind_forensics/features/profile/domain/condition_type.dart';
import 'package:mind_forensics/features/profile/domain/diagnostic_status.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:mind_forensics/features/profile/presentation/psychological_profile_screen.dart';
import 'package:mind_forensics/features/track/presentation/track_screen.dart';
import 'package:mind_forensics/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const outputDirArtifacts = r'C:\Users\HAJER\.gemini\antigravity\brain\100c2c6a-b7d8-4885-b5e6-8d8002edd3bd\screenshots';
  final outputDirProject = Directory('screenshots/vqa_phase2').absolute.path;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;

    // Load local Inter fonts into Flutter's FontLoader for real text rendering
    final interLoader = FontLoader('Inter');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final f = File('assets/fonts/Inter-$weight.ttf');
      if (f.existsSync()) {
        interLoader.addFont(f.readAsBytes().then((bytes) => ByteData.sublistView(Uint8List.fromList(bytes))));
      }
    }
    await interLoader.load();

    // Also load as 'Inter_regular' etc if google_fonts references family variations
    final gfLoader = FontLoader('Inter_regular');
    final regFile = File('assets/fonts/Inter-Regular.ttf');
    if (regFile.existsSync()) {
      gfLoader.addFont(regFile.readAsBytes().then((bytes) => ByteData.sublistView(Uint8List.fromList(bytes))));
      await gfLoader.load();
    }

    // Load MaterialIcons locally so icons render crisply instead of empty squares
    final iconFile = File('assets/fonts/MaterialIcons-Regular.otf');
    if (iconFile.existsSync()) {
      final iconLoader = FontLoader('MaterialIcons');
      iconLoader.addFont(iconFile.readAsBytes().then((bytes) => ByteData.sublistView(Uint8List.fromList(bytes))));
      await iconLoader.load();
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> saveScreenshot(WidgetTester tester, GlobalKey repaintKey, String filename) async {
    await tester.runAsync(() async {
      final boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      for (final dir in [outputDirArtifacts, outputDirProject]) {
        final outPath = '$dir\\$filename';
        final file = File(outPath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(pngBytes);
      }
    });
  }

  group('Visual Quality Assurance Suite (8 Core Screens)', () {
    // 1. Home screen — Light Mode
    testWidgets('Capture 1: Home screen — Light Mode', (tester) async {
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

    // 2. Home screen — Dark Mode
    testWidgets('Capture 2: Home screen — Dark Mode', (tester) async {
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

    // 3. Daily Check-in
    testWidgets('Capture 3: Daily Check-in', (tester) async {
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

      // Scroll down to display the Step 6 Daily Check-in card
      await tester.drag(find.byType(HomeScreen), const Offset(0, -380));
      await tester.pumpAndSettle();

      await saveScreenshot(tester, repaintKey, '03_daily_checkin.png');
    });

    // 4. Mood Tracking (TrackScreen)
    testWidgets('Capture 4: Mood Tracking', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
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
              child: const TrackScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await saveScreenshot(tester, repaintKey, '04_mood_tracking.png');
    });

    // 5. AI Companion (AiCompanionHubView)
    testWidgets('Capture 5: AI Companion', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: LabTheme.nightTheme,
            home: Scaffold(
              body: RepaintBoundary(
                key: repaintKey,
                child: const AiCompanionHubView(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await saveScreenshot(tester, repaintKey, '05_ai_companion.png');
    });

    // 6. Insights / My Progress (InsightsScreen)
    testWidgets('Capture 6: Insights / My Progress', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final now = DateTime.now();
      final repo = container.read(mindTraceRepositoryProvider);
      for (int i = 0; i < 7; i++) {
        await repo.saveTrace(MindTraceModel(
          id: 'trace_$i',
          userId: 'test_user',
          date: now.subtract(Duration(days: i)),
          overallMood: i.isEven ? 'calm' : 'anxious',
          moodIntensity: 5 + (i % 3),
          energyLevel: 6 + (i % 2),
          anxietyLevel: 3 + (i % 2),
          sleepHours: 7.0 + (i % 2),
          createdAt: now,
          updatedAt: now,
        ));
      }

      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: LabTheme.daylightTheme,
            home: RepaintBoundary(
              key: repaintKey,
              child: const InsightsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await saveScreenshot(tester, repaintKey, '06_insights_progress.png');
    });

    // 7. Psychological Profile
    testWidgets('Capture 7: Psychological Profile', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer(
        overrides: [
          profileControllerProvider.overrideWith(() {
            return _MockProfileNotifier(
              PsychologicalProfileModel(
                userId: 'test_user',
                preferredName: 'Alice',
                ageRange: '25-34',
                preferredLanguage: 'English',
                personalIntroduction: 'Exploring emotional patterns and daily somatic rhythm.',
                conditions: const [
                  UserConditionEntry(
                    condition: ConditionType.generalizedAnxiety,
                    status: DiagnosticStatus.professionallyDiagnosed,
                  ),
                ],
                updatedAt: DateTime.now(),
              ),
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: LabTheme.daylightTheme,
            home: RepaintBoundary(
              key: repaintKey,
              child: const PsychologicalProfileScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await saveScreenshot(tester, repaintKey, '07_psychological_profile.png');
    });

    // 8. Main Navigation (Floating Capsule Bottom Bar)
    testWidgets('Capture 8: Main Navigation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        RepaintBoundary(
          key: repaintKey,
          child: const ProviderScope(
            child: MindForensicsApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await saveScreenshot(tester, repaintKey, '08_main_navigation.png');
    });
  });
}

class _MockProfileNotifier extends ProfileNotifier {
  _MockProfileNotifier(this._initial);
  final PsychologicalProfileModel _initial;

  @override
  Future<PsychologicalProfileModel> build() async => _initial;
}
