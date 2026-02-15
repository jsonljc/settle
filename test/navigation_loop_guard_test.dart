import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settle/models/approach.dart';
import 'package:settle/models/baby_profile.dart';
import 'package:settle/models/day_plan.dart';
import 'package:settle/models/night_wake.dart';
import 'package:settle/models/sleep_session.dart';
import 'package:settle/models/tantrum_profile.dart';
import 'package:settle/providers/release_rollout_provider.dart';
import 'package:settle/screens/help_now.dart';
import 'package:settle/screens/sleep_tonight.dart';

class _StaticRolloutNotifier extends StateNotifier<ReleaseRolloutState>
    implements ReleaseRolloutNotifier {
  _StaticRolloutNotifier(super.state);

  @override
  Future<void> setHelpNowEnabled(bool value) async {
    state = state.copyWith(helpNowEnabled: value);
  }

  @override
  Future<void> setSleepTonightEnabled(bool value) async {
    state = state.copyWith(sleepTonightEnabled: value);
  }

  @override
  Future<void> setPlanProgressEnabled(bool value) async {
    state = state.copyWith(planProgressEnabled: value);
  }

  @override
  Future<void> setFamilyRulesEnabled(bool value) async {
    state = state.copyWith(familyRulesEnabled: value);
  }

  @override
  Future<void> setMetricsDashboardEnabled(bool value) async {
    state = state.copyWith(metricsDashboardEnabled: value);
  }

  @override
  Future<void> setComplianceChecklistEnabled(bool value) async {
    state = state.copyWith(complianceChecklistEnabled: value);
  }

  @override
  Future<void> setSleepBoundedAiEnabled(bool value) async {
    state = state.copyWith(sleepBoundedAiEnabled: value);
  }

  @override
  Future<void> setWindDownNotificationsEnabled(bool value) async {
    state = state.copyWith(windDownNotificationsEnabled: value);
  }

  @override
  Future<void> setScheduleDriftNotificationsEnabled(bool value) async {
    state = state.copyWith(scheduleDriftNotificationsEnabled: value);
  }
}

ReleaseRolloutState _rolloutState({
  required bool helpNowEnabled,
  required bool sleepTonightEnabled,
}) {
  return ReleaseRolloutState(
    isLoading: false,
    helpNowEnabled: helpNowEnabled,
    sleepTonightEnabled: sleepTonightEnabled,
    planProgressEnabled: true,
    familyRulesEnabled: true,
    metricsDashboardEnabled: true,
    complianceChecklistEnabled: true,
    sleepBoundedAiEnabled: true,
    windDownNotificationsEnabled: true,
    scheduleDriftNotificationsEnabled: false,
  );
}

Future<void> _pumpWithRollout(
  WidgetTester tester, {
  required GoRouter router,
  required ReleaseRolloutState rollout,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        releaseRolloutProvider.overrideWith(
          (ref) => _StaticRolloutNotifier(rollout),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
}

void main() {
  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('settle_nav_loop_guard');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive
        ..registerAdapter(ApproachAdapter())
        ..registerAdapter(AgeBracketAdapter())
        ..registerAdapter(FamilyStructureAdapter())
        ..registerAdapter(PrimaryChallengeAdapter())
        ..registerAdapter(FeedingTypeAdapter())
        ..registerAdapter(FocusModeAdapter())
        ..registerAdapter(TantrumTypeAdapter())
        ..registerAdapter(TriggerTypeAdapter())
        ..registerAdapter(ParentPatternAdapter())
        ..registerAdapter(ResponsePriorityAdapter())
        ..registerAdapter(TantrumIntensityAdapter())
        ..registerAdapter(PatternTrendAdapter())
        ..registerAdapter(NormalizationStatusAdapter())
        ..registerAdapter(DayBucketAdapter())
        ..registerAdapter(BabyProfileAdapter())
        ..registerAdapter(TantrumProfileAdapter())
        ..registerAdapter(TantrumEventAdapter())
        ..registerAdapter(WeeklyTantrumPatternAdapter())
        ..registerAdapter(SleepSessionAdapter())
        ..registerAdapter(NightWakeAdapter())
        ..registerAdapter(DayPlanAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  testWidgets(
    'Help Now paused fallback goes home when both urgent modules are off',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/help-now',
        routes: [
          GoRoute(
            path: '/help-now',
            builder: (context, state) =>
                HelpNowScreen(now: () => DateTime(2026, 2, 13, 14)),
          ),
          GoRoute(
            path: '/now',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('SHELL_SCREEN'))),
          ),
          GoRoute(
            path: '/sleep',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('SLEEP_SCREEN'))),
          ),
        ],
      );

      await _pumpWithRollout(
        tester,
        router: router,
        rollout: _rolloutState(
          helpNowEnabled: false,
          sleepTonightEnabled: false,
        ),
      );

      expect(find.text('Help Now'), findsOneWidget);
      expect(find.text('Go to Home'), findsOneWidget);

      await tester.tap(find.text('Go to Home'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('SHELL_SCREEN'), findsOneWidget);
      expect(find.text('SLEEP_SCREEN'), findsNothing);
    },
  );

  testWidgets(
    'Sleep Tonight paused fallback goes to shell when both urgent modules are off',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/sleep-tonight',
        routes: [
          GoRoute(
            path: '/sleep-tonight',
            builder: (context, state) => const SleepTonightScreen(),
          ),
          GoRoute(
            path: '/now',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('SHELL_SCREEN'))),
          ),
          GoRoute(
            path: '/help-now',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('HELP_SCREEN'))),
          ),
        ],
      );

      await _pumpWithRollout(
        tester,
        router: router,
        rollout: _rolloutState(
          helpNowEnabled: false,
          sleepTonightEnabled: false,
        ),
      );

      expect(find.text('Sleep Tonight'), findsOneWidget);
      expect(find.text('Go to Home'), findsOneWidget);

      await tester.tap(find.text('Go to Home'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('SHELL_SCREEN'), findsOneWidget);
      expect(find.text('HELP_SCREEN'), findsNothing);
    },
  );

  testWidgets('Help Now paused fallback still routes to Sleep when available', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/help-now',
      routes: [
        GoRoute(
          path: '/help-now',
          builder: (context, state) =>
              HelpNowScreen(now: () => DateTime(2026, 2, 13, 14)),
        ),
        GoRoute(
          path: '/sleep',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('SLEEP_SCREEN'))),
        ),
      ],
    );

    await _pumpWithRollout(
      tester,
      router: router,
      rollout: _rolloutState(helpNowEnabled: false, sleepTonightEnabled: true),
    );

    expect(find.text('Open Sleep Tonight'), findsOneWidget);

    await tester.tap(find.text('Open Sleep Tonight'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('SLEEP_SCREEN'), findsOneWidget);
  });

  testWidgets(
    'Sleep Tonight paused fallback still routes to Help Now when available',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/sleep-tonight',
        routes: [
          GoRoute(
            path: '/sleep-tonight',
            builder: (context, state) => const SleepTonightScreen(),
          ),
          GoRoute(
            path: '/now',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('NOW_SCREEN'))),
          ),
        ],
      );

      await _pumpWithRollout(
        tester,
        router: router,
        rollout: _rolloutState(
          helpNowEnabled: true,
          sleepTonightEnabled: false,
        ),
      );

      expect(find.text('Open Now: Incident'), findsOneWidget);

      await tester.tap(find.text('Open Now: Incident'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('NOW_SCREEN'), findsOneWidget);
    },
  );
}
