import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'internal_tools_gate.dart';
import 'providers/release_rollout_provider.dart';
import 'screens/app_shell.dart';
import 'screens/current_rhythm_screen.dart';
import 'screens/family/activity_feed.dart';
import 'screens/family/family_home_screen.dart';
import 'screens/family/invite_screen.dart';
import 'screens/family_rules.dart';
import 'screens/learn.dart';
import 'screens/library/library_home_screen.dart';
import 'screens/library/monthly_insight_screen.dart';
import 'screens/library/patterns_screen.dart';
import 'screens/library/playbook_card_detail_screen.dart';
import 'screens/library/saved_playbook_screen.dart';
import 'screens/onboarding/onboarding_v2_screen.dart';
import 'screens/plan/plan_home_screen.dart';
import 'screens/plan/plan_script_log_screen.dart';
import 'screens/plan/moment_flow_screen.dart';
import 'screens/plan/reset_flow_screen.dart';
import 'screens/regulate/regulate_flow_screen.dart';
import 'screens/release_compliance_checklist.dart';
import 'screens/release_metrics.dart';
import 'screens/release_ops_checklist.dart';
import 'screens/settings.dart';
import 'screens/pocket/pocket_fab_and_overlay.dart';
import 'screens/sleep/sleep_mini_onboarding.dart';
import 'screens/sleep_tonight.dart';
import 'screens/sos.dart';
import 'screens/splash.dart';
import 'screens/today.dart';
import 'screens/update_rhythm_screen.dart';
import 'widgets/release_surfaces.dart';
import 'widgets/settle_bottom_nav.dart';

const int _v2TabPlan = 0;
const int _v2TabFamily = 1;
const int _v2TabSleep = 2;
const int _v2TabLibrary = 3;

const _v2NavItems = [
  SettleBottomNavItem(
    label: 'Home',
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
  var regulateEnabled = true;
  try {
    if (Hive.isBoxOpen(_rolloutBox)) {
      final box = Hive.box<dynamic>(_rolloutBox);
      final raw = box.get(_rolloutKey);
      if (raw is Map) {
        regulateEnabled = raw['regulate_enabled'] as bool? ?? true;
      }
    }
  } catch (_) {}

  return buildRouter(regulateEnabled: regulateEnabled);
}

GoRouter buildRouter({required bool regulateEnabled}) {
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
        pageBuilder: (context, state) =>
            _fade(state, const OnboardingV2Screen()),
      ),

      _buildV2ShellRoute(regulateEnabled: regulateEnabled),

      GoRoute(
        path: '/breathe',
        redirect: (context, state) {
          if (regulateEnabled) {
            return _redirectWithMergedQuery(state, path: '/plan/regulate');
          }
          return null;
        },
        pageBuilder: (context, state) => _fade(state, const SosScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => _fade(state, const SettingsScreen()),
      ),
      GoRoute(path: '/rules', redirect: (_, __) => '/family/shared'),
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
      GoRoute(path: '/home', redirect: (_, __) => '/plan'),
      ..._compatibilityRoutes(regulateEnabled: regulateEnabled),
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
      return Consumer(
        builder: (context, ref, _) {
          final rollout = ref.watch(releaseRolloutProvider);
          final overlay = rollout.pocketEnabled
              ? const PocketFABAndOverlay()
              : null;
          return AppShell(
            currentIndex: navigationShell.currentIndex,
            navItems: _v2NavItems,
            onTabTap: (index) {
              final resetToBranchRoot =
                  index == _v2TabSleep || index == navigationShell.currentIndex;
              navigationShell.goBranch(
                index,
                initialLocation: resetToBranchRoot,
              );
            },
            overlay: overlay,
            child: navigationShell,
          );
        },
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
                pageBuilder: (context, state) =>
                    _fade(state, const RegulateFlowScreen()),
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
                pageBuilder: (context, state) {
                  final cardId = state.uri.queryParameters['card_id'] ?? '';
                  return _fade(state, PlanScriptLogScreen(cardId: cardId));
                },
              ),
              GoRoute(
                path: 'reset',
                pageBuilder: (context, state) {
                  final contextQuery =
                      state.uri.queryParameters['context'] ?? 'general';
                  return _fade(
                    state,
                    ResetFlowScreen(contextQuery: contextQuery),
                  );
                },
              ),
              GoRoute(
                path: 'moment',
                pageBuilder: (context, state) {
                  final contextQuery =
                      state.uri.queryParameters['context'] ?? 'general';
                  return _fade(
                    state,
                    MomentFlowScreen(contextQuery: contextQuery),
                  );
                },
              ),
              GoRoute(
                path: 'tantrum-just-happened',
                redirect: (_, __) => '/plan/reset?context=tantrum',
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
                pageBuilder: (context, state) =>
                    _fade(state, const InviteScreen()),
              ),
              GoRoute(
                path: 'activity',
                pageBuilder: (context, state) =>
                    _fade(state, const ActivityFeedScreen()),
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
                _fade(state, const SleepMiniOnboardingGate()),
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
              GoRoute(
                path: 'saved',
                pageBuilder: (context, state) =>
                    _fade(state, const SavedPlaybookScreen()),
                routes: [
                  GoRoute(
                    path: 'card/:id',
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return _fade(state, PlaybookCardDetailScreen(cardId: id));
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'patterns',
                pageBuilder: (context, state) =>
                    _fade(state, const PatternsScreen()),
              ),
              GoRoute(
                path: 'insights',
                pageBuilder: (context, state) =>
                    _fade(state, const MonthlyInsightScreen()),
              ),
              GoRoute(
                path: 'cards/:id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return _fade(
                    state,
                    PlanCardScreen(cardId: id, fallbackRoute: '/library'),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

List<RouteBase> _compatibilityRoutes({required bool regulateEnabled}) {
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
    GoRoute(path: '/now/reset', redirect: (_, __) => '/plan/reset'),
    GoRoute(path: '/now/moment', redirect: (_, __) => '/plan/moment'),
    GoRoute(
      path: '/now/tantrum',
      redirect: (_, __) => '/plan/reset?context=tantrum',
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
      routes: [
        GoRoute(path: 'capture', redirect: (_, __) => '/plan'),
        GoRoute(
          path: 'just-happened',
          redirect: (_, __) => '/plan/reset?context=tantrum',
        ),
      ],
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
        return _redirectWithMergedQuery(state, path: '/breathe');
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
