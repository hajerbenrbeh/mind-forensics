import 'package:flutter/material.dart';
import '../../../app/localization/app_strings.dart';
import '../../profile/domain/condition_type.dart';

/// Categories of psychological and somatic symptoms.
enum SymptomDomain {
  mood,
  anxiety,
  cognitive,
  attention,
  somatic,
  stress;

  String localized(AppStrings strings) {
    if (strings.isArabic) {
      switch (this) {
        case SymptomDomain.mood:
          return 'المزاج والانفعال';
        case SymptomDomain.anxiety:
          return 'القلق والتوتر';
        case SymptomDomain.cognitive:
          return 'الأفكار والإدراك';
        case SymptomDomain.attention:
          return 'الانتباه والتركيز';
        case SymptomDomain.somatic:
          return 'الجسد والحواس';
        case SymptomDomain.stress:
          return 'الضغط والصدمات';
      }
    }
    switch (this) {
      case SymptomDomain.mood:
        return 'Mood & Emotion';
      case SymptomDomain.anxiety:
        return 'Anxiety & Tension';
      case SymptomDomain.cognitive:
        return 'Thoughts & Cognition';
      case SymptomDomain.attention:
        return 'Focus & Attention';
      case SymptomDomain.somatic:
        return 'Somatic & Body';
      case SymptomDomain.stress:
        return 'Stress & Trauma';
    }
  }

  IconData get icon {
    switch (this) {
      case SymptomDomain.mood:
        return Icons.water_drop_outlined;
      case SymptomDomain.anxiety:
        return Icons.bolt_outlined;
      case SymptomDomain.cognitive:
        return Icons.psychology_outlined;
      case SymptomDomain.attention:
        return Icons.radar_outlined;
      case SymptomDomain.somatic:
        return Icons.spa_outlined;
      case SymptomDomain.stress:
        return Icons.shield_outlined;
    }
  }
}

/// An individual symptom item in the condition-first library.
class SymptomEntry {
  final String id;
  final String titleEn;
  final String titleFr;
  final String titleAr;
  final String descriptionEn;
  final String descriptionFr;
  final String descriptionAr;
  final SymptomDomain domain;
  final ConditionType? relatedCondition;
  final bool isCustom;
  final DateTime? createdAt;

  const SymptomEntry({
    required this.id,
    required this.titleEn,
    required this.titleFr,
    required this.titleAr,
    required this.descriptionEn,
    required this.descriptionFr,
    required this.descriptionAr,
    required this.domain,
    this.relatedCondition,
    this.isCustom = false,
    this.createdAt,
  });

  String title(AppStrings strings) {
    if (strings.isArabic) return titleAr;
    if (strings.isFrench) return titleFr;
    return titleEn;
  }

  String localizedTitle(AppStrings strings) => title(strings);

  String description(AppStrings strings) {
    if (strings.isArabic) return descriptionAr;
    if (strings.isFrench) return descriptionFr;
    return descriptionEn;
  }

  String localizedDescription(AppStrings strings) => description(strings);

  Map<String, dynamic> toJson() => {
        'id': id,
        'titleEn': titleEn,
        'titleFr': titleFr,
        'titleAr': titleAr,
        'descriptionEn': descriptionEn,
        'descriptionFr': descriptionFr,
        'descriptionAr': descriptionAr,
        'domain': domain.name,
        'relatedCondition': relatedCondition?.name,
        'isCustom': isCustom,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory SymptomEntry.fromJson(Map<String, dynamic> json) {
    final conditionName = json['relatedCondition'] as String?;
    ConditionType? condition;
    if (conditionName != null) {
      try {
        condition = ConditionType.values.firstWhere((c) => c.name == conditionName);
      } catch (_) {}
    }

    final domainName = json['domain'] as String? ?? 'mood';
    final domain = SymptomDomain.values.firstWhere(
      (d) => d.name == domainName,
      orElse: () => SymptomDomain.mood,
    );

    return SymptomEntry(
      id: json['id'] as String,
      titleEn: json['titleEn'] as String? ?? '',
      titleFr: json['titleFr'] as String? ?? '',
      titleAr: json['titleAr'] as String? ?? '',
      descriptionEn: json['descriptionEn'] as String? ?? '',
      descriptionFr: json['descriptionFr'] as String? ?? '',
      descriptionAr: json['descriptionAr'] as String? ?? '',
      domain: domain,
      relatedCondition: condition,
      isCustom: json['isCustom'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

