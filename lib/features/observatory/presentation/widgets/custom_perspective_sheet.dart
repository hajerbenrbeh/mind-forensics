import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_colors.dart';
import '../../../journey/controllers/journey_controller.dart';

class CustomPerspectiveSheet extends ConsumerStatefulWidget {
  const CustomPerspectiveSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CustomPerspectiveSheet(),
    );
  }

  @override
  ConsumerState<CustomPerspectiveSheet> createState() => _CustomPerspectiveSheetState();
}

class _CustomPerspectiveSheetState extends ConsumerState<CustomPerspectiveSheet> {
  int _step = 0; // 0: Fact, 1: Interpretation, 2: Grounded Alternatives
  String? _selectedFact;
  String? _selectedAssumption;
  String? _selectedAlternative;
  final TextEditingController _customFactCtrl = TextEditingController();
  final TextEditingController _customAssumptionCtrl = TextEditingController();
  final TextEditingController _customAlternativeCtrl = TextEditingController();

  final List<({String en, String ar})> _commonFacts = const [
    (en: 'Unanswered message or silence', ar: 'رسالة لم يُرد عليها أو صمت مؤقت'),
    (en: 'Critical feedback received on task', ar: 'ملاحظات أو تعديلات على عمل'),
    (en: 'Sudden cancellation of plans', ar: 'إلغاء موعد أو لقاء فجأة'),
    (en: 'Woke up with heavy somatic fatigue', ar: 'استيقاظ بإرهاق وثقل بدني'),
    (en: 'Mistake made during a meeting', ar: 'هفوة أو تردد أثناء اجتماع'),
  ];

  final List<({String en, String ar})> _commonAssumptions = const [
    (en: 'They are annoyed and rejecting me', ar: 'إنهم متضايقون مني ويتجاهلونني'),
    (en: 'My work is substandard and I will fail', ar: 'عملي فاشل ولن أستطيع النجاح'),
    (en: 'The entire day will be completely lost', ar: 'النهار بأكمله ضاع ولن أنجز شيئاً'),
    (en: 'I am always falling behind everyone else', ar: 'أنا متأخر دائماً عن الآخرين'),
    (en: 'People are quietly judging my presence', ar: 'الجميع يراقبونني ويحكمون عليّ سلبياً'),
  ];

  final List<({String en, String ar})> _groundedAlternatives = const [
    (en: 'Their delay reflects their own busy day, not a verdict on me.', ar: 'تأخرهم يعكس انشغالهم بظروفهم الخاصة، وليس تقييماً لي.'),
    (en: 'Feedback is normal iteration; it proves the work is valued and refinable.', ar: 'الملاحظات جزء طبيعي من التطوير وتؤكد أن العمل يستحق التحسين.'),
    (en: 'Morning stamina fluctuates; pacing gently preserves energy for later.', ar: 'الطاقة تتقلب طبيعياً؛ خفض النسق بهدوء يحفظ التوازن لبقية اليوم.'),
    (en: 'One uncomfortable moment does not define my capability or value.', ar: 'موقف واحد مربك لا يلغي كفاءتي ولا يحدد قيمتي.'),
    (en: 'I do not have to believe every automatic thought my mind generates.', ar: 'لست مجبراً على تصديق كل فكرة تلقائية يقفز إليها ذهني.'),
  ];

  @override
  void dispose() {
    _customFactCtrl.dispose();
    _customAssumptionCtrl.dispose();
    _customAlternativeCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAsDiscovery() async {
    final fact = _selectedFact ?? _customFactCtrl.text.trim();
    final assumption = _selectedAssumption ?? _customAssumptionCtrl.text.trim();
    final alternative = _selectedAlternative ?? _customAlternativeCtrl.text.trim();

    if (alternative.isEmpty) return;

    HapticFeedback.mediumImpact();
    await ref.read(journeyControllerProvider.notifier).addCustomDiscovery(
      title: alternative,
      notes: 'Fact: $fact\nInterpretation: $assumption\nGrounded Reframe: $alternative',
      category: 'Perspective Reframe',
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? LabColors.nightSurface
              : LabColors.daylightTextPrimary,
          content: Text(
            ref.read(appStringsProvider).isArabic
                ? 'تم حفظ زاوية النظر البديلة في سجل الاكتشافات'
                : 'Alternative perspective saved to Personal Discoveries',
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

            // Header with Steps Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAr ? 'تفكيك زوايا النظر' : 'PERSPECTIVE DECONSTRUCTION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: LabColors.sageGreen,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    '${_step + 1} / 3',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Step 0: Fact
            if (_step == 0) ...[
              Text(
                isAr ? '1. ما هي الواقعة الملموسة؟' : '1. What is the observable fact?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                isAr
                    ? 'ما حدث بالعين المجردة بدون أي أحكام أو تأويلات ذهنية.'
                    : 'The plain event as a video camera would record it, free of assumptions.',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
              const SizedBox(height: 14),
              ..._commonFacts.map((f) {
                final label = isAr ? f.ar : f.en;
                final isSelected = _selectedFact == label;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedFact = label;
                        _step = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? LabColors.sageGreen.withValues(alpha: 0.15) : surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? LabColors.sageGreen : border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.fact_check_outlined,
                            size: 16,
                            color: isSelected ? LabColors.sageGreen : textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: textSecondary),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],

            // Step 1: Assumption
            if (_step == 1) ...[
              Text(
                isAr ? '2. ما الذي افترضه ذهنك؟' : '2. What story did your mind assume?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                isAr
                    ? 'التفسير التلقائي الفوري أو السيناريو المخيف الذي قفز إلى تفكيرك.'
                    : 'The automatic narrative or alarmist storyline your mind attached.',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
              const SizedBox(height: 14),
              ..._commonAssumptions.map((a) {
                final label = isAr ? a.ar : a.en;
                final isSelected = _selectedAssumption == label;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedAssumption = label;
                        _step = 2;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? LabColors.sageGreen.withValues(alpha: 0.15) : surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? LabColors.sageGreen : border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.psychology_outlined,
                            size: 16,
                            color: isSelected ? LabColors.sageGreen : textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: textSecondary),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],

            // Step 2: Grounded Alternative
            if (_step == 2) ...[
              Text(
                isAr ? '3. زاوية نظر واقعية بديلة' : '3. Grounded alternative explanation',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                isAr
                    ? 'اختر التفسير الأكثر هدوءاً وواقعية، واحفظه في اكتشافاتك.'
                    : 'Select a grounded perspective to restore balance and anchor your ease.',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
              const SizedBox(height: 14),
              ..._groundedAlternatives.map((alt) {
                final label = isAr ? alt.ar : alt.en;
                final isSelected = _selectedAlternative == label;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedAlternative = label);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? LabColors.sageGreen.withValues(alpha: 0.2) : surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? LabColors.sageGreen : border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            size: 16,
                            color: isSelected ? LabColors.sageGreen : textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              if (_selectedAlternative != null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                    label: Text(isAr ? 'حفظ في الاكتشافات الشخصية' : 'Save as Personal Discovery'),
                    onPressed: _saveAsDiscovery,
                    style: FilledButton.styleFrom(
                      backgroundColor: LabColors.sageGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 12),
            if (_step > 0)
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _step--),
                  child: Text(
                    isAr ? 'الرجوع للخطوة السابقة' : 'Back to previous step',
                    style: TextStyle(fontSize: 11.5, color: textSecondary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

