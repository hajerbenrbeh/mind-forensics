/// The five flexible phases of the personalized psychological journey.
enum JourneyPhase {
  phase1SelfDiscovery,
  phase2UnderstandingPatterns,
  phase3PsychologicalAwareness,
  phase4CopingAndDevelopment,
  phase5PersonalGrowthAndMaintenance;

  String get id => name;
  int get phaseNumber => index + 1;

  String defaultTitle() {
    switch (this) {
      case JourneyPhase.phase1SelfDiscovery:
        return 'Self-Discovery';
      case JourneyPhase.phase2UnderstandingPatterns:
        return 'Understanding Patterns';
      case JourneyPhase.phase3PsychologicalAwareness:
        return 'Psychological Awareness';
      case JourneyPhase.phase4CopingAndDevelopment:
        return 'Coping and Development';
      case JourneyPhase.phase5PersonalGrowthAndMaintenance:
        return 'Personal Growth and Maintenance';
    }
  }

  String defaultPurpose() {
    switch (this) {
      case JourneyPhase.phase1SelfDiscovery:
        return 'Understand your inner world, recurring thoughts, and the distinction between thoughts, emotions, and actions.';
      case JourneyPhase.phase2UnderstandingPatterns:
        return 'Recognize connections between triggers, automatic thought patterns, and behavioral responses.';
      case JourneyPhase.phase3PsychologicalAwareness:
        return 'Deepen understanding of specific experiences, emotional regulation, and cognitive distortions without self-judgment.';
      case JourneyPhase.phase4CopingAndDevelopment:
        return 'Integrate grounded psychological exercises, coping strategies, and gradual behavioral practices.';
      case JourneyPhase.phase5PersonalGrowthAndMaintenance:
        return 'Maintain what you have discovered, navigate setbacks compassionately, and establish sustainable habits.';
    }
  }

  static JourneyPhase fromString(String val) {
    return JourneyPhase.values.firstWhere(
      (e) => e.name == val,
      orElse: () => JourneyPhase.phase1SelfDiscovery,
    );
  }
}

