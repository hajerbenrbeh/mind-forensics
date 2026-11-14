import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/features/journey/data/default_journey_curriculum.dart';
import 'package:mind_forensics/features/journey/presentation/journey_activity_detail_screen.dart';
import 'package:mind_forensics/features/journey/presentation/journey_screen.dart';
import 'package:mind_forensics/features/profile/presentation/psychological_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Psychological Profile & Journey UI Tests', () {
    testWidgets('PsychologicalProfileScreen renders conditions, details, and toggle',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PsychologicalProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and sections
      expect(find.text('MY PSYCHOLOGICAL PROFILE'), findsOneWidget);
      expect(find.text('CONDITIONS & EXPERIENCES'), findsOneWidget);
      expect(find.text('OPTIONAL CONTEXT & DETAILS'), findsOneWidget);

      // Verify condition chips are visible
      expect(find.text('Depression'), findsOneWidget);
      expect(find.text('ADHD'), findsOneWidget);
      expect(find.text('OCD (Obsessive-Compulsive Disorder)'), findsOneWidget);

      // Verify decoupled AI consent toggles exist
      expect(find.text('External AI processing & sharing'), findsOneWidget);
      expect(find.text('Personalize AI with profile context'), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(2));

      // Verify Save button exists
      expect(find.text('SAVE PROFILE'), findsOneWidget);
    });

    testWidgets('JourneyScreen renders phases, activities, and view switcher',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: JourneyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check title and top tabs
      expect(find.text('MY JOURNEY'), findsAtLeastNWidgets(1));
      expect(find.text('My Progress'), findsOneWidget);
      expect(find.text('Tools Lab'), findsOneWidget);

      // Check Phase 1 activities
      expect(find.text('The Triad: Thoughts, Emotions, and Actions'), findsOneWidget);
      expect(find.text('Mapping Recurring Thought Themes'), findsOneWidget);

      // Switch to My Progress tab
      await tester.tap(find.text('My Progress'));
      await tester.pumpAndSettle();

      // Verify non-judgmental progress notice
      expect(find.text('COMPLETED ACTIVITIES'), findsOneWidget);
      expect(find.text('REFLECTIONS LOGGED'), findsOneWidget);
    });

    testWidgets('JourneyActivityDetailScreen allows writing reflection and completing',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final activity = DefaultJourneyCurriculum.getActivities().first;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: JourneyActivityDetailScreen(activity: activity),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check title and purpose
      expect(find.text(activity.title), findsOneWidget);
      expect(find.text('CLINICAL PURPOSE'), findsOneWidget);
      expect(find.text('GUIDED INSTRUCTIONS'), findsOneWidget);
      expect(find.text('REFLECTION QUESTIONS'), findsOneWidget);

      // Enter reflection
      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeastNWidgets(2));

      await tester.enterText(textFields.first, 'Observable situation was a missed call');
      await tester.pumpAndSettle();

      // Tap Mark as completed
      await tester.tap(find.text('Mark as Completed'));
      await tester.pumpAndSettle();

      // Verify completion badge changes
      expect(find.text('Completed'), findsAtLeastNWidgets(1));
    });
  });
}
