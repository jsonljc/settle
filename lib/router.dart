import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'internal_tools_gate.dart';
import 'services/spec_policy.dart';
import 'screens/app_shell.dart';
import 'screens/current_rhythm_screen.dart';
import 'screens/family_rules.dart';
import 'screens/help_now.dart';
// home.dart retained for legacy — /home redirects to /now.
import 'screens/learn.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/plan_progress.dart';
import 'screens/release_compliance_checklist.dart';
import 'screens/release_metrics.dart';
import 'screens/release_ops_checklist.dart';
import 'screens/settings.dart';
import 'screens/sleep_tonight.dart';
import 'screens/sos.dart';
import 'screens/splash.dart';
import 'screens/update_rhythm_screen.dart';
import 'screens/today.dart';
import 'widgets/release_surfaces.dart';

// Tab indices for the bottom navigation shell.
const int _tabHelpNow = 0;
const int _tabSleep = 1;
const int _tabProgress = 2;

final _shellNavigatorKeys = [
  GlobalKey<NavigatorState>(debugLabel: 'helpNow'),
  GlobalKey<NavigatorState>(debugLabel: 'sleep'),
  GlobalKey<NavigatorState>(debugLabel: 'progress'),
];

final router = GoRouter(
  initialLocation: '/',
  errorPageBuilder: (context, state) => _fade(
    state,
    const RouteUnavailableView(),
    duration: const Duration(milliseconds: 200),
  ),
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _fade(state, const SplashScreen()),
    ),
    GoRoute(
      path: '/onboard',
      pageBuilder: (context, state) => _fade(state, const OnboardingScreen()),
    ),

    // ── 3-tab bottom navigation shell ──
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(
          currentIndex: navigationShell.currentIndex,
          onTabTap: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          child: navigationShell,
        );
      },
      branches: [
        // Tab 0: Help Now
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeys[_tabHelpNow],
          routes: [
            GoRoute(
              path: '/now',
              pageBuilder: (context, state) =>
                  _fade(state, const HelpNowScreen()),
            ),
          ],
        ),
        // Tab 1: Sleep
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeys[_tabSleep],
          routes: [
            GoRoute(
              path: '/sleep',
              pageBuilder: (context, state) =>
                  _fade(state, const SleepTonightScreen()),
              routes: [
                GoRoute(
                  path: 'rhythm',
                  pageBuilder: (context, state) =>
                      _fade(state, const CurrentRhythmScreen()),
                ),
                GoRoute(
                  path: 'update-rhythm',
                  pageBuilder: (context, state) =>
                      _fade(state, const UpdateRhythmScreen()),
                ),
              ],
            ),
          ],
        ),
        // Tab 2: Progress
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeys[_tabProgress],
          routes: [
            GoRoute(
              path: '/progress',
              pageBuilder: (context, state) =>
                  _fade(state, const PlanProgressScreen()),
              routes: [
                GoRoute(
                  path: 'logs',
                  pageBuilder: (context, state) =>
                      _fade(state, const TodayScreen()),
                ),
                GoRoute(
                  path: 'learn',
                  pageBuilder: (context, state) =>
                      _fade(state, const LearnScreen()),
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── Overlay screens (push on top of shell, no bottom nav) ──
    GoRoute(
      path: '/breathe',
      pageBuilder: (context, state) => _fade(state, const SosScreen()),
    ),

    // ── Settings (push on top of shell) ──
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => _fade(state, const SettingsScreen()),
    ),
    GoRoute(
      path: '/rules',
      pageBuilder: (context, state) => _fade(state, const FamilyRulesScreen()),
    ),

    // ── Legacy Home — redirect to shell ──
    GoRoute(path: '/home', redirect: (_, __) => '/now'),

    // Internal tooling routes.
    GoRoute(
      path: '/release-metrics',
      pageBuilder: (context, state) =>
          _internalOnly(state, const ReleaseMetricsScreen()),
    ),
    GoRoute(
      path: '/release-compliance',
      pageBuilder: (context, state) =>
          _internalOnly(state, const ReleaseComplianceChecklistScreen()),
    ),
    GoRoute(
      path: '/release-ops',
      pageBuilder: (context, state) =>
          _internalOnly(state, const ReleaseOpsChecklistScreen()),
    ),

    // Compatibility redirects.
    GoRoute(
      path: '/relief',
      redirect: (context, state) => _redirectWithMergedQuery(
        state,
        path: '/now',
        extraQuery: const {SpecPolicy.nowModeParam: SpecPolicy.nowModeIncident},
      ),
    ),
    GoRoute(
      path: '/help-now',
      redirect: (context, state) => _redirectWithMergedQuery(
        state,
        path: '/now',
        extraQuery: const {SpecPolicy.nowModeParam: SpecPolicy.nowModeIncident},
      ),
    ),
    GoRoute(path: '/sleep-tonight', redirect: (_, __) => '/sleep'),
    GoRoute(path: '/current-rhythm', redirect: (_, __) => '/sleep/rhythm'),
    GoRoute(
      path: '/update-rhythm',
      redirect: (_, __) => '/sleep/update-rhythm',
    ),
    GoRoute(path: '/plan-progress', redirect: (_, __) => '/progress'),
    GoRoute(path: '/plan', redirect: (_, __) => '/progress'),
    GoRoute(
      path: '/family-rules',
      redirect: (context, state) =>
          _redirectWithMergedQuery(state, path: '/rules'),
    ),
    GoRoute(
      path: '/night-mode',
      redirect: (context, state) =>
          _redirectWithMergedQuery(state, path: '/sleep'),
    ),
    GoRoute(
      path: '/night',
      redirect: (context, state) =>
          _redirectWithMergedQuery(state, path: '/sleep'),
    ),
    GoRoute(path: '/today', redirect: (_, __) => '/progress/logs'),
    GoRoute(path: '/learn', redirect: (_, __) => '/progress/learn'),
    GoRoute(path: '/sos', redirect: (_, __) => '/breathe'),
  ],
);

String _redirectWithMergedQuery(
  GoRouterState state, {
  required String path,
  Map<String, String> extraQuery = const {},
}) {
  final merged = <String, String>{...state.uri.queryParameters, ...extraQuery};
  return Uri(
    path: path,
    queryParameters: merged.isEmpty ? null : merged,
  ).toString();
}

CustomTransitionPage<void> _internalOnly(GoRouterState state, Widget child) {
  if (!InternalToolsGate.enabled) {
    return _fade(
      state,
      const RouteUnavailableView(
        title: 'Internal tools unavailable',
        message: 'This screen is available only in internal builds.',
      ),
      duration: const Duration(milliseconds: 200),
    );
  }
  return _fade(state, child);
}

CustomTransitionPage<void> _fade(
  GoRouterState state,
  Widget child, {
  Duration duration = const Duration(milliseconds: 250),
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
