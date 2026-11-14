import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/lab_colors.dart';
import '../../controllers/investigation_providers.dart';
import '../../data/direct_gemini_investigator_service.dart';
import '../../data/direct_groq_investigator_service.dart';

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

  late AiEngineProvider _selectedProvider;

  @override
  void initState() {
    super.initState();
    final config = ref.read(aiConfigProvider);
    _selectedProvider = config.provider;
    final keyToDisplay = config.isMockKey ? '' : config.activeApiKey;
    _keyController = TextEditingController(text: keyToDisplay);
  }

  void _switchProvider(AiEngineProvider provider) {
    HapticFeedback.selectionClick();
    final config = ref.read(aiConfigProvider);
    ref.read(aiConfigProvider.notifier).setProvider(provider);
    final nextKey = provider == AiEngineProvider.groq
        ? config.groqApiKey
        : (config.apiKey == kDevMockGeminiKey ? '' : config.apiKey);
    setState(() {
      _selectedProvider = provider;
      _keyController.text = nextKey;
      _testResult = null;
      _testSuccess = null;
    });
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final key = _keyController.text.trim();
    final config = ref.read(aiConfigProvider);
    if (key.isEmpty && !(_selectedProvider == AiEngineProvider.groq && config.hasProxy)) {
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
      final ({bool success, String message}) result;
      if (_selectedProvider == AiEngineProvider.groq) {
        final service = DirectGroqInvestigatorService(
          apiKey: key,
          proxyUrl: config.proxyUrl,
        );
        result = await service.testConnection();
      } else {
        final service = DirectGeminiInvestigatorService(apiKey: key);
        result = await service.testConnection();
      }
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
    await ref.read(aiConfigProvider.notifier).setApiKey(
          key,
          provider: _selectedProvider,
        );
    final providerLabel =
        _selectedProvider == AiEngineProvider.groq ? 'Groq' : 'Gemini';
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(key.isNotEmpty
              ? '$providerLabel API key saved and activated.'
              : 'Switched to offline clinical simulator.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clearKey() async {
    HapticFeedback.lightImpact();
    await ref
        .read(aiConfigProvider.notifier)
        .clearApiKey(provider: _selectedProvider);
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
                      fontFamily: 'Inter',
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
                    aiConfig.isLiveActive
                        ? (aiConfig.provider == AiEngineProvider.groq
                            ? 'LIVE GROQ'
                            : 'LIVE GEMINI')
                        : 'TEST MODE (\$0.00)',
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
              'Mind Forensics supports Groq (Llama 3.3 free tier) or Google Gemini for live specialist dialogue, or offline mock mode with zero transmission.',
              style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
            ),
            const SizedBox(height: 14),

            // Provider Selector (Groq vs Gemini)
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    selected: _selectedProvider == AiEngineProvider.groq,
                    label: const Center(
                      child: Text(
                        'Groq (Free Llama)',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    onSelected: (_) => _switchProvider(AiEngineProvider.groq),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    selected: _selectedProvider == AiEngineProvider.gemini,
                    label: const Center(
                      child: Text(
                        'Google Gemini',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    onSelected: (_) => _switchProvider(AiEngineProvider.gemini),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

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
              _selectedProvider == AiEngineProvider.groq
                  ? 'GROQ API KEY (CONSOLE.GROQ.COM)'
                  : 'GOOGLE GEMINI API KEY',
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
                hintText: _selectedProvider == AiEngineProvider.groq
                    ? 'Paste gsk_... key (or use --dart-define=AI_PROXY_URL)'
                    : 'Paste key from aistudio.google.com...',
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
