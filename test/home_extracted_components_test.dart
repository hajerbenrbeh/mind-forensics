import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/theme/lab_colors.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_active_case_card.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_daily_check_in_card.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';

void main() {
  group('Home Extracted Components Unit & Widget Tests', () {
    const tokens = MindTokens.dark;
    const strings = AppStrings('en');

    final moodOptions = const [
      (key: 'calm', icon: Icons.spa_outlined),
      (key: 'anxious', icon: Icons.bolt_outlined),
      (key: 'frustrated', icon: Icons.local_fire_department_outlined),
    ];

    testWidgets('HomeDailyCheckInCard renders options-first check-in controls and triggers callbacks', (tester) async {
      int selectedIdx = 0;
      double intensity = 5.0;
      bool saved = false;
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return HomeDailyCheckInCard(
                  tokens: tokens,
                  strings: strings,
                  isDark: true,
                  todayTrace: null,
                  traces: const [],
                  selectedMoodIndex: selectedIdx,
                  moodIntensity: intensity,
                  todayNoteController: controller,
                  moodOptions: moodOptions,
                  onMoodSelected: (idx) => setState(() => selectedIdx = idx),
                  onIntensityChanged: (val) => setState(() => intensity = val),
                  onSave: () => saved = true,
                  getMoodLabel: (key, str) => key.toUpperCase(),
                  getMoodColor: (key) => LabColors.moodCalm,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify emotion pills and intensity header
      expect(find.text('${strings.moodIntensityLabel.toUpperCase()}: 5/10'), findsOneWidget);
      expect(find.text('CALM'), findsOneWidget);
      expect(find.text('ANXIOUS'), findsOneWidget);

      // Select 'ANXIOUS'
      await tester.tap(find.text('ANXIOUS'));
      await tester.pumpAndSettle();
      expect(selectedIdx, equals(1));

      // Enter optional text note
      await tester.enterText(find.byType(TextField), 'Calibrated evening walk');
      await tester.pumpAndSettle();
      expect(controller.text, equals('Calibrated evening walk'));

      // Tap Save Check-in
      await tester.tap(find.text(strings.saveCheckInButton));
      await tester.pumpAndSettle();
      expect(saved, isTrue);
    });

    testWidgets('HomeActiveCaseCard renders case progress and invokes onResume', (tester) async {
      bool resumed = false;
      final testCase = CaseModel(
        id: 'c1',
        caseNumber: 'CASE 07',
        title: 'Workplace presentation tension',
        incidentDescription: 'High somatic pressure during presentation',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentStage: CaseStage.evidence,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeActiveCaseCard(
              caseModel: testCase,
              tokens: tokens,
              strings: strings,
              isDark: true,
              onResume: () => resumed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Workplace presentation tension'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text(strings.resumeInvestigation), findsOneWidget);

      await tester.tap(find.text(strings.resumeInvestigation));
      await tester.pumpAndSettle();
      expect(resumed, isTrue);
    });
  });
}
