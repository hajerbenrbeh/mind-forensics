import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_badge.dart';
import '../../../investigation/domain/case_model.dart';

/// Clean, modular Active Case Card for HomeScreen.
/// Displays active investigation progress, stage indicator, and resume button.
class HomeActiveCaseCard extends StatelessWidget {
  const HomeActiveCaseCard({
    super.key,
    required this.caseModel,
    required this.tokens,
    required this.strings,
    required this.isDark,
    required this.onResume,
  });

  final CaseModel caseModel;
  final MindTokens tokens;
  final AppStrings strings;
  final bool isDark;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final progress = caseModel.currentStage.stepNumber / 6.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: tokens.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MindBadge(
                label:
                    '${strings.formatSessionNumber(caseModel.caseNumber)}  •  ${strings.stageNumberLabel(caseModel.currentStage.stepNumber)}',
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: tokens.textSecondary),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            caseModel.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: tokens.surfaceSecondary,
              valueColor: AlwaysStoppedAnimation<Color>(tokens.accent),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onResume();
              },
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? tokens.accent : const Color(0xFF34443B),
                foregroundColor: isDark ? const Color(0xFF151B19) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                strings.resumeInvestigation,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
