import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'internal_tools_gate.dart';
import 'screens/app_shell.dart';
import 'screens/current_rhythm_screen.dart';
import 'screens/family/family_home_screen.dart';
import 'screens/family_rules.dart';
import 'screens/help_now.dart';
import 'screens/learn.dart';
import 'screens/library/library_home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/plan/plan_home_screen.dart';
import 'screens/plan_progress.dart';
import 'screens/release_compliance_checklist.dart';
import 'screens/release_metrics.dart';
import 'screens/release_ops_checklist.dart';
import 'screens/settings.dart';
import 'screens/sleep_hub_screen.dart';
import 'screens/sleep_tonight.dart';
import 'screens/sos.dart';
import 'screens/splash.dart';
import 'screens/tantrum/card_detail_screen.dart';
import 'screens/tantrum/crisis_view_screen.dart';
import 'screens/tantrum/tantrum_card_output_screen.dart';
import 'screens/tantrum/tantrum_capture_screen.dart';
import 'screens/tantrum/tantrum_deck_screen.dart';
import 'screens/tantrum/tantrum_insights_screen.dart';
import 'screens/today.dart';
import 'screens/update_rhythm_screen.dart';
import 'services/spec_policy.dart';
import 'widgets/release_surfaces.dart';
import 'widgets/settle_bottom_nav.dart';

// v1 tab indices.
const int _v1TabHelpNow = 0;
const int _v1TabSleep = 1;
const int _v1TabProgress = 2;
const int _v1TabTantrum = 3;

// v2 tab indices.
const int _v2TabPlan = 0;
const int _v2TabFamily = 1;
const int _v2TabSleep = 2;
const int _v2TabLibrary = 3;

const _v1NavItems = [
  SettleBottomNavItem(
    label: 'Help Now',
    icon: Icons.favorite_outline,
    activeIcon: Icons.favorite_rounded,
  ),
  SettleBottomNavItem(
    label: 'Sleep',
    icon: Icons.nightlight_outlined,
    activeIcon: Icons.nightlight_round,
  ),
  SettleBottomNavItem(
    label: 'Progress',
    icon: Icons.trending_up_rounded,
    activeIcon: Icons.trending_up_rounded,
  ),
  SettleBottomNavItem(
    label: 'Tantrum',
    icon: Icons.psychology_outlined,
    activeIcon: Icons.psychology_rounded,
  ),
];

const _v2NavItems = [
  SettleBottomNavItem(
    label: 'Plan',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
  ),
  SettleBottomNavItem(
    label: 'Family',
    icon: Icons.group_outlined,
    activeIcon: Icons.group,
  ),
  SettleBottomNavItem(
    label: 'Sleep',
    icon: Icons.nightlight_outlined,
    activeIcon: Icons.nightlight_round,
  ),
  SettleBottomNavItem(
    label: 'Library',
    icon: Icons.menu_book_outlined,
    activeIcon: Icons.menu_book_rounded,
  ),
];

const _rolloutBox = 'release_rollout_v1';
const _rolloutKey = 'state';

GoRouter? _routerCache;

GoRouter get router => _routerCache ??= _buildRouterFromRolloutState();

void refreshRouterFromRollout() {
  _routerCache = _buildRouterFromRolloutState();
}

GoRouter _buildRouterFromRolloutState() {
  var v2NavigationEnabled = false;
  var regulateEnabled = false;
  try {
    if (Hive.isBoxOpen(_rolloutBox)) {
      final box = Hive.box<dynamic>(_rolloutBox);
      final raw = box.get(_rolloutKey);
      if (raw is Map) {
        v2NavigationEnabled = raw['v2_navigation_enabled'] as bool? ?? false;
        regulateEnabled = raw['regulate_enabled'] as bool? ?? false;
      }
    }
  } catch (_) {
    // Default to v1 shell when rollout state is unavailable.
  }

  return buildRouter(
    v2NavigationEnabled: v2NavigationEnabled,
    regulateEnabled: regulateEnabled,
  );
}

GoRouter buildRouter({
  required bool v2NavigationEnabled,
  required bool regulateEnabled,
}) {
  return GoRouter(
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

      // Main shell (v1 or v2).
      v2NavigationEnabled
          ? _buildV2ShellRoute(regulateEnabled: regulateEnabled)
          : _buildV1ShellRoute(),

      // Overlay screens (push on top of shell, no bottom nav).
      GoRoute(
        path: '/breathe',
        redirect: (context, state) {
          if (v2NavigationEnabled && regulateEnabled) {
            return _redirectWithMergedQuery(state, path: '/plan/regulate');
          }
          return null;
        },
        pageBuilder: (context, state) => _fade(state, const SosScreen()),
      ),

      // Settings (push on top of shell).
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => _fade(state, const SettingsScreen()),
      ),
      if (!v2NavigationEnabled)
        GoRoute(
          path: '/rules',
          pageBuilder: (context, state) =>
              _fade(state, const FamilyRulesScreen()),
        )
      else
        GoRoute(path: '/rules', redirect: (_, __) => '/family/shared'),

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

      // Root home compatibility.
      if (v2NavigationEnabled)
        GoRoute(path: '/home', redirect: (_, __) => '/plan')
      else
        GoRoute(path: '/home', redirect: (_, __) => '/now'),

      // Compatibility redirects.
      ..._compatibilityRoutes(
        v2NavigationEnabled: v2NavigationEnabled,
        regulateEnabled: regulateEnabled,
      ),
    ],
  );
}

StatefulShellRoute _buildV1ShellRoute() {
  final shellNavigatorKeys = [
    GlobalKey<NavigatorState>(debugLabel: 'helpNow'),
    GlobalKey<NavigatorState>(debugLabel: 'sleep'),
    GlobalKey<NavigatorState>(debugLabel: 'progress'),
    GlobalKey<NavigatorState>(debugLabel: 'tantrum'),
  ];

  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) {
      return AppShell(
        currentIndex: navigationShell.currentIndex,
        navItems: _v1NavItems,
        onTabTap: (index) {
          final resetToBranchRoot =
              index == _v1TabSleep || index == navigationShell.currentIndex;
          navigationShell.goBranch(index, initialLocation: resetToBranchRoot);
        },
        child: navigationShell,
      );
    },
    branches: [
      // Tab 0: Help Now
      StatefulShellBranch(
        navigatorKey: shellNavigatorKeys[_v1TabHelpNow],
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
        navigatorKey: shellNavigatorKeys[_v1TabSleep],
        routes: [
          GoRoute(
            path: '/sleep',
            pageBuilder: (context, state) =>
                _fade(state, const SleepHubScreen()),
            routes: [
              GoRoute(
                path: 'tonight',
                pageBuilder: (context, state) =>
                    _fade(state, const SleepTonightScreen()),
              ),
              GoRoute(
                path: 'rhythm',
                pageBuilder: (context, state) =>
                    _fade(state, const CurrentRhythmScreen()),
              ),
              GoRoute(
                path: 'update',
                pageBuilder: (context, state) =>
                    _fade(state, const UpdateRhythmScreen()),
              ),
            ],
          ),
        ],
      ),
      // Tab 2: Progress
      StatefulShellBranch(
        navigatorKey: shellNavigatorKeys[_v1TabProgress],
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
      // Tab 3: Tantrum
      StatefulShellBranch(
        navigatorKey: shellNavigatorKeys[_v1TabTantrum],
        routes: [
          GoRoute(
            path: '/tantrum',
            redirect: (_, state) =>
                state.uri.path == '/tantrum' ? '/tantrum/capture' : null,
            routes: [
              GoRoute(
                path: 'capture',
                pageBuilder: (context, state) =>
                    _fade(state, const TantrumCaptureScreen()),
              ),
              GoRoute(path: 'now', redirect: (_, __) => '/tantrum/capture'),
              GoRoute(
                path: 'card',
                pageBuilder: (context, state) {
                  final cardId = state.uri.queryParameters['cardId'];
                  return _fade(state, TantrumCardOutputScreen(cardId: cardId));
                },
              ),
              GoRoute(
                path: 'crisis',
                pageBuilder: (context, state) {
                  final cardId = state.uri.queryParameters['cardId'];
                  return _fade(state, CrisisViewScreen(cardId: cardId));
                },
              ),
              GoRoute(
                path: 'deck',
                pageBuilder: (context, state) =>
                    _fade(state, const TantrumDeckScreen()),
                routes: [
                  GoRoute(
                    path: ':id',
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return _fade(state, CardDetailScreen(cardId: id));
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'cards',
                redirect: (_, __) => '/tantrum/deck',
                routes: [
                  GoRoute(
                    path: ':id',
                    redirect: (_, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return '/tantrum/deck/$id';
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'insights',
                pageBuilder: (context, state) =>
                    _fade(state, const TantrumInsightsScreen()),
              ),
              GoRoute(path: 'learn', redirect: (_, __) => '/tantrum/insights'),
            ],
          ),
        ],
      ),
    ],
  );
}

StatefulShellRoute _buildV2ShellRoute({required bool regulateEnabled}) {
  final shellNavigatorKeys = [
    GlobalKey<NavigatorState>(debugLabel: 'plan'),
    GlobalKey<NavigatorState>(debugLabel: 'family'),
    GlobalKey<NavigatorState>(debugLabel: 'sleep_v2'),
    GlobalKey<NavigatorState>(debugLabel: 'library'),
  ];

  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) {
      return AppShell(
        currentIndex: navigationShell.currentIndex,
        navItems: _v2NavItems,
        onTabTap: (index) {
          final resetToBranchRoot =
              index == _v2TabSleep || index == navigationShell.currentIndex;
          navigationShell.goBranch(index, initialLocation: resetToBranchRoot);
        },
        child: navigationShell,
      );
    },
    branches: [
      // Tab 0: Plan
      StatefulShellBranch(
        navigatorKey: shellNavigatorKeys[_v2TabPlan],
        routes: [
          GoRoute(
            path: '/plan',
            pageBuilder: (context, state) =>
                _fade(state, const PlanHomeScreen()),
            routes: [
              GoRoute(
                path: 'regulate',
                pageBuilder: (context, state) {
                  // Phase 1 stub: full flow lands in Phase 5.
                  return _fade(state, const SosScreen());
                },
              ),
              GoRoute(
                path: 'card/:id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return _fade(state, PlanCardScreen(cardId: id));
                },
              ),
              GoRoute(
                path: 'log',
                pageBuilder: (context, state) =>
                    _fade(state, const TodayScreen()),
              ),
            ],
          ),
        ],
      ),
      // Tab 1: Family
      StatefulShellBranch(
        navigatorKey: shellNavigatorKeys[_v2TabFamily],
        routes: [
          GoRoute(
            path: '/family',
            pageBuilder: (context, state) =>
                _fade(state, const FamilyHomeScreen()),
            routes: [
              GoRoute(path: 'home', redirect: (_, __) => '/family'),
              GoRoute(
                path: 'shared',
                pageBuilder: (context, state) =>
                    _fade(state, const FamilyRulesScreen()),
              ),
              GoRoute(
                path: 'invite',
                pageBuilder: (context, state) => _fade(
                  state,
                  const RouteUnavailableView(
                    title: 'Invite coming soon',
                    message: 'Invite flow lands in the Family MVP phase.',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      // Tab 2: Sleep (unchanged)
      StatefulShellBranch(
        navigatorKey: shellNavigatorKeys[_v2TabSleep],
        routes: [
          GoRoute(
            path: '/sleep',
            pageBuilder: (context, state) =>
                _fade(state, const SleepHubScreen()),
            routes: [
              GoRoute(
                path: 'tonight',
                pageBuilder: (context, state) =>
                    _fade(state, const SleepTonightScreen()),
              ),
              GoRoute(
                path: 'rhythm',
                pageBuilder: (context, state) =>
                    _fade(state, const CurrentRhythmScreen()),
              ),
              GoRoute(
                path: 'update',
                pageBuilder: (context, state) =>
                    _fade(state, const UpdateRhythmScreen()),
              ),
            ],
          ),
        ],
      ),
      // Tab 3: Library
      StatefulShellBranch(
        navigatorKey: shellNavigatorKeys[_v2TabLibrary],
        routes: [
          GoRoute(
            path: '/library',
            pageBuilder: (context, state) =>
                _fade(state, const LibraryHomeScreen()),
            routes: [
              GoRoute(
                path: 'learn',
                pageBuilder: (context, state) =>
                    _fade(state, const LearnScreen()),
              ),
              GoRoute(
                path: 'logs',
                pageBuilder: (context, state) =>
                    _fade(state, const TodayScreen()),
              ),
              GoRoute(path: 'saved', redirect: (_, __) => '/library'),
              GoRoute(path: 'patterns', redirect: (_, __) => '/library'),
              GoRoute(
                path: 'cards/:id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return _fade(state, PlanCardScreen(cardId: id));
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

List<RouteBase> _compatibilityRoutes({
  required bool v2NavigationEnabled,
  required bool regulateEnabled,
}) {
  if (!v2NavigationEnabled) {
    return [
      GoRoute(
        path: '/relief',
        redirect: (context, state) => _redirectWithMergedQuery(
          state,
          path: '/now',
          extraQuery: const {
            SpecPolicy.nowModeParam: SpecPolicy.nowModeIncident,
          },
        ),
      ),
      GoRoute(
        path: '/help-now',
        redirect: (context, state) => _redirectWithMergedQuery(
          state,
          path: '/now',
          extraQuery: const {
            SpecPolicy.nowModeParam: SpecPolicy.nowModeIncident,
          },
        ),
      ),
      GoRoute(
        path: '/sleep-tonight',
        redirect: (context, state) =>
            _redirectWithMergedQuery(state, path: '/sleep/tonight'),
      ),
      GoRoute(
        path: '/sleep/update-rhythm',
        redirect: (context, state) =>
            _redirectWithMergedQuery(state, path: '/sleep/update'),
      ),
      GoRoute(
        path: '/current-rhythm',
        redirect: (context, state) =>
            _redirectWithMergedQuery(state, path: '/sleep/rhythm'),
      ),
      GoRoute(
        path: '/update-rhythm',
        redirect: (context, state) =>
            _redirectWithMergedQuery(state, path: '/sleep/update'),
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
            _redirectWithMergedQuery(state, path: '/sleep/tonight'),
      ),
      GoRoute(
        path: '/night',
        redirect: (context, state) =>
            _redirectWithMergedQuery(state, path: '/sleep/tonight'),
      ),
      GoRoute(path: '/today', redirect: (_, __) => '/progress/logs'),
      GoRoute(path: '/learn', redirect: (_, __) => '/progress/learn'),
      GoRoute(path: '/sos', redirect: (_, __) => '/breathe'),
    ];
  }

  return [
    GoRoute(
      path: '/relief',
      redirect: (context, state) =>
          _redirectWithMergedQuery(state, path: '/plan'),
    ),
    GoRoute(
      path: '/help-now',
      redirect: (context, state) =>
          _redirectWithMergedQuery(state, path: '/plan'),
    ),
    GoRoute(
      path: '/now',
      redirect: (context, state) =>
          _redirectWithMergedQuery(state, path: '/plan'),
    ),
    GoRoute(
      path: '/sleep-tonight',
      redirect: (context, state) =>
          _redirectWithMergedQuery(state, path: '/sleep/tonight'),
    ),
    GoRoute(
      path: '/sleep/update-rhythm',
      redirect: (context, state) =>
          _redirectWithMergedQuery(state, path: '/sleep/update'),
    ),
    GoRoute(
      path: '/current-rhythm',
      redirect: (context, state) =>
          _redirectWithMergedQuery(state, path: '/sleep/rhythm'),
    ),
    GoRoute(
      path: '/update-rhythm',
      redirect: (context, state) =>
          _redirectWithMergedQuery(state, path: '/sleep/update'),
    ),
    GoRoute(path: '/plan-progress', redirect: (_, __) => '/library'),
    GoRoute(
      path: '/progress',
      redirect: (_, __) => '/library',
      routes: [
        GoRoute(path: 'logs', redirect: (_, __) => '/library/logs'),
        GoRoute(path: 'learn', redirect: (_, __) => '/library/learn'),
      ],
    ),
    GoRoute(
      path: '/tantrum',
      redirect: (_, __) => '/plan',
      routes: [GoRoute(path: 'capture', redirect: (_, __) => '/plan')],
    ),
    GoRoute(
      path: '/family-rules',
      redirect: (context, state) =>
          _redirectWithMergedQuery(state, path: '/family/shared'),
    ),
    GoRoute(
      path: '/night-mode',
      redirect: (context, state) =>
          _redirectWithMergedQuery(state, path: '/sleep/tonight'),
    ),
    GoRoute(
      path: '/night',
      redirect: (context, state) =>
          _redirectWithMergedQuery(state, path: '/sleep/tonight'),
    ),
    GoRoute(path: '/today', redirect: (_, __) => '/library/logs'),
    GoRoute(path: '/learn', redirect: (_, __) => '/library/learn'),
    GoRoute(
      path: '/sos',
      redirect: (context, state) {
        if (regulateEnabled) {
          return _redirectWithMergedQuery(state, path: '/plan/regulate');
        }
        return '/plan/regulate';
      },
    ),
  ];
}

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
