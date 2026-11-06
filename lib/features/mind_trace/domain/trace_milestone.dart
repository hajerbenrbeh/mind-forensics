/// Non-punitive, positive emotional milestones for The Thought Trace.
///
/// Strictly forbids negative streaks, competitive rankings, or guilt-inducing mechanics.
/// Focuses purely on reflective self-awareness, personal archives, and thought observation.
class TraceMilestone {
  const TraceMilestone({
    required this.id,
    required this.title,
    required this.description,
    required this.symbolName,
    required this.requiredTraces,
    this.requiredReflections = 0,
  });

  final String id;
  final String title;
  final String description;
  final String symbolName;
  final int requiredTraces;
  final int requiredReflections;

  bool isUnlocked(int totalTraces, int totalReflections) {
    return totalTraces >= requiredTraces &&
        totalReflections >= requiredReflections;
  }

  static List<TraceMilestone> get allMilestones => const [
        TraceMilestone(
          id: 'ms_first_star',
          title: 'First Thought Trace',
          description:
              'You recorded your first emotional reflection and began your personal thought archive.',
          symbolName: 'ArchiveEntry',
          requiredTraces: 1,
        ),
        TraceMilestone(
          id: 'ms_triad_weaver',
          title: 'Triad Observer',
          description:
              'Three days of mapping the interplay between thoughts, sensations, and emotions.',
          symbolName: 'Compass',
          requiredTraces: 3,
        ),
        TraceMilestone(
          id: 'ms_reflection_spark',
          title: 'Deep Attunement',
          description:
              'Three personal thought entries logged with thoughtful honesty.',
          symbolName: 'Journal',
          requiredTraces: 3,
          requiredReflections: 3,
        ),
        TraceMilestone(
          id: 'ms_seven_cluster',
          title: 'Reflective Continuity',
          description:
              'Seven thought traces recorded. A meaningful reflective record is taking shape.',
          symbolName: 'Timeline',
          requiredTraces: 7,
        ),
        TraceMilestone(
          id: 'ms_celestial_flow',
          title: 'Pattern Sentinel',
          description:
              'Fourteen thought traces recorded. You are discovering steady patterns with compassion.',
          symbolName: 'Layers',
          requiredTraces: 14,
        ),
        TraceMilestone(
          id: 'ms_constellation_master',
          title: 'Master Archivist',
          description:
              'Thirty thought traces mapped across your journey. A profound archive of resilience and self-awareness.',
          symbolName: 'Vault',
          requiredTraces: 30,
        ),
      ];
}
