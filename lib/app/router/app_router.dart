import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/case_file/presentation/case_report_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/investigation/presentation/flash_case_screen.dart';
import '../../features/journal/presentation/journal_screen.dart';
import '../../features/journey/presentation/journey_screen.dart';
import '../../features/mind_trace/presentation/mind_trace_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/psychological_profile_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/track/presentation/track_screen.dart';
import 'scaffold_with_nav_bar.dart';

/// App router configuration using GoRouter with 5 persistent bottom tabs:
/// Home, Journal, Investigator, Toolkit (placeholder in v1), Profile.
/// Insights lives inside Home until v2.
class AppRouter {
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String journal = '/journal';
  static const String investigator = '/investigation';
  static const String toolkit = '/toolkit';
  static const String profile = '/profile';
  static const String caseReport = '/case/:id';
  static const String mindTrace = '/mind-trace';
  static const String progress = '/progress';
  static const String track = '/track';
  static const String insights = '/insights';
  static const String companion = '/companion';

  // Legacy route aliases for backward compatibility
  static const String tools = '/toolkit';
  static const String settings = '/profile';
  static const String investigation = '/investigation';

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: home,
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
        path: '/check-in',
        redirect: (context, state) => mindTrace,
      ),
      GoRoute(
        path: '/tools',
        redirect: (context, state) => toolkit,
      ),
      GoRoute(
        path: '/settings',
        redirect: (context, state) => profile,
      ),

      // Persistent 5-Tab Bottom Navigation Shell:
      // Home, Journal, Investigator, Toolkit (placeholder in v1), Profile.
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

          // Branch 1: Journal Archive
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: journal,
                name: 'journal',
                builder: (context, state) => const JournalScreen(),
              ),
            ],
          ),

          // Branch 2: Investigator (Flash Case / Cognitive Deconstruction)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: investigator,
                name: 'investigator',
                builder: (context, state) => const FlashCaseScreen(),
              ),
            ],
          ),

          // Branch 3: Toolkit (My Journey & Tools Lab)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: toolkit,
                name: 'toolkit',
                builder: (context, state) => const JourneyScreen(),
              ),
            ],
          ),

          // Branch 4: Profile & Clinical Settings
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
