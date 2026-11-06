/// Mental health conditions and lived experiences supported in Mind Forensics.
///
/// Strictly non-pathologizing: selection does not assume a clinical diagnosis.
enum ConditionType {
  // Mood-related experiences
  depression,
  bipolarI,
  bipolarII,
  moodInstability,
  otherMood,

  // Anxiety-related experiences
  generalizedAnxiety,
  socialAnxiety,
  panicAttacks,
  specificPhobias,
  otherAnxiety,

  // Thought-related experiences
  ocd,
  intrusiveThoughts,
  repetitiveThoughts,
  compulsiveBehaviors,

  // Trauma-related experiences
  ptsd,
  complexPtsd,
  traumaDifficulties,

  // Attention and neurodevelopmental experiences
  adhd,
  autism,
  attentionDifficulties,
  sensoryDifficulties,

  // Psychosis-related experiences
  psychosisSpectrum,
  schizophrenia,
  hallucinations,
  delusions,
  otherPerceptual,

  // Other experiences
  dissociativeDisorders,
  dissociativeExperiences,
  eatingDisorders,
  eatingDifficulties,
  personalityDisorders,
  personalityDifficulties,
  sleepDisorders,
  sleepDifficulties,
  other,
  stillExploring,
  preferNotToSpecify;

  String get id => name;
  String get displayName => defaultDisplayName();

  String defaultDisplayName() {
    switch (this) {
      case ConditionType.depression:
        return 'Depression';
      case ConditionType.bipolarI:
        return 'Bipolar I';
      case ConditionType.bipolarII:
        return 'Bipolar II';
      case ConditionType.moodInstability:
        return 'Mood Instability';
      case ConditionType.otherMood:
        return 'Other Mood-Related Experiences';
      case ConditionType.generalizedAnxiety:
        return 'Generalized Anxiety Disorder (GAD)';
      case ConditionType.socialAnxiety:
        return 'Social Anxiety Disorder';
      case ConditionType.panicAttacks:
        return 'Panic Attacks';
      case ConditionType.specificPhobias:
        return 'Specific Phobias';
      case ConditionType.otherAnxiety:
        return 'Other Anxiety-Related Experiences';
      case ConditionType.ocd:
        return 'OCD (Obsessive-Compulsive Disorder)';
      case ConditionType.intrusiveThoughts:
        return 'Intrusive Thoughts';
      case ConditionType.repetitiveThoughts:
        return 'Repetitive Thoughts';
      case ConditionType.compulsiveBehaviors:
        return 'Compulsive Behaviors';
      case ConditionType.ptsd:
        return 'PTSD';
      case ConditionType.complexPtsd:
        return 'Complex PTSD';
      case ConditionType.traumaDifficulties:
        return 'Trauma-Related Difficulties';
      case ConditionType.adhd:
        return 'ADHD';
      case ConditionType.autism:
        return 'Autism';
      case ConditionType.attentionDifficulties:
        return 'Attention Difficulties';
      case ConditionType.sensoryDifficulties:
        return 'Sensory Difficulties';
      case ConditionType.psychosisSpectrum:
        return 'Psychosis-Spectrum Experiences';
      case ConditionType.schizophrenia:
        return 'Schizophrenia';
      case ConditionType.hallucinations:
        return 'Hallucination-Related Experiences';
      case ConditionType.delusions:
        return 'Delusion-Related Experiences';
      case ConditionType.otherPerceptual:
        return 'Other Unusual Perceptual Experiences';
      case ConditionType.dissociativeDisorders:
        return 'Dissociative Disorders';
      case ConditionType.dissociativeExperiences:
        return 'Dissociative Experiences';
      case ConditionType.eatingDisorders:
        return 'Eating Disorders';
      case ConditionType.eatingDifficulties:
        return 'Eating-Related Difficulties';
      case ConditionType.personalityDisorders:
        return 'Personality Disorders';
      case ConditionType.personalityDifficulties:
        return 'Personality-Related Difficulties';
      case ConditionType.sleepDisorders:
        return 'Sleep Disorders';
      case ConditionType.sleepDifficulties:
        return 'Sleep-Related Difficulties';
      case ConditionType.other:
        return 'Other';
      case ConditionType.stillExploring:
        return 'Still Exploring My Mental Health';
      case ConditionType.preferNotToSpecify:
        return 'Prefer Not to Specify';
    }
  }

  static ConditionType fromString(String val) {
    return ConditionType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => ConditionType.stillExploring,
    );
  }
}

/// The 7 distinct psychological experience categories specified in Session 03.
enum ExperienceCategory {
  mood,
  anxiety,
  thought,
  trauma,
  neurodevelopmental,
  psychosis,
  other;

  String get englishTitle {
    switch (this) {
      case ExperienceCategory.mood:
        return 'Mood-related experiences';
      case ExperienceCategory.anxiety:
        return 'Anxiety-related experiences';
      case ExperienceCategory.thought:
        return 'Thought-related experiences';
      case ExperienceCategory.trauma:
        return 'Trauma-related experiences';
      case ExperienceCategory.neurodevelopmental:
        return 'Attention and neurodevelopmental experiences';
      case ExperienceCategory.psychosis:
        return 'Psychosis-related experiences';
      case ExperienceCategory.other:
        return 'Other experiences';
    }
  }

  String get arabicTitle {
    switch (this) {
      case ExperienceCategory.mood:
        return 'تجارب متعلقة بالمزاج';
      case ExperienceCategory.anxiety:
        return 'تجارب متعلقة بالقلق والهلع';
      case ExperienceCategory.thought:
        return 'تجارب متعلقة بالأفكار والوساوس';
      case ExperienceCategory.trauma:
        return 'تجارب متعلقة بالصدمات';
      case ExperienceCategory.neurodevelopmental:
        return 'الانتباه والنمو العصبي';
      case ExperienceCategory.psychosis:
        return 'تجارب متعلقة بالإدراك وطيف الذهان';
      case ExperienceCategory.other:
        return 'تجارب وحالات أخرى';
    }
  }

  List<ConditionType> get conditions {
    switch (this) {
      case ExperienceCategory.mood:
        return [
          ConditionType.depression,
          ConditionType.bipolarI,
          ConditionType.bipolarII,
          ConditionType.moodInstability,
          ConditionType.otherMood,
        ];
      case ExperienceCategory.anxiety:
        return [
          ConditionType.generalizedAnxiety,
          ConditionType.socialAnxiety,
          ConditionType.panicAttacks,
          ConditionType.specificPhobias,
          ConditionType.otherAnxiety,
        ];
      case ExperienceCategory.thought:
        return [
          ConditionType.ocd,
          ConditionType.intrusiveThoughts,
          ConditionType.repetitiveThoughts,
          ConditionType.compulsiveBehaviors,
        ];
      case ExperienceCategory.trauma:
        return [
          ConditionType.ptsd,
          ConditionType.complexPtsd,
          ConditionType.traumaDifficulties,
        ];
      case ExperienceCategory.neurodevelopmental:
        return [
          ConditionType.adhd,
          ConditionType.autism,
          ConditionType.attentionDifficulties,
          ConditionType.sensoryDifficulties,
        ];
      case ExperienceCategory.psychosis:
        return [
          ConditionType.psychosisSpectrum,
          ConditionType.schizophrenia,
          ConditionType.hallucinations,
          ConditionType.delusions,
          ConditionType.otherPerceptual,
        ];
      case ExperienceCategory.other:
        return [
          ConditionType.dissociativeDisorders,
          ConditionType.dissociativeExperiences,
          ConditionType.eatingDisorders,
          ConditionType.eatingDifficulties,
          ConditionType.personalityDisorders,
          ConditionType.personalityDifficulties,
          ConditionType.sleepDisorders,
          ConditionType.sleepDifficulties,
          ConditionType.other,
          ConditionType.stillExploring,
          ConditionType.preferNotToSpecify,
        ];
    }
  }
}
