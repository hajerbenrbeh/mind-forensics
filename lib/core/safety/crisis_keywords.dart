/// Structured triage classification result produced by the offline safety engine.
enum SafetyClassification {
  /// Tier 1: Acute medical emergency or action already taken (overdose, intentional harmful ingestion, active self-harm).
  /// Requires immediate emergency medical dispatch guidance (SAMU 190 / Protection Civile 198).
  immediateMedicalEmergency,

  /// Tier 1b: Accidental overdose or ingestion (e.g. took wrong dosage by mistake without suicidal intent).
  /// Highly urgent medical event requiring prompt poison control / medical assessment without assuming self-harm.
  accidentalIngestionAlert,

  /// Tier 2: Imminent affirmative suicidal or self-harm intent, stated plan, or concrete preparation.
  /// Halts cognitive analysis immediately and presents crisis support lines.
  imminentIntentOrCrisis,

  /// Tier 3: Mixed or ambiguous safety signals (e.g., partial denial alongside access/preparation,
  /// or thoughts of taking all medication). Requires direct, compassionate safety inquiry turn.
  ambiguousSafetySignal,

  /// Tier 4: Ego-dystonic unwanted intrusive thoughts (without affirmative intent or preparation).
  /// Handled via Intrusive Thought Protocol (Scenario 1) without reassurance loops.
  unwantedIntrusiveThoughts,

  /// Tier 5: Direct denial of intent (without contradictory preparation or intent).
  /// Validates relief/distress and permits supportive dialogue without Level 2 lockout.
  explicitDenial,

  /// Tier 6: Distress or panic specifically about fear of losing control (distinct from intent or denial).
  /// Normalizes autonomic symptoms and grounds without psychiatric labelling.
  fearOfLosingControl,

  /// Tier 7: General elevated distress (hopelessness, sadness, exhaustion) requiring soft redirect.
  generalDistress,

  /// Normal interaction without elevated distress.
  normal,
}

/// Offline crisis and elevated distress keyword lists and contextual decision hierarchy.
///
/// Section 6 & Step 8.6 & Stage 5.5:
/// Deterministic, offline safety triage engine prioritizing:
/// 1. Harmful ingestion or injury already occurred (Immediate Medical Emergency)
/// 2. Accidental overdose or excessive medication (Accidental Ingestion Alert)
/// 3. Concrete current preparation, stated plan, or imminent affirmative intent (Level 2)
/// 4. Mixed or conflicting signals without enough information (Ambiguous Safety Signal)
/// 5. Unwanted intrusive thoughts without intent or preparation (Intrusive Thoughts)
/// 6. Explicit denial without contradictory intent (Explicit Denial)
/// 7. Fear of losing control without affirmative intent (Fear of Losing Control)
/// 8. General distress and normal conversation
class CrisisKeywords {
  // ── 1. Medical Emergency & Harmful Ingestion Keywords ───────────────────────
  static const List<String> emergencyActionPhrases = [
    // English
    'have taken pills to hurt',
    'have taken pills to harm',
    'took pills to hurt',
    'took pills to harm',
    'swallowed pills to hurt',
    'swallowed pills to harm',
    'took medication to hurt myself',
    'took medication to harm myself',
    'swallowed all my pills',
    'took all my pills',
    'drank bleach',
    'slit my wrists',
    'already took the pills',
    'took an overdose',
    'just took all my pills',
    'swallowed a bottle of pills',
    'swallowed a bottle',
    // French
    'ai pris des pilules pour me faire du mal',
    'ai pris des médicaments pour me faire du mal',
    'ai avalé des pilules pour me faire du mal',
    'pris tous mes médicaments',
    'ai fait une overdose',
    'viens de prendre des pilules pour en finir',
    // Arabic & Tunisian Arabizi
    'شربت دوايات باش نموت',
    'خديت حرابش باش نضر روحي',
    'شربت دواء باش نأذي روحي',
    'شربت دوايات باش نأذي روحي',
    'شربت دوايات باش نضر روحي',
    'شربت الدواء البارح باش نموت',
    'chrabt dweyet bch nmout',
    'chrabt barcha dweyet bch nmot',
  ];

  // ── 2. Accidental Ingestion / Overdose Markers ──────────────────────────────
  static const List<String> accidentalIngestionPhrases = [
    'accidentally took more medication',
    'accidentally took too many pills',
    'accidentally took an extra dose',
    'accidentally took more than prescribed',
    'took too much medication by mistake',
    'took the wrong pills by accident',
    'accidentally overdosed',
    'took double dose by mistake',
    // French
    'pris trop de médicaments par erreur',
    'pris une double dose par erreur',
    'trompé de médicament par accident',
    'surdosage accidentel',
    // Arabic & Tunisian Arabizi
    'شربت دواء بالغلط',
    'شربت جرعة زايدة بالغلط',
    'غلطت في الدواء وشربت برشا',
    'chrabt dwe bel ghalat',
  ];

  // ── 3. Concrete Preparation, Stated Plan, & Affirmative Intent ──────────────
  static const List<String> preparationAndIntentPhrases = [
    // Stated Plan & Decision
    'decided to take all my medication',
    'decided to take all my pills',
    'have a plan to end my life',
    'plan to end my life',
    'have a plan to kill myself',
    'plan to kill myself',
    'holding them because i’m going to take them',
    'holding them because im going to take them',
    'holding them because i am going to take them',
    'ready to end it all',
    'ready to end my life',
    // Explicit Intent
    'want to kill myself',
    'going to kill myself',
    'gonna kill myself',
    'want to die',
    'end my life',
    'commit suicide',
    'better off dead',
    'hang myself',
    'slit my wrists',
    'jump off a bridge',
    'shoot myself',
    // French
    'décidé de prendre tous mes médicaments',
    'decide de prendre tous mes medicaments',
    'ai un plan pour en finir',
    'plan pour mettre fin à mes jours',
    'veux me suicider',
    'vais me suicider',
    'envie de mourir',
    'mettre fin à mes jours',
    'en finir avec la vie',
    'me pendre',
    // Arabic & Tunisian Arabizi
    'قررت نشرب كل الدواء',
    'عندي خطة باش ننهي حياتي',
    'نحب نقتل روحي',
    'باش نقتل روحي',
    'نحب نموت',
    'ننهي حياتي',
    'نشنق روحي',
    'نرمي روحي',
    '9arrart nochrob el dwe el kol',
    'n7eb ne9tel rou7i',
    'bch ne9tel rou7i',
    'n7eb nmout',
    'bch nente7er',
    'nente7er',
  ];

  // ── Generic Level 2 Fallback Crisis Phrases ─────────────────────────────────
  static const List<String> level2CrisisPhrases = [
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
    'swallow pills',
    'bottle of pills',
    'take all my pills',
    'slit my wrists',
    'hang myself',
    'hurt myself',
    'harm myself',
    'cut myself',
    'bleed out',
    // French
    'me suicider',
    'envie de mourir',
    'mettre fin à mes jours',
    'me faire du mal',
    'plus envie de vivre',
    'en finir avec la vie',
    'automutilation',
    'avaler des pilules',
    'me couper les veines',
    'me pendre',
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
    'نشرب دوايات',
    'نجرح روحي',
    'نشنق روحي',
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
    'nochrob dweyet',
  ];

  // ── 4. Ambiguous Safety Signals ─────────────────────────────────────────────
  static const List<String> ambiguousSafetyPhrases = [
    'think about taking all my medication',
    'thinking about taking all my medication',
    'think about taking all my pills',
    'thinking about swallowing all my pills',
    'sometimes i think about taking all',
    'sometimes imagine taking all my medication',
    'imagine taking all my medication',
    'penser à prendre tous mes médicaments',
    'pense à prendre tous mes médicaments',
    'penser a prendre tous mes medicaments',
    'pense a prendre tous mes medicaments',
    'خممت نشرب كل الدواء',
    'n5amem nochrob el dwe el kol',
  ];

  // ── 5. Ego-Dystonic Intrusive Thought Markers ────────────────────────────────
  static const List<String> intrusiveThoughtMarkers = [
    'intrusive thought',
    'intrusive thoughts',
    'unwanted thought',
    'unwanted thoughts',
    'random thought',
    'random thoughts',
    'thought popped in my head',
    'flash in my head',
    'image pops in my head',
    'keep thinking what if',
    'thoughts won’t stop',
    'pensée intrusive',
    'pensées intrusives',
    'pensée involontaire',
    'peur d’avoir cette pensée',
    'فكرة تسكن في راسي',
    'أفكار اقتحامية',
    'افكار اقتحامية',
    'أفكار وسواسية',
    'افكار وسواسية',
    'فكرة تتردد موش حاببها',
    'afkar i9ti7amia',
    'afkar waswasia',
    'fekra dakhla l mokhi mouch n7ebha',
  ];

  // ── 6. Explicit Denial / Negation Markers ───────────────────────────────────
  static const List<String> denialOrNegationMarkers = [
    "don't want to",
    "dont want to",
    "do not want to",
    "would never",
    "no intention to",
    "no intention of",
    "no desire to",
    "never want to",
    "je ne veux pas",
    "n'ai pas envie de",
    "pas envie de",
    "je ne veux surtout pas",
    "jamais de la vie",
    "aucune intention de",
    "مانيش حابب",
    "مانحبش",
    "ما نحبش",
    "مستحيل",
    "ما عنديش نية",
    "mouch n7eb",
    "ma n7ebech",
    "man7ebech",
    "mosta7il",
  ];

  // ── 7. Fear of Losing Control Markers ───────────────────────────────────────
  static const List<String> fearOfLosingControlMarkers = [
    'afraid i might lose control',
    'fear of losing control',
    'scared i might lose control',
    'terrified i will lose control',
    'fear i will snap',
    'peur de perdre le contrôle',
    'peur de craquer',
    'خايف نفقد السيطرة',
    'خايف نتهور',
    'khaief nef9ed el saytara',
  ];

  // ── 8. Level 1 Elevated Distress Keywords ───────────────────────────────────
  static const List<String> level1DistressPhrases = [
    'hopeless',
    'worthless',
    'nobody cares',
    'hate myself',
    'falling apart',
    'unbearable',
    'can’t take this',
    'cant take this',
    'drowning in sadness',
    'losing my mind',
    'going crazy',
    'losing control',
    'lose control',
    'can’t handle this',
    'cant handle this',
    'feel detached',
    // French
    'désespéré',
    'desespere',
    'je vaux rien',
    'personne ne m’aime',
    'je craque',
    'insupportable',
    'angoisse totale',
    'perdre la tête',
    'deviens fou',
    'perds le contrôle',
    // Arabic / Tunisian Dialect & Arabizi
    'فقدت الأمل',
    'تعبت',
    'حاسس روحي وحدي',
    'ماعادش عندي جهد',
    'الدنيا ضاقت بيا',
    'نفقد السيطرة',
    'ما عادش نجم نتحمل',
    'مهبول',
    'khaief barcha',
    'ta3eb barcha',
    'faddit',
    'ma 3adch 3andi jahd',
    'denya dha9et',
  ];

  static final List<String> _normalizedEmergencyAction =
      emergencyActionPhrases.map(normalize).toList();
  static final List<String> _normalizedAccidental =
      accidentalIngestionPhrases.map(normalize).toList();
  static final List<String> _normalizedPreparationAndIntent =
      preparationAndIntentPhrases.map(normalize).toList();
  static final List<String> _normalizedLevel2 =
      level2CrisisPhrases.map(normalize).toList();
  static final List<String> _normalizedAmbiguous =
      ambiguousSafetyPhrases.map(normalize).toList();
  static final List<String> _normalizedIntrusive =
      intrusiveThoughtMarkers.map(normalize).toList();
  static final List<String> _normalizedFearControl =
      fearOfLosingControlMarkers.map(normalize).toList();
  static final List<String> _normalizedLevel1 =
      level1DistressPhrases.map(normalize).toList();

  /// Normalizes Arabic and Latin characters: strips Tashkeel, Tatweel,
  /// unifies Alef variants, converts Alef Maksura to Yaa, Teh Marbuta to Ha,
  /// and cleans smart quotes and whitespace.
  static String normalize(String text) {
    if (text.isEmpty) return '';

    var s = text.toLowerCase();

    // 1. Normalize smart quotes and apostrophes
    s = s
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('`', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"');

    // 2. Strip Arabic diacritics / Tashkeel & Tatweel (Kashida)
    s = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '');

    // 3. Normalize Arabic Alef variants [أ, إ, آ, ٱ] -> ا
    s = s.replaceAll(RegExp(r'[أإآٱ]'), 'ا');

    // 4. Normalize Arabic Alef Maksura (ى) -> Yaa (ي)
    s = s.replaceAll('ى', 'ي');

    // 5. Normalize Arabic Teh Marbuta (ة) -> Ha (ه)
    s = s.replaceAll('ة', 'ه');

    // 6. Collapse multiple spaces and trim
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    return s;
  }

  /// Classifies user text into one of the safety tiers using the strict contextual hierarchy:
  ///
  /// 1. Harmful ingestion or injury already occurred (immediateMedicalEmergency)
  /// 2. Accidental overdose or excessive medication (accidentalIngestionAlert)
  /// 3. Concrete current preparation, stated plan, or imminent intent (imminentIntentOrCrisis)
  /// 4. Mixed or conflicting signals without enough information (ambiguousSafetySignal)
  /// 5. Unwanted intrusive thoughts without intent or preparation (unwantedIntrusiveThoughts)
  /// 6. Explicit denial without contradictory intent (explicitDenial)
  /// 7. Fear of losing control without affirmative intent (fearOfLosingControl)
  /// 8. General distress and normal conversation
  static SafetyClassification classifyText(String text) {
    if (text.trim().isEmpty) return SafetyClassification.normal;

    final norm = normalize(text);

    // ── Tier 1: Harmful Ingestion or Injury Already Occurred ─────────────────
    // Current or historical harmful ingestion requires immediate medical assessment.
    for (final phrase in _normalizedEmergencyAction) {
      if (norm.contains(phrase)) {
        return SafetyClassification.immediateMedicalEmergency;
      }
    }
    final pastIngestionRegex = RegExp(
      r'\b(took|have taken|swallowed|drank|chrabt|pris|ai pris)\b.*?\b(pills|medication|tablets|dwe|medicaments|pilules|cachets)\b.*?\b(hurt|harm|die|kill|blesser|mourir|ne9tel|ndhor)\b',
    );
    if (pastIngestionRegex.hasMatch(norm)) {
      return SafetyClassification.immediateMedicalEmergency;
    }

    // ── Tier 1b: Accidental Ingestion Alert (Non-suicidal medical emergency) ─
    for (final phrase in _normalizedAccidental) {
      if (norm.contains(phrase)) {
        return SafetyClassification.accidentalIngestionAlert;
      }
    }
    final accidentalRegex = RegExp(
      r'\b(accidentally|by mistake|par erreur|par accident|bel ghalat|بالغلط|عن طريق الخطأ)\b.*?\b(took|pris|chrabt|swallowed|avale|overdose|surdosage)\b.*?\b(medication|pills|tablets|dose|medicaments|pilules|dwe)\b',
    );
    if (accidentalRegex.hasMatch(norm)) {
      return SafetyClassification.accidentalIngestionAlert;
    }

    // ── Pre-Extraction of Plan / Preparation / Affirmative Intent ────────────
    // Check if user affirms concrete preparation or a stated plan:
    final concretePreparationRegex = RegExp(
      r"""\b(holding them because|have a plan to|plan to|decided to take all|gonna take them|going to take them|decide de prendre tous|ai un plan pour|plan pour|9arrart nochrob|قررت نشرب|عندي خطة)\b""",
    );
    final hasConcretePreparation = concretePreparationRegex.hasMatch(norm);

    // ── Pre-Extraction of Modifiers (Intrusive, Denial, Fear of Control) ─────
    final hasIntrusiveMarker = _normalizedIntrusive.any((m) => norm.contains(m));
    final hasFearOfControlMarker = _normalizedFearControl.any((m) => norm.contains(m));

    // Direct denial check (e.g. "don't want to kill myself", "je ne veux pas me suicider")
    final directNegationRegex = RegExp(
      r"""(don't|dont|do not|would never|never|pas|ne veux pas|n'ai pas envie de|pas envie de|aucune intention de|no intention of|no intention to|man7ebch|mouch n7eb|ma n7ebech|مانيش حابب|مانحبش|ما نحبش|مانيش|موش حابب)\s+(want to\s+|envie de\s+|acting on\s+)?(kill myself|die|suicide|hurt myself|harm myself|end my life|me suicider|me faire du mal|mourir|ne9tel rou7i|nmout|acting on them|them|نقتل روحي|نموت|نأذي روحي)""",
    );
    final hasDirectNegation = directNegationRegex.hasMatch(norm);

    // Check affirmative intent ONLY when the intent isn't what's directly negated
    bool hasAffirmativeIntent = false;
    for (final phrase in _normalizedPreparationAndIntent) {
      if (norm.contains(phrase)) {
        if (hasDirectNegation) {
          final remainder = norm.replaceFirst(directNegationRegex, '').trim();
          if (remainder.contains(phrase)) {
            hasAffirmativeIntent = true;
            break;
          }
        } else {
          hasAffirmativeIntent = true;
          break;
        }
      }
    }

    // ── Tier 2: Concrete Preparation, Stated Plan, or Imminent Intent ────────
    // MANDATORY SAFEGUARD: A denial or intrusive-thought marker must NEVER suppress
    // a separate concrete plan, preparation, or affirmative intent!
    // E.g. "I don't want to die, but I've decided to take all my medication" -> Tier 2
    // E.g. "I have intrusive thoughts about taking pills, and I'm holding them because I'm going to take them" -> Tier 2
    // E.g. "I don't want to die, but I have a plan to end my life tonight" -> Tier 2
    if (hasConcretePreparation || hasAffirmativeIntent) {
      return SafetyClassification.imminentIntentOrCrisis;
    }

    // ── Tier 3: Mixed or Ambiguous Signals ───────────────────────────────────
    for (final phrase in _normalizedAmbiguous) {
      if (norm.contains(phrase)) {
        return SafetyClassification.ambiguousSafetySignal;
      }
    }
    if ((norm.contains('taking all') || norm.contains('swallowing all') || norm.contains('prendre tous') || norm.contains('imagine taking all') || norm.contains('prendre tous mes')) &&
        (norm.contains('medication') || norm.contains('medicament') || norm.contains('médicament') || norm.contains('pills') || norm.contains('dwe'))) {
      return SafetyClassification.ambiguousSafetySignal;
    }

    // ── Tier 4: Unwanted Intrusive Thoughts (Without Intent or Preparation) ──
    if (hasIntrusiveMarker) {
      return SafetyClassification.unwantedIntrusiveThoughts;
    }

    // ── Tier 5: Explicit Denial (Direct Negation Without Intent) ─────────────
    if (hasDirectNegation) {
      return SafetyClassification.explicitDenial;
    }

    // ── Tier 6: Fear of Losing Control (Distinct from Denial) ────────────────
    if (hasFearOfControlMarker) {
      return SafetyClassification.fearOfLosingControl;
    }

    // ── Fallback Level 2 Crisis Keywords (When not negated or intrusive) ─────
    for (final phrase in _normalizedLevel2) {
      if (norm.contains(phrase)) {
        return SafetyClassification.imminentIntentOrCrisis;
      }
    }

    // ── Tier 7: General Elevated Distress ────────────────────────────────────
    for (final phrase in _normalizedLevel1) {
      if (norm.contains(phrase)) {
        return SafetyClassification.generalDistress;
      }
    }

    return SafetyClassification.normal;
  }

  /// Evaluates user text and returns the backward-compatible integer triage level:
  /// - 2: Immediate crisis, harmful ingestion, or preparation (Gentle Pause)
  /// - 1: Accidental overdose, elevated distress, intrusive thoughts, denial, fear, or ambiguous disclosure
  /// - 0: Normal investigation
  static int evaluateText(String text) {
    final classification = classifyText(text);
    switch (classification) {
      case SafetyClassification.immediateMedicalEmergency:
      case SafetyClassification.imminentIntentOrCrisis:
        return 2;
      case SafetyClassification.accidentalIngestionAlert:
      case SafetyClassification.ambiguousSafetySignal:
      case SafetyClassification.unwantedIntrusiveThoughts:
      case SafetyClassification.explicitDenial:
      case SafetyClassification.fearOfLosingControl:
      case SafetyClassification.generalDistress:
        return 1;
      case SafetyClassification.normal:
        return 0;
    }
  }
}
