import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/core/safety/support_button.dart';
import 'package:mind_forensics/features/support/presentation/contextual_support_sheet.dart';
import 'package:mind_forensics/features/support/presentation/widgets/breathing_exercise_card.dart';
import 'package:mind_forensics/features/support/presentation/widgets/grounding_exercise_card.dart';
import 'package:mind_forensics/features/support/presentation/widgets/micro_action_card.dart';
import 'package:mind_forensics/features/support/presentation/widgets/perspective_exploration_card.dart';
import 'package:mind_forensics/features/support/presentation/widgets/routine_anchor_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Contextual Support & Shared Exercise Architecture Tests', () {
    testWidgets('ContextualSupportSheet renders all 5 options-first starting points',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ContextualSupportSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & prompt
      expect(find.text('What would help right now?'), findsOneWidget);
      expect(find.text('CONTEXTUAL SUPPORT'), findsOneWidget);

      // Verify the 5 curated starting points
      expect(find.text('I need to settle myself'), findsOneWidget);
      expect(find.text('I’m stuck in my thoughts'), findsOneWidget);
      expect(find.text('I can’t get myself started'), findsOneWidget);
      expect(find.text('I need help with my routine'), findsOneWidget);
      expect(find.text('I want to explore something else'), findsOneWidget);

      // Verify emergency crisis access button is present
      expect(find.text('Need help now: Emergency crisis lines'), findsOneWidget);
    });

    testWidgets('Tapping "I need to settle myself" displays Box Breathing & Sensory Grounding toggle',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ContextualSupportSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap settle myself
      await tester.tap(find.text('I need to settle myself'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Breathing card is rendered
      expect(find.byType(BreathingExerciseCard), findsOneWidget);
      expect(find.text('VAGAL BOX PACING (4-4-4-4)'), findsOneWidget);

      // Sensory Grounding toggle is available
      expect(find.text('5-4-3-2-1 Sensory Grounding'), findsOneWidget);

      // Switch to Sensory Grounding
      await tester.tap(find.text('5-4-3-2-1 Sensory Grounding'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Grounding card is rendered
      expect(find.byType(GroundingExerciseCard), findsOneWidget);
      expect(find.text('5-4-3-2-1 SENSORY GROUNDING'), findsOneWidget);
      expect(find.text('5 things you see around you'), findsOneWidget);
    });

    testWidgets('Tapping "I’m stuck in my thoughts" displays Perspective Exploration',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ContextualSupportSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('I’m stuck in my thoughts'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PerspectiveExplorationCard), findsOneWidget);
      expect(find.text('PERSPECTIVE EXPLORATION'), findsOneWidget);
      expect(find.text('OBSERVABLE FACT'), findsOneWidget);
      expect(find.text('AUTOMATIC INTERPRETATION'), findsOneWidget);
      expect(find.text('Alternative grounded possibilities:'), findsOneWidget);
    });

    testWidgets('Tapping "I can’t get myself started" displays Micro-action card',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ContextualSupportSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('I can’t get myself started'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MicroActionCard), findsOneWidget);
      expect(find.text('2 MINUTES ONLY'), findsOneWidget);
      expect(find.text('Start 2 Minutes'), findsOneWidget);
    });

    testWidgets('Tapping "I need help with my routine" displays RoutineAnchorCard',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ContextualSupportSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('I need help with my routine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(RoutineAnchorCard), findsOneWidget);
      expect(find.text('ONE GENTLE ANCHOR'), findsOneWidget);
      expect(find.text('Daylight & Hydration'), findsAtLeastNWidgets(1));
    });

    testWidgets('Emergency crisis card displays verified Tunisian lines',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ContextualSupportSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Need help now: Emergency crisis lines'));
      await tester.pumpAndSettle();

      // SupportModalSheet shows the hotline options
      expect(find.byType(SupportModalSheet), findsOneWidget);
      expect(find.textContaining('80 10 50 50'), findsOneWidget);
      expect(find.textContaining('190'), findsOneWidget);
      expect(find.textContaining('198'), findsOneWidget);
    });
  });
}
