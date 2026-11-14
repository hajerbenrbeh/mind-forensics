import '../../journey/domain/journey_activity.dart';
import '../../profile/domain/psychological_profile_model.dart';
import '../domain/mind_trace_model.dart';

/// Service responsible for generating the AI Daily Reflection after a check-in.
///
/// Strictly abides by Section 3 & 4 clinical principles:
/// - Acknowledges what the user shared with warmth and precision.
/// - Identifies possible connections to previous entries when supported by real data.
/// - Distinguishes observable facts from hypotheses.
/// - Asks one meaningful Socratic question.
/// - Never diagnoses or fabricates patterns from insufficient data.
/// - Trilingual support (authentic Tunisian Arabic, French, English).
/// - 0 emojis.
class MindTraceAiService {
  MindTraceAiService({
    this.apiKey,
    this.modelName = 'gemini-3.5-flash',
  });

  static const String kDevMockKey = 'DEV_MOCK_GEMINI_KEY';
  static const bool kIsNetworkPermanentlyDisabled = true;
  static const List<String> fallbackModels = [
    'gemini-3.5-flash',
    'gemini-3.1-flash-lite',
  ];

  final String? apiKey;
  final String modelName;
  bool? lastCallWasLive;
  String? lastModelUsed;
  String? lastError;

  Future<String> generateDailyReflection({
    required MindTraceModel currentTrace,
    required List<MindTraceModel> history,
    required PsychologicalProfileModel? profile,
    required String languageCode,
    List<JourneyActivity>? availableActivities,
  }) async {
    lastCallWasLive = null;
    lastError = null;

    final canShareExternally = profile != null && profile.shareWithAiCompanion;

    // Consent Gate: If consent for external data sharing is missing or revoked,
    // NEVER transmit telemetry to external cloud AI APIs.
    // Instantly route to the 100% on-device local generator.
    if (!canShareExternally) {
      lastCallWasLive = false;
      return _generateLocalReflection(
        currentTrace: currentTrace,
        history: const [], // Strict privacy: do not access past history without consent
        profile: profile,
        languageCode: languageCode,
      );
    }

    // In Stage 6.1A.3: Gemini network transmission is permanently disabled.
    // Mind Forensics uses local deterministic reflection until the separate Grok implementation stage.
    // External transmission is strictly blocked with zero outbound HTTP requests.
    lastCallWasLive = false;
    final allowsPersonalization = profile.allowAiPersonalization;
    return _generateLocalReflection(
      currentTrace: currentTrace,
      history: allowsPersonalization ? history : const [],
      profile: profile,
      languageCode: languageCode,
    );
  }


  String _generateLocalReflection({
    required MindTraceModel currentTrace,
    required List<MindTraceModel> history,
    required PsychologicalProfileModel? profile,
    required String languageCode,
  }) {
    final isAr = languageCode == 'ar';
    final isFr = languageCode == 'fr';

    final mood = currentTrace.overallMood.toLowerCase();
    final intensity = currentTrace.moodIntensity;
    final tension = currentTrace.physicalTension ?? 5;

    // Detect patterns across history
    final hasHighTensionHistory = history.isNotEmpty &&
        history.take(3).any((h) => (h.physicalTension ?? 0) >= 7);

    final hasRepeatedOverwhelm = history.isNotEmpty &&
        history.take(3).where((h) => h.moodIntensity >= 7).length >= 2;

    if (isAr) {
      if (hasRepeatedOverwhelm) {
        return 'لاحظت اللي فما شعور متكرر بضغط عالي في الأيام الأخيرة. زعمة فما موقف ولا محفز معين قاعد يتكرر وما فقتش بيه؟ شنوة اللي قاعد يحرك الإحساس هذا توا؟';
      } else if (hasHighTensionHistory || tension >= 7) {
        return 'بدنك اليوم باين عليه شادد توتر ملحوظ. الملاحظة هذي ماهيش حكم على ضعفك، بل إشارة تنبيه من جهازك العصبي. وين تحس بالضغط أكثر شيء في بدنك في اللحظة هذي؟';
      } else if (mood == 'anxious' || intensity >= 7) {
        return 'باين عليه نهار تطلب منك جهد وطاقة كبيرة باش تتحمله. فكرة أنك وقفت توا وسجلت أثر يومك هي أول خطوة في التهدئة. شنوة أكثر فكرة قالقتك اليوم؟';
      } else {
        return 'سجلت اليوم أثر هادئ ومتزن في مسارك. كي تتفكر الساعات اللي تعداو، شنوة الحاجة البسيطة اللي عاونت بالك باش يبقى مرتاح؟';
      }
    } else if (isFr) {
      if (hasRepeatedOverwhelm) {
        return 'J’observe une intensité émotionnelle soutenue sur plusieurs de vos derniers bilans. Je me demande s’il existe une situation récurrente associée à ce sentiment. Qu’aimeriez-vous explorer à ce sujet ?';
      } else if (hasHighTensionHistory || tension >= 7) {
        return 'Votre corps semble enregistrer une tension physique importante aujourd’hui. C’est un signal précieux de votre système nerveux. Dans quelle partie de votre corps ressentez-vous le plus cette activation ?';
      } else {
        return 'Votre trace du jour témoigne d’une belle présence à vous-même. En observant le fil de cette journée, quelle petite chose a contribué à votre équilibre ?';
      }
    } else {
      if (hasRepeatedOverwhelm) {
        return 'I noticed that you\'ve reported elevated emotional intensity across several recent check-ins. I wonder whether there is a recurring theme or situation associated with that feeling. Would you like to explore what is maintaining it?';
      } else if (hasHighTensionHistory || tension >= 7) {
        return 'Your body is reporting noticeable physical tension today. Recognizing this somatic signal is the first step toward settling. Where in your body do you feel this tension most prominently right now?';
      } else {
        return 'You have captured a thoughtful and grounded trace of your day. Looking back on the past few hours, what was one moment where your mind felt most at ease?';
      }
    }
  }
}

