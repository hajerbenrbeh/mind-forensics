/// Represents an explanatory hypothesis proposed during an investigation.
///
/// Section 3 & 7: Hypotheses are possible explanations proposed by the AI.
/// "Always several, never one verdict."
/// Each hypothesis includes "why it might fit" and "what does not fit".
class Hypothesis {
  const Hypothesis({
    required this.id,
    required this.title,
    required this.explanation,
    required this.whyItMightFit,
    required this.whatDoesNotFit,
  });

  final String id;
  final String title;
  final String explanation;
  final String whyItMightFit;
  final String whatDoesNotFit;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'explanation': explanation,
        'whyItMightFit': whyItMightFit,
        'whatDoesNotFit': whatDoesNotFit,
      };

  factory Hypothesis.fromJson(Map<String, dynamic> json) {
    return Hypothesis(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      whyItMightFit: json['whyItMightFit'] as String? ?? '',
      whatDoesNotFit: json['whatDoesNotFit'] as String? ?? '',
    );
  }
}

