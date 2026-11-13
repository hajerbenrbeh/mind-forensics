import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/theme/lab_colors.dart';
import 'package:mind_forensics/core/widgets/fingerprint_thread_signature.dart';
import 'package:mind_forensics/core/widgets/neural_brain_wireframe.dart';
import 'package:mind_forensics/core/widgets/radial_mood_dial.dart';
import 'package:mind_forensics/core/widgets/slide_to_anchor.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/investigation/presentation/widgets/somatic_body_radar.dart';
import 'package:mind_forensics/features/investigation/presentation/widgets/vagal_breathing_visualizer.dart';
import 'package:mind_forensics/features/support/presentation/contextual_support_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Phase 8 Accessibility & Reduced Motion Guidelines', () {
    testWidgets('RadialMoodDial meets tap target and labeled button guidelines',
        (tester) async {
      final handle = tester.ensureSemantics();
      try {
        int selected = 2;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: Center(
                child: RadialMoodDial(
                  moods: const [
                    MoodItem(key: 'heavy', label: 'Heavy', icon: Icons.cloud_outlined),
                    MoodItem(key: 'tense', label: 'Tense', icon: Icons.bolt_outlined),
                    MoodItem(key: 'steady', label: 'Steady', icon: Icons.spa_outlined),
                    MoodItem(key: 'calm', label: 'Calm', icon: Icons.water_outlined),
                  ],
                  selectedIndex: selected,
                  onChanged: (idx) => selected = idx,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        expect(find.bySemanticsLabel('Calm'), findsOneWidget);
        await tester.tap(find.bySemanticsLabel('Calm'));
        expect(selected, 3);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('SlideToAnchor supports TalkBack SemanticsAction.tap activation',
        (tester) async {
      final handle = tester.ensureSemantics();
      try {
        var completed = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SlideToAnchor(
                    label: 'Slide to save anchor',
                    onCompleted: () async {
                      completed = true;
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        tester.semantics.tap(find.semantics.byLabel('Slide to save anchor'));
        await tester.pumpAndSettle();

        expect(completed, isTrue);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('SomaticBodyRadar nodes meet 48dp guidelines and expose labels',
        (tester) async {
      final handle = tester.ensureSemantics();
      try {
        String? picked;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 340,
                  child: SomaticBodyRadar(
                    selectedSensation: 'Chest tightness',
                    onSensationSelected: (val) => picked = val,
                    isDark: true,
                    arousalIntensity: 6,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        await tester.tap(find.bySemanticsLabel('Cranial / Head'));
        expect(picked, 'Cranial / Head');
      } finally {
        handle.dispose();
      }
    });

    testWidgets('Reduced motion disables infinite loops and settles cleanly',
        (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: const Scaffold(
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FingerprintThreadSignature(
                      size: 72,
                      animated: true,
                      primaryColor: LabColors.warmBeige,
                      accentColor: LabColors.sageGreen,
                    ),
                    NeuralBrainWireframe(size: 80, animate: true),
                    VagalBreathingVisualizer(
                      phase: 0,
                      secondsLeft: 4,
                      phaseText: 'Inhale',
                      isDark: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Should settle immediately without timing out under disableAnimations: true.
        await tester.pumpAndSettle();
        expect(find.byType(VagalBreathingVisualizer), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('ContextualSupportSheet meets Android/iOS/labeled guidelines',
        (tester) async {
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
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

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('HomeScreen meets labeled and tap target guidelines',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      } finally {
        handle.dispose();
      }
    });
  });
}
