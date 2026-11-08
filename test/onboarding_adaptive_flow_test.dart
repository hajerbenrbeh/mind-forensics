import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mind_forensics/features/profile/controllers/profile_controller.dart';
import 'package:mind_forensics/features/profile/domain/condition_type.dart';
import 'package:mind_forensics/features/profile/domain/diagnostic_status.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestWidget({
  required Widget child,
}) {
  return ProviderScope(
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Personalized First-Launch Onboarding Adaptive Flow Tests', () {
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
          'Understand recurring thought patterns',
          'Manage anxiety and somatic tension',
        ],
        customGoal: 'Learn emotional regulation during exams',
        personalGoals:
            'Understand recurring thought patterns, Manage anxiety and somatic tension, Learn emotional regulation during exams',
        professionalSupport: 'therapist',
        communicationPreference: 'analytical_reflective',
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        onboardingStep: 7,
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
      expect(roundtrip.onboardingStep, 7);
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

    testWidgets('3. Step 0 Welcome renders and advances to Step 1 Basic Info',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester
          .pumpWidget(createTestWidget(child: const OnboardingScreen()));
      await tester.pumpAndSettle();

      // Verify Step 0 Welcome elements
      expect(find.text('Every thought leaves a trace.'), findsOneWidget);
      expect(find.text('GET STARTED'), findsOneWidget);

      // Advance to Step 1
      await tester.tap(find.text('GET STARTED'));
      await tester.pumpAndSettle();

      // Step 1: Basic Information should be displayed
      expect(find.text('BASIC INFORMATION'), findsOneWidget);
      expect(find.text('Basic Information'), findsOneWidget);
      expect(find.text('AGE RANGE'), findsOneWidget);
    });

    testWidgets(
        '4. Step 1 Basic Info: selecting under_18 displays minor safeguard notice',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester
          .pumpWidget(createTestWidget(child: const OnboardingScreen()));
      await tester.pumpAndSettle();

      // Navigate to Step 1
      await tester.tap(find.text('GET STARTED'));
      await tester.pumpAndSettle();

      // Safeguard notice should NOT be present initially
      final strings = AppStrings('en');
      expect(find.text(strings.minorSupportNotice), findsNothing);

      // Tap 'Under 18'
      await tester.tap(find.text('Under 18'));
      await tester.pumpAndSettle();

      // Safeguard notice MUST appear immediately
      expect(find.text(strings.minorSupportNotice), findsOneWidget);
    });

    testWidgets(
        '5. Adaptive Branching: Diagnosed background routes to Step 3 Conditions',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester
          .pumpWidget(createTestWidget(child: const OnboardingScreen()));
      await tester.pumpAndSettle();

      // Step 0 -> Step 1
      await tester.tap(find.text('GET STARTED'));
      await tester.pumpAndSettle();

      // Select age 18-24 in Step 1
      await tester.tap(find.text('18-24'));
      await tester.pumpAndSettle();

      // Step 1 -> Step 2 (Starting Point)
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      expect(find.text('STARTING POINT'), findsOneWidget);

      // Select 'Diagnosed Condition'
      await tester.tap(find.text('Diagnosed Condition'));
      await tester.pumpAndSettle();

      // Step 2 -> Next: Should branch to Step 3 Conditions
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      expect(find.text('CONDITIONS'), findsOneWidget);
      expect(find.text('Conditions & Experiences'), findsOneWidget);
      expect(find.text('Search conditions or lived experiences...'),
          findsOneWidget);
    });

    testWidgets(
        '6. Adaptive Branching: Difficulties Without Diagnosis bypasses Conditions to Symptoms',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester
          .pumpWidget(createTestWidget(child: const OnboardingScreen()));
      await tester.pumpAndSettle();

      // Step 0 -> Step 1
      await tester.tap(find.text('GET STARTED'));
      await tester.pumpAndSettle();

      // Step 1 -> Step 2
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      expect(find.text('STARTING POINT'), findsOneWidget);

      // Select non-clinical starting point: 'Difficulties Without Diagnosis'
      await tester.tap(find.text('Difficulties Without Diagnosis'));
      await tester.pumpAndSettle();

      // Step 2 -> Next: Should adaptively BYPASS Step 3 Conditions directly to Step 4 Symptoms!
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      expect(find.text('CONDITIONS'), findsNothing);
      expect(find.text('SYMPTOMS & DIFFICULTIES'), findsOneWidget);
      expect(find.text('Current Symptoms & Difficulties'), findsOneWidget);
    });

    testWidgets(
        '7. Step 7 Summary of Priorities allows 1-tap editing and returning to summary',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester
          .pumpWidget(createTestWidget(child: const OnboardingScreen()));
      await tester.pumpAndSettle();

      // Advance through flow with non-diagnosed background
      await tester.tap(find.text('GET STARTED')); // to Step 1
      await tester.pumpAndSettle();

      await tester.tap(find.text('25-34'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('NEXT')); // to Step 2
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wellbeing & Habit Tracking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('NEXT')); // to Step 4 (bypasses 3)
      await tester.pumpAndSettle();

      await tester.tap(find.text('NEXT')); // to Step 5 (Goals)
      await tester.pumpAndSettle();

      await tester.tap(find.text('NEXT')); // to Step 6 (Support)
      await tester.pumpAndSettle();

      await tester.tap(find.text('NEXT')); // to Step 7 (Summary)
      await tester.pumpAndSettle();

      expect(find.text('CONFIRMATION'), findsOneWidget);
      expect(find.text('Review Your Priorities'), findsOneWidget);
      expect(find.text('CONFIRM & GET STARTED'), findsOneWidget);

      // Verify that all 6 sections have Edit buttons
      expect(find.text('Edit'), findsNWidgets(6));

      // Tap the first Edit button (Basic Information)
      await tester.tap(find.text('Edit').first);
      await tester.pumpAndSettle();

      // Should now be on Step 1 in Edit mode
      expect(find.text('BASIC INFORMATION'), findsOneWidget);
      expect(find.text('Editing section • Review will reflect changes'),
          findsOneWidget);
      expect(find.text('RETURN TO SUMMARY'), findsWidgets);

      // Tap 'RETURN TO SUMMARY'
      await tester.tap(find.text('RETURN TO SUMMARY').first);
      await tester.pumpAndSettle();

      // Immediately back to Step 7 Confirmation
      expect(find.text('CONFIRMATION'), findsOneWidget);
      expect(find.text('CONFIRM & GET STARTED'), findsOneWidget);
    });

    testWidgets(
        '8. Optional questions can be skipped without blocking onboarding completion',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester
          .pumpWidget(createTestWidget(child: const OnboardingScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('GET STARTED')); // Step 1
      await tester.pumpAndSettle();

      // In Step 1, tap SKIP in the AppBar without entering age or sex
      await tester.tap(find.text('SKIP'));
      await tester.pumpAndSettle();

      // Should advance to Step 2
      expect(find.text('STARTING POINT'), findsOneWidget);

      // Select 'Still Figuring It Out'
      await tester.tap(find.text('Still Figuring It Out'));
      await tester.pumpAndSettle();

      // Step 2 -> Next bypasses conditions to Step 4 Symptoms
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();
      expect(find.text('SYMPTOMS & DIFFICULTIES'), findsOneWidget);

      // Advance through remaining steps without selecting any mandatory items
      await tester.tap(find.text('NEXT')); // Step 5 Goals
      await tester.pumpAndSettle();

      await tester.tap(find.text('NEXT')); // Step 6 Support
      await tester.pumpAndSettle();

      // In Step 6, tap SKIP
      await tester.tap(find.text('SKIP'));
      await tester.pumpAndSettle();

      // Should arrive at Step 7 Confirmation cleanly
      expect(find.text('CONFIRMATION'), findsOneWidget);
      expect(find.text('CONFIRM & GET STARTED'), findsOneWidget);
    });

    testWidgets('9. Interrupted onboarding recovery: hydrates from draft profile',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Pre-seed an interrupted draft profile at step 4
      final draftProfile = PsychologicalProfileModel(
        userId: 'local_user',
        ageRange: '35-44',
        biologicalSex: 'female',
        mentalHealthBackground: 'difficulties_no_diagnosis',
        selectedSymptoms: const ['sym_persistent_heaviness'],
        onboardingStep: 4,
        updatedAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          profileControllerProvider.overrideWith(() => _MockProfileNotifier(draftProfile)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should have resumed directly at Step 4 Symptoms & Difficulties
      expect(find.text('SYMPTOMS & DIFFICULTIES'), findsOneWidget);
      expect(find.text('Step 4 of 7'), findsOneWidget);
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
