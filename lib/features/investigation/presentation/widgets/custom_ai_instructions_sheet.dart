import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_theme.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/bouncing_widget.dart';
import '../../../profile/controllers/profile_controller.dart';
import '../../../profile/domain/psychological_profile_model.dart';

/// Modal bottom sheet allowing users to define custom directives and instructions
/// for their AI Psychological Companion.
class CustomAiInstructionsSheet extends ConsumerStatefulWidget {
  const CustomAiInstructionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CustomAiInstructionsSheet(),
    );
  }

  @override
  ConsumerState<CustomAiInstructionsSheet> createState() =>
      _CustomAiInstructionsSheetState();
}

class _CustomAiInstructionsSheetState
    extends ConsumerState<CustomAiInstructionsSheet> {
  late final TextEditingController _instructionsController;
  bool _isSaving = false;

  final List<({String label, String directive})> _presets = const [
    (
      label: 'Concise & Grounding',
      directive:
          'Keep replies under 3 sentences. Focus on physical sensations, slow breathing, and tangible present-moment observations.',
    ),
    (
      label: 'Socratic & Analytical',
      directive:
          'Use probing Socratic questions to examine evidence, unpack assumptions, and challenge cognitive leaps without lecturing.',
    ),
    (
      label: 'Gentle & Validating',
      directive:
          'Respond with patient, compassionate validation of feelings before exploring alternative perspectives. Take it slow.',
    ),
    (
      label: 'Direct & Pragmatic',
      directive:
          'Be straightforward, clear, and action-oriented. Point out cognitive distortions directly with zero fluff.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider).value;
    _instructionsController = TextEditingController(
      text: profile?.customAiDirectives ?? '',
    );
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    final current =
        ref.read(profileControllerProvider).value ?? PsychologicalProfileModel.empty();
    final updated = current.copyWith(
      customAiDirectives: _instructionsController.text.trim(),
      updatedAt: DateTime.now(),
    );

    await ref.read(profileControllerProvider.notifier).saveFullProfile(updated);

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI Companion instructions updated successfully.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);

    final bg = tokens.surface;
    final surfaceColor = tokens.surfaceSecondary;
    final borderColor = tokens.border;
    final textPrimary = tokens.textPrimary;
    final textSecondary = tokens.textSecondary;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.cardRadius),
        ),
        border: Border(
          top: BorderSide(
            color: tokens.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tokens.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: tokens.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.isArabic
                          ? 'تعليمات المساعد المخصصة'
                          : (strings.isFrench
                              ? 'Instructions personnalisées'
                              : 'Custom AI Instructions'),
                      style: LabTheme.serifStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.isArabic
                          ? 'حدد كيف ترغب أن يتحاور معك رفيقك النفسي الذكي'
                          : (strings.isFrench
                              ? 'Définissez comment votre compagnon échange avec vous'
                              : 'Define how your AI companion should communicate with you'),
                      style: TextStyle(fontSize: 11.5, color: textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Preset Chips
          Text(
            strings.isArabic
                ? 'نماذج جاهزة سريعة'
                : (strings.isFrench
                    ? 'MODÈLES RAPIDES'
                    : 'QUICK DIRECTIVE PRESETS'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: tokens.accent,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _presets.map((preset) {
              return BouncingWidget(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _instructionsController.text = preset.directive;
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(tokens.chipRadius),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Text(
                    preset.label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Custom Input Box
          Text(
            strings.isArabic
                ? 'تعليماتك الخاصة'
                : (strings.isFrench
                    ? 'VOS INSTRUCTIONS PERSONNELLES'
                    : 'YOUR CUSTOM INSTRUCTIONS'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: tokens.accent,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _instructionsController,
            maxLines: 4,
            style: TextStyle(color: textPrimary, fontSize: 12.5, height: 1.4),
            decoration: InputDecoration(
              hintText: strings.isArabic
                  ? 'مثال: تحدث باقتضاب، ولا تطرح أكثر من سؤال واحد في كل مرة. ركز على تقنيات التنفس والتأريض الحسي...'
                  : 'e.g. Keep responses concise, never give unsolicited lectures, and ask only one question at a time. Emphasize somatic grounding...',
              hintStyle: TextStyle(
                fontSize: 11.5,
                color: textSecondary.withValues(alpha: 0.65),
              ),
              filled: true,
              fillColor: surfaceColor,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.buttonRadius),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.buttonRadius),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.buttonRadius),
                borderSide: BorderSide(color: tokens.accent, width: 1.4),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: isDark ? tokens.background : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(tokens.buttonRadius),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      strings.isArabic
                          ? 'حفظ التعليمات'
                          : (strings.isFrench
                              ? 'ENREGISTRER LES INSTRUCTIONS'
                              : 'SAVE INSTRUCTIONS'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        letterSpacing: 0.6,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

