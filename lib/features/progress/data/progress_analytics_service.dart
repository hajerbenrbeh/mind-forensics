import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_strings.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../investigation/domain/case_model.dart';
import '../../journey/controllers/journey_controller.dart';
import '../../journey/domain/journey_state_model.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../domain/progress_analytics_model.dart';

/// State notifier for the currently selected time window.
class TimeWindowNotifier extends Notifier<ProgressTimeWindow> {
  @override
  ProgressTimeWindow build() => ProgressTimeWindow.thirtyDays;

  void setWindow(ProgressTimeWindow window) => state = window;
}

final selectedTimeWindowProvider =
    NotifierProvider<TimeWindowNotifier, ProgressTimeWindow>(TimeWindowNotifier.new);

/// State notifier for IDs of dismissed personal insights.
class DismissedInsightsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void dismiss(String id) => state = {...state, id};
}

final dismissedInsightsProvider =
    NotifierProvider<DismissedInsightsNotifier, Set<String>>(DismissedInsightsNotifier.new);

/// State notifier for the reflection archive search query.
class ReflectionSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final reflectionSearchQueryProvider =
    NotifierProvider<ReflectionSearchQueryNotifier, String>(ReflectionSearchQueryNotifier.new);

/// State notifier for the reflection source filter.
class ReflectionSourceFilterNotifier extends Notifier<ReflectionSourceType?> {
  @override
  ReflectionSourceType? build() => null;

  void setFilter(ReflectionSourceType? filter) => state = filter;
}

final selectedReflectionSourceFilterProvider =
    NotifierProvider<ReflectionSourceFilterNotifier, ReflectionSourceType?>(
  ReflectionSourceFilterNotifier.new,
);

/// Pure computation engine for calculating non-judgmental progress analytics.
class ProgressAnalyticsCalculator {
  static ProgressAnalyticsModel computeAnalytics({
    required List<MindTraceModel> allTraces,
    required List<CaseModel> allCases,
    required JourneyStateModel? journeyState,
    required ProgressTimeWindow timeWindow,
    required Set<String> dismissedInsightIds,
    required AppStrings strings,
  }) {
    // 1. Time-window filtering for traces
    final now = DateTime.now();
    final List<MindTraceModel> filteredTraces;
    if (timeWindow.durationInDays != null) {
      final cutoff = now.subtract(Duration(days: timeWindow.durationInDays!));
      filteredTraces = allTraces.where((t) => t.date.isAfter(cutoff)).toList();
    } else {
      filteredTraces = List<MindTraceModel>.from(allTraces);
    }

    filteredTraces.sort((a, b) => a.date.compareTo(b.date));

    // 2. Count distinct calendar days & emotion selections
    final totalEntries = filteredTraces.length;
    final uniqueDaysCount = filteredTraces.map((t) => t.dateKey).toSet().length;

    var totalEmotionSelections = 0;
    final emotionCounts = <String, int>{};
    for (final trace in filteredTraces) {
      totalEmotionSelections += trace.selectedEmotions.length;
      for (final emotion in trace.selectedEmotions) {
        emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
      }
    }

    final sortedFrequencies = Map.fromEntries(
      emotionCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    final emotionalVarietyCount = sortedFrequencies.length;

    // 3. Intensity stats & timeline
    double avgIntensity = 0.0;
    int minIntensity = 0;
    int maxIntensity = 0;
    final intensityTimeline = <({DateTime date, int intensity, String mood})>[];

    if (filteredTraces.isNotEmpty) {
      final intensities = filteredTraces.map((t) => t.moodIntensity).toList();
      final sum = intensities.reduce((a, b) => a + b);
      avgIntensity = sum / intensities.length;
      minIntensity = intensities.reduce((a, b) => a < b ? a : b);
      maxIntensity = intensities.reduce((a, b) => a > b ? a : b);

      for (final t in filteredTraces) {
        intensityTimeline.add((
          date: t.date,
          intensity: t.moodIntensity,
          mood: t.overallMood,
        ));
      }
    }

    // 4. Somatic & sleep indicators
    double? avgEnergy;
    double? avgSleepDuration;
    double? avgSleepQuality;
    double? avgPhysicalTension;

    if (filteredTraces.isNotEmpty) {
      final energies = filteredTraces.map((t) => t.energyLevel).toList();
      avgEnergy = energies.reduce((a, b) => a + b) / energies.length;

      final sleeps = filteredTraces.where((t) => t.sleepHours != null).map((t) => t.sleepHours!).toList();
      if (sleeps.isNotEmpty) {
        avgSleepDuration = sleeps.reduce((a, b) => a + b) / sleeps.length;
      }

      final sleepQualities = filteredTraces.where((t) => t.sleepQuality != null).map((t) => t.sleepQuality!).toList();
      if (sleepQualities.isNotEmpty) {
        avgSleepQuality = sleepQualities.reduce((a, b) => a + b) / sleepQualities.length;
      }

      final tensions = filteredTraces.where((t) => t.physicalTension != null).map((t) => t.physicalTension!).toList();
      if (tensions.isNotEmpty) {
        avgPhysicalTension = tensions.reduce((a, b) => a + b) / tensions.length;
      }
    }

    // Empirical sleep vs. tension observation
    String? sleepObservation;
    final validSleepTension = filteredTraces
        .where((t) => t.sleepHours != null && t.physicalTension != null)
        .toList();

    if (validSleepTension.length >= 2) {
      final shortSleep = validSleepTension.where((t) => t.sleepHours! < 6.5).toList();
      final longSleep = validSleepTension.where((t) => t.sleepHours! >= 6.5).toList();

      if (shortSleep.isNotEmpty && longSleep.isNotEmpty) {
        final avgShortTension = (shortSleep.map((t) => t.physicalTension!).reduce((a, b) => a + b) / shortSleep.length)
            .toStringAsFixed(1);
        final avgLongTension = (longSleep.map((t) => t.physicalTension!).reduce((a, b) => a + b) / longSleep.length)
            .toStringAsFixed(1);

        sleepObservation = strings.isArabic
            ? 'ملاحظة بيانات: في الأيام التي قل فيها النوم عن 6.5 ساعات، بلغ متوسط التوتر الجسدي $avgShortTension/10، مقارنة بـ $avgLongTension/10 في ليالي الراحة الكافية.'
            : (strings.isFrench
                ? 'Observation empirique : Les jours avec moins de 6,5h de sommeil, la tension physique moyenne était de $avgShortTension/10, contre $avgLongTension/10 lors des nuits reposantes.'
                : 'Data observation: On days with sleep under 6.5 hours, reported physical tension averaged $avgShortTension/10, compared to $avgLongTension/10 on nights with sufficient rest.');
      } else {
        sleepObservation = strings.isArabic
            ? 'ملاحظة مستمرة: وتيرة النوم والتوتر الجسدي تسجل مستويات مستقرة نسبياً في هذه الفترة.'
            : (strings.isFrench
                ? 'Observation continue : Les rythmes de sommeil et de tension restent cohérents sur cette période.'
                : 'Ongoing observation: Sleep duration and somatic tension patterns have shown consistent stability across this timeframe.');
      }
    }

    // 5. Gather all user reflections across traces, cases, and journey
    final allReflections = <SavedReflectionItem>[];

    // From Daily Mind Traces
    for (final trace in allTraces) {
      final text = trace.journalText?.trim();
      if (text != null && text.isNotEmpty) {
        allReflections.add(SavedReflectionItem(
          id: 'trace_${trace.id}',
          text: text,
          date: trace.date,
          sourceType: ReflectionSourceType.dailyTrace,
          sourceTitle: strings.isArabic
              ? 'تدوينة أثر (${trace.overallMood})'
              : (strings.isFrench ? 'Trace du jour (${trace.overallMood})' : 'Daily Trace (${trace.overallMood})'),
          originalTrace: trace,
        ));
      }
    }

    // From Investigation Cases
    for (final c in allCases) {
      final conclusion = c.userConclusion?.trim();
      if (conclusion != null && conclusion.isNotEmpty) {
        allReflections.add(SavedReflectionItem(
          id: 'case_${c.id}',
          text: conclusion,
          date: c.createdAt,
          sourceType: ReflectionSourceType.investigation,
          sourceTitle: c.title.isNotEmpty ? c.title : c.caseNumber,
          originalCase: c,
        ));
      } else if (c.incidentDescription.trim().isNotEmpty) {
        allReflections.add(SavedReflectionItem(
          id: 'case_desc_${c.id}',
          text: c.incidentDescription.trim(),
          date: c.createdAt,
          sourceType: ReflectionSourceType.investigation,
          sourceTitle: c.title.isNotEmpty ? c.title : c.caseNumber,
          originalCase: c,
        ));
      }
    }

    // From Journey Activities
    if (journeyState != null) {
      for (final act in journeyState.activities) {
        if (act.personalNotes.trim().isNotEmpty) {
          allReflections.add(SavedReflectionItem(
            id: 'journey_${act.id}',
            text: act.personalNotes.trim(),
            date: act.completedAt ?? journeyState.updatedAt,
            sourceType: ReflectionSourceType.journeyActivity,
            sourceTitle: act.title,
            originalActivity: act,
          ));
        }
      }
    }

    // Sort newest reflections first
    allReflections.sort((a, b) => b.date.compareTo(a.date));

    // 6. Cumulative Milestones (Honor observation, zero streak pressure)
    final allTimeTraceCount = allTraces.length;
    final allTimeReflectionsCount = allReflections.length;
    final allUniqueEmotions = allTraces.expand((t) => t.selectedEmotions).toSet();
    final validSomaticCount = allTraces.where((t) => t.sleepHours != null && t.energyLevel > 0).length;
    final completedCases = allCases.where((c) => c.isCompleted || c.userConclusion != null).length;
    final journeyExplored = journeyState?.totalCompletedCount ?? 0;
    final totalJourneyActivities = journeyState?.activities.length ?? 17;

    final milestones = <ProgressMilestoneItem>[
      ProgressMilestoneItem(
        id: 'ms_first_star',
        title: strings.isArabic ? 'أثر الفكرة الأول' : (strings.isFrench ? 'Première Empreinte' : 'First Thought Trace'),
        description: strings.isArabic
            ? 'سجلت أول أثر يومي وبدأت أرشيف أفكارك الشخصي.'
            : (strings.isFrench
                ? 'Vous avez enregistré votre première trace et ouvert votre archive de pensées.'
                : 'You recorded your first emotional reflection and began your personal thought archive.'),
        category: 'Observation',
        symbolName: 'ArchiveEntry',
        isUnlocked: allTimeTraceCount >= 1,
        currentValue: allTimeTraceCount,
        targetValue: 1,
      ),
      ProgressMilestoneItem(
        id: 'ms_triad_weaver',
        title: strings.isArabic ? 'راصد الثلاثية' : (strings.isFrench ? 'Observateur de la Triade' : 'Triad Observer'),
        description: strings.isArabic
            ? 'ثلاثة أيام من ملاحظة التفاعل بين الأفكار والأحاسيس والمشاعر.'
            : (strings.isFrench
                ? 'Trois jours d’observation des liens entre pensées, sensations et émotions.'
                : 'Three days of mapping the interplay between thoughts, sensations, and emotions.'),
        category: 'Attunement',
        symbolName: 'Compass',
        isUnlocked: allTimeTraceCount >= 3,
        currentValue: allTimeTraceCount,
        targetValue: 3,
      ),
      ProgressMilestoneItem(
        id: 'ms_seven_cluster',
        title: strings.isArabic ? 'استمرارية التأمل' : (strings.isFrench ? 'Continuité Réflexive' : 'Reflective Continuity'),
        description: strings.isArabic
            ? 'سبعة آثار مسجلة. بدأ أرشيف تأملي عميق يتشكل في سجلك.'
            : (strings.isFrench
                ? 'Sept traces enregistrées. Une archive réflexive prend forme avec clarté.'
                : 'Seven thought traces mapped. A meaningful reflective record is taking shape.'),
        category: 'Observation',
        symbolName: 'Timeline',
        isUnlocked: allTimeTraceCount >= 7,
        currentValue: allTimeTraceCount,
        targetValue: 7,
      ),
      ProgressMilestoneItem(
        id: 'ms_fourteen_cluster',
        title: strings.isArabic ? 'شاهد متواصل' : (strings.isFrench ? 'Témoin Bienveillant' : 'Dedicated Witness'),
        description: strings.isArabic
            ? 'أربعة عشر أثراً مسجلاً. أنت تكتشف أنماطك بثبات ولطف ذاتي.'
            : (strings.isFrench
                ? 'Quatorze traces enregistrées. Vous explorez vos schémas avec régularité.'
                : 'Fourteen traces recorded. You are discovering steady patterns with self-compassion.'),
        category: 'Observation',
        symbolName: 'Cassiopeia',
        isUnlocked: allTimeTraceCount >= 14,
        currentValue: allTimeTraceCount,
        targetValue: 14,
      ),
      ProgressMilestoneItem(
        id: 'ms_emotional_granularity',
        title: strings.isArabic ? 'تنوّع المشاعر' : (strings.isFrench ? 'Granularité Émotionnelle' : 'Emotional Granularity'),
        description: strings.isArabic
            ? 'حددت 5 مشاعر متباينة أو أكثر، مما يدل على وعي عاطفي دقيق.'
            : (strings.isFrench
                ? 'Vous avez nommé 5 émotions distinctes ou plus avec précision.'
                : 'You identified 5 or more distinct emotions, cultivating rich emotional nuance.'),
        category: 'Diversity',
        symbolName: 'Vega',
        isUnlocked: allUniqueEmotions.length >= 5,
        currentValue: allUniqueEmotions.length,
        targetValue: 5,
      ),
      ProgressMilestoneItem(
        id: 'ms_somatic_attunement',
        title: strings.isArabic ? 'تناغم جسدي' : (strings.isFrench ? 'Écoute Somatique' : 'Somatic Attunement'),
        description: strings.isArabic
            ? 'تابعت مؤشرات النوم والطاقة في 5 تدوينات على الأقل.'
            : (strings.isFrench
                ? 'Vous avez corrélé sommeil et niveau d’énergie sur 5 bilans ou plus.'
                : 'Tracked sleep and bodily energy across 5 or more daily traces.'),
        category: 'Attunement',
        symbolName: 'Sirius',
        isUnlocked: validSomaticCount >= 5,
        currentValue: validSomaticCount,
        targetValue: 5,
      ),
      ProgressMilestoneItem(
        id: 'ms_reflective_voice',
        title: strings.isArabic ? 'صوت التأمل' : (strings.isFrench ? 'Voix Réflexive' : 'Reflective Voice'),
        description: strings.isArabic
            ? 'دونت 3 تأملات شخصية بصدق وشجاعة في سجلاتك.'
            : (strings.isFrench
                ? 'Trois réflexions intimes écrites avec honnêteté dans votre espace.'
                : 'Three personal reflections written with honesty across your journal.'),
        category: 'Reflection',
        symbolName: 'Lyra',
        isUnlocked: allTimeReflectionsCount >= 3,
        currentValue: allTimeReflectionsCount,
        targetValue: 3,
      ),
      ProgressMilestoneItem(
        id: 'ms_forensic_inquirer',
        title: strings.isArabic ? 'مستكشف معرفي' : (strings.isFrench ? 'Enquêteur Cognitif' : 'Forensic Inquirer'),
        description: strings.isArabic
            ? 'فككت فكرة تلقائية ووصلت إلى استنتاج فكري في جلسة محقق.'
            : (strings.isFrench
                ? 'Vous avez déconstruit une boucle de pensée et posé un recadrage.'
                : 'Deconstructed an automatic thought to a grounded conclusion in a Case session.'),
        category: 'Exploration',
        symbolName: 'Arcturus',
        isUnlocked: completedCases >= 1,
        currentValue: completedCases,
        targetValue: 1,
      ),
      ProgressMilestoneItem(
        id: 'ms_journey_pioneer',
        title: strings.isArabic ? 'رائد المسار' : (strings.isFrench ? 'Pionnier du Parcours' : 'Journey Pioneer'),
        description: strings.isArabic
            ? 'أتممت تمريناً توجيهياً واستبصارياً ضمن مراحل المسار النفسي.'
            : (strings.isFrench
                ? 'Vous avez exploré et validé un exercice guidé dans votre parcours.'
                : 'Explored and completed a guided psychological exercise in your Journey.'),
        category: 'Exploration',
        symbolName: 'Antares',
        isUnlocked: journeyExplored >= 1,
        currentValue: journeyExplored,
        targetValue: 1,
      ),
      ProgressMilestoneItem(
        id: 'ms_thirty_cluster',
        title: strings.isArabic ? 'فلكي الوعي' : (strings.isFrench ? 'Cartographe Céleste' : 'Cosmic Cartographer'),
        description: strings.isArabic
            ? 'ثلاثون أثراً مرسوماً في مسارك. خريطة رحبة للمرونة والاستبصار الذاتي.'
            : (strings.isFrench
                ? 'Trente traces cartographiées. Une carte intérieure de résilience profonde.'
                : 'Thirty traces mapped across your journey. A profound map of inner resilience.'),
        category: 'Observation',
        symbolName: 'Cygnus',
        isUnlocked: allTimeTraceCount >= 30,
        currentValue: allTimeTraceCount,
        targetValue: 30,
      ),
    ];

    // 7. Cautious, empowering local personal insights ("Patterns Worth Exploring")
    final rawInsights = <PersonalInsightItem>[];

    // Insight A: Emotional Granularity
    if (emotionalVarietyCount >= 4) {
      rawInsights.add(PersonalInsightItem(
        id: 'insight_granularity',
        title: strings.isArabic ? 'تنوّع في التعبير عن المشاعر' : (strings.isFrench ? 'Nuances Émotionnelles' : 'Emotional Granularity'),
        description: strings.isArabic
            ? 'استخدمت $emotionalVarietyCount مشاعر مختلفة مؤخراً. التعبير الدقيق عن الشعور يخفف من حدة الاستجابة التلقائية للجهاز العصبي.'
            : (strings.isFrench
                ? 'Vous avez identifié $emotionalVarietyCount états distincts. Nommer ses émotions avec nuance active la régulation préfrontale.'
                : 'You identified $emotionalVarietyCount distinct emotions recently. Emotional granularity helps the nervous system regulate affective spikes.'),
        caveat: strings.isArabic
            ? 'ملاحظة محلية تعتمد على السجلات المدونة فقط.'
            : (strings.isFrench ? 'Observation formulée d’après vos saisies.' : 'Local heuristic based on your recorded entries.'),
        icon: Icons.palette_outlined,
      ));
    }

    // Insight B: Sleep & Tension Correlation
    if (sleepObservation != null && !sleepObservation.contains('مستمرة') && !sleepObservation.contains('continue') && !sleepObservation.contains('Ongoing')) {
      rawInsights.add(PersonalInsightItem(
        id: 'insight_sleep_tension',
        title: strings.isArabic ? 'رابط النوم والتوتر الجسدي' : (strings.isFrench ? 'Sommeil & Tension' : 'Sleep & Somatic Ease'),
        description: sleepObservation,
        caveat: strings.isArabic
            ? 'هذا الارتباط إحصائي بحت ولا يمثل حكماً طبياً أو سببية حتمية.'
            : (strings.isFrench ? 'Cette corrélation statistique n’implique pas de causalité médicale absolue.' : 'Statistical correlation based on your logs; does not imply medical causality.'),
        icon: Icons.bedtime_outlined,
      ));
    }

    // Insight C: Reflective Honesty
    if (allTimeReflectionsCount >= 2) {
      rawInsights.add(PersonalInsightItem(
        id: 'insight_reflections',
        title: strings.isArabic ? 'قوة التدوين والتأمل' : (strings.isFrench ? 'Écriture Réflexive' : 'Reflective Attunement'),
        description: strings.isArabic
            ? 'لديك $allTimeReflectionsCount تدوينات وتأملات في سجلاتك. تحويل التجارب الداخلية إلى كلمات مكتوبة يساعد العقل على فرز ما يمكن التعامل معه.'
            : (strings.isFrench
                ? 'Vous avez consigné $allTimeReflectionsCount réflexions. Externaliser ses pensées par écrit clarifie les distorsions cognitives.'
                : 'You have recorded $allTimeReflectionsCount personal reflections. Externalizing internal thoughts into written words clarifies mental loops.'),
        caveat: strings.isArabic
            ? 'مستخلصة من اليوميات وجلسات التحقيق وتمارين المسار.'
            : (strings.isFrench ? 'Tiré de vos traces, cas et exercices de parcours.' : 'Derived from traces, cases, and journey exercises.'),
        icon: Icons.auto_stories_outlined,
      ));
    }

    // Insight D: Evening Attunement
    final eveningTraces = filteredTraces.where((t) => t.createdAt.hour >= 18 || t.createdAt.hour < 4).length;
    if (eveningTraces >= 3 && eveningTraces >= (filteredTraces.length * 0.4).round()) {
      rawInsights.add(PersonalInsightItem(
        id: 'insight_evening_routine',
        title: strings.isArabic ? 'هدوء المساء والتأمل' : (strings.isFrench ? 'Pause du Soir' : 'Evening Reflection Rhythm'),
        description: strings.isArabic
            ? 'تفضل غالباً تسجيل أثرك في الفترة المسائية، وهو توقيت ملائم لتفريغ الذهن وتخفيف التوتر المتراكم قبل النوم.'
            : (strings.isFrench
                ? 'Vous enregistrez souvent votre bilan en soirée, un moment propice à la décompression avant la nuit.'
                : 'You frequently record your traces in the evening, creating a calming space to decompress before rest.'),
        caveat: strings.isArabic
            ? 'مستندة إلى توقيت التدوينات.'
            : (strings.isFrench ? 'Basé sur l’heure de vos enregistrements.' : 'Based on entry timestamps.'),
        icon: Icons.nights_stay_outlined,
      ));
    }

    // Filter out dismissed insights
    final activeInsights = rawInsights.where((ins) => !dismissedInsightIds.contains(ins.id)).toList();

    return ProgressAnalyticsModel(
      timeWindow: timeWindow,
      totalEntries: totalEntries,
      uniqueDaysCount: uniqueDaysCount,
      totalEmotionSelections: totalEmotionSelections,
      emotionFrequencies: sortedFrequencies,
      emotionalVarietyCount: emotionalVarietyCount,
      averageIntensity: avgIntensity,
      minIntensity: minIntensity,
      maxIntensity: maxIntensity,
      intensityTimeline: intensityTimeline,
      averageEnergy: avgEnergy,
      averageSleepDuration: avgSleepDuration,
      averageSleepQuality: avgSleepQuality,
      averagePhysicalTension: avgPhysicalTension,
      sleepTensionObservation: sleepObservation,
      chronologicalTraces: filteredTraces,
      allReflections: allReflections,
      milestones: milestones,
      insights: activeInsights,
      journeyActivitiesExplored: journeyExplored,
      totalJourneyActivities: totalJourneyActivities,
      completedCasesCount: completedCases,
    );
  }
}

/// Dynamic Riverpod provider for progress analytics.
final progressAnalyticsProvider = Provider<ProgressAnalyticsModel>((ref) {
  final allTraces = ref.watch(mindTraceControllerProvider).value ?? [];
  final allCases = ref.watch(savedCasesProvider).value ?? [];
  final journeyState = ref.watch(journeyControllerProvider).value;
  final timeWindow = ref.watch(selectedTimeWindowProvider);
  final dismissedInsightIds = ref.watch(dismissedInsightsProvider);
  final strings = ref.watch(appStringsProvider);

  return ProgressAnalyticsCalculator.computeAnalytics(
    allTraces: allTraces,
    allCases: allCases,
    journeyState: journeyState,
    timeWindow: timeWindow,
    dismissedInsightIds: dismissedInsightIds,
    strings: strings,
  );
});
