import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/features/case_file/data/clinical_export_log_service.dart';
import 'package:mind_forensics/features/case_file/data/clinical_export_service.dart';
import 'package:mind_forensics/features/investigation/data/local_case_repository.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/forensic_chain.dart';
import 'package:mind_forensics/features/investigation/domain/hypothesis.dart';
import 'package:mind_forensics/features/investigation/domain/label_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Clinical Sharing & Privacy Shield Tests (Step 12)', () {
    test('CaseModel isPrivate defaults to false and round-trips via JSON', () {
      final now = DateTime.now();
      final case1 = CaseModel(
        id: 'test-1',
        caseNumber: 'SESSION 01',
        title: 'Meeting dread',
        createdAt: now,
        updatedAt: now,
        currentStage: CaseStage.conclusion,
        incidentDescription: 'Upcoming presentation anxiety',
      );

      expect(case1.isPrivate, isFalse);

      final json = case1.toJson();
      expect(json['isPrivate'], isFalse);

      final case2 = case1.copyWith(isPrivate: true);
      expect(case2.isPrivate, isTrue);

      final json2 = case2.toJson();
      expect(json2['isPrivate'], isTrue);

      final restored = CaseModel.fromJson(json2);
      expect(restored.isPrivate, isTrue);
    });

    test('LocalCaseRepository toggleCasePrivacy modifies state and persists', () async {
      final repo = LocalCaseRepository();
      final now = DateTime.now();
      final testCase = CaseModel(
        id: 'case-toggle-test',
        caseNumber: 'SESSION 01',
        title: 'Work confrontation',
        createdAt: now,
        updatedAt: now,
        currentStage: CaseStage.conclusion,
        incidentDescription: 'Disagreeing with manager',
        isPrivate: false,
      );

      await repo.saveCase(testCase);

      var fetched = await repo.getCaseById('case-toggle-test');
      expect(fetched?.isPrivate, isFalse);

      // Toggle privacy to true
      await repo.toggleCasePrivacy('case-toggle-test');
      fetched = await repo.getCaseById('case-toggle-test');
      expect(fetched?.isPrivate, isTrue);

      // Toggle back to false
      await repo.toggleCasePrivacy('case-toggle-test');
      fetched = await repo.getCaseById('case-toggle-test');
      expect(fetched?.isPrivate, isFalse);
    });

    test('ClinicalExportService excludes private cases and includes clinical disclaimers', () {
      const stringsEn = AppStrings('en');
      final now = DateTime.now();

      final shareableCase = CaseModel(
        id: 'c1',
        caseNumber: 'SESSION 01',
        title: 'Late reply catastrophe',
        createdAt: now,
        updatedAt: now,
        currentStage: CaseStage.conclusion,
        incidentDescription: 'Colleague did not reply for 4 hours',
        chain: const ForensicChain(
          trigger: 'Unanswered Slack message',
          thought: 'They resent working with me',
          thoughtLabel: LabelType.assumption,
          emotion: 'Anxiety',
          emotionIntensity: 7,
          behavior: 'Drafted defensive follow-up email',
        ),
        hypotheses: const [
          Hypothesis(
            id: 'h1',
            title: 'Deep Focus Work',
            explanation: 'Colleague is heads down on a production launch.',
            whyItMightFit: 'They mentioned a tight deadline yesterday.',
            whatDoesNotFit: 'They were friendly during the morning standup.',
          ),
        ],
        userConclusion: 'Decided to wait until tomorrow before assuming malice.',
        isPrivate: false,
      );

      final privateCase = CaseModel(
        id: 'c2',
        caseNumber: 'SESSION 02',
        title: 'Family conflict',
        createdAt: now,
        updatedAt: now,
        currentStage: CaseStage.conclusion,
        incidentDescription: 'Private sensitive matter',
        isPrivate: true,
      );

      // Both cases passed in
      final brief = ClinicalExportService.generateSessionBrief(
        cases: [shareableCase, privateCase],
        strings: stringsEn,
        recipientOrNote: 'Dr. Ben Ammar',
      );

      // Verify clinical disclaimer requirements
      expect(brief, contains('CLINICAL NOTICE & DISCLAIMER'));
      expect(brief, contains('inspired by CBT'));
      expect(brief, isNot(contains('CBT treatment')));
      expect(brief, contains('exploratory cognitive possibilities'));
      expect(brief, contains('never predicts relapse'));

      // Verify shareable case is included
      expect(brief, contains('SESSION 01 — "Late reply catastrophe"'));
      expect(brief, contains('They resent working with me'));
      expect(brief, contains('ASSUMPTION'));
      expect(brief, contains('Deep Focus Work'));
      expect(brief, contains('Decided to wait until tomorrow'));

      // Verify private case is strictly excluded
      expect(brief, isNot(contains('SESSION 02')));
      expect(brief, isNot(contains('Family conflict')));
      expect(brief, isNot(contains('Private sensitive matter')));
    });

    test('ClinicalExportService generates authentic Tunisian Arabic with proper dialect', () {
      const stringsAr = AppStrings('ar');
      final now = DateTime.now();

      final testCase = CaseModel(
        id: 'c-ar',
        caseNumber: 'SESSION 03',
        title: 'ضغط الخدمة',
        createdAt: now,
        updatedAt: now,
        currentStage: CaseStage.conclusion,
        incidentDescription: 'المدير طلب تقرير مستعجل',
        chain: const ForensicChain(
          trigger: 'إيميل عاجل',
          thought: 'باش يطردوني من الخدمة',
          thoughtLabel: LabelType.assumption,
          emotion: 'قلق وخوف',
          emotionIntensity: 9,
          behavior: 'تشنج وعزلة',
        ),
        userConclusion: 'فهمت اللي هذا استباق دفاعي وطلبت توضيح برزانة.',
        isPrivate: false,
      );

      final briefAr = ClinicalExportService.generateSessionBrief(
        cases: [testCase],
        strings: stringsAr,
      );

      expect(briefAr, contains('MIND FORENSICS — ملخص الجلسات السريري'));
      expect(briefAr, contains('مستوحاة من مبادئ العلاج السلوكي المعرفي (CBT)'));
      expect(briefAr, contains('الفرضيات المولدة بواسطة الذكاء الاصطناعي هي نماذج فكرية استكشافية'));
      expect(briefAr, contains('لا يتنبأ بالانتكاس النفسي'));
      expect(briefAr, contains('باش يطردوني من الخدمة'));
    });

    test('ClinicalExportLogService stores, retrieves, and clears visible audit history', () async {
      final logService = ClinicalExportLogService();

      var records = await logService.getRecords();
      expect(records, isEmpty);

      // Log first export
      await logService.logExport(
        sessionNumbers: ['SESSION 01', 'SESSION 02'],
        recipientOrNote: 'Dr. Ben Ammar - Session 3',
      );

      records = await logService.getRecords();
      expect(records.length, equals(1));
      expect(records.first.sessionNumbers, equals(['SESSION 01', 'SESSION 02']));
      expect(records.first.recipientOrNote, equals('Dr. Ben Ammar - Session 3'));

      // Log second export
      await logService.logExport(
        sessionNumbers: ['SESSION 03'],
        recipientOrNote: 'Personal Archive',
      );

      records = await logService.getRecords();
      expect(records.length, equals(2));
      expect(records.first.sessionNumbers, equals(['SESSION 03']));

      // Clear history
      await logService.clearHistory();
      records = await logService.getRecords();
      expect(records, isEmpty);
    });
  });
}
