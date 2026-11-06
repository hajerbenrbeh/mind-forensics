import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/core/widgets/bouncing_widget.dart';
import 'package:mind_forensics/core/widgets/slide_to_anchor.dart';
import 'package:mind_forensics/features/investigation/presentation/widgets/somatic_body_radar.dart';
import 'package:mind_forensics/features/investigation/presentation/widgets/vagal_breathing_visualizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Interactive UX Widgets Tests', () {
    testWidgets('BouncingWidget renders child and responds to tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BouncingWidget(
              onTap: () => tapped = true,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      expect(find.text('Tap Me'), findsOneWidget);

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('SlideToAnchor renders track and prompt label', (tester) async {
      bool anchored = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideToAnchor(
              label: 'Slide to Anchor',
              onCompleted: () async => anchored = true,
            ),
          ),
        ),
      );

      expect(find.text('SLIDE TO ANCHOR'), findsOneWidget);
      expect(find.byIcon(Icons.anchor_rounded), findsOneWidget);
      expect(anchored, isFalse);
    });

    testWidgets('SomaticBodyRadar renders anatomical scanner and taps node', (tester) async {
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SomaticBodyRadar(
              selectedSensation: null,
              onSensationSelected: (s) => selected = s,
              isDark: true,
              arousalIntensity: 6.0,
            ),
          ),
        ),
      );

      expect(find.text('SOMATOSENSORY RADAR'), findsOneWidget);
      expect(find.text('TAP TO LOCATE'), findsOneWidget);

      // Find one of the gesture detectors
      final gestureFinders = find.byType(GestureDetector);
      expect(gestureFinders, findsWidgets);

      await tester.tap(gestureFinders.first);
      await tester.pump(const Duration(milliseconds: 100));

      expect(selected, isNotNull);
    });

    testWidgets('VagalBreathingVisualizer displays seconds and phase', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VagalBreathingVisualizer(
              phase: 0,
              secondsLeft: 4,
              phaseText: 'Inhale',
              isDark: true,
            ),
          ),
        ),
      );

      expect(find.text('4'), findsOneWidget);
      expect(find.text('INHALE'), findsOneWidget);
    });
  });
}
