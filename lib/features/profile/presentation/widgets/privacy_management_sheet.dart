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
import '../../../journal/presentation/widgets/journal_memory_sheet.dart';

class PrivacyManagementSheet extends ConsumerStatefulWidget {
  const PrivacyManagementSheet({super.key, required this.profile});

  final PsychologicalProfileModel profile;

  static Future<void> show(BuildContext context, PsychologicalProfileModel profile) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PrivacyManagementSheet(profile: profile),
    );
  }

  @override
  ConsumerState<PrivacyManagementSheet> createState() =>
      _PrivacyManagementSheetState();
}

class _PrivacyManagementSheetState extends ConsumerState<PrivacyManagementSheet> {
  late bool _allowAi;

  @override
  void initState() {
    super.initState();
    _allowAi = widget.profile.allowAiPersonalization;
  }

  Future<void> _toggleAi(bool val) async {
    HapticFeedback.lightImpact();
    setState(() => _allowAi = val);
    await ref.read(profileControllerProvider.notifier).setAiPersonalization(val);
  }

  void _confirmClearNotes(AppStrings strings, bool isDark) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.tokens.cardRadius)),
        title: Text(
          strings.isArabic
              ? 'مسح الملاحظات الحرة؟'
              : (strings.isFrench
                  ? 'Effacer les notes libres ?'
                  : 'Clear Free-Text Notes?'),
          style: TextStyle(
            color: context.tokens.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          strings.isArabic
              ? 'سيتم مسح النصوص والملاحظات الشخصية، مع الإبقاء على الحالات والأهداف وتفضيلات التواصل.'
              : (strings.isFrench
                  ? 'Ceci efface vos notes personnelles tout en conservant vos expériences, objectifs et préférences.'
                  : 'This clears your free-text notes while preserving selected conditions, goals, and preferences.'),
          style: TextStyle(fontSize: 12, color: context.tokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              strings.isArabic ? 'إلغاء' : (strings.isFrench ? 'Annuler' : 'Cancel'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.tokens.accent,
              foregroundColor: isDark ? context.tokens.background : Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(profileControllerProvider.notifier).clearProfileNotes();
              if (mounted) Navigator.pop(context);
            },
            child: Text(
              strings.isArabic
                  ? 'مسح الملاحظات'
                  : (strings.isFrench ? 'Effacer les notes' : 'Clear Notes'),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProfile(AppStrings strings, bool isDark) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? LabColors.safetySoftBgDark : LabColors.safetySoftBgLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isDark ? LabColors.safetyBorderDark : LabColors.safetyBorderLight, width: 1),
        ),
        title: Text(
          strings.isArabic
              ? 'حذف الملف النفسي بالكامل؟'
              : (strings.isFrench
                  ? 'Supprimer le profil psychologique ?'
                  : 'Delete Psychological Profile?'),
          style: TextStyle(
            color: isDark ? LabColors.safetyWarmthDark : LabColors.safetyWarmth,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          strings.isArabic
              ? 'تنبيه: حذف ملفك النفسي يمسح جميع الحالات والتفضيلات المسجلة. حسابك وسجل جلساتك ستبقى محفوظة دون حذف.'
              : (strings.isFrench
                  ? 'Attention : supprimer votre profil réinitialise vos préférences et expériences. Votre compte et votre journal restent protégés.'
                  : 'Important: Deleting your psychological profile resets all conditions and profile preferences. Your application account and journal entries remain safe.'),
          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade300 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              strings.isArabic ? 'إلغاء' : (strings.isFrench ? 'Annuler' : 'Cancel'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: LabColors.cherryRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(profileControllerProvider.notifier).clearProfile();
              if (mounted) Navigator.pop(context);
            },
            child: Text(
              strings.isArabic
                  ? 'تأكيد الحذف'
                  : (strings.isFrench ? 'Supprimer le profil' : 'Delete Profile'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);

    final bg = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final surfaceColor = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
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
                  strings.sectionPrivacy,
                  style: LabTheme.serifStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.sectionPrivacyDesc,
                  style: TextStyle(fontSize: 11.5, color: textSecondary),
                ),

                const SizedBox(height: 20),

                // AI Consent Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _allowAi
                        ? context.tokens.accentSoft
                        : context.tokens.surfaceSecondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _allowAi ? context.tokens.accent : border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              strings.isArabic
                                  ? 'السماح بتخصيص ردود المساعد الذكي'
                                  : 'Allow my profile to personalize AI responses',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          Switch.adaptive(
                            value: _allowAi,
                            activeTrackColor: context.tokens.accent,
                            onChanged: _toggleAi,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _allowAi
                            ? (strings.isArabic
                                ? 'مفعل: يستخدم المساعد أهدافك ونبرتك المفضلة لتخصيص الحوار بدقة، وتبقى بياناتك محفوظة محلياً على جهازك فقط.'
                                : 'Enabled: Companion references your goals and preferred communication style. Data strictly stays on your local device.')
                            : (strings.isArabic
                                ? 'معطل: لن يتم تزويد المساعد الذكي بأي تفاصيل من ملفك النفسي. التطبيق يظل يعمل بكامل وظائفه.'
                                : 'Disabled: Profile context is strictly excluded from AI inquiries. All app features remain fully functional.'),
                        style: TextStyle(fontSize: 11, height: 1.35, color: textSecondary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Data Sovereignty & Offline Guarantee Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.tokens.surfaceSecondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 16, color: context.tokens.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          strings.isArabic
                              ? 'بياناتك مشفرة ومحفوظة محلياً فقط في خزينة جهازك (Offline-First). لا توجد مزامنة سحابية غير مصرح بها.'
                              : 'Your profile is encrypted and stored locally on this device (Offline-First). Zero unauthorized cloud exposure.',
                          style: TextStyle(fontSize: 11, height: 1.35, color: textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Memory Vault Access Tile
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    JournalMemorySheet.show(context);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.tokens.surfaceSecondary,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.psychology_outlined, size: 20, color: context.tokens.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.memoryVaultTitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                strings.isArabic
                                    ? 'عرض ومراجعة المعلومات التي يتذكرها المساعد الذكي'
                                    : 'Review what the AI companion remembers',
                                style: TextStyle(fontSize: 10.5, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 18, color: textSecondary),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Management & Reset Actions
                Text(
                  (strings.isArabic
                          ? 'إدارة البيانات وحذفها'
                          : (strings.isFrench
                              ? 'GESTION DES DONNÉES'
                              : 'DATA MANAGEMENT'))
                      .toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 10),

                // Clear Notes
                BouncingWidget(
                  onTap: () => _confirmClearNotes(strings, isDark),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      strings.isArabic
                          ? 'مسح الملاحظات الحرة فقط'
                          : (strings.isFrench
                              ? 'Effacer uniquement les notes libres'
                              : 'Clear Free-Text Notes Only'),
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Delete Profile
                BouncingWidget(
                  onTap: () => _confirmDeleteProfile(strings, isDark),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: isDark ? LabColors.safetySoftBgDark : LabColors.safetySoftBgLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? LabColors.safetyBorderDark : LabColors.safetyBorderLight),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      strings.isArabic
                          ? 'حذف الملف النفسي بالكامل'
                          : (strings.isFrench
                              ? 'Supprimer le profil psychologique'
                              : 'Delete Psychological Profile'),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? LabColors.safetyWarmthDark : LabColors.safetyWarmth,
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
