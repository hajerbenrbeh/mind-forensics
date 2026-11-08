import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/investigation/domain/label_type.dart';
import '../../features/journey/domain/journey_phase.dart';
import '../../features/profile/domain/condition_type.dart';
import '../../features/profile/domain/diagnostic_status.dart';
import 'locale_controller.dart';

/// Central type-safe medical & cognitive neuropsychological dictionary for Mind Forensics.
///
/// Supports English ('en'), Français médical ('fr'), and authentic Tunisian Arabic ('ar').
class AppStrings {
  final String languageCode;

  const AppStrings(this.languageCode);

  bool get isArabic => languageCode == 'ar';
  bool get isFrench => languageCode == 'fr';

  // Navigation (4 Primary Destinations: Home, Investigator, Toolkit, Profile)
  String get navHome => isArabic ? 'الرئيسية' : (isFrench ? 'Accueil' : 'Home');
  String get navTrack => isArabic ? 'تتبّع' : (isFrench ? 'Observer' : 'Track');
  String get navCompanion => isArabic ? 'الرفيق الذكي' : (isFrench ? 'Compagnon IA' : 'AI Companion');
  String get navInsights => isArabic ? 'التحليلات' : (isFrench ? 'Analyses' : 'Insights');
  String get navProfile => isArabic ? 'الملف الشخصي' : (isFrench ? 'Profil' : 'Profile');

  // Backward compatibility tab aliases
  String get navJournal => isArabic ? 'السجل' : (isFrench ? 'Journal' : 'Journal');
  String get navInvestigator => isArabic ? 'المحقق' : (isFrench ? 'Enquêteur' : 'Investigator');
  String get navToolkit => isArabic ? 'صندوق الأدوات' : (isFrench ? 'Boîte à outils' : 'Toolkit');
  String get navCases => navJournal;
  String get navTools => navToolkit;
  String get navSettings => navProfile;
  String get newInvestigation => isArabic ? 'تفكيك معرفي جديد' : (isFrench ? 'Nouveau Recadrage' : 'New Deconstruction');

  // Memory Vault
  String get memoryVaultTitle => isArabic ? 'خزينة الذاكرة' : (isFrench ? 'Coffre de mémoire' : 'Memory Vault');
  String get memoryVaultDesc => isArabic
      ? 'عرض ومراجعة المعلومات التي يتذكرها المساعد الذكي عنك'
      : (isFrench ? 'Consulter et gérer les éléments mémorisés par le compagnon IA' : 'Review and manage what the AI companion remembers');

  // Track & Self-Observation Hub
  String get trackHubTitle => isArabic ? 'مساحة الملاحظة والتتبّع' : (isFrench ? 'Espace d’auto-observation' : 'Self-Observation & Tracking');
  String get trackHubSubtitle => isArabic ? 'سجل حالتك الشعورية، النوم، الطاقة، وأفكارك بكل سهولة' : (isFrench ? 'Observez vos émotions, sommeil, énergie et pensées sans friction' : 'Track mood, sleep, energy, thoughts, and symptoms with ease');
  String get quickCheckInTab => isArabic ? 'تسجيل سريع' : (isFrench ? 'Bilan rapide' : 'Quick Check-in');
  String get fullObservationTab => isArabic ? 'ملاحظة مفصلة' : (isFrench ? 'Observation complète' : 'Detailed Trace');
  String get traceHistoryTab => isArabic ? 'السجل الزمني' : (isFrench ? 'Historique' : 'Trace History');
  String get historyTab => traceHistoryTab;
  String get journalTab => traceHistoryTab;
  String get sleepTrackingLabel => isArabic ? 'ساعات النوم' : (isFrench ? 'Heures de sommeil' : 'Sleep Duration');
  String get energyTrackingLabel => isArabic ? 'مستوى الطاقة' : (isFrench ? 'Niveau d’énergie' : 'Energy Level');
  String get anxietyTrackingLabel => isArabic ? 'مستوى التوتر والقلق' : (isFrench ? 'Niveau d’anxiété / tension' : 'Stress & Anxiety');
  String get trackingTriggersLabel => isArabic ? 'المحفزات والظروف المحيطة' : (isFrench ? 'Facteurs déclencheurs' : 'Triggers & Context');
  String get medicationLabel => isArabic ? 'الأدوية الموصوفة' : (isFrench ? 'Médication' : 'Medication');
  String get medicationTakenPrompt => isArabic ? 'هل تناولت علاجك اليوم؟' : (isFrench ? 'Traitements pris aujourd’hui ?' : 'Prescribed medication taken today?');

  // Baseline & Pattern Awareness
  String get personalBaselineTitle => isArabic ? 'خط الأساس الشخصي' : (isFrench ? 'Ligne de base personnelle' : 'Personal Baseline');
  String get patternAwarenessTitle => isArabic ? 'ملاحظات الأنماط والتغيرات' : (isFrench ? 'Observations des schémas' : 'Pattern Awareness');
  String get baselineNeedsMoreData => isArabic ? 'يتطلب خط الأساس 3 أيام على الأقل من التسجيل للبدء' : (isFrench ? 'Au moins 3 jours d’observation nécessaires' : 'At least 3 observation days needed to establish your baseline');
  String get weeklySummaryTitle => isArabic ? 'الملخص الأسبوعي للمختص' : (isFrench ? 'Synthèse hebdomadaire' : 'Weekly Summary for Therapist');
  String get exportSummaryButton => isArabic ? 'تصدير التقرير للمختص' : (isFrench ? 'Exporter la synthèse' : 'Export Therapist Report');
  String get recognizeChangePrompt => isArabic ? 'هل تلاحظ هذا التغير في روتينك أو حالتك الجسدية؟' : (isFrench ? 'Reconnaissez-vous ce changement dans votre quotidien ?' : 'Do you recognize this change in your routine or physical state?');
  String get reviewSupportPlan => isArabic ? 'مراجعة خطة الدعم الشخصية' : (isFrench ? 'Consulter le plan de soutien' : 'Review Personal Support Plan');

  // Daily Check-in & Notes (Step 6)
  String get dailyCheckInTitle => isArabic ? 'التقييم اليومي' : (isFrench ? 'Bilan quotidien' : 'Daily Check-in');
  String get todaysNoteLabel => isArabic ? 'ملاحظة اليوم (اختياري)' : (isFrench ? 'Note du jour (facultatif)' : "Today's note (optional)");
  String get todaysNoteHint => isArabic ? 'شنوة صار اليوم؟ دوّن باختصار...' : (isFrench ? 'Que s’est-il passé aujourd’hui ?' : 'What happened today? Briefly note...');
  String get lastMoodLabel => isArabic ? 'آخر حالة مسجلة' : (isFrench ? 'Dernier état' : 'Last Mood');
  String get saveCheckInButton => isArabic ? 'تسجيل التقييم اليومي' : (isFrench ? 'Enregistrer le bilan' : 'Log Daily Check-in');
  String get checkInSavedSnackbar => isArabic ? 'تم تسجيل التقييم وملاحظة اليوم بنجاح' : (isFrench ? 'Bilan et note enregistrés' : 'Daily check-in and note saved');
  String get toolkitPlaceholderV1 => isArabic ? 'صندوق الأدوات (نموذج v1)' : (isFrench ? 'Boîte à outils (v1 Réservé)' : 'Toolkit (v1 Placeholder)');
  String get toolkitV2Notice => isArabic 
      ? 'تمارين الاسترخاء واليقظة الذهنية، وسجل النوم، ومخطط الأنشطة ستتوفر بالكامل في الإصدار الثاني v2.' 
      : (isFrench ? 'Exercices de relaxation, journal de sommeil et planification comportementale arriveront en v2.' : 'Short mindfulness exercises, sleep hygiene diary, and behavioral activity planner arrive in v2.');

  // Greetings & Home
  String get greetingMorning => isArabic ? 'صباح الخير' : (isFrench ? 'Bonjour' : 'Good morning');
  String get greetingAfternoon => isArabic ? 'مساء الخير' : (isFrench ? 'Bon après-midi' : 'Good afternoon');
  String get greetingEvening => isArabic ? 'مساء النور' : (isFrench ? 'Bonsoir' : 'Good evening');
  String dearUserGreeting(String name) => isArabic
      ? 'عزيزي $name،'
      : (isFrench ? 'Cher(e) $name,' : 'Dear $name,');
  String get timeSwitcherMonth => isArabic ? 'شهر' : (isFrench ? 'Mois' : 'Month');
  String get timeSwitcherWeek => isArabic ? 'أسبوع' : (isFrench ? 'Semaine' : 'Week');
  String get timeSwitcherDay => isArabic ? 'يوم' : (isFrench ? 'Jour' : 'Day');
  String get exercisesForYou => isArabic ? 'تمارين مقترحة لك' : (isFrench ? 'Exercices pour vous' : 'Exercises for you');
  String get relieveStress => isArabic ? 'تخفيف التوتر' : (isFrench ? 'Soulager le stress' : 'Relieve stress');
  String get breathingPractice => isArabic ? 'تمرين التنفس المبهمي' : (isFrench ? 'Pratique respiratoire' : 'Breathing practice');
  String get duration5Min => isArabic ? '5 دقائق' : (isFrench ? '5 min' : '5 min');
  String get lastWeekLabel => isArabic ? 'الأسبوع الماضي' : (isFrench ? 'Semaine passée' : 'Last week');
  String get moodStable => isArabic ? 'مزاج مستقر' : (isFrench ? 'Humeur stable' : 'Mood stable');
  String get moodUnstable => isArabic ? 'تذبذب مزاجي' : (isFrench ? 'Humeur fluctuante' : 'Mood unstable');
  String get avgStressLevel => isArabic ? 'متوسط مستوى التوتر' : (isFrench ? 'Niveau de stress moyen' : 'Average stress level');
  String get inAWeek => isArabic ? 'خلال أسبوع' : (isFrench ? 'en une semaine' : 'in a week');
  String get calibratingBaseline => isArabic ? 'معايرة خط الأساس' : (isFrench ? 'Calibration du repère' : 'Calibrating baseline');
  String get needsTwoEntries => isArabic ? 'يتطلب تسجيلين على الأقل' : (isFrench ? 'Nécessite 2 entrées' : 'Needs 2+ entries');
  String get noEntriesThisWeek => isArabic ? 'لا توجد تسجيلات' : (isFrench ? 'Aucune entrée' : 'No entries yet');
  String get updateCheckInButton => isArabic ? 'تحديث تقييم اليوم' : (isFrench ? 'Mettre à jour' : 'Update Check-in');
  String get todayCheckInRecorded => isArabic ? 'تم توثيق تقييم اليوم' : (isFrench ? 'Entrée du jour enregistrée' : 'Today\'s check-in recorded');
  String get homeQuestion => isArabic 
      ? 'شنوة الفكرة ولا التوتر اللي تحب تفككو توا؟' 
      : (isFrench ? 'Quel schéma cognitif souhaitez-vous déconstruire ?' : 'What cognitive loop would you like to deconstruct?');

  // Dashboard Sections
  String get activeCaseSection => isArabic ? 'الجلسة النشطة' : (isFrench ? 'SESSION EN COURS' : 'ACTIVE SESSION');
  String get mindsetPulseSection => isArabic ? 'مؤشر الاستثارة العصبية' : (isFrench ? 'ÉTAT DU SYSTÈME NERVEUX' : 'NEURAL AROUSAL PULSE');
  String get recentCasesSection => isArabic ? 'سجل الجلسات المعرفية' : (isFrench ? 'SESSIONS RÉCENTES' : 'RECENT SESSIONS');
  String get viewAll => isArabic ? 'عرض الأرشيف' : (isFrench ? 'Voir tout' : 'View All');
  String get startInvestigation => isArabic ? 'بدء تفكيك فكري سريع' : (isFrench ? 'Déconstruction Cognitive' : 'Cognitive Deconstruction');
  String get startInvestigationSub => isArabic 
      ? 'تفكيك فوري للأفكار التلقائية والتشنج الجسدي في 60 ثانية' 
      : (isFrench ? 'Désamorcez les distorsions cognitives et sensations somatiques en 60 secondes' : 'De-escalate cognitive distortions and somatic arousal in 60 seconds');
  String get resumeInvestigation => isArabic ? 'مواصلة الجلسة' : (isFrench ? 'Reprendre la session' : 'Resume Session');
  String get noCasesOnFile => isArabic ? 'لا توجد جلسات مسجلة. اضغط + للبدء.' : (isFrench ? 'AUCUNE SESSION. APPUYEZ SUR + POUR COMMENCER.' : 'NO SESSIONS ON FILE. TAP + TO BEGIN.');
  String stageNumberLabel(int step) => isArabic ? 'المرحلة $step/6' : (isFrench ? 'PHASE $step/6' : 'PHASE $step/6');
  String get inProgressLabel => isArabic ? 'قيد المعالجة' : (isFrench ? 'EN COURS' : 'IN PROGRESS');
  String get quickTriageLabel => isArabic ? 'فرز سريع 60 ثانية' : (isFrench ? 'TRIAGE RAPIDE 60s' : '60s QUICK TRIAGE');
  String get groundedAnchorTag => isArabic ? 'مرسى التعافي' : (isFrench ? 'ANCRAGE RECADRÉ' : 'GROUNDED ANCHOR');

  // Moods & Somatic States
  String get moodCalm => isArabic ? 'متزن (Parasympathique)' : (isFrench ? 'Régulé' : 'Regulated');
  String get moodAnxious => isArabic ? 'استثارة قلقة' : (isFrench ? 'Anxieux' : 'Hyperaroused');
  String get moodFrustrated => isArabic ? 'احتقان / غضب' : (isFrench ? 'Réactif' : 'Reactive');
  String get moodHeavy => isArabic ? 'هبوط طاقي / تثبيط' : (isFrench ? 'Inhibé' : 'Dorsal Vagal');
  String get moodRestless => isArabic ? 'تشتت ذهني' : (isFrench ? 'Agité' : 'Restless');
  String get moodIntensityLabel => isArabic ? 'شدة التوتر العصبي' : (isFrench ? 'Intensité d’activation' : 'Nervous Activation');

  // Daily Cognitive Insight
  String get dailyInsightTitle => isArabic ? 'ملاحظة علم الأعصاب الإدراكي' : (isFrench ? 'Éclairage Neuro-Cognitif' : 'Neuro-Cognitive Insight');
  String get dailyInsightBody => isArabic
      ? 'الجهاز العصبي يطلق إشارات الخطر قبل ما الفكرة الواعية تتشكل. وقت تفصل بين الإحساس الجسدي والتأويل الفكري، ترجعلك السيطرة على مساراتك العصبية.'
      : (isFrench
          ? 'Le système limbique déclenche l’alerte avant la pensée consciente. Séparer l’activation somatique de l’interprétation mentale restaure la régulation préfrontale.'
          : 'The nervous system sounds alarms before conscious thoughts form. Separating somatic body activation from mental narrative restores prefrontal regulation.');

  // Clinical Epistemic Labels
  String get labelFact => isArabic ? 'حقيقة مثبتة' : (isFrench ? 'Fait Objectif' : 'Objective Fact');
  String get labelAssumption => isArabic ? 'فرضية غير مؤكدة' : (isFrench ? 'Hypothèse' : 'Unverified Assumption');
  String get labelInterpretation => isArabic ? 'تأويل ذاتي' : (isFrench ? 'Interprétation' : 'Subjective Interpretation');

  String localizedLabelName(LabelType label) {
    switch (label) {
      case LabelType.fact:
        return labelFact;
      case LabelType.assumption:
        return labelAssumption;
      case LabelType.interpretation:
        return labelInterpretation;
    }
  }

  // Interactive Catalysts (1-Tap Triggers)
  String get catalystUnanswered => isArabic ? 'رسالة بدون رد' : (isFrench ? 'Message sans réponse' : 'Unanswered Message');
  String get catalystCritique => isArabic ? 'ملاحظة / تقييم مهني' : (isFrench ? 'Critique ou évaluation' : 'Work Evaluation / Critique');
  String get catalystComparison => isArabic ? 'مقارنة اجتماعية' : (isFrench ? 'Comparaison sociale' : 'Social Comparison');
  String get catalystImposter => isArabic ? 'شك في الكفاءة (Imposteur)' : (isFrench ? 'Syndrome de l’imposteur' : 'Imposter Doubt');
  String get catalystConflict => isArabic ? 'توتر في العلاقة' : (isFrench ? 'Tension relationnelle' : 'Interpersonal Friction');
  String get catalystExclusion => isArabic ? 'إحساس بالإقصاء' : (isFrench ? 'Sentiment d’exclusion' : 'Excluded / Left Out');
  String get catalystOverload => isArabic ? 'تراكم المسؤوليات' : (isFrench ? 'Surcharge mentale' : 'Cognitive Overload');
  String get catalystUncertainty => isArabic ? 'مستقبل غامض' : (isFrench ? 'Incertitude future' : 'Ambiguous Future');

  // Somatic Sensations (Body State Radar)
  String get somaticChest => isArabic ? 'ضيق بالصدر' : (isFrench ? 'Oppression thoracique' : 'Chest Constriction');
  String get somaticThroat => isArabic ? 'غصة بالحلق' : (isFrench ? 'Nœud à la gorge' : 'Throat Tightness');
  String get somaticStomach => isArabic ? 'تشنج بالمعدة' : (isFrench ? 'Nœud à l’estomac' : 'Gastric Knot');
  String get somaticHeart => isArabic ? 'تسارع نبضات القلب' : (isFrench ? 'Palpitations' : 'Racing Heartbeat');
  String get somaticJaw => isArabic ? 'ضغط الفك والرقبة' : (isFrench ? 'Mâchoire crispée' : 'Clenched Jaw / Neck');
  String get somaticHeavy => isArabic ? 'ثقل وإرهاق عام' : (isFrench ? 'Lourdeur léthargique' : 'Heavy Fatigue');

  // Cognitive Distortions
  String get distortionMindReading => isArabic ? 'قراءة الأفكار (Mind Reading)' : (isFrench ? 'Lecture de pensée' : 'Mind Reading');
  String get distortionCatastrophizing => isArabic ? 'التضخيم الكارثي (Catastrophizing)' : (isFrench ? 'Scénario catastrophe' : 'Catastrophizing');
  String get distortionAllOrNothing => isArabic ? 'الكل أو لا شيء (All-or-Nothing)' : (isFrench ? 'Pensée dichotomique' : 'All-or-Nothing');
  String get distortionPersonalization => isArabic ? 'الشخصنة (Personalization)' : (isFrench ? 'Personnalisation excessive' : 'Personalization');

  // Fast Socratic Micro-Toggles
  String get socraticCameraCheck => isArabic ? '1. إمكانية الإثبات المادي:' : (isFrench ? '1. Vérifiabilité empirique :' : '1. Empirical Verifiability:');
  String get socraticCameraTrue => isArabic ? 'ملموس بالكاميرا' : (isFrench ? 'Observable / Prouvé' : 'Verifiable Reality');
  String get socraticCameraFalse => isArabic ? 'سيناريو ذهني داخلي' : (isFrench ? 'Projection interne' : 'Internal Narrative');
  String get socraticTimeHorizon => isArabic ? '2. الأثر الزمني بعد 6 أشهر:' : (isFrench ? '2. Impact à 6 mois :' : '2. 6-Month Time Horizon:');
  String get socraticTimeLow => isArabic ? 'دون أي أثر حقيقي' : (isFrench ? 'Bruit éphémère (nul)' : 'Zero Long-Term Impact');
  String get socraticTimeHigh => isArabic ? 'أثر دائم وملموس' : (isFrench ? 'Impact durable' : 'Permanent Impact');
  String get socraticProbability => isArabic ? '3. الاحتمال الإحصائي للسيناريو الأسوأ:' : (isFrench ? '3. Probabilité réelle du pire :' : '3. Catastrophe Probability:');
  String get socraticProbLow => isArabic ? 'احتمال ضئيل (<15%)' : (isFrench ? 'Très faible (<15%)' : 'Highly Unlikely (<15%)');
  String get socraticProbHigh => isArabic ? 'شبه مؤكد (>80%)' : (isFrench ? 'Quasi certain (>80%)' : 'High Likelihood (>80%)');

  // 1-Tap Adaptive Reframes
  String get adoptReframeBtn => isArabic ? 'اعتماد هذا التوجيه الذهني' : (isFrench ? 'Adopter ce recadrage' : 'ADOPT THIS REFRAME');
  String get reframeAdoptedSnackbar => isArabic ? 'تم تثبيت إعادة التوجيه المعرفي بنجاح.' : (isFrench ? 'Recadrage adaptatif ancré avec succès.' : 'Adaptive reframe successfully anchored.');
  String get reframe1Title => isArabic ? 'تفكيك الشخصنة (De-personalization)' : (isFrench ? 'Désattribution personnelle' : 'De-Personalization Anchor');
  String get reframe1Body => isArabic 
      ? 'سلوك الطرف الآخر يعكس ظروفه، ضغطه، أو طاقته اللحظية، ولا يحدد قيمتي أو كفاءتي.'
      : (isFrench ? 'Le comportement d’autrui reflète ses propres contraintes et sa charge mentale, non ma valeur intrinsèque.' : 'Their reaction reflects their internal bandwidth and circumstances, not my intrinsic worth or competence.');
  String get reframe2Title => isArabic ? 'تعليق الحكم حتى ثبوت الدليل (Cognitive Pause)' : (isFrench ? 'Suspension du jugement' : 'Empirical Data Hold');
  String get reframe2Body => isArabic
      ? 'أنا أتفاعل مع فراغ في البيانات. سأتوقف عن نسج السيناريوهات حتى تتوفر حقائق واضحة.'
      : (isFrench ? 'Je réagis à un vide informationnel. Je suspends toute alarme tant que les données réelles manquent.' : 'I am reacting to a data void. I choose to withhold panic until verifiable facts emerge.');
  String get reframe3Title => isArabic ? 'تهدئة التنبيه الجسدي (Somatic Safety)' : (isFrench ? 'Sécurité neuro-somatique' : 'Somatic Safety Anchor');
  String get reframe3Body => isArabic
      ? 'جهازي العصبي أطلق إنذاراً كاذباً للحماية. جسدي آمن في هذه اللحظة، ولا يوجد خطر حقيقي.'
      : (isFrench ? 'Mon système nerveux a sonné une fausse alerte par réflexe. Mon corps est en sécurité ici et maintenant.' : 'My sympathetic nervous system fired a false alarm. My physical body is safe here and now.');

  // Tools
  String get toolsTitle => isArabic ? 'مخبر التنظيم العصبي' : (isFrench ? 'Lab de Régulation Neuro' : 'Neuro Regulation Lab');
  String get labelMasterTitle => isArabic ? 'تمرين الفرز المعرفي' : (isFrench ? 'Triage Cognitif Rapide' : 'Cognitive Triage Drill');
  String get labelMasterDesc => isArabic ? 'تدريب سريع لفصل الإشارات الواقعية عن التشويش الذهني' : (isFrench ? 'Entraînement réflexe pour séparer faits et biais' : 'Rapid reflex drill to separate empirical facts from cognitive noise');
  String get breathingTitle => isArabic ? 'تنظيم العصب الحائر (4-4-4-4)' : (isFrench ? 'Régulation Vagale (4-4-4-4)' : 'Vagal Box Pacing (4-4-4-4)');
  String get breathingDesc => isArabic ? 'تثبيط فوري لنشاط الجهاز العصبي الودي في 3 دقائق' : (isFrench ? 'Désactivation immédiate de l’hyperarousal sympathique' : 'Immediate downregulation of sympathetic hyperarousal');
  String get breatheIn => isArabic ? 'شهيق عميق...' : (isFrench ? 'Inspiration...' : 'Inhale deeply...');
  String get breatheHold => isArabic ? 'حبس النفس...' : (isFrench ? 'Rétention...' : 'Hold...');
  String get breatheOut => isArabic ? 'زفير بطيء...' : (isFrench ? 'Expiration...' : 'Exhale slowly...');
  String get breatheRest => isArabic ? 'استقرار...' : (isFrench ? 'Pause...' : 'Rest...');
  String get tunisianHotlinesTitle => isArabic ? 'خطوط الدعم النفسي والطوارئ في تونس' : (isFrench ? 'Lignes de Crise & Urgences (Tunisie)' : 'Clinical Crisis & Emergency Hub');
  String get tunisianHotlinesDesc => isArabic ? 'دعم طبي ونفسي مجاني وسري 24/7' : (isFrench ? 'Assistance médicale et psychiatrique confidentielle' : 'Free confidential psychiatric & emergency support');
  String drillCounter(int current, int total) => isArabic ? 'تمرين $current/$total' : (isFrench ? 'EXERCICE $current/$total' : 'DRILL $current/$total');
  String get nextDrill => isArabic ? 'التمرين الموالي' : (isFrench ? 'SUIVANT' : 'NEXT DRILL');
  String get startPacer => isArabic ? 'تفعيل إيقاع التنظيم (4-4-4-4)' : (isFrench ? 'ACTIVER LE RYTHMEUR' : 'ACTIVATE PACER (4-4-4-4)');
  String get stopPacer => isArabic ? 'إيقاف الإيقاع' : (isFrench ? 'ARRÊTER LE RYTHMEUR' : 'STOP PACER');
  String get pacerSub => isArabic ? '4 ثواني شهيق • 4 حبس • 4 زفير • 4 استقرار' : (isFrench ? '4s Inspiration • 4s Rétention • 4s Expiration • 4s Pause' : '4s Inhale • 4s Hold • 4s Exhale • 4s Rest');

  // Settings
  String get settingsTitle => isArabic ? 'إعدادات المنظومة' : (isFrench ? 'Paramètres Cliniques' : 'Clinical Settings');
  String get themeModeTitle => isArabic ? 'بيئة الإضاءة البصرية' : (isFrench ? 'Environnement Visuel' : 'Visual Environment');
  String get themeDaylight => isArabic ? 'نهاري' : (isFrench ? 'Jour' : 'Daylight');
  String get themeNight => isArabic ? 'ليلي عالي التباين' : (isFrench ? 'Sombre OLED' : 'OLED Dark');
  String get themeSystem => isArabic ? 'النظام' : (isFrench ? 'Système' : 'System');
  String get languageTitle => isArabic ? 'لغة المنظومة' : (isFrench ? 'Langue clinique' : 'Clinical Language');
  String get aiHistoryTitle => isArabic ? 'سياق الأنماط المعرفية التراكمية' : (isFrench ? 'Mémoire des schémas cognitifs' : 'Cognitive Pattern Memory');
  String get aiHistoryDesc => isArabic ? 'تضمين الجلسات السابقة لرصد الأنماط المتكررة بدقة' : (isFrench ? 'Croiser les sessions pour détecter les schémas récurrents' : 'Cross-reference sessions to identify recurring cognitive schemas');
  String get biometricLockTitle => isArabic ? 'قفل الأمان البيومتري' : (isFrench ? 'Verrouillage biométrique' : 'Biometric Security');
  String get biometricLockDesc => isArabic ? 'المصادقة بالبصمة لحماية سرية السجلات المعرفية' : (isFrench ? 'Empreinte requise pour accéder aux dossiers cliniques' : 'Require biometrics to access sensitive cognitive records');
  String get biometricVaultLockedTitle => isArabic ? 'سجل الجلسات مقفل' : (isFrench ? 'DOSSIERS SÉCURISÉS' : 'SESSION VAULT LOCKED');
  String get biometricVaultLockedDesc => isArabic 
      ? 'يلزم التحقق بالبصمة للوصول إلى سجلات وتفكيكات أفكارك الخاصة.' 
      : (isFrench ? 'Authentification requise pour déverrouiller vos dossiers de déconstruction.' : 'Biometric authentication required to access your private cognitive session records.');
  String get unlockWithBiometricsBtn => isArabic ? 'فتح القفل بالبصمة' : (isFrench ? 'DÉVERROUILLER' : 'UNLOCK VAULT');
  String get biometricFailedSnackbar => isArabic ? 'فشلت المصادقة البيومترية' : (isFrench ? 'Échec de l’authentification' : 'Biometric authentication failed');
  String get biometricNotAvailableSnackbar => isArabic ? 'البصمة غير متوفرة في هذا الجهاز' : (isFrench ? 'Biométrie non disponible' : 'Biometrics not available on this device');
  // Cloud Sync (Firebase Spark Plan - Step 11)
  String get cloudSyncTitle => isArabic ? 'المزامنة السحابية (خطة Spark)' : (isFrench ? 'Synchronisation Cloud (Spark)' : 'Cloud Sync (Firebase Spark)');
  String get cloudSyncDesc => isArabic 
      ? 'نسخ احتياطي مشفر ومتوافق مع خطة Firebase Spark بدون فوترة (\$0.00)' 
      : (isFrench ? 'Sauvegarde chiffrée sur forfait Spark sans facturation (\$0.00)' : 'Encrypted backup on Firebase Spark plan with zero billing linked (\$0.00)');
  String get exportVaultBtn => isArabic ? 'تصدير نسخة كاملة (JSON)' : (isFrench ? 'Exporter Sauvegarde (JSON)' : 'Export Full Vault (JSON)');
  String get exportVaultSuccess => isArabic ? 'تم نسخ النسخة الكاملة إلى الحافظة' : (isFrench ? 'Sauvegarde complète copiée' : 'Full vault backup copied to clipboard');
  String get sparkPlanBadge => isArabic ? 'خطة SPARK المجانية (\$0.00)' : (isFrench ? 'FORFAIT SPARK (\$0.00)' : 'SPARK FREE TIER (\$0.00)');

  String get wipeDataTitle => isArabic ? 'مسح السجلات نهائياً' : (isFrench ? 'Purger toutes les données' : 'Purge All Records');
  String get wipeDataDesc => isArabic ? 'حذف كافة الجلسات والتحليلات المعرفية المحفوظة على هذا الجهاز' : (isFrench ? 'Suppression irréversible de l’historique des sessions' : 'Irreversibly delete all cognitive history from this device');
  String get dataTransparencyTitle => isArabic ? 'بروتوكول حماية وسرية البيانات' : (isFrench ? 'CONFIDENTIALITÉ & SÉCURITÉ' : 'DATA PRIVACY PROTOCOL');
  String get privacyPrinciplesTitle => isArabic ? 'المعايير السريرية للخصوصية' : (isFrench ? 'Normes de Confidentialité Médicale' : 'Clinical Privacy Standards');
  String get privacyPrinciplesBody => isArabic
      ? '1. تشفير تام لكافة الجلسات محلياً على هاتفك فقط.\n2. لا يتم بيع أو مشاركة أي معطى شخصي مع أطراف ثالثة.\n3. لا يتم تدريب نماذج الذكاء الاصطناعي على بياناتك الخاصة.\n4. استقلالية تامة وملكية مطلقة لكل فكرة تسجلها.'
      : (isFrench
          ? '1. Chiffrement local intégral sur votre appareil.\n2. Aucune donnée n’est partagée, monétisée ou utilisée à des fins tierces.\n3. Vos pensées ne servent jamais à entraîner des modèles IA.\n4. Contrôle absolu et propriété totale de vos enregistrements cognitifs.'
          : '1. Strict local device encryption for all sessions.\n2. Zero data monetization, sharing, or advertising tracking.\n3. Your private thoughts are never used for AI model training.\n4. Complete sovereignty and ownership over every logged record.');
  String get allDataWipedSnackbar => isArabic ? 'تم مسح كافة السجلات المعرفية بنجاح.' : (isFrench ? 'Toutes les données ont été purgées avec succès.' : 'All clinical session records permanently cleared.');

  // Deconstruction Workflow (Clinical Stages)
  String get stageIncident => isArabic ? 'المحفز اللحظي' : (isFrench ? 'Catalyseur' : 'Activating Catalyst');
  String get stageEvidence => isArabic ? 'الحالة الجسدية والفكرية' : (isFrench ? 'État Somatique & Pensée' : 'Neural & Somatic State');
  String get stageHypotheses => isArabic ? 'النماذج التفسيرية' : (isFrench ? 'Modèles Alternatifs' : 'Cognitive Models');
  String get stageCrossExam => isArabic ? 'اختبار الواقع السقراطي' : (isFrench ? 'Test de Réalité' : 'Socratic Reality Test');
  String get stageFindings => isArabic ? 'تشخيص الانحيازات' : (isFrench ? 'Synthèse des Biais' : 'Distortion Diagnosis');
  String get stageVerdict => isArabic ? 'إعادة التوجيه المتزنة' : (isFrench ? 'Recadrage Adaptatif' : 'Adaptive Reframe');

  String stepBadgeText(int step, String stageTitle) =>
      isArabic ? 'المرحلة $step من 6  •  $stageTitle' : (isFrench ? 'PHASE $step SUR 6  •  ${stageTitle.toUpperCase()}' : 'PHASE $step OF 6  •  ${stageTitle.toUpperCase()}');

  String get whatHappenedQuestion => isArabic ? 'شنوة المحفز اللي أثار التوتر؟' : (isFrench ? 'Quel est le stimulus déclencheur ?' : 'What is the activating stimulus?');
  String get incidentHelpText => isArabic 
      ? 'اختر من المحفزات السريعة بنقرة واحدة، أو اكتب جملة توضيحية إذا تحب:'
      : (isFrench ? 'Sélectionnez un déclencheur rapide en 1 tap, ou ajoutez une précision si nécessaire :' : 'Select a catalyst in 1 tap, or write a single brief note if desired:');
  String get incidentHint => isArabic 
      ? 'أو اكتب باختصار: مثلاً شفت الإيميل وحسيت بضغط مفاجئ...' 
      : (isFrench ? 'Ou notez brièvement le contexte...' : 'Or enter optional custom trigger context...');
  String get describeSituationWarning => isArabic ? 'الرجاء اختيار أو كتابة المحفز للمتابعة.' : (isFrench ? 'Veuillez sélectionner un stimulus pour continuer.' : 'Please select or enter a catalyst before proceeding.');
  String get proceedToEvidenceBtn => isArabic ? 'فحص الحالة الجسدية والفكرة' : (isFrench ? 'Analyser l’état somato-cognitif' : 'CONTINUE TO SOMATIC & NEURAL STATE');

  String get mapChainTitle => isArabic ? 'تحديد الاستجابة الجسدية والفكرة' : (isFrench ? 'Cartographie Somatique & Cognitive' : 'Map Somatic & Cognitive Response');
  String get mapChainSub => isArabic 
      ? 'حدد أين استقر التوتر في جسدك وصنف الفكرة التلقائية السريعة:'
      : (isFrench ? 'Localisez la tension corporelle et qualifiez la pensée automatique :' : 'Locate where the body feels it and classify the automatic thought:');
  String get triggerLabel => isArabic ? 'المحفز المختار' : (isFrench ? 'Stimulus identifié' : 'Identified Catalyst');
  String get emotionLabel => isArabic ? 'الإحساس الجسدي / الشعور' : (isFrench ? 'Sensation somatique principale' : 'Primary Somatic / Emotional State');
  String get emotionalIntensityTitle => isArabic ? 'مستوى الاستثارة العصبية' : (isFrench ? 'INTENSITÉ SOMATIQUE' : 'SOMATIC AROUSAL INTENSITY');
  String get behaviorLabel => isArabic ? 'دافع السلوك اللحظي (هروب، تجنب، هجوم)' : (isFrench ? 'Impulsion d’action (fuite, évitement, repli)' : 'Action Impulse (withdraw, avoid, confront)');
  String get classifyThoughtLabel => isArabic ? 'تصنيف الفكرة التلقائية' : (isFrench ? 'CLASSIFICATION ÉPISTÉMIQUE' : 'CLASSIFY THE AUTOMATIC THOUGHT');
  String get examinePerspectivesBtn => isArabic ? 'توليد النماذج التفسيرية البديلة' : (isFrench ? 'Générer les modèles alternatifs' : 'GENERATE ALTERNATIVE MODELS');

  String get warmInvestigatorTitle => isArabic ? 'النماذج الإدراكية البديلة' : (isFrench ? 'Modèles Cognitifs Alternatifs' : 'Alternative Neuro-Cognitive Models');
  String get hypothesesSub => isArabic
      ? 'مسارات عصبية بديلة لتفكيك النظرة الضيقة وتخفيف نشاط مركز الخوف بالمخ.'
      : (isFrench ? 'Perspectives cliniques alternatives pour désamorcer l’hypervigilance de l’amygdale.' : 'Alternative prefrontal cognitive pathways to disarm limbic hypervigilance.');
  String get queryInvestigatorBtn => isArabic ? 'توليد مسارات تفسيرية إضافية' : (isFrench ? 'Générer d’autres hypothèses' : 'Generate Additional Models');
  String get whyItFitsPrefix => isArabic ? 'عوامل التوافق:' : (isFrench ? 'Facteurs concordants :' : 'Congruent evidence:');
  String get whatDoesNotFitPrefix => isArabic ? 'مؤشرات التناقض:' : (isFrench ? 'Facteurs divergents :' : 'Contradictory evidence:');
  String get testAssumptionsBtn => isArabic ? 'إجراء اختبار الواقع السقراطي' : (isFrench ? 'Tester la réalité socratique' : 'RUN SOCRATIC REALITY TEST');

  String get crossExamTitle => isArabic ? 'اختبار الواقع السقراطي السريع' : (isFrench ? 'Test de Réalité Socratique' : 'Socratic Reality Testing');
  String get crossExamSub => isArabic 
      ? 'أجب بنقرة سريعة على الأسئلة الثلاثة لفصل الواقع الحسي عن تهويل المخ:'
      : (isFrench ? 'Répondez rapidement aux 3 curseurs pour isoler les faits des distorsions :' : 'Quickly toggle the 3 reality checks to separate empirical reality from mental projection:');
  String get crossExamQuestion1 => isArabic
      ? '“هل يمكن لكاميرا فيديو محايدة إثبات هذه الفكرة بنسبة 100%؟”'
      : (isFrench ? '« Une caméra externe neutre pourrait-elle prouver cette pensée à 100% ? »' : '“Could a neutral video camera prove this thought 100% true?”');
  String get crossExamQuestion2 => isArabic
      ? '“هل سيكون لهذا الموقف أي أثر فعلي على حياتك بعد 6 أشهر؟”'
      : (isFrench ? '« Cet événement aura-t-il un impact tangible dans 6 mois ? »' : '“Will this event hold any real impact 6 months from now?”');
  String get crossExamQuestion3 => isArabic
      ? '“ما هو الاحتمال الرياضي لحدوث السيناريو الكارثي الذي تخشاه؟”'
      : (isFrench ? '« Quelle est la probabilité statistique réelle du pire scénario ? »' : '“What is the statistical likelihood of your catastrophic fear?”');
  String get synthesizeFindingsBtn => isArabic ? 'عرض تشخيص الانحيازات المعرفية' : (isFrench ? 'Afficher le diagnostic cognitif' : 'SYNTHESIZE DISTORTION DIAGNOSIS');

  String get findingsTitle => isArabic ? 'تشخيص الانحيازات المعرفية' : (isFrench ? 'Diagnostic des Distorsions' : 'Cognitive Distortion Diagnosis');
  String get findingsSub => isArabic 
      ? 'خلاصة الفرز بين الواقع الحسي والانحيازات العصبية التي ضخمت الموقف:'
      : (isFrench ? 'Séparation clinique entre réalité empirique et filtres déformants :' : 'Clinical triage between empirical reality and cognitive distortions:');
  String get fallbackFindingsSummary => isArabic
      ? '• الواقع الحسي الملموس: المنبه الخارجي وقع بشكل عادي دون وجود أي دليل على استهداف مقصود.\n• الانحياز المعرفي المرصود: قفز الجهاز العصبي إلى "قراءة الأفكار" وافتراض الرفض الشخصي لتجنب الصدمة.\n• الاستنتاج السريري: الخطر غير موجود مادياً وإنما تشكل كاستجابة إنذار وهمية داخلية.'
      : (isFrench
          ? '• Réalité empirique : L’événement extérieur s’est produit sans preuve d’intention malveillante.\n• Distorsion identifiée : Glissement automatique vers la "lecture de pensée" et la personnalisation.\n• Synthèse clinique : La menace est purement projective et ne requiert aucune défense active.'
          : '• Empirical Reality: The stimulus occurred without objective evidence of personal hostility.\n• Detected Distortion: The nervous system defaulted to "Mind Reading" and premature catastrophizing.\n• Clinical Assessment: The perceived threat is an internal projection rather than an immediate hazard.');
  String get recordVerdictBtn => isArabic ? 'الانتقال إلى إعادة التوجيه المتزنة' : (isFrench ? 'Passer au recadrage adaptatif' : 'CONTINUE TO ADAPTIVE REFRAME');

  String get verdictTitle => isArabic ? 'إعادة التوجيه المتزنة (Adaptive Reframe)' : (isFrench ? 'Recadrage Adaptatif & Ancrage' : 'Adaptive Reframe & Grounded Anchor');
  String get verdictSub => isArabic 
      ? 'اختر الركيزة المعرفية الأنسب لك واعتمدها بنقرة واحدة لتهدئة الدائرة العصبية:'
      : (isFrench ? 'Sélectionnez le recadrage clinique le plus aidant et ancrez-le en 1 tap :' : 'Select the most empowering clinical reframe and anchor it in 1 tap:');
  String get conclusionHint => isArabic 
      ? 'أو اكتب تعديلك الخاص باختصار شديد...' 
      : (isFrench ? 'Ou notez votre propre recadrage...' : 'Or enter custom personal reframe...');
  String get fileAndArchiveBtn => isArabic ? 'تثبيت وحفظ الجلسة في الأرشيف' : (isFrench ? 'Ancrer & archiver la session' : 'ANCHOR & ARCHIVE SESSION');
  String get caseArchivedSuccess => isArabic ? 'تم تثبيت الجلسة المعرفية وحفظها بنجاح.' : (isFrench ? 'Session cognitive ancrée avec succès.' : 'Cognitive session successfully anchored.');
  String get writeConclusionWarning => isArabic ? 'الرجاء اختيار أو كتابة إعادة التوجيه قبل الحفظ.' : (isFrench ? 'Veuillez sélectionner un recadrage avant d’archiver.' : 'Please select or enter an adaptive reframe before filing.');
  String get previousStepBtn => isArabic ? 'المرحلة السابقة' : (isFrench ? 'PHASE PRÉCÉDENTE' : 'PREVIOUS PHASE');

  /// Formats an internal session identifier (e.g. "SESSION 01" or legacy "CASE 001") into localized display format.
  String formatSessionNumber(String rawNumber) {
    final digitsMatch = RegExp(r'\d+').firstMatch(rawNumber);
    final num = digitsMatch != null ? int.tryParse(digitsMatch.group(0) ?? '') : null;
    final formatted = num != null ? num.toString().padLeft(2, '0') : '01';
    if (isArabic) {
      return 'جلسة $formatted';
    }
    return 'SESSION $formatted';
  }

  // Case Report View
  String get caseReportTitle => isArabic ? 'تقرير الجلسة المعرفية' : (isFrench ? 'Rapport de Session Cognitive' : 'Cognitive Session Report');
  String get caseNotFound => isArabic ? 'الجلسة غير موجودة.' : (isFrench ? 'Session introuvable.' : 'Session record not found.');
  String get editVerdictTitle => isArabic ? 'تعديل إعادة التوجيه' : (isFrench ? 'MODIFIER LE RECADRAGE' : 'EDIT REFRAME');
  String get yourUpdatedTakeaway => isArabic ? 'صيغتك المعدلة...' : (isFrench ? 'Votre recadrage révisé...' : 'Your updated reframe...');
  String get saveVerdictBtn => isArabic ? 'حفظ التعديل' : (isFrench ? 'ENREGISTRER' : 'SAVE REFRAME');
  String get deleteCaseFileTitle => isArabic ? 'حذف سجل الجلسة' : (isFrench ? 'PURGER LA SESSION' : 'PURGE SESSION RECORD');
  String get deleteCase => isArabic ? 'حذف الجلسة' : (isFrench ? 'Supprimer la session' : 'Delete Session');
  String get deleteCaseWarning => isArabic
      ? 'هذا الإجراء نهائي. سيتم حذف جميع بيانات الاستجابة الجسدية والتشخيص المعرفي لهذه الجلسة.'
      : (isFrench ? 'Cette action est irréversible. Toutes les données somatiques et cognitives seront définitivement effacées.' : 'This action is irreversible. All somatic and cognitive data for this session will be permanently purged.');
  String get deletePermanentlyBtn => isArabic ? 'حذف نهائي' : (isFrench ? 'PURGER DÉFINITIVEMENT' : 'PURGE PERMANENTLY');
  String get cancelBtn => isArabic ? 'إلغاء' : (isFrench ? 'Annuler' : 'Cancel');
  String get incidentNarrativeHeader => isArabic ? '1. المحفز اللحظي (Activating Catalyst)' : (isFrench ? '1. STIMULUS DÉCLENCHEUR' : '1. ACTIVATING CATALYST');
  String get noNarrativeRecorded => isArabic ? 'لم يتم تسجيل محفز.' : (isFrench ? 'Aucun stimulus enregistré.' : 'No stimulus recorded.');
  String get observableChainHeader => isArabic ? '2. الاستجابة الجسدية والفكرية' : (isFrench ? '2. ÉTAT SOMATIQUE & PENSÉE' : '2. SOMATIC & NEURAL RESPONSE');
  String get hypothesesExaminedHeader => isArabic ? '3. النماذج التفسيرية المفحوصة' : (isFrench ? '3. MODÈLES CLINIQUES ALTERNATIFS' : '3. COGNITIVE MODELS EXAMINED');
  String get groundedVerdictHeader => isArabic ? '4. إعادة التوجيه المعتمدة (Adaptive Anchor)' : (isFrench ? '4. RECADRAGE ADAPTATIF ANCRÉ' : '4. ADAPTIVE REFRAME ANCHOR');
  String get finalTakeawayUserHeader => isArabic ? 'الركيزة المعرفية المعتمدة' : (isFrench ? 'RECADRAGE ANCRÉ' : 'ADOPTED REFRAME ANCHOR');
  String get editBtn => isArabic ? 'تعديل' : (isFrench ? 'MODIFIER' : 'EDIT');
  String get noConclusionYet => isArabic ? 'لم يُعتمد توجيه بعد.' : (isFrench ? 'Aucun recadrage ancré pour le moment.' : 'No reframe anchored yet.');
  String emotionTag(String emotion, int intensity) => isArabic ? 'الحالة الجسدية: $emotion (شدة $intensity/10)' : (isFrench ? 'ÉTAT SOMATIQUE : ${emotion.toUpperCase()} ($intensity/10)' : 'SOMATIC STATE: ${emotion.toUpperCase()} ($intensity/10)');
  String get triggerTitle => isArabic ? 'المحفز' : (isFrench ? 'Stimulus' : 'Catalyst');
  String get thoughtTitle => isArabic ? 'الفكرة التلقائية' : (isFrench ? 'Pensée automatique' : 'Automatic Thought');
  String get behaviorTitle => isArabic ? 'دافع السلوك' : (isFrench ? 'Impulsion' : 'Action Impulse');

  // Journal / Vault
  String get noCasesRecordedTitle => isArabic ? 'لا توجد جلسات مسجلة' : (isFrench ? 'AUCUNE SESSION ENREGISTRÉE' : 'NO SESSIONS RECORDED');
  String get noCasesRecordedDesc => isArabic 
      ? 'عندما تشعر بأي استثارة عصبية أو فكرة مقلقة، ابدأ تفكيكاً سريعاً في 60 ثانية لتهدئة الدائرة.'
      : (isFrench ? 'Dès qu’une tension ou pensée automatique surgit, initiez une déconstruction en 60 secondes.' : 'Whenever tension or automatic anxiety arises, launch a 60-second deconstruction.');
  String get emotionHiddenPrivacy => isArabic ? 'البيانات الجسدية مخفية (وضع الخصوصية)' : (isFrench ? 'Données masquées (mode privé)' : 'Somatic state hidden (privacy mode)');
  String feltEmotionSub(String emotion, int intensity) => isArabic ? 'الاستجابة: $emotion • الشدة: $intensity/10' : (isFrench ? 'État : $emotion • Intensité $intensity/10' : 'State: $emotion • Arousal $intensity/10');
  String get showPreviewsTooltip => isArabic ? 'إظهار المعاينة' : (isFrench ? 'Afficher' : 'Show previews');
  String get hidePreviewsTooltip => isArabic ? 'إخفاء المعاينة (خصوصية)' : (isFrench ? 'Masquer (Confidentialité)' : 'Hide previews (Privacy)');

  // Safety & Crisis Dialog / Bottom Sheet
  String get needSupportBtn => isArabic ? 'دعم نفسي وطوارئ' : (isFrench ? 'Lignes d’urgence' : 'Crisis Support');
  String get callBtn => isArabic ? 'اتصال مباشر' : (isFrench ? 'Appeler' : 'CALL');
  String get supportModalTitle => isArabic ? 'Aide & Urgences • الدعم والمساعدة السريرية' : (isFrench ? 'Lignes Cliniques & Urgences' : 'Clinical Support & Emergency');
  String get supportModalSub => isArabic ? 'أرقام النجدة والمساندة النفسية الرسمية في تونس' : (isFrench ? 'Numéros d’urgence officiels en Tunisie' : 'Official emergency hotlines in Tunisia');
  String get supportModalBody => isArabic
      ? 'إذا كنت تعيش في لحظة صعيبة، قلق شديد أو أزمة نفسية، مانكش وحدك. فما مختصين جاهزين يسمعوك ويعاونوك بسرية ومجاناً.'
      : (isFrench
          ? 'Si vous traversez un moment difficile, de grande anxiété ou de crise, vous n’avez pas à porter cela seul(e). Des spécialistes sont disponibles pour vous écouter.'
          : 'If you are experiencing overwhelming distress, severe anxiety, or a crisis, you don’t have to carry this alone. Free, confidential support is available right now.');
  String get crisisPauseTitle => isArabic ? 'وقفة هادئة لتنظيم الجهاز العصبي' : (isFrench ? 'Pause de Régulation Immédiate' : 'Gentle Neuro-Regulation Pause');
  String get crisisPauseBody => isArabic
      ? 'المعطيات تشير إلى استثارة عصبية عالية جداً. في هذه الحالة، التحليل المعرفي يزيد الضغط. الأولوية الآن هي تهدئة الجسد وتوفير الأمان والدعم السريري.'
      : (isFrench
          ? 'Les indicateurs révèlent une hyperarousal aigu. Dans cet état, l’analyse cognitive devient contre-productive. La priorité absolue est la sécurité et le soutien clinique immédiat.'
          : 'Indicators show acute autonomic hyperarousal. In this state, cognitive analysis increases strain. The absolute priority is immediate physiological safety and clinical support.');
  String get greenLineTitle => isArabic ? 'الرقم الأخضر للمساعدة النفسية (تونس)' : (isFrench ? 'Numéro Vert d’Aide Psychologique (Tunisie)' : 'National Mental Health Green Line (Tunisia)');
  String get greenLineSubtitle => isArabic ? '80 10 50 50 • مجاني 24/7' : (isFrench ? '80 10 50 50 • Gratuit 24/7' : '80 10 50 50 • Free 24/7');
  String get returnToCaseBtn => isArabic ? 'الرجوع للجلسة' : (isFrench ? 'Revenir à la session' : 'Return to Session');
  String get viewSupportResourcesBtn => isArabic ? 'أرقام النجدة والمساعدة' : (isFrench ? 'Voir les ressources d’urgence' : 'View Crisis Resources');

  // Onboarding
  String get onboardingSkip => isArabic ? 'تخطي' : (isFrench ? 'PASSER' : 'SKIP');
  String get onboardingEnterLab => isArabic ? 'دخول مخبر التنظيم المعرفي' : (isFrench ? 'ENTRER AU LAB' : 'ENTER NEURO LAB');
  String get onboardingNext => isArabic ? 'الموالي' : (isFrench ? 'SUIVANT' : 'NEXT');

  // Clinical Session Brief & Privacy Shield (Section 12 - Step 12)
  String get casePrivateBadge => isArabic ? 'سري: خاص — غير قابل للمشاركة' : (isFrench ? 'CONFIDENTIEL : PRIVÉ — NON PARTAGEABLE' : 'CONFIDENTIAL: PRIVATE — NEVER SHAREABLE');
  String get caseShareableBadge => isArabic ? 'قابل للتضمين في الملخص السريري' : (isFrench ? 'PARTAGEABLE DANS LE BILAN DE SESSION' : 'SHAREABLE IN SESSION BRIEF');
  String get togglePrivacyTooltip => isArabic ? 'تعديل درع السرية' : (isFrench ? 'Basculer la confidentialité' : 'Toggle Privacy Shield');
  String get privacyShieldTitle => isArabic ? 'درع السرية والخصوصية' : (isFrench ? 'Bouclier de Confidentialité' : 'Privacy & Confidentiality Shield');
  String get caseIsPrivateCannotExport => isArabic
      ? 'هذه الجلسة محمية بدرع السرية. تم استبعادها تلقائياً ولا يمكن تصديرها إلا إذا قمت بإلغاء وضع الخصوصية أولاً.'
      : (isFrench
          ? 'Cette session est protégée par le bouclier de confidentialité. Elle ne peut être exportée sans déverrouillage préalable.'
          : 'This session is protected by your privacy shield and cannot be exported. Unlock privacy first to share.');

  String get exportSessionBriefTitle => isArabic ? 'ملخص الجلسة السريري' : (isFrench ? 'Bilan de Session Clinique' : 'Clinical Session Brief');
  String get sessionBriefExportHeader => isArabic ? 'تصدير ملخص الجلسات للمعالج' : (isFrench ? 'Exporter le Bilan de Session' : 'Export Clinical Session Brief');
  String get sessionBriefSubtitle => isArabic
      ? 'ملخص معرفي منظم بمبادرة شخصية لمناقشته مع طبيبك أو أخصائيك النفسي'
      : (isFrench ? 'Synthèse cognitive structurée pour votre praticien' : 'Structured patient-initiated cognitive summary for clinician collaboration');
  String get exportSelectionMode => isArabic ? 'تحديد الجلسات' : (isFrench ? 'Sélectionner des sessions' : 'Select Sessions');
  String get selectSessionsToExport => isArabic ? 'اختر الجلسات لتضمينها في الملخص' : (isFrench ? 'Choisissez les sessions à inclure' : 'Select sessions to include in brief');
  String sessionsSelectedCount(int count) => isArabic
      ? (count == 1 ? 'جلسة واحدة مختارة' : '$count جلسات مختارة')
      : (isFrench ? '$count session(s) sélectionnée(s)' : '$count session(s) selected');
  String get previewBriefBtn => isArabic ? 'معاينة الملخص السريري' : (isFrench ? 'APERÇU DU BILAN' : 'PREVIEW CLINICAL BRIEF');
  String get copySessionBriefBtn => isArabic ? 'نسخ الملخص السريري للحافظة' : (isFrench ? 'COPIER LE BILAN' : 'COPY CLINICAL BRIEF');
  String get sessionBriefCopiedSuccess => isArabic ? 'تم نسخ الملخص السريري إلى الحافظة بنجاح' : (isFrench ? 'Bilan clinique copié dans le presse-papiers' : 'Clinical session brief copied to clipboard');
  String get recipientOrNoteLabel => isArabic ? 'اسم المعالج / ملاحظة الجلسة (اختياري)' : (isFrench ? 'Praticien / Note de séance (optionnel)' : 'Clinician / Session Note (optional)');
  String get recipientOrNoteHint => isArabic ? 'مثال: د. بن عمار - متابعة الجلسة' : (isFrench ? 'Ex: Dr. Ben Ammar - Suivi' : 'e.g., Dr. Ben Ammar - Session follow-up');
  String privateCasesExcludedNote(int count) => isArabic
      ? (count == 1 ? 'تم استبعاد جلسة واحدة موسومة كخاصة وسرية' : 'تم استبعاد $count جلسات موسومة كخاصة وسرية')
      : (isFrench ? '$count session(s) confidentielle(s) exclue(s)' : '$count private shielded session(s) excluded');
  String get clinicalDisclaimerNotice => isArabic
      ? 'إشعار سريري: Mind Forensics مستوحى من مبادئ العلاج السلوكي المعرفي (CBT). الفرضيات الاستكشافية ليست تشخيصاً نفسياً أو استنتاجاً طبياً.'
      : (isFrench
          ? 'Avis clinique : Mind Forensics est inspiré des approches TCC. Les hypothèses exploratoires ne sont pas des diagnostics médicaux.'
          : 'Clinical Notice: Mind Forensics is inspired by CBT principles. Exploratory hypotheses are not medical diagnoses or clinical findings.');

  // Clinical Sharing History (Principle 5)
  String get clinicalSharingHistoryTitle => isArabic ? 'سجل التصدير والمشاركات السريرية' : (isFrench ? 'Historique des Partages Cliniques' : 'Clinical Sharing History');
  String get clinicalSharingHistoryDesc => isArabic
      ? 'سجل مرئي وتوثيق دقيق لكل ملخص جلسة تم نسخه أو تصديره (لا يتم أي تصدير تلقائي أبداً)'
      : (isFrench ? 'Journal visible de tous les bilans exportés (aucun envoi automatique)' : 'Visible audit log of all exported session briefs (zero automatic sharing)');
  String get noSharingHistoryYet => isArabic ? 'لم يتم تصدير أي ملخص جلسة حتى الآن.' : (isFrench ? 'Aucun bilan partagé pour l’instant.' : 'No clinical briefs have been exported yet.');
  String get clearSharingHistoryBtn => isArabic ? 'مسح سجل المشاركات' : (isFrench ? 'Purger l’historique' : 'Clear Sharing History');
  String get sharingHistoryCleared => isArabic ? 'تم مسح سجل المشاركات بنجاح' : (isFrench ? 'Historique des partages purgé' : 'Clinical sharing history cleared');
  String get closeBtn => isArabic ? 'إغلاق' : (isFrench ? 'Fermer' : 'Close');

  // AI Investigator Engine Settings (Direct Free Gemini API Key)
  String get aiEngineSectionTitle => isArabic ? 'محرك الذكاء الاصطناعي (GEMINI)' : (isFrench ? 'MOTEUR D’IA (GEMINI)' : 'AI INVESTIGATOR ENGINE');
  String get aiEngineSectionDesc => isArabic
      ? 'اربط مفتاح Gemini المجاني للتحليل السريري المباشر أو اعتمد المحاكي الداخلي (\$0.00)'
      : (isFrench
          ? 'Connectez votre clé Gemini gratuite pour l’analyse directe ou utilisez le simulateur local (\$0.00)'
          : 'Connect your free Gemini API key for live analysis or use the local simulator (\$0.00)');
  String get liveGeminiActiveBadge => isArabic ? 'GEMINI FLASH مباشر' : (isFrench ? 'GEMINI FLASH ACTIF' : 'LIVE GEMINI FLASH');
  String get offlineMockActiveBadge => isArabic ? 'محاكي محلي (\$0.00)' : (isFrench ? 'SIMULATEUR LOCAL (\$0.00)' : 'LOCAL OFFLINE MOCK (\$0.00)');
  String get geminiApiKeyLabel => isArabic ? 'مفتاح Gemini API (Google AI Studio)' : (isFrench ? 'Clé API Gemini (Google AI Studio)' : 'Gemini API Key (Google AI Studio)');
  String get geminiApiKeyHint => isArabic ? 'الصق المفتاح AIzaSy... أو AQ...' : (isFrench ? 'Collez votre clé API...' : 'Paste your API key');
  String get getFreeKeyLink => isArabic
      ? 'احصل على مفتاح مجاني 100% بدون بطاقة بنكية من aistudio.google.com (1,500 استعلام يومياً مجاناً)'
      : (isFrench
          ? 'Obtenez une clé gratuite sans carte sur aistudio.google.com (1 500 requêtes/jour gratuites)'
          : 'Get a 100% free developer key without credit card at aistudio.google.com (1,500 free queries/day)');
  String get testConnectionBtn => isArabic ? 'فحص الاتصال' : (isFrench ? 'TESTER LA CONNEXION' : 'TEST CONNECTION');
  String get saveKeyBtn => isArabic ? 'حفظ وتفعيل' : (isFrench ? 'ENREGISTRER' : 'SAVE & ACTIVATE');
  String get clearKeyBtn => isArabic ? 'مسح المفتاح (الرجوع للمحاكي)' : (isFrench ? 'Purger la clé' : 'Clear Key');
  String get connectionSuccessToast => isArabic ? 'تم الاتصال بنجاح بـ Gemini Flash' : (isFrench ? 'Connexion réussie à Gemini Flash' : 'Connected to Gemini Flash successfully');
  String get connectionFailedToast => isArabic ? 'فشل الاتصال: تأكد من صحة المفتاح والإنترنت' : (isFrench ? 'Échec de connexion : vérifiez la clé et le réseau' : 'Connection failed: verify your key and internet');
  String get keySavedToast => isArabic ? 'تم تفعيل محرك Gemini المباشر بنجاح' : (isFrench ? 'Moteur Gemini direct activé avec succès' : 'Gemini live engine activated successfully');
  String get keyClearedToast => isArabic ? 'تم مسح المفتاح والعودة للمحاكي المحلي (\$0.00)' : (isFrench ? 'Clé purgée, retour au simulateur local (\$0.00)' : 'Key cleared, reverted to local mock (\$0.00)');

  // Direct Live Conversation with The Warm Investigator
  String get dialogueModeTitle => isArabic ? 'حوار مباشر' : (isFrench ? 'Dialogue Direct' : 'Live Dialogue');
  String get labModeTitle => isArabic ? 'المختبر السريري' : (isFrench ? 'Labo Clinique' : 'Clinical Lab');
  String get investigatorTyping => isArabic ? 'المحقق بصدد التفكير...' : (isFrench ? 'L’Enquêteur réfléchit...' : 'The Investigator is reflecting...');
  String get typeMessageHint => isArabic ? 'احكي مع المحقق (شنوة الفكرة اللي قالقتك؟)...' : (isFrench ? 'Échangez avec l’enquêteur...' : 'Talk with the investigator...');
  String get welcomeDialoguePrompt => isArabic
      ? 'أهلاً بيك. أنا هوني باش نسمعك ونفككوا مع بعضنا أي فكرة أو توتر مقلقك توا. شنوة اللي صاير معاك؟'
      : (isFrench
          ? 'Bienvenue. Je suis là pour explorer avec vous ce qui vous pèse. Quelle pensée ou situation traverse votre esprit ?'
          : 'Welcome. I am here to explore whatever thought or reaction is weighing on your mind right now. What happened, or what are you feeling?');
  String get quickPillAssumption => isArabic ? 'نحسها مجرد فرضية موش حقيقة' : (isFrench ? 'C’est une supposition, pas un fait' : 'It feels like an assumption');
  String get quickPillNoProof => isArabic ? 'ما عندي حتى دليل ملموس' : (isFrench ? 'Je n’ai pas de preuve concrète' : 'I have no concrete proof');
  String get quickPillAlternative => isArabic ? 'كيفاش نجم نغزر للموضوع بطريقة أخرى؟' : (isFrench ? 'Quelle serait une autre explication ?' : 'What is an alternative explanation?');
  String get quickPillSomatic => isArabic ? 'حاسس بتوتر وضغط في بدني' : (isFrench ? 'Je ressens une tension physique' : 'I feel tension in my body');
  String get newSessionBtn => isArabic ? 'جلسة جديدة' : (isFrench ? 'Nouvelle Session' : 'New Session');
  String get convertToCaseBtn => isArabic ? 'حفظ كملف قضية' : (isFrench ? 'Archiver le Dossier' : 'Save as Case File');
  String get caseSavedFromChat => isArabic ? 'تم حفظ الحوار كملف قضية في السجل' : (isFrench ? 'Session archivée dans le Journal' : 'Session saved to Journal as a case file');
  String get tagStatementFact => isArabic ? 'حقيقة [F]' : (isFrench ? 'Fait [F]' : 'Fact [F]');
  String get tagStatementAssumption => isArabic ? 'فرضية [A]' : (isFrench ? 'Supposition [A]' : 'Assumption [A]');
  String get tagStatementInterpretation => isArabic ? 'تأويل [I]' : (isFrench ? 'Interprétation [I]' : 'Interpretation [I]');

  // Cognitive Distortions & Forensic Synthesis
  String get synthesizeCaseBtn => isArabic ? 'استخلاص الملف' : (isFrench ? 'SYNTHÉTISER' : 'SYNTHESIZE BRIEF');
  String get synthesizingCase => isArabic ? 'جاري استخلاص النتائج المعرفية...' : (isFrench ? 'Synthèse cognitive en cours...' : 'Synthesizing cognitive findings...');
  String get caseSynthesizedSuccess => isArabic ? 'تم توثيق واستخلاص الجلسة في السجل بنجاح' : (isFrench ? 'Session synthétisée et enregistrée dans le Journal' : 'Session brief synthesized and filed to Journal');
  String get cognitiveDistortionSheetTitle => isArabic ? 'مستكشف التشوهات المعرفية' : (isFrench ? 'DISTORSIONS COGNITIVES' : 'COGNITIVE DISTORTIONS');
  String get cognitiveDistortionSheetDesc => isArabic
      ? 'حدد التشويه الفكري الأكثر مطابقة لفكرتك لمساعدتك على تفكيكها بهدوء'
      : (isFrench
          ? 'Identifiez le piège de pensée correspondant pour prendre du recul'
          : 'Identify the automatic thinking trap to re-anchor in reality');
  String get distortionEmotionalReasoning => isArabic ? 'الاستدلال الشعوري (الشعور بالشيء يجعله حقيقة)' : (isFrench ? 'Raisonnement émotionnel (je le ressens donc c’est vrai)' : 'Emotional Reasoning (feeling = reality)');
  String get distortionMentalFilter => isArabic ? 'التصفية الذهنية (التركيز على السلبي وتجاهل الإيجابي)' : (isFrench ? 'Filtre mental (focalisation négative)' : 'Mental Filter (discounting the positives)');
  String get distortionOvergeneralization => isArabic ? 'التعميم المفرط (موقف سلبي واحد يتحول إلى قاعدة دائمة)' : (isFrench ? 'Généralisation excessive (règle absolue)' : 'Overgeneralization (single event = permanent pattern)');
  String get tagDistortionBtn => isArabic ? '+ تشويه فكري' : (isFrench ? '+ Distorsion' : '+ Distortion');
  String get quickPillWhatFacts => isArabic ? 'شنوة اللي صار بالحق في الواقع؟' : (isFrench ? 'Quels sont les faits observables ?' : 'What are the raw facts?');
  String get quickPillFriendPerspective => isArabic ? 'شنوة كنت ننصح صديق لو كان في بلاصتي؟' : (isFrench ? 'Que dirais-je à un ami proche ?' : 'What would I tell a friend?');
  String get quickPillControl => isArabic ? 'شنوة اللي في نطاق تحكمي توا؟' : (isFrench ? 'Que puis-je contrôler maintenant ?' : 'What is in my control right now?');

  // =========================================================================
  // 3. The Thought Trace & Daily Mind Trace
  // =========================================================================
  String get dailyMindTraceTitle => isArabic ? 'أثر اليوم' : (isFrench ? 'Trace Quotidienne' : 'Daily Mind Trace');
  String get dailyMindTraceQuote => isArabic
      ? '«كل نهار يخلي أثر فينا. كيفاش تحب ترسم وتوثق أثر يومك الليلة؟»'
      : (isFrench
          ? '« Chaque jour laisse une trace. À quoi ressemble la vôtre aujourd’hui ? »'
          : '“Every day leaves a trace. What does yours look like today?”');
  String get thoughtTraceTitle => isArabic ? 'أثر الأفكار' : (isFrench ? 'L’Empreinte des Pensées' : 'The Thought Trace');
  String get thoughtTraceQuote => isArabic
      ? '«كل فكرة تترك أثراً. كل تدوينة تصبح جزءاً من سجل شخصي يمكنك مراجعته وفحصه وفهمه.»'
      : (isFrench
          ? '« Chaque pensée laisse une trace. Chaque entrée devient une archive personnelle à revisiter, examiner et comprendre. »'
          : '“Every thought leaves a trace. Every entry becomes part of a personal record that can be revisited, examined, and understood.”');
  String get thoughtTraceTab => isArabic ? 'أثر الأفكار' : (isFrench ? 'Empreinte' : 'The Thought Trace');
  String get constellationTab => thoughtTraceTab;
  String get patternsTab => isArabic ? 'استكشاف الأنماط' : (isFrench ? 'Exploration des Schémas' : 'Pattern Exploration');
  String get checkInTab => isArabic ? 'تسجيل الأثر' : (isFrench ? 'Bilan' : 'Check-in');
  String get recordTraceBtn => isArabic ? 'تسجيل أثر اليوم في السجل' : (isFrench ? 'Enregistrer dans l’archive' : 'RECORD DAILY THOUGHT TRACE');
  String get traceSavedSnackbar => isArabic
      ? 'تم تسجيل أثر الفكرة وحفظه في أرشيفك الشخصي بنجاح'
      : (isFrench
          ? 'Empreinte de pensée enregistrée dans votre archive personnelle'
          : 'Daily thought trace recorded in your personal archive');

  // =========================================================================
  // 1. Personalized Mental Health Profile
  // =========================================================================
  // 1. Personalized Mental Health Profile (Session 03)
  // =========================================================================
  String get myPsychologicalProfileTitle => isArabic ? 'ملفي النفسي' : (isFrench ? 'Mon Profil Psychologique' : 'My Psychological Profile');
  String get profileIntroQuote => isArabic
      ? '«تجاربك فريدة تماماً. ساعد Mind Forensics على فهم عالمك النفسي، وتحدياتك، وما يهمك حقاً.»'
      : (isFrench
          ? '« Vos expériences sont uniques. Aidez Mind Forensics à comprendre votre monde intérieur et ce qui compte pour vous. »'
          : '“Your experiences are unique. Help Mind Forensics understand your psychological world, your challenges, and what matters to you.”');
  String get profileSecondaryQuote => isArabic
      ? 'شارك فقط ما ترتاح في مشاركته. يمكنك تحديث أو إزالة أي معلومة متى شئت دون قيود.'
      : (isFrench
          ? 'Ne partagez que ce qui vous convient. Vous pouvez modifier ou retirer vos informations à tout moment.'
          : 'Share only what you feel comfortable sharing. You can update or remove your information whenever you want.');
  String get sectionAboutMe => isArabic ? 'عني (About Me)' : (isFrench ? 'À propos de moi' : 'About Me');
  String get sectionAboutMeDesc => isArabic ? 'الاسم المفضل، الفئة العمرية، اللغة المفضلة، ومقدمة شخصية.' : (isFrench ? 'Nom préféré, tranche d’âge, langue et présentation personnelle.' : 'Preferred name, age range, language, and personal introduction.');
  String get sectionExperiences => isArabic ? 'التجارب النفسية' : (isFrench ? 'Expériences psychologiques' : 'Psychological Experiences');
  String get sectionExperiencesDesc => isArabic ? 'التجارب والحالات المعاشة ومستوى التشخيص أو الاستكشاف.' : (isFrench ? 'Vécus, schémas ou particularités et leur statut d’évaluation.' : 'Conditions, patterns, and neurodivergent traits relevant to you.');
  String get sectionSymptoms => isArabic ? 'الأعراض والصعوبات' : (isFrench ? 'Symptômes et difficultés' : 'Symptoms and Difficulties');
  String get sectionSymptomsDesc => isArabic ? 'التحديات الانفعالية، الفكرية، السلوكية والجسدية الحالية.' : (isFrench ? 'Défis émotionnels, cognitifs, comportementaux et somatiques.' : 'Current emotional, cognitive, and behavioral challenges.');
  String get sectionGoals => isArabic ? 'الأهداف الشخصية' : (isFrench ? 'Objectifs personnels' : 'Personal Goals');
  String get sectionGoalsDesc => isArabic ? 'ما ترغب في استكشافه أو تطويره من خلال Mind Forensics.' : (isFrench ? 'Ce que vous souhaitez comprendre ou renforcer grâce à l’application.' : 'What you would like to explore or improve through Mind Forensics.');
  String get sectionContext => isArabic ? 'سياقي الشخصي' : (isFrench ? 'Contexte personnel' : 'Personal Context');
  String get sectionContextDesc => isArabic ? 'ما ترغب أن يدركه التطبيق عن تاريخك وتحدياتك وما يساعدك.' : (isFrench ? 'Ce que vous aimeriez que Mind Forensics comprenne de votre parcours.' : 'What you would like Mind Forensics to understand about you.');
  String get sectionCommunication => isArabic ? 'تفضيلات التواصل' : (isFrench ? 'Préférences de communication' : 'Communication Preferences');
  String get sectionCommunicationDesc => isArabic ? 'نبرة المساعد، طول الردود، وتفضيلات التعامل أثناء التوتر.' : (isFrench ? 'Ton du compagnon, longueur des réponses et préférences en cas de détresse.' : 'AI tone, response length, and preferences when feeling distressed.');
  String get sectionPrivacy => isArabic ? 'الخصوصية وتخصيص الذكاء الاصطناعي' : (isFrench ? 'Confidentialité et IA' : 'Privacy and AI Personalization');
  String get sectionPrivacyDesc => isArabic ? 'التحكم الدقيق في مشاركة السياق، حذف البيانات، وأمان الخزينة.' : (isFrench ? 'Contrôle granulaire du contexte IA et gestion des données locales.' : 'Granular control over AI context, data removal, and vault security.');
  String get profileNotCompletedBadge => isArabic ? 'غير مكتمل بعد' : (isFrench ? 'À compléter' : 'Not yet completed');
  String get profileCompletedBadge => isArabic ? 'مكتمل' : (isFrench ? 'Complété' : 'Completed');
  String get profileSubtitle => isArabic
      ? 'مساحة شخصية وسرية لتوثيق تجاربك وتخصيص مرافقتك النفسية وفق احتياجاتك.'
      : (isFrench
          ? 'Espace confidentiel pour consigner votre vécu et personnaliser votre accompagnement.'
          : 'A confidential space to document your lived experiences and personalize your companion.');
  String get conditionsSectionTitle => isArabic ? 'التجارب والحالات النفسية' : (isFrench ? 'Conditions & Expériences' : 'Conditions & Experiences');
  String get conditionsSectionSubtitle => isArabic
      ? 'اختر ما يعبر عن تجربتك الشخصية. الاختيار لا يعني بالضرورة وجود تشخيص طبي رسمي.'
      : (isFrench
          ? 'Sélectionnez ce qui résonne avec votre vécu. Ne constitue pas un diagnostic médical.'
          : 'Select what resonates with your experience. Selection does not assume a clinical diagnosis.');
  String get statusTitle => isArabic ? 'حالة التقييم السريري' : (isFrench ? 'Statut d’évaluation' : 'Evaluation Status');
  String get optionalDetailsTitle => isArabic ? 'سياق وتفاصيل إضافية (اختياري)' : (isFrench ? 'Contexte & détails (facultatif)' : 'Optional Context & Details');
  String get symptomsLabel => isArabic ? 'الأعراض والتجارب المعاشة' : (isFrench ? 'Symptômes et vécus' : 'Symptoms and lived experiences');
  String get durationLabel => isArabic ? 'المدة الزمنية لهذه التجارب' : (isFrench ? 'Durée de cette expérience' : 'How long you have experienced them');
  String get difficultiesLabel => isArabic ? 'الصعوبات الحالية الأكثر تأثيراً' : (isFrench ? 'Difficultés actuelles' : 'Current difficulties');
  String get triggersLabel => isArabic ? 'المحفزات الشخصية المعروفة' : (isFrench ? 'Déclencheurs personnels connus' : 'Personal triggers, if known');
  String get treatmentLabel => isArabic ? 'المتابعة أو العلاج المهني الحالي' : (isFrench ? 'Accompagnement ou traitement actuel' : 'Current treatment or professional support');
  String get goalsLabel => isArabic ? 'أهدافك الشخصية من الاستكشاف' : (isFrench ? 'Vos objectifs personnels' : 'Personal goals');
  String get notesForAiLabel => isArabic ? 'ما ترغب أن يدركه مرافقك الذكي' : (isFrench ? 'Ce que l’IA devrait comprendre de vous' : 'Things you want your AI companion to understand');
  String get shareWithAiToggle => isArabic ? 'مشاركة الملف مع المرافق الذكي' : (isFrench ? 'Partager avec le compagnon IA' : 'Share profile with AI companion');
  String get shareWithAiDesc => isArabic
      ? 'يسمح للمرافق الذكي بتخصيص أسئلته وفقاً لحالتك وأهدافك الشخصية، مع الحفاظ على سرية بياناتك على هذا الجهاز فقط.'
      : (isFrench
          ? 'Permet au compagnon de personnaliser son écoute selon vos besoins en toute confidentialité locale.'
          : 'Allows your companion to personalize inquiry to your goals with strict on-device confidentiality.');
  String get saveProfileBtn => isArabic ? 'حفظ الملف النفسي' : (isFrench ? 'ENREGISTRER LE PROFIL' : 'SAVE PROFILE');
  String get profileSavedSnackbar => isArabic ? 'تم حفظ الملف النفسي وتحديث سياق المرافق بنجاح' : (isFrench ? 'Profil psychologique mis à jour avec succès' : 'Psychological profile saved and AI context updated');
  String get editConditionStatusTitle => isArabic ? 'تحديد حالة التقييم' : (isFrench ? 'Définir le statut' : 'Specify Evaluation Status');
  String get conditionNoteLabel => isArabic ? 'ملاحظة خاصة بهذه الحالة' : (isFrench ? 'Note personnelle pour cette condition' : 'Personal note for this condition');
  String get tabProfile => isArabic ? 'ملفي النفسي' : (isFrench ? 'Mon Profil' : 'My Profile');
  String get tabSettings => isArabic ? 'الإعدادات والأمان' : (isFrench ? 'Paramètres & Coffre' : 'Settings & Vault');

  // =========================================================================
  // 2. Personalized Psychological Journey & Progress
  // =========================================================================
  String get myJourneyTitle => isArabic ? 'رحلتي النفسية' : (isFrench ? 'Mon Parcours' : 'My Journey');
  String get myJourneySubtitle => isArabic
      ? 'مسار مرن واستكشافي يتكيف معك، بدون تقييمات قسرية أو نسب تعافٍ زائفة.'
      : (isFrench
          ? 'Cadre d’exploration flexible et bienveillant, sans pourcentages de guérison arbitraires.'
          : 'A flexible, non-judgmental exploration framework without arbitrary recovery scores.');
  String get myProgressTab => isArabic ? 'تقدمي ومحطاتي' : (isFrench ? 'Mes Progrès' : 'My Progress');
  String get currentPhaseLabel => isArabic ? 'المرحلة المستكشفة حالياً' : (isFrench ? 'Phase active' : 'Active Phase');
  String get activityCompletedBadge => isArabic ? 'مكتمل' : (isFrench ? 'Complété' : 'Completed');
  String get activityInProgressBadge => isArabic ? 'استكشاف' : (isFrench ? 'En cours' : 'Explore');
  String get startActivityBtn => isArabic ? 'بدء التمرين والتأمل' : (isFrench ? 'Explorer l’activité' : 'Explore Activity');
  String get guidedInstructionsTitle => isArabic ? 'إرشادات توجيهية خطوة بخطوة' : (isFrench ? 'Instructions pas-à-pas' : 'Guided Instructions');
  String get reflectionQuestionsTitle => isArabic ? 'أسئلة التأمل والاستبصار' : (isFrench ? 'Questions de réflexion' : 'Reflection Questions');
  String get personalNotesLabel => isArabic ? 'ملاحظاتي واستنتاجاتي الشخصية' : (isFrench ? 'Notes & réflexions personnelles' : 'Personal notes and reflections');
  String get markAsCompletedBtn => isArabic ? 'تعليم كمكتمل' : (isFrench ? 'Marquer comme complété' : 'Mark as Completed');
  String get saveReflectionBtn => isArabic ? 'حفظ التأمل والاستنتاجات' : (isFrench ? 'ENREGISTRER LA RÉFLEXION' : 'SAVE REFLECTION');
  String get reflectionSavedSnackbar => isArabic ? 'تم حفظ تأملاتك بنجاح' : (isFrench ? 'Réflexion enregistrée avec succès' : 'Reflection saved successfully');
  String get totalCompletedActivities => isArabic ? 'الأنشطة المكتملة' : (isFrench ? 'Activités complétées' : 'Completed Activities');
  String get totalReflectionsLogged => isArabic ? 'التأملات المدونة' : (isFrench ? 'Réflexions consignées' : 'Reflections Logged');
  String get nonJudgmentalNotice => isArabic
      ? 'هذا المسار هو إطار مرن للاستبصار، وليس مقياساً لقيمتك الشخصية أو مؤشراً لتعافيك. يمكنك التنقل بحرية بين الأنشطة ومراجعتها متى شئت.'
      : (isFrench
          ? 'Ce parcours est un cadre bienveillant d’auto-observation. La progression ne mesure ni votre valeur ni votre guérison.'
          : 'This journey is a flexible framework for self-attunement. Progress is never a metric of your psychological worth or recovery.');
  String get toolkitLabTab => isArabic ? 'مختبر الأدوات' : (isFrench ? 'Boîte à Outils' : 'Tools Lab');

  // =========================================================================
  // 3. Authentication & Vault Onboarding
  // =========================================================================
  String get authTitle => isArabic ? 'فتح الخزنة الذهنية' : (isFrench ? 'Accès au Coffre Mental' : 'Access Your Mental Vault');
  String get authSubtitle => isArabic
      ? 'مساحة استكشاف معرفية مشفرة. ادخل إلى سجلاتك وخزنتك الآمنة.'
      : (isFrench
          ? 'Espace d’exploration cognitive souverain et chiffré. Accédez à votre coffre.'
          : 'A private cognitive exploration space. Access your encrypted forensic records.');
  String get signInTab => isArabic ? 'فتح الخزنة (دخول)' : (isFrench ? 'Déverrouiller' : 'Unlock Vault');
  String get signUpTab => isArabic ? 'إنشاء خزنة جديدة' : (isFrench ? 'Créer un Coffre' : 'Create Vault');
  String get emailFieldLabel => isArabic ? 'البريد الإلكتروني' : (isFrench ? 'Adresse email' : 'Email Address');
  String get emailFieldHint => 'investigator@domain.com';
  String get passwordFieldLabel => isArabic ? 'كلمة سر الخزنة' : (isFrench ? 'Mot de passe' : 'Vault Password');
  String get passwordFieldHint => isArabic ? '6 أحرف على الأقل' : (isFrench ? '6 caractères minimum' : 'At least 6 characters');
  String get codenameFieldLabel => isArabic ? 'الاسم الرمزي للمحقق (اختياري)' : (isFrench ? 'Nom de code / Alias (facultatif)' : 'Forensic Codename (Optional)');
  String get codenameFieldHint => isArabic ? 'مثال: باحث #4092' : (isFrench ? 'ex: Observateur #4092' : 'e.g. Observer #4092');
  String get createVaultBtn => isArabic ? 'إنشاء الخزنة السيادية' : (isFrench ? 'CRÉER LE COFFRE SOUVERAIN' : 'CREATE SOVEREIGN VAULT');
  String get unlockVaultBtn => isArabic ? 'فتح الخزنة' : (isFrench ? 'DÉVERROUILLER LE COFFRE' : 'UNLOCK VAULT');
  String get anonymousOptionTitle => isArabic ? 'خزنة سيادية مجهولة الهوية' : (isFrench ? 'Coffre Souverain Anonyme' : 'Anonymous Sovereign Vault');
  String get anonymousOptionSubtitle => isArabic
      ? 'بدون بريد أو هاتف أو هوية شخصية. تبقى كافة البيانات مشفرة محلياً على جهازك لخصوصية تامة.'
      : (isFrench
          ? 'Sans email ni identifiant. Toutes les données sont chiffrées localement pour une confidentialité absolue.'
          : 'Zero email, phone, or identity footprint. All data remains encrypted on your device with complete privacy.');
  String get startAnonymouslyBtn => isArabic ? 'استكشاف فوري بدون حساب (خزنة خاصة)' : (isFrench ? 'EXPLORATION PRIVÉE SANS COMPTE' : 'EXPLORE ANONYMOUSLY (PRIVATE VAULT)');
  String get alreadyHaveVaultPrompt => isArabic ? 'لديك خزنة سابقة؟' : (isFrench ? 'Vous avez déjà un coffre ?' : 'Already have a vault?');
  String get newInvestigatorPrompt => isArabic ? 'مستكشف جديد؟' : (isFrench ? 'Nouvel explorateur ?' : 'New investigator?');
  String get startExplorationBtn => isArabic ? 'ابدأ رحلة الاستكشاف' : (isFrench ? 'Commencer l’exploration' : 'Start Exploration');
  String get signInPromptBtn => isArabic ? 'تسجيل الدخول' : (isFrench ? 'Se connecter' : 'Sign In');
  String get biometricUnlockBtn => isArabic ? 'فتح سريع بالبصمة' : (isFrench ? 'Déverrouillage biométrique' : 'Quick Biometric Unlock');
  String get linkEmailTitle => isArabic ? 'ترقية إلى خزنة سحابية' : (isFrench ? 'Associer un compte cloud' : 'Upgrade to Cloud Vault');
  String get linkEmailSubtitle => isArabic
      ? 'اربط بريدك الإلكتروني لمزامنة مسارك النفسي بين أجهزتك بأمان دون فقدان أي ملاحظة.'
      : (isFrench
          ? 'Associez un email pour synchroniser votre parcours entre vos appareils sans rien perdre.'
          : 'Link an email and password to securely sync your journey across devices without losing data.');
  String get linkEmailBtn => isArabic ? 'ربط ومزامنة الخزنة' : (isFrench ? 'ASSOCIER & SYNCHRONISER' : 'LINK & SYNC VAULT');
  String get signOutBtn => isArabic ? 'قفل الخزنة والخروج' : (isFrench ? 'Verrouiller et déconnecter' : 'Lock & Sign Out');
  String get deleteAccountBtn => isArabic ? 'حذف الحساب والخزنة نهائياً' : (isFrench ? 'Supprimer définitivement le compte' : 'Delete Account & Vault');
  String get vaultStatusAnonymous => isArabic ? 'خزنة سيادية محلية (مجهولة الهوية)' : (isFrench ? 'Coffre Souverain Local (Anonyme)' : 'Sovereign Local Vault (Anonymous)');
  String get vaultStatusCloud => isArabic ? 'خزنة سحابية مشفرة' : (isFrench ? 'Coffre Chiffré dans le Cloud' : 'Cloud-Synced Vault');
  String get onboardingVaultChoiceTitle => isArabic ? 'الخزنة النفسية ودرع الخصوصية' : (isFrench ? 'Coffre Mental & Bouclier Privé' : 'Mental Vault & Privacy Shield');
  String get onboardingVaultChoiceSubtitle => isArabic
      ? 'حدد أسلوب حفظ وتأمين سجلاتك وتأملاتك النفسية.'
      : (isFrench
          ? 'Choisissez comment sécuriser vos traces et découvertes cognitives.'
          : 'Choose how your cognitive traces and reflections are stored and secured.');
  String get anonymousChoiceBadge => isArabic ? 'أعلى درجات الخصوصية' : (isFrench ? 'CONFIDENTIALITÉ MAXIMALE' : 'MAXIMUM PRIVACY');
  String get cloudChoiceBadge => isArabic ? 'مزامنة متعددة الأجهزة' : (isFrench ? 'SYNCHRONISATION MULTI-APPAREILS' : 'MULTI-DEVICE SYNC');
  String get biometricEnableToggle => isArabic ? 'تأمين هذا الجهاز ببصمة الإصبع أو الوجه' : (isFrench ? 'Protéger l’accès par biométrie' : 'Secure device with Biometrics');

  // Condition and Status Display Name Localizers
  String conditionName(ConditionType condition) {
    if (isArabic) {
      switch (condition) {
        case ConditionType.depression: return 'الاكتئاب';
        case ConditionType.bipolarI: return 'اضطراب ثنائي القطب النوع الأول';
        case ConditionType.bipolarII: return 'اضطراب ثنائي القطب النوع الثاني';
        case ConditionType.moodInstability: return 'تقلبات المزاج وعدم الاستقرار';
        case ConditionType.otherMood: return 'تجارب مزاجية أخرى';
        case ConditionType.generalizedAnxiety: return 'القلق العام (GAD)';
        case ConditionType.socialAnxiety: return 'القلق الاجتماعي';
        case ConditionType.panicAttacks: return 'نوبات الهلع (Panic Attacks)';
        case ConditionType.specificPhobias: return 'مخاوف ورهاب محدد';
        case ConditionType.otherAnxiety: return 'تجارب قلق أخرى';
        case ConditionType.ocd: return 'الوسواس القهري (OCD)';
        case ConditionType.intrusiveThoughts: return 'أفكار متطفلة وملحة';
        case ConditionType.repetitiveThoughts: return 'أفكار متكررة واجترار';
        case ConditionType.compulsiveBehaviors: return 'سلوكيات قهرية متكررة';
        case ConditionType.ptsd: return 'اضطراب ما بعد الصدمة (PTSD)';
        case ConditionType.complexPtsd: return 'اضطراب ما بعد الصدمة المعقد (C-PTSD)';
        case ConditionType.traumaDifficulties: return 'صعوبات ناتجة عن صدمات';
        case ConditionType.adhd: return 'تشتت الانتباه وفرط الحركة (ADHD)';
        case ConditionType.autism: return 'طيف التوحد';
        case ConditionType.attentionDifficulties: return 'صعوبات الانتباه والتركيز';
        case ConditionType.sensoryDifficulties: return 'حساسية وتحديات حسية';
        case ConditionType.psychosisSpectrum: return 'تجارب طيف الذهان';
        case ConditionType.schizophrenia: return 'الفصام (Schizophrenia)';
        case ConditionType.hallucinations: return 'تجارب حسية وهلوسات';
        case ConditionType.delusions: return 'معتقدات خاصة / ضلالات';
        case ConditionType.otherPerceptual: return 'تجارب إدراكية غير اعتيادية';
        case ConditionType.dissociativeDisorders: return 'الاضطرابات التفارقية';
        case ConditionType.dissociativeExperiences: return 'تجارب انفصال وتفارق';
        case ConditionType.eatingDisorders: return 'اضطرابات الأكل';
        case ConditionType.eatingDifficulties: return 'صعوبات تتعلق بالأكل';
        case ConditionType.personalityDisorders: return 'اضطرابات الشخصية';
        case ConditionType.personalityDifficulties: return 'صعوبات نمط الشخصية';
        case ConditionType.sleepDisorders: return 'اضطرابات النوم والأرق';
        case ConditionType.sleepDifficulties: return 'صعوبات النوم والاستيقاظ';
        case ConditionType.other: return 'حالة أخرى / غير مدرجة';
        case ConditionType.stillExploring: return 'ما زلت أستكشف صحتي النفسية';
        case ConditionType.preferNotToSpecify: return 'أفضل عدم التحديد';
      }
    } else if (isFrench) {
      switch (condition) {
        case ConditionType.depression: return 'Dépression';
        case ConditionType.bipolarI: return 'Trouble bipolaire I';
        case ConditionType.bipolarII: return 'Trouble bipolaire II';
        case ConditionType.moodInstability: return 'Instabilité de l’humeur';
        case ConditionType.otherMood: return 'Autres expériences de l’humeur';
        case ConditionType.generalizedAnxiety: return 'Anxiété généralisée (TAG)';
        case ConditionType.socialAnxiety: return 'Anxiété sociale';
        case ConditionType.panicAttacks: return 'Attaques de panique';
        case ConditionType.specificPhobias: return 'Phobies spécifiques';
        case ConditionType.otherAnxiety: return 'Autres expériences anxieuses';
        case ConditionType.ocd: return 'Trouble obsessionnel-compulsif (TOC)';
        case ConditionType.intrusiveThoughts: return 'Pensées intrusives';
        case ConditionType.repetitiveThoughts: return 'Pensées répétitives';
        case ConditionType.compulsiveBehaviors: return 'Comportements compulsifs';
        case ConditionType.ptsd: return 'Stress post-traumatique (TSPT)';
        case ConditionType.complexPtsd: return 'TSPT complexe';
        case ConditionType.traumaDifficulties: return 'Difficultés liées aux traumatismes';
        case ConditionType.adhd: return 'TDAH';
        case ConditionType.autism: return 'Spectre de l’autisme';
        case ConditionType.attentionDifficulties: return 'Difficultés d’attention';
        case ConditionType.sensoryDifficulties: return 'Sensibilités sensorielles';
        case ConditionType.psychosisSpectrum: return 'Expériences du spectre psychotique';
        case ConditionType.schizophrenia: return 'Schizophrénie';
        case ConditionType.hallucinations: return 'Expériences hallucinatoires';
        case ConditionType.delusions: return 'Idées délirantes / croyances inhabituelles';
        case ConditionType.otherPerceptual: return 'Autres perceptions inhabituelles';
        case ConditionType.dissociativeDisorders: return 'Troubles dissociatifs';
        case ConditionType.dissociativeExperiences: return 'Expériences dissociatives';
        case ConditionType.eatingDisorders: return 'Troubles du comportement alimentaire';
        case ConditionType.eatingDifficulties: return 'Difficultés alimentaires';
        case ConditionType.personalityDisorders: return 'Troubles de la personnalité';
        case ConditionType.personalityDifficulties: return 'Difficultés relationnelles/personnalité';
        case ConditionType.sleepDisorders: return 'Troubles du sommeil';
        case ConditionType.sleepDifficulties: return 'Difficultés de sommeil';
        case ConditionType.other: return 'Autre / Non listé';
        case ConditionType.stillExploring: return 'En cours d’exploration';
        case ConditionType.preferNotToSpecify: return 'Préfère ne pas préciser';
      }
    } else {
      return condition.defaultDisplayName();
    }
  }

  String statusName(DiagnosticStatus status) {
    if (isArabic) {
      switch (status) {
        case DiagnosticStatus.professionallyDiagnosed: return 'تشخيص طبي معتمد';
        case DiagnosticStatus.currentlyBeingEvaluated: return 'قيد التقييم السريري حالياً';
        case DiagnosticStatus.selfIdentifiedExploring: return 'استكشاف ذاتي / ملاحظة شخصية';
        case DiagnosticStatus.preferNotToSay: return 'أفضل عدم الذكر';
      }
    } else if (isFrench) {
      switch (status) {
        case DiagnosticStatus.professionallyDiagnosed: return 'Diagnostic professionnel';
        case DiagnosticStatus.currentlyBeingEvaluated: return 'En cours d’évaluation';
        case DiagnosticStatus.selfIdentifiedExploring: return 'Auto-identifié / En exploration';
        case DiagnosticStatus.preferNotToSay: return 'Préfère ne pas dire';
      }
    } else {
      return status.defaultDisplayName();
    }
  }

  String phaseTitle(JourneyPhase phase) {
    if (isArabic) {
      switch (phase) {
        case JourneyPhase.phase1SelfDiscovery: return 'المرحلة 1: اكتشاف الذات';
        case JourneyPhase.phase2UnderstandingPatterns: return 'المرحلة 2: فهم الأنماط';
        case JourneyPhase.phase3PsychologicalAwareness: return 'المرحلة 3: الوعي النفسي';
        case JourneyPhase.phase4CopingAndDevelopment: return 'المرحلة 4: التكيف والتطور';
        case JourneyPhase.phase5PersonalGrowthAndMaintenance: return 'المرحلة 5: النمو والاستمرارية';
      }
    } else if (isFrench) {
      switch (phase) {
        case JourneyPhase.phase1SelfDiscovery: return 'Phase 1 : Découverte de soi';
        case JourneyPhase.phase2UnderstandingPatterns: return 'Phase 2 : Schémas & Liens';
        case JourneyPhase.phase3PsychologicalAwareness: return 'Phase 3 : Conscience psycho';
        case JourneyPhase.phase4CopingAndDevelopment: return 'Phase 4 : Stratégies d’adaptation';
        case JourneyPhase.phase5PersonalGrowthAndMaintenance: return 'Phase 5 : Croissance durable';
      }
    } else {
      return 'Phase ${phase.phaseNumber} — ${phase.defaultTitle()}';
    }
  }

  String phasePurpose(JourneyPhase phase) {
    if (isArabic) {
      switch (phase) {
        case JourneyPhase.phase1SelfDiscovery:
          return 'فهم عالمك الداخلي، والأفكار المتكررة، والتمييز الواضح بين الفكرة والشعور والتصرف.';
        case JourneyPhase.phase2UnderstandingPatterns:
          return 'إدراك الروابط بين المحفزات، والأنماط الفكرية التلقائية، والاستجابات السلوكية كالتجنب.';
        case JourneyPhase.phase3PsychologicalAwareness:
          return 'تعميق الوعي بالتجارب الخاصة، والتنظيم الانفعالي، والتشوهات المعرفية دون إصدار أحكام ذاتية.';
        case JourneyPhase.phase4CopingAndDevelopment:
          return 'تطبيق تمارين نفسية واستراتيجيات تكيف مثبتة، مثل تقنيات التأريض، وسجلات الأفكار، والروتين الصحي.';
        case JourneyPhase.phase5PersonalGrowthAndMaintenance:
          return 'ترسيخ ما اكتشفته، والتعامل برحمة ووعي مع الانتكاسات، وبناء عادات مستدامة طويلة المدى.';
      }
    } else if (isFrench) {
      switch (phase) {
        case JourneyPhase.phase1SelfDiscovery:
          return 'Comprendre votre monde intérieur et distinguer pensées, émotions et comportements.';
        case JourneyPhase.phase2UnderstandingPatterns:
          return 'Repérer les liens entre déclencheurs, pensées automatiques et stratégies d’évitement.';
        case JourneyPhase.phase3PsychologicalAwareness:
          return 'Approfondir la compréhension de vos vécus et distorsions sans jugement de soi.';
        case JourneyPhase.phase4CopingAndDevelopment:
          return 'Intégrer des exercices ancrés : ancrage 5-4-3-2-1, restructuration cognitive et routines.';
        case JourneyPhase.phase5PersonalGrowthAndMaintenance:
          return 'Consolider vos acquis, traverser les rechutes avec bienveillance et pérenniser vos habitudes.';
      }
    } else {
      return phase.defaultPurpose();
    }
  }

  // ===========================================================================
  // AI COMPANION (SESSION 05)
  // ===========================================================================
  String get aiCompanionTitle => isArabic ? 'المرافق الذكي' : (isFrench ? 'Compagnon IA' : 'AI Companion');
  String get aiCompanionIntro => isArabic
      ? 'مساحة ذكية لاستكشاف ما يجري في داخلك.'
      : (isFrench ? 'Un espace intelligent pour explorer ce qui se passe en vous.' : 'An intelligent space to explore what is happening within you.');
  String get aiCompanionSupporting => isArabic
      ? 'تحدث بحرية، استكشف أفكارك، وافهم مشاعرك، واكتشف الروابط المحتملة في تجاربك.'
      : (isFrench
          ? 'Parlez librement, explorez vos pensées, comprenez vos émotions et découvrez les liens possibles dans vos expériences.'
          : 'Talk freely, explore your thoughts, understand your emotions, and discover possible connections in your experiences.');
  String get selectConversationMode => isArabic ? 'اختر نمط المحادثة' : (isFrench ? 'Mode de conversation' : 'Select Conversation Mode');
  String get newConversationBtn => isArabic ? 'محادثة جديدة' : (isFrench ? 'Nouvelle conversation' : 'New Conversation');
  String get resumeConversationBtn => isArabic ? 'متابعة' : (isFrench ? 'Reprendre' : 'Resume');
  String get recentConversationsTitle => isArabic ? 'المحادثات السابقة' : (isFrench ? 'Conversations récentes' : 'Recent Conversations');
  String get noRecentConversations => isArabic
      ? 'لا توجد محادثات سابقة بعد. اختر نمطاً أعلاه للبدء.'
      : (isFrench ? 'Aucune conversation enregistrée. Choisissez un mode ci-dessus.' : 'No conversations saved yet. Select a mode above to begin.');
  String get suggestedStartersTitle => isArabic ? 'مقترحات للمحادثة' : (isFrench ? 'Idées de départ' : 'Suggested Starters');
  String get renameConversationTitle => isArabic ? 'إعادة تسمية المحادثة' : (isFrench ? 'Renommer la conversation' : 'Rename Conversation');
  String get deleteConversationTitle => isArabic ? 'حذف المحادثة' : (isFrench ? 'Supprimer la conversation' : 'Delete Conversation');
  String get deleteConversationConfirm => isArabic
      ? 'هل أنت متأكد من حذف هذه المحادثة؟ لا يمكن التراجع عن هذا الإجراء.'
      : (isFrench ? 'Êtes-vous sûr de vouloir supprimer cette conversation ? Cette action est irréversible.' : 'Are you sure you want to delete this conversation? This action cannot be undone.');
  String get clearAllConversationsBtn => isArabic ? 'مسح سجل المحادثات' : (isFrench ? 'Effacer tout l’historique' : 'Clear All History');
  String get clearAllConversationsConfirm => isArabic
      ? 'هل أنت متأكد من حذف جميع سجلات المحادثات نهائياً من هذا الجهاز؟'
      : (isFrench ? 'Supprimer définitivement tout l’historique des conversations ?' : 'Permanently delete all conversation records from this device?');
  String get offlineNoticeTitle => isArabic ? 'الوضع دون اتصال' : (isFrench ? 'Mode hors ligne' : 'Offline Mode');
  String get offlineNoticeBody => isArabic
      ? 'الردود الحية تتطلب اتصالاً بالإنترنت. محادثاتك وملاحظاتك محفوظة محلياً بأمان.'
      : (isFrench
          ? 'Les réponses en direct nécessitent une connexion Internet. Vos échanges restent enregistrés localement.'
          : 'Live AI responses require an active internet connection. Your conversations remain securely saved locally.');
  String get switchMode => isArabic ? 'تغيير النمط' : (isFrench ? 'Changer de mode' : 'Switch Mode');
  String get inputPlaceholder => isArabic ? 'اكتب ما يدور في خاطرك...' : (isFrench ? 'Écrivez ce qui vous traverse l’esprit...' : 'What has been happening in your mind?');
  String get typingIndicator => isArabic ? 'المرافق يستمع ويتأمل...' : (isFrench ? 'Le compagnon réfléchit...' : 'AI Companion is reflecting...');
  String get backToAllConversations => isArabic ? 'جميع المحادثات' : (isFrench ? 'Toutes les conversations' : 'All Conversations');

  // ===========================================================================
  // MY PROGRESS (BUILD SESSION 06)
  // ===========================================================================
  String get progressTitle => isArabic ? 'مساري وتقدّمي' : (isFrench ? 'MON CHEMINEMENT' : 'MY PROGRESS');
  String get progressQuote => isArabic
      ? 'كل تدوينة تروي قصة. استكشف اللحظات والمشاعر والاستبصارات التي تشكّل مسارك.'
      : (isFrench
          ? 'Chaque entrée raconte une histoire. Explorez les moments, émotions et découvertes qui composent votre cheminement.'
          : 'Every entry tells a story. Explore the moments, emotions, and discoveries that make up your journey.');
  String get progressTabThoughtTrace => isArabic ? 'أثر الأفكار والنظرة العامة' : (isFrench ? 'EMPREINTE DES PENSÉES & APERÇU' : 'THOUGHT TRACE & OVERVIEW');
  String get progressTabConstellation => progressTabThoughtTrace;
  String get progressTabCalendar => isArabic ? 'التقويم والسجلات' : (isFrench ? 'CALENDRIER & ENTRÉES' : 'CALENDAR & ENTRIES');
  String get progressTabReflections => isArabic ? 'أرشيف التأملات' : (isFrench ? 'ARCHIVES DE RÉFLEXIONS' : 'REFLECTIONS ARCHIVE');
  String get progressTabMilestones => isArabic ? 'المحطات والمسار' : (isFrench ? 'JALONS & PARCOURS' : 'MILESTONES & JOURNEY');

  String get thoughtTraceWaitingTitle => isArabic ? 'سجل أثر الأفكار بانتظارك' : (isFrench ? 'L’EMPREINTE DES PENSÉES VOUS ATTEND' : 'THE THOUGHT TRACE IS WAITING');
  String get skyWaitingTitle => thoughtTraceWaitingTitle;
  String get thoughtTraceWaitingSub => isArabic
      ? 'كل فكرة تترك أثراً. سجّل تقرير اليوم لبدء سجلك الزمني والتأملي.'
      : (isFrench
          ? 'Chaque pensée laisse une trace. Enregistrez votre bilan aujourd’hui pour ouvrir votre chronologie réflexive.'
          : 'Every thought leaves a trace. Record today’s check-in to begin your reflective timeline archive.');
  String get skyWaitingSub => thoughtTraceWaitingSub;
  String get recordTodayTraceBtn => isArabic ? 'تسجيل أثر اليوم' : (isFrench ? 'Enregistrer l’empreinte du jour' : 'Record Today\'s Trace');
  String get tapTraceToInspect => isArabic ? 'المس أي تدوينة لمعاينة أثر الفكرة وتفكيكها.' : (isFrench ? 'Touchez une entrée pour inspecter et déconstruire la pensée.' : 'Tap any entry to inspect and deconstruct the thought.');
  String get tapStarToInspect => tapTraceToInspect;
  String get selectedTraceLabel => isArabic ? 'أثر الفكرة المحدد' : (isFrench ? 'Empreinte sélectionnée' : 'Selected Thought Trace');
  String get selectedStarLabel => selectedTraceLabel;
  String get viewFullTraceBtn => isArabic ? 'عرض تفاصيل الأثر' : (isFrench ? 'Voir la trace complète' : 'View Full Trace');
  String get investigateThoughtBtn => isArabic ? 'فحص وتفكيك هذه الفكرة' : (isFrench ? 'Investiguer cette pensée' : 'Investigate This Thought');

  String get totalEntriesMetric => isArabic ? 'إجمالي التدوينات' : (isFrench ? 'TOTAL ENTRÉES' : 'TOTAL ENTRIES');
  String get uniqueDaysMetric => isArabic ? 'الأيام الملاحظة' : (isFrench ? 'JOURS OBSERVÉS' : 'DAYS OBSERVED');
  String get emotionSelectionsMetric => isArabic ? 'المشاعر المحددة' : (isFrench ? 'ÉMOTIONS CITÉES' : 'EMOTION TAGS');
  String get emotionalSpectrumTitle => isArabic ? 'توزيع المشاعر المعاشة' : (isFrench ? 'SPECTRE ÉMOTIONNEL' : 'REPORTED EMOTIONAL SPECTRUM');
  String get emotionalVarietyTitle => isArabic ? 'تنوع المشاعر واستبصارها' : (isFrench ? 'GRANULARITÉ ÉMOTIONNELLE' : 'EMOTIONAL GRANULARITY');
  String distinctEmotionsCount(int count) => isArabic
      ? '$count مشاعر مختلفة تم تمييزها'
      : (isFrench ? '$count émotions distinctes nommées' : '$count distinct emotions recognized');
  String get intensityTimelineTitle => isArabic ? 'منحنى شدة المشاعر' : (isFrench ? 'INTENSITÉ DANS LE TEMPS' : 'MOOD INTENSITY TIMELINE');
  String get avgIntensityLabel => isArabic ? 'متوسط الشدة' : (isFrench ? 'Intensité moyenne' : 'Average Intensity');
  String intensityMinMax(int min, int max) => isArabic
      ? 'المدى: $min - $max / 10'
      : (isFrench ? 'Plage : $min - $max / 10' : 'Range: $min - $max / 10');

  String get energyAndSleepTitle => isArabic ? 'مؤشرات النوم والطاقة الجسدية' : (isFrench ? 'SOMMEIL ET ÉNERGIE SOMATIQUE' : 'SOMATIC & SLEEP INSIGHTS');
  String get avgEnergyMetric => isArabic ? 'متوسط الطاقة' : (isFrench ? 'ÉNERGIE MOY.' : 'AVG ENERGY');
  String get avgSleepMetric => isArabic ? 'متوسط النوم' : (isFrench ? 'SOMMEIL MOY.' : 'AVG SLEEP');
  String get avgQualityMetric => isArabic ? 'جودة النوم' : (isFrench ? 'QUALITÉ MOY.' : 'AVG QUALITY');
  String get empiricalDisclaimer => isArabic
      ? '* ملاحظات إحصائية مستندة إلى بياناتك المسجلة فقط، ولا تعني وجود علاقة سببية طبية حتمية.'
      : (isFrench
          ? '* Observations issues exclusivement de vos bilans enregistrés. N’implique aucune causalité médicale.'
          : '* Data observations from your self-reported logs only. Does not imply medical or psychological causality.');

  String get calendarNoBreaksNote => isArabic
      ? 'كل نقطة مضيئة تمثل يوماً موثقاً. لا توجد سلاسل تفوت، بل وعي مستمر بالذات.'
      : (isFrench
          ? 'Chaque point marque un jour observé. Sans calcul de série rompue, uniquement de la présence à soi.'
          : 'Each highlighted point marks an observed day. No broken streaks, only continuous self-awareness.');
  String get deleteEntryBtn => isArabic ? 'حذف' : (isFrench ? 'Supprimer' : 'Delete');
  String get editEntryBtn => isArabic ? 'تعديل' : (isFrench ? 'Modifier' : 'Edit');
  String get deleteTraceConfirmTitle => isArabic ? 'حذف الأثر المسجل؟' : (isFrench ? 'Supprimer cette trace ?' : 'Delete Trace Entry?');
  String get deleteTraceConfirmBody => isArabic
      ? 'هل أنت متأكد من رغبتك في حذف هذا الأثر نهائياً من سجلاتك المحلية؟'
      : (isFrench ? 'Êtes-vous sûr de vouloir supprimer définitivement cette entrée ?' : 'Are you sure you want to permanently delete this daily trace entry?');

  String get searchReflectionsHint => isArabic ? 'ابحث في أفكارك وتأملاتك...' : (isFrench ? 'Rechercher dans vos réflexions...' : 'Search your thoughts and reflections...');
  String get filterAllSources => isArabic ? 'كافة المصادر' : (isFrench ? 'Toutes les sources' : 'All Sources');
  String get noReflectionsFound => isArabic ? 'لم يتم العثور على أي تأملات مطابقة للبحث.' : (isFrench ? 'Aucune réflexion ne correspond à votre recherche.' : 'No reflections found matching your query.');
  String get noReflectionsEmpty => isArabic
      ? 'أرشيفك بانتظار تدويناتك. اكتب خواطرك أثناء التقييم اليومي أو جلسات التحقيق أو تمارين المسار.'
      : (isFrench
          ? 'Vos réflexions apparaîtront ici dès vos premiers bilans ou exercices.'
          : 'Your reflection archive is waiting. Write thoughts during daily check-ins, case deconstructions, or journey activities.');

  String get journeyProgressTitle => isArabic ? 'استكشاف مراحل المسار النفسي' : (isFrench ? 'EXPLORATION DU PARCOURS' : 'JOURNEY CURRICULUM EXPLORATION');
  String activitiesExplored(int completed, int total) => isArabic
      ? '$completed من $total أنشطة تم استكشافها'
      : (isFrench ? '$completed / $total activités explorées' : '$completed / $total Activities Explored');
  String get milestonesTitle => isArabic ? 'المحطات الكونية المستنيرة' : (isFrench ? 'JALONS CÉLESTES' : 'CELESTIAL MILESTONES');
  String get milestonesSub => isArabic
      ? 'محطات تحتفي بتراكم الاستبصار والفضول الذاتي دون ضغط أو سلاسل ملزمة.'
      : (isFrench
          ? 'Ces repères célèbrent votre exploration intérieure, sans pression de performance.'
          : 'Milestones honor cumulative self-discovery with zero streak pressure or judgment.');
  String get patternsWorthExploringTitle => isArabic ? 'أنماط جديرة بالاستكشاف' : (isFrench ? 'SCHÉMAS À EXPLORER' : 'PATTERNS WORTH EXPLORING');
  String get patternsSub => isArabic
      ? 'ملاحظات محلية مستخلصة من بياناتك لمساعدتك في التأمل والاستبصار دون أحكام.'
      : (isFrench
          ? 'Observations locales formulées à partir de vos saisies pour nourrir votre réflexion.'
          : 'Local observations formulated from your entries to assist self-reflection.');
  String get dismissInsight => isArabic ? 'تجاهل' : (isFrench ? 'Masquer' : 'Dismiss');
  String get reopenTraceAction => isArabic ? 'فتح الأثر' : (isFrench ? 'Ouvrir' : 'Open Entry');

  // Helper factory
  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return AppStrings(locale.languageCode);
  }
}

final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeControllerProvider);
  return AppStrings(locale.languageCode);
});
