import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/core/security/daily_usage_limiter.dart';
import 'package:mind_forensics/features/investigation/domain/ai_service.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DailyUsageLimiter.resetForTesting();
  });

  group('DailyUsageLimiter Tests', () {
    test('Initial state allows requests up to max ceiling', () async {
      expect(await DailyUsageLimiter.canMakeRequest(), isTrue);
      expect(
        await DailyUsageLimiter.getRemainingRequests(),
        equals(DailyUsageLimiter.maxDailyRequests),
      );
    });

    test('Decrements quota and blocks further calls once limit is reached', () async {
      // Consume all daily requests
      for (int i = 0; i < DailyUsageLimiter.maxDailyRequests; i++) {
        expect(await DailyUsageLimiter.canMakeRequest(), isTrue);
        await DailyUsageLimiter.recordRequest();
      }

      // 21st request should be blocked
      expect(await DailyUsageLimiter.canMakeRequest(), isFalse);
      expect(await DailyUsageLimiter.getRemainingRequests(), equals(0));
    });

    test('AiService returns calm message when daily limit is exhausted', () async {
      // Consume all requests
      for (int i = 0; i < DailyUsageLimiter.maxDailyRequests; i++) {
        await DailyUsageLimiter.recordRequest();
      }

      final aiService = MockAiService();
      final testCase = CaseModel(
        id: 'limit-test',
        caseNumber: 'SESSION 99',
        title: 'Limit Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentStage: CaseStage.incident,
        incidentDescription: 'Testing daily limit ceiling.',
      );

      final result = await aiService.analyzeCase(testCase);

      // Verify user receives calm guidance, not a crash or error
      expect(result.message, equals(DailyUsageLimiter.limitExceededMessage));
      expect(result.safetyLevel, equals(0));
    });
  });
}

