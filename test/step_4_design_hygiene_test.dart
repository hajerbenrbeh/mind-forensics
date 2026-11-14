import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/router/app_router.dart';
import 'package:mind_forensics/app/theme/lab_colors.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/core/widgets/mind_pressable.dart';
import 'package:mind_forensics/core/widgets/neural_waveform_visualizer.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_daily_check_in_card.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

double _contrastRatio(Color foreground, Color background) {
  final l1 = foreground.computeLuminance();
  final l2 = background.computeLuminance();
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Step 4 Design Token Hygiene, Typography & Motion Tests', () {
    test('LabTheme styles rely strictly on bundled Inter with no serif/monospace fallbacks', () {
      expect(LabTheme.serifStyle().fontFamily, equals('Inter'));
      expect(LabTheme.editorialSerif().fontFamily, equals('Inter'));
      expect(LabTheme.monoStyle().fontFamily, equals('Inter'));
      expect(LabTheme.daylightTheme.textTheme.bodyMedium?.fontFamily, equals('Inter'));
      expect(LabTheme.nightTheme.textTheme.bodyMedium?.fontFamily, equals('Inter'));
      expect(LabTheme.daylightTheme.textTheme.bodyMedium?.height, equals(1.5));
      expect(LabTheme.nightTheme.textTheme.bodyMedium?.height, equals(1.5));
    });

    test('MindTokens light and dark text/safety pairs meet WCAG AA (>= 4.5:1)', () {
      const light = MindTokens.light;
      const dark = MindTokens.dark;

      // Light surfaces
      expect(_contrastRatio(light.textPrimary, light.background), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(light.textSecondary, light.background), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(light.textSecondary, light.surfaceSecondary), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(light.textTertiary, light.background), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(light.textTertiary, light.surfaceSecondary), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(light.accent, light.accentSoft), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(light.safetyWarmth, light.safetyWarmthSoft), greaterThanOrEqualTo(4.5));

      // Dark surfaces
      expect(_contrastRatio(dark.textPrimary, dark.background), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(dark.textSecondary, dark.surface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(dark.textSecondary, dark.surfaceSecondary), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(dark.textTertiary, dark.surface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(dark.textTertiary, dark.surfaceSecondary), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(dark.accent, dark.accentSoft), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(dark.safetyWarmth, dark.safetyWarmthSoft), greaterThanOrEqualTo(4.5));
    });

    testWidgets('MindPressable applies organic scale+opacity motion and honors reduced motion', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: MindPressable(
                semanticLabel: 'Calm Press',
                onPressed: () => tapped = true,
                child: const SizedBox(width: 120, height: 48, child: Center(child: Text('Tap'))),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaleWidget = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      final opacityWidget = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      expect(scaleWidget.duration, equals(Duration.zero));
      expect(opacityWidget.duration, equals(Duration.zero));

      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('HomeDailyCheckInCard omits NeuralWaveformVisualizer and navigates VIEW to /track', (tester) async {
      final now = DateTime.now();
      final todayTrace = MindTraceModel(
        id: 't_today',
        userId: 'u1',
        date: now,
        overallMood: 'calm',
        moodIntensity: 7,
        energyLevel: 7,
        anxietyLevel: 3,
        createdAt: now,
        updatedAt: now,
      );

      final router = GoRouter(
        initialLocation: '/card',
        routes: [
          GoRoute(
            path: '/card',
            builder: (context, state) => Scaffold(
              body: HomeDailyCheckInCard(
                tokens: MindTokens.light,
                strings: const AppStrings('en'),
                isDark: false,
                todayTrace: todayTrace,
                traces: [todayTrace],
                selectedMoodIndex: 0,
                moodIntensity: 7,
                todayNoteController: TextEditingController(),
                moodOptions: const [
                  (key: 'calm', icon: Icons.spa_outlined),
                  (key: 'anxious', icon: Icons.bolt_outlined),
                  (key: 'frustrated', icon: Icons.local_fire_department_outlined),
                  (key: 'heavy', icon: Icons.grain_outlined),
                  (key: 'restless', icon: Icons.air_outlined),
                ],
                onMoodSelected: (_) {},
                onIntensityChanged: (_) {},
                onSave: () {},
                getMoodLabel: (key, s) => switch (key) {
                  'calm' => s.moodCalm,
                  'anxious' => s.moodAnxious,
                  'frustrated' => s.moodFrustrated,
                  'heavy' => s.moodHeavy,
                  'restless' => s.moodRestless,
                  _ => key,
                },
                getMoodColor: (_) => LabColors.moodCalm,
              ),
            ),
          ),
          GoRoute(
            path: AppRouter.track,
            builder: (context, state) => const Scaffold(body: Text('TRACK_DESTINATION')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.byType(NeuralWaveformVisualizer), findsNothing);
      expect(find.text('Calm'), findsOneWidget);
      expect(find.text('VIEW'), findsOneWidget);

      await tester.tap(find.text('VIEW'));
      await tester.pumpAndSettle();

      expect(find.text('TRACK_DESTINATION'), findsOneWidget);
    });

    testWidgets('HomeScreen renders cleanly at 320px width and 1.35x text scale with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const ProviderScope(
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.35)),
            child: MaterialApp(home: HomeScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Unanswered text'), findsOneWidget);
      expect(find.text('Work feedback'), findsOneWidget);
      expect(find.text('Mental overload'), findsOneWidget);
    });
  });
}

