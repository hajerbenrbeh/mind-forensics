import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_colors.dart';
import '../../../../core/widgets/bouncing_widget.dart';
import '../../controllers/mind_trace_controller.dart';
import '../../domain/mind_trace_model.dart';
import 'thought_trace_detail_sheet.dart';

/// The signature Thought Trace view: an editorial chronological timeline of saved entries.
///
/// Features:
/// - Editorial header and concept quote
/// - Search bar across thoughts, situations, and emotions
/// - Filtering: All, Investigated Only, Date ranges (All, 7D, 30D)
/// - Date grouping: Today, Yesterday, Earlier This Week, Month Year
/// - Hairline timeline thread with fingerprint indicator
/// - Thought snippet in serif quotation styling
/// - Contextual trigger & coping pills
/// - Direct tap to inspect & deconstruct via ThoughtTraceDetailSheet
/// - Thoughtful empty state encouraging first reflection
class ThoughtTraceTimelineView extends ConsumerStatefulWidget {
  const ThoughtTraceTimelineView({
    super.key,
    this.onRecordCheckIn,
  });

  final VoidCallback? onRecordCheckIn;

  @override
  ConsumerState<ThoughtTraceTimelineView> createState() =>
      _ThoughtTraceTimelineViewState();
}

class _ThoughtTraceTimelineViewState
    extends ConsumerState<ThoughtTraceTimelineView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'investigated', 'week', 'month'
  String? _selectedEmotionFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final tracesState = ref.watch(mindTraceControllerProvider);

    return tracesState.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(LabColors.burgundyRose),
        ),
      ),
      error: (err, _) => Center(
        child: Text(
          'Unable to load thought traces.',
          style: const TextStyle(color: LabColors.textSecondary, fontSize: 13),
        ),
      ),
      data: (traces) {
        if (traces.isEmpty) {
          return _buildEmptyState(context, strings);
        }

        // Apply search and filters
        final filtered = _filterTraces(traces);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _buildEditorialHeader(strings),
            const SizedBox(height: 16),
            _buildSearchBar(strings),
            const SizedBox(height: 12),
            _buildFilterPills(strings, traces),
            const SizedBox(height: 18),
            if (filtered.isEmpty)
              _buildNoMatchState(strings)
            else
              ..._buildGroupedTimeline(filtered, strings),
          ],
        );
      },
    );
  }

  Widget _buildEditorialHeader(AppStrings strings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LabColors.surface1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: LabColors.burgundyMaroon.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: LabColors.burgundyRose,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                strings.thoughtTraceTitle.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: LabColors.burgundyRose,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            strings.thoughtTraceQuote,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: LabColors.textPrimary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppStrings strings) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: LabColors.surface1,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: LabColors.borderSubtle, width: 1),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 13, color: LabColors.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          hintText: strings.isArabic
              ? 'ابحث في أرشيف الأفكار والمشاعر...'
              : (strings.isFrench
                  ? 'Rechercher dans vos pensées et émotions...'
                  : 'Search thoughts, situations, emotions...'),
          hintStyle: const TextStyle(
            fontSize: 12,
            color: LabColors.textTertiary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: LabColors.textSecondary,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16, color: LabColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildFilterPills(AppStrings strings, List<MindTraceModel> allTraces) {
    // Collect distinct emotions from records
    final distinctEmotions = <String>{};
    for (final t in allTraces) {
      distinctEmotions.addAll(t.selectedEmotions);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: strings.isArabic ? 'الكل' : 'All',
            isSelected: _selectedFilter == 'all' && _selectedEmotionFilter == null,
            onTap: () {
              setState(() {
                _selectedFilter = 'all';
                _selectedEmotionFilter = null;
              });
            },
          ),
          const SizedBox(width: 6),
          _buildFilterChip(
            label: strings.isArabic ? 'تم فحصها' : 'Investigated',
            isSelected: _selectedFilter == 'investigated',
            onTap: () {
              setState(() {
                _selectedFilter = 'investigated';
                _selectedEmotionFilter = null;
              });
            },
          ),
          const SizedBox(width: 6),
          _buildFilterChip(
            label: strings.isArabic ? 'آخر 7 أيام' : 'Past 7 Days',
            isSelected: _selectedFilter == 'week',
            onTap: () {
              setState(() {
                _selectedFilter = 'week';
                _selectedEmotionFilter = null;
              });
            },
          ),
          const SizedBox(width: 6),
          _buildFilterChip(
            label: strings.isArabic ? 'هذا الشهر' : 'Past 30 Days',
            isSelected: _selectedFilter == 'month',
            onTap: () {
              setState(() {
                _selectedFilter = 'month';
                _selectedEmotionFilter = null;
              });
            },
          ),
          if (distinctEmotions.isNotEmpty) ...[
            const SizedBox(width: 6),
            ...distinctEmotions.take(4).map((emotion) {
              final isSelected = _selectedEmotionFilter == emotion;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _buildFilterChip(
                  label: emotion,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (_selectedEmotionFilter == emotion) {
                        _selectedEmotionFilter = null;
                      } else {
                        _selectedEmotionFilter = emotion;
                        _selectedFilter = 'emotion';
                      }
                    });
                  },
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? LabColors.burgundyRose : LabColors.surface1,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? LabColors.burgundyRose : LabColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? LabColors.surface0 : LabColors.textSecondary,
          ),
        ),
      ),
    );
  }

  List<MindTraceModel> _filterTraces(List<MindTraceModel> traces) {
    var result = List<MindTraceModel>.from(traces)
      ..sort((a, b) => b.date.compareTo(a.date)); // Newest first

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((t) {
        final matchesThought = t.thoughtPreview.toLowerCase().contains(query);
        final matchesEmotions =
            t.selectedEmotions.any((e) => e.toLowerCase().contains(query));
        final matchesSituation =
            t.situation != null && t.situation!.toLowerCase().contains(query);
        final matchesBehavior = t.behavioralResponse != null &&
            t.behavioralResponse!.toLowerCase().contains(query);
        final matchesJournal =
            t.journalText != null && t.journalText!.toLowerCase().contains(query);
        return matchesThought ||
            matchesEmotions ||
            matchesSituation ||
            matchesBehavior ||
            matchesJournal;
      }).toList();
    }

    if (_selectedFilter == 'investigated') {
      result = result.where((t) => t.isInvestigated).toList();
    } else if (_selectedFilter == 'week') {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      result = result.where((t) => t.date.isAfter(weekAgo)).toList();
    } else if (_selectedFilter == 'month') {
      final monthAgo = DateTime.now().subtract(const Duration(days: 30));
      result = result.where((t) => t.date.isAfter(monthAgo)).toList();
    } else if (_selectedEmotionFilter != null) {
      result = result
          .where((t) => t.selectedEmotions.contains(_selectedEmotionFilter))
          .toList();
    }

    return result;
  }

  List<Widget> _buildGroupedTimeline(
    List<MindTraceModel> traces,
    AppStrings strings,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final groups = <String, List<MindTraceModel>>{
      'Today': [],
      'Yesterday': [],
      'Earlier This Week': [],
      'Earlier Entries': [],
    };

    for (final trace in traces) {
      final tDate = DateTime(trace.date.year, trace.date.month, trace.date.day);
      if (tDate.isAtSameMomentAs(today)) {
        groups['Today']!.add(trace);
      } else if (tDate.isAtSameMomentAs(yesterday)) {
        groups['Yesterday']!.add(trace);
      } else if (tDate.isAfter(weekAgo)) {
        groups['Earlier This Week']!.add(trace);
      } else {
        final monthKey = '${_monthName(trace.date.month)} ${trace.date.year}';
        groups.putIfAbsent(monthKey, () => []).add(trace);
      }
    }

    final widgets = <Widget>[];

    groups.forEach((label, groupTraces) {
      if (groupTraces.isEmpty) return;

      final localizedLabel = _localizeGroupLabel(label, strings);

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Row(
            children: [
              Text(
                localizedLabel.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: LabColors.burgundyRose,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 1,
                  color: LabColors.borderSubtle,
                ),
              ),
            ],
          ),
        ),
      );

      for (var i = 0; i < groupTraces.length; i++) {
        final isLast = i == groupTraces.length - 1;
        widgets.add(_buildTimelineItem(groupTraces[i], isLast: isLast, strings: strings));
      }
    });

    return widgets;
  }

  Widget _buildTimelineItem(
    MindTraceModel trace, {
    required bool isLast,
    required AppStrings strings,
  }) {
    final hour = trace.createdAt.hour.toString().padLeft(2, '0');
    final minute = trace.createdAt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical thread with fingerprint node
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 14),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: trace.isInvestigated
                        ? LabColors.burgundyRose
                        : LabColors.surfaceElevated,
                    border: Border.all(
                      color: LabColors.burgundyRose,
                      width: 1.5,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: LabColors.borderSubtle,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Editorial Timeline Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BouncingWidget(
                onTap: () {
                  ThoughtTraceDetailSheet.show(context, trace: trace);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: LabColors.surface1,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: LabColors.borderSubtle,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date, Time & Intensity
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${trace.dateKey} • $timeStr',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: LabColors.textSecondary,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: LabColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: LabColors.borderSubtle),
                                ),
                                child: Text(
                                  '${trace.moodIntensity}/10',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: LabColors.burgundyRose,
                                  ),
                                ),
                              ),
                              if (trace.isInvestigated) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.psychology_outlined,
                                  size: 13,
                                  color: LabColors.burgundyRose,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Thought Preview in Serif Italic
                      Text(
                        '“${trace.thoughtPreview}”',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 13.5,
                          fontStyle: FontStyle.italic,
                          color: LabColors.textPrimary,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Emotion Pills
                      if (trace.selectedEmotions.isNotEmpty) ...[
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: trace.selectedEmotions.take(4).map((e) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: LabColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                    color: LabColors.borderSubtle, width: 0.8),
                              ),
                              child: Text(
                                e,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: LabColors.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Contextual Trigger or Response Snippet
                      if (trace.situation != null &&
                          trace.situation!.trim().isNotEmpty) ...[
                        Row(
                          children: [
                            Text(
                              strings.isArabic ? 'الموقف: ' : 'CONTEXT: ',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: LabColors.textSecondary,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                trace.situation!.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: LabColors.textSecondary.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppStrings strings) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LabColors.surface1,
                border: Border.all(
                  color: LabColors.burgundyRose.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.fingerprint_rounded,
                size: 28,
                color: LabColors.burgundyRose,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              strings.thoughtTraceWaitingTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: LabColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.thoughtTraceWaitingSub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: LabColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            if (widget.onRecordCheckIn != null)
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: widget.onRecordCheckIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LabColors.textPrimary,
                    foregroundColor: LabColors.surface0,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    strings.recordTodayTraceBtn,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMatchState(AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          strings.isArabic
              ? 'لا توجد أفكار مطابقة لمعايير البحث الحالية.'
              : (strings.isFrench
                  ? 'Aucune pensée ne correspond à votre recherche.'
                  : 'No thoughts match the current search or filters.'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: LabColors.textSecondary,
          ),
        ),
      ),
    );
  }

  String _localizeGroupLabel(String label, AppStrings strings) {
    if (label == 'Today') {
      return strings.isArabic
          ? 'اليوم'
          : (strings.isFrench ? 'Aujourd’hui' : 'Today');
    }
    if (label == 'Yesterday') {
      return strings.isArabic
          ? 'الأمس'
          : (strings.isFrench ? 'Hier' : 'Yesterday');
    }
    if (label == 'Earlier This Week') {
      return strings.isArabic
          ? 'سابقاً هذا الأسبوع'
          : (strings.isFrench ? 'Plus tôt cette semaine' : 'Earlier This Week');
    }
    return label;
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return names[month - 1];
  }
}

