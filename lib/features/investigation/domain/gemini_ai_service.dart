import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../../../core/security/daily_usage_limiter.dart';
import 'ai_case_analysis.dart';
import 'ai_service.dart';
import 'case_model.dart';
import 'warm_investigator_prompt.dart';

/// Live Gemini implementation of [AiService] using the Firebase AI SDK.
///
/// Section 8 & 11:
/// - No API keys live in this code.
/// - System instruction forces "The Warm Investigator" persona.
/// - Requires valid JSON output (`responseMimeType: 'application/json'`).
/// - Catches all network/parsing errors so the app never crashes.
class GeminiAiService implements AiService {
  GeminiAiService({GenerativeModel? model})
    : _model =
          model ??
          FirebaseAI.vertexAI().generativeModel(
            model: 'gemini-1.5-flash',
            systemInstruction: Content.system(
              WarmInvestigatorPrompt.systemInstruction,
            ),
            generationConfig: GenerationConfig(
              responseMimeType: 'application/json',
              temperature: 0.7,
            ),
          );

  final GenerativeModel _model;

  @override
  Future<AiCaseAnalysis> analyzeCase(
    CaseModel currentCase, {
    bool allowPastHistory = true,
  }) async {
    // Check daily rate limit to protect costs and prevent rumination
    final canProceed = await DailyUsageLimiter.canMakeRequest();
    if (!canProceed) {
      return const AiCaseAnalysis(
        message: DailyUsageLimiter.limitExceededMessage,
        safetyLevel: 0,
      );
    }
    await DailyUsageLimiter.recordRequest();

    try {
      final promptText = WarmInvestigatorPrompt.buildCaseAnalysisPrompt(
        incidentDescription: currentCase.incidentDescription,
        trigger: currentCase.chain?.trigger ?? '',
        thought: currentCase.chain?.thought ?? '',
        emotion: currentCase.chain?.emotion ?? '',
        emotionIntensity: currentCase.chain?.emotionIntensity ?? 5,
        behavior: currentCase.chain?.behavior ?? '',
        allowPastHistory: allowPastHistory,
      );

      final response = await _model.generateContent([Content.text(promptText)]);

      final rawText = response.text;
      if (rawText == null || rawText.trim().isEmpty) {
        return AiCaseAnalysis.fallback;
      }

      // Clean any accidental markdown wrappers
      var cleaned = rawText.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      }
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }

      final Map<String, dynamic> decoded =
          jsonDecode(cleaned.trim()) as Map<String, dynamic>;
      return AiCaseAnalysis.fromJson(decoded);
    } catch (_) {
      // In production: log error securely without user text.
      // Always return a graceful, calming fallback response.
      return const AiCaseAnalysis(
        message: 'I am here with you. Let’s focus on the observable facts of what happened while our connection stabilizes.',
        safetyLevel: 0,
      );
    }
  }

  @override
  Future<AiCaseAnalysis> askFollowUp(
    CaseModel currentCase,
    String userReply,
  ) async {
    try {
      final followUpPrompt =
          '''
CASE CONTEXT:
• Incident: ${currentCase.incidentDescription}
• User’s response to follow-up: "$userReply"

Please provide the next brief Warm Investigator question in strict JSON format.
''';

      final response = await _model.generateContent([
        Content.text(followUpPrompt),
      ]);

      final rawText = response.text;
      if (rawText == null || rawText.trim().isEmpty) {
        return AiCaseAnalysis.fallback;
      }

      var cleaned = rawText.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      }
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }

      final Map<String, dynamic> decoded =
          jsonDecode(cleaned.trim()) as Map<String, dynamic>;
      return AiCaseAnalysis.fromJson(decoded);
    } catch (_) {
      return const AiCaseAnalysis(
        message: 'Notice that thought. Is there another possible explanation you might offer a close friend in this scenario?',
        safetyLevel: 0,
      );
    }
  }

  @override
  Future<String> summarizeCase(CaseModel currentCase) async {
    try {
      final summaryPrompt =
          '''
Summarize the findings for this investigation:
• Incident: ${currentCase.incidentDescription}
• Observable Chain: Trigger: ${currentCase.chain?.trigger}, Thought: ${currentCase.chain?.thought}, Emotion: ${currentCase.chain?.emotion}
• Conclusion: ${currentCase.userConclusion ?? 'In progress'}

Provide a 3-4 bullet summary sorting facts from assumptions.
''';

      final response = await _model.generateContent([
        Content.text(summaryPrompt),
      ]);

      return response.text ??
          'Cognitive deconstruction complete. You have examined the neural evidence and hold sovereignty over your reframe.';
    } catch (_) {
      return 'Cognitive synthesis complete based on the observable data and somatic sensations recorded in your session.';
    }
  }
}
