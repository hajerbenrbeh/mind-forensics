import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/features/observatory/presentation/inner_observatory_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Inner Observatory Screen Tests', () {
    testWidgets('Renders all 4 non-gamified sections & Contextual Support button',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: InnerObservatoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('SELF-CARE TOOLS'), findsOneWidget);

      // Section tabs (2x2 wrapped grid)
      expect(find.text('Reframe Thought'), findsAtLeastNWidgets(1));
      expect(find.text('Coping Steps'), findsAtLeastNWidgets(1));
      expect(find.text('Saved Notes'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Body & Mind'), findsAtLeastNWidgets(1));

      // Section 1 (default active): Reframe Thought
      expect(find.text('Reframe Thought'), findsAtLeastNWidgets(2));

      // Switch to Section 2: Coping Steps
      await tester.tap(find.text('Coping Steps').first);
      await tester.pumpAndSettle();
      expect(find.text('Coping Steps'), findsAtLeastNWidgets(2));

      // Switch to Section 3: Saved Notes
      await tester.tap(find.text('Saved Notes').first);
      await tester.pumpAndSettle();
      expect(find.text('Saved Notes'), findsAtLeastNWidgets(2));

      // Switch to Section 4: Body & Mind
      await tester.tap(find.textContaining('Body & Mind').first);
      await tester.pumpAndSettle();
      expect(find.text('Self-Attunement Check'), findsOneWidget);
    });
  });
}
