import '../../insights/domain/personal_baseline_model.dart';
import '../../profile/domain/psychological_profile_model.dart';
import '../domain/symptom_entry.dart';

/// Clinical AI service for Inner Observatory:
/// - Generates adaptive options-first follow-up inquiries
/// - Generates immediate Socratic analysis distinguishing observations from hypotheses
/// - Recommends stabilizing non-coercive micro-actions
/// - 0 emojis, strict non-pathologizing guardrails (never diagnose)
/// - Offline mock fallback with zero network calls on [kDevMockKey]
class ObservatoryAiService {
  ObservatoryAiService({
    this.apiKey,
    this.modelName = 'gemini-3.5-flash',
  });

  static const String kDevMockKey = 'DEV_MOCK_GEMINI_KEY';
  static const bool kIsNetworkPermanentlyDisabled = true;
  static const List<String> fallbackModels = [
    'gemini-3.5-flash',
    'gemini-3.1-flash-lite',
  ];

  final String? apiKey;
  final String modelName;
  bool? lastCallWasLive;
  String? lastModelUsed;
  String? lastError;

  /// Suggests a single context-aware, non-intrusive adaptive follow-up inquiry.
  String generateAdaptiveFollowUpQuestion({
    required List<SymptomEntry> selectedSymptoms,
    required PsychologicalProfileModel? profile,
    required String languageCode,
  }) {
    if (selectedSymptoms.isEmpty) {
      if (languageCode == 'ar') {
        return 'شنوة أكثر إحساس أو فكرة تحسها مسيطرة على انتباهك توا؟';
      } else if (languageCode == 'fr') {
        return 'Quel ressenti ou pensée occupe le plus votre esprit en ce moment ?';
      }
      return 'What feeling or thought is currently drawing most of your awareness?';
    }

    final first = selectedSymptoms.first;
    switch (first.domain) {
      case SymptomDomain.mood:
        if (languageCode == 'ar') {
          return 'كي تحس بالثقل هذا، هل تحسه مصحوب ببطء جسدي وإرهاق، والا بعزلة ورغبة في الهدوء؟';
        } else if (languageCode == 'fr') {
          return 'Cette lourdeur s’accompagne-t-elle plutôt de fatigue physique ou d’un besoin de retrait ?';
        }
        return 'When noticing this heaviness, does it feel more somatic and tired, or a mental pull toward solitude?';

      case SymptomDomain.anxiety:
        if (languageCode == 'ar') {
          return 'التوتر هذا، هل هو استباق لشيء معين قادم، والا مجرد تسارع جسدي من غير موضوع واضح؟';
        } else if (languageCode == 'fr') {
          return 'Cette tension est-elle liée à une anticipation précise ou à une agitation physique diffuse ?';
        }
        return 'Is this tension anchored in anticipation of an upcoming event, or a diffuse physical restlessness?';

      case SymptomDomain.cognitive:
        if (languageCode == 'ar') {
          return 'الأفكار اللي تدور في ذهنك، هل تحسها تطالبك بالتحقق السريع، والا مجرد سيناريوهات للمستقبل؟';
        } else if (languageCode == 'fr') {
          return 'Ces pensées vous poussent-elles à vérifier immédiatement, ou s’agit-il de scénarios futurs ?';
        }
        return 'Do these recurring thoughts urge you to re-verify something immediately, or are they future scenarios?';

      case SymptomDomain.attention:
        if (languageCode == 'ar') {
          return 'صعوبة الانطلاق توا، هل هي نابعة من كثرة التفاصيل، والا من غياب الطاقة للخطوة الأولى؟';
        } else if (languageCode == 'fr') {
          return 'La difficulté à démarrer vient-elle d’une surcharge de détails ou d’un manque d’élan ?';
        }
        return 'Does the barrier to starting stem from feeling overwhelmed by details, or low somatic activation?';

      case SymptomDomain.somatic:
        if (languageCode == 'ar') {
          return 'الشد الجسدي هذا، هل لاحظت متى بدا بالتحديد خلال نهارك؟';
        } else if (languageCode == 'fr') {
          return 'À quel moment de la journée avez-vous senti cette tension physique s’installer ?';
        }
        return 'At what point in your day did this physical stiffness or knot first become prominent?';

      case SymptomDomain.stress:
        if (languageCode == 'ar') {
          return 'هل تحس المحيط داير بيك حاد وصاخب أكثر من المعتاد، والا تحس برغبة في الانعزال التام؟';
        } else if (languageCode == 'fr') {
          return 'L’environnement vous paraît-il trop stimulant et bruyant, ou ressentez-vous une coupure ?';
        }
        return 'Does your environment feel excessively sharp and noisy, or are you noticing emotional detachment?';
    }
  }

  /// Generates immediate Socratic analysis and stabilizing suggestions.
  Future<({String analysis, String stabilizingStrategy})> analyzeSymptoms({
    required List<SymptomEntry> selectedSymptoms,
    required int intensity,
    required String? contextTrigger,
    required String? somaticLocation,
    required String? userAdaptiveAnswer,
    required PersonalBaseline? baseline,
    required PsychologicalProfileModel? profile,
    required String languageCode,
  }) async {
    lastCallWasLive = null;
    lastError = null;

    final canShareExternally = profile != null && profile.shareWithAiCompanion;

    if (!canShareExternally) {
      lastCallWasLive = false;
      return _generateLocalAnalysis(
        selectedSymptoms: selectedSymptoms,
        intensity: intensity,
        contextTrigger: contextTrigger,
        somaticLocation: somaticLocation,
        userAdaptiveAnswer: userAdaptiveAnswer,
        baseline: null,
        languageCode: languageCode,
      );
    }

    // In Stage 6.1A.3: Gemini network transmission is permanently disabled.
    // Mind Forensics uses local deterministic analysis until the separate Grok implementation stage.
    // External transmission is strictly blocked with zero outbound HTTP requests.
    lastCallWasLive = false;
    final allowsPersonalization = profile.allowAiPersonalization;
    return _generateLocalAnalysis(
      selectedSymptoms: selectedSymptoms,
      intensity: intensity,
      contextTrigger: contextTrigger,
      somaticLocation: somaticLocation,
      userAdaptiveAnswer: userAdaptiveAnswer,
      baseline: allowsPersonalization ? baseline : null,
      languageCode: languageCode,
    );
  }

  ({String analysis, String stabilizingStrategy}) _generateLocalAnalysis({
    required List<SymptomEntry> selectedSymptoms,
    required int intensity,
    required String? contextTrigger,
    required String? somaticLocation,
    required String? userAdaptiveAnswer,
    required PersonalBaseline? baseline,
    required String languageCode,
  }) {
    final symptomNames = selectedSymptoms.map((s) => s.titleEn).join(', ');

    if (languageCode == 'ar') {
      final symptomListAr = selectedSymptoms.map((s) => s.titleAr).join(' و ');
      final analysisText =
          'الملاحظات المسجلة: تم رصد تجارب ذات صلة بـ ($symptomListAr) بشدة مسجلة ($intensity/10).'
          '${contextTrigger != null ? " يظهر التقرير اقتران هذه التجربة بسياق: $contextTrigger." : ""}'
          '\n\nفرضية استكشافية: تشير المعطيات إلى استجابة تكيفية للضغط النفسي؛ هذا توصيف تأملي ولا يشكل تشخيصاً سريرياً.'
          '${baseline != null && baseline.hasEstablishedBaseline ? "\n\nمقارنة بالمرجع: متوسط المزاج المعتاد لديك يبلغ ${baseline.averageMoodIntensity?.toStringAsFixed(1) ?? 'N/A'}/10." : ""}';

      final strategyText = intensity >= 7
          ? 'تخفيف الحمل الحسي وتطبيق تمرين تنفس مهدئ (4-4-4-4) لتخفيض استثارة الجهاز العصبي دون إجبار نفسك على حل المشكلات الآن.'
          : 'خطوة ميكرو-بسيطة تدوم دقيقتين أو تثبيت حسي (5-4-3-2-1) لإعادة وصل الانتباه باللحظة الحاضرة.';

      return (analysis: analysisText, stabilizingStrategy: strategyText);
    }

    if (languageCode == 'fr') {
      final symptomListFr = selectedSymptoms.map((s) => s.titleFr).join(', ');
      final analysisText =
          'Observations rapportées : Expériences identifiées autour de ($symptomListFr) avec une intensité auto-déclarée de $intensity/10.'
          '${contextTrigger != null ? " Le contexte rapporté mentionne : $contextTrigger." : ""}'
          '\n\nHypothèse réflexive : Ces manifestations reflètent une mobilisation adaptative face à une surcharge ; il s’agit d’un regard réflexif et non d’un diagnostic médical.'
          '${baseline != null && baseline.hasEstablishedBaseline ? "\n\nComparaison avec votre ligne de base : Votre intensité habituelle se situe autour de ${baseline.averageMoodIntensity?.toStringAsFixed(1) ?? 'N/A'}/10." : ""}';

      final strategyText = intensity >= 7
          ? 'Priorité à la régulation vagale : pause sensorielle et respiration en boîte 4-4-4-4 pour apaiser l’organisme.'
          : 'Micro-action de deux minutes pour contourner l’inertie ou ancrage sensoriel 5-4-3-2-1 pour revenir au présent.';

      return (analysis: analysisText, stabilizingStrategy: strategyText);
    }

    // English default
    final analysisText =
        'Reported Observations: Noted experiences involving ($symptomNames) with a self-reported intensity of $intensity/10.'
        '${contextTrigger != null ? " Accompanied by contextual catalyst: $contextTrigger." : ""}'
        '\n\nReflective Hypothesis: This pattern reflects an adaptive psychological and autonomic stress response. This is a reflective perspective, not a clinical diagnosis.'
        '${baseline != null && baseline.hasEstablishedBaseline ? "\n\nBaseline Comparison: Your established baseline mood intensity is ${baseline.averageMoodIntensity?.toStringAsFixed(1) ?? 'N/A'}/10 across ${baseline.totalRecordedDays} observed days." : ""}';

    final strategyText = intensity >= 7
        ? 'Autonomic downregulation: Reduce incoming sensory stimuli and use 4-4-4-4 Box Breathing to steady the nervous system without pressure to resolve everything right now.'
        : 'Low-friction micro-action: Engage in one 2-minute concrete task or use 5-4-3-2-1 Sensory Grounding to reconnect with immediate reality.';

    return (analysis: analysisText, stabilizingStrategy: strategyText);
  }
}
