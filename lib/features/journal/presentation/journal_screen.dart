import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/lab_colors.dart';
import '../../../core/safety/support_button.dart';
import '../../case_file/presentation/clinical_export_preview_sheet.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../investigation/domain/case_model.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../mind_trace/presentation/widgets/trace_entry_detail_sheet.dart';
import '../../../core/widgets/bouncing_widget.dart';

/// The Journal screen listing all past investigations.
///
/// Vercel Luxury Dark & Minimalist Precision.
class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  int _selectedJournalTab = 0; // 0: Cases, 1: Daily Traces
  List<CaseModel> _cases = [];
  bool _isLoading = true;
  bool _hidePreviews = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedCaseIds = {};

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCases() async {
    final repo = ref.read(caseRepositoryProvider);
    final all = await repo.getAllCases();
    if (mounted) {
      setState(() {
        _cases = all;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);

    final bg = isDark ? LabColors.nightBackground : LabColors.daylightBackground;
    final surfaceColor = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final borderColor = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary = isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary = isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    final traces = ref.watch(mindTraceControllerProvider).value ?? [];

    final filteredCases = _searchQuery.isEmpty
        ? _cases
        : _cases.where((c) {
            final q = _searchQuery.toLowerCase();
            final titleMatch = c.title.toLowerCase().contains(q);
            final descMatch = c.incidentDescription.toLowerCase().contains(q);
            final emotionMatch = c.chain?.emotion.toLowerCase().contains(q) ?? false;
            final numMatch = c.caseNumber.toLowerCase().contains(q);
            return titleMatch || descMatch || emotionMatch || numMatch;
          }).toList();

    final filteredTraces = _searchQuery.isEmpty
        ? traces
        : traces.where((t) {
            final q = _searchQuery.toLowerCase();
            final moodMatch = t.overallMood.toLowerCase().contains(q);
            final dateMatch = t.dateKey.contains(q);
            final notesMatch = t.journalText?.toLowerCase().contains(q) ?? false;
            final emotionsMatch =
                t.selectedEmotions.any((e) => e.toLowerCase().contains(q));
            return moodMatch || dateMatch || notesMatch || emotionsMatch;
          }).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          _isSelectionMode ? strings.exportSelectionMode.toUpperCase() : strings.navJournal.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 1.2,
            color: textPrimary,
          ),
        ),
        actions: [
          if (!_isSelectionMode) ...[
            const SupportButton(),
            IconButton(
              icon: Icon(
                _hidePreviews ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: textPrimary,
              ),
              tooltip: _hidePreviews ? strings.showPreviewsTooltip : strings.hidePreviewsTooltip,
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _hidePreviews = !_hidePreviews);
              },
            ),
            IconButton(
              icon: const Icon(Icons.outbox_rounded, size: 18),
              tooltip: strings.exportSelectionMode,
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _isSelectionMode = true;
                  _selectedCaseIds.clear();
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              tooltip: strings.cancelBtn,
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedCaseIds.clear();
                });
              },
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: _isSelectionMode
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(top: BorderSide(color: borderColor, width: 1)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.sessionsSelectedCount(_selectedCaseIds.length),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = false;
                          _selectedCaseIds.clear();
                        });
                      },
                      child: Text(strings.cancelBtn, style: TextStyle(color: textSecondary, fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary,
                        foregroundColor: isDark ? LabColors.nightBackground : LabColors.daylightBackground,
                        disabledBackgroundColor: isDark ? const Color(0xFF222222) : const Color(0xFFE4E4E7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: _selectedCaseIds.isEmpty
                          ? null
                          : () {
                              final selectedCases = _cases.where((c) => _selectedCaseIds.contains(c.id)).toList();
                              ClinicalExportPreviewSheet.show(context, selectedCases);
                            },
                      child: Text(
                        strings.previewBriefBtn,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : Column(
                children: [
                  // Segmented Vault Switcher
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isDark ? LabColors.nightSurfaceElevated : LabColors.daylightSurfaceSubtle,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: BouncingWidget(
                              onTap: () {
                                if (_selectedJournalTab != 0) {
                                  HapticFeedback.lightImpact();
                                  setState(() => _selectedJournalTab = 0);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: _selectedJournalTab == 0
                                      ? (isDark ? LabColors.nightSurface : LabColors.daylightSurface)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _selectedJournalTab == 0
                                        ? (isDark ? LabColors.nightAccent.withValues(alpha: 0.4) : LabColors.daylightAccent.withValues(alpha: 0.3))
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '${strings.isArabic ? 'جلسات التحقيق' : 'Forensic Cases'} (${_cases.length})',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                    color: _selectedJournalTab == 0
                                        ? (isDark ? LabColors.nightAccent : LabColors.daylightAccent)
                                        : textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: BouncingWidget(
                              onTap: () {
                                if (_selectedJournalTab != 1) {
                                  HapticFeedback.lightImpact();
                                  setState(() => _selectedJournalTab = 1);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: _selectedJournalTab == 1
                                      ? (isDark ? LabColors.nightSurface : LabColors.daylightSurface)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _selectedJournalTab == 1
                                        ? (isDark ? LabColors.nightAccent.withValues(alpha: 0.4) : LabColors.daylightAccent.withValues(alpha: 0.3))
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '${strings.isArabic ? 'آثار الذهن اليومية' : 'Daily Traces'} (${traces.length})',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                    color: _selectedJournalTab == 1
                                        ? (isDark ? LabColors.nightAccent : LabColors.daylightAccent)
                                        : textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      style: TextStyle(fontSize: 12.5, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: _selectedJournalTab == 0
                            ? (strings.isArabic
                                ? 'بحث في الجلسات...'
                                : (strings.isFrench ? 'Rechercher une session...' : 'Search cognitive sessions...'))
                            : (strings.isArabic
                                ? 'بحث في السجلات اليومية...'
                                : 'Search daily traces, moods, notes...'),
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF555555) : const Color(0xFFA1A1AA),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 16,
                          color: isDark ? const Color(0xFF777777) : const Color(0xFF71717A),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 14),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark ? LabColors.nightSurface : LabColors.daylightSurface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: borderColor, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: borderColor, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? LabColors.nightAccent : LabColors.daylightAccent,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // List Content
                  Expanded(
                    child: _selectedJournalTab == 0
                        ? (filteredCases.isEmpty
                            ? _buildEmptyState(isDark, strings, textPrimary, textSecondary)
                            : RefreshIndicator(
                                onRefresh: _loadCases,
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  itemCount: filteredCases.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                                  itemBuilder: (ctx, index) {
                                    final c = filteredCases[index];
                                    return _buildCaseCard(c, isDark, strings, surfaceColor, borderColor, textPrimary, textSecondary);
                                  },
                                ),
                              ))
                        : (filteredTraces.isEmpty
                            ? _buildTracesEmptyState(isDark, strings, textPrimary, textSecondary)
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                itemCount: filteredTraces.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 8),
                                itemBuilder: (ctx, index) {
                                  final t = filteredTraces[index];
                                  return _buildTraceCard(t, isDark, strings, surfaceColor, borderColor, textPrimary, textSecondary);
                                },
                              )),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTracesEmptyState(
    bool isDark,
    AppStrings strings,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? LabColors.nightSurfaceElevated : LabColors.daylightSurfaceSubtle,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? LabColors.nightBorder : LabColors.daylightBorder),
              ),
              child: Icon(
                Icons.auto_awesome_outlined,
                size: 32,
                color: isDark ? LabColors.nightAccent : LabColors.daylightAccent,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              strings.isArabic ? 'لا توجد آثار يومية مسجلة بعد' : 'No Daily Traces Recorded Yet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.isArabic
                  ? 'سجل أثرك النفسي اليومي من الشاشة الرئيسية لبناء سجلك الزمني وتتبع أفكارك.'
                  : 'Log your daily mind trace from Home to build your thought trace and track patterns.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary,
                foregroundColor: isDark ? LabColors.nightBackground : LabColors.daylightBackground,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                (strings.isArabic ? 'تسجيل أثر اليوم' : 'Log Daily Mind Trace').toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
              ),
              onPressed: () => context.push('/mind-trace'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTraceCard(
    MindTraceModel trace,
    bool isDark,
    AppStrings strings,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        TraceEntryDetailSheet.show(context, trace: trace);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? LabColors.nightSurfaceElevated : LabColors.daylightSurfaceSubtle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? LabColors.nightBorder : LabColors.daylightBorder,
                        ),
                      ),
                      child: Text(
                        trace.overallMood.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isDark ? LabColors.nightAccent : LabColors.daylightAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isDark ? LabColors.nightSurfaceSubtle : const Color(0xFFE4E4E7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${trace.moodIntensity} / 10',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    if (trace.voiceNotePath != null) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.mic_none_rounded, size: 12, color: isDark ? LabColors.nightAccent : LabColors.daylightAccent),
                    ],
                  ],
                ),
                Text(
                  trace.dateKey,
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
            if (trace.selectedEmotions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: trace.selectedEmotions.take(4).map((em) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isDark ? LabColors.nightSurfaceElevated : LabColors.daylightSurfaceSubtle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      em,
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: textSecondary),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (trace.journalText != null && trace.journalText!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _hidePreviews ? '••••••••••••••••••••' : trace.journalText!.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, height: 1.35, color: textPrimary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    bool isDark,
    AppStrings strings,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? LabColors.nightSurfaceElevated : LabColors.daylightSurfaceSubtle,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? LabColors.nightBorder : LabColors.daylightBorder),
              ),
              child: Icon(
                Icons.folder_open_outlined,
                size: 32,
                color: isDark ? LabColors.nightAccent : LabColors.daylightAccent,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              strings.noCasesRecordedTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.noCasesRecordedDesc,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary,
                foregroundColor: isDark ? LabColors.nightBackground : LabColors.daylightBackground,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                strings.newInvestigation.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
              ),
              onPressed: () async {
                HapticFeedback.mediumImpact();
                ref.read(activeCaseControllerProvider.notifier).startNewCase('Unopened Session');
                await context.push('/investigation');
                _loadCases();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseCard(
    CaseModel c,
    bool isDark,
    AppStrings strings,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final chain = c.chain;
    final isSelected = _selectedCaseIds.contains(c.id);

    return Opacity(
      opacity: (_isSelectionMode && c.isPrivate) ? 0.55 : 1.0,
      child: InkWell(
        onTap: () async {
          if (_isSelectionMode) {
            if (c.isPrivate) {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(strings.caseIsPrivateCannotExport, style: const TextStyle(fontSize: 11.5)),
                  duration: const Duration(seconds: 2),
                ),
              );
              return;
            }
            HapticFeedback.selectionClick();
            setState(() {
              if (isSelected) {
                _selectedCaseIds.remove(c.id);
              } else {
                _selectedCaseIds.add(c.id);
              }
            });
          } else {
            HapticFeedback.lightImpact();
            await context.push('/case/${c.id}');
            _loadCases();
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? (isDark ? LabColors.nightAccent : LabColors.daylightAccent)
                  : borderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: c.isCompleted
                              ? LabColors.beigeBackground(isDark: isDark)
                              : LabColors.cherryBackground(isDark: isDark),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: c.isCompleted
                                ? LabColors.beigeBorder(isDark: isDark)
                                : LabColors.cherryBorder(isDark: isDark),
                          ),
                        ),
                        child: Text(
                          strings.formatSessionNumber(c.caseNumber),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: c.isCompleted
                                ? (isDark ? LabColors.warmBeigeGlow : LabColors.warmBeigeDark)
                                : (isDark ? LabColors.cherryRedGlow : LabColors.cherryRedDeep),
                          ),
                        ),
                      ),
                      if (c.isPrivate) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: LabColors.cherryBackground(isDark: isDark),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: LabColors.cherryBorder(isDark: isDark)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_rounded,
                                size: 10,
                                color: isDark ? LabColors.cherryRedGlow : LabColors.cherryRedDeep,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                strings.isArabic ? 'سري' : (strings.isFrench ? 'CONFIDENTIEL' : 'PRIVATE'),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: isDark ? LabColors.cherryRedGlow : LabColors.cherryRedDeep,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_isSelectionMode)
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: c.isPrivate
                            ? (isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE4E4E7))
                            : (isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark ? const Color(0xFF444444) : const Color(0xFFA1A1AA)),
                          width: 1.5,
                        ),
                      ),
                      child: c.isPrivate
                          ? Icon(Icons.lock_outline, size: 12, color: textSecondary)
                          : isSelected
                              ? Icon(Icons.check, size: 12, color: isDark ? Colors.black : Colors.white)
                              : null,
                    )
                  else
                    Text(
                      '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}',
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _hidePreviews ? '••••••••••••••••••••' : c.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, letterSpacing: -0.2, color: textPrimary),
              ),
              if (chain != null && chain.emotion.isNotEmpty) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: c.isCompleted ? LabColors.warmBeige : LabColors.cherryRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _hidePreviews
                            ? strings.emotionHiddenPrivacy
                            : strings.feltEmotionSub(chain.emotion, chain.emotionIntensity),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: textSecondary,
                          fontStyle: _hidePreviews ? FontStyle.italic : FontStyle.normal,
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
    );
  }
}
