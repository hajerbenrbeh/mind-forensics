/// The three core forensic labels used across Mind Forensics.
///
/// Section 2: "Every statement in a case carries one of three labels.
/// Each label has a fixed color, an icon, and a letter, so it never depends
/// on color alone (accessibility)."
enum LabelType {
  /// Observable, verifiable evidence (e.g., "She did not reply for 3 hours.")
  fact(
    letter: 'F',
    displayName: 'Fact',
    definition: 'Observable, verifiable fact.',
    example: 'She did not reply for 3 hours.',
  ),

  /// Taken as true but unverified (e.g., "She is ignoring me.")
  assumption(
    letter: 'A',
    displayName: 'Assumption',
    definition: 'Taken as true, but not yet verified.',
    example: 'She is ignoring me.',
  ),

  /// The meaning or weight given to it (e.g., "I am not important to her.")
  interpretation(
    letter: 'I',
    displayName: 'Interpretation',
    definition: 'The personal meaning given to what happened.',
    example: 'I am not important to her.',
  );

  const LabelType({
    required this.letter,
    required this.displayName,
    required this.definition,
    required this.example,
  });

  final String letter;
  final String displayName;
  final String definition;
  final String example;
}

