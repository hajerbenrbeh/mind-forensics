import '../../journey/domain/journey_state_model.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../profile/domain/psychological_profile_model.dart';
import '../domain/case_model.dart';
import '../domain/conversation_mode.dart';
import '../domain/hypothesis.dart';
import '../domain/investigator_service.dart';
import '../domain/statement.dart';

/// Simulated implementation of The Warm Investigator for offline development & testing.
///
/// Strictly adheres to Section 4 voice rules:
/// 1. Ask more than tell.
/// 2. Hypotheses, never verdicts.
/// 3. Acknowledge the feeling first.
/// 4. Plain language.
/// 5. Short turns.
/// 6. Trilingual clinical fidelity (authentic Tunisian Arabic, French, English).
class MockInvestigatorService implements InvestigatorService {
  @override
  Future<String> getNextQuestion({
    required CaseModel currentCase,
    required List<Statement> conversationHistory,
    bool includePastCaseSummaries = true,
    String? languageCode,
    PsychologicalProfileModel? profile,
    JourneyStateModel? journey,
    ConversationMode? conversationMode,
    MindTraceModel? latestTrace,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final lang = languageCode ?? 'en';

    if (conversationMode == ConversationMode.grounding) {
      if (lang == 'ar') {
        return 'خلّينا نوقفو لحظة وناخذو نفس عميق وموزون. ثبّت عينيك في 3 حاجات ملموسة بحذاك توا، وحس بالأرض تحت ساقيك. شنوة اللي تلاحظه؟';
      } else if (lang == 'fr') {
        return 'Prenons une pause ici pour respirer calmement. Remarquez 3 objets tangibles autour de vous, et ressentez le sol ferme sous vos pieds. Que remarquez-vous ?';
      }
      return "Let's pause right here and find your breath. Notice 3 tangible things you can see around you right now, and feel the solid ground under your feet. What do you notice?";
    }

    if (conversationMode == ConversationMode.understandEmotion) {
      if (lang == 'ar') {
        return 'خلّينا نتريثوا مع هذا الشعور من غير حكم. لو كان هذا الإحساس موجود في بلاصة معينة في بدنك توا، وين تحس بيه بوضوح؟';
      } else if (lang == 'fr') {
        return 'Accueillons cette émotion sans jugement. Si ce ressenti avait un emplacement physique précis dans votre corps en cet instant, où se situerait-il ?';
      }
      return "Let's sit with this emotion without judging it. If this feeling had a physical location in your body right now, where would you sense it most clearly?";
    }

    if (conversationMode == ConversationMode.psychologicalAnalysis) {
      if (lang == 'ar') {
        return 'كي نربطوا بين اللي حكيته وتجاربك السابقة: فما احتمال أن هذا النمط يظهر ديما كي تحس بنقص السيطرة. شنوة رايك في الفرضية هذي، هل تنطبق على حالتك؟';
      } else if (lang == 'fr') {
        return 'En observant les liens entre ce récit et vos expériences : il est possible que ce schéma apparaisse lorsque le sentiment de contrôle diminue. Est-ce que cette perspective résonne avec votre ressenti ?';
      }
      return 'Looking at possible connections across what you shared: one possibility is that this pattern surfaces when certainty or control feels low. Does that perspective fit your experience, or does it feel different?';
    }

    if (conversationMode == ConversationMode.guidedReflection) {
      if (lang == 'ar') {
        return 'خلّينا نتبعوا الخطوات بهدوء: شنوة كان الحدث الملموس أولاً، وشنوة أول فكرة خطرت على بالك وقتها؟';
      } else if (lang == 'fr') {
        return 'Prenons le temps d’une réflexion guidée : quel a été l’événement précis au départ, et quelle a été la première pensée spontanée ?';
      }
      return 'Let us walk through this guided reflection together: what was the specific situation, and what was the very first thought that crossed your mind?';
    }

    if (conversationMode == ConversationMode.justTalk) {
      if (lang == 'ar') {
        return 'أنا نسمع فيك بكل انتباه وبدون أي حكم. خوذ راحتك، وشاركني كل ما يدور في خاطرك توا.';
      } else if (lang == 'fr') {
        return 'Je vous écoute avec attention et sans aucun jugement. Prenez tout votre temps pour exprimer ce qui vous traverse l’esprit.';
      }
      return 'I am listening with you, with patience and without any judgment. Take all the space you need to talk through whatever is on your mind.';
    }

    final count = conversationHistory.where((s) => s.speaker == StatementSpeaker.user).length;

    if (lang == 'ar') {
      if (count <= 1) {
        return 'باين عليه موقف ثقيل باش تتحمله. قبل ما نحللوا الفكرة، شنوة المحفز الملموس اللي قدح ردة الفعل هذي؟ شنوة اللي صار بالضبط قبل؟';
      } else if (count == 2) {
        return 'واضح. وقت اللي صار هكا، شنوة أول إحساس بدني أو شعوري فقت بيه، وقداش كانت شدتو؟';
      } else if (count == 3) {
        return 'كي تغزر للفكرة هذي توا: فما دليل حقيقي ملموس تنجم تشير ليه، ولا هو تأويل صنعه مخك في لحظة توتر؟';
      } else {
        return 'مفهوم. وشنوة لقيت روحك عملت بعد ما حسيت بهكا؟';
      }
    } else if (lang == 'fr') {
      if (count <= 1) {
        return 'Cela semble avoir été un moment pesant. Avant d’examiner la pensée, quel a été le déclencheur observable ? Que s’est-il passé juste avant ?';
      } else if (count == 2) {
        return 'Compris. Lorsque cela s’est produit, quelle sensation physique ou émotion avez-vous ressentie en premier, et avec quelle intensité ?';
      } else if (count == 3) {
        return 'En observant cette pensée : existe-t-il un fait concret observable, ou s’agit-il d’une interprétation forgée dans l’instant ?';
      } else {
        return 'Bien noté. Qu’avez-vous fait ensuite après avoir ressenti cela ?';
      }
    } else {
      if (count <= 1) {
        return 'That sounds like a heavy moment to sit with. Before we examine the thought itself, what was the observable trigger? What happened right before this reaction?';
      } else if (count == 2) {
        return 'Got it. When that happened, what physical sensation or emotion did you notice first, and how intense was it?';
      } else if (count == 3) {
        return 'Looking at that thought: is there any concrete, observable fact you can point to, or is it an interpretation your mind made in the moment?';
      } else {
        return 'Understood. What did you find yourself doing next after feeling that way?';
      }
    }
  }

  @override
  Future<List<Hypothesis>> generateHypotheses({
    required CaseModel currentCase,
    String? languageCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final lang = languageCode ?? 'en';

    if (lang == 'ar') {
      return const [
        Hypothesis(
          id: 'hyp-ar-1',
          title: 'استباق دفاعي وقائي',
          explanation: 'مخك ينجم يكون قفز لأسوأ سيناريو باش يحمي روحك من الصدمة أو المفاجأة.',
          whyItMightFit: 'يتطابق مع الانتقال السريع من واقعة عادية إلى استنتاج قلق وعالي الشدة.',
          whatDoesNotFit: 'ما فما حتى تصريح واضح أو مباشر من الطرف الآخر يفيد الرفض أو العداء.',
        ),
        Hypothesis(
          id: 'hyp-ar-2',
          title: 'ظروف خارجة عن النطاق',
          explanation: 'الطرف الآخر ينجم يكون لاهي، مشغول، ولا ما عندوش وقت ولا طاقة يجاوب توا.',
          whyItMightFit: 'التأخر في الرد لساعات أمر شائع وطبيعي في نسق الحياة اليومية والخدمة.',
          whatDoesNotFit: 'تحس بيه غير منطقي وقت تبدا انت على أعصابك وتستنى في رد فوري.',
        ),
        Hypothesis(
          id: 'hyp-ar-3',
          title: 'تضخيم الغموض والسكوت',
          explanation: 'السكوت ديما يشبه لصفحة بيضاء، يخلّي المخ والمخاوف القديمة ترسم عليها سيناريوهات مرعبة.',
          whyItMightFit: 'ردة فعلك الشعورية أكبر بكثير من الحدث الواقعي الملموس في حد ذاته.',
          whatDoesNotFit: 'تنجم تكون فعلاً حسيت بنوع من البرود أو التوتر الحقيقي في وقت سابق.',
        ),
      ];
    } else if (lang == 'fr') {
      return const [
        Hypothesis(
          id: 'hyp-fr-1',
          title: 'Anticipation Protectrice',
          explanation: 'Votre esprit anticipe peut-être le pire scénario pour éviter d’être pris au dépourvu.',
          whyItMightFit: 'Cela correspond au glissement rapide d’un fait neutre vers une conclusion anxiogène.',
          whatDoesNotFit: 'Il n’y a eu aucune déclaration explicite de l’autre personne indiquant un rejet.',
        ),
        Hypothesis(
          id: 'hyp-fr-2',
          title: 'Délai Circonstanciel',
          explanation: 'L’autre personne était peut-être simplement occupée, distraite ou indisponible.',
          whyItMightFit: 'Quelques heures sans répondre restent habituelles dans une journée chargée.',
          whatDoesNotFit: 'Cela semble contre-intuitif lorsque vous attendiez urgemment une réponse.',
        ),
        Hypothesis(
          id: 'hyp-fr-3',
          title: 'Amplification de l’Ambiguïté',
          explanation: 'Le silence agit comme une toile blanche sur laquelle les anxiétés passées projettent leur propre scénario.',
          whyItMightFit: 'La charge émotionnelle dépasse largement l’événement factuel observable.',
          whatDoesNotFit: 'Vous avez peut-être perçu une réelle tension relationnelle préalable.',
        ),
      ];
    }

    return const [
      Hypothesis(
        id: 'hyp-en-1',
        title: 'Protective Anticipation',
        explanation: 'Your mind might be jumping ahead to assume the worst to prevent feeling caught off guard.',
        whyItMightFit: 'It matches the quick shift from a neutral fact to a high-intensity conclusion.',
        whatDoesNotFit: 'There was no explicit statement from the other person indicating rejection.',
      ),
      Hypothesis(
        id: 'hyp-en-2',
        title: 'Circumstantial Delay',
        explanation: 'The other person may have simply been occupied, distracted, or unavailable.',
        whyItMightFit: 'Three hours without replying is common during busy workdays.',
        whatDoesNotFit: 'It feels counter-intuitive when you were urgently waiting for a reply.',
      ),
      Hypothesis(
        id: 'hyp-en-3',
        title: 'Amplified Ambiguity',
        explanation: 'Silence often acts like a blank canvas where past anxieties project their own script.',
        whyItMightFit: 'The reaction felt larger than the observable event alone.',
        whatDoesNotFit: 'You may indeed have picked up on real interpersonal friction earlier.',
      ),
    ];
  }

  @override
  Future<List<String>> generateCrossExaminationQuestions({
    required CaseModel currentCase,
    required Hypothesis hypothesis,
    String? languageCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final lang = languageCode ?? 'en';

    if (lang == 'ar') {
      return [
        'شنوة الأدلة الملموسة اللي كنا نشوفوها لو كانت هذي صحيحة 100%؟',
        'صارش مرة موقف كيف هكا وكانت النتيجة عادية ولا إيجابية؟',
        'شنوة النصيحة الهادئة اللي تعطيها لصاحبك لو عاش نفس الموقف بالضبط؟',
      ];
    } else if (lang == 'fr') {
      return [
        'Quelles preuves tangibles verrait-on si cette explication était vraie à 100% ?',
        'Y a-t-il déjà eu une fois où cette situation s’est produite avec une issue neutre ou positive ?',
        'Quel conseil bienveillant donneriez-vous à un proche vivant exactement cette situation ?',
      ];
    }

    return [
      'What observable evidence would we expect to see if this explanation were 100% true?',
      'Has there ever been a time when this situation happened and the outcome was completely different?',
      'If a close friend experienced this exact scenario, what possibility would you offer them?',
    ];
  }

  @override
  Future<String> summarizeFindings({
    required CaseModel currentCase,
    String? languageCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final lang = languageCode ?? 'en';

    if (lang == 'ar') {
      return 'خلاصة الجلسة المعرفية لـ ${currentCase.caseNumber}:\n\n'
          '• الوقائع الملموسة: الحدث الخارجي وقع كما هو دون دليل مباشر على نية إيذاء.\n'
          '• الافتراضات المرصودة: العقل سارع إلى سد فجوة الصمت بافتراض الرفض الشخصي.\n'
          '• نقاط عدم اليقين: النية الحقيقية للطرف الآخر تبقى غير مؤكدة ما لم يتم التحقق المباشر.';
    } else if (lang == 'fr') {
      return 'Synthèse cognitive pour la ${currentCase.caseNumber} :\n\n'
          '• Faits observés : L’événement extérieur s’est produit tel que décrit, sans preuve directe d’intention malveillante.\n'
          '• Suppositions identifiées : L’esprit a comblé le silence par l’hypothèse d’un rejet personnel.\n'
          '• Incertitudes : Les intentions réelles restent invérifiées jusqu’à clarification directe.';
    }

    return 'Cognitive Analysis Summary for ${currentCase.caseNumber}:\n\n'
        '• Observed Facts: The external event occurred as stated, without direct evidence of malicious intent.\n'
        '• Assumptions Identified: The mind filled the silence with assumed rejection.\n'
        '• Uncertainties: The true intent of the other person remains unverified until clarified.';
  }
}
