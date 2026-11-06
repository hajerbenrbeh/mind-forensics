import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';

class PrefChoiceItem {
  final String key;
  final String english;
  final String french;
  final String arabic;
  final IconData? icon;

  const PrefChoiceItem({
    required this.key,
    required this.english,
    required this.french,
    required this.arabic,
    this.icon,
  });

  String localized(AppStrings strings) {
    if (strings.isArabic) return arabic;
    if (strings.isFrench) return french;
    return english;
  }
}

class CommunicationPreferencesCatalog {
  // 1. Tone
  static const List<PrefChoiceItem> tones = [
    PrefChoiceItem(
      key: 'gentle_reassuring',
      english: 'Gentle and reassuring',
      french: 'Bienveillant et rassurant',
      arabic: 'هادئ ومطمئن وصبور',
      icon: Icons.favorite_border_rounded,
    ),
    PrefChoiceItem(
      key: 'calm_analytical',
      english: 'Calm and analytical',
      french: 'Calme et analytique',
      arabic: 'متزن وتحليلي استقصائي',
      icon: Icons.psychology_outlined,
    ),
    PrefChoiceItem(
      key: 'direct_practical',
      english: 'Direct and practical',
      french: 'Direct et pragmatique',
      arabic: 'مباشر وعملي ومختصر',
      icon: Icons.bolt_outlined,
    ),
    PrefChoiceItem(
      key: 'warm_conversational',
      english: 'Warm and conversational',
      french: 'Chaleureux et conversationnel',
      arabic: 'دافئ وحواري قريب',
      icon: Icons.forum_outlined,
    ),
    PrefChoiceItem(
      key: 'detailed_educational',
      english: 'Detailed and educational',
      french: 'Détaillé et pédagogique',
      arabic: 'تعليمي ومعمق نفسياً',
      icon: Icons.school_outlined,
    ),
  ];

  // 2. Response Length
  static const List<PrefChoiceItem> responseLengths = [
    PrefChoiceItem(
      key: 'short_concise',
      english: 'Short and concise',
      french: 'Court et concis',
      arabic: 'قصير وموجز',
      icon: Icons.short_text_rounded,
    ),
    PrefChoiceItem(
      key: 'balanced',
      english: 'Balanced',
      french: 'Équilibré',
      arabic: 'متوازن ومعتدل',
      icon: Icons.subject_rounded,
    ),
    PrefChoiceItem(
      key: 'detailed',
      english: 'Detailed explanations',
      french: 'Explications détaillées',
      arabic: 'شروحات وافية ومفصلة',
      icon: Icons.notes_rounded,
    ),
  ];

  // 3. When I feel distressed, I prefer
  static const List<PrefChoiceItem> distressPreferences = [
    PrefChoiceItem(
      key: 'listen_first',
      english: 'Being listened to first',
      french: 'Être écouté avant tout',
      arabic: 'الاستماع والإنصات أولاً قبل أي شيء',
    ),
    PrefChoiceItem(
      key: 'understand_experience',
      english: 'Understanding what I am experiencing',
      french: 'Comprendre ce que je ressens',
      arabic: 'مساعدتي على فهم ما أختبره شعورياً',
    ),
    PrefChoiceItem(
      key: 'practical_steps',
      english: 'Practical steps',
      french: 'Étapes pratiques immédiates',
      arabic: 'خطوات تأريض وعملية محددة',
    ),
    PrefChoiceItem(
      key: 'gentle_questions',
      english: 'Gentle questions',
      french: 'Questions douces',
      arabic: 'أسئلة هادئة لاستيضاح الفكرة',
    ),
    PrefChoiceItem(
      key: 'space_without_advice',
      english: 'Having space without immediate advice',
      french: 'Avoir de l’espace sans conseil immédiat',
      arabic: 'إعطائي مساحة للتعبير دون نصح فوري',
    ),
  ];

  // 4. What I dislike
  static const List<PrefChoiceItem> dislikedApproaches = [
    PrefChoiceItem(
      key: 'excessive_reassurance',
      english: 'Excessive reassurance',
      french: 'Rassurement excessif',
      arabic: 'التطمين المفرط والمكرر',
    ),
    PrefChoiceItem(
      key: 'generic_motivational',
      english: 'Generic motivational messages',
      french: 'Messages motivationnels génériques',
      arabic: 'الشعارات التحفيزية السطحية',
    ),
    PrefChoiceItem(
      key: 'long_explanations',
      english: 'Long explanations',
      french: 'Longues explications théoriques',
      arabic: 'النصوص الطويلة المعقدة',
    ),
    PrefChoiceItem(
      key: 'judgmental_language',
      english: 'Judgmental language',
      french: 'Langage culpabilisant ou moralisateur',
      arabic: 'أي نبرة لوم أو أحكام ضمنية',
    ),
    PrefChoiceItem(
      key: 'pressured_to_share',
      english: 'Being pressured to share',
      french: 'Pression à me confier',
      arabic: 'الضغط عليّ لمشاركة تفاصيل إضافية',
    ),
    PrefChoiceItem(
      key: 'other_dislikes',
      english: 'Other',
      french: 'Autre',
      arabic: 'أمور أخرى',
    ),
  ];
}

