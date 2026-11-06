import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/data/local_case_repository.dart';
import 'package:mind_forensics/features/investigation/data/mock_investigator_service.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/forensic_chain.dart';
import 'package:mind_forensics/features/investigation/domain/label_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Investigation & Repository Unit Tests', () {
    test('LocalCaseRepository persists and retrieves cases across instances', () async {
      final repo1 = LocalCaseRepository();
      final caseNumber = await repo1.getNextCaseNumber();
      expect(caseNumber, equals('SESSION 01'));

      final nextCaseNumber = await repo1.getNextCaseNumber();
      expect(nextCaseNumber, equals('SESSION 02'));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final newCase = await container
          .read(activeCaseControllerProvider.notifier)
          .startNewCase('Late night text anxiety');

      expect(newCase.title, equals('Late night text anxiety'));
      expect(newCase.currentStage, equals(CaseStage.incident));

      // Advance stage to evidence
      await container
          .read(activeCaseControllerProvider.notifier)
          .advanceStage(CaseStage.evidence);

      expect(
        container.read(activeCaseControllerProvider).value?.currentStage,
        equals(CaseStage.evidence),
      );

      // Record Forensic Chain
      const chain = ForensicChain(
        trigger: 'Message delivered but unread',
        thought: 'They are deliberately ignoring me',
        thoughtLabel: LabelType.assumption,
        emotion: 'Severe Anxiety',
        emotionIntensity: 8,
        behavior: 'Checked screen repeatedly',
      );

      await container
          .read(activeCaseControllerProvider.notifier)
          .recordChain(chain);

      final updatedCase = container.read(activeCaseControllerProvider).value;
      expect(updatedCase?.chain?.thought, equals('They are deliberately ignoring me'));
      expect(updatedCase?.chain?.thoughtLabel, equals(LabelType.assumption));

      // Save Conclusion
      await container
          .read(activeCaseControllerProvider.notifier)
          .saveConclusion('Realized it was my internal fear, not their malice.');

      final completedCase = container.read(activeCaseControllerProvider).value;
      expect(completedCase?.isCompleted, isTrue);
      expect(completedCase?.userConclusion, contains('internal fear'));

      // Verify persistent storage via repo
      final repoCases = await container.read(caseRepositoryProvider).getAllCases();
      expect(repoCases.length, equals(1));
      expect(repoCases.first.id, equals(newCase.id));
    });

    test('MockInvestigatorService generates trilingual hypotheses accurately', () async {
      final container = ProviderContainer(
        overrides: [
          investigatorServiceProvider.overrideWithValue(MockInvestigatorService()),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(investigatorServiceProvider);
      final testCase = await container
          .read(activeCaseControllerProvider.notifier)
          .startNewCase('Mock Case');

      // Test Arabic
      final arHypotheses = await service.generateHypotheses(
        currentCase: testCase,
        languageCode: 'ar',
      );
      expect(arHypotheses.length, equals(3));
      expect(arHypotheses.first.title, contains('استباق'));

      // Test French
      final frHypotheses = await service.generateHypotheses(
        currentCase: testCase,
        languageCode: 'fr',
      );
      expect(frHypotheses.length, equals(3));
      expect(frHypotheses.first.title, contains('Anticipation'));

      // Test English
      final enHypotheses = await service.generateHypotheses(
        currentCase: testCase,
        languageCode: 'en',
      );
      expect(enHypotheses.length, equals(3));
      expect(enHypotheses.first.title, contains('Anticipation'));
    });
  });
}

