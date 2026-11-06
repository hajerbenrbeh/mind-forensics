import 'journey_activity.dart';
import 'journey_phase.dart';

/// State of the user's psychological exploration journey.
///
/// Follows non-judgmental principles: no recovery percentages, no mandatory linear order.
class JourneyStateModel {
  const JourneyStateModel({
    required this.activities,
    this.activePhase = JourneyPhase.phase1SelfDiscovery,
    required this.updatedAt,
  });

  factory JourneyStateModel.initial(List<JourneyActivity> activities) =>
      JourneyStateModel(
        activities: activities,
        activePhase: JourneyPhase.phase1SelfDiscovery,
        updatedAt: DateTime.now(),
      );

  final List<JourneyActivity> activities;
  final JourneyPhase activePhase;
  final DateTime updatedAt;

  List<JourneyActivity> getActivitiesForPhase(JourneyPhase phase) {
    return activities.where((a) => a.phase == phase).toList();
  }

  JourneyActivity? getActivity(String id) {
    final idx = activities.indexWhere((a) => a.id == id);
    return idx != -1 ? activities[idx] : null;
  }

  int get totalCompletedCount => activities.where((a) => a.isCompleted).length;
  int get completedCount => totalCompletedCount;

  int completedCountForPhase(JourneyPhase phase) =>
      activities.where((a) => a.phase == phase && a.isCompleted).length;

  int totalCountForPhase(JourneyPhase phase) =>
      activities.where((a) => a.phase == phase).length;

  JourneyStateModel copyWith({
    List<JourneyActivity>? activities,
    JourneyPhase? activePhase,
    DateTime? updatedAt,
  }) {
    return JourneyStateModel(
      activities: activities ?? this.activities,
      activePhase: activePhase ?? this.activePhase,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'activities': activities.map((a) => a.toJson()).toList(),
        'activePhase': activePhase.name,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory JourneyStateModel.fromJson(
    Map<String, dynamic> json,
    List<JourneyActivity> defaultActivities,
  ) {
    final rawList = json['activities'] as List<dynamic>?;
    final List<JourneyActivity> loadedActivities = [];

    if (rawList != null && rawList.isNotEmpty) {
      final savedMap = {
        for (var item in rawList)
          (item as Map<String, dynamic>)['id'] as String:
              JourneyActivity.fromJson(item)
      };

      for (final defaultAct in defaultActivities) {
        if (savedMap.containsKey(defaultAct.id)) {
          loadedActivities.add(savedMap[defaultAct.id]!);
        } else {
          loadedActivities.add(defaultAct);
        }
      }
    } else {
      loadedActivities.addAll(defaultActivities);
    }

    return JourneyStateModel(
      activities: loadedActivities,
      activePhase: JourneyPhase.fromString(
        json['activePhase'] as String? ?? '',
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
