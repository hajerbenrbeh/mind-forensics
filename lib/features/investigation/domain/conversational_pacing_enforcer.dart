import '../../../core/safety/crisis_keywords.dart';
import 'conversation_mode.dart';

/// Multilingual conversational pacing validator and safe response guardrail.
///
/// Enforces concise, clinically paced responses per [ConversationMode]
/// across English, French, and authentic Tunisian Arabic.
///
/// Strictly non-destructive:
/// - Evaluates sentence bounds using robust punctuation and decimal/abbreviation protection.
/// - Grants 100% immunity to safety, crisis guidance, hotlines, and grounding instructions.
/// - Never chops or mutilates text mid-sentence.
class ConversationalPacingEnforcer {
  /// Standard Tunisian and international crisis hotline numbers.
  static const List<String> kCrisisHotlines = [
    '80 10 50 50',
    '80105050',
    '190',
    '198',
  ];

  /// Keywords indicating grounding or somatic regulation instructions.
  static const List<String> kGroundingMarkers = [
    '5-4-3-2-1',
    'vagal',
    'breathing',
    'respiration',
    'تنفس',
    'شهيق',
    'زفير',
    'somatic',
    'ancrage',
  ];

  /// Target maximum sentence count per conversational mode.
  static int targetMaxSentences(ConversationMode mode) {
    switch (mode) {
      case ConversationMode.exploreThought:
        return 3;
      case ConversationMode.understandEmotion:
        return 4;
      case ConversationMode.psychologicalAnalysis:
        return 4;
      case ConversationMode.guidedReflection:
        return 3;
      case ConversationMode.justTalk:
        return 5;
      case ConversationMode.grounding:
        return 2;
    }
  }

  /// Checks if [text] contains safety guidance, crisis resources, or somatic grounding.
  ///
  /// Safety-related text receives 100% immunity from pacing enforcement.
  static bool hasSafetyExemption(String text) {
    final lower = text.toLowerCase();

    // 1. Check verified emergency hotlines
    for (final hotline in kCrisisHotlines) {
      if (text.contains(hotline)) return true;
    }

    // 2. Check offline crisis/distress phrases
    if (CrisisKeywords.evaluateText(text) > 0) return true;

    // 3. Check somatic grounding markers
    for (final marker in kGroundingMarkers) {
      if (lower.contains(marker)) return true;
    }

    return false;
  }

  /// Robust multilingual sentence segmentation.
  ///
  /// Protects:
  /// - Ellipses (`...`, `…`) followed by whitespace are split as complete thoughts
  /// - Decimals (`5.4`, `7.5/10`, `3.1-flash`)
  /// - Common abbreviations (`Dr.`, `Mr.`, `Ms.`, `e.g.`, `i.e.`, `approx.`, `M.`, `Mme.`)
  /// - Splits cleanly on terminal punctuation (`.`, `!`, `?`, `؟`) and double newlines.
  /// - Avoids treating Arabic interrogatives (`شنوة`, `علاش`) as split points when mid-sentence.
  static List<String> tokenizeSentences(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return const [];

    // Step 1: Shield decimals (digits separated by period)
    String masked = clean.replaceAllMapped(
      RegExp(r'(\d+)\.(\d+)'),
      (match) => '${match.group(1)}__MF_DOT__${match.group(2)}',
    );

    // Step 2: Shield common abbreviations
    final abbreviations = [
      'Dr.',
      'dr.',
      'Mr.',
      'mr.',
      'Ms.',
      'ms.',
      'e.g.',
      'i.e.',
      'approx.',
      'M.',
      'Mme.',
      'vs.',
    ];
    for (final abbr in abbreviations) {
      masked = masked.replaceAll(abbr, abbr.replaceAll('.', '__MF_DOT__'));
    }

    // Step 3: Handle terminal ellipses followed by whitespace
    masked = masked.replaceAllMapped(
      RegExp(r'(\.{3}|…)(\s+)'),
      (match) => '...__MF_SPLIT__',
    );

    // Step 4: Tokenize on terminal punctuation (. ! ? ؟) followed by whitespace, newline, or end-of-string
    masked = masked.replaceAllMapped(
      RegExp(r'(?<=[.!?؟])(\s+|\n+|$)|\n{2,}'),
      (match) => '__MF_SPLIT__',
    );

    final rawTokens = masked.split('__MF_SPLIT__');

    final results = <String>[];
    for (final token in rawTokens) {
      final unmasked = token
          .replaceAll('__MF_DOT__', '.')
          .trim();
      if (unmasked.isNotEmpty) {
        results.add(unmasked);
      }
    }

    return results;
  }

  /// Validates a response against mode pacing bounds.
  ///
  /// Returns a record:
  /// - [isValid]: Whether the response meets the pacing target (including +1 tolerance margin).
  /// - [sentenceCount]: Number of detected sentences.
  /// - [isExempt]: Whether safety/grounding immunity was applied.
  static ({bool isValid, int sentenceCount, bool isExempt}) validateResponse(
    String text,
    ConversationMode mode,
  ) {
    if (hasSafetyExemption(text)) {
      return (
        isValid: true,
        sentenceCount: tokenizeSentences(text).length,
        isExempt: true,
      );
    }

    final sentences = tokenizeSentences(text);
    final count = sentences.length;
    final maxTarget = targetMaxSentences(mode);

    // Margin of tolerance: up to +1 sentence above target is valid to preserve natural phrasing
    final withinMargin = count <= (maxTarget + 1);

    return (
      isValid: withinMargin,
      sentenceCount: count,
      isExempt: false,
    );
  }
}
