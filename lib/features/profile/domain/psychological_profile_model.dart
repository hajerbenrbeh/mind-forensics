import 'condition_type.dart';
import 'diagnostic_status.dart';

/// An entry representing a condition or experience and its evaluation status.
class UserConditionEntry {
  const UserConditionEntry({
    required this.condition,
    this.status = DiagnosticStatus.selfIdentifiedExploring,
    this.note = '',
  });

  final ConditionType condition;
  final DiagnosticStatus status;
  final String note;

  UserConditionEntry copyWith({
    ConditionType? condition,
    DiagnosticStatus? status,
    String? note,
  }) {
    return UserConditionEntry(
      condition: condition ?? this.condition,
      status: status ?? this.status,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'condition': condition.name,
        'status': status.name,
        'note': note,
      };

  factory UserConditionEntry.fromJson(Map<String, dynamic> json) {
    return UserConditionEntry(
      condition: ConditionType.fromString(json['condition'] as String? ?? ''),
      status: DiagnosticStatus.fromString(json['status'] as String? ?? ''),
      note: json['note'] as String? ?? '',
    );
  }
}

/// The user's personalized psychological profile.
///
/// Designed with privacy and autonomy: users control all disclosures,
/// and can update, clear, or modify entries at any time.
///
/// Fully encapsulates the 7 Core Sections from Session 03:
/// 1. About Me (preferred name, age range, preferred language, personal introduction)
/// 2. Psychological Experiences (7 categorized clusters + diagnostic status)
/// 3. Symptoms and Difficulties (emotional, thought, behavioral, other + free text)
/// 4. Personal Goals (multi-select goals + custom goals)
/// 5. Personal Context (rich unjudged personal history & triggers)
/// 6. Communication Preferences (tone, length, distress preference, disliked styles)
/// 7. Privacy and AI Personalization (explicit consent, local isolation, reset)
class PsychologicalProfileModel {
  const PsychologicalProfileModel({
    this.userId = 'local_user',

    // Section 1: About Me
    this.preferredName = '',
    this.ageRange = '',
    this.biologicalSex = '',
    this.preferredLanguage = '',
    this.personalIntroduction = '',
    this.additionalContext = '',

    // Starting Point & Background
    this.mentalHealthBackground = '',

    // Professional Care
    this.professionalSupport = '',

    // Onboarding Progress Tracking
    this.onboardingStep = 0,

    // Section 2: Psychological Experiences
    this.conditions = const [],

    // Section 3: Symptoms and Difficulties
    this.selectedSymptoms = const [],
    this.symptomNotes = '',
    this.symptomsAndExperiences = '',
    this.duration = '',
    this.currentDifficulties = '',
    this.personalTriggers = '',
    this.currentTreatment = '',

    // Section 4: Personal Goals
    this.selectedGoals = const [],
    this.customGoal = '',
    this.personalGoals = '',

    // Section 5: Personal Context
    this.personalContext = '',
    this.notesForAiCompanion = '',
    this.customAiDirectives = '',

    // Section 6: Communication Preferences
    this.communicationPreference = 'analytical_reflective',
    this.communicationTone = 'calm_analytical',
    this.responseLength = 'balanced',
    this.distressPreferences = const [],
    this.dislikedApproaches = const [],

    // Section 7: Privacy & AI Personalization
    this.allowAiPersonalization = true,
    this.shareWithAiCompanion = true,

    required this.updatedAt,
    this.createdAt,
  });

  final String userId;

  // Section 1: About Me
  final String preferredName;
  final String ageRange;
  final String biologicalSex;
  final String preferredLanguage;
  final String personalIntroduction;
  final String additionalContext;

  // Lived Background & Support
  final String mentalHealthBackground;
  final String professionalSupport;
  final int onboardingStep;

  bool get isMinor => ageRange == 'under_18' || ageRange == '<18';

  // Section 2: Psychological Experiences
  final List<UserConditionEntry> conditions;

  // Section 3: Symptoms and Difficulties
  final List<String> selectedSymptoms;
  final String symptomNotes;
  final String symptomsAndExperiences;
  final String duration;
  final String currentDifficulties;
  final String personalTriggers;
  final String currentTreatment;

  // Section 4: Personal Goals
  final List<String> selectedGoals;
  final String customGoal;
  final String personalGoals;

  // Section 5: Personal Context
  final String personalContext;
  final String notesForAiCompanion;
  final String customAiDirectives;

  // Section 6: Communication Preferences
  final String communicationPreference;
  final String communicationTone;
  final String responseLength;
  final List<String> distressPreferences;
  final List<String> dislikedApproaches;

  // Section 7: Privacy & AI Personalization
  final bool allowAiPersonalization;
  final bool shareWithAiCompanion;

  final DateTime updatedAt;
  final DateTime? createdAt;

  static PsychologicalProfileModel empty({String userId = 'local_user'}) =>
      PsychologicalProfileModel(
        userId: userId,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

  bool get isEmpty =>
      preferredName.trim().isEmpty &&
      ageRange.trim().isEmpty &&
      personalIntroduction.trim().isEmpty &&
      conditions.isEmpty &&
      selectedSymptoms.isEmpty &&
      symptomNotes.trim().isEmpty &&
      symptomsAndExperiences.trim().isEmpty &&
      duration.trim().isEmpty &&
      currentDifficulties.trim().isEmpty &&
      personalTriggers.trim().isEmpty &&
      currentTreatment.trim().isEmpty &&
      selectedGoals.isEmpty &&
      customGoal.trim().isEmpty &&
      personalGoals.trim().isEmpty &&
      personalContext.trim().isEmpty &&
      notesForAiCompanion.trim().isEmpty &&
      customAiDirectives.trim().isEmpty;

  bool hasCondition(ConditionType type) =>
      conditions.any((c) => c.condition == type);

  UserConditionEntry? getEntry(ConditionType type) {
    final idx = conditions.indexWhere((c) => c.condition == type);
    return idx != -1 ? conditions[idx] : null;
  }

  /// True if Section 1 (About Me) has any data
  bool get hasAboutMe =>
      preferredName.trim().isNotEmpty ||
      ageRange.trim().isNotEmpty ||
      preferredLanguage.trim().isNotEmpty ||
      personalIntroduction.trim().isNotEmpty;

  /// True if Section 2 (Experiences) has items
  bool get hasExperiences => conditions.isNotEmpty;

  /// True if Section 3 (Symptoms) has items
  bool get hasSymptoms =>
      selectedSymptoms.isNotEmpty ||
      symptomNotes.trim().isNotEmpty ||
      symptomsAndExperiences.trim().isNotEmpty ||
      currentDifficulties.trim().isNotEmpty;

  /// True if Section 4 (Goals) has items
  bool get hasGoals =>
      selectedGoals.isNotEmpty ||
      customGoal.trim().isNotEmpty ||
      personalGoals.trim().isNotEmpty;

  /// True if Section 5 (Context) has items
  bool get hasContext =>
      personalContext.trim().isNotEmpty ||
      notesForAiCompanion.trim().isNotEmpty ||
      personalTriggers.trim().isNotEmpty ||
      currentTreatment.trim().isNotEmpty;

  /// True if Section 6 (Communication) is non-default
  bool get hasCommunicationPrefs =>
      communicationTone.isNotEmpty ||
      distressPreferences.isNotEmpty ||
      dislikedApproaches.isNotEmpty;

  PsychologicalProfileModel copyWith({
    String? userId,
    String? preferredName,
    String? ageRange,
    String? biologicalSex,
    String? preferredLanguage,
    String? personalIntroduction,
    String? additionalContext,
    String? mentalHealthBackground,
    String? professionalSupport,
    int? onboardingStep,
    List<UserConditionEntry>? conditions,
    List<String>? selectedSymptoms,
    String? symptomNotes,
    String? symptomsAndExperiences,
    String? duration,
    String? currentDifficulties,
    String? personalTriggers,
    String? currentTreatment,
    List<String>? selectedGoals,
    String? customGoal,
    String? personalGoals,
    String? personalContext,
    String? notesForAiCompanion,
    String? customAiDirectives,
    String? communicationPreference,
    String? communicationTone,
    String? responseLength,
    List<String>? distressPreferences,
    List<String>? dislikedApproaches,
    bool? allowAiPersonalization,
    bool? shareWithAiCompanion,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    final aiConsent = allowAiPersonalization ??
        shareWithAiCompanion ??
        this.allowAiPersonalization;

    return PsychologicalProfileModel(
      userId: userId ?? this.userId,
      preferredName: preferredName ?? this.preferredName,
      ageRange: ageRange ?? this.ageRange,
      biologicalSex: biologicalSex ?? this.biologicalSex,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      personalIntroduction:
          personalIntroduction ?? this.personalIntroduction,
      additionalContext: additionalContext ?? this.additionalContext,
      mentalHealthBackground: mentalHealthBackground ?? this.mentalHealthBackground,
      professionalSupport: professionalSupport ?? this.professionalSupport,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      conditions: conditions ?? this.conditions,
      selectedSymptoms: selectedSymptoms ?? this.selectedSymptoms,
      symptomNotes: symptomNotes ?? this.symptomNotes,
      symptomsAndExperiences:
          symptomsAndExperiences ?? this.symptomsAndExperiences,
      duration: duration ?? this.duration,
      currentDifficulties: currentDifficulties ?? this.currentDifficulties,
      personalTriggers: personalTriggers ?? this.personalTriggers,
      currentTreatment: currentTreatment ?? this.currentTreatment,
      selectedGoals: selectedGoals ?? this.selectedGoals,
      customGoal: customGoal ?? this.customGoal,
      personalGoals: personalGoals ?? this.personalGoals,
      personalContext: personalContext ?? this.personalContext,
      notesForAiCompanion: notesForAiCompanion ?? this.notesForAiCompanion,
      customAiDirectives: customAiDirectives ?? this.customAiDirectives,
      communicationPreference:
          communicationPreference ?? this.communicationPreference,
      communicationTone: communicationTone ?? this.communicationTone,
      responseLength: responseLength ?? this.responseLength,
      distressPreferences: distressPreferences ?? this.distressPreferences,
      dislikedApproaches: dislikedApproaches ?? this.dislikedApproaches,
      allowAiPersonalization: aiConsent,
      shareWithAiCompanion: aiConsent,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'preferredName': preferredName,
        'ageRange': ageRange,
        'biologicalSex': biologicalSex,
        'preferredLanguage': preferredLanguage,
        'personalIntroduction': personalIntroduction,
        'additionalContext': additionalContext,
        'mentalHealthBackground': mentalHealthBackground,
        'professionalSupport': professionalSupport,
        'onboardingStep': onboardingStep,
        'conditions': conditions.map((c) => c.toJson()).toList(),
        'selectedSymptoms': selectedSymptoms,
        'symptomNotes': symptomNotes,
        'symptomsAndExperiences': symptomsAndExperiences,
        'duration': duration,
        'currentDifficulties': currentDifficulties,
        'personalTriggers': personalTriggers,
        'currentTreatment': currentTreatment,
        'selectedGoals': selectedGoals,
        'customGoal': customGoal,
        'personalGoals': personalGoals,
        'personalContext': personalContext,
        'notesForAiCompanion': notesForAiCompanion,
        'customAiDirectives': customAiDirectives,
        'communicationPreference': communicationPreference,
        'communicationTone': communicationTone,
        'responseLength': responseLength,
        'distressPreferences': distressPreferences,
        'dislikedApproaches': dislikedApproaches,
        'allowAiPersonalization': allowAiPersonalization,
        'shareWithAiCompanion': shareWithAiCompanion,
        'updatedAt': updatedAt.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };

  factory PsychologicalProfileModel.fromJson(Map<String, dynamic> json) {
    final aiConsent = json['allowAiPersonalization'] as bool? ??
        json['shareWithAiCompanion'] as bool? ??
        true;

    // Handle backward compatibility for personalGoals
    final rawGoals = json['personalGoals'] as String? ?? '';
    final listGoals = (json['selectedGoals'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (rawGoals.isNotEmpty
            ? rawGoals.split(', ').where((s) => s.trim().isNotEmpty).toList()
            : const []);

    return PsychologicalProfileModel(
      userId: json['userId'] as String? ?? 'local_user',
      preferredName: json['preferredName'] as String? ?? '',
      ageRange: json['ageRange'] as String? ?? '',
      biologicalSex: json['biologicalSex'] as String? ?? '',
      preferredLanguage: json['preferredLanguage'] as String? ?? '',
      personalIntroduction: json['personalIntroduction'] as String? ?? '',
      additionalContext: json['additionalContext'] as String? ?? '',
      mentalHealthBackground: json['mentalHealthBackground'] as String? ?? '',
      professionalSupport: json['professionalSupport'] as String? ?? '',
      onboardingStep: (json['onboardingStep'] as num?)?.toInt() ?? 0,
      conditions: (json['conditions'] as List<dynamic>?)
              ?.map((e) => UserConditionEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      selectedSymptoms: (json['selectedSymptoms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      symptomNotes: json['symptomNotes'] as String? ?? '',
      symptomsAndExperiences:
          json['symptomsAndExperiences'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      currentDifficulties: json['currentDifficulties'] as String? ?? '',
      personalTriggers: json['personalTriggers'] as String? ?? '',
      currentTreatment: json['currentTreatment'] as String? ?? '',
      selectedGoals: listGoals,
      customGoal: json['customGoal'] as String? ?? '',
      personalGoals: rawGoals,
      personalContext: json['personalContext'] as String? ?? '',
      notesForAiCompanion: json['notesForAiCompanion'] as String? ?? '',
      customAiDirectives: json['customAiDirectives'] as String? ?? '',
      communicationPreference:
          json['communicationPreference'] as String? ?? 'analytical_reflective',
      communicationTone: json['communicationTone'] as String? ??
          json['communicationPreference'] as String? ??
          'calm_analytical',
      responseLength: json['responseLength'] as String? ?? 'balanced',
      distressPreferences: (json['distressPreferences'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      dislikedApproaches: (json['dislikedApproaches'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      allowAiPersonalization: aiConsent,
      shareWithAiCompanion: aiConsent,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}
