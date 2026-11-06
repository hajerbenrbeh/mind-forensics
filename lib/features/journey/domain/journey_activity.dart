import 'journey_phase.dart';

/// An individual psychological exercise, educational exploration, or reflection module.
class JourneyActivity {
  const JourneyActivity({
    required this.id,
    required this.phase,
    required this.title,
    required this.purpose,
    required this.shortExplanation,
    required this.guidedInstructions,
    required this.reflectionQuestions,
    this.isCompleted = false,
    this.completedAt,
    this.personalNotes = '',
    this.reflectionAnswers = const {},
  });

  final String id;
  final JourneyPhase phase;
  final String title;
  final String purpose;
  final String shortExplanation;
  final List<String> guidedInstructions;
  final List<String> reflectionQuestions;
  final bool isCompleted;
  final DateTime? completedAt;
  final String personalNotes;
  final Map<String, String> reflectionAnswers;

  JourneyActivity copyWith({
    String? id,
    JourneyPhase? phase,
    String? title,
    String? purpose,
    String? shortExplanation,
    List<String>? guidedInstructions,
    List<String>? reflectionQuestions,
    bool? isCompleted,
    DateTime? completedAt,
    String? personalNotes,
    Map<String, String>? reflectionAnswers,
  }) {
    return JourneyActivity(
      id: id ?? this.id,
      phase: phase ?? this.phase,
      title: title ?? this.title,
      purpose: purpose ?? this.purpose,
      shortExplanation: shortExplanation ?? this.shortExplanation,
      guidedInstructions: guidedInstructions ?? this.guidedInstructions,
      reflectionQuestions: reflectionQuestions ?? this.reflectionQuestions,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      personalNotes: personalNotes ?? this.personalNotes,
      reflectionAnswers: reflectionAnswers ?? this.reflectionAnswers,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phase': phase.name,
        'title': title,
        'purpose': purpose,
        'shortExplanation': shortExplanation,
        'guidedInstructions': guidedInstructions,
        'reflectionQuestions': reflectionQuestions,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'personalNotes': personalNotes,
        'reflectionAnswers': reflectionAnswers,
      };

  factory JourneyActivity.fromJson(Map<String, dynamic> json) {
    return JourneyActivity(
      id: json['id'] as String? ?? '',
      phase: JourneyPhase.fromString(json['phase'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      purpose: json['purpose'] as String? ?? '',
      shortExplanation: json['shortExplanation'] as String? ?? '',
      guidedInstructions: (json['guidedInstructions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      reflectionQuestions: (json['reflectionQuestions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      personalNotes: json['personalNotes'] as String? ?? '',
      reflectionAnswers: (json['reflectionAnswers'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          const {},
    );
  }
}

