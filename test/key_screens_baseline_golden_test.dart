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
import 'package:settle/providers/plan_progress_provider.dart';
import 'package:settle/providers/sleep_tonight_provider.dart';
import 'package:settle/screens/family_rules.dart';
import 'package:settle/screens/help_now.dart';
import 'package:settle/screens/plan_progress.dart';
import 'package:settle/screens/sleep_tonight.dart';

void main() {
  const childId = 'golden-child-1';
  BabyProfile buildProfile() {
    return BabyProfile(
      name: 'Ari',
      ageBracket: AgeBracket.twoToThreeYears,
      familyStructure: FamilyStructure.twoParents,
      approach: Approach.stayAndSupport,
      primaryChallenge: PrimaryChallenge.nightWaking,
      feedingType: FeedingType.combo,
      focusMode: FocusMode.both,
      createdAt: childId,
    );
  }

  Widget harness(Widget child, {List<Override> overrides = const []}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [GoRoute(path: '/', builder: (context, state) => child)],
    );
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        theme: ThemeData.dark(
          useMaterial3: true,
        ).copyWith(scaffoldBackgroundColor: Colors.transparent),
        routerConfig: router,
      ),
    );
  }

  Future<void> seedState() async {
    final profileBox = await Hive.openBox<BabyProfile>('profile');
    await profileBox.put('baby', buildProfile());

    final rolloutBox = await Hive.openBox<dynamic>('release_rollout_v1');
    await rolloutBox.put('state', {
      'schema_version': 1,
      'help_now_enabled': true,
      'sleep_tonight_enabled': true,
      'plan_progress_enabled': true,
      'family_rules_enabled': true,
      'metrics_dashboard_enabled': true,
      'compliance_checklist_enabled': true,
    });

    final sleepBox = await Hive.openBox<dynamic>('sleep_tonight_v1');
    await sleepBox.clear();

    final planBox = await Hive.openBox<dynamic>('plan_progress_v1');
    await planBox.put('plan_progress:$childId', {
      'bottleneck': 'Public meltdowns',
      'experiment': null,
      'evidence': 'Selected this week by caregiver.',
      'rhythm': {
        'wake': '07:00',
        'nap': '13:00',
        'meals': '08:00 / 12:00 / 17:30',
        'milk': '08:30 / 19:00',
        'bedtime_routine': '19:30',
      },
      'updated_at': '2026-02-13T10:00:00.000Z',
    });

    final rulesBox = await Hive.openBox<dynamic>('family_rules_v1');
    await rulesBox.put('state', {
      'schema_version': 1,
      'ruleset_version': 3,
      'rules': {
        'boundary_public': 'One script, then hold the line calmly.',
        'screens_default': 'No screens before breakfast.',
        'snacks_default': 'Snack windows only.',
        'bedtime_routine': 'Bath, books, bed.',
      },
      'pending_diffs': [],
      'change_feed': [],
      'updated_at': '2026-02-13T10:00:00.000Z',
    });

    final eventBusBox = await Hive.openBox<dynamic>('event_bus_v1');
    await eventBusBox.clear();
  }

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('settle_key_goldens');
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
    await seedState();
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  void configureSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
  }

  void resetSurface(WidgetTester tester) {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  testWidgets('Help Now baseline', (tester) async {
    configureSurface(tester);
    addTearDown(() => resetSurface(tester));

    await tester.pumpWidget(
      harness(HelpNowScreen(now: () => DateTime(2026, 2, 13, 14))),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(HelpNowScreen),
      matchesGoldenFile('goldens/help_now.png'),
    );
  });

  testWidgets('Sleep Tonight baseline', (tester) async {
    configureSurface(tester);
    addTearDown(() => resetSurface(tester));

    const sleepState = SleepTonightState(
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

    await tester.pumpWidget(
      harness(
        const SleepTonightScreen(),
        overrides: [
          sleepTonightProvider.overrideWith(
            (ref) => _GoldenSleepTonightNotifier(sleepState),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SleepTonightScreen),
      matchesGoldenFile('goldens/sleep_tonight.png'),
    );
  });

  testWidgets('Plan & Progress baseline', (tester) async {
    configureSurface(tester);
    addTearDown(() => resetSurface(tester));

    const planState = PlanProgressState(
      isLoading: false,
      bottleneck: 'Public meltdowns',
      experiment: null,
      evidence: 'Selected this week by caregiver.',
      rhythm: {
        'wake': '07:00',
        'nap': '13:00',
        'meals': '08:00 / 12:00 / 17:30',
        'milk': '08:30 / 19:00',
        'bedtime_routine': '19:30',
      },
      insightEligible: false,
    );

    await tester.pumpWidget(
      harness(
        const PlanProgressScreen(),
        overrides: [
          planProgressProvider.overrideWith(
            (ref) => _GoldenPlanProgressNotifier(planState),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(PlanProgressScreen),
      matchesGoldenFile('goldens/plan_progress.png'),
    );
  });

  testWidgets('Family Rules baseline', (tester) async {
    configureSurface(tester);
    addTearDown(() => resetSurface(tester));

    await tester.pumpWidget(harness(const FamilyRulesScreen()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(FamilyRulesScreen),
      matchesGoldenFile('goldens/family_rules.png'),
    );
  });
}

class _GoldenSleepTonightNotifier extends SleepTonightNotifier {
  _GoldenSleepTonightNotifier(this._seed) {
    state = _seed;
  }

  final SleepTonightState _seed;

  @override
  Future<void> loadTonightPlan(String childId, {DateTime? now}) async {
    state = _seed;
  }
}

class _GoldenPlanProgressNotifier extends PlanProgressNotifier {
  _GoldenPlanProgressNotifier(this._seed) {
    state = _seed;
  }

  final PlanProgressState _seed;

  @override
  Future<void> load({required String childId}) async {
    state = _seed;
  }
}
