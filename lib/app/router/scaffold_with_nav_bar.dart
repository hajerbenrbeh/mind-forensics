import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_strings.dart';
import '../theme/lab_colors.dart';

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
    final strings = ref.watch(appStringsProvider);
    final currentIndex = navigationShell.currentIndex;

    final scaffoldBg = isDark ? LabColors.darkForestBackground : LabColors.warmIvory;
    final navBg = isDark ? LabColors.darkForestSurface : LabColors.cardIvory;
    final borderColor = isDark ? LabColors.darkForestBorder : LabColors.borderIvory;
    final activeColor = isDark ? LabColors.lightOlive : LabColors.forestGreen;
    final inactiveColor = isDark ? LabColors.darkTextSecondary : LabColors.secondaryText;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: navigationShell,
      bottomNavigationBar: Container(
        color: scaffoldBg,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SafeArea(
          top: false,
          child: MediaQuery.withClampedTextScaling(
            minScaleFactor: 0.85,
            maxScaleFactor: 1.15,
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: navBg,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: borderColor, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? LabColors.forestGreen : LabColors.forestGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFFC7CDAD) : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: LabColors.forestGreen.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: 19,
                  color: const Color(0xFFF5EEE3),
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
