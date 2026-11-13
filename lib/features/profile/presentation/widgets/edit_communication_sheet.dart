import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_colors.dart';
import '../../../../app/theme/lab_theme.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/bouncing_widget.dart';
import '../../controllers/profile_controller.dart';
import '../../domain/communication_preferences_catalog.dart';
import '../../domain/psychological_profile_model.dart';

class EditCommunicationSheet extends ConsumerStatefulWidget {
  const EditCommunicationSheet({super.key, required this.profile});

  final PsychologicalProfileModel profile;

  static Future<void> show(BuildContext context, PsychologicalProfileModel profile) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditCommunicationSheet(profile: profile),
    );
  }

  @override
  ConsumerState<EditCommunicationSheet> createState() =>
      _EditCommunicationSheetState();
}

class _EditCommunicationSheetState extends ConsumerState<EditCommunicationSheet> {
  late String _selectedTone;
  late String _selectedLength;
  late Set<String> _distressPreferences;
  late Set<String> _dislikedApproaches;

  @override
  void initState() {
    super.initState();
    _selectedTone = widget.profile.communicationTone.isNotEmpty
        ? widget.profile.communicationTone
        : 'calm_analytical';
    _selectedLength = widget.profile.responseLength.isNotEmpty
        ? widget.profile.responseLength
        : 'balanced';
    _distressPreferences = Set.from(widget.profile.distressPreferences);
    _dislikedApproaches = Set.from(widget.profile.dislikedApproaches);
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    await ref.read(profileControllerProvider.notifier).updateCommunicationPreferences(
      communicationTone: _selectedTone,
      responseLength: _selectedLength,
      distressPreferences: _distressPreferences.toList(),
      dislikedApproaches: _dislikedApproaches.toList(),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);

    final bg = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final border = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary = isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary = isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                strings.sectionCommunication,
                style: LabTheme.serifStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.sectionCommunicationDesc,
                style: TextStyle(fontSize: 11.5, color: textSecondary),
              ),

              const SizedBox(height: 12),
              Divider(color: border, height: 1),
              const SizedBox(height: 12),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // 1. Tone
                    Text(
                      (strings.isArabic ? 'النبرة وأسلوب الحوار' : 'COMPANION TONE').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: context.tokens.accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...CommunicationPreferencesCatalog.tones.map((tone) {
                      final isSelected = _selectedTone == tone.key;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedTone = tone.key);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.tokens.accentSoft
                                  : context.tokens.surfaceSecondary,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? context.tokens.accent : border,
                                width: isSelected ? 1.2 : 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (tone.icon != null) ...[
                                  Icon(tone.icon, size: 16, color: isSelected ? context.tokens.accent : textSecondary),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Text(
                                    tone.localized(strings),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? textPrimary : textPrimary,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_rounded, size: 14, color: context.tokens.accent),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 18),

                    // 2. Response Length
                    Text(
                      (strings.isArabic ? 'طول الشروحات والردود' : 'RESPONSE LENGTH').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: context.tokens.accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: CommunicationPreferencesCatalog.responseLengths.map((len) {
                        final isSelected = _selectedLength == len.key;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedLength = len.key);
                              },
                              borderRadius: BorderRadius.circular(context.tokens.chipRadius),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? context.tokens.accentSoft
                                      : context.tokens.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(context.tokens.chipRadius),
                                  border: Border.all(
                                    color: isSelected ? context.tokens.accent : border,
                                  ),
                                ),
                                child: Text(
                                  len.localized(strings),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? context.tokens.accent : textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // 3. When distressed
                    Text(
                      (strings.isArabic ? 'عندما أشعر بالتوتر أو الضيق، أفضّل' : 'WHEN I FEEL DISTRESSED, I PREFER').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: context.tokens.accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: CommunicationPreferencesCatalog.distressPreferences.map((pref) {
                        final isSelected = _distressPreferences.contains(pref.key);
                        return InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (isSelected) {
                                _distressPreferences.remove(pref.key);
                              } else {
                                _distressPreferences.add(pref.key);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(context.tokens.chipRadius),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.tokens.accentSoft
                                  : context.tokens.surfaceSecondary,
                              borderRadius: BorderRadius.circular(context.tokens.chipRadius),
                              border: Border.all(
                                color: isSelected ? context.tokens.accent : border,
                                width: isSelected ? 1 : 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  Icon(Icons.check_rounded, size: 12, color: context.tokens.accent),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  pref.localized(strings),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? context.tokens.accent : textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // 4. What I dislike
                    Text(
                      (strings.isArabic ? 'أساليب أنفر منها ولا تناسبني' : 'WHAT I DISLIKE / AVOID').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: context.tokens.safetyWarmth,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: CommunicationPreferencesCatalog.dislikedApproaches.map((item) {
                        final isSelected = _dislikedApproaches.contains(item.key);
                        return InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (isSelected) {
                                _dislikedApproaches.remove(item.key);
                              } else {
                                _dislikedApproaches.add(item.key);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(context.tokens.chipRadius),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.tokens.safetyWarmthSoft
                                  : context.tokens.surfaceSecondary,
                              borderRadius: BorderRadius.circular(context.tokens.chipRadius),
                              border: Border.all(
                                color: isSelected ? context.tokens.safetyWarmth : border,
                                width: isSelected ? 1 : 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  Icon(Icons.remove_circle_outline_rounded, size: 12, color: context.tokens.safetyWarmth),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  item.localized(strings),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? context.tokens.safetyWarmth : textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              BouncingWidget(
                onTap: _save,
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    color: context.tokens.accent,
                    borderRadius: BorderRadius.circular(context.tokens.buttonRadius),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (strings.isArabic ? 'حفظ تفضيلات التواصل' : 'SAVE PREFERENCES').toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isDark ? context.tokens.background : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

