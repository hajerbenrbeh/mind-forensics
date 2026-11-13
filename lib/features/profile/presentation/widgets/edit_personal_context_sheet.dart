import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_colors.dart';
import '../../../../app/theme/lab_theme.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/bouncing_widget.dart';
import '../../controllers/profile_controller.dart';
import '../../domain/psychological_profile_model.dart';

class EditPersonalContextSheet extends ConsumerStatefulWidget {
  const EditPersonalContextSheet({super.key, required this.profile});

  final PsychologicalProfileModel profile;

  static Future<void> show(BuildContext context, PsychologicalProfileModel profile) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditPersonalContextSheet(profile: profile),
    );
  }

  @override
  ConsumerState<EditPersonalContextSheet> createState() =>
      _EditPersonalContextSheetState();
}

class _EditPersonalContextSheetState
    extends ConsumerState<EditPersonalContextSheet> {
  late TextEditingController _contextController;

  @override
  void initState() {
    super.initState();
    _contextController = TextEditingController(
      text: widget.profile.personalContext.isNotEmpty
          ? widget.profile.personalContext
          : widget.profile.notesForAiCompanion,
    );
  }

  @override
  void dispose() {
    _contextController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    await ref.read(profileControllerProvider.notifier).updatePersonalContext(
      _contextController.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);

    final bg = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final border = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary = isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary = isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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

                Text(
                  strings.isArabic
                      ? 'ما الذي ترغب أن يدركه Mind Forensics عنك؟'
                      : 'What would you like Mind Forensics to understand about you?',
                  style: LabTheme.serifStyle(
                    fontSize: 16,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.isArabic
                      ? 'يمكنك مشاركة أي شيء يجعل تجربتك أكثر عمقاً وأماناً: تاريخك الشخصي، ما يمر بك، ما يساعدك، أو أي سياق تراه مهماً.'
                      : 'You can share anything that might help make your experience more meaningful. Your personal history, current challenges, what helps you, or anything you feel is important.',
                  style: TextStyle(fontSize: 11.5, height: 1.4, color: textSecondary),
                ),

                const SizedBox(height: 18),

                TextField(
                  controller: _contextController,
                  maxLines: 8,
                  style: TextStyle(fontSize: 13, height: 1.45, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: strings.isArabic
                        ? 'اكتب براحتك وسرية تامة... هذه المساحة آمنة وخاصة بجهازك.'
                        : 'Share freely and without pressure... this space is private and stored only on your device.',
                    hintStyle: TextStyle(fontSize: 12, color: textSecondary.withValues(alpha: 0.6)),
                    filled: true,
                    fillColor: context.tokens.surfaceSecondary,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.tokens.accent)),
                  ),
                ),

                const SizedBox(height: 24),

                BouncingWidget(
                  onTap: _save,
                  child: Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      color: context.tokens.accent,
                      borderRadius: BorderRadius.circular(context.tokens.buttonRadius),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      (strings.isArabic ? 'حفظ السياق الشخصي' : 'SAVE PERSONAL CONTEXT').toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: isDark ? context.tokens.background : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

