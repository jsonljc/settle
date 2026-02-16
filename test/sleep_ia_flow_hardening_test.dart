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
import 'package:settle/models/rhythm_models.dart';
import 'package:settle/models/sleep_session.dart';
import 'package:settle/models/tantrum_profile.dart';
import 'package:settle/providers/release_rollout_provider.dart';
import 'package:settle/providers/rhythm_provider.dart';
import 'package:settle/screens/current_rhythm_screen.dart';
import 'package:settle/screens/update_rhythm_screen.dart';

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
  Future<void> setV2NavigationEnabled(bool value) async {}
  @override
  Future<void> setV2OnboardingEnabled(bool value) async {}
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
}

class _FakeRhythmNotifier extends RhythmNotifier {
  _FakeRhythmNotifier() {
    final rhythm = Rhythm(
      id: 'rhythm_ia_test',
      ageMonths: 8,
      napCountTarget: 3,
      napTargetsBySlotMinutes: const {'nap1': 80, 'nap2': 75, 'nap3': 45},
      wakeWindowsBySlotMinutes: const {
        'nap1': 120,
        'nap2': 150,
        'nap3': 165,
        'bedtime': 180,
      },
      bedtimeAnchorMinutes: 1170,
      softWindowMinutes: 20,
      rescueNapEnabled: true,
      locks: const RhythmLocks(
        bedtimeAnchorLocked: true,
        daycareNapBlocksLocked: false,
        hardConstraintBlocksLocked: false,
      ),
      confidence: RhythmConfidence.medium,
      hysteresisMinutes: 20,
      updatedAt: DateTime(2026, 2, 15, 8),
    );

    state = RhythmState(
      isLoading: false,
      rhythm: rhythm,
      todaySchedule: DaySchedule(
        dateKey: '2026-02-15',
        wakeTimeMinutes: 420,
        wakeTimeKnown: true,
        blocks: const [
          RhythmScheduleBlock(
            id: 'wake',
            label: 'Wake',
            centerlineMinutes: 420,
            windowStartMinutes: 420,
            windowEndMinutes: 420,
            anchorLocked: false,
          ),
          RhythmScheduleBlock(
            id: 'bedtime',
            label: 'Bedtime',
            centerlineMinutes: 1170,
            windowStartMinutes: 1150,
            windowEndMinutes: 1190,
            anchorLocked: true,
          ),
        ],
        confidence: RhythmConfidence.medium,
        appliedHysteresis: true,
        generatedAt: DateTime(2026, 2, 15, 8),
      ),
      events: const [],
      recapHistory: const [],
      dailySignals: const [],
      shiftAssessment: RhythmShiftAssessment(
        shouldSuggestUpdate: true,
        softPromptOnly: false,
        reasons: [
          RhythmShiftReason(
            type: RhythmShiftReasonType.roughNights,
            title: 'Rough nights pattern',
            detail: '3 rough nights in the last 5',
            hardTrigger: true,
          ),
        ],
        explanation: 'Why update now: 3 rough nights in the last 5.',
      ),
      lastUpdatePlan: null,
      lastRhythmUpdateAt: null,
      advancedDayLogging: false,
      preciseView: true,
      wakeTimeMinutes: 420,
      wakeTimeKnown: true,
      lastHint: null,
    );
  }

  @override
  Future<void> load({
    required String childId,
    required int ageMonths,
    DateTime? now,
  }) async {}
}

void main() {
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

  Future<void> seedProfile() async {
    final box = await Hive.openBox<BabyProfile>('profile');
    await box.put(
      'baby',
      BabyProfile(
        name: 'Ari',
        ageBracket: AgeBracket.sixToEightMonths,
        familyStructure: FamilyStructure.twoParents,
        approach: Approach.rhythmFirst,
        primaryChallenge: PrimaryChallenge.schedule,
        feedingType: FeedingType.combo,
        focusMode: FocusMode.both,
        createdAt: 'child-ia-1',
      ),
    );
  }

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync(
      'settle_sleep_ia_hardening',
    );
    Hive.init(dir.path);
    await registerHiveAdapters();
    await seedProfile();
  });

  tearDownAll(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget app({
    required ReleaseRolloutState rollout,
    required RhythmNotifier notifier,
  }) {
    final router = GoRouter(
      initialLocation: '/sleep/rhythm',
      routes: [
        GoRoute(
          path: '/sleep/rhythm',
          builder: (context, state) => const CurrentRhythmScreen(),
        ),
        GoRoute(
          path: '/sleep/update',
          builder: (context, state) => const UpdateRhythmScreen(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        releaseRolloutProvider.overrideWith(
          (ref) => _StaticRolloutNotifier(rollout),
        ),
        rhythmProvider.overrideWith((ref) => notifier),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('IA flow reaches Update Rhythm from Current Rhythm', (
    tester,
  ) async {
    setPhoneViewport(tester);
    final notifier = _FakeRhythmNotifier();
    const rollout = ReleaseRolloutState(
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
      scheduleDriftNotificationsEnabled: true,
    );

    await tester.pumpWidget(app(rollout: rollout, notifier: notifier));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Current Rhythm (this week)'), findsOneWidget);
    expect(find.text('Update Rhythm suggested'), findsOneWidget);

    await tester.ensureVisible(find.text('Update Rhythm'));
    await tester.tap(find.text('Update Rhythm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Step 1 of 4'), findsOneWidget);
  });

  testWidgets('kill-switch hides rhythm surfaces', (tester) async {
    setPhoneViewport(tester);

    const surfaceOff = ReleaseRolloutState(
      isLoading: false,
      helpNowEnabled: true,
      sleepTonightEnabled: true,
      planProgressEnabled: true,
      familyRulesEnabled: true,
      metricsDashboardEnabled: true,
      complianceChecklistEnabled: true,
      sleepBoundedAiEnabled: true,
      sleepRhythmSurfacesEnabled: false,
      rhythmShiftDetectorPromptsEnabled: true,
      windDownNotificationsEnabled: true,
      scheduleDriftNotificationsEnabled: true,
    );

    await tester.pumpWidget(
      app(rollout: surfaceOff, notifier: _FakeRhythmNotifier()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Current Rhythm'), findsOneWidget);
    expect(find.text('This section is unavailable right now.'), findsOneWidget);
  });

  testWidgets('detector prompt kill-switch hides update suggestion', (
    tester,
  ) async {
    setPhoneViewport(tester);

    const promptOff = ReleaseRolloutState(
      isLoading: false,
      helpNowEnabled: true,
      sleepTonightEnabled: true,
      planProgressEnabled: true,
      familyRulesEnabled: true,
      metricsDashboardEnabled: true,
      complianceChecklistEnabled: true,
      sleepBoundedAiEnabled: true,
      sleepRhythmSurfacesEnabled: true,
      rhythmShiftDetectorPromptsEnabled: false,
      windDownNotificationsEnabled: true,
      scheduleDriftNotificationsEnabled: true,
    );

    await tester.pumpWidget(
      app(rollout: promptOff, notifier: _FakeRhythmNotifier()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('This section is unavailable right now.'), findsNothing);
    expect(find.text('Update Rhythm suggested'), findsNothing);
  });
}
