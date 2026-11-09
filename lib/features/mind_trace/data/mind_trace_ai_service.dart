import 'dart:convert';
import 'dart:io';

import '../../../core/security/daily_usage_limiter.dart';
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

  final String? apiKey;
  final String modelName;

  Future<String> generateDailyReflection({
    required MindTraceModel currentTrace,
    required List<MindTraceModel> history,
    required PsychologicalProfileModel? profile,
    required String languageCode,
    List<JourneyActivity>? availableActivities,
  }) async {
    final hasConsent = profile != null &&
        profile.shareWithAiCompanion &&
        profile.allowAiPersonalization;

    // Consent Gate: If consent for AI companion or personalization is revoked,
    // NEVER transmit telemetry to external cloud AI APIs (Gemini).
    // Instantly route to the 100% on-device local generator with zero historical linkage.
    if (!hasConsent) {
      return _generateLocalReflection(
        currentTrace: currentTrace,
        history: const [], // Strict privacy: do not access past history without consent
        profile: profile,
        languageCode: languageCode,
      );
    }

    final cleanKey = apiKey?.trim() ?? '';

    if (cleanKey.isNotEmpty && cleanKey != kDevMockKey) {
      final geminiResult = await _callGeminiReflection(
        apiKey: cleanKey,
        currentTrace: currentTrace,
        history: history,
        profile: profile,
        languageCode: languageCode,
      );
      if (geminiResult != null && geminiResult.trim().isNotEmpty) {
        return geminiResult.trim();
      }
    }

    // Local Clinical Generator (Offline fallback)
    return _generateLocalReflection(
      currentTrace: currentTrace,
      history: history,
      profile: profile,
      languageCode: languageCode,
    );
  }

  Future<String?> _callGeminiReflection({
    required String apiKey,
    required MindTraceModel currentTrace,
    required List<MindTraceModel> history,
    required PsychologicalProfileModel? profile,
    required String languageCode,
  }) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty || cleanKey == kDevMockKey) return null;
    // Defense-in-depth consent check
    final hasConsent = profile != null &&
        profile.shareWithAiCompanion &&
        profile.allowAiPersonalization;
    if (!hasConsent) return null;

    final canProceed = await DailyUsageLimiter.canMakeRequest();
    if (!canProceed) return null;

    final systemInstruction = '''
You are the Mind Forensics Psychological Companion providing a short, deeply compassionate, and scientifically informed Daily Mind Trace reflection.

CLINICAL GUIDELINES:
1. ACKNOWLEDGE: Reflect the user's self-reported feelings, somatic state, and intensity in 1 gentle sentence.
2. DISTINGUISH OBSERVATION FROM HYPOTHESIS:
   - Clear distinction: "I notice that..." (observation) vs. "I wonder if..." (collaborative hypothesis).
   - Only point out patterns across past check-ins if actual data shows it. Never fabricate or assume.
3. ONE MEANINGFUL QUESTION:
   - Conclude with exactly ONE grounded, open question that invites psychological self-attunement.
4. BOUNDARIES:
   - Never diagnose. Never state absolute causes.
   - Strictly NO emojis anywhere in the response.
5. LANGUAGE:
${languageCode == 'ar' ? '''
- Respond in warm, authentic Tunisian Arabic dialect (لهجة تونسية رزينة، متفهمة، دافية، ومبنية على العلاج النفسي الواعي):
  * استعمل مفردات تونسية سلسة مثل "لاحظت اللي...", "زعمة فما رابط...", "شنوة تحس...".
  * اطرح سؤال واحد يخليه يفكر في روحه برحمة.
''' : (languageCode == 'fr' ? '''
- Respond in warm, articulate, psychologically attuned French.
''' : '''
- Respond in warm, dignified, psychologically informed English.
''')}
''';

    final promptBuffer = StringBuffer();
    promptBuffer.writeln('TODAY\'S CHECK-IN DATA:');
    promptBuffer.writeln('- Overall Mood: ${currentTrace.overallMood}');
    promptBuffer.writeln('- Intensity (1-10): ${currentTrace.moodIntensity}');
    if (currentTrace.energyLevel != null && currentTrace.energyLevel! >= 1 && currentTrace.energyLevel! <= 10) {
      promptBuffer.writeln('- Energy Level (1-10): ${currentTrace.energyLevel}');
    }
    if (currentTrace.anxietyLevel != null) {
      promptBuffer.writeln('- Anxiety Level: ${currentTrace.anxietyLevel}');
    }
    if (currentTrace.selectedEmotions.isNotEmpty) {
      promptBuffer.writeln('- Emotions: ${currentTrace.selectedEmotions.join(', ')}');
    }
    if (currentTrace.sleepHours != null) {
      promptBuffer.writeln('- Sleep Hours: ${currentTrace.sleepHours}');
    }
    if (currentTrace.physicalTension != null) {
      promptBuffer.writeln('- Physical Tension (1-10): ${currentTrace.physicalTension}');
    }
    // Note: Raw journalText is strictly excluded across all AI prompt builders to protect personal diary privacy.

    if (history.isNotEmpty) {
      promptBuffer.writeln('\nPREVIOUS CHECK-INS HISTORY (Past ${history.take(4).length} days):');
      for (final h in history.take(4)) {
        promptBuffer.writeln('• ${h.dateKey}: Mood=${h.overallMood}, Intensity=${h.moodIntensity}${h.energyLevel != null ? ', Energy=${h.energyLevel}' : ''}');
      }
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
    );

    final payload = {
      'system_instruction': {
        'parts': [
          {'text': systemInstruction}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': promptBuffer.toString()}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.6,
        'maxOutputTokens': 200,
      },
    };

    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        await DailyUsageLimiter.recordRequest();
        final Map<String, dynamic> decoded = jsonDecode(body) as Map<String, dynamic>;
        final candidates = decoded['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates.first['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            return parts.first['text'] as String?;
          }
        }
      }
    } catch (_) {
    } finally {
      client?.close();
    }

    return null;
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

