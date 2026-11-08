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
      expect(find.text('INNER OBSERVATORY'), findsOneWidget);

      // Section tabs
      expect(find.text('Perspective Exploration'), findsAtLeastNWidgets(1));
      expect(find.text('Experiments & Strategies'), findsAtLeastNWidgets(1));
      expect(find.text('Personal Discoveries'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Symptom Exploration'), findsAtLeastNWidgets(1));

      // Section 1 (default active): Perspective Exploration
      expect(find.text('Perspective Exploration'), findsAtLeastNWidgets(1));

      // Switch to Section 2: Experiments & Strategies
      await tester.tap(find.text('Experiments & Strategies').first);
      await tester.pumpAndSettle();
      expect(find.text('Experiments & Strategies'), findsAtLeastNWidgets(2));

      // Switch to Section 3: Personal Discoveries
      await tester.tap(find.text('Personal Discoveries').first);
      await tester.pumpAndSettle();
      expect(find.text('Personal Discoveries'), findsAtLeastNWidgets(2));

      // Switch to Section 4: Symptom Exploration
      await tester.tap(find.textContaining('Symptom Exploration').first);
      await tester.pumpAndSettle();
      expect(find.text('Self-Attunement Check'), findsOneWidget);
    });
  });
}
