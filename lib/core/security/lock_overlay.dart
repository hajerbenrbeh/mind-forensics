import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/app_strings.dart';
import '../../app/theme/lab_colors.dart';
import '../widgets/bouncing_widget.dart';
import 'app_lock_provider.dart';
import 'master_key_recovery_dialog.dart';
import 'master_key_status_provider.dart';

/// Full-screen biometric lock overlay protecting private cognitive sessions.
///
/// Luxury Vercel Dark aesthetic:
/// OLED pitch black (#000000), 1.0px hairline borders, monochrome action button,
/// and zero emoji clutter.
class LockOverlay extends ConsumerWidget {
  const LockOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if master encryption key is missing while encrypted data is present
    final masterKeyStatus = ref.watch(masterKeyStatusProvider);
    masterKeyStatus.whenData((isIntact) {
      if (!isIntact) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            MasterKeyRecoveryDialog.show(context, onRecovered: () {
              ref.invalidate(masterKeyStatusProvider);
            });
          }
        });
      }
    });

    final lockState = ref.watch(appLockProvider);
    final strings = ref.watch(appStringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!lockState.isLocked) {
      return child;
    }

    final bg = isDark ? LabColors.nightBackground : LabColors.daylightBackground;
    final surface = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final border = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary = isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary = isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    return Directionality(
      textDirection: strings.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Biometric Icon Container
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: border, width: 1),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.fingerprint_rounded,
                        size: 32,
                        color: textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: LabColors.beigeBackground(isDark: isDark),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: LabColors.beigeBorder(isDark: isDark)),
                    ),
                    child: Text(
                      strings.biometricVaultLockedTitle.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? LabColors.warmBeigeGlow : LabColors.warmBeigeDark,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Mind Forensics',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    strings.biometricVaultLockedDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: textSecondary,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Unlock Action Button
                  SizedBox(
                    width: double.infinity,
                    child: BouncingWidget(
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        final success = await ref.read(appLockProvider.notifier).unlock();
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: isDark ? const Color(0xFF161616) : Colors.black,
                              content: Text(
                                strings.biometricFailedSnackbar,
                                style: const TextStyle(color: Colors.white, fontSize: 12.5),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xFF333333) : const Color(0xFFE4E4E7),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_open_rounded,
                              size: 16,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              strings.unlockWithBiometricsBtn.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

