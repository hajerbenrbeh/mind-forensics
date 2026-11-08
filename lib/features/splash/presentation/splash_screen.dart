import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/lab_colors.dart';
import '../../../core/widgets/neural_brain_wireframe.dart';

/// Master Splash Screen matching Phone 1 of the visual specification.
/// Features deep forest-green (#303A29), glowing neural wireframe,
/// editorial serif title, and glowing horizontal progress bar.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateNext();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final hasCompleted = prefs.getBool('mf_onboarding_completed') ?? false;

    if (!mounted) return;
    if (!hasCompleted && AppRouter.enableFirstLaunchGating) {
      context.go(AppRouter.onboarding);
    } else {
      context.go(AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LabColors.forestGreen, // #303A29 Deep Forest Green
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Glowing Neural Brain Wireframe
              const Center(
                child: NeuralBrainWireframe(
                  size: 200,
                  animate: true,
                ),
              ),

              const SizedBox(height: 36),

              // Title: "Mind Forensics" (Serif Typography)
              const Text(
                'Mind\nForensics',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 38,
                  fontWeight: FontWeight.w400,
                  color: LabColors.warmIvory,
                  height: 1.15,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                'Understand your mind.\nSupport your journey.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFC7CDAD).withValues(alpha: 0.90),
                  height: 1.45,
                  letterSpacing: 0.2,
                ),
              ),

              const Spacer(flex: 3),

              // Bottom Loading Indicator
              Text(
                'LOADING...',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.8,
                  color: const Color(0xFFC7CDAD).withValues(alpha: 0.75),
                ),
              ),

              const SizedBox(height: 12),

              // Glowing Progress Bar
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return Container(
                    height: 3,
                    width: 160,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 3,
                      width: 160 * _progressController.value,
                      decoration: BoxDecoration(
                        color: LabColors.warmIvory,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.60),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

