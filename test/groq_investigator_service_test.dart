import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/core/security/daily_usage_limiter.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/data/direct_groq_investigator_service.dart';
import 'package:mind_forensics/features/investigation/data/mock_investigator_service.dart';
import 'package:mind_forensics/features/investigation/domain/ai_companion_system_prompt.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/hypothesis.dart';
import 'package:mind_forensics/features/investigation/presentation/widgets/ai_engine_config_sheet.dart';
import 'package:mind_forensics/features/profile/domain/psychological_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, String> values = {};

  @override
  ContentType? contentType;

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    values[name] = value.toString();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUtf8Response implements HttpClientResponse {
  _FakeUtf8Response({required this.statusCode, required String body})
      : _bytes = utf8.encode(body);

  @override
  final int statusCode;
  final List<int> _bytes;

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) =>
      Stream<List<int>>.fromIterable([_bytes]).transform(streamTransformer);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest({
    required this.headers,
    required this.onComplete,
  });

  @override
  final _FakeHttpHeaders headers;
  final HttpClientResponse Function(String writtenBody) onComplete;
  final StringBuffer _body = StringBuffer();

  @override
  void write(Object? object) {
    _body.write(object);
  }

  @override
  Future<HttpClientResponse> close() async => onComplete(_body.toString());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient({
    required this.statusCode,
    required this.responseBody,
    this.throwSocketError = false,
  });

  final int statusCode;
  final String responseBody;
  final bool throwSocketError;
  final List<_FakeHttpHeaders> capturedHeaders = [];

  @override
  Duration? connectionTimeout;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    if (throwSocketError) {
      throw const SocketException('Simulated offline state');
    }
    final headers = _FakeHttpHeaders();
    capturedHeaders.add(headers);
    return _FakeHttpClientRequest(
      headers: headers,
      onComplete: (_) => _FakeUtf8Response(
        statusCode: statusCode,
        body: responseBody,
      ),
    );
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
    await DailyUsageLimiter.resetForTesting();
  });

  CaseModel buildSampleCase({bool isPrivate = false}) {
    final now = DateTime(2026, 11, 13, 20);
    return CaseModel(
      id: 'case_groq_1',
      caseNumber: 'SESSION 01',
      title: 'Delayed reply',
      createdAt: now,
      updatedAt: now,
      currentStage: CaseStage.incident,
      incidentDescription: 'No reply yet and my chest feels tight.',
      isPrivate: isPrivate,
    );
  }

  PsychologicalProfileModel buildConsentedProfile() => PsychologicalProfileModel(
        shareWithAiCompanion: true,
        allowAiPersonalization: true,
        updatedAt: DateTime(2026, 11, 13, 20),
      );

  group('DirectGroqInvestigatorService & Specialist Prompting', () {
    test('Private case or empty key makes 0 HTTP requests and returns fallback', () async {
      var requests = 0;
      final service = DirectGroqInvestigatorService(
        apiKey: '',
        onRequestAttempted: (_, _) => requests++,
      );

      final reply = await service.getNextQuestion(
        currentCase: buildSampleCase(isPrivate: true),
        conversationHistory: const [],
        profile: buildConsentedProfile(),
      );

      expect(reply.isNotEmpty, isTrue);
      expect(requests, equals(0));
      expect(service.networkRequestsAttempted, equals(0));
    });

    test('Active Groq key sends Bearer header + specialist prompt and parses reply', () async {
      Uri? capturedUri;
      Map<String, dynamic>? capturedPayload;
      final fakeClient = _FakeHttpClient(
        statusCode: 200,
        responseBody: jsonEncode({
          'choices': [
            {
              'message': {
                'content':
                    'Notice how your chest tightened before any facts arrived. What observable detail happened right before that assumption?',
              },
            },
          ],
        }),
      );

      final service = DirectGroqInvestigatorService(
        apiKey: 'gsk_test_123',
        proxyUrl: 'https://proxy.example.com/v1/chat/completions',
        clientFactory: () => fakeClient,
        onRequestAttempted: (url, payload) {
          capturedUri = url;
          capturedPayload = payload;
        },
      );

      final reply = await service.getNextQuestion(
        currentCase: buildSampleCase(),
        conversationHistory: const [],
        profile: buildConsentedProfile(),
        languageCode: 'en',
      );

      expect(
        capturedUri.toString(),
        equals('https://proxy.example.com/v1/chat/completions'),
      );
      expect(
        fakeClient.capturedHeaders.single.values['Authorization'],
        equals('Bearer gsk_test_123'),
      );
      final messages = capturedPayload?['messages'] as List<dynamic>;
      final systemMsg = (messages.first as Map)['content'] as String;
      expect(systemMsg, contains('Psychological Inquiry Specialist'));
      expect(systemMsg, contains('Zero generic AI filler'));
      expect(
        reply,
        contains('Notice how your chest tightened before any facts arrived.'),
      );
    });

    test('Groq parses JSON hypotheses and falls back silently on SocketException', () async {
      final jsonClient = _FakeHttpClient(
        statusCode: 200,
        responseBody: jsonEncode({
          'choices': [
            {
              'message': {
                'content': jsonEncode({
                  'hypotheses': [
                    {
                      'id': 'hyp-1',
                      'title': 'Busy afternoon',
                      'explanation': 'They might simply be away from their phone.',
                      'whyItMightFit': 'Work hours often delay replies.',
                      'whatDoesNotFit': 'No prior sign of conflict.',
                    },
                  ],
                }),
              },
            },
          ],
        }),
      );

      final service = DirectGroqInvestigatorService(
        apiKey: 'gsk_test_json',
        clientFactory: () => jsonClient,
      );

      final hypotheses = await service.generateHypotheses(
        currentCase: buildSampleCase(),
        profile: buildConsentedProfile(),
      );
      expect(hypotheses, hasLength(1));
      expect(hypotheses.first.title, equals('Busy afternoon'));

      final offlineService = DirectGroqInvestigatorService(
        apiKey: 'gsk_test_offline',
        clientFactory: () => _FakeHttpClient(
          statusCode: 500,
          responseBody: '',
          throwSocketError: true,
        ),
      );

      final questions = await offlineService.generateCrossExaminationQuestions(
        currentCase: buildSampleCase(),
        hypothesis: const Hypothesis(
          id: 'hyp-1',
          title: 'Busy afternoon',
          explanation: 'Away from phone',
          whyItMightFit: 'Meetings run late.',
          whatDoesNotFit: 'No prior disagreement.',
        ),
        profile: buildConsentedProfile(),
      );
      expect(questions.length, greaterThanOrEqualTo(1));
    });

    test('investigatorServiceProvider routes to DirectGroqInvestigatorService when Groq key saved', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(investigatorServiceProvider),
        isA<MockInvestigatorService>(),
      );

      await container
          .read(aiConfigProvider.notifier)
          .setApiKey('gsk_live_test_999', provider: AiEngineProvider.groq);

      final config = container.read(aiConfigProvider);
      expect(config.provider, equals(AiEngineProvider.groq));
      expect(config.isLiveActive, isTrue);
      expect(
        container.read(investigatorServiceProvider),
        isA<DirectGroqInvestigatorService>(),
      );
    });

    testWidgets('AiEngineConfigSheet allows switching between Groq and Gemini cleanly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: AiEngineConfigSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Groq (Free Llama)'), findsOneWidget);
      expect(find.text('Google Gemini'), findsOneWidget);

      await tester.tap(find.text('Groq (Free Llama)'));
      await tester.pumpAndSettle();

      expect(find.text('GROQ API KEY (CONSOLE.GROQ.COM)'), findsOneWidget);
      expect(
        AiCompanionSystemPrompt.coreIdentityPrompt,
        contains('Psychological Inquiry Specialist'),
      );
    });
  });
}
