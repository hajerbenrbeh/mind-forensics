import '../../investigation/domain/case_model.dart';
import '../../../app/localization/app_strings.dart';

/// Clinical Session Brief generator formatting cognitive deconstructions for clinician review.
///
/// Section 12: "The app should help a person arrive at therapy better prepared.
/// Working concept: the Session Brief, a summary of selected cases and patterns
/// the user brings to a professional."
class ClinicalExportService {
  /// Generates a structured clinical session brief from selected cases.
  ///
  /// Any case marked `isPrivate == true` is strictly filtered out.
  static String generateSessionBrief({
    required List<CaseModel> cases,
    required AppStrings strings,
    String recipientOrNote = '',
  }) {
    // Strictly filter out private shielded cases (Principle 2)
    final shareableCases = cases.where((c) => !c.isPrivate).toList();
    if (shareableCases.isEmpty) {
      return strings.isArabic
          ? 'لا توجد جلسات قابلة للمشاركة. جميع الجلسات المحددة موسومة بدرع السرية (خاصة).'
          : (strings.isFrench
              ? 'Aucune session partageable. Toutes les sessions sélectionnées sont confidentielles.'
              : 'No shareable sessions found. All selected sessions are shielded as private.');
    }

    final buffer = StringBuffer();
    final isAr = strings.isArabic;
    final isFr = strings.isFrench;

    // Header & Confidentiality banner
    buffer.writeln('======================================================================');
    buffer.writeln(isAr
        ? 'MIND FORENSICS — ملخص الجلسات السريري (SESSION BRIEF)'
        : (isFr
            ? 'MIND FORENSICS — BILAN DE SESSIONS CLINIQUES (SESSION BRIEF)'
            : 'MIND FORENSICS — CLINICAL SESSION BRIEF'));
    buffer.writeln(isAr
        ? 'تقرير معرفي صادر بمبادرة شخصية من المستعمل لمناقشته مع المعالج'
        : (isFr
            ? 'Document cognitif généré à l’initiative exclusive du patient'
            : 'Confidential Patient-Initiated Cognitive Summary for Clinical Collaboration'));
    buffer.writeln('======================================================================\n');

    // Clinical Notice & Mandatory Principles (Principles 4 & Forbidden terms compliance)
    buffer.writeln(isAr ? '[إشعار وتنبيه سريري]' : (isFr ? '[AVIS ET MENTIONS CLINIQUES]' : '[CLINICAL NOTICE & DISCLAIMER]'));
    if (isAr) {
      buffer.writeln('• تم تصميم Mind Forensics كأداة للتأمل الفكري الذاتي مستوحاة من مبادئ العلاج السلوكي المعرفي (CBT).');
      buffer.writeln('• التطبيق لا يقدم علاجاً طبياً، تشخيصاً نفسياً، أو علاجاً سريرياً بديلاً عن الطبيب المختص.');
      buffer.writeln('• الفرضيات المولدة بواسطة الذكاء الاصطناعي هي نماذج فكرية استكشافية للتأمل وليست استنتاجات طبية سريرية.');
      buffer.writeln('• المحفزات، الأفكار التلقائية، والخلاصات الواردة تمثل تقارير ذاتية دقيقة سجلها المستعمل بكلماته الشخصية.');
      buffer.writeln('• النظام لا يتنبأ بالانتكاس النفسي ولا يقيم شخصية المستعمل.');
    } else if (isFr) {
      buffer.writeln('• Mind Forensics est un outil d’auto-réflexion cognitive inspiré des approches TCC.');
      buffer.writeln('• L’application ne fournit aucun traitement médical, diagnostic psychiatrique ni psychothérapie.');
      buffer.writeln('• Les hypothèses générées par l’IA sont des modèles cognitifs exploratoires de réflexion, et NON des conclusions cliniques.');
      buffer.writeln('• Les stimuli, pensées automatiques et conclusions reflètent l’auto-évaluation authentique de l’utilisateur.');
      buffer.writeln('• L’application ne prédit jamais de rechute et ne porte aucun jugement sur la personne.');
    } else {
      buffer.writeln('• Mind Forensics is a cognitive self-reflection instrument inspired by CBT principles.');
      buffer.writeln('• The application does NOT provide psychiatric treatment, medical diagnoses, or formal psychotherapy.');
      buffer.writeln('• AI-assisted hypotheses are exploratory cognitive possibilities for patient self-reflection, NOT clinical findings or diagnoses.');
      buffer.writeln('• Patient narrative, observable triggers, automatic thoughts, and conclusions represent authentic patient self-reports.');
      buffer.writeln('• Mind Forensics never predicts relapse or judges psychological character.');
    }

    buffer.writeln('\n----------------------------------------------------------------------');
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    buffer.writeln(isAr
        ? 'تاريخ التصدير: $dateStr | عدد الجلسات المرفقة: ${shareableCases.length}'
        : (isFr
            ? 'Date d’export : $dateStr | Nombre de sessions : ${shareableCases.length}'
            : 'Export Date: $dateStr | Sessions Included: ${shareableCases.length}'));
    if (recipientOrNote.trim().isNotEmpty) {
      buffer.writeln(isAr
          ? 'المعالج المستهدف / ملاحظة: ${recipientOrNote.trim()}'
          : (isFr
              ? 'Praticien / Note de séance : ${recipientOrNote.trim()}'
              : 'Clinician / Session Note: ${recipientOrNote.trim()}'));
    }
    buffer.writeln('----------------------------------------------------------------------\n');

    // Chronological Sessions Deconstruction
    for (int i = 0; i < shareableCases.length; i++) {
      final c = shareableCases[i];
      final sessionDate = '${c.createdAt.day.toString().padLeft(2, '0')}/${c.createdAt.month.toString().padLeft(2, '0')}/${c.createdAt.year}';

      buffer.writeln('======================================================================');
      buffer.writeln('${isAr ? "الجلسة" : (isFr ? "SESSION" : "SESSION")}: ${strings.formatSessionNumber(c.caseNumber)} — "${c.title}"');
      buffer.writeln('${isAr ? "التاريخ" : (isFr ? "Date" : "Recorded")}: $sessionDate | ${isAr ? "الحالة" : (isFr ? "Statut" : "Status")}: ${c.isCompleted ? (isAr ? "مكتملة" : (isFr ? "Complétée" : "Completed")) : (isAr ? "قيد التفكيك" : (isFr ? "En cours" : "In Progress"))}');

      if (c.chain != null && c.chain!.emotion.isNotEmpty) {
        buffer.writeln('${isAr ? "الحالة العاطفية والشدة" : (isFr ? "Affect somatique & intensité" : "Self-Reported Affect & Intensity")}: ${c.chain!.emotion} (${c.chain!.emotionIntensity}/10)');
      }
      buffer.writeln('----------------------------------------------------------------------');

      // 1. Activating Catalyst
      buffer.writeln(isAr
          ? '1. المحفز اللحظي (Activating Catalyst):'
          : (isFr ? '1. STIMULUS DÉCLENCHEUR :' : '1. ACTIVATING CATALYST:'));
      buffer.writeln(c.incidentDescription.isNotEmpty
          ? '"${c.incidentDescription}"'
          : (isAr
              ? 'لم يُسجل محفز نصي.'
              : (isFr ? 'Aucun récit enregistré.' : 'No narrative logged.')));
      buffer.writeln();

      // 2. Observable Chain
      if (c.chain != null) {
        buffer.writeln(isAr
            ? '2. سلسلة الاستجابة المعرفية والسلوكية:'
            : (isFr ? '2. CHAÎNE COGNITIVE & COMPORTEMENTALE :' : '2. COGNITIVE & BEHAVIORAL CHAIN:'));
        buffer.writeln('   • ${isAr ? "المحفز الملاحظ" : (isFr ? "Déclencheur observable" : "Observable Trigger")}: ${c.chain!.trigger}');
        buffer.writeln('   • ${isAr ? "الفكرة التلقائية" : (isFr ? "Pensée automatique" : "Automatic Thought")}: "${c.chain!.thought}" [${isAr ? "التصنيف الإبستيمي" : (isFr ? "Catégorie" : "Epistemic Label")}: ${c.chain!.thoughtLabel.name.toUpperCase()}]');
        buffer.writeln('   • ${isAr ? "دافع السلوك / رد الفعل" : (isFr ? "Impulsion comportementale" : "Behavioral Impulse / Action")}: ${c.chain!.behavior}');
        buffer.writeln();
      }

      // 3. AI Exploratory Hypotheses (Clearly Labeled)
      if (c.hypotheses.isNotEmpty) {
        buffer.writeln(isAr
            ? '3. النماذج التفسيرية الاستكشافية (مساعدة الذكاء الاصطناعي - للتأمل فقط):'
            : (isFr
                ? '3. HYPOTHÈSES COGNITIVES EXPLORATOIRES (Assistance IA - Réflexion uniquement) :'
                : '3. EXPLORATORY COGNITIVE HYPOTHESES (AI-Assisted - For Patient Reflection Only):'));
        for (final h in c.hypotheses) {
          buffer.writeln('   • [${h.title}]: ${h.explanation}');
          if (h.whyItMightFit.isNotEmpty) {
            buffer.writeln('     - ${isAr ? "نقاط التوافق" : (isFr ? "Pourquoi cela correspond" : "Supporting indicators")}: ${h.whyItMightFit}');
          }
          if (h.whatDoesNotFit.isNotEmpty) {
            buffer.writeln('     - ${isAr ? "نقاط عدم التوافق" : (isFr ? "Ce qui ne correspond pas" : "Counter indicators")}: ${h.whatDoesNotFit}');
          }
        }
        buffer.writeln();
      }

      // 4. Patient's Grounded Conclusion
      buffer.writeln(isAr
          ? '4. الركيزة المعرفية المعتمدة (خلاصة المستعمل بكلماته الشخصية):'
          : (isFr
              ? '4. CONCLUSION ANCRÉE (Mots personnels du patient) :'
              : '4. PATIENT GROUNDED REFRAME ANCHOR (Patient’s Own Words):'));
      buffer.writeln(c.userConclusion != null && c.userConclusion!.isNotEmpty
          ? '"${c.userConclusion}"'
          : (isAr
              ? 'لم تُحدد خلاصة نهائية بعد.'
              : (isFr
                  ? 'Aucune conclusion formulée pour le moment.'
                  : 'No conclusion anchored yet.')));
      buffer.writeln('======================================================================\n');
    }

    buffer.writeln(isAr
        ? '--- نهاية ملخص الجلسات السريري • Mind Forensics ---'
        : (isFr
            ? '--- FIN DU BILAN DE SESSIONS CLINIQUES • Mind Forensics ---'
            : '--- END OF CLINICAL SESSION BRIEF • Mind Forensics ---'));

    return buffer.toString();
  }
}
