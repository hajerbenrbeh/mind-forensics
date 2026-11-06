/// Offline crisis and elevated distress keyword lists for Layer 1 Safety.
///
/// Section 6 & Step 8.6:
/// A simple, fast offline function that scans user input before any AI call.
///
/// Includes English, French, Standard Arabic, and authentic Tunisian dialect / Arabizi.
class CrisisKeywords {
  /// Level 2 Crisis Keywords: Immediate gentle pause, stop analysis, show support hotlines.
  static const List<String> level2CrisisPhrases = [
    // English
    'kill myself',
    'suicide',
    'end my life',
    'want to die',
    'better off dead',
    'self harm',
    'cutting myself',
    'overdose',
    'no reason to live',
    'can’t go on anymore',
    'cant go on anymore',

    // French
    'me suicider',
    'envie de mourir',
    'mettre fin à mes jours',
    'me faire du mal',
    'plus envie de vivre',
    'en finir avec la vie',
    'automutilation',

    // Arabic / Tunisian Dialect & Arabizi
    'انتحار',
    'نموت',
    'نقتل روحي',
    'نحب نموت',
    'فديت من حياتي',
    'حياتي وفات',
    'نحب نرتاح للأبد',
    'نرمي روحي',
    'تعبت من الدنيا',
    'ننهي حياتي',
    'ما عادش نحب نعيش',
    'fadit mel 7yet',
    'n7eb nmout',
    'nkamel 7yeti',
    '7yeti wfét',
    'n7eb nerté7 lel abad',
    'fadit mel denya',
    'n7eb ne9tel rou7i',
    'nente7er',
    'bch nente7er',
    'ma 3adch n7eb n3ich',
  ];

  /// Level 1 Elevated Distress Keywords: Soft redirect, gentle validation, fewer hypotheses.
  static const List<String> level1DistressPhrases = [
    // English
    'hopeless',
    'worthless',
    'nobody cares',
    'hate myself',
    'falling apart',
    'unbearable',
    'can’t take this',
    'cant take this',
    'drowning in sadness',

    // French
    'désespéré',
    'desespere',
    'je vaux rien',
    'personne ne m’aime',
    'je craque',
    'insupportable',
    'angoisse totale',

    // Arabic / Tunisian Dialect & Arabizi
    'فقدت الأمل',
    'تعبت',
    'حاسس روحي وحدي',
    'ماعادش عندي جهد',
    'الدنيا ضاقت بيا',
    'khaief barcha',
    'ta3eb barcha',
    'faddit',
    'ma 3adch 3andi jahd',
    'denya dha9et',
  ];

  /// Evaluates text offline and returns:
  /// - 2 for immediate crisis indicators
  /// - 1 for elevated distress
  /// - 0 for normal investigation
  static int evaluateText(String text) {
    if (text.trim().isEmpty) return 0;

    final lower = text.toLowerCase();

    // Check Level 2 first (highest risk)
    for (final phrase in level2CrisisPhrases) {
      if (lower.contains(phrase.toLowerCase())) {
        return 2;
      }
    }

    // Check Level 1
    for (final phrase in level1DistressPhrases) {
      if (lower.contains(phrase.toLowerCase())) {
        return 1;
      }
    }

    return 0;
  }
}
