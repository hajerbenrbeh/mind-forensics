import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/router/app_router.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Real Android Emulator Onboarding Scenarios', () {
    testWidgets('Scenario 1: User with professionally diagnosed condition',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      AppRouter.enableFirstLaunchGating = true;

      await tester.pumpWidget(
        const ProviderScope(
          child: MindForensicsApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify First-Launch Gating routes to Welcome Screen
      expect(find.text('Every thought leaves a trace.'), findsOneWidget);
      expect(find.text('GET STARTED'), findsOneWidget);

      // Advance to Step 1 Basic Info
      await tester.tap(find.text('GET STARTED'));
      await tester.pumpAndSettle();

      expect(find.text('BASIC INFORMATION'), findsOneWidget);
      expect(find.text('AGE RANGE'), findsOneWidget);

      // Select Age 25-34 & Sex Female
      await tester.tap(find.text('25-34'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Female'));
      await tester.pumpAndSettle();

      // Advance to Step 2 Starting Point
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      expect(find.text('STARTING POINT'), findsOneWidget);

      // Select 'Diagnosed Condition'
      await tester.tap(find.text('Diagnosed Condition'));
      await tester.pumpAndSettle();

      // Advance to Step 3 Conditions (Should be present for diagnosed user)
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      expect(find.text('CONDITIONS'), findsOneWidget);
      expect(find.text('Conditions & Experiences'), findsOneWidget);

      // Search & select Generalized Anxiety Disorder (GAD)
      await tester.enterText(
          find.byType(TextField).first, 'Generalized Anxiety');
      await tester.pumpAndSettle();

      expect(find.textContaining('Generalized Anxiety Disorder'), findsOneWidget);
      await tester.tap(find.textContaining('Generalized Anxiety Disorder').first);
      await tester.pumpAndSettle();

      // Verify Diagnosed tag is active
      expect(find.text('Diagnosed'), findsWidgets);

      // Advance to Step 4 Symptoms & Difficulties
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      expect(find.text('SYMPTOMS & DIFFICULTIES'), findsOneWidget);

      // Advance to Step 5 Goals
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      expect(find.text('EXPLORATION GOALS'), findsOneWidget);
      await tester.tap(find.text('Manage anxiety and somatic tension'));
      await tester.pumpAndSettle();

      // Advance to Step 6 Professional Support
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      expect(find.text('PROFESSIONAL CARE'), findsOneWidget);
      await tester.tap(find.text('Therapist or Psychologist'));
      await tester.pumpAndSettle();

      // Advance to Step 7 Confirmation & Priorities
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      expect(find.text('CONFIRMATION'), findsOneWidget);
      expect(find.text('Review Your Priorities'), findsOneWidget);
      expect(find.text('CONFIRM & GET STARTED'), findsOneWidget);

      // Confirm & Get Started
      await tester.tap(find.text('CONFIRM & GET STARTED'));
      await tester.pumpAndSettle();

      // Must arrive at HomeScreen
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining('Manage anxiety and somatic tension'), findsOneWidget);
    });

    testWidgets('Scenario 2: User who suspects a condition without formal diagnosis',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      AppRouter.enableFirstLaunchGating = true;

      await tester.pumpWidget(
        const ProviderScope(
          child: MindForensicsApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('GET STARTED'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('18-24'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      // Select 'Suspected / Exploring'
      await tester.tap(find.text('Suspected / Exploring'));
      await tester.pumpAndSettle();

      // Advance to Conditions
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      expect(find.text('CONDITIONS'), findsOneWidget);

      // Select first available condition (e.g. Depression)
      await tester.tap(find.text('Depression'));
      await tester.pumpAndSettle();

      // Status toggle defaults to Suspected/Exploring
      expect(find.text('Suspected / Exploring'), findsWidgets);

      // Advance through remaining steps
      await tester.tap(find.text('NEXT')); // Step 4
      await tester.pumpAndSettle();
      await tester.tap(find.text('NEXT')); // Step 5
      await tester.pumpAndSettle();
      await tester.tap(find.text('NEXT')); // Step 6
      await tester.pumpAndSettle();
      await tester.tap(find.text('NEXT')); // Step 7
      await tester.pumpAndSettle();

      expect(find.text('CONFIRMATION'), findsOneWidget);
      expect(find.textContaining('Depression (Exploring)'), findsOneWidget);

      await tester.tap(find.text('CONFIRM & GET STARTED'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Scenario 3: Non-clinical user (Wellbeing & Habit Tracking)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      AppRouter.enableFirstLaunchGating = true;

      await tester.pumpWidget(
        const ProviderScope(
          child: MindForensicsApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('GET STARTED'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('25-34'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      // Select 'Wellbeing & Habit Tracking'
      await tester.tap(find.text('Wellbeing & Habit Tracking'));
      await tester.pumpAndSettle();

      // Next MUST adaptively bypass Step 3 Conditions directly to Step 4 Symptoms!
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      expect(find.text('CONDITIONS'), findsNothing);
      expect(find.text('SYMPTOMS & DIFFICULTIES'), findsOneWidget);

      // Complete flow
      await tester.tap(find.text('NEXT')); // Step 5 Goals
      await tester.pumpAndSettle();
      await tester.tap(find.text('General self-awareness and mindful observation'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('NEXT')); // Step 6 Support
      await tester.pumpAndSettle();
      await tester.tap(find.text('NEXT')); // Step 7 Summary
      await tester.pumpAndSettle();

      expect(find.text('CONFIRMATION'), findsOneWidget);
      expect(find.text('No conditions specified (Self-guided exploration)'), findsOneWidget);

      await tester.tap(find.text('CONFIRM & GET STARTED'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Scenario 4: User unsure of their experiences',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      AppRouter.enableFirstLaunchGating = true;

      await tester.pumpWidget(
        const ProviderScope(
          child: MindForensicsApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('GET STARTED'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('35-44'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      // Select 'Still Figuring It Out'
      await tester.tap(find.text('Still Figuring It Out'));
      await tester.pumpAndSettle();

      // Next MUST adaptively bypass Conditions to Symptoms
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      expect(find.text('CONDITIONS'), findsNothing);
      expect(find.text('SYMPTOMS & DIFFICULTIES'), findsOneWidget);
    });

    testWidgets('Scenario 5: User under 18 with safeguards active',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      AppRouter.enableFirstLaunchGating = true;

      await tester.pumpWidget(
        const ProviderScope(
          child: MindForensicsApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('GET STARTED'));
      await tester.pumpAndSettle();

      // Select 'Under 18'
      await tester.tap(find.text('Under 18'));
      await tester.pumpAndSettle();

      // Safeguard notice must appear immediately
      final strings = AppStrings('en');
      expect(find.text(strings.minorSupportNotice), findsOneWidget);

      // Advance through flow
      await tester.tap(find.text('NEXT')); // Step 2
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wellbeing & Habit Tracking'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('NEXT')); // Step 4 (bypasses 3)
      await tester.pumpAndSettle();
      await tester.tap(find.text('NEXT')); // Step 5
      await tester.pumpAndSettle();
      await tester.tap(find.text('NEXT')); // Step 6
      await tester.pumpAndSettle();
      await tester.tap(find.text('NEXT')); // Step 7
      await tester.pumpAndSettle();

      expect(find.text('CONFIRMATION'), findsOneWidget);
      expect(find.text('Under-18 Safeguards Active'), findsOneWidget);

      await tester.tap(find.text('CONFIRM & GET STARTED'));
      await tester.pumpAndSettle();

      // Verify HomeScreen displays safe reflection space indicator
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining('Safe reflection space'), findsOneWidget);
    });

    testWidgets('Scenario 6: User skipping optional questions',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      AppRouter.enableFirstLaunchGating = true;

      await tester.pumpWidget(
        const ProviderScope(
          child: MindForensicsApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('GET STARTED')); // Step 1
      await tester.pumpAndSettle();

      // Skip demographic details
      await tester.tap(find.text('SKIP'));
      await tester.pumpAndSettle();

      expect(find.text('STARTING POINT'), findsOneWidget);
      await tester.tap(find.text('Still Figuring It Out'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('NEXT')); // Step 4 Symptoms
      await tester.pumpAndSettle();

      await tester.tap(find.text('NEXT')); // Step 5 Goals
      await tester.pumpAndSettle();

      await tester.tap(find.text('NEXT')); // Step 6 Support
      await tester.pumpAndSettle();

      // Skip professional support
      await tester.tap(find.text('SKIP'));
      await tester.pumpAndSettle();

      expect(find.text('CONFIRMATION'), findsOneWidget);
      expect(find.text('CONFIRM & GET STARTED'), findsOneWidget);

      await tester.tap(find.text('CONFIRM & GET STARTED'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Scenario 7: Persistence across application reload',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'mf_onboarding_completed': true,
      });
      AppRouter.enableFirstLaunchGating = true;

      // Launch application as a returning user
      await tester.pumpWidget(
        const ProviderScope(
          child: MindForensicsApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Must land directly on HomeScreen, NOT on onboarding!
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Every thought leaves a trace.'), findsNothing);
    });
  });
}

