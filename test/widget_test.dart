import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Mind Forensics App smoke test with 4 bottom tabs and options-first Daily Check-in', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: MindForensicsApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify that the header renders
    expect(find.text('Mind Forensics'), findsOneWidget);

    // 2. Verify all 4 persistent bottom navigation tabs (clean 4-tab bar)
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Investigator'), findsOneWidget);
    expect(find.text('Toolkit'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Journal'), findsNothing);

    // 3. Verify options-first Daily check-in elements on Home screen (no compulsory note)
    expect(find.text('Log Daily Check-in'), findsOneWidget);
  });
}
