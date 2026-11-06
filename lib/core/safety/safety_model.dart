/// The three safety triage tiers defined in Section 6.
enum SafetyLevel {
  /// Level 0: Normal investigation. Ordinary stress, frustration, sadness.
  /// The app proceeds as usual.
  level0Normal,

  /// Level 1: Soft redirect (elevated distress).
  /// Acknowledges feelings first, shifts to supportive tone with fewer hypotheses,
  /// offers to continue later, keeps support option visible.
  level1SoftRedirect,

  /// Level 2: Gentle pause (possible crisis).
  /// Investigation stops (no analysis, no hypotheses, no findings).
  /// Responds with warmth, shows crisis resources with one-tap access.
  /// Never a dead end: the user can return to the case afterward.
  level2GentlePause,
}

/// Represents an emergency or crisis helpline resource.
class CrisisResource {
  const CrisisResource({
    required this.name,
    required this.description,
    required this.phone,
    this.sms,
    this.website,
    required this.countryCode,
    this.isTollFree = false,
  });

  final String name;
  final String description;
  final String phone;
  final String? sms;
  final String? website;
  final String countryCode;
  final bool isTollFree;

  /// Official Tunisian and Regional Crisis Resources.
  ///
  /// Section 6: "Crisis resources depend on country, so a region-aware list is needed."
  static const List<CrisisResource> tunisianResources = [
    CrisisResource(
      name: 'Numéro Vert d’Aide Psychologique\nالخط الأخضر للمساعدة النفسية',
      description:
          'Numéro vert gratuit du Ministère de la Santé pour l’écoute, le soutien et l’orientation psychologique.',
      phone: '80105050',
      countryCode: 'TN',
      isTollFree: true,
    ),
    CrisisResource(
      name: 'SAMU - Urgences Médicales\nالإسعاف الطبي الاستعجالي',
      description:
          'Urgences médicales et psychiatriques 24h/24 et 7j/7 partout en Tunisie.',
      phone: '190',
      countryCode: 'TN',
      isTollFree: false,
    ),
    CrisisResource(
      name: 'Protection Civile\nالحماية المدنية',
      description:
          'Secours d’urgence, assistance immédiate et intervention de crise 24h/24.',
      phone: '198',
      countryCode: 'TN',
      isTollFree: false,
    ),
    CrisisResource(
      name: 'Ligne d’Écoute et de Soutien Social\nخط الإشعار والدعم النفسي',
      description:
          'Numéro vert gratuit d’écoute, de prise en charge psychologique et d’assistance.',
      phone: '1899',
      countryCode: 'TN',
      isTollFree: true,
    ),
    CrisisResource(
      name: 'Befrienders Worldwide\nالدعم العاطفي الدولي',
      description:
          'Réseau international d’écoute bienveillante et confidentielle accessible en ligne.',
      phone: '',
      website: 'https://www.befrienders.org',
      countryCode: 'GLOBAL',
      isTollFree: false,
    ),
  ];
}
