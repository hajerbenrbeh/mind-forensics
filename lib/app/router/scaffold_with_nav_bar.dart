import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_strings.dart';
import '../theme/lab_colors.dart';

/// Calm, organic, modern capsule navigation bar.
///
/// Features:
/// - Floating 28px rounded capsule bar matching the organic Earth/Sage palette.
/// - Soft shadow layering and clean vector icons.
/// - Four tabs: Home, Investigator, Toolkit, Profile.
/// - Zero emoji clutter, minimum 48px interactive target.
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

    final scaffoldBg = isDark ? LabColors.nightBackground : LabColors.daylightBackground;
    final navBg = isDark ? LabColors.nightSurface : LabColors.daylightSurface;
    final borderColor = isDark ? LabColors.nightBorder : LabColors.daylightBorder;
    final activeColor = isDark ? LabColors.nightAccent : LabColors.daylightAccent;
    final inactiveColor = isDark ? LabColors.nightTextSecondary : LabColors.daylightTextSecondary;

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
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.35)
                        : const Color(0xFF668274).withValues(alpha: 0.08),
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
                    icon: Icons.grid_view_outlined,
                    activeIcon: Icons.grid_view_rounded,
                    label: strings.navHome,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                  ),

                  // 2. Investigator (Center Focus)
                  _buildNavItem(
                    index: 1,
                    currentIndex: currentIndex,
                    icon: Icons.psychology_outlined,
                    activeIcon: Icons.psychology_rounded,
                    label: strings.navInvestigator,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                    isCenterAction: true,
                    isDark: isDark,
                  ),

                  // 3. Inner Observatory (Symptom Exploration, Perspectives, Experiments, Discoveries)
                  _buildNavItem(
                    index: 2,
                    currentIndex: currentIndex,
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore_rounded,
                    label: strings.navObservatory,
                    activeColor: activeColor,
                    inactiveColor: inactiveColor,
                  ),

                  // 4. Profile
                  _buildNavItem(
                    index: 3,
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? LabColors.nightAccent : LabColors.daylightAccent)
                      : (isDark ? LabColors.nightSurfaceSubtle : LabColors.daylightSurfaceSubtle),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: 18,
                  color: isSelected
                      ? (isDark ? const Color(0xFF151B19) : Colors.white)
                      : (isDark ? LabColors.nightTextPrimary : LabColors.daylightTextPrimary),
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
