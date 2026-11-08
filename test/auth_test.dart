import 'dart:convert';
import 'package:crypto/crypto.dart';
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

  group('PBKDF2 Cryptographic Security & Password Migration Tests', () {
    test('New account registration produces standard PBKDF2-HMAC-SHA256 hash', () async {
      final service = AuthService();
      await service.signUpWithEmail('doctor@clinic.org', 'StrongPassword123!');

      final prefs = await SharedPreferences.getInstance();
      final credsRaw = prefs.getString('mf_auth_user_credentials') ?? '{}';
      final Map<String, dynamic> creds = jsonDecode(credsRaw);
      final storedHash = creds['doctor@clinic.org'] as String;

      expect(storedHash.startsWith('pbkdf2_sha256\$10000\$'), isTrue);
      final parts = storedHash.split('\$');
      expect(parts.length, equals(4)); // prefix, iterations, salt, key
      expect(parts[1], equals('10000'));
      expect(parts[2].isNotEmpty, isTrue); // saltBase64
      expect(parts[3].isNotEmpty, isTrue); // keyBase64
    });

    test('Different cryptographically secure salts generated for identical passwords', () async {
      final service = AuthService();
      await service.signUpWithEmail('usera@clinic.org', 'IdenticalPassword99!');
      await service.signUpWithEmail('userb@clinic.org', 'IdenticalPassword99!');

      final prefs = await SharedPreferences.getInstance();
      final credsRaw = prefs.getString('mf_auth_user_credentials') ?? '{}';
      final Map<String, dynamic> creds = jsonDecode(credsRaw);

      final hashA = creds['usera@clinic.org'] as String;
      final hashB = creds['userb@clinic.org'] as String;

      expect(hashA, isNot(equals(hashB))); // Unique salts produce different hashes
      final saltA = hashA.split('\$')[2];
      final saltB = hashB.split('\$')[2];
      expect(saltA, isNot(equals(saltB)));
    });

    test('Constant-time password verification confirms matching and rejects incorrect', () async {
      final service = AuthService();
      await service.signUpWithEmail('tester@clinic.org', 'CorrectPassword456!');

      // Valid password passes
      final user = await service.signInWithEmail('tester@clinic.org', 'CorrectPassword456!');
      expect(user.email, equals('tester@clinic.org'));

      // Incorrect password fails
      expect(
        () => service.signInWithEmail('tester@clinic.org', 'IncorrectPassword456!'),
        throwsA(isA<FormatException>()),
      );
    });

    test('Legacy Stage 2 SHA-256 credentials verify and automatically upgrade to PBKDF2', () async {
      final prefs = await SharedPreferences.getInstance();
      final salt = 'test-salt-uuid-v4';
      final legacySha256 = sha256.convert(utf8.encode('$salt:LegacyPass789!')).toString();

      // Seed legacy credential record
      await prefs.setString(
        'mf_auth_user_credentials',
        jsonEncode({'legacy@clinic.org': '$salt:$legacySha256'}),
      );
      await prefs.setString(
        'mf_auth_registered_users',
        jsonEncode({
          'legacy@clinic.org': {
            'id': 'legacy-user-uuid',
            'codename': 'LegacyUser',
            'email': 'legacy@clinic.org',
            'authType': 'emailPassword',
            'createdAt': DateTime.now().toIso8601String(),
          }
        }),
      );

      final service = AuthService();

      // Sign in with legacy password succeeds
      final user = await service.signInWithEmail('legacy@clinic.org', 'LegacyPass789!');
      expect(user.email, equals('legacy@clinic.org'));

      // Verify that stored credential was transparently upgraded to PBKDF2
      final updatedCredsRaw = prefs.getString('mf_auth_user_credentials') ?? '{}';
      final Map<String, dynamic> updatedCreds = jsonDecode(updatedCredsRaw);
      final upgradedHash = updatedCreds['legacy@clinic.org'] as String;

      expect(upgradedHash.startsWith('pbkdf2_sha256\$10000\$'), isTrue);

      // Subsequent sign in verifies with the new PBKDF2 hash
      final userAgain = await service.signInWithEmail('legacy@clinic.org', 'LegacyPass789!');
      expect(userAgain.email, equals('legacy@clinic.org'));
    });

    test('Legacy Stage 1 plaintext credentials verify and automatically upgrade to PBKDF2', () async {
      final prefs = await SharedPreferences.getInstance();

      // Seed plaintext credential
      await prefs.setString(
        'mf_auth_user_credentials',
        jsonEncode({'plain@clinic.org': 'RawPlaintextSecret!'}),
      );
      await prefs.setString(
        'mf_auth_registered_users',
        jsonEncode({
          'plain@clinic.org': {
            'id': 'plain-user-uuid',
            'codename': 'PlainUser',
            'email': 'plain@clinic.org',
            'authType': 'emailPassword',
            'createdAt': DateTime.now().toIso8601String(),
          }
        }),
      );

      final service = AuthService();

      // Sign in succeeds
      final user = await service.signInWithEmail('plain@clinic.org', 'RawPlaintextSecret!');
      expect(user.email, equals('plain@clinic.org'));

      // Plaintext was removed and upgraded to PBKDF2
      final updatedCredsRaw = prefs.getString('mf_auth_user_credentials') ?? '{}';
      final Map<String, dynamic> updatedCreds = jsonDecode(updatedCredsRaw);
      final upgradedHash = updatedCreds['plain@clinic.org'] as String;

      expect(upgradedHash.startsWith('pbkdf2_sha256\$10000\$'), isTrue);
      expect(upgradedHash, isNot(contains('RawPlaintextSecret!')));
    });

    test('Invalid, corrupted, or truncated credential records fail gracefully', () {
      expect(AuthService.verifyPasswordWithMigration('pass', '').isValid, isFalse);
      expect(AuthService.verifyPasswordWithMigration('pass', 'pbkdf2_sha256\$corrupted').isValid, isFalse);
      expect(AuthService.verifyPasswordWithMigration('pass', 'pbkdf2_sha256\$-10\$bad\$salt').isValid, isFalse);
      expect(AuthService.verifyPasswordWithMigration('pass', 'pbkdf2_sha256\$10000\$notBase64!@#\$badKey').isValid, isFalse);
    });
  });

  group('AuthService Unit Tests', () {
    test('creates anonymous sovereign vault with default codename and zero email footprint', () async {
      final service = AuthService();
      final user = await service.createAnonymousVault();

      expect(user.id.isNotEmpty, isTrue);
      expect(user.email, isNull);
      expect(user.isAnonymous, isTrue);
      expect(user.authType, equals(AuthType.anonymous));
      expect(user.codename.startsWith('Observer #'), isTrue);

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
      expect(find.text('Access Your Account'), findsOneWidget);

      // Verify tabs & submit button
      expect(find.text('SIGN IN'), findsNWidgets(2));
      expect(find.text('CREATE ACCOUNT'), findsOneWidget);

      // Verify Anonymous card
      expect(find.text('Private Local Space'), findsOneWidget);
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
      expect(find.text('Already have an account?'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}
