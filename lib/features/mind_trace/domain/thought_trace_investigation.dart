/// Domain definition for The Thought Trace Socratic Investigation.
///
/// Provides the 6 core reflective inquiries that allow users to deconstruct
/// a saved thought trace without psychological pressure or forced completion.
class ThoughtTraceInvestigationQuestion {
  const ThoughtTraceInvestigationQuestion({
    required this.id,
    required this.question,
    required this.category,
    required this.hint,
  });

  final String id;
  final String question;
  final String category;
  final String hint;
}

class ThoughtTraceInvestigation {
  ThoughtTraceInvestigation._();

  static const List<ThoughtTraceInvestigationQuestion> questions = [
    ThoughtTraceInvestigationQuestion(
      id: 'trigger',
      question: 'What happened before this thought appeared?',
      category: 'Situation / Context',
      hint: 'A conversation, a quiet moment, a sudden physical sensation, or a specific event...',
    ),
    ThoughtTraceInvestigationQuestion(
      id: 'feeling',
      question: 'What was I feeling?',
      category: 'Affect & Somatic',
      hint: 'Emotional waves, muscular tension, tightness in chest, lightness, or numbness...',
    ),
    ThoughtTraceInvestigationQuestion(
      id: 'belief',
      question: 'What did I believe was happening?',
      category: 'Interpretation',
      hint: 'The assumption, narrative, or mental rule that formed in that instant...',
    ),
    ThoughtTraceInvestigationQuestion(
      id: 'response',
      question: 'What did I do in response?',
      category: 'Action & Coping',
      hint: 'Withdrawing, reaching out, seeking distraction, breathing, or confronting...',
    ),
    ThoughtTraceInvestigationQuestion(
      id: 'pattern',
      question: 'Is this something I have noticed before?',
      category: 'Pattern Recognition',
      hint: 'Has this familiar narrative or reaction appeared in similar circumstances in the past?',
    ),
    ThoughtTraceInvestigationQuestion(
      id: 'inquiry',
      question: 'What would I like to understand about this experience?',
      category: 'Reflective Inquiry',
      hint: 'What insight, gentleness, or question would help make peace with this trace?',
    ),
  ];
}

