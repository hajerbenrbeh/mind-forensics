/// A comprehensive daily emotional and psychological check-in record.
///
/// Satisfies the Daily Mind Trace architecture:
/// - Basic metadata (id, date, timestamp, isCompleted)
/// - Core somatic & affective indicators (mood, emotions, intensity, energy, anxiety)
/// - Cognitive clarity (racing thoughts, concentration, intrusive thoughts, mental clarity, emotional disconnection)
/// - Somatic clarity (sleep hours, sleep quality, physical tension)
/// - Subjective explorations (dynamic questions, journal entry, voice note reference)
/// - AI reflection & suggested Journey activity integration
class MindTraceModel {
  const MindTraceModel({
    required this.id,
    this.userId = 'local_user',
    required this.date,
    this.overallMood = 'calm',
    this.selectedEmotions = const [],
    this.moodIntensity = 5,
    this.energyLevel = 5,
    this.anxietyLevel,
    this.sleepHours,
    this.sleepQuality,
    this.concentrationLevel,
    this.mentalClarity,
    this.physicalTension,
    this.racingThoughts,
    this.intrusiveThoughts,
    this.emotionalDisconnection,
    this.symptomsAndExperiences,
    this.situation,
    this.behavioralResponse,
    this.journalText,
    this.voiceNotePath,
    this.dynamicAnswers = const {},
    this.investigationAnswers = const {},
    this.aiReflection,
    this.suggestedJourneyActivityId,
    this.isCompleted = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final DateTime date;
  final String overallMood;
  final List<String> selectedEmotions;
  final int moodIntensity; // 1 - 10
  final int energyLevel; // 1 - 10
  final int? anxietyLevel; // 0 - 10
  final double? sleepHours;
  final int? sleepQuality; // 1 - 5
  final int? concentrationLevel; // 1 - 10
  final int? mentalClarity; // 1 - 10
  final int? physicalTension; // 1 - 10
  final int? racingThoughts; // 1 - 10
  final int? intrusiveThoughts; // 1 - 10
  final int? emotionalDisconnection; // 1 - 10
  final String? symptomsAndExperiences;
  final String? situation;
  final String? behavioralResponse;
  final String? journalText;
  final String? voiceNotePath;
  final Map<String, String> dynamicAnswers;
  final Map<String, String> investigationAnswers;
  final String? aiReflection;
  final String? suggestedJourneyActivityId;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isInvestigated =>
      investigationAnswers.values.any((v) => v.trim().isNotEmpty);

  String get thoughtPreview {
    if (journalText != null && journalText!.trim().isNotEmpty) {
      return journalText!.trim();
    }
    if (situation != null && situation!.trim().isNotEmpty) {
      return situation!.trim();
    }
    return overallMood;
  }

  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  MindTraceModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? overallMood,
    List<String>? selectedEmotions,
    int? moodIntensity,
    int? energyLevel,
    int? anxietyLevel,
    double? sleepHours,
    int? sleepQuality,
    int? concentrationLevel,
    int? mentalClarity,
    int? physicalTension,
    int? racingThoughts,
    int? intrusiveThoughts,
    int? emotionalDisconnection,
    String? symptomsAndExperiences,
    String? situation,
    String? behavioralResponse,
    String? journalText,
    String? voiceNotePath,
    Map<String, String>? dynamicAnswers,
    Map<String, String>? investigationAnswers,
    String? aiReflection,
    String? suggestedJourneyActivityId,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MindTraceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      overallMood: overallMood ?? this.overallMood,
      selectedEmotions: selectedEmotions ?? this.selectedEmotions,
      moodIntensity: moodIntensity ?? this.moodIntensity,
      energyLevel: energyLevel ?? this.energyLevel,
      anxietyLevel: anxietyLevel ?? this.anxietyLevel,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      concentrationLevel: concentrationLevel ?? this.concentrationLevel,
      mentalClarity: mentalClarity ?? this.mentalClarity,
      physicalTension: physicalTension ?? this.physicalTension,
      racingThoughts: racingThoughts ?? this.racingThoughts,
      intrusiveThoughts: intrusiveThoughts ?? this.intrusiveThoughts,
      emotionalDisconnection:
          emotionalDisconnection ?? this.emotionalDisconnection,
      symptomsAndExperiences:
          symptomsAndExperiences ?? this.symptomsAndExperiences,
      situation: situation ?? this.situation,
      behavioralResponse: behavioralResponse ?? this.behavioralResponse,
      journalText: journalText ?? this.journalText,
      voiceNotePath: voiceNotePath ?? this.voiceNotePath,
      dynamicAnswers: dynamicAnswers ?? this.dynamicAnswers,
      investigationAnswers: investigationAnswers ?? this.investigationAnswers,
      aiReflection: aiReflection ?? this.aiReflection,
      suggestedJourneyActivityId:
          suggestedJourneyActivityId ?? this.suggestedJourneyActivityId,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'date': date.toIso8601String(),
        'overallMood': overallMood,
        'selectedEmotions': selectedEmotions,
        'moodIntensity': moodIntensity,
        'energyLevel': energyLevel,
        'anxietyLevel': anxietyLevel,
        'sleepHours': sleepHours,
        'sleepQuality': sleepQuality,
        'concentrationLevel': concentrationLevel,
        'mentalClarity': mentalClarity,
        'physicalTension': physicalTension,
        'racingThoughts': racingThoughts,
        'intrusiveThoughts': intrusiveThoughts,
        'emotionalDisconnection': emotionalDisconnection,
        'symptomsAndExperiences': symptomsAndExperiences,
        'situation': situation,
        'behavioralResponse': behavioralResponse,
        'journalText': journalText,
        'voiceNotePath': voiceNotePath,
        'dynamicAnswers': dynamicAnswers,
        'investigationAnswers': investigationAnswers,
        'aiReflection': aiReflection,
        'suggestedJourneyActivityId': suggestedJourneyActivityId,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MindTraceModel.fromJson(Map<String, dynamic> json) {
    return MindTraceModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? 'local_user',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      overallMood: json['overallMood'] as String? ?? 'calm',
      selectedEmotions: (json['selectedEmotions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      moodIntensity: (json['moodIntensity'] as num?)?.toInt() ?? 5,
      energyLevel: (json['energyLevel'] as num?)?.toInt() ?? 5,
      anxietyLevel: (json['anxietyLevel'] as num?)?.toInt(),
      sleepHours: (json['sleepHours'] as num?)?.toDouble(),
      sleepQuality: (json['sleepQuality'] as num?)?.toInt(),
      concentrationLevel: (json['concentrationLevel'] as num?)?.toInt(),
      mentalClarity: (json['mentalClarity'] as num?)?.toInt(),
      physicalTension: (json['physicalTension'] as num?)?.toInt(),
      racingThoughts: (json['racingThoughts'] as num?)?.toInt(),
      intrusiveThoughts: (json['intrusiveThoughts'] as num?)?.toInt(),
      emotionalDisconnection: (json['emotionalDisconnection'] as num?)?.toInt(),
      symptomsAndExperiences: json['symptomsAndExperiences'] as String?,
      situation: json['situation'] as String?,
      behavioralResponse: json['behavioralResponse'] as String?,
      journalText: json['journalText'] as String?,
      voiceNotePath: json['voiceNotePath'] as String?,
      dynamicAnswers: (json['dynamicAnswers'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          const {},
      investigationAnswers:
          (json['investigationAnswers'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k, v.toString())) ??
              const {},
      aiReflection: json['aiReflection'] as String?,
      suggestedJourneyActivityId:
          json['suggestedJourneyActivityId'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static MindTraceModel createFresh({
    required String id,
    DateTime? date,
    String overallMood = 'calm',
  }) {
    final now = DateTime.now();
    return MindTraceModel(
      id: id,
      date: date ?? now,
      overallMood: overallMood,
      createdAt: now,
      updatedAt: now,
    );
  }
}
