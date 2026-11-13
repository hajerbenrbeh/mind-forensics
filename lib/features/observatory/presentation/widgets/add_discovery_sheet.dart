import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_colors.dart';
import '../../../journey/controllers/journey_controller.dart';

class AddDiscoverySheet extends ConsumerStatefulWidget {
  const AddDiscoverySheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddDiscoverySheet(),
    );
  }

  @override
  ConsumerState<AddDiscoverySheet> createState() => _AddDiscoverySheetState();
}

class _AddDiscoverySheetState extends ConsumerState<AddDiscoverySheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedCategory = 'Thought Shift';

  final List<({String key, String en, String fr, String ar})> _categories = const [
    (key: 'Thought Shift', en: 'Thought Shift', fr: 'Recadrage', ar: 'تغيير فكري'),
    (key: 'Body Wisdom', en: 'Body Wisdom', fr: 'Signal corporel', ar: 'إشارة جسدية'),
    (key: 'Grounded Boundary', en: 'Boundary', fr: 'Limite saine', ar: 'رسم حدود'),
    (key: 'Gentle Reminder', en: 'Gentle Reminder', fr: 'Rappel doux', ar: 'تذكير رفيق'),
  ];

  final List<({String titleEn, String titleFr, String titleAr, String notesEn, String notesFr, String notesAr})> _suggestions = const [
    (
      titleEn: 'Pausing is intentional, not avoidance',
      titleFr: 'Faire une pause est intentionnel, pas une fuite',
      titleAr: 'التوقف اختيار واعٍ موش هروب',
      notesEn: 'I do not have to react instantly to sudden worries or unanswered texts.',
      notesFr: 'Je n’ai pas à réagir dans l’instant aux inquiétudes soudaines ou aux messages sans réponse.',
      notesAr: 'مانيش مجبر نجاوب ولا نتفاعل مباشرة مع كل فكرة مقلقة أو مساج معلق.',
    ),
    (
      titleEn: 'Energy fluctuates naturally',
      titleFr: 'L’énergie fluctue naturellement',
      titleAr: 'طاقتي تتبدل طبيعياً',
      notesEn: 'Low physical stamina in the morning does not dictate how the entire day unfolds.',
      notesFr: 'Un manque d’entrain le matin ne détermine pas le reste de ma journée.',
      notesAr: 'تعب الصباح ما يعنيش اللي النهار كامل ضاع؛ نعدل نسقي برفق.',
    ),
    (
      titleEn: 'Feedback is collaboration, not a verdict',
      titleFr: 'Les retours sont une collaboration, pas un jugement',
      titleAr: 'الملاحظات عمل مشترك موش حكم',
      notesEn: 'Critique on my work reflects collaborative refinement, not my personal value.',
      notesFr: 'Les remarques visent à améliorer le travail, elles ne mesurent pas ma valeur personnelle.',
      notesAr: 'التعديلات في الخدمة فرصة للتحسين، موش مقياس لقيمتي كشخص.',
    ),
    (
      titleEn: 'Action precedes motivation',
      titleFr: 'L’action précède souvent la motivation',
      titleAr: 'الحركة تجيب الرغبة',
      notesEn: 'Starting with a two-minute micro-step breaks mental inertia without guilt.',
      notesFr: 'Commencer par un petit pas de deux minutes brise l’inertie sans culpabilité.',
      notesAr: 'خطوة بسيطة متاع دقيقتين تكسر الجمود من غير أي ضغط أو لوم.',
    ),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _applySuggestion(
    ({String titleEn, String titleFr, String titleAr, String notesEn, String notesFr, String notesAr}) s,
    AppStrings strings,
  ) {
    HapticFeedback.selectionClick();
    setState(() {
      _titleController.text = strings.isArabic ? s.titleAr : (strings.isFrench ? s.titleFr : s.titleEn);
      _notesController.text = strings.isArabic ? s.notesAr : (strings.isFrench ? s.notesFr : s.notesEn);
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();
    if (title.isEmpty) return;

    HapticFeedback.mediumImpact();
    await ref.read(journeyControllerProvider.notifier).addCustomDiscovery(
      title: title,
      notes: notes.isNotEmpty ? notes : title,
      category: _selectedCategory,
    );

    if (mounted) {
      Navigator.of(context).pop();
      final s = ref.read(appStringsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? LabColors.nightSurface
              : LabColors.daylightTextPrimary,
          content: Text(
            s.isArabic
                ? 'تم حفظ الخلاصة في سجل الاكتشافات'
                : (s.isFrench
                    ? 'Réflexion enregistrée dans vos découvertes personnelles'
                    : 'Reflection saved to your personal discoveries'),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);
    final isAr = strings.isArabic;

    final surface = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final border = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary = isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary = isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? LabColors.nightBackground : LabColors.daylightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: border, width: 1.5)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF333333) : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAr
                      ? 'تسجيل خلاصة نفسية'
                      : (strings.isFrench
                          ? 'ENREGISTRER UNE DÉCOUVERTE'
                          : 'RECORD A DISCOVERY'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: LabColors.sageGreen,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isAr
                  ? 'وثّق ملاحظة أو قناعة جديدة اكتشفتها اليوم، لتكون دليلك ومرجعك في أوقات التشتت.'
                  : (strings.isFrench
                      ? 'Notez une idée ou un recadrage apaisant découvert aujourd’hui.'
                      : 'Capture an insight or reframed perspective that felt grounding today.'),
              style: TextStyle(fontSize: 12, color: textSecondary, height: 1.35),
            ),
            const SizedBox(height: 16),

            // Category Chips (Options-first)
            Text(
              isAr
                  ? 'تصنيف الملاحظة'
                  : (strings.isFrench ? 'CATÉGORIE' : 'CATEGORY'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((c) {
                  final isSelected = _selectedCategory == c.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(isAr ? c.ar : (strings.isFrench ? c.fr : c.en)),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategory = c.key),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? textPrimary : textSecondary,
                      ),
                      backgroundColor: surface,
                      selectedColor: LabColors.sageGreen.withValues(alpha: 0.25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(
                          color: isSelected ? LabColors.sageGreen : border,
                        ),
                      ),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Options-First Suggestions
            Text(
              isAr
                  ? 'أفكار مقترحة بنقرة واحدة'
                  : (strings.isFrench
                      ? 'SUGGESTIONS EN UN CLIC'
                      : 'OPTIONS-FIRST SUGGESTIONS'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _suggestions.map((s) {
                final label = isAr ? s.titleAr : (strings.isFrench ? s.titleFr : s.titleEn);
                return ActionChip(
                  backgroundColor: surface,
                  side: BorderSide(color: border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  label: Text(
                    label,
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                  onPressed: () => _applySuggestion(s, strings),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Title Field
            Text(
              isAr
                  ? 'الخلاصة الأساسية'
                  : (strings.isFrench ? 'IDÉE CLÉ' : 'CORE TAKEAWAY'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: isAr
                    ? 'مثال: التوقف ليس كسلاً...'
                    : (strings.isFrench
                        ? 'ex. Faire une pause est un choix conscient...'
                        : 'e.g., Pausing is intentional...'),
                hintStyle: TextStyle(fontSize: 12, color: textSecondary.withValues(alpha: 0.6)),
                filled: true,
                fillColor: surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: LabColors.sageGreen, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Detail Notes Field
            Text(
              isAr
                  ? 'ملاحظة أو سياق إضافي (اختياري)'
                  : (strings.isFrench
                      ? 'RÉFLEXION PERSONNELLE (OPTIONNEL)'
                      : 'PERSONAL REFLECTION (OPTIONAL)'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              style: TextStyle(fontSize: 12.5, color: textPrimary),
              decoration: InputDecoration(
                hintText: isAr
                    ? 'كيف غيّرت هذه الفكرة شعورك بالراحة؟'
                    : (strings.isFrench
                        ? 'En quoi ce recadrage vous apaise-t-il aujourd’hui ?'
                        : 'How does this shift support your ease today?'),
                hintStyle: TextStyle(fontSize: 11.5, color: textSecondary.withValues(alpha: 0.6)),
                filled: true,
                fillColor: surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: LabColors.sageGreen, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: LabColors.sageGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  isAr
                      ? 'حفظ في الاكتشافات الشخصية'
                      : (strings.isFrench
                          ? 'Enregistrer la découverte'
                          : 'Save Personal Discovery'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

