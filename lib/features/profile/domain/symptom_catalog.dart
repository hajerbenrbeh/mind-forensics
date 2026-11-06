import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';

/// Categories of self-reported symptoms and difficulties.
enum SymptomCategory {
  emotional,
  thought,
  behavioral,
  other;

  String localized(AppStrings strings) {
    if (strings.isArabic) {
      switch (this) {
        case SymptomCategory.emotional:
          return 'تجارب انفعالية وشعورية';
        case SymptomCategory.thought:
          return 'تجارب فكرية وإدراكية';
        case SymptomCategory.behavioral:
          return 'أنماط سلوكية وتفاعلية';
        case SymptomCategory.other:
          return 'صعوبات جسدية وحسية أخرى';
      }
    }
    switch (this) {
      case SymptomCategory.emotional:
        return 'Emotional experiences';
      case SymptomCategory.thought:
        return 'Thought-related experiences';
      case SymptomCategory.behavioral:
        return 'Behavioral experiences';
      case SymptomCategory.other:
        return 'Other difficulties';
    }
  }

  IconData get icon {
    switch (this) {
      case SymptomCategory.emotional:
        return Icons.water_drop_outlined;
      case SymptomCategory.thought:
        return Icons.psychology_outlined;
      case SymptomCategory.behavioral:
        return Icons.alt_route_rounded;
      case SymptomCategory.other:
        return Icons.grain_outlined;
    }
  }
}

/// Descriptor for individual symptom item.
class SymptomItem {
  final String key;
  final String english;
  final String french;
  final String arabic;
  final SymptomCategory category;

  const SymptomItem({
    required this.key,
    required this.english,
    required this.french,
    required this.arabic,
    required this.category,
  });

  String localized(AppStrings strings) {
    if (strings.isArabic) return arabic;
    if (strings.isFrench) return french;
    return english;
  }
}

class SymptomCatalog {
  static const List<SymptomItem> all = [
    // Emotional experiences
    SymptomItem(
      key: 'sadness',
      english: 'Sadness',
      french: 'Tristesse',
      arabic: 'حزن عميق',
      category: SymptomCategory.emotional,
    ),
    SymptomItem(
      key: 'anxiety',
      english: 'Anxiety',
      french: 'Anxiété',
      arabic: 'قلق وتوجس',
      category: SymptomCategory.emotional,
    ),
    SymptomItem(
      key: 'irritability',
      english: 'Irritability',
      french: 'Irritabilité',
      arabic: 'عصبية وسرعة انفعال',
      category: SymptomCategory.emotional,
    ),
    SymptomItem(
      key: 'emotional_numbness',
      english: 'Emotional numbness',
      french: 'Engourdissement émotionnel',
      arabic: 'تبلد شعوري',
      category: SymptomCategory.emotional,
    ),
    SymptomItem(
      key: 'mood_changes',
      english: 'Mood changes',
      french: 'Variations d’humeur',
      arabic: 'تقلبات مزاجية',
      category: SymptomCategory.emotional,
    ),
    SymptomItem(
      key: 'feeling_overwhelmed',
      english: 'Feeling overwhelmed',
      french: 'Sentiment d’être submergé',
      arabic: 'شعور بالغمر والضغط',
      category: SymptomCategory.emotional,
    ),
    SymptomItem(
      key: 'regulating_emotions',
      english: 'Difficulty regulating emotions',
      french: 'Difficulté à réguler ses émotions',
      arabic: 'صعوبة تنظيم المشاعر',
      category: SymptomCategory.emotional,
    ),

    // Thought-related experiences
    SymptomItem(
      key: 'intrusive_thoughts',
      english: 'Intrusive thoughts',
      french: 'Pensées intrusives',
      arabic: 'أفكار متطفلة وملحة',
      category: SymptomCategory.thought,
    ),
    SymptomItem(
      key: 'racing_thoughts',
      english: 'Racing thoughts',
      french: 'Pensées accélérées',
      arabic: 'تسارع وتزاحم الأفكار',
      category: SymptomCategory.thought,
    ),
    SymptomItem(
      key: 'repetitive_thinking',
      english: 'Repetitive thinking',
      french: 'Ruminations répétitives',
      arabic: 'اجترار فكري متكرر',
      category: SymptomCategory.thought,
    ),
    SymptomItem(
      key: 'unwanted_images',
      english: 'Unwanted mental images',
      french: 'Images mentales indésirables',
      arabic: 'صور ذهنية غير مرغوبة',
      category: SymptomCategory.thought,
    ),
    SymptomItem(
      key: 'difficulty_concentrating',
      english: 'Difficulty concentrating',
      french: 'Difficulté à se concentrer',
      arabic: 'صعوبة في التركيز',
      category: SymptomCategory.thought,
    ),
    SymptomItem(
      key: 'excessive_worrying',
      english: 'Excessive worrying',
      french: 'Inquiétudes excessives',
      arabic: 'قلق مفرط بشأن المستقبل',
      category: SymptomCategory.thought,
    ),
    SymptomItem(
      key: 'understanding_thoughts',
      english: 'Difficulty understanding my thoughts',
      french: 'Difficulté à comprendre mes pensées',
      arabic: 'صعوبة استيعاب أفكاري',
      category: SymptomCategory.thought,
    ),

    // Behavioral experiences
    SymptomItem(
      key: 'avoidance',
      english: 'Avoidance',
      french: 'Évitement',
      arabic: 'التجنب والانسحاب',
      category: SymptomCategory.behavioral,
    ),
    SymptomItem(
      key: 'repetitive_behaviors',
      english: 'Repetitive behaviors',
      french: 'Comportements répétitifs',
      arabic: 'سلوكيات وأفعال قهرية',
      category: SymptomCategory.behavioral,
    ),
    SymptomItem(
      key: 'starting_tasks',
      english: 'Difficulty starting tasks',
      french: 'Difficulté à démarrer des tâches',
      arabic: 'صعوبة المبادرة بالمهام',
      category: SymptomCategory.behavioral,
    ),
    SymptomItem(
      key: 'social_withdrawal',
      english: 'Social withdrawal',
      french: 'Retrait social',
      arabic: 'الانعزال الاجتماعي',
      category: SymptomCategory.behavioral,
    ),
    SymptomItem(
      key: 'maintaining_routines',
      english: 'Difficulty maintaining routines',
      french: 'Difficulté à maintenir des routines',
      arabic: 'صعوبة الالتزام بالروتين',
      category: SymptomCategory.behavioral,
    ),

    // Other
    SymptomItem(
      key: 'sleep_difficulties',
      english: 'Sleep difficulties',
      french: 'Difficultés de sommeil',
      arabic: 'أرق وصعوبات نوم',
      category: SymptomCategory.other,
    ),
    SymptomItem(
      key: 'low_energy',
      english: 'Low energy',
      french: 'Énergie basse',
      arabic: 'خمول وهبوط في الطاقة',
      category: SymptomCategory.other,
    ),
    SymptomItem(
      key: 'restlessness',
      english: 'Restlessness',
      french: 'Agitation',
      arabic: 'تململ وعدم استقرار',
      category: SymptomCategory.other,
    ),
    SymptomItem(
      key: 'feeling_disconnected',
      english: 'Feeling disconnected',
      french: 'Sentiment de déconnexion',
      arabic: 'شعور بالانفصال والغربة',
      category: SymptomCategory.other,
    ),
    SymptomItem(
      key: 'sensory_overwhelm',
      english: 'Sensory overwhelm',
      french: 'Surcharge sensorielle',
      arabic: 'حساسية وفرط تنبيه حسي',
      category: SymptomCategory.other,
    ),
  ];

  static List<SymptomItem> byCategory(SymptomCategory cat) =>
      all.where((s) => s.category == cat).toList();
}

