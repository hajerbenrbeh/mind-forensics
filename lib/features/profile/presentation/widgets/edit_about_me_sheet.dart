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

class EditAboutMeSheet extends ConsumerStatefulWidget {
  const EditAboutMeSheet({super.key, required this.profile});

  final PsychologicalProfileModel profile;

  static Future<void> show(BuildContext context, PsychologicalProfileModel profile) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditAboutMeSheet(profile: profile),
    );
  }

  @override
  ConsumerState<EditAboutMeSheet> createState() => _EditAboutMeSheetState();
}

class _EditAboutMeSheetState extends ConsumerState<EditAboutMeSheet> {
  late TextEditingController _nameController;
  late TextEditingController _introController;
  late TextEditingController _additionalController;
  late String _selectedAgeRange;
  late String _selectedLanguage;

  final List<String> _ageRanges = const [
    'Under 18',
    '18–24',
    '25–34',
    '35–44',
    '45–54',
    '55+',
    'Prefer not to say',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.preferredName);
    _introController = TextEditingController(text: widget.profile.personalIntroduction);
    _additionalController = TextEditingController(text: widget.profile.additionalContext);
    _selectedAgeRange = widget.profile.ageRange.isNotEmpty
        ? widget.profile.ageRange
        : 'Prefer not to say';
    _selectedLanguage = widget.profile.preferredLanguage.isNotEmpty
        ? widget.profile.preferredLanguage
        : 'en';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _introController.dispose();
    _additionalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    await ref.read(profileControllerProvider.notifier).updateAboutMe(
      preferredName: _nameController.text.trim(),
      ageRange: _selectedAgeRange,
      preferredLanguage: _selectedLanguage,
      personalIntroduction: _introController.text.trim(),
      additionalContext: _additionalController.text.trim(),
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
                  strings.sectionAboutMe,
                  style: LabTheme.serifStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.sectionAboutMeDesc,
                  style: TextStyle(fontSize: 11.5, color: textSecondary),
                ),

                const SizedBox(height: 20),

                // Preferred Name
                Text(
                  (strings.isArabic
                          ? 'الاسم أو اللقب المفضل'
                          : (strings.isFrench ? 'PRÉNOM OU SURNOM' : 'PREFERRED NAME'))
                      .toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  style: TextStyle(fontSize: 12.5, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: strings.isArabic
                        ? 'كيف تحب أن نناديك؟'
                        : (strings.isFrench
                            ? 'Comment souhaitez-vous être appelé(e) ?'
                            : 'How should we address you?'),
                    hintStyle: TextStyle(fontSize: 11.5, color: textSecondary.withValues(alpha: 0.6)),
                    filled: true,
                    fillColor: context.tokens.surfaceSecondary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.tokens.accent)),
                  ),
                ),

                const SizedBox(height: 16),

                // Age Range
                Text(
                  (strings.isArabic
                          ? 'الفئة العمرية (اختياري)'
                          : (strings.isFrench
                              ? 'TRANCHE D’ÂGE (OPTIONNEL)'
                              : 'AGE RANGE (OPTIONAL)'))
                      .toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _ageRanges.map((range) {
                    final isSelected = _selectedAgeRange == range;
                    return InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedAgeRange = range);
                      },
                      borderRadius: BorderRadius.circular(context.tokens.chipRadius),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.tokens.accentSoft
                              : context.tokens.surfaceSecondary,
                          borderRadius: BorderRadius.circular(context.tokens.chipRadius),
                          border: Border.all(
                            color: isSelected ? context.tokens.accent : border,
                            width: isSelected ? 1 : 0.8,
                          ),
                        ),
                        child: Text(
                          range,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? context.tokens.accent
                                : textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Personal Introduction
                Text(
                  (strings.isArabic
                          ? 'مقدمة شخصية قصيرة'
                          : (strings.isFrench
                              ? 'PRÉSENTATION PERSONNELLE'
                              : 'PERSONAL INTRODUCTION'))
                      .toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _introController,
                  maxLines: 3,
                  style: TextStyle(fontSize: 12.5, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: strings.isArabic
                        ? 'مقدمة حرة ومريحة عن نفسك وتجربتك...'
                        : (strings.isFrench
                            ? 'Quelques mots simples que vous souhaitez partager...'
                            : 'Brief introductory thoughts you feel comfortable sharing...'),
                    hintStyle: TextStyle(fontSize: 11.5, color: textSecondary.withValues(alpha: 0.6)),
                    filled: true,
                    fillColor: context.tokens.surfaceSecondary,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.tokens.accent)),
                  ),
                ),

                const SizedBox(height: 24),

                // Save Action
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
                      (strings.isArabic
                              ? 'حفظ المعلومات'
                              : (strings.isFrench ? 'ENREGISTRER' : 'SAVE CHANGES'))
                          .toUpperCase(),
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

