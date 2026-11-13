import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/localization/locale_controller.dart';
import '../../../app/theme/lab_colors.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/security/app_lock_provider.dart';
import '../../../core/widgets/botanical_emblem.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../backup/data/unified_backup_service.dart';
import '../../case_file/presentation/clinical_export_preview_sheet.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../investigation/data/cloud_sync_service.dart';
import '../../investigation/presentation/widgets/ai_engine_config_sheet.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/presentation/psychological_profile_screen.dart';
import '../../journal/presentation/widgets/journal_memory_sheet.dart';
import 'clinical_sharing_history_sheet.dart';

/// The Lab Settings screen: Vercel Luxury Dark & Minimalist Precision.
///
/// Features:
/// - Forensic Identity & Mental Vault management (Anonymous vs Cloud-Synced)
/// - App Theme (Daylight, Night Lab, System) with clean vector icons
/// - App Language with clean typographic badges [EN, FR, AR]
/// - Gentle Notifications with non-pressuring frequency settings
/// - AI Memory access toggle with SharedPreferences persistence
/// - Biometric App Lock toggle with SharedPreferences persistence
/// - Local Data Wipe / Reset with trilingual confirmation
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const String _prefAiHistory = 'mf_settings_ai_history';
  static const String _prefGentleNotif = 'mf_gentle_notifications';
  static const String _prefNotifFreq = 'mf_notification_freq';

  bool _aiHistoryAccess = true;
  bool _cloudSyncEnabled = true;
  bool _gentleNotifications = false;
  String _notificationFrequency = 'daily';

  @override
  void initState() {
    super.initState();
    _loadPersistedSettings();
  }

  Future<void> _loadPersistedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final syncEnabled = await ref.read(cloudSyncServiceProvider).isSyncEnabled();
    if (mounted) {
      setState(() {
        _aiHistoryAccess = prefs.getBool(_prefAiHistory) ?? true;
        _cloudSyncEnabled = syncEnabled;
        _gentleNotifications = prefs.getBool(_prefGentleNotif) ?? false;
        _notificationFrequency = prefs.getString(_prefNotifFreq) ?? 'daily';
      });
    }
  }

  Future<void> _setGentleNotifications(bool val) async {
    HapticFeedback.lightImpact();
    setState(() => _gentleNotifications = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefGentleNotif, val);
  }

  Future<void> _setNotificationFrequency(String freq) async {
    HapticFeedback.selectionClick();
    setState(() => _notificationFrequency = freq);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefNotifFreq, freq);
  }

  Future<void> _setAiHistory(bool val) async {
    HapticFeedback.lightImpact();
    setState(() => _aiHistoryAccess = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefAiHistory, val);
  }

  void _showUpgradeVaultSheet(BuildContext context, AppStrings strings, bool isDark) {
    HapticFeedback.lightImpact();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final codenameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? LabColors.nightSurface : LabColors.daylightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_upload_outlined, size: 20, color: isDark ? LabColors.nightAccent : LabColors.daylightAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    strings.linkEmailTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: strings.closeBtn,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              strings.linkEmailSubtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: codenameController,
              style: TextStyle(color: isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: strings.codenameFieldHint,
                labelText: strings.codenameFieldLabel,
                filled: true,
                fillColor: isDark ? LabColors.nightSurfaceElevated : LabColors.daylightSurfaceSubtle,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: strings.emailFieldHint,
                labelText: strings.emailFieldLabel,
                filled: true,
                fillColor: isDark ? LabColors.nightSurfaceElevated : LabColors.daylightSurfaceSubtle,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              style: TextStyle(color: isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: strings.passwordFieldHint,
                labelText: strings.passwordFieldLabel,
                filled: true,
                fillColor: isDark ? LabColors.nightSurfaceElevated : LabColors.daylightSurfaceSubtle,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary,
                  foregroundColor: isDark ? LabColors.nightBackground : LabColors.daylightBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  final email = emailController.text.trim();
                  final password = passwordController.text.trim();
                  final codename = codenameController.text.trim();

                  final success = await ref.read(authControllerProvider.notifier).linkEmail(
                    email,
                    password,
                    codename: codename.isNotEmpty ? codename : null,
                  );

                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Account successfully linked to cloud.' : 'Failed to link account.'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Text(
                  strings.linkEmailBtn.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteEverything(AppStrings strings, bool isDark) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? LabColors.nightSurface : LabColors.daylightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isDark ? LabColors.nightBorder : LabColors.daylightBorder, width: 1),
        ),
        title: Text(strings.wipeDataTitle, style: TextStyle(color: isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
        content: Text(strings.wipeDataDesc, style: TextStyle(color: isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(strings.cancelBtn, style: TextStyle(color: isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: LabColors.safetyWarmth,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(caseRepositoryProvider).deleteAllCases();
              await ref.read(authControllerProvider.notifier).deleteAccount();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(strings.allDataWipedSnackbar),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(strings.wipeDataTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _openSharePacketBuilder(BuildContext context, AppStrings strings) async {
    final allCases = await ref.read(savedCasesProvider.future);
    if (!context.mounted) return;
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shareableCases = allCases.where((c) => !c.isPrivate).toList();
    final privateCount = allCases.length - shareableCases.length;
    final selectedIds = <String>{};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final selectedCases = shareableCases.where((c) => selectedIds.contains(c.id)).toList();
          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.82),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.cardRadius)),
              border: Border(top: BorderSide(color: tokens.border)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: tokens.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    strings.sharePacketTitle,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.sharePacketSub,
                    style: TextStyle(fontSize: 12.5, color: tokens.textSecondary),
                  ),
                  if (privateCount > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: tokens.surfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tokens.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 15, color: tokens.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              strings.isArabic
                                  ? 'تم استبعاد $privateCount جلسات خاصة تلقائياً.'
                                  : (strings.isFrench
                                      ? '$privateCount sessions privées exclues automatiquement.'
                                      : '$privateCount private sessions automatically excluded.'),
                              style: TextStyle(fontSize: 11.5, color: tokens.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (shareableCases.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        strings.isArabic
                            ? 'لا توجد جلسات غير خاصة جاهزة للمشاركة بعد.'
                            : (strings.isFrench
                                ? 'Aucune session partageable disponible pour le moment.'
                                : 'No non-private reflections available to include yet.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: shareableCases.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, idx) {
                          final item = shareableCases[idx];
                          final checked = selectedIds.contains(item.id);
                          final label = item.title.trim().isNotEmpty
                              ? item.title.trim()
                              : (item.incidentDescription.trim().isNotEmpty
                                  ? item.incidentDescription.trim()
                                  : item.caseNumber);
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => setSheetState(() {
                              if (checked) {
                                selectedIds.remove(item.id);
                              } else {
                                selectedIds.add(item.id);
                              }
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: checked ? tokens.accentSoft : tokens.surfaceSecondary,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: checked ? tokens.accent : tokens.border),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: checked,
                                    activeColor: tokens.accent,
                                    onChanged: (_) => setSheetState(() {
                                      if (checked) {
                                        selectedIds.remove(item.id);
                                      } else {
                                        selectedIds.add(item.id);
                                      }
                                    }),
                                  ),
                                  Expanded(
                                    child: Text(
                                      label,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: checked ? FontWeight.w600 : FontWeight.w500,
                                        color: tokens.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (shareableCases.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.accent,
                          foregroundColor: isDark ? tokens.background : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(tokens.buttonRadius),
                          ),
                        ),
                        onPressed: selectedCases.isEmpty
                            ? null
                            : () {
                                Navigator.of(ctx).pop();
                                ClinicalExportPreviewSheet.show(context, selectedCases);
                              },
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: Text(
                          strings.isArabic
                              ? 'معاينة الحزمة (${selectedCases.length})'
                              : (strings.isFrench
                                  ? 'Aperçu du dossier (${selectedCases.length})'
                                  : 'Preview Share Packet (${selectedCases.length})'),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentThemeMode = ref.watch(themeControllerProvider);
    final currentLocale = ref.watch(localeControllerProvider);
    final strings = ref.watch(appStringsProvider);

    final bg = isDark ? LabColors.nightBackground : LabColors.daylightBackground;
    final surfaceColor = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final borderColor = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary = isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary = isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          strings.settingsTitle.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 1.2,
            color: textPrimary,
          ),
        ),
        actions: const [
          SupportButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Phone 8 Hero: Member Avatar & Account Card
            Center(
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.tokens.accentSoft,
                      border: Border.all(
                        color: context.tokens.accent.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const BotanicalEmblem(size: 40),
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, _) {
                      final authState = ref.watch(authControllerProvider);
                      final profileAsync = ref.watch(profileControllerProvider);
                      final preferred = profileAsync.value?.preferredName;
                      final displayName = (preferred != null && preferred.isNotEmpty)
                          ? preferred
                          : (authState.user?.codename.isNotEmpty == true
                              ? authState.user!.codename
                              : (strings.isArabic
                                  ? 'مستكشف'
                                  : (strings.isFrench
                                      ? 'Observateur'
                                      : 'Observer')));
                      return Column(
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strings.memberRoleLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            MindCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PsychologicalProfileScreen(),
                  ),
                );
              },
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.tokens.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.eco_outlined,
                      size: 20,
                      color: context.tokens.accent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.myAccountTitle,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.myAccountSub,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            MindCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: () {
                HapticFeedback.lightImpact();
                AiEngineConfigSheet.show(context);
              },
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.tokens.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 20,
                      color: context.tokens.accent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.mindAssistantEngineTitle,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.mindAssistantEngineSub,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 0A: Forensic Identity & Mental Vault
            Consumer(
              builder: (context, ref, _) {
                final authState = ref.watch(authControllerProvider);
                final user = authState.user;
                final codename = user?.codename ??
                    (strings.isArabic
                        ? 'مستكشف'
                        : (strings.isFrench ? 'Observateur' : 'Observer'));
                final isAnon = user?.isAnonymous ?? true;
                final email = user?.email;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel(strings.authTitle.toUpperCase(), textSecondary),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: borderColor,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? LabColors.nightSurfaceElevated : LabColors.daylightSurfaceSubtle,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.shield_outlined,
                                  size: 20,
                                  color: isDark ? LabColors.nightAccent : LabColors.daylightAccent,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            codename,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: (isDark ? LabColors.nightAccent : LabColors.daylightAccent).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isAnon ? 'ANONYMOUS' : 'CLOUD SYNCED',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.4,
                                              color: isDark ? LabColors.nightAccent : LabColors.daylightAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      isAnon ? strings.vaultStatusAnonymous : (email ?? strings.vaultStatusCloud),
                                      style: TextStyle(fontSize: 11, color: textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (isAnon) ...[
                            const SizedBox(height: 12),
                            Divider(color: borderColor, height: 1),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark ? LabColors.nightAccent : LabColors.daylightAccent,
                                  side: BorderSide(
                                    color: isDark ? LabColors.nightAccent.withValues(alpha: 0.3) : LabColors.daylightAccent.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                ),
                                icon: const Icon(Icons.cloud_upload_outlined, size: 15),
                                label: Text(
                                  strings.linkEmailTitle.toUpperCase(),
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                                ),
                                onPressed: () => _showUpgradeVaultSheet(context, strings, isDark),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),

            // Section 0B: My Psychological Profile Entry Card
            _sectionLabel(strings.myPsychologicalProfileTitle.toUpperCase(), textSecondary),
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PsychologicalProfileScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? LabColors.nightAccent.withValues(alpha: 0.3) : LabColors.daylightAccent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: LabColors.sageBackground(isDark: isDark),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fingerprint_rounded,
                        size: 20,
                        color: LabColors.sageGreenGlow,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.myPsychologicalProfileTitle,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            strings.profileSubtitle,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: textSecondary,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Section 1: Appearance & Theme
            _sectionLabel(strings.themeModeTitle.toUpperCase(), textSecondary),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.themeModeTitle, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _themePill(strings.themeDaylight, Icons.light_mode_outlined, ThemeMode.light, currentThemeMode, isDark, textPrimary, textSecondary, borderColor),
                      const SizedBox(width: 8),
                      _themePill(strings.themeNight, Icons.dark_mode_outlined, ThemeMode.dark, currentThemeMode, isDark, textPrimary, textSecondary, borderColor),
                      const SizedBox(width: 8),
                      _themePill(strings.themeSystem, Icons.tune_outlined, ThemeMode.system, currentThemeMode, isDark, textPrimary, textSecondary, borderColor),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 2: Language & Region
            _sectionLabel(strings.languageTitle.toUpperCase(), textSecondary),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.languageTitle, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppLanguage.values.map((lang) {
                      final isSelected = currentLocale.languageCode == lang.code;
                      return InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref.read(localeControllerProvider.notifier).setLanguage(lang);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? LabColors.nightSurfaceElevated : LabColors.daylightSurfaceSubtle)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? LabColors.nightAccent : LabColors.daylightAccent)
                                  : borderColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                lang.shortCode,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? (isDark ? LabColors.nightAccent : LabColors.daylightAccent) : textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                lang.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? textPrimary : textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 3: Gentle Reflection Notifications
            _sectionLabel(
              strings.isArabic
                  ? 'إشعارات التأمل الهادئة'
                  : (strings.isFrench
                      ? 'NOTIFICATIONS DE RÉFLEXION DOUCES'
                      : 'GENTLE REFLECTION NOTIFICATIONS'),
              textSecondary,
            ),
            Container(
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.isArabic
                                  ? 'إشعارات هادئة وغير ملزمة'
                                  : (strings.isFrench
                                      ? 'Invitations douces'
                                      : 'Gentle Invitations'),
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              strings.isArabic
                                  ? 'تذكيرات لطيفة للتأمل دون ضغط أو عدادات أيام متتالية.'
                                  : (strings.isFrench
                                      ? 'Rappels bienveillants pour faire une pause et observer, sans pression ni séries.'
                                      : 'Thoughtful reminders to pause and observe. No streak pressure or guilt.'),
                              style: TextStyle(fontSize: 12, color: textSecondary, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _gentleNotifications,
                        activeTrackColor: context.tokens.accent,
                        activeThumbColor: context.tokens.background,
                        inactiveThumbColor: context.tokens.textTertiary,
                        inactiveTrackColor: context.tokens.surfaceSecondary,
                        onChanged: _setGentleNotifications,
                      ),
                    ],
                  ),
                  if (_gentleNotifications) ...[
                    const SizedBox(height: 14),
                    Divider(color: borderColor, height: 1),
                    const SizedBox(height: 12),
                    Text(
                      strings.isArabic
                          ? 'وتيرة الإشعارات'
                          : (strings.isFrench
                              ? 'FRÉQUENCE DES INVITATIONS'
                              : 'NOTIFICATION FREQUENCY'),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: isDark ? LabColors.nightAccent : LabColors.daylightAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _notifFreqChip(
                            'daily',
                            strings.isArabic
                                ? 'يومياً'
                                : (strings.isFrench ? 'Quotidien' : 'Daily'),
                            isDark,
                            borderColor),
                        const SizedBox(width: 8),
                        _notifFreqChip(
                            'alternate',
                            strings.isArabic
                                ? 'يوم بيوم'
                                : (strings.isFrench
                                    ? 'Un jour sur deux'
                                    : 'Alternate Days'),
                            isDark,
                            borderColor),
                        const SizedBox(width: 8),
                        _notifFreqChip(
                            'weekly',
                            strings.isArabic
                                ? 'أسبوعياً'
                                : (strings.isFrench ? 'Hebdomadaire' : 'Weekly'),
                            isDark,
                            borderColor),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? LabColors.nightSurfaceElevated : LabColors.daylightSurfaceSubtle,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.notifications_active_outlined, size: 16, color: isDark ? LabColors.nightAccent : LabColors.daylightAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              strings.isArabic
                                  ? 'مثال: "أثر ذهنك اليومي ينتظرك وقتما تكون مستعداً."'
                                  : 'Sample: "Your daily Mind Trace is waiting whenever you\'re ready."',
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 4: AI Memory & Past Cases
            _sectionLabel(strings.aiHistoryTitle.toUpperCase(), textSecondary),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.aiHistoryTitle,
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.aiHistoryDesc,
                          style: TextStyle(fontSize: 12, color: textSecondary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch(
                    value: _aiHistoryAccess,
                    activeTrackColor: context.tokens.accent,
                    activeThumbColor: context.tokens.background,
                    inactiveThumbColor: context.tokens.textTertiary,
                    inactiveTrackColor: context.tokens.surfaceSecondary,
                    onChanged: _setAiHistory,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 5: Device Security
            _sectionLabel(strings.biometricLockTitle.toUpperCase(), textSecondary),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.biometricLockTitle,
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.biometricLockDesc,
                          style: TextStyle(fontSize: 12, color: textSecondary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Consumer(
                    builder: (context, ref, _) {
                      final appLockState = ref.watch(appLockProvider);
                      return Switch(
                        value: appLockState.isEnabled,
                        activeTrackColor: context.tokens.accent,
                        activeThumbColor: context.tokens.background,
                        inactiveThumbColor: context.tokens.textTertiary,
                        inactiveTrackColor: context.tokens.surfaceSecondary,
                        onChanged: (val) async {
                          final success = await ref.read(appLockProvider.notifier).toggleBiometrics(val);
                          if (!success && val && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(strings.biometricNotAvailableSnackbar),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 6: Data Backup & Cloud Synchronization
            _sectionLabel(
              strings.isArabic
                  ? 'النسخ الاحتياطي والمزامنة السحابية'
                  : (strings.isFrench
                      ? 'SAUVEGARDE ET RESTAURATION CLOUD'
                      : 'DATA BACKUP & CLOUD RESTORATION'),
              textSecondary,
            ),
            Container(
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  strings.cloudSyncTitle,
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isDark ? LabColors.nightAccent : LabColors.daylightAccent).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: (isDark ? LabColors.nightAccent : LabColors.daylightAccent).withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    'SPARK & LOCAL',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                      color: isDark ? LabColors.nightAccent : LabColors.daylightAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              strings.cloudSyncDesc,
                              style: TextStyle(fontSize: 12, color: textSecondary, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _cloudSyncEnabled,
                        activeTrackColor: context.tokens.accent,
                        activeThumbColor: context.tokens.background,
                        inactiveThumbColor: context.tokens.textTertiary,
                        inactiveTrackColor: context.tokens.surfaceSecondary,
                        onChanged: (val) async {
                          HapticFeedback.lightImpact();
                          setState(() => _cloudSyncEnabled = val);
                          await ref.read(cloudSyncServiceProvider).setSyncEnabled(val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? LabColors.nightSurfaceElevated : LabColors.daylightSurfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shield_outlined, size: 14, color: isDark ? LabColors.sageGreenGlow : LabColors.forestGreen),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                strings.isArabic
                                    ? 'التخزين المحلي السيادي: نشط'
                                    : (strings.isFrench
                                        ? 'STOCKAGE LOCAL SOUVERAIN : ACTIF'
                                        : 'LOCAL SOVEREIGN STORAGE: ACTIVE'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: isDark ? LabColors.sageGreenGlow : LabColors.forestGreen),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.isArabic
                              ? 'كل السجلات اليومية وجلسات الاستبصار والملف النفسي محفوظة بأمان على جهازك. يتم تفعيل المزامنة السحابية تلقائياً عند توفر بيانات Firebase.'
                              : (strings.isFrench
                                  ? 'Tous vos journaux d’humeur, sessions de réflexion et profils cliniques sont conservés en sécurité sur cet appareil.'
                                  : 'All mood logs, reflection sessions, and clinical profiles are securely stored on this device. Cloud sync activates automatically when Firebase credentials (google-services.json) are provided.'),
                          style: TextStyle(fontSize: 11, color: textSecondary, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(color: borderColor, width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.backup_outlined, size: 15),
                          label: Text(
                            strings.isArabic
                                ? 'نسخ احتياطي الآن'
                                : (strings.isFrench
                                    ? 'SAUVEGARDER'
                                    : 'BACKUP NOW'),
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                          ),
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            final result = await ref.read(unifiedBackupServiceProvider).createFullBackup();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    strings.isArabic
                                        ? 'اكتمل النسخ الاحتياطي: ${result.tracesCount} أثر، ${result.sessionsCount} جلسات، ${result.memoriesCount} خلاصات محفوظة.'
                                        : (strings.isFrench
                                            ? 'Sauvegarde terminée : ${result.tracesCount} empreintes, ${result.sessionsCount} sessions, ${result.memoriesCount} souvenirs préservés.'
                                            : 'Backup complete: ${result.tracesCount} traces, ${result.sessionsCount} sessions, ${result.memoriesCount} memories preserved.'),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(color: borderColor, width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.file_download_outlined, size: 15),
                          label: Text(
                            strings.exportVaultBtn.toUpperCase(),
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                          ),
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            final result = await ref.read(unifiedBackupServiceProvider).createFullBackup();
                            if (result.rawJson != null) {
                              Clipboard.setData(ClipboardData(text: result.rawJson!));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(strings.exportVaultSuccess),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 7: Clinical Sharing History
            _sectionLabel(strings.clinicalSharingHistoryTitle.toUpperCase(), textSecondary),
            Container(
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.clinicalSharingHistoryTitle,
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              strings.clinicalSharingHistoryDesc,
                              style: TextStyle(fontSize: 12, color: textSecondary, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.tokens.accent,
                        foregroundColor: isDark ? context.tokens.background : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      icon: const Icon(Icons.inventory_2_outlined, size: 16),
                      label: Text(
                        strings.sharePacketTitle,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _openSharePacketBuilder(context, strings);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: BorderSide(color: borderColor, width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.history_edu_outlined, size: 16),
                      label: Text(
                        strings.clinicalSharingHistoryTitle.toUpperCase(),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ClinicalSharingHistorySheet.show(context);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 8: Data Transparency & Privacy
            _sectionLabel(strings.dataTransparencyTitle, textSecondary),
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                JournalMemorySheet.show(context);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.psychology_outlined, size: 22, color: context.tokens.accent),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.memoryVaultTitle,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strings.isArabic
                                ? 'عرض ومراجعة المعلومات التي يتذكرها المساعد الذكي عنك'
                                : 'Review and manage what the AI companion remembers',
                            style: TextStyle(fontSize: 11.5, color: textSecondary, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 20, color: textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.privacyPrinciplesTitle,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.privacyPrinciplesBody,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Phone 8: Sign Out Action
            MindButton(
              text: strings.signOutBtn,
              variant: MindButtonVariant.secondary,
              isFullWidth: true,
              onPressed: () async {
                HapticFeedback.lightImpact();
                await ref.read(authControllerProvider.notifier).signOut();
              },
            ),

            const SizedBox(height: 16),

            // Danger Zone: Delete Everything
            Center(
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: LabColors.safetyWarmth,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text(
                  strings.wipeDataTitle.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
                ),
                onPressed: () => _confirmDeleteEverything(strings, isDark),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
    );
  }

  Widget _notifFreqChip(String freq, String label, bool isDark, Color borderColor) {
    final isSelected = _notificationFrequency == freq;
    return InkWell(
      onTap: () => _setNotificationFrequency(freq),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? LabColors.nightSurfaceElevated : LabColors.daylightSurfaceSubtle)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? LabColors.nightAccent : LabColors.daylightAccent)
                : borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? context.tokens.accent
                : context.tokens.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _themePill(
    String label,
    IconData icon,
    ThemeMode mode,
    ThemeMode current,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    final isSelected = mode == current;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          ref.read(themeControllerProvider.notifier).setTheme(mode);
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? LabColors.nightSurfaceElevated : LabColors.daylightSurfaceSubtle)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? (isDark ? LabColors.nightAccent : LabColors.daylightAccent)
                  : borderColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? (isDark ? LabColors.nightAccent : LabColors.daylightAccent) : textSecondary,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? (isDark ? LabColors.nightAccent : LabColors.daylightAccent) : textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String title, Color textSecondary) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8, start: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
