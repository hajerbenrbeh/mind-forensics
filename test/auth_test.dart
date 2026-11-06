import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/features/auth/controllers/auth_controller.dart';
import 'package:mind_forensics/features/auth/data/auth_service.dart';
import 'package:mind_forensics/features/auth/domain/auth_state.dart';
import 'package:mind_forensics/features/auth/domain/auth_user.dart';
import 'package:mind_forensics/features/auth/presentation/auth_screen.dart';
import 'package:mind_forensics/features/onboarding/presentation/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AuthService Unit Tests', () {
    test('creates anonymous sovereign vault with default codename and zero email footprint', () async {
      final service = AuthService();
      final user = await service.createAnonymousVault();

      expect(user.id.isNotEmpty, isTrue);
      expect(user.email, isNull);
      expect(user.isAnonymous, isTrue);
      expect(user.authType, equals(AuthType.anonymous));
      expect(user.codename.startsWith('Investigator #'), isTrue);

      final current = await service.getCurrentUser();
      expect(current?.id, equals(user.id));
      expect(current?.isAnonymous, isTrue);
    });

    test('signs up with email and password, creating a cloud-synced vault', () async {
      final service = AuthService();
      final user = await service.signUpWithEmail(
        'test@mindforensics.org',
        'secureVault123',
        codename: 'Agent Veritas',
      );

      expect(user.email, equals('test@mindforensics.org'));
      expect(user.codename, equals('Agent Veritas'));
      expect(user.authType, equals(AuthType.emailPassword));
      expect(user.isAnonymous, isFalse);

      final current = await service.getCurrentUser();
      expect(current?.email, equals('test@mindforensics.org'));
    });

    test('validates email format and password length on sign up', () async {
      final service = AuthService();

      expect(
        () => service.signUpWithEmail('invalid-email', '123456'),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => service.signUpWithEmail('valid@test.com', '123'),
        throwsA(isA<FormatException>()),
      );
    });

    test('signs in successfully with existing credentials and rejects incorrect password', () async {
      final service = AuthService();
      await service.signUpWithEmail('detective@mind.org', 'password999');

      final user = await service.signInWithEmail('detective@mind.org', 'password999');
      expect(user.email, equals('detective@mind.org'));

      expect(
        () => service.signInWithEmail('detective@mind.org', 'wrongPassword'),
        throwsA(isA<FormatException>()),
      );
    });

    test('upgrades anonymous vault to email-secured cloud vault without losing user ID', () async {
      final service = AuthService();
      final anon = await service.createAnonymousVault(codename: 'AnonObserver');
      final originalId = anon.id;

      final upgraded = await service.linkEmailToAnonymous(
        'upgraded@mindforensics.org',
        'newPassword123',
      );

      expect(upgraded.id, equals(originalId));
      expect(upgraded.email, equals('upgraded@mindforensics.org'));
      expect(upgraded.authType, equals(AuthType.emailPassword));
      expect(upgraded.isAnonymous, isFalse);
    });

    test('signs out and removes current session', () async {
      final service = AuthService();
      await service.createAnonymousVault();
      expect(await service.getCurrentUser(), isNotNull);

      await service.signOut();
      expect(await service.getCurrentUser(), isNull);
    });
  });

  group('AuthController StateNotifier Tests', () {
    test('creates anonymous vault and transitions AuthState to authenticated', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authControllerProvider.notifier);
      final user = await notifier.createAnonymousVault(codename: 'TestSubject');

      expect(user, isNotNull);
      final state = container.read(authControllerProvider);
      expect(state.status, equals(AuthStatus.authenticated));
      expect(state.user?.codename, equals('TestSubject'));
      expect(state.isAnonymous, isTrue);
    });
  });

  group('AuthScreen & Onboarding Widget Tests', () {
    testWidgets('AuthScreen renders tabs, anonymous vault card, and input fields', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title and subtitle
      expect(find.text('Access Your Mental Vault'), findsOneWidget);

      // Verify tabs & submit button
      expect(find.text('UNLOCK VAULT'), findsNWidgets(2));
      expect(find.text('CREATE VAULT'), findsOneWidget);

      // Verify Anonymous card
      expect(find.text('Anonymous Sovereign Vault'), findsOneWidget);
      expect(find.text('MAXIMUM PRIVACY'), findsOneWidget);

      // Verify new investigator link
      expect(find.text('Start Exploration'), findsOneWidget);
    });

    testWidgets('OnboardingScreen Step 1 renders Welcome and discrete Sign In link', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Every thought leaves a trace.'), findsOneWidget);
      expect(find.text('Already have a vault?'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}
