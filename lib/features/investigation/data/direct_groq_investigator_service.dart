import 'dart:convert';
import 'dart:io';

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

  /// Status of the most recent AI operation: false for local deterministic fallback.
  bool? lastCallWasLive;

  bool get _hasProxy => proxyUrl.trim().isNotEmpty;

  static bool isMockKey(String key) => DirectGeminiInvestigatorService.isMockKey(key);


  static const bool kIsNetworkPermanentlyDisabled = true;

  /// Tests connectivity with the Groq API or configured proxy endpoint.
  ///
  /// Permanently disabled in Stage 6.1A.3: Mind Forensics will use xAI Grok
  /// as its sole external AI provider in a future stage. Groq network
  /// transmission is isolated with zero network requests.
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
    return (
      success: false,
      message:
          'External AI is currently unavailable. Groq is not supported; local reflection and support engine is active.',
    );
  }

  Future<String?> _callChatCompletions({
    required List<Map<String, String>> messages,
    bool isJsonObject = false,
  }) async {
    // In Stage 6.1A.3: Groq network transmission is permanently disabled.
    // Mind Forensics uses local deterministic AI behavior until the separate Grok implementation stage.
    // Outbound HTTP requests, socket connections, and external API key transmissions are strictly blocked.
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
      lastCallWasLive = false;
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

    lastCallWasLive = false;
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

