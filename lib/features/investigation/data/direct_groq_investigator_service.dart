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
import 'direct_gemini_investigator_service.dart';
import 'mock_investigator_service.dart';

/// Direct Groq / OpenAI-compatible implementation of [InvestigatorService].
///
/// Designed for zero-cost free-tier text reasoning via GroqCloud (`api.groq.com`)
/// or an optional user-hosted proxy URL (`proxyUrl`), with:
/// - Specialist Mind Forensics prompting (non-diagnostic, options-first, 0 emojis)
/// - Strict privacy gates ([DirectGeminiInvestigatorService.canTransmitCaseData])
/// - 20 queries/day limiter ([DailyUsageLimiter])
/// - Automatic silent fallback to [MockInvestigatorService] when offline/limited
class DirectGroqInvestigatorService implements InvestigatorService {
  DirectGroqInvestigatorService({
    required this.apiKey,
    this.modelName = defaultModel,
    this.proxyUrl = '',
    this.clientFactory,
    this.onRequestAttempted,
  });

  static const String defaultModel = 'llama-3.3-70b-versatile';
  static const String defaultEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  static const List<String> fallbackModels = [
    'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant',
    'qwen/qwen3-32b',
  ];

  final String apiKey;
  final String modelName;
  final String proxyUrl;
  final HttpClient Function()? clientFactory;
  final void Function(Uri url, Map<String, dynamic> payload)? onRequestAttempted;
  final MockInvestigatorService _fallback = MockInvestigatorService();

  /// Counter tracking external network requests attempted.
  int networkRequestsAttempted = 0;

  bool get _hasProxy => proxyUrl.trim().isNotEmpty;

  static bool isMockKey(String key) => DirectGeminiInvestigatorService.isMockKey(key);

  Uri get _resolvedEndpoint {
    final trimmed = proxyUrl.trim();
    if (trimmed.isNotEmpty) {
      return Uri.parse(trimmed);
    }
    return Uri.parse(defaultEndpoint);
  }

  /// Tests connectivity with the Groq API or configured proxy endpoint.
  Future<({bool success, String message})> testConnection() async {
    final cleanKey = apiKey.trim();
    if (!_hasProxy && (cleanKey.isEmpty || isMockKey(cleanKey))) {
      return (
        success: false,
        message: cleanKey.isEmpty
            ? 'API key cannot be empty'
            : 'Mock mode active (zero network calls)',
      );
    }

    final modelsToTry = [
      modelName,
      ...fallbackModels.where((m) => m != modelName),
    ];

    String lastError = 'No Groq models available';

    for (final currentModel in modelsToTry) {
      HttpClient? client;
      try {
        final url = _resolvedEndpoint;
        final payload = <String, dynamic>{
          'model': currentModel,
          'messages': [
            {'role': 'user', 'content': 'Ping'},
          ],
          'max_tokens': 8,
          'temperature': 0.2,
        };

        networkRequestsAttempted++;
        onRequestAttempted?.call(url, payload);

        client = clientFactory != null
            ? clientFactory!()
            : (HttpClient()..connectionTimeout = const Duration(seconds: 6));
        final request = await client.postUrl(url);
        request.headers.contentType = ContentType.json;
        if (cleanKey.isNotEmpty && !isMockKey(cleanKey)) {
          request.headers.set('Authorization', 'Bearer $cleanKey');
        }
        request.write(jsonEncode(payload));

        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          return (
            success: true,
            message: 'Connected to Groq ($currentModel) successfully',
          );
        }
        lastError = 'Status ${response.statusCode}: $body';
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

  Future<String?> _callChatCompletions({
    required List<Map<String, String>> messages,
    bool isJsonObject = false,
  }) async {
    final cleanKey = apiKey.trim();
    if (!_hasProxy && isMockKey(cleanKey)) return null;

    final canProceed = await DailyUsageLimiter.canMakeRequest();
    if (!canProceed) return DailyUsageLimiter.limitExceededMessage;

    final modelsToTry = [
      modelName,
      ...fallbackModels.where((m) => m != modelName),
    ];

    for (final currentModel in modelsToTry) {
      final url = _resolvedEndpoint;
      final payload = <String, dynamic>{
        'model': currentModel,
        'messages': messages,
        'temperature': 0.65,
        if (isJsonObject) 'response_format': {'type': 'json_object'},
      };

      HttpClient? client;
      try {
        networkRequestsAttempted++;
        onRequestAttempted?.call(url, payload);

        client = clientFactory != null
            ? clientFactory!()
            : (HttpClient()..connectionTimeout = const Duration(seconds: 6));
        final request = await client.postUrl(url);
        request.headers.contentType = ContentType.json;
        if (cleanKey.isNotEmpty && !isMockKey(cleanKey)) {
          request.headers.set('Authorization', 'Bearer $cleanKey');
        }
        request.write(jsonEncode(payload));

        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          await DailyUsageLimiter.recordRequest();
          final decoded = jsonDecode(body) as Map<String, dynamic>;
          final choices = decoded['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final first = choices.first as Map<String, dynamic>?;
            final message = first?['message'] as Map<String, dynamic>?;
            final content = message?['content'] as String?;
            if (content != null && content.trim().isNotEmpty) {
              return content.trim();
            }
          }
        }
      } on SocketException {
        break;
      } on HandshakeException {
        break;
      } catch (_) {
        // Try fallback model on transient error
      } finally {
        client?.close();
      }
    }

    return null;
  }

  static String _stripCodeFences(String raw) {
    var cleaned = raw.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
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
    if (!DirectGeminiInvestigatorService.canTransmitCaseData(
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
    final incident = currentCase.incidentDescription.trim();

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

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemInstruction},
    ];

    for (final s in conversationHistory) {
      final text = s.text.trim();
      if (text.isEmpty) continue;
      final role = s.speaker == StatementSpeaker.user ? 'user' : 'assistant';
      if (messages.length > 1 && messages.last['role'] == role) {
        messages.last['content'] = '${messages.last['content']}\n$text';
      } else {
        messages.add({'role': role, 'content': text});
      }
    }

    if (messages.length == 1) {
      messages.add({
        'role': 'user',
        'content': incident.isNotEmpty
            ? incident
            : 'I am noticing heavy thoughts right now and want to unpack them calmly.',
      });
    } else if (messages.last['role'] != 'user') {
      messages.add({
        'role': 'user',
        'content': 'What stands out most here, and what single thread should we examine next?',
      });
    }

    final result = await _callChatCompletions(messages: messages);
    if (result != null && result.isNotEmpty) {
      if (ConversationalPacingEnforcer.hasSafetyExemption(result)) {
        return result;
      }

      final mode = conversationMode ?? ConversationMode.exploreThought;
      final validation = ConversationalPacingEnforcer.validateResponse(result, mode);
      if (validation.isValid) {
        return result;
      }

      final targetMax = ConversationalPacingEnforcer.targetMaxSentences(mode);
      if (validation.sentenceCount > targetMax + 2) {
        final conciseMessages = <Map<String, String>>[
          {
            'role': 'system',
            'content':
                '$systemInstruction\nIMPORTANT: Keep your reply concise ($targetMax sentences max).',
          },
          ...messages.skip(1),
        ];
        final retryResult = await _callChatCompletions(messages: conciseMessages);
        if (retryResult != null && retryResult.isNotEmpty) {
          return retryResult;
        }
      }

      return result;
    }

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
    if (!DirectGeminiInvestigatorService.canTransmitCaseData(
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

Output strictly a JSON object formatted as:
{
  "hypotheses": [
    {
      "id": "hyp-1",
      "title": "Short Hypothesis Title",
      "explanation": "Gentle, possibility-framed cognitive reframe.",
      "whyItMightFit": "Specific observation supporting this alternative.",
      "whatDoesNotFit": "Counter-evidence or facts that cast doubt on worst-case assumption."
    }
  ]
}
Provide exactly 3 distinct alternative hypotheses inside "hypotheses".
''';

    final rawJson = await _callChatCompletions(
      messages: [
        {'role': 'system', 'content': WarmInvestigatorPrompt.systemInstruction},
        {'role': 'user', 'content': prompt},
      ],
      isJsonObject: true,
    );

    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(_stripCodeFences(rawJson));
        List<dynamic> items = const [];
        if (decoded is List) {
          items = decoded;
        } else if (decoded is Map<String, dynamic> &&
            decoded['hypotheses'] is List) {
          items = decoded['hypotheses'] as List<dynamic>;
        }
        if (items.isNotEmpty) {
          return items
              .whereType<Map<String, dynamic>>()
              .map(Hypothesis.fromJson)
              .toList();
        }
      } catch (_) {}
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
    if (!DirectGeminiInvestigatorService.canTransmitCaseData(
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
Output strictly as JSON object: {"questions": ["question 1", "question 2", "question 3"]}
''';

    final rawJson = await _callChatCompletions(
      messages: [
        {'role': 'system', 'content': WarmInvestigatorPrompt.systemInstruction},
        {'role': 'user', 'content': prompt},
      ],
      isJsonObject: true,
    );

    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(_stripCodeFences(rawJson));
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
        if (decoded is Map<String, dynamic> && decoded['questions'] is List) {
          return (decoded['questions'] as List<dynamic>)
              .map((e) => e.toString())
              .toList();
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
    if (!DirectGeminiInvestigatorService.canTransmitCaseData(
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

    final result = await _callChatCompletions(
      messages: [
        {'role': 'system', 'content': WarmInvestigatorPrompt.systemInstruction},
        {'role': 'user', 'content': prompt},
      ],
    );

    if (result != null && result.isNotEmpty) {
      return result;
    }

    return _fallback.summarizeFindings(
      currentCase: currentCase,
      languageCode: languageCode,
      profile: profile,
    );
  }
}

