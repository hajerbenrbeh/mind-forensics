import 'hypothesis.dart';
import 'label_type.dart';

/// The strict structured response returned by the Warm Investigator.
///
/// Section 8 & Step 8: The AI answers in a fixed structure,
/// not free-form text, so the app renders reliably without crashes.
class AiCaseAnalysis {
  const AiCaseAnalysis({
    required this.message,
    this.followUpQuestions = const [],
    this.hypotheses = const [],
    this.statementLabels = const {},
    this.safetyLevel = 0,
  });

  /// The main supportive text shown to the user.
  final String message;

  /// Short, gentle follow-up questions to test rigidity.
  final List<String> followUpQuestions;

  /// Candidate explanations (each with "why it might fit" & "what does not fit").
  final List<Hypothesis> hypotheses;

  /// Suggested forensic labels for statements in the case.
  final Map<String, LabelType> statementLabels;

  /// Triage level: 0 = Normal, 1 = Elevated distress, 2 = Gentle crisis pause.
  final int safetyLevel;

  factory AiCaseAnalysis.fromJson(Map<String, dynamic> json) {
    return AiCaseAnalysis(
      message: json['message'] as String? ?? 'I am here with you to examine this thought.',
      followUpQuestions: (json['followUpQuestions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      hypotheses: (json['hypotheses'] as List<dynamic>?)
              ?.map((e) => Hypothesis.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      statementLabels: (json['statementLabels'] as Map<String, dynamic>?)?.map(
            (key, val) => MapEntry(
              key,
              LabelType.values.firstWhere(
                (l) => l.name == val,
                orElse: () => LabelType.assumption,
              ),
            ),
          ) ??
          const {},
      safetyLevel: (json['safetyLevel'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'message': message,
        'followUpQuestions': followUpQuestions,
        'hypotheses': hypotheses.map((h) => h.toJson()).toList(),
        'statementLabels':
            statementLabels.map((key, val) => MapEntry(key, val.name)),
        'safetyLevel': safetyLevel,
      };

  /// Fallback response if parsing ever fails (never crash the app).
  static const fallback = AiCaseAnalysis(
    message:
        'I am listening carefully. Let’s look at the observable facts of what happened together.',
    safetyLevel: 0,
  );
}

