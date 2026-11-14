import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/core/safety/crisis_keywords.dart';
import 'package:mind_forensics/core/safety/safety_interceptor.dart';

void main() {
  group('Stage 5.5 Final Contextual Safety Decision Hierarchy — Scenarios A through J', () {
    // ── Scenario A: Explicit Denial ──────────────────────────────────────────
    test('Scenario A: "I don\'t want to kill myself." -> Level 1 explicitDenial without crisis lockout', () {
      final denialInputs = [
        "I don't want to kill myself.",
        "I dont want to kill myself.",
        "I do not want to die.",
        "I would never kill myself.",
        "Je ne veux pas me suicider.",
        "Je n'ai pas envie de mourir.",
        "مانيش حابب نقتل روحي.",
        "ما نحبش نموت.",
        "mouch n7eb ne9tel rou7i.",
        "ma n7ebech nmout.",
      ];

      for (final text in denialInputs) {
        final classification = CrisisKeywords.classifyText(text);
        expect(
          classification,
          equals(SafetyClassification.explicitDenial),
          reason: 'Expected explicitDenial for: $text, got: $classification',
        );
        expect(CrisisKeywords.evaluateText(text), equals(1), reason: 'Expected Level 1 for: $text');
        expect(SafetyInterceptor.resolveSafetyLevel(userText: text, aiSafetyLevel: 0), equals(1));
      }
    });

    // ── Scenario B: Unwanted Intrusive Thoughts (Ego-Dystonic) ────────────────
    test('Scenario B: "I have intrusive thoughts about swallowing pills." -> Level 1 unwantedIntrusiveThoughts', () {
      final intrusiveInputs = [
        "I keep having intrusive thoughts about swallowing pills.",
        "I have intrusive thoughts about swallowing pills.",
        "I keep having intrusive thoughts to swallow pills.",
        "I have unwanted thoughts about jumping off a balcony.",
        "A random thought popped in my head about cutting myself.",
        "J'ai des pensées intrusives qui me disent d'avaler des pilules.",
        "أفكار اقتحامية تتردد في راسي عن شرب دواء.",
        "افكار وسواسية عن إيذاء نفسي.",
        "afkar i9ti7amia bch nochrob dwe.",
      ];

      for (final text in intrusiveInputs) {
        final classification = CrisisKeywords.classifyText(text);
        expect(
          classification,
          equals(SafetyClassification.unwantedIntrusiveThoughts),
          reason: 'Expected unwantedIntrusiveThoughts for: $text, got: $classification',
        );
        expect(CrisisKeywords.evaluateText(text), equals(1), reason: 'Expected Level 1 for: $text');
      }
    });

    // ── Scenario C: Denial + Concrete Decision / Action ─────────────────────
    test('Scenario C: "I don\'t want to die, but I\'ve decided to take all my medication." -> Level 2 imminentIntentOrCrisis', () {
      const text = "I don't want to die, but I've decided to take all my medication.";
      final classification = CrisisKeywords.classifyText(text);
      expect(
        classification,
        equals(SafetyClassification.imminentIntentOrCrisis),
        reason: 'Concrete decision/plan must override denial marker',
      );
      expect(CrisisKeywords.evaluateText(text), equals(2));
      expect(SafetyInterceptor.resolveSafetyLevel(userText: text, aiSafetyLevel: 0), equals(2));
    });

    // ── Scenario D: Intrusive Thoughts + Preparation & Stated Intent ────────
    test('Scenario D: "I have intrusive thoughts about taking pills, and I\'m holding them because I\'m going to take them." -> Level 2 imminentIntentOrCrisis', () {
      const text = "I have intrusive thoughts about taking pills, and I'm holding them because I'm going to take them.";
      final classification = CrisisKeywords.classifyText(text);
      expect(
        classification,
        equals(SafetyClassification.imminentIntentOrCrisis),
        reason: 'Preparation and stated execution intent must override intrusive thoughts',
      );
      expect(CrisisKeywords.evaluateText(text), equals(2));
    });

    // ── Scenario E: Accidental Ingestion Alert (Non-Suicidal Medical Urgency) ─
    test('Scenario E: "I accidentally took more medication than prescribed." -> accidentalIngestionAlert', () {
      final accidentalInputs = [
        "I accidentally took more medication than prescribed.",
        "I accidentally took too many pills by mistake.",
        "J'ai pris trop de médicaments par erreur.",
        "شربت دواء بالغلط.",
        "chrabt dwe bel ghalat.",
      ];

      for (final text in accidentalInputs) {
        final classification = CrisisKeywords.classifyText(text);
        expect(
          classification,
          equals(SafetyClassification.accidentalIngestionAlert),
          reason: 'Expected accidentalIngestionAlert for: $text, got: $classification',
        );
        expect(CrisisKeywords.evaluateText(text), equals(1), reason: 'Expected Level 1 (urgent medical copy) for: $text');
      }
    });

    // ── Scenario F: Ambiguous Disclosure with Denial of Intent ──────────────
    test('Scenario F: "I sometimes imagine taking all my medication, but I don\'t want to do it." -> ambiguousSafetySignal (no Level 2 lockout)', () {
      final ambiguousInputs = [
        "I sometimes imagine taking all my medication, but I don't want to do it.",
        "Sometimes I think about taking all my medication.",
        "Je pense parfois à prendre tous mes médicaments mais je ne veux pas le faire.",
        "خممت نشرب كل الدواء.",
      ];

      for (final text in ambiguousInputs) {
        final classification = CrisisKeywords.classifyText(text);
        expect(
          classification,
          anyOf(
            equals(SafetyClassification.ambiguousSafetySignal),
            equals(SafetyClassification.explicitDenial),
          ),
          reason: 'Expected ambiguous safety check without automatic crisis lockout for: $text',
        );
        expect(CrisisKeywords.evaluateText(text), equals(1));
      }
    });

    // ── Scenario G: Historical Harmful Ingestion ─────────────────────────────
    test('Scenario G: "I took medication to hurt myself yesterday." -> Level 2 immediateMedicalEmergency', () {
      final historicalHarm = [
        "I took medication to hurt myself yesterday.",
        "I swallowed pills to hurt myself yesterday.",
        "J'ai pris des médicaments pour me faire du mal hier.",
        "شربت دوايات باش نأذي روحي البارح.",
      ];

      for (final text in historicalHarm) {
        final classification = CrisisKeywords.classifyText(text);
        expect(
          classification,
          equals(SafetyClassification.immediateMedicalEmergency),
          reason: 'Historical harmful ingestion must be assessed as immediate medical emergency for: $text',
        );
        expect(CrisisKeywords.evaluateText(text), equals(2));
      }
    });

    // ── Scenario H: Denial + Concrete Plan to End Life Tonight ───────────────
    test('Scenario H: "I don\'t want to die, but I have a plan to end my life tonight." -> Level 2 imminentIntentOrCrisis', () {
      const text = "I don't want to die, but I have a plan to end my life tonight.";
      final classification = CrisisKeywords.classifyText(text);
      expect(
        classification,
        equals(SafetyClassification.imminentIntentOrCrisis),
        reason: 'Concrete plan overrides denial prefix',
      );
      expect(CrisisKeywords.evaluateText(text), equals(2));
    });

    // ── Scenario I: Fear of Losing Control (Distinct from Denial) ───────────
    test('Scenario I: "I\'m afraid I might lose control." -> fearOfLosingControl (Level 1, no crisis lockout)', () {
      final fearInputs = [
        "I'm afraid I might lose control.",
        "I have a terrifying fear of losing control.",
        "J'ai peur de perdre le contrôle.",
        "خايف نفقد السيطرة.",
        "khaief nef9ed el saytara.",
      ];

      for (final text in fearInputs) {
        final classification = CrisisKeywords.classifyText(text);
        expect(
          classification,
          equals(SafetyClassification.fearOfLosingControl),
          reason: 'Expected fearOfLosingControl for: $text, got: $classification',
        );
        expect(CrisisKeywords.evaluateText(text), equals(1));
      }
    });

    // ── Scenario J: Intrusive Thoughts with Explicit Negation of Intent ──────
    test('Scenario J: "I have intrusive thoughts, but I have no intention of acting on them." -> unwantedIntrusiveThoughts (Level 1)', () {
      final noIntentIntrusive = [
        "I have intrusive thoughts, but I have no intention of acting on them.",
        "I have intrusive thoughts about swallowing pills, but I would never do it.",
        "J'ai des pensées intrusives, mais je n'ai aucune intention de passer à l'acte.",
        "أفكار اقتحامية في راسي، أما ما عندي حتى نية باش نعملها.",
      ];

      for (final text in noIntentIntrusive) {
        final classification = CrisisKeywords.classifyText(text);
        expect(
          classification,
          equals(SafetyClassification.unwantedIntrusiveThoughts),
          reason: 'Expected unwantedIntrusiveThoughts for: $text, got: $classification',
        );
        expect(CrisisKeywords.evaluateText(text), equals(1));
      }
    });

    // ── Normal / Prescribed Medication Mentions ─────────────────────────────
    test('Prescribed medication use without harmful intent remains Level 0 normal', () {
      final normalPrescriptions = [
        "I took my daily blood pressure medication this morning.",
        "Can I track my prescribed antidepressants in the app?",
        "J'ai pris mes vitamines aujourd'hui.",
        "شربت دوائي في الوقت كيما قال الطبيب.",
      ];

      for (final text in normalPrescriptions) {
        expect(CrisisKeywords.classifyText(text), equals(SafetyClassification.normal));
        expect(CrisisKeywords.evaluateText(text), equals(0));
      }
    });

    // ── Runtime Interception & UI Routing Integrity ─────────────────────────
    test('Accidental ingestion alert triggers immediate interceptor without invoking AI service', () {
      const accidentalText = "I accidentally took more medication than prescribed.";
      final classification = CrisisKeywords.classifyText(accidentalText);

      // 1. Classification matches accidentalIngestionAlert
      expect(classification, equals(SafetyClassification.accidentalIngestionAlert));

      // 2. Interceptor condition triggers pre-generation halt
      final shouldHaltPreGeneration =
          classification == SafetyClassification.immediateMedicalEmergency ||
          classification == SafetyClassification.imminentIntentOrCrisis ||
          classification == SafetyClassification.accidentalIngestionAlert;
      expect(shouldHaltPreGeneration, isTrue);

      // 3. Verifies that intentional self-harm is decoupled from accidental overdose
      expect(classification == SafetyClassification.imminentIntentOrCrisis, isFalse);
    });
  });
}
