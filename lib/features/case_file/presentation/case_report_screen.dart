import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/lab_colors.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/crisis_keywords.dart';
import '../../../core/safety/safety_interceptor.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/label_badge.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../investigation/domain/case_model.dart';
import 'clinical_export_preview_sheet.dart';

/// The official Case File in Report View: Vercel Luxury Dark & Minimalist Precision.
///
/// Trilingual support (authentic Tunisian Arabic, French, English) with full RTL awareness.
class CaseReportScreen extends ConsumerStatefulWidget {
  const CaseReportScreen({super.key, required this.caseId});

  final String caseId;

  @override
  ConsumerState<CaseReportScreen> createState() => _CaseReportScreenState();
}

class _CaseReportScreenState extends ConsumerState<CaseReportScreen> {
  CaseModel? _case;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCase();
  }

  Future<void> _loadCase() async {
    final repo = ref.read(caseRepositoryProvider);
    final found = await repo.getCaseById(widget.caseId);
    if (mounted) {
      setState(() {
        _case = found;
        _isLoading = false;
      });
    }
  }

  void _editConclusionDialog(bool isDark, AppStrings strings) {
    if (_case == null) return;
    final controller = TextEditingController(text: _case!.userConclusion ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ctx.tokens.cardRadius),
          side: BorderSide(color: ctx.tokens.border, width: 1),
        ),
        title: Text(
          strings.editVerdictTitle,
          style: TextStyle(
            color: ctx.tokens.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
          decoration: InputDecoration(
            hintText: strings.yourUpdatedTakeaway,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(strings.cancelBtn, style: TextStyle(color: isDark ? const Color(0xFF888888) : const Color(0xFF71717A))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ctx.tokens.accent,
              foregroundColor: isDark ? ctx.tokens.background : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ctx.tokens.buttonRadius),
              ),
            ),
            onPressed: () async {
              HapticFeedback.lightImpact();
              final newConclusion = controller.text.trim();

              // Layer 1 crisis pre-scan: Intercept Level 2 phrases immediately
              if (CrisisKeywords.evaluateText(newConclusion) == 2) {
                if (ctx.mounted) Navigator.of(ctx).pop();
                SafetyInterceptor.showCrisisPauseDialog(context);
                return;
              }

              final updated = _case!.copyWith(
                userConclusion: newConclusion,
                updatedAt: DateTime.now(),
              );
              await ref.read(caseRepositoryProvider).saveCase(updated);
              setState(() => _case = updated);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text(strings.saveVerdictBtn, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePrivacy(CaseModel c) async {
    HapticFeedback.lightImpact();
    await ref.read(caseRepositoryProvider).toggleCasePrivacy(c.id);
    await _loadCase();
  }

  void _openSessionBriefExport(CaseModel c, AppStrings strings) {
    if (c.isPrivate) {
      HapticFeedback.heavyImpact();
      showDialog(
        context: context,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: ctx.tokens.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ctx.tokens.cardRadius),
              side: BorderSide(color: ctx.tokens.border, width: 1),
            ),
            title: Row(
              children: [
                Icon(Icons.lock_rounded, size: 18, color: ctx.tokens.safetyWarmth),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.privacyShieldTitle,
                    style: TextStyle(
                      color: ctx.tokens.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              strings.caseIsPrivateCannotExport,
              style: TextStyle(fontSize: 12.5, color: ctx.tokens.textSecondary, height: 1.4),
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: ctx.tokens.accent,
                  foregroundColor: isDark ? ctx.tokens.background : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ctx.tokens.buttonRadius),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(strings.closeBtn, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
              ),
            ],
          );
        },
      );
      return;
    }

    ClinicalExportPreviewSheet.show(context, [c]);
  }

  void _deleteCase(bool isDark, AppStrings strings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ctx.tokens.cardRadius),
          side: BorderSide(color: ctx.tokens.border, width: 1),
        ),
        title: Text(
          strings.deleteCaseFileTitle,
          style: TextStyle(
            color: ctx.tokens.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        content: Text(
          strings.deleteCaseWarning,
          style: TextStyle(fontSize: 12.5, color: ctx.tokens.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(strings.cancelBtn, style: TextStyle(color: ctx.tokens.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ctx.tokens.safetyWarmth,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ctx.tokens.buttonRadius),
              ),
            ),
            onPressed: () async {
              HapticFeedback.heavyImpact();
              await ref.read(caseRepositoryProvider).deleteCase(widget.caseId);
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
              if (mounted) {
                context.go('/journal');
              }
            },
            child: Text(strings.deletePermanentlyBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_case == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(title: Text(strings.caseReportTitle)),
        body: Center(child: Text(strings.caseNotFound)),
      );
    }

    final c = _case!;
    final chain = c.chain;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          strings.formatSessionNumber(c.caseNumber),
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.5, color: textPrimary),
        ),
        actions: [
          const SupportButton(),
          IconButton(
            icon: Icon(
              c.isPrivate ? Icons.lock_rounded : Icons.lock_open_outlined,
              size: 18,
              color: c.isPrivate ? (isDark ? LabColors.cherryRedGlow : LabColors.cherryRedDeep) : textSecondary,
            ),
            tooltip: strings.togglePrivacyTooltip,
            onPressed: () => _togglePrivacy(c),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 18),
            tooltip: strings.exportSessionBriefTitle,
            onPressed: () => _openSessionBriefExport(c, strings),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            tooltip: strings.deleteCase,
            onPressed: () => _deleteCase(isDark, strings),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Case Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(context.tokens.cardRadius),
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
                                color: context.tokens.surfaceSecondary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                strings.formatSessionNumber(c.caseNumber),
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _togglePrivacy(c),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: c.isPrivate
                                      ? context.tokens.safetyWarmthSoft
                                      : context.tokens.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: c.isPrivate
                                        ? context.tokens.safetyWarmth.withValues(alpha: 0.35)
                                        : borderColor,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      c.isPrivate ? Icons.lock_rounded : Icons.lock_open_outlined,
                                      size: 11,
                                      color: c.isPrivate
                                          ? context.tokens.safetyWarmth
                                          : textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      c.isPrivate ? strings.casePrivateBadge : strings.caseShareableBadge,
                                      style: TextStyle(
                                        color: c.isPrivate
                                            ? context.tokens.safetyWarmth
                                            : textSecondary,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}',
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      c.title,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, letterSpacing: -0.3, color: textPrimary),
                    ),
                    if (chain != null && chain.emotion.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: LabColors.cherryBackground(isDark: isDark),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: LabColors.cherryBorder(isDark: isDark)),
                        ),
                        child: Text(
                          strings.emotionTag(chain.emotion, chain.emotionIntensity),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: isDark ? LabColors.cherryRedGlow : LabColors.cherryRedDeep,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Section 1: The Incident
              _reportSectionHeader(strings.incidentNarrativeHeader, textSecondary),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Text(
                  c.incidentDescription.isNotEmpty ? c.incidentDescription : strings.noNarrativeRecorded,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Section 2: Forensic Chain & Evidence
              if (chain != null) ...[
                _reportSectionHeader(strings.observableChainHeader, textSecondary),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    children: [
                      _chainRow(strings.triggerTitle, chain.trigger, Icons.location_on_outlined, isDark, textPrimary, textSecondary),
                      Divider(height: 18, color: borderColor),
                      _chainRow(
                        strings.thoughtTitle,
                        chain.thought,
                        Icons.psychology_outlined,
                        isDark,
                        textPrimary,
                        textSecondary,
                        badge: LabelBadge(label: chain.thoughtLabel, compact: true),
                      ),
                      Divider(height: 18, color: borderColor),
                      _chainRow(strings.behaviorTitle, chain.behavior, Icons.directions_walk_outlined, isDark, textPrimary, textSecondary),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Section 3: Alternative Hypotheses
              if (c.hypotheses.isNotEmpty) ...[
                _reportSectionHeader(strings.hypothesesExaminedHeader, textSecondary),
                ...c.hypotheses.map(
                  (h) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: textPrimary)),
                        const SizedBox(height: 4),
                        Text(h.explanation, style: TextStyle(fontSize: 12, color: textSecondary, height: 1.35)),
                        const SizedBox(height: 8),
                        Text('• ${strings.whyItFitsPrefix} ${h.whyItMightFit}', style: const TextStyle(fontSize: 11.5, color: LabColors.factBlue)),
                        const SizedBox(height: 2),
                        Text('• ${strings.whatDoesNotFitPrefix} ${h.whatDoesNotFit}', style: const TextStyle(fontSize: 11.5, color: LabColors.assumptionAmber)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Section 4: My Conclusion
              _reportSectionHeader(strings.groundedVerdictHeader, textSecondary),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: LabColors.beigeBackground(isDark: isDark),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: LabColors.beigeBorder(isDark: isDark),
                    width: 1,
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
                            const Icon(Icons.anchor_rounded, size: 14, color: LabColors.warmBeigeMuted),
                            const SizedBox(width: 6),
                            Text(
                              strings.finalTakeawayUserHeader,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: LabColors.warmBeigeMuted,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => _editConclusionDialog(isDark, strings),
                          child: Text(
                            strings.editBtn,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: isDark ? LabColors.warmBeigeGlow : LabColors.warmBeigeDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c.userConclusion?.isNotEmpty == true ? c.userConclusion! : strings.noConclusionYet,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13.5,
                        height: 1.45,
                        color: isDark ? LabColors.warmBeigeGlow : textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: context.tokens.accent,
                    foregroundColor: isDark ? context.tokens.background : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.tokens.buttonRadius),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.go('/journal');
                  },
                  child: Text(
                    strings.navJournal.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportSectionHeader(String title, Color textSecondary) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8, start: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: textSecondary,
        ),
      ),
    );
  }

  Widget _chainRow(
    String label,
    String content,
    IconData icon,
    bool isDark,
    Color textPrimary,
    Color textSecondary, {
    Widget? badge,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            content.isNotEmpty ? content : '—',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          badge,
        ],
      ],
    );
  }
}
