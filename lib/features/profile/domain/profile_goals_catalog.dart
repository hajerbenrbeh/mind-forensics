import '../../../app/localization/app_strings.dart';

class ProfileGoalItem {
  final String key;
  final String english;
  final String french;
  final String arabic;

  const ProfileGoalItem({
    required this.key,
    required this.english,
    required this.french,
    required this.arabic,
  });

  String localized(AppStrings strings) {
    if (strings.isArabic) return arabic;
    if (strings.isFrench) return french;
    return english;
  }
}

class ProfileGoalsCatalog {
  static const List<ProfileGoalItem> standardGoals = [
    ProfileGoalItem(
      key: 'understand_thoughts',
      english: 'Understand my thoughts',
      french: 'Comprendre mes pensées',
      arabic: 'فهم أفكاري ومساراتها',
    ),
    ProfileGoalItem(
      key: 'understand_emotions',
      english: 'Understand my emotions',
      french: 'Comprendre mes émotions',
      arabic: 'فهم مشاعري والوعي بها',
    ),
    ProfileGoalItem(
      key: 'recognize_patterns',
      english: 'Recognize recurring patterns',
      french: 'Reconnaître les schémas récurrents',
      arabic: 'رصد أنماطي الفكرية المتكررة',
    ),
    ProfileGoalItem(
      key: 'understand_intrusive_thoughts',
      english: 'Understand intrusive thoughts',
      french: 'Comprendre les pensées intrusives',
      arabic: 'فهم الأفكار المتطفلة والتعامل معها',
    ),
    ProfileGoalItem(
      key: 'improve_emotional_regulation',
      english: 'Improve emotional regulation',
      french: 'Améliorer la régulation émotionnelle',
      arabic: 'تطوير مهارات تنظيم المشاعر',
    ),
    ProfileGoalItem(
      key: 'understand_anxiety',
      english: 'Understand my anxiety',
      french: 'Mieux comprendre mon anxiété',
      arabic: 'فهم جذور القلق لديّ',
    ),
    ProfileGoalItem(
      key: 'understand_mood_changes',
      english: 'Better understand mood changes',
      french: 'Mieux cerner les fluctuations d’humeur',
      arabic: 'استيعاب تقلبات مزاجي',
    ),
    ProfileGoalItem(
      key: 'develop_self_awareness',
      english: 'Develop self-awareness',
      french: 'Développer la conscience de soi',
      arabic: 'تنمية الوعي الذاتي العميق',
    ),
    ProfileGoalItem(
      key: 'understand_behaviors',
      english: 'Understand my behaviors',
      french: 'Comprendre mes comportements',
      arabic: 'فهم دوافع سلوكياتي وتصرفاتي',
    ),
    ProfileGoalItem(
      key: 'explore_coping_strategies',
      english: 'Explore coping strategies',
      french: 'Explorer des stratégies d’adaptation',
      arabic: 'استكشاف استراتيجيات تأقلم صحية',
    ),
    ProfileGoalItem(
      key: 'improve_daily_routines',
      english: 'Improve daily routines',
      french: 'Améliorer mes routines quotidiennes',
      arabic: 'تحسين الروتين والعادات اليومية',
    ),
    ProfileGoalItem(
      key: 'build_confidence',
      english: 'Build confidence',
      french: 'Renforcer la confiance en soi',
      arabic: 'بناء الثقة والأمان الداخلي',
    ),
    ProfileGoalItem(
      key: 'improve_relationship_with_self',
      english: 'Improve my relationship with myself',
      french: 'Améliorer ma relation avec moi-même',
      arabic: 'تحسين علاقتي برحمة مع نفسي',
    ),
  ];
}

