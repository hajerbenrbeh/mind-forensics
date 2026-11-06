import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mind_forensics/core/security/app_lock_provider.dart';
import 'package:mind_forensics/core/security/biometric_service.dart';
import 'package:mind_forensics/core/security/lock_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockLocalAuthentication extends Fake implements LocalAuthentication {
  bool authenticateResult = true;
  bool canAuth = true;

  @override
  Future<bool> get canCheckBiometrics async => canAuth;

  @override
  Future<bool> isDeviceSupported() async => canAuth;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<dynamic> authMessages = const [],
    bool biometricOnly = false,
    bool persistAcrossBackgrounding = false,
    bool sensitiveTransaction = true,
  }) async {
    return authenticateResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLocalAuthentication mockAuth;
  late BiometricSecurityService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAuth = MockLocalAuthentication();
    service = BiometricSecurityService(auth: mockAuth);
  });

  group('Biometric Security & Vault Lock Tests', () {
    test('Default preference is disabled', () async {
      final enabled = await BiometricSecurityService.isBiometricEnabled();
      expect(enabled, isFalse);
    });

    test('Persists biometric toggle in SharedPreferences', () async {
      await BiometricSecurityService.setBiometricEnabled(true);
      expect(await BiometricSecurityService.isBiometricEnabled(), isTrue);

      await BiometricSecurityService.setBiometricEnabled(false);
      expect(await BiometricSecurityService.isBiometricEnabled(), isFalse);
    });

    test('AppLockNotifier starts unlocked when biometrics disabled', () async {
      final container = ProviderContainer(
        overrides: [
          biometricServiceProvider.overrideWithValue(service),
        ],
      );
      final state = container.read(appLockProvider);
      expect(state.isEnabled, isFalse);
      expect(state.isLocked, isFalse);
    });

    test('AppLockNotifier unlocks on successful biometric authentication', () async {
      await BiometricSecurityService.setBiometricEnabled(true);
      final container = ProviderContainer(
        overrides: [
          biometricServiceProvider.overrideWithValue(service),
        ],
      );
      // Let it initialize
      await pumpEventQueue();

      final unlocked = await container.read(appLockProvider.notifier).unlock();
      expect(unlocked, isTrue);
      expect(container.read(appLockProvider).isLocked, isFalse);
    });

    test('AppLockNotifier fails unlock when biometric authentication fails', () async {
      await BiometricSecurityService.setBiometricEnabled(true);
      mockAuth.authenticateResult = false;

      final container = ProviderContainer(
        overrides: [
          biometricServiceProvider.overrideWithValue(service),
        ],
      );
      await pumpEventQueue();

      final unlocked = await container.read(appLockProvider.notifier).unlock();
      expect(unlocked, isFalse);
      expect(container.read(appLockProvider).isLocked, isTrue);
    });

    testWidgets('LockOverlay renders child when unlocked and overlay when locked', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            biometricServiceProvider.overrideWithValue(service),
          ],
          child: const MaterialApp(
            home: LockOverlay(
              child: Scaffold(
                body: Text('Protected Session Content'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially unlocked
      expect(find.text('Protected Session Content'), findsOneWidget);

      // Now toggle biometrics on and lock manually
      final element = tester.element(find.byType(LockOverlay));
      final container = ProviderScope.containerOf(element);
      await container.read(appLockProvider.notifier).toggleBiometrics(true);
      container.read(appLockProvider.notifier).lockManually();

      await tester.pumpAndSettle();

      // Should display locked screen
      expect(find.text('SESSION VAULT LOCKED'), findsOneWidget);
      expect(find.text('UNLOCK VAULT'), findsOneWidget);
      expect(find.text('Protected Session Content'), findsNothing);
    });
  });
}
