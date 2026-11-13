import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_strings.dart';
import '../theme/mind_tokens.dart';

/// Calm, organic, modern capsule navigation bar matching the 5-item master reference:
/// 1. Home
/// 2. Track
/// 3. Inner Observatory (Center elevated circular button with neural emblem)
/// 4. Insights
/// 5. Profile
class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    HapticFeedback.lightImpact();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final currentIndex = navigationShell.currentIndex;

    final scaffoldBg = tokens.background;
    final navBg = tokens.surface;
    final borderColor = tokens.border;
    final activeColor = tokens.accent;
    final inactiveColor = tokens.textSecondary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: navigationShell,
      bottomNavigationBar: Container(
        color: scaffoldBg,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: SafeArea(
          top: false,
          child: MediaQuery.withClampedTextScaling(
            minScaleFactor: 0.85,
            maxScaleFactor: 1.15,
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: navBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 1. Home
                  _buildNavItem(
                    index: 0,
                    currentIndex: currentIndex,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: strings.navHome,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                    tokens: tokens,
                    isDark: isDark,
                  ),

                  // 2. Track
                  _buildNavItem(
                    index: 1,
                    currentIndex: currentIndex,
                    icon: Icons.adjust_outlined,
                    activeIcon: Icons.adjust_rounded,
                    label: strings.navTrack,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                    tokens: tokens,
                    isDark: isDark,
                  ),

                  // 3. Inner Observatory (Center Elevated Button)
                  _buildNavItem(
                    index: 2,
                    currentIndex: currentIndex,
                    icon: Icons.hub_outlined,
                    activeIcon: Icons.hub_rounded,
                    label: strings.navObservatory,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                    tokens: tokens,
                    isCenterAction: true,
                    isDark: isDark,
                  ),

                  // 4. Insights
                  _buildNavItem(
                    index: 3,
                    currentIndex: currentIndex,
                    icon: Icons.auto_stories_outlined,
                    activeIcon: Icons.auto_stories_rounded,
                    label: strings.navInsights,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                    tokens: tokens,
                    isDark: isDark,
                  ),

                  // 5. Profile
                  _buildNavItem(
                    index: 4,
                    currentIndex: currentIndex,
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: strings.navProfile,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                    tokens: tokens,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int currentIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color activeColor,
    required Color inactiveColor,
    required MindTokens tokens,
    bool isCenterAction = false,
    bool isDark = true,
  }) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: InkWell(
        onTap: () => _onTap(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isCenterAction)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? tokens.background : Colors.white)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: isDark ? 0.25 : 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: 19,
                  color: isDark ? tokens.background : Colors.white,
                ),
              )
            else
              Icon(
                isSelected ? activeIcon : icon,
                size: 20,
                color: isSelected ? activeColor : inactiveColor,
              ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.0,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
