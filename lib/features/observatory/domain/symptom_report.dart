import 'package:flutter/foundation.dart';

/// Represents a multiple-symptom self-report logged by the user.
///
/// Follows Directive 11 (options-first, non-pathologizing):
/// - Multiple symptoms reported in a single entry
/// - Low cognitive load options for somatic impact & triggers
/// - Non-compulsory optional follow-up answers
/// - Stores immediate AI reflection and stabilizing strategy
@immutable
class SymptomReport {
  final String id;
  final List<String> symptomIds;
  final int intensity; // 1-10
  final String? onset; // 'few_hours', 'today', 'few_days', 'chronic'
  final String? somaticLocation; // 'chest', 'jaw_neck', 'stomach', 'general_fatigue', 'none'
  final String? contextTrigger; // 'work_academic', 'social_interaction', 'sleep_deprivation', 'solitude', 'unclear'
  final List<String> copingStrategiesTried;
  final String? adaptiveAiQuestion;
  final String? userAdaptiveAnswer;
  final String? aiAnalysis;
  final String? stabilizingStrategy;
  final DateTime createdAt;

  const SymptomReport({
    required this.id,
    required this.symptomIds,
    required this.intensity,
    this.onset,
    this.somaticLocation,
    this.contextTrigger,
    this.copingStrategiesTried = const [],
    this.adaptiveAiQuestion,
    this.userAdaptiveAnswer,
    this.aiAnalysis,
    this.stabilizingStrategy,
    required this.createdAt,
  });

  String get dateKey =>
      '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'symptomIds': symptomIds,
        'intensity': intensity,
        'onset': onset,
        'somaticLocation': somaticLocation,
        'contextTrigger': contextTrigger,
        'copingStrategiesTried': copingStrategiesTried,
        'adaptiveAiQuestion': adaptiveAiQuestion,
        'userAdaptiveAnswer': userAdaptiveAnswer,
        'aiAnalysis': aiAnalysis,
        'stabilizingStrategy': stabilizingStrategy,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SymptomReport.fromJson(Map<String, dynamic> json) {
    return SymptomReport(
      id: json['id'] as String,
      symptomIds: (json['symptomIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      intensity: (json['intensity'] as num?)?.toInt() ?? 5,
      onset: json['onset'] as String?,
      somaticLocation: json['somaticLocation'] as String?,
      contextTrigger: json['contextTrigger'] as String?,
      copingStrategiesTried: (json['copingStrategiesTried'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      adaptiveAiQuestion: json['adaptiveAiQuestion'] as String?,
      userAdaptiveAnswer: json['userAdaptiveAnswer'] as String?,
      aiAnalysis: json['aiAnalysis'] as String?,
      stabilizingStrategy: json['stabilizingStrategy'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  SymptomReport copyWith({
    String? id,
    List<String>? symptomIds,
    int? intensity,
    String? onset,
    String? somaticLocation,
    String? contextTrigger,
    List<String>? copingStrategiesTried,
    String? adaptiveAiQuestion,
    String? userAdaptiveAnswer,
    String? aiAnalysis,
    String? stabilizingStrategy,
    DateTime? createdAt,
  }) {
    return SymptomReport(
      id: id ?? this.id,
      symptomIds: symptomIds ?? this.symptomIds,
      intensity: intensity ?? this.intensity,
      onset: onset ?? this.onset,
      somaticLocation: somaticLocation ?? this.somaticLocation,
      contextTrigger: contextTrigger ?? this.contextTrigger,
      copingStrategiesTried: copingStrategiesTried ?? this.copingStrategiesTried,
      adaptiveAiQuestion: adaptiveAiQuestion ?? this.adaptiveAiQuestion,
      userAdaptiveAnswer: userAdaptiveAnswer ?? this.userAdaptiveAnswer,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      stabilizingStrategy: stabilizingStrategy ?? this.stabilizingStrategy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

