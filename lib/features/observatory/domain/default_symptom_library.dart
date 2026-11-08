import '../../profile/domain/condition_type.dart';
import 'symptom_entry.dart';

/// Predefined Condition-First Symptom Library for Mind Forensics.
///
/// Organized around 6 domains and aligned with lived psychological experiences:
/// - Mood & Emotion
/// - Anxiety & Tension
/// - Thoughts & Cognition
/// - Focus & Attention
/// - Somatic & Body
/// - Stress & Trauma
class DefaultSymptomLibrary {
  static const List<SymptomEntry> entries = [
    // -------------------------------------------------------------------------
    // 1. Mood & Emotion (Depression, Bipolar, Mood Instability)
    // -------------------------------------------------------------------------
    SymptomEntry(
      id: 'sym_persistent_heaviness',
      titleEn: 'Persistent Heaviness',
      titleFr: 'Lourdeur persistante',
      titleAr: 'ثقل روحي مستمر',
      descriptionEn: 'A continuous low weight making daily motion and interaction feel effortful.',
      descriptionFr: 'Une sensation continue de lourdeur rendant le quotidien difficile.',
      descriptionAr: 'إحساس مستمر بالثقل والركود يجعل أبسط المهام تتطلب جهداً مضاعفاً.',
      domain: SymptomDomain.mood,
      relatedCondition: ConditionType.depression,
    ),
    SymptomEntry(
      id: 'sym_anhedonia',
      titleEn: 'Loss of Interest (Anhedonia)',
      titleFr: 'Perte d’intérêt (Anhédonie)',
      titleAr: 'فقدان المتعة والشغف',
      descriptionEn: 'Activities that previously brought comfort or joy feel muted or flat.',
      descriptionFr: 'Les activités habituelles semblent ternes et sans saveur.',
      descriptionAr: 'الأشياء والاهتمامات التي كانت تبعث الراحة تبدو باهتة وخالية من المعنى.',
      domain: SymptomDomain.mood,
      relatedCondition: ConditionType.depression,
    ),
    SymptomEntry(
      id: 'sym_rapid_mood_shifts',
      titleEn: 'Rapid Mood Shifts',
      titleFr: 'Fluctuations rapides de l’humeur',
      titleAr: 'تقلبات مزاجية متسارعة',
      descriptionEn: 'Noticeable swings between high energy, irritability, and sudden drops in stamina.',
      descriptionFr: 'Oscillations rapides entre énergie intense et abattement soudain.',
      descriptionAr: 'تغيرات ملحوظة بين طاقة متدفقة، عصبية مفاجئة، وهبوط حاد في القدرة.',
      domain: SymptomDomain.mood,
      relatedCondition: ConditionType.moodInstability,
    ),
    SymptomEntry(
      id: 'sym_emotional_exhaustion',
      titleEn: 'Emotional Exhaustion',
      titleFr: 'Épuisement émotionnel',
      titleAr: 'إنهاك واستنزاف نفسي',
      descriptionEn: 'Feeling mentally depleted even after physical rest or quiet periods.',
      descriptionFr: 'Se sentir vidé mentalement malgré le repos physique.',
      descriptionAr: 'شعور بالنفاذ النفسي والإنهاك حتى بعد فترات الراحة أو النوم.',
      domain: SymptomDomain.mood,
      relatedCondition: ConditionType.depression,
    ),

    // -------------------------------------------------------------------------
    // 2. Anxiety & Tension (GAD, Panic, Social Anxiety)
    // -------------------------------------------------------------------------
    SymptomEntry(
      id: 'sym_constant_apprehension',
      titleEn: 'Constant Apprehension',
      titleFr: 'Appréhension constante',
      titleAr: 'توجس وترقب دائم',
      descriptionEn: 'Persistent internal tension anticipating that something is about to go wrong.',
      descriptionFr: 'Tension intérieure persistante anticipant un problème imminent.',
      descriptionAr: 'ترقب داخلي مستمر وشعور باقتراب أمر غير مرغوب فيه دون سبب واضح.',
      domain: SymptomDomain.anxiety,
      relatedCondition: ConditionType.generalizedAnxiety,
    ),
    SymptomEntry(
      id: 'sym_sudden_dread_surge',
      titleEn: 'Sudden Dread Surge (Panic Spike)',
      titleFr: 'Poussée soudaine d’angoisse',
      titleAr: 'نوبة فزع مفاجئة',
      descriptionEn: 'Abrupt waves of intense somatic fear accompanied by rapid heartbeat or breathlessness.',
      descriptionFr: 'Bouffée aiguë de panique avec accélération du rythme cardiaque.',
      descriptionAr: 'موجة مفاجئة من الخوف الشديد مصحوبة بتسارع دقات القلب وضيق التنفس.',
      domain: SymptomDomain.anxiety,
      relatedCondition: ConditionType.panicAttacks,
    ),
    SymptomEntry(
      id: 'sym_hypervigilance',
      titleEn: 'Social Hypervigilance',
      titleFr: 'Hypervigilance sociale',
      titleAr: 'يقظة اجتماعية مفرطة',
      descriptionEn: 'Intense self-monitoring and fear of being scrutinized or negatively perceived.',
      descriptionFr: 'Surveillance excessive de soi et peur d’être jugé négativement.',
      descriptionAr: 'مراقبة مفرطة للنفس وخشية مستمرة من نظرة الآخرين أو أحكامهم.',
      domain: SymptomDomain.anxiety,
      relatedCondition: ConditionType.socialAnxiety,
    ),
    SymptomEntry(
      id: 'sym_physical_restlessness',
      titleEn: 'Motor Restlessness',
      titleFr: 'Agitation motrice',
      titleAr: 'تململ وعدم استقرار حركي',
      descriptionEn: 'Difficulty sitting still or settling down physically, with inner pacing.',
      descriptionFr: 'Difficulté à rester en place, sensation d’agitation interne.',
      descriptionAr: 'صعوبة في البقاء ساكناً أو الاستقرار، مع شعور داخلي بالاستعجال.',
      domain: SymptomDomain.anxiety,
      relatedCondition: ConditionType.generalizedAnxiety,
    ),

    // -------------------------------------------------------------------------
    // 3. Thoughts & Cognition (OCD, Rumination, Intrusive Loops)
    // -------------------------------------------------------------------------
    SymptomEntry(
      id: 'sym_intrusive_loops',
      titleEn: 'Intrusive Thought Loops',
      titleFr: 'Pensées intrusives répétitives',
      titleAr: 'أفكار وسواسية متكررة',
      descriptionEn: 'Unwanted thoughts or vivid scenarios that repeat despite attempts to dismiss them.',
      descriptionFr: 'Pensées involontaires persistantes qui tournent en boucle.',
      descriptionAr: 'أفكار أو سيناريوهات غير مرغوبة تلح على الذهن وتتكرر بصورة متواصلة.',
      domain: SymptomDomain.cognitive,
      relatedCondition: ConditionType.intrusiveThoughts,
    ),
    SymptomEntry(
      id: 'sym_mental_rumination',
      titleEn: 'Post-Event Rumination',
      titleFr: 'Rumination après événement',
      titleAr: 'اجترار فكري وتحليل مفرط',
      descriptionEn: 'Replaying past conversations and interactions repeatedly looking for errors.',
      descriptionFr: 'Rejouer sans cesse les scènes passées en quête d’erreurs.',
      descriptionAr: 'إعادة تدوير المواقف السابقة وتحليل كل كلمة ونظرة بصورة مستمرة.',
      domain: SymptomDomain.cognitive,
      relatedCondition: ConditionType.repetitiveThoughts,
    ),
    SymptomEntry(
      id: 'sym_checking_urgency',
      titleEn: 'Urge to Re-Verify / Check',
      titleFr: 'Besoin compulsif de vérifier',
      titleAr: 'رغبة ملحة في إعادة التثبت',
      descriptionEn: 'An intense internal urge to check actions, messages, or physical safety repeatedly.',
      descriptionFr: 'Besoin impérieux de vérifier plusieurs fois pour calmer le doute.',
      descriptionAr: 'دافع داخلي قوي للتأكد المتكرر من الأفعال، الرسائل، أو الأمان.',
      domain: SymptomDomain.cognitive,
      relatedCondition: ConditionType.compulsiveBehaviors,
    ),
    SymptomEntry(
      id: 'sym_catastrophic_projection',
      titleEn: 'Catastrophic Projection',
      titleFr: 'Scénarios catastrophes',
      titleAr: 'توقع أسوأ السيناريوهات',
      descriptionEn: 'Instinctively extrapolating uncertain situations toward worst-case outcomes.',
      descriptionFr: 'Imaginer spontanément le pire dénouement face à une incertitude.',
      descriptionAr: 'القفز التلقائي نحو افتراض الكوارث والانهيار عند مواجهة أي مجهول.',
      domain: SymptomDomain.cognitive,
      relatedCondition: ConditionType.repetitiveThoughts,
    ),

    // -------------------------------------------------------------------------
    // 4. Focus & Attention (ADHD, Executive Dysfunction)
    // -------------------------------------------------------------------------
    SymptomEntry(
      id: 'sym_task_initiation_paralysis',
      titleEn: 'Task Initiation Paralysis',
      titleFr: 'Incapacité à démarrer une tâche',
      titleAr: 'شلل البداية وصعوبة الانطلاق',
      descriptionEn: 'Knowing exactly what needs to be done, yet experiencing immense barrier to starting.',
      descriptionFr: 'Savoir quoi faire mais bloquer totalement devant la première étape.',
      descriptionAr: 'معرفة ما يجب فعله تماماً، مع عجز حقيقي عن البدء في الخطوة الأولى.',
      domain: SymptomDomain.attention,
      relatedCondition: ConditionType.adhd,
    ),
    SymptomEntry(
      id: 'sym_mental_scatter',
      titleEn: 'Mental Scatter & Brain Fog',
      titleFr: 'Dispersion et brouillard mental',
      titleAr: 'تشتت ذهني وضبابية في التركيز',
      descriptionEn: 'Thoughts drifting quickly across unrelated topics, losing train of thought.',
      descriptionFr: 'Pensées morcelées, difficulté à maintenir le fil conducteur.',
      descriptionAr: 'تطاير الأفكار وصعوبة الإمساك بخيط تفكير متماسك لأكثر من دقائق.',
      domain: SymptomDomain.attention,
      relatedCondition: ConditionType.attentionDifficulties,
    ),
    SymptomEntry(
      id: 'sym_hyperfocus_burnout',
      titleEn: 'Hyperfocus Followed by Crash',
      titleFr: 'Hyperfocalisation suivie d’épuisement',
      titleAr: 'تركيز فائق يتبعه انهيار في الطاقة',
      descriptionEn: 'Immersing obsessively in a topic for hours without pause, followed by total depletion.',
      descriptionFr: 'Immersion intense de plusieurs heures suivie d’une fatigue aiguë.',
      descriptionAr: 'الاندماج لساعات طويلة في نشاط واحد دون إدراك الوقت ثم الانهيار التام.',
      domain: SymptomDomain.attention,
      relatedCondition: ConditionType.adhd,
    ),
    SymptomEntry(
      id: 'sym_time_blindness',
      titleEn: 'Time Blindness',
      titleFr: 'Difficulté à évaluer le temps',
      titleAr: 'عمى الإحساس بالوقت',
      descriptionEn: 'Underestimating how long activities take, leading to missed anchors and hurry.',
      descriptionFr: 'Mauvaise estimation de l’écoulement du temps entraînant précipitation.',
      descriptionAr: 'صعوبة تقدير مرور الوقت مما يسبب ضغطاً مفاجئاً وتأخراً غير مقصود.',
      domain: SymptomDomain.attention,
      relatedCondition: ConditionType.attentionDifficulties,
    ),

    // -------------------------------------------------------------------------
    // 5. Somatic & Body (Sleep, Physical Tension)
    // -------------------------------------------------------------------------
    SymptomEntry(
      id: 'sym_sleep_latency',
      titleEn: 'Prolonged Sleep Latency (Insomnia)',
      titleFr: 'Difficulté d’endormissement',
      titleAr: 'أرق وصعوبة استجلاب النوم',
      descriptionEn: 'Lying awake in bed with an active mind for over an hour before drifting off.',
      descriptionFr: 'Rester éveillé plus d’une heure avec l’esprit qui tourne avant de dormir.',
      descriptionAr: 'البقاء مستيقظاً في السرير لأكثر من ساعة مع عقل نشط قبل التمكن من النوم.',
      domain: SymptomDomain.somatic,
      relatedCondition: ConditionType.sleepDifficulties,
    ),
    SymptomEntry(
      id: 'sym_morning_grogginess',
      titleEn: 'Morning Exhaustion & Unrefreshing Sleep',
      titleFr: 'Réveil non réparateur',
      titleAr: 'نوم غير مريح وإرهاق صباحي',
      descriptionEn: 'Waking up feeling unrefreshed, heavy, or physically sluggish.',
      descriptionFr: 'Se réveiller lourd et fatigué comme si la nuit n’avait pas suffi.',
      descriptionAr: 'الاستيقاظ بشعور بالإنهاك وثقل في البدن وكأن النوم لم يجدد الطاقة.',
      domain: SymptomDomain.somatic,
      relatedCondition: ConditionType.sleepDifficulties,
    ),
    SymptomEntry(
      id: 'sym_jaw_neck_clenching',
      titleEn: 'Jaw, Neck or Shoulder Tension',
      titleFr: 'Tension mâchoire, nuque ou épaules',
      titleAr: 'شد في الفك، الرقبة، أو الأكتاف',
      descriptionEn: 'Unconscious physical clenching and stiffness in the upper body and jaw.',
      descriptionFr: 'Crispation musculaire inconsciente de la nuque ou serrement des dents.',
      descriptionAr: 'شد عضلي غير واعي في منطقة الفك أو الرقبة والكتفين نتيجة الضغط.',
      domain: SymptomDomain.somatic,
      relatedCondition: ConditionType.generalizedAnxiety,
    ),
    SymptomEntry(
      id: 'sym_gut_churning',
      titleEn: 'Gastrointestinal Distress / Gut Knots',
      titleFr: 'Nœud à l’estomac ou gêne digestive',
      titleAr: 'اضطراب وعقد في المعدة',
      descriptionEn: 'Physical butterflies, churning, or nausea closely following emotional tension.',
      descriptionFr: 'Inconfort digestif et crampes d’estomac liés aux pics de stress.',
      descriptionAr: 'شعور بالانقباض، الغثيان، أو الاضطراب في البطن بالتزامن مع التوتر.',
      domain: SymptomDomain.somatic,
      relatedCondition: ConditionType.generalizedAnxiety,
    ),

    // -------------------------------------------------------------------------
    // 6. Stress & Trauma (Dissociation, Overload)
    // -------------------------------------------------------------------------
    SymptomEntry(
      id: 'sym_sensory_overload',
      titleEn: 'Sensory Overload',
      titleFr: 'Surcharge sensorielle',
      titleAr: 'إجهاد وتحسس حسي مفرط',
      descriptionEn: 'Everyday lights, background chatter, or sounds feel overwhelmingly sharp and irritating.',
      descriptionFr: 'Bruits et lumières du quotidien perçus comme agressifs et insupportables.',
      descriptionAr: 'الأصوات المحيطة والإضاءة تبدو حادة ومزعجة للغاية وتستنزف الطاقة سريعاً.',
      domain: SymptomDomain.stress,
      relatedCondition: ConditionType.sensoryDifficulties,
    ),
    SymptomEntry(
      id: 'sym_dissociative_fog',
      titleEn: 'Emotional Numbing / Detachment',
      titleFr: 'Engourdissement émotionnel / Détachement',
      titleAr: 'تخدر شعوري وانفصال عن الواقع',
      descriptionEn: 'Feeling like an observer of your own life, disconnected from real emotions.',
      descriptionFr: 'Sensation d’être spectateur de sa propre vie, émotionnellement déconnecté.',
      descriptionAr: 'شعور بالانفصال وكأنك تراقب نفسك من بعيد مع خمول في الاستجابة الشعورية.',
      domain: SymptomDomain.stress,
      relatedCondition: ConditionType.dissociativeExperiences,
    ),
    SymptomEntry(
      id: 'sym_startle_reactivity',
      titleEn: 'Exaggerated Startle Response',
      titleFr: 'Réaction de sursaut exagérée',
      titleAr: 'ردة فعل فزع مفرطة للأصوات',
      descriptionEn: 'Strong physical jumping or heart jump in response to sudden everyday sounds.',
      descriptionFr: 'Sursauter brutalement au moindre bruit ou mouvement inattendu.',
      descriptionAr: 'انتفاض البدن وتسارع ضربات القلب عند سماع أي صوت مفاجئ حتى لو كان بسيطاً.',
      domain: SymptomDomain.stress,
      relatedCondition: ConditionType.ptsd,
    ),
  ];
}

