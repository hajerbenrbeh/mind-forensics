import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/case_file/presentation/case_report_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/investigation/presentation/flash_case_screen.dart';
import '../../features/observatory/presentation/inner_observatory_screen.dart';
import '../../features/mind_trace/presentation/mind_trace_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/psychological_profile_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/track/presentation/track_screen.dart';
import 'scaffold_with_nav_bar.dart';

/// App router configuration using GoRouter with 4 persistent bottom tabs:
/// Home, Investigator, Toolkit, Profile.
/// Insights lives inside Home until v2.
class AppRouter {
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String journal = '/journal';
  static const String investigator = '/investigation';
  static const String observatory = '/observatory';
  static const String toolkit = '/toolkit';
  static const String profile = '/profile';
  static const String caseReport = '/case/:id';
  static const String mindTrace = '/mind-trace';
  static const String progress = '/progress';
  static const String track = '/track';
  static const String insights = '/insights';
  static const String companion = '/companion';

  /// Whether first-launch gating redirects new users to /onboarding.
  static bool enableFirstLaunchGating = true;

  // Legacy route aliases for backward compatibility
  static const String tools = '/toolkit';
  static const String settings = '/profile';
  static const String investigation = '/investigation';

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: home,
    redirect: (context, state) async {
      if (!enableFirstLaunchGating) return null;

      final prefs = await SharedPreferences.getInstance();
      final hasCompleted = prefs.getBool('mf_onboarding_completed') ?? false;

      final isGoingToOnboarding = state.matchedLocation == onboarding;
      final isGoingToAuth = state.matchedLocation == auth;

      // First-launch gating: if not completed, redirect to /onboarding
      if (!hasCompleted) {
        if (!isGoingToOnboarding && !isGoingToAuth) {
          return onboarding;
        }
      } else {
        // Completed returning users stay away from onboarding
        if (isGoingToOnboarding) {
          return home;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: auth,
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: caseReport,
        name: 'caseReport',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CaseReportScreen(caseId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/profile/conditions',
        name: 'profileConditions',
        builder: (context, state) => const PsychologicalProfileScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: mindTrace,
        name: 'mindTrace',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MindTraceScreen(
            initialTabIndex: extra?['initialTabIndex'] as int? ?? 0,
            startInEditMode: extra?['startInEditMode'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: progress,
        name: 'progress',
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: track,
        name: 'track',
        builder: (context, state) => const TrackScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: insights,
        name: 'insights',
        builder: (context, state) => const InsightsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: companion,
        name: 'companion',
        builder: (context, state) => const FlashCaseScreen(),
      ),

      // Route aliases for backward compatibility
      GoRoute(
        path: '/journal',
        redirect: (context, state) => home,
      ),
      GoRoute(
        path: '/check-in',
        redirect: (context, state) => mindTrace,
      ),
      GoRoute(
        path: '/tools',
        redirect: (context, state) => observatory,
      ),
      GoRoute(
        path: '/toolkit',
        redirect: (context, state) => observatory,
      ),
      GoRoute(
        path: '/settings',
        redirect: (context, state) => profile,
      ),

      // Persistent 4-Tab Bottom Navigation Shell:
      // Home, Investigator, Inner Observatory, Profile.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home Dashboard (with check-in card, last mood, open cases, recent entries, insights)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Branch 1: Investigator (Flash Case / Cognitive Deconstruction)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: investigator,
                name: 'investigator',
                builder: (context, state) => const FlashCaseScreen(),
              ),
            ],
          ),

          // Branch 2: Inner Observatory (Symptom Exploration, Perspectives, Experiments, Discoveries)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: observatory,
                name: 'observatory',
                builder: (context, state) => const InnerObservatoryScreen(),
              ),
            ],
          ),

          // Branch 3: Profile & Clinical Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: profile,
                name: 'profile',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
