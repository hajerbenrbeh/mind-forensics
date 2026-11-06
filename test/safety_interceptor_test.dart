import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/core/safety/crisis_keywords.dart';
import 'package:mind_forensics/core/safety/safety_interceptor.dart';

void main() {
  group('Two-Layer Safety Interceptor Tests', () {
    test('Layer 1 (Offline): Returns Level 0 for normal, non-crisis thoughts', () {
      const normalText = 'I am worried about my job interview tomorrow morning.';
      expect(CrisisKeywords.evaluateText(normalText), equals(0));
    });

    test('Layer 1 (Offline): Detects Level 1 elevated distress keywords', () {
      const distressEnglish = 'I feel completely hopeless and like nobody cares.';
      const distressFrench = 'C’est insupportable, je craque complètement.';
      const distressArabizi = 'Faddit barcha men kol chay.';

      expect(CrisisKeywords.evaluateText(distressEnglish), equals(1));
      expect(CrisisKeywords.evaluateText(distressFrench), equals(1));
      expect(CrisisKeywords.evaluateText(distressArabizi), equals(1));
    });

    test('Layer 1 (Offline): Immediately detects Level 2 crisis phrases without AI', () {
      const crisisEnglish = 'I want to kill myself and end this.';
      const crisisFrench = 'J’ai envie de mourir ce soir.';
      const crisisArabic = 'أريد الانتحار';
      const crisisTunisianDialect = 'نحب نموت وفديت من حياتي';
      const crisisArabizi = 'n7eb ne9tel rou7i tawwa';

      expect(CrisisKeywords.evaluateText(crisisEnglish), equals(2));
      expect(CrisisKeywords.evaluateText(crisisFrench), equals(2));
      expect(CrisisKeywords.evaluateText(crisisArabic), equals(2));
      expect(CrisisKeywords.evaluateText(crisisTunisianDialect), equals(2));
      expect(CrisisKeywords.evaluateText(crisisArabizi), equals(2));
    });

    test('Safety Resolution: The HIGHEST safety level always wins', () {
      // Scenario A: Offline check is Level 2, AI says Level 0 -> Level 2 wins
      expect(
        SafetyInterceptor.resolveSafetyLevel(
          userText: 'I want to end my life',
          aiSafetyLevel: 0,
        ),
        equals(2),
      );

      // Scenario B: Offline check is Level 0, but AI detects Level 1 distress -> Level 1 wins
      expect(
        SafetyInterceptor.resolveSafetyLevel(
          userText: 'I just feel sad today.',
          aiSafetyLevel: 1,
        ),
        equals(1),
      );

      // Scenario C: Offline check is Level 1, AI detects Level 2 -> Level 2 wins
      expect(
        SafetyInterceptor.resolveSafetyLevel(
          userText: 'I feel hopeless',
          aiSafetyLevel: 2,
        ),
        equals(2),
      );

      // Scenario D: Both say Level 0 -> Level 0
      expect(
        SafetyInterceptor.resolveSafetyLevel(
          userText: 'He did not reply for 2 hours.',
          aiSafetyLevel: 0,
        ),
        equals(0),
      );
    });
  });
}

