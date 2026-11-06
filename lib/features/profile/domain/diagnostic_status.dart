/// Clinical or self-exploration status of a selected condition.
enum DiagnosticStatus {
  professionallyDiagnosed,
  currentlyBeingEvaluated,
  selfIdentifiedExploring,
  preferNotToSay;

  String get displayName => defaultDisplayName();

  String defaultDisplayName() {
    switch (this) {
      case DiagnosticStatus.professionallyDiagnosed:
        return 'Professionally Diagnosed';
      case DiagnosticStatus.currentlyBeingEvaluated:
        return 'Currently Being Evaluated';
      case DiagnosticStatus.selfIdentifiedExploring:
        return 'Self-Identified / Exploring';
      case DiagnosticStatus.preferNotToSay:
        return 'Prefer Not to Say';
    }
  }

  static DiagnosticStatus fromString(String val) {
    return DiagnosticStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => DiagnosticStatus.selfIdentifiedExploring,
    );
  }
}

