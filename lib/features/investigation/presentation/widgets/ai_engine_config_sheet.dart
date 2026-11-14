import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_colors.dart';
import '../../controllers/investigation_providers.dart';

/// Modal bottom sheet displaying truthful AI engine status,
/// provider availability, and local clinical processing guarantees.
class AiEngineConfigSheet extends ConsumerStatefulWidget {
  const AiEngineConfigSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiEngineConfigSheet(),
    );
  }

  @override
  ConsumerState<AiEngineConfigSheet> createState() => _AiEngineConfigSheetState();
}

class _AiEngineConfigSheetState extends ConsumerState<AiEngineConfigSheet> {
  bool _isTesting = false;
  String? _testResult;
  bool? _testSuccess;

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });
    HapticFeedback.lightImpact();

    await Future<void>.delayed(const Duration(milliseconds: 150));

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = false;
        _testResult =
            'External AI is currently unavailable. Gemini and Groq are not supported; local reflection and support engine is active.';
      });
    }
  }

  Future<void> _clearHistoricalKeys() async {
    HapticFeedback.lightImpact();
    final strings = ref.read(appStringsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textDirection = Directionality.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: textDirection,
          child: AlertDialog(
            backgroundColor:
                isDark ? LabColors.nightSurface : LabColors.daylightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? LabColors.nightBorder : LabColors.daylightBorder,
              ),
            ),
            title: Text(
              strings.purgeHistoricalKeysTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? LabColors.nightTextPrimary
                    : LabColors.daylightTextPrimary,
              ),
            ),
            content: Text(
              strings.purgeHistoricalKeysMessage,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark
                    ? LabColors.nightTextSecondary
                    : LabColors.daylightTextSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  strings.cancelBtn,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? LabColors.nightTextSecondary
                        : LabColors.daylightTextSecondary,
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: LabColors.safetyWarmth,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  strings.confirmPurgeBtn,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    await ref.read(aiConfigProvider.notifier).clearAllHistoricalKeys();
    if (mounted) {
      setState(() {
        _testResult = null;
        _testSuccess = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.historicalKeysClearedToast),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);
    final aiConfig = ref.watch(aiConfigProvider);

    final bg = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final border = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary =
        isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary =
        isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    final hasHistoricalKeys =
        (aiConfig.apiKey.isNotEmpty && aiConfig.apiKey != kDevMockGeminiKey) ||
            aiConfig.groqApiKey.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: border, width: 1)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: [
                Icon(
                  Icons.psychology_outlined,
                  size: 20,
                  color: textPrimary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    strings.aiEngineStatusTitle.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? LabColors.nightSurfaceElevated
                        : LabColors.daylightSurfaceSubtle,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    strings.engineBadgeOffline.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              strings.aiEngineStatusDesc,
              style:
                  TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Availability Matrix: 4 Status Cards
            // 1. Local AI
            _buildStatusCard(
              title: strings.localAiTitle,
              badgeText: 'AVAILABLE & ACTIVE',
              badgeColor: LabColors.sageGreenGlow,
              badgeBg: LabColors.sageGreenGlow.withValues(alpha: 0.12),
              description: strings.localAiDesc,
              borderColor: LabColors.sageGreenGlow.withValues(alpha: 0.35),
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 10),

            // 2. External Cloud AI
            _buildStatusCard(
              title: strings.externalAiTitle,
              badgeText: 'UNAVAILABLE',
              badgeColor: textSecondary,
              badgeBg: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.06),
              description: strings.externalAiDesc,
              borderColor: border,
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 10),

            // 3. xAI Grok (Planned)
            _buildStatusCard(
              title: strings.grokTitle,
              badgeText: 'PLANNED',
              badgeColor: LabColors.warmBeige,
              badgeBg: LabColors.warmBeige.withValues(alpha: 0.12),
              description: strings.grokDesc,
              borderColor: LabColors.warmBeige.withValues(alpha: 0.3),
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 10),

            // 4. Google Gemini & Groq (Not Supported)
            _buildStatusCard(
              title: strings.unsupportedProvidersTitle,
              badgeText: 'NOT SUPPORTED',
              badgeColor: LabColors.safetyWarmth,
              badgeBg: LabColors.safetyWarmth.withValues(alpha: 0.12),
              description: strings.unsupportedProvidersDesc,
              borderColor: LabColors.safetyWarmth.withValues(alpha: 0.3),
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),

            if (_testResult != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_testSuccess == true
                          ? LabColors.sageGreenGlow
                          : LabColors.safetyWarmth)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _testSuccess == true
                        ? LabColors.sageGreenGlow
                        : LabColors.safetyWarmth,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _testSuccess == true
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      size: 16,
                      color: _testSuccess == true
                          ? LabColors.sageGreenGlow
                          : LabColors.safetyWarmth,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _testSuccess == true
                              ? LabColors.sageGreenGlow
                              : LabColors.safetyWarmth,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isTesting ? null : _testConnection,
                    child: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            strings.testConnectionBtn,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: textPrimary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      strings.doneBtn.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (hasHistoricalKeys) ...[
              const SizedBox(height: 14),
              Text(
                strings.historicalKeysNote,
                style:
                    TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(
                      foregroundColor: LabColors.safetyWarmth),
                  onPressed: _clearHistoricalKeys,
                  child: Text(
                    strings.clearHistoricalKeysBtn,
                    style: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
    required String description,
    required Color borderColor,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? LabColors.nightSurfaceElevated
            : LabColors.daylightSurfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 11.5,
              color: textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}