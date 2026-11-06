import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_colors.dart';
import '../../../../app/theme/lab_theme.dart';
import '../../../../core/widgets/bouncing_widget.dart';
import '../../controllers/profile_controller.dart';
import '../../domain/psychological_profile_model.dart';

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
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(
          strings.isArabic ? 'مسح الملاحظات الحرة؟' : 'Clear Free-Text Notes?',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          strings.isArabic
              ? 'سيتم مسح النصوص والملاحظات الشخصية، مع الإبقاء على الحالات والأهداف وتفضيلات التواصل.'
              : 'This clears your free-text notes while preserving selected conditions, goals, and preferences.',
          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey : Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(profileControllerProvider.notifier).clearProfileNotes();
              if (mounted) Navigator.pop(context);
            },
            child: Text(strings.isArabic ? 'مسح الملاحظات' : 'Clear Notes'),
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
        backgroundColor: isDark ? const Color(0xFF1F080D) : const Color(0xFFFFF1F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: LabColors.cherryRed, width: 1),
        ),
        title: Text(
          strings.isArabic ? 'حذف الملف النفسي بالكامل؟' : 'Delete Psychological Profile?',
          style: const TextStyle(
            color: LabColors.cherryRedGlow,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          strings.isArabic
              ? 'تنبيه: حذف ملفك النفسي يمسح جميع الحالات والتفضيلات المسجلة. حسابك وخزينة تفكيكاتك في السجل ستبقى محفوظة دون حذف.'
              : 'Important: Deleting your psychological profile resets all conditions and profile preferences. Your application account and journal cases remain safe.',
          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade300 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.isArabic ? 'إلغاء' : 'Cancel'),
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
            child: Text(strings.isArabic ? 'تأكيد الحذف' : 'Delete Profile'),
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
                        ? (isDark ? LabColors.darkWine : const Color(0xFFFBE8E9))
                        : (isDark ? const Color(0xFF101010) : const Color(0xFFFAFAFA)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _allowAi ? LabColors.champagneGold : border,
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
                            activeTrackColor: LabColors.champagneGold,
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
                    color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 16, color: LabColors.champagneGold),
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

                const SizedBox(height: 24),

                // Management & Reset Actions
                Text(
                  (strings.isArabic ? 'إدارة البيانات وحذفها' : 'DATA MANAGEMENT').toUpperCase(),
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
                      strings.isArabic ? 'مسح الملاحظات الحرة فقط' : 'Clear Free-Text Notes Only',
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
                      color: isDark ? const Color(0xFF1E070C) : const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: LabColors.cherryBorderDark),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      strings.isArabic ? 'حذف الملف النفسي بالكامل' : 'Delete Psychological Profile',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: LabColors.cherryRedGlow,
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
