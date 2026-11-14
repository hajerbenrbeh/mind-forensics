import 'dart:convert';
import 'dart:io';

import '../../../core/security/daily_usage_limiter.dart';
import '../../journal/domain/journal_memory_model.dart';
import '../../journey/domain/journey_state_model.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../profile/domain/condition_type.dart';
import '../../profile/domain/psychological_profile_model.dart';
import '../domain/ai_companion_context_selector.dart';
import '../domain/ai_companion_system_prompt.dart';
import '../domain/case_model.dart';
import '../domain/conversational_pacing_enforcer.dart';
import '../domain/conversation_mode.dart';
import '../domain/hypothesis.dart';
import '../domain/investigator_service.dart';
import '../domain/statement.dart';
import '../domain/warm_investigator_prompt.dart';
import 'mock_investigator_service.dart';

/// Direct Google Gemini API implementation of [InvestigatorService].
///
/// Enables users to connect their free Google AI Studio developer API key directly
/// without requiring cloud consoles or Firebase setup.
///
/// Strictly enforces:
/// - "The Warm Investigator" persona (warm, curious, question-first, hypotheses-only).
/// - 20 queries/day rate limit to protect cognitive boundaries and API quotas.
/// - Full trilingual support (authentic Tunisian Arabic, French, English).
/// - Automatic, silent fallback to [MockInvestigatorService] on network failure or rate limits.
class DirectGeminiInvestigatorService implements InvestigatorService {
  DirectGeminiInvestigatorService({
    required this.apiKey,
    this.modelName = 'gemini-3.5-flash',
    this.clientFactory,
    this.onRequestAttempted,
  });

  final String apiKey;
  final String modelName;
  final HttpClient Function()? clientFactory;
  final void Function(Uri url, Map<String, dynamic> payload)? onRequestAttempted;
  final MockInvestigatorService _fallback = MockInvestigatorService();

  /// Counter tracking external network requests attempted.
  int networkRequestsAttempted = 0;

  /// Status of the most recent AI operation: true if live Gemini responded, false if local fallback was used.
  bool? lastCallWasLive;

  /// Model name that successfully handled the last live call.
  String? lastModelUsed;

  /// Error message from the last live Gemini attempt, if any.
  String? lastErrorMessage;

  /// Centralized Privacy & Consent Gate for AI operations.
  ///
  /// Enforces:
  /// 1. Private case isolation: If [currentCase.isPrivate == true], external AI calls are strictly forbidden.
  /// 2. Dual-consent requirement: If [checkProfileConsent == true], [profile] must be non-null and
  ///    both [shareWithAiCompanion] and [allowAiPersonalization] must be true.
  static bool canTransmitCaseData({
    required CaseModel currentCase,
    PsychologicalProfileModel? profile,
    bool checkProfileConsent = true,
  }) {
    if (currentCase.isPrivate) {
      return false;
    }
    if (checkProfileConsent) {
      if (profile == null) return false;
      if (!profile.shareWithAiCompanion || !profile.allowAiPersonalization) {
        return false;
      }
    }
    return true;
  }

  static const String kDevMockKey = 'DEV_MOCK_GEMINI_KEY';

  /// Returns true if [key] is empty or corresponds to the offline development mock key.
  static bool isMockKey(String key) =>
      key.trim().isEmpty || key.trim() == kDevMockKey;

  static const List<String> fallbackModels = [
    'gemini-3.5-flash',
    'gemini-3.8-flash',
    'gemini-3.1-flash-lite',
    'gemini-flash-latest',
  ];

  /// Tests the validity of the provided API key with a minimal query.
  Future<({bool success, String message})> testConnection() async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      return (success: false, message: 'API key cannot be empty');
    }
    if (cleanKey == kDevMockKey) {
      return (
        success: false,
        message: 'Mock API key configured (zero network mode)',
      );
    }

    final modelsToTry = [
      modelName,
      ...fallbackModels.where((m) => m != modelName),
    ];

    String lastError = 'No models available';

    for (final currentModel in modelsToTry) {
      HttpClient? client;
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$currentModel:generateContent',
        );
        final payload = {
          'contents': [
            {
              'parts': [
                {'text': 'Ping'}
              ]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': 5,
          },
        };

        networkRequestsAttempted++;
        onRequestAttempted?.call(url, payload);

        client = clientFactory != null
            ? clientFactory!()
            : (HttpClient()..connectionTimeout = const Duration(seconds: 4));
        final request = await client.postUrl(url);
        request.headers.contentType = ContentType.json;
        request.headers.set('x-goog-api-key', cleanKey);
        request.write(jsonEncode(payload));

        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          lastModelUsed = currentModel;
          return (
            success: true,
            message: 'Connected to Gemini ($currentModel) successfully'
          );
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          return (
            success: false,
            message: 'Authentication failed (HTTP ${response.statusCode}): Invalid or unauthorized API key'
          );
        } else if (response.statusCode == 400) {
          return (
            success: false,
            message: 'Invalid request (HTTP 400): $body'
          );
        } else if (response.statusCode == 429 || response.statusCode == 503) {
          lastError = 'HTTP ${response.statusCode} on $currentModel';
          continue;
        } else {
          lastError = 'Status ${response.statusCode}: $body';
        }
      } on SocketException catch (e) {
        lastError = 'Network unavailable: ${e.message}';
        break;
      } on HandshakeException catch (e) {
        lastError = 'Handshake failed: ${e.message}';
        break;
      } catch (e) {
        lastError = 'Connection failed: $e';
      } finally {
        client?.close();
      }
    }

    return (success: false, message: lastError);
  }

  Future<String?> _callGemini({
    required String prompt,
    required String systemInstruction,
    bool isJson = false,
  }) async {
    return _callGeminiContents(
      contents: [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ],
        }
      ],
      systemInstruction: systemInstruction,
      isJson: isJson,
    );
  }

  Future<String?> _callGeminiContents({
    required List<Map<String, dynamic>> contents,
    required String systemInstruction,
    bool isJson = false,
  }) async {
    final cleanKey = apiKey.trim();
    if (isMockKey(cleanKey)) return null;

    final canProceed = await DailyUsageLimiter.canMakeRequest();
    if (!canProceed) return DailyUsageLimiter.limitExceededMessage;

    final modelsToTry = [
      modelName,
      ...fallbackModels.where((m) => m != modelName),
    ];

    for (final currentModel in modelsToTry) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$currentModel:generateContent',
      );

      final payload = {
        'system_instruction': {
          'parts': [
            {'text': systemInstruction}
          ]
        },
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          if (isJson) 'response_mime_type': 'application/json',
        },
      };

      HttpClient? client;
      try {
        networkRequestsAttempted++;
        onRequestAttempted?.call(url, payload);

        client = clientFactory != null
            ? clientFactory!()
            : (HttpClient()..connectionTimeout = const Duration(seconds: 4));
        final request = await client.postUrl(url);
        request.headers.contentType = ContentType.json;
        request.headers.set('x-goog-api-key', cleanKey);
        request.write(jsonEncode(payload));

        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          lastCallWasLive = true;
          lastModelUsed = currentModel;
          lastErrorMessage = null;
          await DailyUsageLimiter.recordRequest();
          final Map<String, dynamic> decoded =
              jsonDecode(body) as Map<String, dynamic>;
          final candidates = decoded['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final content =
                candidates.first['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              return parts.first['text'] as String?;
            }
          }
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          lastErrorMessage = 'Authentication failed (HTTP ${response.statusCode})';
          break; // Stop retrying on invalid key
        } else if (response.statusCode == 400) {
          lastErrorMessage = 'Invalid request (HTTP 400): $body';
          break; // Do not retry identical bad request
        } else if (response.statusCode == 429 || response.statusCode == 503) {
          lastErrorMessage = 'HTTP ${response.statusCode} on $currentModel';
          continue; // Try next fallback model
        } else {
          lastErrorMessage = 'Status ${response.statusCode}: $body';
        }
      } on SocketException catch (e) {
        lastErrorMessage = 'Network unavailable: ${e.message}';
        break;
      } on HandshakeException catch (e) {
        lastErrorMessage = 'Handshake failed: ${e.message}';
        break;
      } catch (e) {
        lastErrorMessage = 'Error on $currentModel: $e';
      } finally {
        client?.close();
      }
    }

    lastCallWasLive = false;
    return null;
  }

  @override
  Future<String> getNextQuestion({
    required CaseModel currentCase,
    required List<Statement> conversationHistory,
    bool includePastCaseSummaries = true,
    String? languageCode,
    PsychologicalProfileModel? profile,
    JourneyStateModel? journey,
    ConversationMode? conversationMode,
    MindTraceModel? latestTrace,
    List<MindTraceModel>? historicalTraces,
    List<JournalMemoryModel>? compressedMemories,
    String? sessionSummary,
  }) async {
    // Privacy and cloud-consent gate:
    // If case is private OR cloud consent is missing/revoked, route strictly to local fallback.
    if (!canTransmitCaseData(
      currentCase: currentCase,
      profile: profile,
      checkProfileConsent: true,
    )) {
      return _fallback.getNextQuestion(
        currentCase: currentCase,
        conversationHistory: conversationHistory,
        includePastCaseSummaries: includePastCaseSummaries,
        languageCode: languageCode,
        profile: profile,
        journey: journey,
        conversationMode: conversationMode,
        latestTrace: latestTrace,
        historicalTraces: historicalTraces,
        compressedMemories: compressedMemories,
        sessionSummary: sessionSummary,
      );
    }

    final lang = languageCode ?? 'en';

    // Format full multi-turn conversational dialogue for Gemini
    final contents = <Map<String, dynamic>>[];
    final incident = currentCase.incidentDescription.trim();

    // Iterate through conversation history
    for (final s in conversationHistory) {
      final text = s.text.trim();
      if (text.isEmpty) continue;
      final role = s.speaker == StatementSpeaker.user ? 'user' : 'model';

      if (contents.isNotEmpty && contents.last['role'] == role) {
        final parts = contents.last['parts'] as List<dynamic>;
        parts.add({'text': text});
      } else {
        // Gemini strictly requires the first content turn to have role 'user'
        if (contents.isEmpty && role == 'model') {
          contents.add({
            'role': 'user',
            'parts': [
              {
                'text': incident.isNotEmpty
                    ? 'Initial situation: $incident'
                    : 'Hello. I need help deconstructing my thoughts.'
              }
            ],
          });
        }
        contents.add({
          'role': role,
          'parts': [
            {'text': text}
          ],
        });
      }
    }

    // If contents is empty, populate initial turn with case context
    if (contents.isEmpty) {
      contents.add({
        'role': 'user',
        'parts': [
          {
            'text': incident.isNotEmpty
                ? incident
                : 'I am experiencing distressing thoughts right now.'
          }
        ],
      });
    }

    // Ensure the last turn is from user so Gemini generates model reply
    if (contents.last['role'] != 'user') {
      contents.add({
        'role': 'user',
        'parts': [
          {'text': 'What do you notice about that, and what should we explore next?'}
        ],
      });
    }

    final contextualPrompt = AiCompanionContextSelector.buildContext(
      profile: profile,
      latestTrace: latestTrace,
      historicalTraces: historicalTraces,
      journey: journey,
      compressedMemories: compressedMemories,
    );

    final hasConsent = profile != null &&
        profile.shareWithAiCompanion &&
        profile.allowAiPersonalization;

    final conditions = hasConsent
        ? profile.conditions.map((c) => c.condition).toList()
        : <ConditionType>[];

    final activeSummary = sessionSummary ?? currentCase.sessionSummary;

    final systemInstruction = AiCompanionSystemPrompt.buildFullPrompt(
      mode: conversationMode ?? ConversationMode.exploreThought,
      languageCode: lang,
      conditions: conditions,
      contextualUserPrompt: contextualPrompt,
      sessionSummary: activeSummary,
    );

    final result = await _callGeminiContents(
      contents: contents,
      systemInstruction: systemInstruction,
    );

    if (result != null && result.trim().isNotEmpty) {
      final text = result.trim();
      // Safety exemption check: crisis hotlines, distress phrases, and grounding cues are 100% immune
      if (ConversationalPacingEnforcer.hasSafetyExemption(text)) {
        return text;
      }

      // Check pacing: if within tolerance margin, return complete response without altering
      final mode = conversationMode ?? ConversationMode.exploreThought;
      final validation = ConversationalPacingEnforcer.validateResponse(text, mode);
      if (validation.isValid) {
        return text;
      }

      // If response is excessively long (> +2 sentences above target) and has no safety content,
      // attempt one controlled retry with an explicit brevity prompt.
      final targetMax = ConversationalPacingEnforcer.targetMaxSentences(mode);
      if (validation.sentenceCount > targetMax + 2) {
        final concisePrompt = '$systemInstruction\nIMPORTANT: Keep your response strictly concise ($targetMax sentences max).';
        final retryResult = await _callGeminiContents(
          contents: contents,
          systemInstruction: concisePrompt,
        );
        if (retryResult != null && retryResult.trim().isNotEmpty) {
          return retryResult.trim();
        }
      }

      // Non-destructive preservation: Return original complete response rather than discarding it
      return text;
    }

    lastCallWasLive = false;
    lastErrorMessage = 'Gemini connection unavailable; offline clinical simulator used.';

    return _fallback.getNextQuestion(
      currentCase: currentCase,
      conversationHistory: conversationHistory,
      includePastCaseSummaries: includePastCaseSummaries,
      languageCode: languageCode,
      profile: profile,
      journey: journey,
      conversationMode: conversationMode,
      latestTrace: latestTrace,
      historicalTraces: historicalTraces,
      compressedMemories: compressedMemories,
      sessionSummary: sessionSummary,
    );
  }

  @override
  Future<List<Hypothesis>> generateHypotheses({
    required CaseModel currentCase,
    String? languageCode,
    PsychologicalProfileModel? profile,
  }) async {
    if (!canTransmitCaseData(
      currentCase: currentCase,
      profile: profile,
      checkProfileConsent: true,
    )) {
      return _fallback.generateHypotheses(
        currentCase: currentCase,
        languageCode: languageCode,
        profile: profile,
      );
    }

    final lang = languageCode ?? 'en';
    final chain = currentCase.chain;

    final prompt = '''
Examine this cognitive case file:
• Activating Incident: ${currentCase.incidentDescription}
• Observable Trigger: ${chain?.trigger ?? 'Not provided'}
• Automatic Thought: ${chain?.thought ?? currentCase.incidentDescription}
• Emotion & Intensity: ${chain?.emotion ?? 'Distress'} (${chain?.emotionIntensity ?? 6}/10)
• Behavioral Impulse: ${chain?.behavior ?? 'Avoidance / Tension'}

Language constraint: Formulate all titles and explanations in ${lang == 'ar' ? 'Tunisian Arabic dialect (بالدارجة التونسية الرزينة والمعبرة)' : (lang == 'fr' ? 'French' : 'English')}.

Output strictly a JSON list containing 3 distinct alternative hypotheses formatted exactly as:
[
  {
    "id": "hyp-1",
    "title": "Short Hypothesis Title",
    "explanation": "Gentle, possibility-framed cognitive reframe.",
    "whyItMightFit": "Specific observation supporting this alternative.",
    "whatDoesNotFit": "Counter-evidence or facts that cast doubt on worst-case assumption."
  },
  ...
]
''';

    final rawJson = await _callGemini(
      prompt: prompt,
      systemInstruction: WarmInvestigatorPrompt.systemInstruction,
      isJson: true,
    );

    if (rawJson != null && rawJson.trim().isNotEmpty) {
      try {
        var cleaned = rawJson.trim();
        if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
        if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
        if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);

        final dynamic decoded = jsonDecode(cleaned.trim());
        List<dynamic> items = [];
        if (decoded is List) {
          items = decoded;
        } else if (decoded is Map<String, dynamic> && decoded['hypotheses'] is List) {
          items = decoded['hypotheses'] as List<dynamic>;
        }

        if (items.isNotEmpty) {
          return items
              .whereType<Map<String, dynamic>>()
              .map((item) => Hypothesis.fromJson(item))
              .toList();
        }
      } catch (_) {
        // Fall back gracefully
      }
    }

    return _fallback.generateHypotheses(
      currentCase: currentCase,
      languageCode: languageCode,
      profile: profile,
    );
  }

  @override
  Future<List<String>> generateCrossExaminationQuestions({
    required CaseModel currentCase,
    required Hypothesis hypothesis,
    String? languageCode,
    PsychologicalProfileModel? profile,
  }) async {
    if (!canTransmitCaseData(
      currentCase: currentCase,
      profile: profile,
      checkProfileConsent: true,
    )) {
      return _fallback.generateCrossExaminationQuestions(
        currentCase: currentCase,
        hypothesis: hypothesis,
        languageCode: languageCode,
        profile: profile,
      );
    }

    final lang = languageCode ?? 'en';
    final prompt = '''
Target Hypothesis: "${hypothesis.title} — ${hypothesis.explanation}"
Original Incident: "${currentCase.incidentDescription}"

Language: ${lang == 'ar' ? 'Tunisian Arabic dialect' : (lang == 'fr' ? 'French' : 'English')}.
Provide 3 concise Socratic cross-examination questions to test the reality and probability of this hypothesis.
Output as a raw JSON list of strings: ["question 1", "question 2", "question 3"]
''';

    final rawJson = await _callGemini(
      prompt: prompt,
      systemInstruction: WarmInvestigatorPrompt.systemInstruction,
      isJson: true,
    );

    if (rawJson != null && rawJson.trim().isNotEmpty) {
      try {
        var cleaned = rawJson.trim();
        if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
        if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
        if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);

        final decoded = jsonDecode(cleaned.trim());
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return _fallback.generateCrossExaminationQuestions(
      currentCase: currentCase,
      hypothesis: hypothesis,
      languageCode: languageCode,
      profile: profile,
    );
  }

  @override
  Future<String> summarizeFindings({
    required CaseModel currentCase,
    String? languageCode,
    PsychologicalProfileModel? profile,
  }) async {
    if (!canTransmitCaseData(
      currentCase: currentCase,
      profile: profile,
      checkProfileConsent: true,
    )) {
      return _fallback.summarizeFindings(
        currentCase: currentCase,
        languageCode: languageCode,
        profile: profile,
      );
    }

    final lang = languageCode ?? 'en';
    final prompt = '''
Synthesize findings for:
• Incident: ${currentCase.incidentDescription}
• Chain: Trigger: ${currentCase.chain?.trigger}, Thought: ${currentCase.chain?.thought}, Behavior: ${currentCase.chain?.behavior}
• User Reframe Anchor: ${currentCase.userConclusion ?? 'Grounded'}

Language: ${lang == 'ar' ? 'Tunisian Arabic dialect' : (lang == 'fr' ? 'French' : 'English')}.
Write a 3-bullet structured cognitive summary separating observable facts from assumptions. Under 80 words.
''';

    final result = await _callGemini(
      prompt: prompt,
      systemInstruction: WarmInvestigatorPrompt.systemInstruction,
    );

    if (result != null && result.trim().isNotEmpty) {
      return result.trim();
    }

    return _fallback.summarizeFindings(
      currentCase: currentCase,
      languageCode: languageCode,
      profile: profile,
    );
  }
}
