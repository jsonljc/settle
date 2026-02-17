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
import 'package:settle/providers/sleep_tonight_provider.dart';
import 'package:settle/screens/sleep_tonight.dart';

void main() {
  const childId = 'sleep-runner-child-1';

  Future<void> registerHiveAdapters() async {
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
  }

  Future<void> seedState() async {
    final profileBox = await Hive.openBox<BabyProfile>('profile');
    await profileBox.put(
      'baby',
      BabyProfile(
        name: 'Ari',
        ageBracket: AgeBracket.twoToThreeYears,
        familyStructure: FamilyStructure.twoParents,
        approach: Approach.stayAndSupport,
        primaryChallenge: PrimaryChallenge.nightWaking,
        feedingType: FeedingType.combo,
        focusMode: FocusMode.both,
        createdAt: childId,
      ),
    );

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
  }

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('settle_sleep_runner_flow');
    Hive.init(dir.path);
    await registerHiveAdapters();
  });

  setUp(() async {
    await seedState();
  });

  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<void> settleUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  Future<void> tapByText(WidgetTester tester, String label) async {
    await tester.pump(const Duration(milliseconds: 50));
    final target = find.text(label);
    expect(target, findsWidgets);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
  }

  Future<void> openMoreOptions(WidgetTester tester) async {
    await tapByText(tester, 'More options');
    for (var i = 0; i < 20; i++) {
      if (find.text('Switch scenario').evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
  }

  Widget buildApp() {
    final router = GoRouter(
      initialLocation: '/sleep-tonight',
      routes: [
        GoRoute(
          path: '/sleep-tonight',
          builder: (context, state) => const SleepTonightScreen(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        sleepTonightProvider.overrideWith((ref) => _FlowSleepTonightNotifier()),
        releaseRolloutProvider.overrideWith(
          (ref) => _StaticRolloutNotifier(_rolloutState),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  Widget buildActivePlanApp(_ActivePlanSleepTonightNotifier notifier) {
    final router = GoRouter(
      initialLocation: '/sleep-tonight',
      routes: [
        GoRoute(
          path: '/sleep-tonight',
          builder: (context, state) => const SleepTonightScreen(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        sleepTonightProvider.overrideWith((ref) => notifier),
        releaseRolloutProvider.overrideWith(
          (ref) => _StaticRolloutNotifier(_rolloutState),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('Sleep Tonight runner executes core actions end-to-end', (
    tester,
  ) async {
    setPhoneViewport(tester);
    await tester.pumpWidget(buildApp());
    await settleUi(tester);

    expect(find.text('Tonight'), findsOneWidget);
    if (find.text('Choose what is happening').evaluate().isNotEmpty) {
      await tapByText(tester, 'Night wake');
    }
    expect(find.textContaining('Do now:'), findsOneWidget);

    await tapByText(tester, 'Next step');
    await openMoreOptions(tester);
    await tapByText(tester, 'Mark done');
    await tapByText(tester, 'Save recap');
    await settleUi(tester);

    expect(find.textContaining('Do now:'), findsOneWidget);
  });

  testWidgets('active plan shows wake guidance immediately', (tester) async {
    final notifier = _ActivePlanSleepTonightNotifier();
    setPhoneViewport(tester);
    await tester.pumpWidget(buildActivePlanApp(notifier));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Do now:'), findsOneWidget);
    expect(find.text('More options'), findsOneWidget);
    expect(find.text('Choose what is happening'), findsNothing);
  });

  testWidgets('More options exposes safety and switch controls', (
    tester,
  ) async {
    setPhoneViewport(tester);
    await tester.pumpWidget(buildApp());
    await settleUi(tester);

    if (find.text('Choose what is happening').evaluate().isNotEmpty) {
      await tapByText(tester, 'Night wake');
    }
    await openMoreOptions(tester);
    expect(find.text('Switch scenario'), findsOneWidget);
    expect(find.text('Change approach'), findsOneWidget);
    expect(find.text('Something feels off'), findsOneWidget);
  });
}

const _rolloutState = ReleaseRolloutState(
  isLoading: false,
  helpNowEnabled: true,
  sleepTonightEnabled: true,
  planProgressEnabled: true,
  familyRulesEnabled: true,
  metricsDashboardEnabled: true,
  complianceChecklistEnabled: true,
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

  Map<String, dynamic>? _activePlanCopy() {
    final plan = state.activePlan;
    if (plan == null) return null;
    return Map<String, dynamic>.from(plan);
  }

  @override
  Future<void> loadTonightPlan(String childId, {DateTime? now}) async {
    state = state.copyWith(
      isLoading: false,
      activePlan: null,
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
    final plan = <String, dynamic>{
      'plan_id': 'test_plan_1',
      'child_id': childId,
      'scenario': scenario,
      'preference': preference,
      'feeding_association': feedingAssociation,
      'feed_mode': feedMode,
      'safe_sleep_confirmed': safeSleepConfirmed,
      'steps': const [
        {
          'title': 'Set boundary and script',
          'script': 'Bedtime now. I will help you settle.',
          'do_step': 'Keep response short and calm.',
          'minutes': 3,
        },
        {
          'title': 'One calm intervention',
          'script': 'I keep this brief and steady.',
          'do_step': 'Repeat script once and pause.',
          'minutes': 3,
        },
        {
          'title': 'Pause before next response',
          'script': 'I stay consistent. You are safe.',
          'do_step': 'Hold boundary and reduce language.',
          'minutes': 4,
        },
      ],
      'current_step': 0,
      'wakes_logged': 0,
      'early_wakes_logged': 0,
      'is_active': true,
      'escalation_rule': 'If escalation continues, reset to step 1.',
      'morning_review_complete': false,
      'runner_hint': '',
    };

    state = state.copyWith(
      activePlan: plan,
      safeSleepConfirmed: safeSleepConfirmed,
      comfortMode: false,
      somethingFeelsOff: false,
      lastError: null,
    );
  }

  @override
  Future<void> completeCurrentStep() async {
    final plan = _activePlanCopy();
    if (plan == null) return;
    final steps = (plan['steps'] as List?)?.cast<Map>() ?? const <Map>[];
    final current = plan['current_step'] as int? ?? 0;

    if (current < steps.length - 1) {
      final next = current + 1;
      plan['current_step'] = next;
      plan['runner_hint'] = 'Step complete. Start step ${next + 1} now.';
    } else {
      plan['runner_hint'] =
          'Step complete. Hold this response unless a wake is logged.';
    }
    state = state.copyWith(activePlan: plan);
  }

  @override
  Future<void> logNightWake() async {
    final plan = _activePlanCopy();
    if (plan == null) return;
    final steps = (plan['steps'] as List?)?.cast<Map>() ?? const <Map>[];
    final current = plan['current_step'] as int? ?? 0;
    final nextStep = steps.isEmpty
        ? 0
        : (current + 1).clamp(0, steps.length - 1);
    plan['current_step'] = nextStep;
    plan['wakes_logged'] = (plan['wakes_logged'] as int? ?? 0) + 1;
    plan['runner_hint'] = 'Wake logged. Start step ${nextStep + 1} now.';
    state = state.copyWith(activePlan: plan);
  }

  @override
  Future<void> logEarlyWake() async {
    final plan = _activePlanCopy();
    if (plan == null) return;
    plan['current_step'] = 0;
    plan['early_wakes_logged'] = (plan['early_wakes_logged'] as int? ?? 0) + 1;
    plan['runner_hint'] = 'Early wake logged. Restart at step 1.';
    state = state.copyWith(activePlan: plan);
  }

  @override
  Future<void> logFeedTaperStep() async {}

  @override
  Future<void> completeMorningReview() async {
    final plan = _activePlanCopy();
    if (plan == null) return;
    plan['morning_review_complete'] = true;
    plan['runner_hint'] = 'Morning review captured.';
    state = state.copyWith(activePlan: plan);
  }

  @override
  Future<void> abortPlan() async {
    final plan = _activePlanCopy();
    if (plan == null) return;
    plan['is_active'] = false;
    plan['runner_hint'] = 'Plan paused.';
    state = state.copyWith(activePlan: plan);
  }
}

class _ActivePlanSleepTonightNotifier extends SleepTonightNotifier {
  _ActivePlanSleepTonightNotifier() {
    state = SleepTonightState(
      isLoading: false,
      activePlan: {
        'plan_id': 'active_plan_1',
        'child_id': 'sleep-runner-child-1',
        'date': '2026-02-13',
        'is_active': true,
        'safe_sleep_confirmed': true,
        'comfort_mode': false,
        'something_feels_off': false,
        'training_paused': false,
        'steps': const [
          {
            'title': 'Set boundary and script',
            'script': 'Bedtime now. I will help you settle.',
            'do_step': 'Keep response short and calm.',
            'minutes': 3,
          },
          {
            'title': 'One calm intervention',
            'script': 'I keep this brief and steady.',
            'do_step': 'Repeat script once and pause.',
            'minutes': 3,
          },
        ],
        'current_step': 0,
        'wakes_logged': 0,
        'early_wakes_logged': 0,
        'escalation_rule': 'If escalation continues, reset to step 1.',
        'morning_review_complete': false,
        'runner_hint': '',
      },
      breathingDifficulty: false,
      dehydrationSigns: false,
      repeatedVomiting: false,
      severePainIndicators: false,
      feedingRefusalWithPainSigns: false,
      safeSleepConfirmed: true,
      comfortMode: false,
      somethingFeelsOff: false,
      lastError: null,
    );
  }

  @override
  Future<void> loadTonightPlan(String childId, {DateTime? now}) async {
    state = state.copyWith(isLoading: false, lastError: null);
  }

  @override
  Future<void> markSomethingFeelsOff() async {
    final plan = Map<String, dynamic>.from(state.activePlan ?? const {});
    plan['comfort_mode'] = true;
    plan['something_feels_off'] = true;
    plan['training_paused'] = true;
    plan['runner_hint'] = 'Something feels off. Comfort first tonight.';
    state = state.copyWith(
      activePlan: plan,
      comfortMode: true,
      somethingFeelsOff: true,
    );
  }
}
