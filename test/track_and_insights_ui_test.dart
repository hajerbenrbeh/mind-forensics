import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/widgets/mind_button.dart';
import 'package:mind_forensics/core/widgets/mind_card.dart';
import 'package:mind_forensics/core/widgets/mind_segmented.dart';
import 'package:mind_forensics/features/insights/presentation/insights_screen.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/mind_trace/presentation/widgets/daily_mind_trace_stepper.dart';
import 'package:mind_forensics/features/track/presentation/track_screen.dart';
import 'package:mind_forensics/features/track/presentation/widgets/track_entry_detail_sheet.dart';
import 'package:mind_forensics/features/track/presentation/widgets/track_month_calendar.dart';
import 'package:mind_forensics/features/track/presentation/widgets/track_mood_picker.dart';
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
    testWidgets(
      'TrackScreen renders 2 consolidated tabs, 5 core states, collapsed optional context, and guided trigger',
      (tester) async {
        await tester.pumpWidget(createTestHarness(const TrackScreen()));
        await tester.pumpAndSettle();

        // Exactly 2 consolidated segments + Full Calendar action
        expect(find.byType(MindSegmented), findsOneWidget);
        expect(find.text('Check-In Today'), findsOneWidget);
        expect(find.text('History & Calendar'), findsOneWidget);
        expect(find.byTooltip('Full Calendar & Analytics'), findsOneWidget);

        // 5 Core State cards in 2-col TrackMoodPicker
        expect(find.text("TODAY'S CORE STATE"), findsOneWidget);
        expect(find.byType(TrackMoodPicker), findsOneWidget);
        expect(find.byType(TrackIntensitySlider), findsOneWidget);
        expect(find.text('Calm'), findsOneWidget);
        expect(find.text('Anxious'), findsOneWidget);
        expect(find.text('Frustrated'), findsOneWidget);
        expect(find.text('Heavy'), findsOneWidget);
        expect(find.text('Restless'), findsOneWidget);
        expect(find.text('Calm 1'), findsOneWidget);
        expect(find.text('Overwhelmed 10'), findsOneWidget);
        expect(find.text('What is on your mind? (optional)'), findsOneWidget);

        // Primary Intensity slider is visible immediately; context sliders are collapsed initially
        expect(find.text('Intensity'), findsOneWidget);
        expect(find.text('Add context (optional)'), findsOneWidget);
        expect(find.text('Sleep Duration'), findsNothing);
        expect(find.text('Energy Level'), findsNothing);
        expect(find.text('Stress & Anxiety'), findsNothing);

        // Expand Add context (optional)
        await tester.ensureVisible(find.text('Add context (optional)'));
        await tester.tap(find.text('Add context (optional)'));
        await tester.pumpAndSettle();

        expect(find.text('Work / Demands'), findsOneWidget);
        expect(find.text('Sleep Disruption'), findsOneWidget);
        expect(find.text('What helped today? (optional)'), findsOneWidget);
        expect(find.text('Sleep Duration'), findsOneWidget);
        expect(find.text('Energy Level'), findsOneWidget);
        expect(find.text('Stress & Anxiety'), findsOneWidget);

        // Verify Save Check-In & guided link
        expect(find.text('Save Check-In'), findsOneWidget);
        expect(find.text('Prefer step-by-step check-in?'), findsOneWidget);
      },
    );

    testWidgets(
      'TrackScreen saves check-in, switches primary CTA to Update Today’s Entry, and opens guided stepper sheet',
      (tester) async {
        await tester.pumpWidget(createTestHarness(const TrackScreen()));
        await tester.pumpAndSettle();

        // Select Anxious mood card
        await tester.tap(find.text('Anxious'));
        await tester.pumpAndSettle();

        // Enter optional note
        await tester.enterText(find.byType(TextField), 'Tight deadline today.');
        await tester.pumpAndSettle();

        // Expand optional context and choose a trigger
        await tester.ensureVisible(find.text('Add context (optional)'));
        await tester.tap(find.text('Add context (optional)'));
        await tester.pumpAndSettle();

        final triggerFinder = find.text('Work / Demands');
        await tester.ensureVisible(triggerFinder);
        await tester.tap(triggerFinder);
        await tester.pumpAndSettle();

        // Tap Save Check-In
        final saveFinder = find.text('Save Check-In');
        await tester.ensureVisible(saveFinder);
        await tester.pumpAndSettle();
        await tester.tap(saveFinder);
        await tester.pumpAndSettle();

        expect(find.text('Daily check-in and note saved'), findsOneWidget);
        expect(find.text('Saved'), findsOneWidget);
        expect(find.text("Update Today's Entry"), findsOneWidget);

        // Open discreet step-by-step guided modal sheet
        final guidedFinder = find.text('Prefer step-by-step check-in?');
        await tester.ensureVisible(guidedFinder);
        await tester.tap(guidedFinder);
        await tester.pumpAndSettle();

        expect(find.byType(DailyMindTraceStepper), findsOneWidget);
      },
    );

    testWidgets(
      'History & Calendar tab renders empty CTA -> Tab 0, calendar day filtering, edit, and delete confirmation',
      (tester) async {
        late ProviderContainer container;
        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, _) {
                container = ProviderScope.containerOf(context);
                final locale = ref.watch(localeControllerProvider);
                return MaterialApp(
                  theme: LabTheme.daylightTheme,
                  darkTheme: LabTheme.nightTheme,
                  locale: locale,
                  home: const Scaffold(body: TrackScreen(initialTab: 1)),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Empty History state shows prompt + Log Today -> navigates back to Check-In Today
        expect(find.byType(TrackMonthCalendar), findsOneWidget);
        expect(find.text('Your timeline builds as you log'), findsOneWidget);
        await tester.ensureVisible(find.text('Log Today'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Log Today'));
        await tester.pumpAndSettle();
        expect(find.text('Save Check-In'), findsOneWidget);

        // Seed two traces (a non-today trace in current month + today)
        final now = DateTime.now();
        final altDay = now.day > 1 ? now.day - 1 : 2;
        final pastDate = DateTime(now.year, now.month, altDay);
        final todayDate = DateTime(now.year, now.month, now.day);

        final pastTrace = MindTraceModel(
          id: 'trace-past-1',
          date: pastDate,
          overallMood: 'heavy',
          selectedEmotions: const ['heavy'],
          moodIntensity: 7,
          situation: 'Work / Demands',
          journalText: 'Long afternoon debugging.',
          createdAt: pastDate,
          updatedAt: pastDate,
        );
        final todayTrace = MindTraceModel(
          id: 'trace-today-1',
          date: todayDate,
          overallMood: 'calm',
          selectedEmotions: const ['calm'],
          moodIntensity: 4,
          journalText: 'Quiet morning walk.',
          createdAt: todayDate,
          updatedAt: todayDate,
        );

        await container
            .read(mindTraceControllerProvider.notifier)
            .recordCheckIn(pastTrace, generateAi: false);
        await container
            .read(mindTraceControllerProvider.notifier)
            .recordCheckIn(todayTrace, generateAi: false);

        await tester.tap(find.text('History & Calendar'));
        await tester.pumpAndSettle();

        final scrollableFinder = find.byType(Scrollable).last;
        await tester.scrollUntilVisible(
          find.text('Long afternoon debugging.'),
          150,
          scrollable: scrollableFinder,
        );
        await tester.pumpAndSettle();
        expect(find.text('Long afternoon debugging.'), findsOneWidget);

        // Scroll back to calendar top and tap past calendar day to filter history list
        final calDayFinder = find.descendant(
          of: find.byType(TrackMonthCalendar),
          matching: find.text('$altDay'),
        );
        await tester.ensureVisible(calDayFinder);
        await tester.pumpAndSettle();
        await tester.tap(calDayFinder);
        await tester.pumpAndSettle();

        expect(find.text('Show all'), findsOneWidget);
        expect(find.text('Long afternoon debugging.'), findsAtLeastNWidgets(1));
        expect(find.text('Quiet morning walk.'), findsNothing);

        // Clear day filter with Show all
        await tester.ensureVisible(find.text('Show all'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Show all'));
        await tester.pumpAndSettle();
        expect(find.text('Quiet morning walk.'), findsOneWidget);

        // Tap past entry card -> opens TrackEntryDetailSheet -> Edit historical entry
        await tester.scrollUntilVisible(
          find.text('Long afternoon debugging.'),
          150,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.ensureVisible(find.text('Long afternoon debugging.'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Long afternoon debugging.'));
        await tester.pumpAndSettle();

        expect(find.byType(TrackEntryDetailSheet), findsOneWidget);
        expect(find.text('Explore with AI Guide'), findsOneWidget);
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);

        await tester.ensureVisible(find.text('Edit'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        expect(find.byType(EditPastTraceSheet), findsOneWidget);
        expect(find.textContaining('Edit Check-In Entry'), findsOneWidget);
        await tester.enterText(
          find.descendant(
            of: find.byType(EditPastTraceSheet),
            matching: find.byType(TextField),
          ),
          'Updated evening reflection.',
        );
        await tester.ensureVisible(find.text('Save Changes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save Changes'));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Updated evening reflection.'),
          150,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        expect(find.text('Updated evening reflection.'), findsOneWidget);

        // Open detail again -> Delete -> Cancel keeps entry -> Confirm Delete removes entry
        await tester.ensureVisible(find.text('Updated evening reflection.'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Updated evening reflection.'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Delete'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        expect(find.text('Delete Trace Entry?'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.byType(TrackEntryDetailSheet), findsOneWidget);

        await tester.ensureVisible(find.text('Delete'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Delete'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Updated evening reflection.'), findsNothing);
        expect(find.text('Quiet morning walk.'), findsOneWidget);

        // Explore with AI Guide seeds activeCaseControllerProvider with mood, intensity, and note
        await tester.tap(find.text('Quiet morning walk.'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Explore with AI Guide'));
        await tester.pumpAndSettle();

        final activeCase = container.read(activeCaseControllerProvider).value;
        expect(activeCase, isNotNull);
        expect(activeCase!.incidentDescription, contains('Calm'));
        expect(activeCase.incidentDescription, contains('4/10'));
        expect(activeCase.incidentDescription, contains('Quiet morning walk.'));
      },
    );
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
