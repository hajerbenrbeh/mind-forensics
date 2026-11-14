import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/router/app_router.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/insights/presentation/insights_screen.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/presentation/flash_case_screen.dart';
import 'package:mind_forensics/features/investigation/presentation/widgets/live_dialogue_view.dart';
import 'package:mind_forensics/features/journey/presentation/journey_screen.dart';
import 'package:mind_forensics/features/observatory/presentation/inner_observatory_screen.dart';
import 'package:mind_forensics/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mind_forensics/features/settings/presentation/settings_screen.dart';
import 'package:mind_forensics/features/support/presentation/contextual_support_sheet.dart';
import 'package:mind_forensics/features/track/presentation/track_screen.dart';
import 'package:mind_forensics/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpViewport(
    WidgetTester tester, {
    required Widget child,
    required Size logicalSize,
    double textScale = 1.0,
    Locale locale = const Locale('en'),
    bool isDark = true,
    Map<String, Object> extraPrefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues({
      'mind_forensics_locale': locale.languageCode,
      'mf_onboarding_completed': true,
      ...extraPrefs,
    });
    tester.view.physicalSize = logicalSize;
    tester.view.devicePixelRatio = 1.0;

    final errors = <FlutterErrorDetails>[];
    final prevOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
    };

    try {
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          child: MediaQuery(
            data: MediaQueryData(
              size: logicalSize,
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: MaterialApp(
              theme: LabTheme.daylightTheme,
              darkTheme: LabTheme.nightTheme,
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              locale: locale,
              supportedLocales: const [
                Locale('en'),
                Locale('fr'),
                Locale('ar'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: child,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        errors.map((e) {
          final lines = e.toString().split('\n');
          final match = lines.where((l) =>
              l.contains('overflowed') ||
              l.contains('file:///') ||
              l.contains('Row ') ||
              l.contains('Column ')).take(3).join(' <- ');
          return match.isNotEmpty ? match : e.exceptionAsString();
        }).toList(),
        isEmpty,
        reason:
            'Unexpected layout/overflow errors at $logicalSize scale=$textScale locale=${locale.languageCode} dark=$isDark',
      );
      expect(tester.takeException(), isNull);
    } finally {
      FlutterError.onError = prevOnError;
      tester.view.reset();
    }
  }

  group('Phase 9 Responsive, Large-Text & RTL Visual QA Matrix', () {
    final screens = <({String name, Widget Function() build})>[
      (name: 'HomeScreen', build: () => const HomeScreen()),
      (name: 'TrackScreen', build: () => const TrackScreen()),
      (name: 'TrackScreenHistory', build: () => const TrackScreen(initialTab: 1)),
      (name: 'InnerObservatoryScreen', build: () => const InnerObservatoryScreen()),
      (name: 'InsightsScreen', build: () => const InsightsScreen()),
      (name: 'SettingsScreen', build: () => const SettingsScreen()),
      (name: 'FlashCaseScreen', build: () => const FlashCaseScreen()),
      (name: 'JourneyScreen', build: () => const JourneyScreen()),
      (name: 'OnboardingScreen', build: () => const OnboardingScreen()),
      (
        name: 'ContextualSupportSheet',
        build: () => const Scaffold(body: ContextualSupportSheet()),
      ),
    ];

    for (final screen in screens) {
      testWidgets('${screen.name}: 320px narrow portrait EN dark',
          (tester) async {
        await pumpViewport(
          tester,
          child: screen.build(),
          logicalSize: const Size(320, 568),
          isDark: true,
        );
      });

      testWidgets('${screen.name}: 375px with 1.35x text scaling FR light',
          (tester) async {
        await pumpViewport(
          tester,
          child: screen.build(),
          logicalSize: const Size(375, 812),
          textScale: 1.35,
          locale: const Locale('fr'),
          isDark: false,
        );
      });

      testWidgets('${screen.name}: 360px with 1.3x Tunisian Arabic RTL dark',
          (tester) async {
        await pumpViewport(
          tester,
          child: screen.build(),
          logicalSize: const Size(360, 780),
          textScale: 1.3,
          locale: const Locale('ar'),
          isDark: true,
        );
      });

      testWidgets('${screen.name}: 800px tablet EN light', (tester) async {
        await pumpViewport(
          tester,
          child: screen.build(),
          logicalSize: const Size(800, 1200),
          isDark: false,
        );
      });
    }

    testWidgets(
        'Full MindForensicsApp bottom navigation shell renders cleanly in 320px Tunisian Arabic RTL',
        (tester) async {
      AppRouter.enableFirstLaunchGating = false;
      SharedPreferences.setMockInitialValues({
        'mind_forensics_locale': 'ar',
        'mf_onboarding_completed': true,
      });
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;

      final errors = <FlutterErrorDetails>[];
      final prevOnError = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details);

      try {
        await tester.pumpWidget(
          const ProviderScope(
            child: MediaQuery(
              data: MediaQueryData(
                size: Size(320, 568),
                disableAnimations: true,
              ),
              child: MindForensicsApp(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(errors.map((e) => e.exceptionAsString()).toList(), isEmpty);
        expect(tester.takeException(), isNull);
        expect(find.text('الرئيسية'), findsOneWidget);
      } finally {
        FlutterError.onError = prevOnError;
        AppRouter.enableFirstLaunchGating = true;
        tester.view.reset();
      }
    });
  });

  group('Phase 10 UX Polish & Localized Controls Regression', () {
    testWidgets(
        'SettingsScreen gentle notifications cadence Wrap renders cleanly in FR 320px 1.3x',
        (tester) async {
      await pumpViewport(
        tester,
        child: const SettingsScreen(),
        logicalSize: const Size(320, 568),
        textScale: 1.3,
        locale: const Locale('fr'),
        isDark: true,
        extraPrefs: const {'mf_gentle_notifications': true},
      );
      expect(
        find.text(
          'Exemple : « Votre empreinte du jour vous attend quand vous êtes prêt(e). »',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'SettingsScreen gentle notifications cadence Wrap renders cleanly in AR RTL 320px 1.3x',
        (tester) async {
      await pumpViewport(
        tester,
        child: const SettingsScreen(),
        logicalSize: const Size(320, 568),
        textScale: 1.3,
        locale: const Locale('ar'),
        isDark: false,
        extraPrefs: const {'mf_gentle_notifications': true},
      );
      expect(find.text('يوم بيوم'), findsOneWidget);
    });

    testWidgets(
        'LiveDialogueView paused-for-safety input hint is localized in FR and AR without overflow at 320px',
        (tester) async {
      final now = DateTime(2026, 11, 13, 12);
      final pausedCase = CaseModel(
        id: 'paused_case_test',
        caseNumber: 'CASE-01',
        title: 'Safety Pause Verification',
        createdAt: now,
        updatedAt: now,
        currentStage: CaseStage.incident,
        incidentDescription: 'Test scenario',
        isPausedForSafety: true,
      );

      await pumpViewport(
        tester,
        child: Scaffold(body: LiveDialogueView(caseModel: pausedCase)),
        logicalSize: const Size(320, 568),
        locale: const Locale('fr'),
        isDark: true,
      );
      expect(find.text('Session mise en pause par sécurité'), findsOneWidget);

      await pumpViewport(
        tester,
        child: Scaffold(body: LiveDialogueView(caseModel: pausedCase)),
        logicalSize: const Size(320, 568),
        locale: const Locale('ar'),
        isDark: true,
      );
      expect(find.text('تم إيقاف الجلسة مؤقتاً لسلامتك'), findsOneWidget);
    });
  });
}

