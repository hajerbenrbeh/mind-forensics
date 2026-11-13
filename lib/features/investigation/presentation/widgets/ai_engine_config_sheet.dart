import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/lab_colors.dart';
import '../../controllers/investigation_providers.dart';
import '../../data/direct_gemini_investigator_service.dart';

/// Modal bottom sheet allowing users and developers to inspect AI status,
/// test Google Gemini connectivity, switch between Live and Test Mode,
/// and securely manage their Gemini developer key.
class AiEngineConfigSheet extends ConsumerStatefulWidget {
  const AiEngineConfigSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiEngineConfigSheet(),
    );
  }

  @override
  ConsumerState<AiEngineConfigSheet> createState() => _AiEngineConfigSheetState();
}

class _AiEngineConfigSheetState extends ConsumerState<AiEngineConfigSheet> {
  late final TextEditingController _keyController;
  bool _obscureKey = true;
  bool _isTesting = false;
  String? _testResult;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    final config = ref.read(aiConfigProvider);
    final keyToDisplay = config.isMockKey ? '' : config.apiKey;
    _keyController = TextEditingController(text: keyToDisplay);
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _testResult = 'Please enter an API key to test connection.';
        _testSuccess = false;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });
    HapticFeedback.lightImpact();

    try {
      final service = DirectGeminiInvestigatorService(apiKey: key);
      final result = await service.testConnection();
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = result.success;
          _testResult = result.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testResult = 'Connection check failed: $e';
        });
      }
    }
  }

  Future<void> _saveKey() async {
    final key = _keyController.text.trim();
    HapticFeedback.mediumImpact();
    await ref.read(aiConfigProvider.notifier).setApiKey(key);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(key.isNotEmpty
              ? 'Gemini API key saved and activated.'
              : 'Switched to offline clinical simulator.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clearKey() async {
    HapticFeedback.lightImpact();
    await ref.read(aiConfigProvider.notifier).clearApiKey();
    if (mounted) {
      _keyController.clear();
      setState(() {
        _testResult = null;
        _testSuccess = null;
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API key cleared. Offline mock mode active.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final aiConfig = ref.watch(aiConfigProvider);

    final bg = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final border = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final textPrimary = isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary;
    final textSecondary = isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: border, width: 1)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 20, color: isDark ? LabColors.sageGreenGlow : LabColors.forestGreen),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'MIND ASSISTANT ENGINE',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: aiConfig.isLiveActive
                        ? LabColors.sageGreenGlow.withValues(alpha: 0.15)
                        : LabColors.warmBeige.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    aiConfig.isLiveActive ? 'LIVE GEMINI' : 'TEST MODE (\$0.00)',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: aiConfig.isLiveActive ? LabColors.sageGreenGlow : LabColors.warmBeige,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Mind Forensics connects directly to Google AI Studio for live multi-turn reasoning, or runs in offline clinical test mode with zero data transmission.',
              style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Mode Selector: Test Mode toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? LabColors.nightSurfaceElevated : LabColors.daylightSurfaceSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Development / Test Mode',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Enforce offline mock mode for zero-cost and automated testing.',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: !aiConfig.useLiveAi || aiConfig.isMockKey,
                    onChanged: (isTestMode) async {
                      HapticFeedback.lightImpact();
                      await ref.read(aiConfigProvider.notifier).toggleLiveMode(!isTestMode);
                    },
                    activeThumbColor: LabColors.warmBeige,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'GOOGLE GEMINI API KEY',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _keyController,
              obscureText: _obscureKey,
              style: TextStyle(fontSize: 13, color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Paste key from aistudio.google.com...',
                hintStyle: TextStyle(fontSize: 12, color: textSecondary.withValues(alpha: 0.6)),
                filled: true,
                fillColor: isDark ? LabColors.nightSurfaceElevated : LabColors.daylightSurfaceSubtle,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1.5)),
                suffixIcon: IconButton(
                  tooltip: 'Toggle key visibility',
                  icon: Icon(_obscureKey ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ),
              ),
            ),

            if (_testResult != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_testSuccess == true ? LabColors.sageGreenGlow : LabColors.safetyWarmth).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _testSuccess == true ? LabColors.sageGreenGlow : LabColors.safetyWarmth,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _testSuccess == true ? Icons.check_circle_outline : Icons.error_outline,
                      size: 16,
                      color: _testSuccess == true ? LabColors.sageGreenGlow : LabColors.safetyWarmth,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _testSuccess == true ? LabColors.sageGreenGlow : LabColors.safetyWarmth,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isTesting ? null : _testConnection,
                    child: _isTesting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(
                            'TEST CONNECTION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: textPrimary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _saveKey,
                    child: const Text(
                      'SAVE & ACTIVATE',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),

            if (_keyController.text.isNotEmpty || !aiConfig.isMockKey) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: LabColors.safetyWarmth),
                  onPressed: _clearKey,
                  child: const Text('Revert to Offline Mock Mode', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
