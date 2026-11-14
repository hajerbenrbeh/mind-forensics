import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/router/app_router.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/widgets/mind_pressable.dart';
import 'package:mind_forensics/features/auth/controllers/auth_controller.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mind_forensics/features/profile/controllers/profile_controller.dart';
import 'package:mind_forensics/features/profile/domain/condition_type.dart';
import 'package:mind_forensics/features/profile/domain/diagnostic_status.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createLocalizedTestApp({
  required Widget child,
  ProviderContainer? container,
}) {
  Widget app = Consumer(
    builder: (context, ref, _) {
      final locale = ref.watch(localeControllerProvider);
      return MaterialApp(
        theme: LabTheme.daylightTheme,
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
      );
    },
  );

  if (container != null) {
    return UncontrolledProviderScope(container: container, child: app);
  }
  return ProviderScope(child: app);
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Step 5: Fast 4-Step Onboarding & Zero-Blank-Screen Handoff', () {
    test(
        '1. PsychologicalProfileModel serialization preserves all onboarding fields',
        () {
      final now = DateTime.now();
      final profile = PsychologicalProfileModel(
        userId: 'test_user_onboarding',
        preferredName: 'Atlas',
        ageRange: 'under_18',
        biologicalSex: 'female',
        mentalHealthBackground: 'diagnosed',
        conditions: const [
          UserConditionEntry(
            condition: ConditionType.generalizedAnxiety,
            status: DiagnosticStatus.professionallyDiagnosed,
          ),
          UserConditionEntry(
            condition: ConditionType.adhd,
            status: DiagnosticStatus.selfIdentifiedExploring,
          ),
        ],
        selectedSymptoms: const [
          'sym_persistent_heaviness',
          'sym_constant_apprehension',
        ],
        selectedGoals: const [
          'Ease stress & anxiety',
          'Understand mood patterns',
        ],
        customGoal: 'Learn emotional regulation during exams',
        personalGoals:
            'Ease stress & anxiety, Understand mood patterns, Learn emotional regulation during exams',
        professionalSupport: 'therapist',
        communicationPreference: 'analytical_reflective',
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        onboardingStep: 4,
        updatedAt: now,
      );

      final json = profile.toJson();
      final roundtrip = PsychologicalProfileModel.fromJson(json);

      expect(roundtrip.userId, 'test_user_onboarding');
      expect(roundtrip.preferredName, 'Atlas');
      expect(roundtrip.ageRange, 'under_18');
      expect(roundtrip.isMinor, isTrue);
      expect(roundtrip.biologicalSex, 'female');
      expect(roundtrip.mentalHealthBackground, 'diagnosed');
      expect(roundtrip.conditions.length, 2);
      expect(
        roundtrip.conditions[0].status,
        DiagnosticStatus.professionallyDiagnosed,
      );
      expect(
        roundtrip.conditions[1].status,
        DiagnosticStatus.selfIdentifiedExploring,
      );
      expect(roundtrip.selectedSymptoms.length, 2);
      expect(roundtrip.selectedGoals.length, 2);
      expect(roundtrip.customGoal, 'Learn emotional regulation during exams');
      expect(roundtrip.professionalSupport, 'therapist');
      expect(roundtrip.communicationPreference, 'analytical_reflective');
      expect(roundtrip.shareWithAiCompanion, isTrue);
      expect(roundtrip.onboardingStep, 4);
    });

    test(
        '2. isMinor correctly flags minors and adults without unsupported assumptions',
        () {
      final minorProfile1 = PsychologicalProfileModel(
        ageRange: 'under_18',
        updatedAt: DateTime.now(),
      );
      expect(minorProfile1.isMinor, isTrue);

      final minorProfile2 = PsychologicalProfileModel(
        ageRange: '<18',
        updatedAt: DateTime.now(),
      );
      expect(minorProfile2.isMinor, isTrue);

      final adultProfile = PsychologicalProfileModel(
        ageRange: '25-34',
        updatedAt: DateTime.now(),
      );
      expect(adultProfile.isMinor, isFalse);
    });

    testWidgets(
        '3. Step 1 renders Welcome, privacy guarantee, Sign In link, and live EN/FR/AR RTL switching',
        (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        createLocalizedTestApp(child: const OnboardingScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.text('Every thought leaves a trace.'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      // Verify >= 48dp minimum touch targets on primary interactive controls
      final getStartedPressable = find.ancestor(
        of: find.text('Get Started'),
        matching: find.byType(MindPressable),
      );
      expect(tester.getSize(getStartedPressable).height,
          greaterThanOrEqualTo(48));
      final enPill = find.ancestor(
        of: find.text('EN'),
        matching: find.byType(MindPressable),
      );
      expect(tester.getSize(enPill).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(enPill).width, greaterThanOrEqualTo(48));

      // Switch live to French
      await tester.tap(find.text('FR'));
      await tester.pumpAndSettle();
      expect(find.text('Chaque pensée laisse une trace.'), findsOneWidget);
      expect(find.text('Commencer'), findsOneWidget);

      // Switch live to Tunisian Arabic (RTL)
      await tester.tap(find.text('AR'));
      await tester.pumpAndSettle();
      expect(find.text('كل فكرة تترك أثراً.'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text('كل فكرة تترك أثراً.'))),
        TextDirection.rtl,
      );

      // Switch back to EN
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();
      expect(find.text('Every thought leaves a trace.'), findsOneWidget);
    });

    testWidgets(
        '4. Step 2 uses Options-First focus cards and keeps text input collapsed by default',
        (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        createLocalizedTestApp(child: const OnboardingScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 4'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text('Ease stress & anxiety'));
      await tester.tap(find.text('Understand mood patterns'));
      await tester.pumpAndSettle();

      // Expand optional custom goal only when explicitly tapped
      await tester.tap(find.text('Or add your own focus (optional)'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets(
        '5. Step 3 shows Under 18 safeguard immediately and preserves crisis lines',
        (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        createLocalizedTestApp(child: const OnboardingScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Step 3 of 4'), findsOneWidget);
      final enStrings = AppStrings('en');
      expect(find.text(enStrings.minorSupportNotice), findsNothing);

      // Tapping Under 18 reveals safeguard notice
      await tester.tap(find.text('Under 18'));
      await tester.pumpAndSettle();
      expect(find.text(enStrings.minorSupportNotice), findsOneWidget);

      // Selecting adult range hides minor notice
      await tester.tap(find.text('25-34'));
      await tester.pumpAndSettle();
      expect(find.text(enStrings.minorSupportNotice), findsNothing);

      // Verify crisis resources reminder stays clearly visible
      expect(find.text(enStrings.onboardingCrisisSafetyNote), findsOneWidget);
      expect(find.text(enStrings.openCrisisResourcesLabel), findsOneWidget);
    });

    testWidgets(
        '6. Skip flows through Steps 2-4 cleanly without creating forced check-in',
        (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        createLocalizedTestApp(
          container: container,
          child: const OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 4'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.text('Step 3 of 4'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.text('Step 4 of 4'), findsOneWidget);

      await tester.tap(find.text('Skip & Enter App'));
      await tester.pumpAndSettle();

      expect(
        container.read(authControllerProvider).hasCompletedOnboarding,
        isTrue,
      );
      expect(
        container.read(profileControllerProvider).value?.onboardingStep,
        4,
      );
      expect(
        container.read(mindTraceControllerProvider).value ?? [],
        isEmpty,
      );
    });

    testWidgets(
        '7. Step 4 Save & Enter App records Trace #1 and hands off to populated HomeScreen',
        (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final testRouter = GoRouter(
        initialLocation: AppRouter.onboarding,
        routes: [
          GoRoute(
            path: AppRouter.onboarding,
            builder: (context, state) => const OnboardingScreen(),
          ),
          GoRoute(
            path: AppRouter.home,
            builder: (context, state) => const HomeScreen(),
          ),
        ],
      );
      addTearDown(testRouter.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: LabTheme.daylightTheme,
            routerConfig: testRouter,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1 -> Step 2
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Understand mood patterns'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3 -> Step 4
      await tester.tap(find.text('Seeing a specialist'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 4 First Check-In
      expect(find.text('Step 4 of 4'), findsOneWidget);
      await tester.tap(find.text('Anxious'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save & Enter App'));
      await tester.pumpAndSettle();

      // Verify HomeScreen reached with Trace #1 hydrated
      expect(find.byType(HomeScreen), findsOneWidget);
      final traces = container.read(mindTraceControllerProvider).value ?? [];
      expect(traces.length, 1);
      expect(traces.first.overallMood, 'anxious');
      expect(traces.first.moodIntensity, 5);
      expect(container.read(todayTraceProvider)?.overallMood, 'anxious');
    });

    testWidgets('8. Interrupted onboarding recovery hydrates saved step draft',
        (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final draftProfile = PsychologicalProfileModel(
        userId: 'local_user',
        ageRange: '35-44',
        selectedGoals: const ['Understand mood patterns'],
        onboardingStep: 2,
        updatedAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          profileControllerProvider
              .overrideWith(() => _MockProfileNotifier(draftProfile)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        createLocalizedTestApp(
          container: container,
          child: const OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 3 of 4'), findsOneWidget);
      expect(find.text('Comfort & safety check'), findsOneWidget);
    });
  });
}

class _MockProfileNotifier extends ProfileNotifier {
  _MockProfileNotifier(this._initialProfile);

  final PsychologicalProfileModel _initialProfile;

  @override
  Future<PsychologicalProfileModel> build() async {
    return _initialProfile;
  }
}
