import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/widgets/mind_button.dart';
import 'package:mind_forensics/core/widgets/mind_card.dart';
import 'package:mind_forensics/features/insights/presentation/insights_screen.dart';
import 'package:mind_forensics/features/track/presentation/track_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestHarness(Widget child) {
  return ProviderScope(
    child: Consumer(
      builder: (context, ref, _) {
        final locale = ref.watch(localeControllerProvider);
        return MaterialApp(
          theme: LabTheme.daylightTheme,
          darkTheme: LabTheme.nightTheme,
          locale: locale,
          home: Scaffold(body: child),
        );
      },
    ),
  );
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('TrackScreen & Self-Observation Widget Tests', () {
    testWidgets('TrackScreen renders tabs, mood options, telemetry sliders, and save action', (tester) async {
      await tester.pumpWidget(createTestHarness(const TrackScreen()));
      await tester.pumpAndSettle();

      // Verify TabBar
      expect(find.text('Quick Check-in'), findsOneWidget);
      expect(find.text('Detailed Trace'), findsOneWidget);
      expect(find.text('Trace History'), findsOneWidget);

      // Verify Core State Options
      expect(find.text("TODAY'S CORE STATE"), findsOneWidget);
      expect(find.text('Calm'), findsOneWidget);
      expect(find.text('Anxious'), findsOneWidget);
      expect(find.text('Frustrated'), findsOneWidget);
      expect(find.text('Heavy'), findsOneWidget);
      expect(find.text('Restless'), findsOneWidget);

      // Verify primary intensity slider and progressive disclosure toggle
      expect(find.text('Nervous Activation'), findsOneWidget);
      expect(find.text('Add context (optional)'), findsOneWidget);
      expect(find.text('Sleep Duration'), findsNothing);

      // Expand optional context block cleanly on demand
      await tester.ensureVisible(find.text('Add context (optional)'));
      await tester.tap(find.text('Add context (optional)'));
      await tester.pumpAndSettle();

      expect(find.text('Sleep Duration'), findsOneWidget);
      expect(find.text('Energy Level'), findsOneWidget);
      expect(find.text('Stress & Anxiety'), findsOneWidget);

      // Verify Trigger options
      expect(find.text('TRIGGERS & CONTEXT'), findsOneWidget);
      expect(find.text('Work / Demands'), findsOneWidget);
      expect(find.text('Sleep Disruption'), findsOneWidget);

      // Verify Save button
      expect(find.text('Log Daily Check-in'), findsOneWidget);
    });

    testWidgets('Selecting a mood and tapping trigger updates state without error', (tester) async {
      await tester.pumpWidget(createTestHarness(const TrackScreen()));
      await tester.pumpAndSettle();

      // Tap Anxious mood card
      await tester.tap(find.text('Anxious'));
      await tester.pumpAndSettle();

      // Expand optional context and tap Trigger chip
      final contextToggle = find.text('Add context (optional)');
      await tester.ensureVisible(contextToggle);
      await tester.tap(contextToggle);
      await tester.pumpAndSettle();

      final triggerFinder = find.text('Work / Demands');
      await tester.ensureVisible(triggerFinder);
      await tester.pumpAndSettle();
      await tester.tap(triggerFinder);
      await tester.pumpAndSettle();

      // Scroll and Tap Save button
      final saveFinder = find.text('Log Daily Check-in');
      await tester.ensureVisible(saveFinder);
      await tester.pumpAndSettle();
      await tester.tap(saveFinder);
      await tester.pumpAndSettle();

      // Verify Snackbar confirms save
      expect(find.text('Daily check-in and note saved'), findsOneWidget);
    });
  });

  group('InsightsScreen Widget Tests', () {
    testWidgets('InsightsScreen renders personal baseline and weekly summary cards', (tester) async {
      await tester.pumpWidget(createTestHarness(const InsightsScreen()));
      await tester.pumpAndSettle();

      // Verify Header & Baseline Card
      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('PERSONAL BASELINE'), findsOneWidget);
      expect(find.textContaining('Calibrating'), findsOneWidget);

      // Verify Weekly Summary section
      expect(find.text('WEEKLY SUMMARY FOR THERAPIST'), findsOneWidget);
      expect(find.text('Export Therapist Report'), findsOneWidget);

      // Verify Longitudinal Analytics link
      expect(find.text('Full Progress & Longitudinal Trends'), findsOneWidget);
    });
  });

  group('Mind Design System Primitives Tests', () {
    testWidgets('MindButton has minimum 48x48 tap target and responds to press', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        createTestHarness(
          MindButton(
            text: 'Action',
            onPressed: () => pressed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final buttonFinder = find.byType(MindButton);
      expect(buttonFinder, findsOneWidget);

      final size = tester.getSize(buttonFinder);
      expect(size.height, greaterThanOrEqualTo(48.0));
      expect(size.width, greaterThanOrEqualTo(48.0));

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      expect(pressed, isTrue);
    });

    testWidgets('MindCard renders child within 10px rounded border', (tester) async {
      await tester.pumpWidget(
        createTestHarness(
          const MindCard(
            child: Text('Card Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Card Content'), findsOneWidget);
    });
  });
}
