import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/mind_trace/presentation/mind_trace_screen.dart';
import 'package:mind_forensics/features/mind_trace/presentation/widgets/pattern_discovery_view.dart';
import 'package:mind_forensics/features/mind_trace/presentation/widgets/thought_trace_detail_sheet.dart';
import 'package:mind_forensics/features/mind_trace/presentation/widgets/thought_trace_timeline_view.dart';
import 'package:mind_forensics/features/mind_trace/presentation/widgets/trace_investigation_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Daily Mind Trace & The Thought Trace UI Tests', () {
    testWidgets('MindTraceScreen renders opening poetic quote and core inputs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MindTraceScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and tabs
      expect(find.text('DAILY MIND TRACE'), findsAtLeastNWidgets(1));
      expect(find.text('CHECK-IN'), findsOneWidget);
      expect(find.text('THE THOUGHT TRACE'), findsOneWidget);
      expect(find.text('PATTERN EXPLORATION'), findsOneWidget);

      // Check opening text quote
      expect(
        find.text('“Every day leaves a trace. What does yours look like today?”'),
        findsOneWidget,
      );

      // Check 14-emotion library cards (Step 1)
      expect(find.text('Happy'), findsOneWidget);
      expect(find.text('Calm'), findsOneWidget);
      expect(find.text('Sad'), findsOneWidget);
      expect(find.text('Anxious'), findsOneWidget);
      expect(find.text('Overwhelmed'), findsOneWidget);
      expect(find.text('Custom emotion'), findsOneWidget);

      // Step navigation: select emotion and tap CONTINUE
      await tester.tap(find.text('Calm'));
      await tester.pumpAndSettle();
      expect(find.text('CONTINUE'), findsOneWidget);
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();

      // Step 2: Intensity scale (1-10)
      expect(find.text('2. EMOTIONAL INTENSITY'), findsOneWidget);
      expect(find.text('/ 10'), findsOneWidget);
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();

      // Step 3: Mind check
      expect(find.text('3. HOW IS YOUR MIND?'), findsOneWidget);
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();

      // Step 4: Body check & final submission (options-first 4-step wizard)
      expect(find.text('4. HOW IS YOUR BODY?'), findsOneWidget);
      expect(find.text('RECORD DAILY THOUGHT TRACE'), findsOneWidget);
      expect(find.text('5. PERSONAL REFLECTION'), findsNothing);
    });

    testWidgets('ThoughtTraceTimelineView renders search, filters, and grouped timeline entries',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final traces = [
        MindTraceModel(
          id: 't1',
          date: now,
          overallMood: 'calm',
          selectedEmotions: const ['Calm', 'Content'],
          moodIntensity: 4,
          journalText: 'A quiet morning enjoying coffee in solitude.',
          situation: 'Sitting on the balcony before work.',
          createdAt: now,
          updatedAt: now,
        ),
        MindTraceModel(
          id: 't2',
          date: now.subtract(const Duration(days: 1)),
          overallMood: 'anxious',
          selectedEmotions: const ['Anxious', 'Restless'],
          moodIntensity: 8,
          journalText: 'Deadline approaching rapidly, feeling hurried.',
          situation: 'Work project review meeting.',
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      SharedPreferences.setMockInitialValues({
        'mf_mind_traces_v1': jsonEncode(traces.map((t) => t.toJson()).toList()),
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ThoughtTraceTimelineView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header and concept quote
      expect(find.text('THE THOUGHT TRACE'), findsOneWidget);
      expect(
        find.textContaining('Every thought leaves a trace'),
        findsOneWidget,
      );

      // Verify search bar and filter pills
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Investigated'), findsOneWidget);

      // Verify entries rendered in timeline
      expect(find.text('“A quiet morning enjoying coffee in solitude.”'), findsOneWidget);
      expect(find.text('“Deadline approaching rapidly, feeling hurried.”'), findsOneWidget);
    });

    testWidgets('ThoughtTraceDetailSheet and TraceInvestigationSheet allow Socratic inquiry',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final trace = MindTraceModel(
        id: 't_inspect',
        date: now,
        overallMood: 'overwhelmed',
        selectedEmotions: const ['Overwhelmed'],
        moodIntensity: 7,
        journalText: 'Feeling like I will let everyone down if this fails.',
        situation: 'Preparing a presentation.',
        behavioralResponse: 'Procrastinating on social media.',
        createdAt: now,
        updatedAt: now,
      );

      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ThoughtTraceDetailSheet(trace: trace),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify thought quotation
      expect(find.text('“Feeling like I will let everyone down if this fails.”'), findsOneWidget);
      expect(find.text('INVESTIGATE THIS THOUGHT'), findsOneWidget);

      // Verify context displayed
      expect(find.text('Preparing a presentation.'), findsOneWidget);
      expect(find.text('Procrastinating on social media.'), findsOneWidget);

      // Test TraceInvestigationSheet directly
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TraceInvestigationSheet(trace: trace),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify 6 Socratic inquiries
      expect(find.text('INVESTIGATE THIS THOUGHT'), findsOneWidget);
      expect(find.text('What happened before this thought appeared?'), findsOneWidget);
      expect(find.text('What was I feeling?'), findsOneWidget);
      expect(find.text('What did I believe was happening?'), findsOneWidget);
      expect(find.text('What did I do in response?'), findsOneWidget);
      expect(find.text('Is this something I have noticed before?'), findsOneWidget);
      expect(find.text('What would I like to understand about this experience?'), findsOneWidget);
      expect(find.text('SAVE INVESTIGATION TO TRACE'), findsOneWidget);
    });

    testWidgets('PatternDiscoveryView renders filter buttons, statistics, and milestones',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final traces = [
        MindTraceModel(
          id: 't1',
          date: now,
          overallMood: 'calm',
          selectedEmotions: const ['Content', 'Gratitude'],
          moodIntensity: 6,
          energyLevel: 7,
          sleepHours: 7.5,
          physicalTension: 3,
          situation: 'Morning walk in the park',
          behavioralResponse: 'Deep breathing',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PatternDiscoveryView(traces: traces),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify filters and metrics
      expect(find.text('7 DAYS'), findsOneWidget);
      expect(find.text('30 DAYS'), findsOneWidget);
      expect(find.text('AVG INTENSITY'), findsOneWidget);
      expect(find.text('AVG ENERGY'), findsOneWidget);
      expect(find.text('REPORTED EMOTIONAL SPECTRUM'), findsOneWidget);
      expect(find.text('RECURRING CONTEXT & COPING THEMES'), findsOneWidget);

      // Verify milestones
      expect(find.text('THOUGHT & REFLECTION MILESTONES'), findsOneWidget);
      expect(find.text('First Thought Trace'), findsOneWidget);
    });
  });
}
