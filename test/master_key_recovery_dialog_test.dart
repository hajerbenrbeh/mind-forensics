import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/core/security/local_data_cipher.dart';
import 'package:mind_forensics/core/security/master_key_recovery_dialog.dart';
import 'package:mind_forensics/core/security/secure_key_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureKeyManager keyManager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SecureKeyManager.resetStaticCache();
    keyManager = SecureKeyManager();
  });

  Widget buildTestDialog({
    VoidCallback? onRecovered,
  }) {
    return ProviderScope(
      overrides: [
        secureKeyManagerProvider.overrideWithValue(keyManager),
      ],
      child: MaterialApp(
        theme: ThemeData(
          extensions: const [MindTokens.light],
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    MasterKeyRecoveryDialog.show(
                      context,
                      onRecovered: onRecovered,
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  group('MasterKeyRecoveryDialog Widget Tests', () {
    testWidgets('rejects invalid key format (< 64 hex chars)', (tester) async {
      await tester.pumpWidget(buildTestDialog());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is presented
      expect(find.byType(TextField), findsOneWidget);

      // Enter short key
      await tester.enterText(find.byType(TextField), 'abcd1234');
      await tester.pump();

      // Tap restore button: strings.restoreActionBtn is "Restore Data"
      final restoreBtn = find.text('Restore Data');
      expect(restoreBtn, findsOneWidget);
      await tester.tap(restoreBtn);
      await tester.pumpAndSettle();

      // Error banner should appear
      expect(
        find.text('Invalid key format. The recovery key must be exactly 64 hexadecimal characters.'),
        findsOneWidget,
      );
    });

    testWidgets('successfully restores master key on empty installation', (tester) async {
      bool recoveredCalled = false;
      await tester.pumpWidget(buildTestDialog(onRecovered: () {
        recoveredCalled = true;
      }));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Valid 64-hex key
      const validKey = '0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF';
      await tester.enterText(find.byType(TextField), validKey);
      await tester.pump();

      final restoreBtn = find.text('Restore Data');
      expect(restoreBtn, findsOneWidget);
      await tester.tap(restoreBtn);
      await tester.pumpAndSettle();

      // Dialog closed, onRecovered triggered
      expect(find.byType(MasterKeyRecoveryDialog), findsNothing);
      expect(recoveredCalled, isTrue);

      // Key is stored and can be exported as uppercase hex
      final exported = await keyManager.exportMasterRecoveryKey();
      expect(exported, equals(validKey));
    });

    testWidgets('shows warning and overwrite confirmation when existing key with data exists', (tester) async {
      // Setup existing key and simulated data encrypted with prefix enc:v1$
      final initialKey = await keyManager.exportMasterRecoveryKey();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('case_record_1', '${LocalDataCipher.prefixV1}fake_encrypted_record_data');

      await tester.pumpWidget(buildTestDialog());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter a different valid key
      const differentKey = 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF';
      await tester.enterText(find.byType(TextField), differentKey);
      await tester.pump();

      final restoreBtn = find.text('Restore Data');
      expect(restoreBtn, findsOneWidget);
      await tester.tap(restoreBtn);
      await tester.pumpAndSettle();

      // Should show overwrite warning and overwrite confirmation button
      expect(find.textContaining('A local key with encrypted records already exists'), findsOneWidget);
      expect(find.text('Confirm Overwrite'), findsOneWidget);

      // Verify key has not changed yet
      final currentKey = await keyManager.exportMasterRecoveryKey();
      expect(currentKey, equals(initialKey));

      // Now tap confirm overwrite
      final confirmBtn = find.text('Confirm Overwrite');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Now dialog should dismiss and key is overwritten
      expect(find.byType(MasterKeyRecoveryDialog), findsNothing);
      final finalKey = await keyManager.exportMasterRecoveryKey();
      expect(finalKey, equals(differentKey));
    });
  });
}
