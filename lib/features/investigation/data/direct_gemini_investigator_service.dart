import 'dart:convert';
import 'dart:io';

import '../../../core/security/daily_usage_limiter.dart';
import '../../journey/domain/journey_state_model.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../profile/domain/condition_type.dart';
import '../../profile/domain/psychological_profile_model.dart';
import '../domain/ai_companion_context_selector.dart';
import '../domain/ai_companion_system_prompt.dart';
import '../domain/case_model.dart';
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
    this.modelName = 'gemini-3.1-flash-lite',
  });

  final String apiKey;
  final String modelName;
  final MockInvestigatorService _fallback = MockInvestigatorService();

  static const List<String> fallbackModels = [
    'gemini-3.1-flash-lite',
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  /// Tests the validity of the provided API key with a minimal query.
  Future<({bool success, String message})> testConnection() async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      return (success: false, message: 'API key cannot be empty');
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
          'https://generativelanguage.googleapis.com/v1beta/models/$currentModel:generateContent?key=$cleanKey',
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

        client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
        final request = await client.postUrl(url);
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(payload));

        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          return (
            success: true,
            message: 'Connected to Gemini ($currentModel) successfully'
          );
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
    if (cleanKey.isEmpty) return null;

    final canProceed = await DailyUsageLimiter.canMakeRequest();
    if (!canProceed) return DailyUsageLimiter.limitExceededMessage;

    final modelsToTry = [
      modelName,
      ...fallbackModels.where((m) => m != modelName),
    ];

    for (final currentModel in modelsToTry) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$currentModel:generateContent?key=$cleanKey',
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
        client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
        final request = await client.postUrl(url);
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(payload));

        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
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
        }
      } on SocketException {
        // Network unavailable, break immediately without waiting on remaining models
        break;
      } on HandshakeException {
        // Security handshake failure, break immediately
        break;
      } catch (_) {
        // Model-specific error (404/429), try next fallback model
      } finally {
        client?.close();
      }
    }

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
  }) async {
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
      journey: journey,
    );

    final conditions = profile?.shareWithAiCompanion == true
        ? profile?.conditions.map((c) => c.condition).toList() ?? <ConditionType>[]
        : <ConditionType>[];

    final systemInstruction = AiCompanionSystemPrompt.buildFullPrompt(
      mode: conversationMode ?? ConversationMode.exploreThought,
      languageCode: lang,
      conditions: conditions,
      contextualUserPrompt: contextualPrompt,
    );

    final result = await _callGeminiContents(
      contents: contents,
      systemInstruction: systemInstruction,
    );

    if (result != null && result.trim().isNotEmpty) {
      return result.trim();
    }

    return _fallback.getNextQuestion(
      currentCase: currentCase,
      conversationHistory: conversationHistory,
      includePastCaseSummaries: includePastCaseSummaries,
      languageCode: languageCode,
      profile: profile,
      journey: journey,
      conversationMode: conversationMode,
    );
  }

  @override
  Future<List<Hypothesis>> generateHypotheses({
    required CaseModel currentCase,
    String? languageCode,
  }) async {
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
    );
  }

  @override
  Future<List<String>> generateCrossExaminationQuestions({
    required CaseModel currentCase,
    required Hypothesis hypothesis,
    String? languageCode,
  }) async {
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
    );
  }

  @override
  Future<String> summarizeFindings({
    required CaseModel currentCase,
    String? languageCode,
  }) async {
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
    );
  }
}
