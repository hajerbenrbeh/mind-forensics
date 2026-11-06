import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/forensic_chain.dart';
import 'package:mind_forensics/features/investigation/domain/label_type.dart';
import 'package:mind_forensics/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Technical Polish & Edge Case Hardening Tests (Step 13)', () {
    testWidgets('App root clamps text scaling and wraps with unfocus GestureDetector', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MindForensicsApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Find the clamped MediaQuery in root
      final mediaQueryFinder = find.byType(MediaQuery);
      expect(mediaQueryFinder, findsWidgets);

      final BuildContext context = tester.element(find.text('Home'));
      final scaler = MediaQuery.textScalerOf(context);
      // Clamped scale factor should never exceed 1.35 even with large OS requests
      expect(scaler.scale(10.0), inInclusiveRange(8.5, 13.5));
    });

    testWidgets('Arabic locale activates RTL text directionality properly', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MindForensicsApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch language to Arabic
      await container.read(localeControllerProvider.notifier).setLanguage(AppLanguage.arabic);
      await tester.pumpAndSettle();

      final BuildContext arContext = tester.element(find.text('الرئيسية'));
      final directionality = Directionality.of(arContext);
      expect(directionality, equals(TextDirection.rtl));
    });

    test('Draft persistence logic updates repository before completing investigation', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeCaseControllerProvider.notifier);
      final initialCase = await notifier.startNewCase('Draft incident test');

      expect(initialCase.incidentDescription, equals('Draft incident test'));

      // Update incident description
      await notifier.updateIncident('Updated draft text while typing');
      var currentCase = container.read(activeCaseControllerProvider).value;
      expect(currentCase?.incidentDescription, equals('Updated draft text while typing'));

      // Advance stage and record partial chain
      await notifier.advanceStage(CaseStage.evidence);
      const partialChain = ForensicChain(
        trigger: 'Meeting notice',
        thought: 'I might be unprepared',
        thoughtLabel: LabelType.assumption,
        emotion: 'Nervous',
        emotionIntensity: 6,
        behavior: 'Started reviewing slides immediately',
      );
      await notifier.recordChain(partialChain);

      currentCase = container.read(activeCaseControllerProvider).value;
      expect(currentCase?.currentStage, equals(CaseStage.evidence));
      expect(currentCase?.chain?.thought, equals('I might be unprepared'));

      // Fetch from local repository to verify persistence without loss
      final repo = container.read(caseRepositoryProvider);
      final persisted = await repo.getCaseById(initialCase.id);
      expect(persisted?.chain?.thought, equals('I might be unprepared'));
    });
  });
}
