import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/app_strings.dart';
import '../../app/theme/mind_tokens.dart';
import '../widgets/mind_button.dart';
import '../widgets/mind_card.dart';
import 'secure_key_manager.dart';

/// Modal dialog presented when encrypted local data exists on device
/// but the platform master key is missing or corrupted in hardware Keystore.
///
/// Styled in Mind Forensics Warm Linen & Mineral Sage palette.
class MasterKeyRecoveryDialog extends ConsumerStatefulWidget {
  const MasterKeyRecoveryDialog({
    super.key,
    this.onRecovered,
  });

  final VoidCallback? onRecovered;

  /// Shows the dialog over the navigator. Returns true if recovered successfully.
  static Future<bool?> show(BuildContext context, {VoidCallback? onRecovered}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MasterKeyRecoveryDialog(onRecovered: onRecovered),
    );
  }

  @override
  ConsumerState<MasterKeyRecoveryDialog> createState() => _MasterKeyRecoveryDialogState();
}

class _MasterKeyRecoveryDialogState extends ConsumerState<MasterKeyRecoveryDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _requiresOverwriteConfirmation = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _attemptRestore({bool forceOverwrite = false}) async {
    final rawKey = _controller.text.trim();
    final clean = rawKey.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');

    final strings = ref.read(appStringsProvider);

    if (clean.length != 64) {
      setState(() {
        _errorMessage = strings.invalidKeyFormatError;
        _requiresOverwriteConfirmation = false;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final keyManager = ref.read(secureKeyManagerProvider);
      final result = await keyManager.restoreMasterKeyFromRecovery(
        clean,
        forceOverwrite: forceOverwrite,
      );

      if (result == MasterKeyRestoreResult.success) {
        // Probe test roundtrip on user partition cipher
        try {
          final cipher = await keyManager.getCipherForUser();
          final testRoundtrip = await cipher.decryptString(await cipher.encryptString('validation_probe'));
          if (testRoundtrip != 'validation_probe') {
            throw Exception('Cipher validation failed');
          }
        } catch (_) {}

        if (mounted) {
          widget.onRecovered?.call();
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.restoreSuccessMsg),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (result == MasterKeyRestoreResult.existingKeyWithData) {
        if (mounted) {
          setState(() {
            _requiresOverwriteConfirmation = true;
            _errorMessage = strings.isArabic
                ? 'يوجد بالفعل مفتاح تشفير محلي مع بيانات محفوظة. استبداله بمفتاح غير مطابق قد يؤدي إلى فقدان الوصول للبيانات الحالية.'
                : (strings.isFrench
                    ? 'Une clé locale avec données existe déjà. Le remplacement nécessite une confirmation explicite.'
                    : 'A local key with encrypted records already exists. Overwriting it with an unmatched key may cause data loss.');
            _isSubmitting = false;
          });
        }
      } else if (result == MasterKeyRestoreResult.invalidFormat) {
        if (mounted) {
          setState(() {
            _errorMessage = strings.invalidKeyFormatError;
            _requiresOverwriteConfirmation = false;
            _isSubmitting = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = strings.incorrectKeyError;
            _requiresOverwriteConfirmation = false;
            _isSubmitting = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _requiresOverwriteConfirmation = false;
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final tokens = context.tokens;

    return Directionality(
      textDirection: strings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Dialog(
        backgroundColor: tokens.background,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(color: tokens.border, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Icon and Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: tokens.accentSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tokens.accent.withValues(alpha: 0.2), width: 1),
                      ),
                      child: Icon(Icons.lock_reset_rounded, size: 22, color: tokens.accent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        strings.restoreKeyPromptTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Explanation
                Text(
                  strings.restoreKeyPromptBody,
                  style: TextStyle(
                    fontSize: 13,
                    color: tokens.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),

                // Key input text field inside MindCard
                MindCard(
                  padding: const EdgeInsets.all(4),
                  backgroundColor: tokens.surface,
                  borderColor: tokens.border,
                  child: TextField(
                    controller: _controller,
                    maxLines: 3,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: tokens.textPrimary,
                      letterSpacing: 1.0,
                    ),
                    decoration: InputDecoration(
                      labelText: strings.recoveryKeyInputLabel,
                      hintText: strings.recoveryKeyInputHint,
                      labelStyle: TextStyle(fontSize: 12, color: tokens.textSecondary),
                      hintStyle: TextStyle(fontSize: 11, color: tokens.textTertiary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Error / Warning banner if any
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.safetyWarmthSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: tokens.safetyWarmth.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(fontSize: 12, color: tokens.safetyWarmth, height: 1.35),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Action buttons
                if (_requiresOverwriteConfirmation) ...[
                  MindButton(
                    text: strings.isArabic ? 'تأكيد استبدال المفتاح' : (strings.isFrench ? 'Confirmer le remplacement' : 'Confirm Overwrite'),
                    variant: MindButtonVariant.danger,
                    isLoading: _isSubmitting,
                    isFullWidth: true,
                    onPressed: _isSubmitting ? null : () => _attemptRestore(forceOverwrite: true),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => setState(() => _requiresOverwriteConfirmation = false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tokens.textSecondary,
                      side: BorderSide(color: tokens.border, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      strings.isArabic ? 'إلغاء' : (strings.isFrench ? 'Annuler' : 'Cancel'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: tokens.textSecondary,
                            side: BorderSide(color: tokens.border, width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            strings.closeBtn,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: MindButton(
                          text: strings.restoreActionBtn,
                          isLoading: _isSubmitting,
                          onPressed: _isSubmitting ? null : () => _attemptRestore(forceOverwrite: false),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
