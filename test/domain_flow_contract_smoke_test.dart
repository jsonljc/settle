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
import 'package:settle/models/reset_event.dart';
import 'package:settle/models/sleep_session.dart';
import 'package:settle/models/tantrum_profile.dart';
import 'package:settle/models/user_card.dart';
import 'package:settle/providers/reset_flow_provider.dart';
import 'package:settle/providers/release_rollout_provider.dart';
import 'package:settle/providers/sleep_tonight_provider.dart';
import 'package:settle/screens/plan/moment_flow_screen.dart';
import 'package:settle/screens/plan/reset_flow_screen.dart';
import 'package:settle/screens/sleep_tonight.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final hiveDir = Directory.systemTemp.createTempSync(
      'settle_domain_flow_smoke',
    );
    Hive.init(hiveDir.path);
    _registerAdapters();
    await Future.wait([
      Hive.openBox<dynamic>('release_rollout_v1'),
      Hive.openBox<dynamic>('spine_store'),
      Hive.openBox<BabyProfile>('profile'),
      Hive.openBox<UserCard>('user_cards'),
    ]);
  });

  setUp(() async {
    await Hive.box<dynamic>('release_rollout_v1').clear();
    await Hive.box<dynamic>('spine_store').clear();
    await Hive.box<BabyProfile>('profile').clear();
    await Hive.box<UserCard>('user_cards').clear();

    await Hive.box<BabyProfile>('profile').put(
      'baby',
      BabyProfile(
        name: 'Ari',
        ageBracket: AgeBracket.twoToThreeYears,
        familyStructure: FamilyStructure.twoParents,
        approach: Approach.stayAndSupport,
        primaryChallenge: PrimaryChallenge.nightWaking,
        feedingType: FeedingType.combo,
        focusMode: FocusMode.both,
        sleepProfileComplete: true,
        createdAt: 'domain-flow-child',
      ),
    );
  });

  testWidgets('Moment contexts complete and Close has safe fallback', (
    tester,
  ) async {
    for (final ctx in ['general', 'sleep', 'tantrum']) {
      await _pumpMomentApp(tester, ctx);
      expect(find.byType(MomentFlowScreen), findsOneWidget);

      await _tapText(tester, '10 seconds');
      await _settleRoute(tester);
      await _tapText(tester, 'Boundary');
      await _settleRoute(tester);
      await _tapText(tester, 'Close');
      await _settleRoute(tester);
      expect(find.text('PLAN_ROOT'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('Sleep Tonight scenarios render guidance in <=3 taps and close', (
    tester,
  ) async {
    for (final scenario in ['Bedtime protest', 'Night wake', 'Early wake']) {
      await _pumpSleepTonightApp(tester);

      var taps = 0;
      await _tapText(tester, scenario);
      taps += 1;
      await _settleRoute(tester);

      expect(find.textContaining('Do now:'), findsOneWidget);
      expect(taps <= 3, isTrue);

      await _tapBack(tester);
      await _settleRoute(tester);
      expect(find.text('NOW_ROOT'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('Sleep Tonight moment entry opens Moment and returns cleanly', (
    tester,
  ) async {
    await _pumpSleepTonightApp(tester);
    await _tapText(tester, 'In the moment? → Moment');
    await _settleRoute(tester);
    expect(find.byType(MomentFlowScreen), findsOneWidget);

    await _tapBack(tester);
    await _settleRoute(tester);
    expect(find.byType(SleepTonightScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Tantrum just happened route redirects to Reset with context', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/plan',
      routes: [
        GoRoute(
          path: '/plan',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('PLAN_ROOT'))),
          routes: [
            GoRoute(
              path: 'tantrum-just-happened',
              redirect: (_, __) => '/plan/reset?context=tantrum',
            ),
            GoRoute(
              path: 'reset',
              builder: (context, state) => ResetFlowScreen(
                contextQuery: state.uri.queryParameters['context'] ?? 'general',
              ),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await _settleRoute(tester);

    router.go('/plan/tantrum-just-happened');
    await _settleRoute(tester);
    expect(find.byType(ResetFlowScreen), findsOneWidget);

    await _tapText(tester, 'For my child');
    await _settleRoute(tester);

    final tantrumTitles = <String>{
      'Big feelings, you’re safe',
      'Limit and presence',
      'Name it, then wait',
    };
    expect(
      tantrumTitles.any((title) => find.text(title).evaluate().isNotEmpty),
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    router.dispose();
  });

  testWidgets('Reset state enforces max Another = 3', (tester) async {
    expect(ResetFlowState.maxAnother, 3);
    expect(const ResetFlowState(anotherCount: 2).canShowAnother, isTrue);
    expect(const ResetFlowState(anotherCount: 3).canShowAnother, isFalse);
  });

}

Future<void> _pumpMomentApp(WidgetTester tester, String contextQuery) async {
  final router = GoRouter(
    initialLocation: '/moment',
    routes: [
      GoRoute(
        path: '/moment',
        builder: (context, state) =>
            MomentFlowScreen(contextQuery: contextQuery),
      ),
      GoRoute(
        path: '/plan',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('PLAN_ROOT'))),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: router)),
  );
  await _settleRoute(tester);
}

Future<void> _pumpSleepTonightApp(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: '/sleep-tonight',
    routes: [
      GoRoute(
        path: '/sleep-tonight',
        builder: (context, state) => const SleepTonightScreen(),
      ),
      GoRoute(
        path: '/plan/moment',
        builder: (context, state) {
          final ctx = state.uri.queryParameters['context'] ?? 'general';
          return MomentFlowScreen(contextQuery: ctx);
        },
      ),
      GoRoute(
        path: '/sleep',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('SLEEP_ROOT'))),
      ),
      GoRoute(
        path: '/now',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('NOW_ROOT'))),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sleepTonightProvider.overrideWith((ref) => _FlowSleepTonightNotifier()),
        releaseRolloutProvider.overrideWith(
          (ref) => _StaticRolloutNotifier(_rolloutState),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await _settleRoute(tester);
}

Future<void> _settleRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump(const Duration(milliseconds: 650));
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final target = find.text(text).first;
  await tester.ensureVisible(target);
  await tester.tap(target);
}

Future<void> _tapBack(WidgetTester tester) async {
  final icon = find.byIcon(Icons.arrow_back_ios_rounded);
  if (icon.evaluate().isNotEmpty) {
    await tester.tap(icon.first);
    return;
  }
  await tester.tap(find.bySemanticsLabel('Back').first);
}

const _rolloutState = ReleaseRolloutState(
  isLoading: false,
  helpNowEnabled: true,
  sleepTonightEnabled: true,
  planProgressEnabled: true,
  familyRulesEnabled: true,
  metricsDashboardEnabled: false,
  complianceChecklistEnabled: false,
  sleepBoundedAiEnabled: true,
  sleepRhythmSurfacesEnabled: true,
  rhythmShiftDetectorPromptsEnabled: true,
  windDownNotificationsEnabled: true,
  scheduleDriftNotificationsEnabled: false,
);

class _StaticRolloutNotifier extends StateNotifier<ReleaseRolloutState>
    implements ReleaseRolloutNotifier {
  _StaticRolloutNotifier(super.state);

  @override
  Future<void> setHelpNowEnabled(bool value) async {}

  @override
  Future<void> setSleepTonightEnabled(bool value) async {}

  @override
  Future<void> setPlanProgressEnabled(bool value) async {}

  @override
  Future<void> setFamilyRulesEnabled(bool value) async {}

  @override
  Future<void> setMetricsDashboardEnabled(bool value) async {}

  @override
  Future<void> setComplianceChecklistEnabled(bool value) async {}

  @override
  Future<void> setSleepBoundedAiEnabled(bool value) async {}

  @override
  Future<void> setSleepRhythmSurfacesEnabled(bool value) async {}

  @override
  Future<void> setRhythmShiftDetectorPromptsEnabled(bool value) async {}

  @override
  Future<void> setWindDownNotificationsEnabled(bool value) async {}

  @override
  Future<void> setScheduleDriftNotificationsEnabled(bool value) async {}

  @override
  Future<void> setPlanTabEnabled(bool value) async {}

  @override
  Future<void> setFamilyTabEnabled(bool value) async {}

  @override
  Future<void> setLibraryTabEnabled(bool value) async {}

  @override
  Future<void> setPocketEnabled(bool value) async {}

  @override
  Future<void> setRegulateEnabled(bool value) async {}

  @override
  Future<void> setSmartNudgesEnabled(bool value) async {}

  @override
  Future<void> setPatternDetectionEnabled(bool value) async {}

  @override
  Future<void> setUiV3Enabled(bool value) async {}
}

class _FlowSleepTonightNotifier extends SleepTonightNotifier {
  _FlowSleepTonightNotifier() {
    state = const SleepTonightState(
      isLoading: false,
      activePlan: null,
      breathingDifficulty: false,
      dehydrationSigns: false,
      repeatedVomiting: false,
      severePainIndicators: false,
      feedingRefusalWithPainSigns: false,
      safeSleepConfirmed: false,
      comfortMode: false,
      somethingFeelsOff: false,
      lastError: null,
    );
  }

  @override
  Future<void> createTonightPlan({
    required String childId,
    required int ageMonths,
    required String scenario,
    required String preference,
    required bool feedingAssociation,
    required String feedMode,
    required bool safeSleepConfirmed,
    String? lockedMethodId,
    int? timeToStartSeconds,
    DateTime? now,
  }) async {
    state = state.copyWith(
      activePlan: {
        'plan_id': 'test_plan_1',
        'child_id': childId,
        'scenario': scenario,
        'is_active': true,
        'steps': const [
          {
            'title': 'Set boundary and script',
            'script': 'Bedtime now. I will help you settle.',
            'do_step': 'Keep response short and calm.',
            'minutes': 3,
          },
        ],
        'current_step': 0,
        'escalation_rule': 'Pause and reset if escalation continues.',
      },
      safeSleepConfirmed: safeSleepConfirmed,
      comfortMode: false,
      somethingFeelsOff: false,
      lastError: null,
    );
  }

  @override
  Future<void> loadTonightPlan(String childId, {DateTime? now}) async {
    state = state.copyWith(isLoading: false, lastError: null);
  }
}

void _registerAdapters() {
  if (Hive.isAdapterRegistered(0)) return;
  Hive
    ..registerAdapter(ApproachAdapter())
    ..registerAdapter(AgeBracketAdapter())
    ..registerAdapter(FamilyStructureAdapter())
    ..registerAdapter(RegulationLevelAdapter())
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
    ..registerAdapter(DayPlanAdapter())
    ..registerAdapter(UserCardAdapter())
    ..registerAdapter(ResetEventAdapter());
}
