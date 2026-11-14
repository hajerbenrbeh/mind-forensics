import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/security/secure_key_manager.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../../../core/widgets/mind_card.dart';

/// Modal bottom sheet allowing users to view, copy, and confirm backup of
/// their 256-bit Master Recovery Key.
///
/// Mind Forensics Organic Calm palette:
/// Warm linen (#F7F5F0) / Soft Slate Obsidian (#121614),
/// Mineral Forest Sage accent (#3B5242 / #8EB19B), crisp surfaces, 0 emojis.
class RecoveryKeyBackupSheet extends ConsumerStatefulWidget {
  const RecoveryKeyBackupSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RecoveryKeyBackupSheet(),
    );
  }

  @override
  ConsumerState<RecoveryKeyBackupSheet> createState() => _RecoveryKeyBackupSheetState();
}

class _RecoveryKeyBackupSheetState extends ConsumerState<RecoveryKeyBackupSheet> {
  String? _recoveryKey;
  bool _isLoading = false;
  bool _hasSavedConfirmed = false;
  String? _errorMessage;

  Future<void> _fetchRecoveryKey() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final key = await ref.read(secureKeyManagerProvider).exportMasterRecoveryKey();
      if (mounted) {
        setState(() {
          _recoveryKey = key;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: strings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        decoration: BoxDecoration(
          color: tokens.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: tokens.border, width: 1),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: tokens.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tokens.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tokens.accent.withValues(alpha: 0.2), width: 1),
                    ),
                    child: Icon(Icons.key_rounded, size: 20, color: tokens.accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      strings.masterRecoveryKeyTitle,
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
              const SizedBox(height: 12),

              // Plain-language explanation
              Text(
                strings.masterRecoveryKeyDesc,
                style: TextStyle(
                  fontSize: 13,
                  color: tokens.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),

              if (_recoveryKey == null) ...[
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
                      style: TextStyle(fontSize: 12, color: tokens.safetyWarmth, height: 1.3),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Action to Reveal Key
                MindButton(
                  text: strings.revealKeyBtn,
                  isLoading: _isLoading,
                  isFullWidth: true,
                  onPressed: _isLoading ? null : _fetchRecoveryKey,
                ),
              ] else ...[
                // Display Key Box inside MindCard
                MindCard(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: tokens.surface,
                  borderColor: tokens.border,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SelectableText(
                        _recoveryKey!,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          letterSpacing: 1.2,
                          height: 1.6,
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Clipboard.setData(ClipboardData(text: _recoveryKey!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(strings.keyCopiedSnackbar),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: tokens.textPrimary,
                          side: BorderSide(color: tokens.border, width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: Icon(Icons.copy_rounded, size: 15, color: tokens.accent),
                        label: Text(
                          strings.copyKeyBtn,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Strict Warning Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tokens.safetyWarmthSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tokens.safetyWarmth.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield_outlined, size: 18, color: tokens.safetyWarmth),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          strings.recoveryKeyWarning,
                          style: TextStyle(
                            fontSize: 12,
                            color: tokens.textPrimary.withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Confirmation Checkbox
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _hasSavedConfirmed = !_hasSavedConfirmed);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _hasSavedConfirmed,
                          activeColor: tokens.accent,
                          checkColor: isDark ? tokens.background : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          onChanged: (val) {
                            HapticFeedback.selectionClick();
                            setState(() => _hasSavedConfirmed = val ?? false);
                          },
                        ),
                        Expanded(
                          child: Text(
                            strings.recoveryKeySavedCheckbox,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Done Button (Disabled until acknowledged)
                MindButton(
                  text: strings.doneBtn,
                  isFullWidth: true,
                  onPressed: _hasSavedConfirmed ? () => Navigator.of(context).pop() : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
