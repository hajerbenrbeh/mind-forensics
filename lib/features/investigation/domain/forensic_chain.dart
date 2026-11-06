import 'label_type.dart';

/// The core chain behind every case:
/// Trigger -> Thought -> Emotion -> Behavior
///
/// Section 3: "If the investigation flow asks about these four links
/// naturally, every saved case contains the raw material for all pattern
/// analysis. Cases must therefore be stored in a structured way from
/// version 1, even though patterns arrive later."
class ForensicChain {
  const ForensicChain({
    required this.trigger,
    required this.thought,
    required this.thoughtLabel,
    required this.emotion,
    required this.emotionIntensity,
    required this.behavior,
  });

  /// What set it off (a situation, person, time, or place).
  final String trigger;

  /// What the mind said about it.
  final String thought;

  /// Labeled Fact, Assumption, or Interpretation.
  final LabelType thoughtLabel;

  /// What the user felt (e.g., anxiety, sadness, anger).
  final String emotion;

  /// Intensity on a scale from 1 (mild) to 10 (overwhelming).
  final int emotionIntensity;

  /// What the user did next (e.g., withdrew, argued, avoided, ruminated).
  final String behavior;

  ForensicChain copyWith({
    String? trigger,
    String? thought,
    LabelType? thoughtLabel,
    String? emotion,
    int? emotionIntensity,
    String? behavior,
  }) {
    return ForensicChain(
      trigger: trigger ?? this.trigger,
      thought: thought ?? this.thought,
      thoughtLabel: thoughtLabel ?? this.thoughtLabel,
      emotion: emotion ?? this.emotion,
      emotionIntensity: emotionIntensity ?? this.emotionIntensity,
      behavior: behavior ?? this.behavior,
    );
  }

  Map<String, dynamic> toJson() => {
        'trigger': trigger,
        'thought': thought,
        'thoughtLabel': thoughtLabel.name,
        'emotion': emotion,
        'emotionIntensity': emotionIntensity,
        'behavior': behavior,
      };

  factory ForensicChain.fromJson(Map<String, dynamic> json) {
    return ForensicChain(
      trigger: json['trigger'] as String? ?? '',
      thought: json['thought'] as String? ?? '',
      thoughtLabel: LabelType.values.firstWhere(
        (e) => e.name == json['thoughtLabel'],
        orElse: () => LabelType.assumption,
      ),
      emotion: json['emotion'] as String? ?? '',
      emotionIntensity: (json['emotionIntensity'] as num?)?.toInt() ?? 5,
      behavior: json['behavior'] as String? ?? '',
    );
  }
}

