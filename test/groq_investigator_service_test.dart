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
  });

  final int statusCode;
  final String responseBody;
  final List<_FakeHttpHeaders> capturedHeaders = [];

  @override
  Duration? connectionTimeout;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
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

    test('Groq network transmission is permanently disabled: fake client never invoked and returns local fallback', () async {
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

      // Stage 6.1A.3: Prove fake client is NEVER invoked even with active key and consented profile
      expect(capturedUri, isNull);
      expect(capturedPayload, isNull);
      expect(fakeClient.capturedHeaders, isEmpty);
      expect(service.networkRequestsAttempted, equals(0));
      // Local fallback produces grounded clinical inquiry
      expect(reply.isNotEmpty, isTrue);
    });

    test('Groq hypothesis generation is permanently disabled and uses local clinical generator', () async {
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
      // Local fallback generates 3 high-fidelity clinical hypotheses
      expect(hypotheses, hasLength(3));
      expect(jsonClient.capturedHeaders, isEmpty);
      expect(service.networkRequestsAttempted, equals(0));

      final questions = await service.generateCrossExaminationQuestions(
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

    test('Groq testConnection returns network disabled without opening sockets', () async {
      final fakeClient = _FakeHttpClient(statusCode: 200, responseBody: '{}');
      final service = DirectGroqInvestigatorService(
        apiKey: 'gsk_live_123',
        clientFactory: () => fakeClient,
      );

      final result = await service.testConnection();
      expect(result.success, isFalse);
      expect(result.message, contains('External AI is currently unavailable'));
      expect(result.message, contains('Groq is not supported'));
      expect(result.message, contains('local reflection and support engine is active'));
      expect(fakeClient.capturedHeaders, isEmpty);
      expect(service.networkRequestsAttempted, equals(0));
    });

    test('investigatorServiceProvider routes to MockInvestigatorService even when Groq key saved', () async {
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
      expect(config.provider, equals(AiEngineProvider.local));
      expect(config.isLiveActive, isFalse);
      expect(
        container.read(investigatorServiceProvider),
        isA<MockInvestigatorService>(),
      );
    });

    testWidgets('AiEngineConfigSheet displays truthful 4-part availability matrix', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: AiEngineConfigSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Local Reflection & Support Engine'), findsOneWidget);
      expect(find.text('AVAILABLE & ACTIVE'), findsOneWidget);
      expect(find.text('External Cloud AI'), findsOneWidget);
      expect(find.text('UNAVAILABLE'), findsOneWidget);
      expect(find.text('xAI Grok'), findsOneWidget);
      expect(find.text('PLANNED'), findsOneWidget);
      expect(find.text('Google Gemini & Groq'), findsOneWidget);
      expect(find.text('NOT SUPPORTED'), findsOneWidget);

      // Obsolete controls are removed
      expect(find.text('Groq (Free Llama)'), findsNothing);
      expect(find.text('SAVE & ACTIVATE'), findsNothing);
    });
  });
}
