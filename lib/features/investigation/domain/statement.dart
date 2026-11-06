import 'label_type.dart';

/// Speaker in an investigative turn.
enum StatementSpeaker {
  user,
  investigator,
}

/// A statement collected during the investigation.
///
/// Section 2: "Every statement in a case carries one of three labels.
/// This is the core visual and conceptual device of the app."
class Statement {
  const Statement({
    required this.id,
    required this.text,
    required this.speaker,
    this.label,
    this.distortionTag,
    required this.timestamp,
  });

  final String id;
  final String text;
  final StatementSpeaker speaker;
  final LabelType? label;
  final String? distortionTag;
  final DateTime timestamp;

  Statement copyWith({
    String? id,
    String? text,
    StatementSpeaker? speaker,
    LabelType? label,
    String? distortionTag,
    DateTime? timestamp,
  }) {
    return Statement(
      id: id ?? this.id,
      text: text ?? this.text,
      speaker: speaker ?? this.speaker,
      label: label ?? this.label,
      distortionTag: distortionTag ?? this.distortionTag,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'speaker': speaker.name,
        'label': label?.name,
        'distortionTag': distortionTag,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Statement.fromJson(Map<String, dynamic> json) {
    return Statement(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      speaker: json['speaker'] == 'investigator'
          ? StatementSpeaker.investigator
          : StatementSpeaker.user,
      label: json['label'] != null
          ? LabelType.values.firstWhere(
              (e) => e.name == json['label'],
              orElse: () => LabelType.assumption,
            )
          : null,
      distortionTag: json['distortionTag'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

