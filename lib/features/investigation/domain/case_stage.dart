/// The 6 investigative stages of a Mind Forensics case.
///
/// Section 3: "A case moves through stages:
/// 1. Incident -> 2. Evidence -> 3. Hypotheses ->
/// 4. Cross-examination -> 5. Findings -> 6. My conclusion"
enum CaseStage {
  incident(
    stepNumber: 1,
    title: 'Incident',
    subtitle: 'What happened, in your own words.',
  ),
  evidence(
    stepNumber: 2,
    title: 'Evidence',
    subtitle: 'Separating observable facts from interpretations.',
  ),
  hypotheses(
    stepNumber: 3,
    title: 'Hypotheses',
    subtitle: 'Exploring multiple possible explanations.',
  ),
  crossExamination(
    stepNumber: 4,
    title: 'Cross-Examination',
    subtitle: 'Testing assumptions and looking for exceptions.',
  ),
  findings(
    stepNumber: 5,
    title: 'Findings',
    subtitle: 'Structured summary of what is known, assumed, and uncertain.',
  ),
  conclusion(
    stepNumber: 6,
    title: 'My Conclusion',
    subtitle: 'Your personal takeaway. You have the final word.',
  );

  const CaseStage({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
  });

  final int stepNumber;
  final String title;
  final String subtitle;
}

