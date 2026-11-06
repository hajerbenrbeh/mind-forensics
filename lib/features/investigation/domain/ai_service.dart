import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/daily_usage_limiter.dart';
import 'ai_case_analysis.dart';
import 'case_model.dart';
import 'hypothesis.dart';

/// The single AI boundary interface for Mind Forensics.
///
/// COST AND DATA RULES:
/// - Develop entirely on the free Firebase Spark plan, with billing NOT linked.
/// - Use the Gemini free tier ONLY with fictional test text, never with real personal data.
/// - Default to the fake "test mode" in AiService ([MockAiService]).
/// - The Gemini free tier lets Google use submitted content to improve its products
///   and allows human review. Therefore, before ANY real user, the project must move
///   to the paid tier (billing linked), with budget alerts and spend caps.
///   Remind the team of this at Steps 10 and 14, and check the CURRENT official pricing
///   and data terms then.
abstract class AiService {
  /// Analyzes the case and returns structured findings, hypotheses, and safety level.
  Future<AiCaseAnalysis> analyzeCase(
    CaseModel currentCase, {
    bool allowPastHistory = true,
  });

  /// Conducts a gentle follow-up turn.
  Future<AiCaseAnalysis> askFollowUp(
    CaseModel currentCase,
    String userReply,
  );

  /// Produces a calm, structured findings summary for the final report.
  Future<String> summarizeCase(CaseModel currentCase);
}

/// A free, offline fake test mode simulating "The Warm Investigator".
///
/// Costs $0.00, requires zero internet and no API keys.
/// Default engine for all development and automated testing.
/// Strictly implements all forensic rules:
/// - Acknowledges feelings first.
/// - Questions before statements.
/// - Never diagnoses, always speaks in hypotheses.
/// - Uses fictional test scenarios only.
class MockAiService implements AiService {
  @override
  Future<AiCaseAnalysis> analyzeCase(
    CaseModel currentCase, {
    bool allowPastHistory = true,
  }) async {
    // Check daily rate limit to protect costs and prevent rumination
    final canProceed = await DailyUsageLimiter.canMakeRequest();
    if (!canProceed) {
      return const AiCaseAnalysis(
        message: DailyUsageLimiter.limitExceededMessage,
        safetyLevel: 0,
      );
    }
    await DailyUsageLimiter.recordRequest();

    // Simulate brief human-like pause for realism
    await Future.delayed(const Duration(milliseconds: 600));

    final incident = currentCase.incidentDescription.toLowerCase();

    // Check for distress cues
    int safety = 0;
    if (incident.contains('hopeless') || incident.contains('can’t do this anymore')) {
      safety = 1;
    }

    return AiCaseAnalysis(
      message:
          'That sounds like a really heavy moment to carry. Before we examine the thought, let’s separate what was directly observable from how your mind interpreted it.',
      followUpQuestions: const [
        'What was the exact moment or situation right before this feeling surfaced?',
        'If a close friend witnessed that moment, what observable fact would they describe?',
      ],
      hypotheses: const [
        Hypothesis(
          id: 'hyp-1',
          title: 'Protective Mindset',
          explanation:
              'Your mind might be anticipating the worst scenario to protect you from being hurt.',
          whyItMightFit:
              'It explains the speed with which a neutral event turned into a painful conclusion.',
          whatDoesNotFit:
              'There was no concrete confirmation from the other person indicating rejection.',
        ),
        Hypothesis(
          id: 'hyp-2',
          title: 'Situational Factor',
          explanation:
              'The other person may have simply been overwhelmed, busy, or distracted.',
          whyItMightFit: 'Delays and brief replies are common when people are under stress.',
          whatDoesNotFit: 'It doesn’t soothe the immediate feeling of being dismissed.',
        ),
      ],
      safetyLevel: safety,
    );
  }

  @override
  Future<AiCaseAnalysis> askFollowUp(
    CaseModel currentCase,
    String userReply,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return const AiCaseAnalysis(
      message:
          'I hear you. Notice how your mind holds onto that explanation. Is there any evidence that might challenge that assumption?',
      followUpQuestions: [
        'Has there ever been an occasion where things turned out differently than expected?',
      ],
      safetyLevel: 0,
    );
  }

  @override
  Future<String> summarizeCase(CaseModel currentCase) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final chain = currentCase.chain;
    final emotion = chain != null && chain.emotion.isNotEmpty ? chain.emotion : 'distress';

    return 'Cognitive Analysis Findings for ${currentCase.caseNumber}:\n\n'
        '• Observable Incident: The external situation occurred as described.\n'
        '• Underlying Reaction: The feeling of $emotion was amplified by an automatic assumption.\n'
        '• Explanations Considered: Multiple alternate interpretations exist that do not require assuming the worst.\n'
        '• Grounded Reality: You have examined the facts and hold the authority over your conclusion.';
  }
}

/// Riverpod provider for AiService.
/// Defaults to MockAiService so your app works completely free out of the box!
final aiServiceProvider = Provider<AiService>((ref) {
  return MockAiService();
});

