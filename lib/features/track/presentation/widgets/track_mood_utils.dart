import 'package:flutter/material.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_colors.dart';

/// Shared core mood definitions, icons, colors, and localized labels for Track.
class TrackMoodOption {
  const TrackMoodOption({
    required this.key,
    required this.icon,
    required this.color,
  });

  final String key;
  final IconData icon;
  final Color color;
}

const List<TrackMoodOption> trackCoreMoods = [
  TrackMoodOption(
    key: 'calm',
    icon: Icons.water_drop_outlined,
    color: LabColors.moodCalm,
  ),
  TrackMoodOption(
    key: 'anxious',
    icon: Icons.air_rounded,
    color: LabColors.moodAnxious,
  ),
  TrackMoodOption(
    key: 'frustrated',
    icon: Icons.bolt_rounded,
    color: LabColors.moodFrustrated,
  ),
  TrackMoodOption(
    key: 'heavy',
    icon: Icons.cloud_outlined,
    color: LabColors.moodHeavy,
  ),
  TrackMoodOption(
    key: 'restless',
    icon: Icons.waves_rounded,
    color: LabColors.moodRestless,
  ),
];

TrackMoodOption trackMoodOptionFor(String key) {
  final normalized = key.trim().toLowerCase();
  for (final option in trackCoreMoods) {
    if (option.key == normalized) return option;
  }
  return TrackMoodOption(
    key: normalized,
    icon: Icons.circle_outlined,
    color: LabColors.moodCalm,
  );
}

String trackMoodLabel(String key, AppStrings strings) {
  switch (key.trim().toLowerCase()) {
    case 'calm':
      return strings.moodCalm;
    case 'anxious':
      return strings.moodAnxious;
    case 'frustrated':
      return strings.moodFrustrated;
    case 'heavy':
      return strings.moodHeavy;
    case 'restless':
      return strings.moodRestless;
    default:
      return key;
  }
}

