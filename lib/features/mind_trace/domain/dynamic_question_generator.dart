import '../../profile/domain/condition_type.dart';
import '../../profile/domain/psychological_profile_model.dart';
import 'mind_trace_model.dart';

/// Generates tailored, non-leading, sensitive daily questions based on
/// the user's psychological profile and recent emotional check-in history.
class DynamicQuestionGenerator {
  static List<({String id, String questionText})> getQuestionsForUser({
    required PsychologicalProfileModel? profile,
    required List<MindTraceModel> recentTraces,
    required String languageCode,
  }) {
    final questions = <({String id, String questionText})>[];

    final isAr = languageCode == 'ar';
    final isFr = languageCode == 'fr';

    // 1. Contextual question from profile conditions (if available)
    if (profile != null && profile.conditions.isNotEmpty) {
      final types = profile.conditions.map((c) => c.condition).toSet();

      if (types.contains(ConditionType.ocd)) {
        questions.add((
          id: 'q_recurring_thoughts',
          questionText: isAr
              ? 'هل فقت بأفكار متكررة حاولت تطردها اليوم؟'
              : (isFr
                  ? 'Avez-vous remarqué des pensées répétitives aujourd’hui ?'
                  : 'Have you noticed any recurring thoughts or loops occupying your mind today?'),
        ));
      } else if (types.contains(ConditionType.generalizedAnxiety) ||
          types.contains(ConditionType.socialAnxiety)) {
        questions.add((
          id: 'q_overwhelmed',
          questionText: isAr
              ? 'فما موقف اليوم حسسك بضغط أو تسارع في التفكير؟'
              : (isFr
                  ? 'Une situation a-t-elle suscité un sentiment de débordement ?'
                  : 'Did any particular situation make you feel hurried or overwhelmed today?'),
        ));
      } else if (types.contains(ConditionType.bipolarI) ||
          types.contains(ConditionType.bipolarII)) {
        questions.add((
          id: 'q_energy_rhythm',
          questionText: isAr
              ? 'كيفاش كانت طاقتك وإيقاع نشاطك خلال ساعات النهار؟'
              : (isFr
                  ? 'Comment votre énergie et votre rythme intérieur ont-ils évolué ?'
                  : 'How has your internal energy level and pace felt throughout the day?'),
        ));
      } else if (types.contains(ConditionType.ptsd) ||
          types.contains(ConditionType.complexPtsd)) {
        questions.add((
          id: 'q_groundedness',
          questionText: isAr
              ? 'حسيت بروحك حاضر ومتصل بمحيطك بأمان، ولا حسيت بتباعد؟'
              : (isFr
                  ? 'Vous êtes-vous senti ancré dans votre environnement aujourd’hui ?'
                  : 'Have you felt grounded and present in your surroundings today?'),
        ));
      } else if (types.contains(ConditionType.adhd)) {
        questions.add((
          id: 'q_focus_flow',
          questionText: isAr
              ? 'التركيز متاعك اليوم كان مريح ولا حسيت بتشتت متعب؟'
              : (isFr
                  ? 'Votre concentration était-elle fluide ou fragmentée ?'
                  : 'Did your concentration feel manageable or fragmented today?'),
        ));
      }
    }

    // 2. Contextual question from recent traces (e.g. sleep or tension patterns)
    if (recentTraces.isNotEmpty) {
      final last = recentTraces.first;
      if (last.sleepQuality != null && last.sleepQuality! <= 2) {
        questions.add((
          id: 'q_sleep_recovery',
          questionText: isAr
              ? 'هل كان النوم الليلة هذي أفضل ولا ما زال متعب؟'
              : (isFr
                  ? 'Le sommeil a-t-il été plus réparateur la nuit dernière ?'
                  : 'Was sleep more restful last night, or did fatigue persist?'),
        ));
      } else if (last.physicalTension != null && last.physicalTension! >= 7) {
        questions.add((
          id: 'q_body_ease',
          questionText: isAr
              ? 'وين مخزن التوتر في بدنك اليوم، وهل فما لحظة حسيت فيها برخاوة؟'
              : (isFr
                  ? 'Où réside la tension corporelle aujourd’hui, et y a-t-il eu un répit ?'
                  : 'Where is your body holding tension today, and was there a moment of ease?'),
        ));
      }
    }

    // 3. Fallback / Universal thoughtful inquiries
    if (questions.length < 2) {
      questions.add((
        id: 'q_front_mind',
        questionText: isAr
            ? 'شنوة الموضوع اللي كان واخذ الحيز الأكبر من تفكيرك اليوم؟'
            : (isFr
                ? 'Qu’est-ce qui a le plus occupé vos pensées aujourd’hui ?'
                : 'What has been occupying the forefront of your mind today?'),
      ));
    }

    if (questions.length < 3) {
      questions.add((
        id: 'q_calm_spark',
        questionText: isAr
            ? 'فماش لحظة هدوء أو إحساس خفيف بالراحة لفت انتباهك اليوم؟'
            : (isFr
                ? 'Y a-t-il eu un instant de calme ou de soulagement dans la journée ?'
                : 'Was there a moment of calm, connection, or quiet relief today?'),
      ));
    }

    return questions.take(3).toList();
  }
}

