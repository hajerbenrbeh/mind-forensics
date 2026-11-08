import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/localization/app_strings.dart';
import '../../app/theme/lab_colors.dart';
import 'safety_model.dart';

/// The persistent, calm "I need support" button required in every mode.
class SupportButton extends ConsumerWidget {
  const SupportButton({super.key, this.compact = false});

  final bool compact;

  void _openSupportSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SupportModalSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    if (compact) {
      return IconButton(
        icon: const Icon(Icons.shield_outlined, size: 18),
        tooltip: strings.needSupportBtn,
        onPressed: () => _openSupportSheet(context),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: isDark ? LabColors.safetyWarmthDark : LabColors.safetyWarmth,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      icon: const Icon(Icons.shield_outlined, size: 15),
      label: Text(
        strings.needSupportBtn,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.3),
      ),
      onPressed: () => _openSupportSheet(context),
    );
  }
}

/// The modal bottom sheet presenting Tunisian crisis and supportive resources.
class SupportModalSheet extends ConsumerWidget {
  const SupportModalSheet({super.key});

  Future<void> _makeCall(String phone) async {
    HapticFeedback.mediumImpact();
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWeb(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatPhone(String raw) {
    if (raw == '80105050') return '80 10 50 50';
    return raw;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);
    final resources = CrisisResource.tunisianResources;

    final sheetBg = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final cardBg = isDark ? LabColors.nightSurfaceSubtle : LabColors.daylightBackground;
    final borderColor = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary = isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary = isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          border: Border.all(color: borderColor, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isDark ? LabColors.safetySoftBgDark : LabColors.safetySoftBgLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.shield_outlined,
                    color: isDark ? LabColors.safetyWarmthDark : LabColors.safetyWarmth, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.supportModalTitle,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: textPrimary),
                    ),
                    Text(
                      strings.supportModalSub,
                      style: TextStyle(fontSize: 11.5, color: textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            strings.supportModalBody,
            style: TextStyle(
              fontSize: 12.5,
              color: textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: resources.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, index) {
                final res = resources[index];
                final hasPhone = res.phone.isNotEmpty;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              res.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              res.description,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: textSecondary,
                              ),
                            ),
                            if (res.isTollFree) ...[
                              const SizedBox(height: 2),
                              const Text(
                                'Gratuit / مجاني 24/7',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: LabColors.factBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (hasPhone)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: isDark ? LabColors.safetyWarmthDark : LabColors.safetyWarmth,
                            foregroundColor: isDark ? LabColors.nightBackground : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          icon: const Icon(Icons.phone_outlined, size: 14),
                          label: Text(
                            _formatPhone(res.phone),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                          ),
                          onPressed: () => _makeCall(res.phone),
                        )
                      else if (res.website != null)
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderColor),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () => _openWeb(res.website!),
                          child: Text(
                            'INFO',
                            style: TextStyle(color: textPrimary, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}
}
