import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settle/models/approach.dart';
import 'package:settle/models/baby_profile.dart';
import 'package:settle/models/day_plan.dart';
import 'package:settle/models/night_wake.dart';
import 'package:settle/models/rhythm_models.dart';
import 'package:settle/models/sleep_session.dart';
import 'package:settle/models/tantrum_profile.dart';
import 'package:settle/providers/rhythm_provider.dart';
import 'package:settle/screens/current_rhythm_screen.dart';

void main() {
  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

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
        createdAt: 'child-rhythm-1',
      ),
    );
  }

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync(
      'settle_current_rhythm_screen',
    );
    Hive.init(dir.path);
    await registerHiveAdapters();
    await seedProfile();
  });

  tearDownAll(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  testWidgets('renders rhythm surface with precise/relaxed and recalc', (
    tester,
  ) async {
    final fakeNotifier = _FakeRhythmNotifier();
    setPhoneViewport(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [rhythmProvider.overrideWith((ref) => fakeNotifier)],
        child: const MaterialApp(home: CurrentRhythmScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Today rhythm'), findsOneWidget);
    expect(find.text('Precise view'), findsOneWidget);
    expect(find.text('Relaxed view'), findsOneWidget);
    expect(find.text('Late morning nap'), findsOneWidget);

    await tester.ensureVisible(find.text('Relaxed view'));
    await tester.tap(find.text('Relaxed view'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Late morning nap'), findsOneWidget);

    await tester.ensureVisible(find.text('Adjust today'));
    await tester.tap(find.text('Adjust today'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('OK nap'), findsOneWidget);
    expect(find.text('Long nap'), findsOneWidget);

    await tester.ensureVisible(find.text('Tools'));
    await tester.tap(find.text('Tools'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Recalculate schedule'), findsOneWidget);
    expect(find.text('Advanced mode: Off'), findsOneWidget);

    await tester.ensureVisible(find.text('Recalculate schedule'));
    await tester.tap(find.text('Recalculate schedule'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Still okay.'), findsOneWidget);
  });
}

class _FakeRhythmNotifier extends RhythmNotifier {
  _FakeRhythmNotifier() {
    final rhythm = Rhythm(
      id: 'rhythm_test',
      ageMonths: 7,
      napCountTarget: 3,
      napTargetsBySlotMinutes: const {'nap1': 80, 'nap2': 75, 'nap3': 45},
      wakeWindowsBySlotMinutes: const {
        'nap1': 120,
        'nap2': 150,
        'nap3': 165,
        'bedtime': 180,
      },
      bedtimeAnchorMinutes: 19 * 60 + 30,
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
            id: 'nap1',
            label: 'Nap 1',
            centerlineMinutes: 540,
            windowStartMinutes: 520,
            windowEndMinutes: 560,
            anchorLocked: false,
            expectedDurationMinMinutes: 60,
            expectedDurationMaxMinutes: 90,
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
      shiftAssessment: RhythmShiftAssessment.none,
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
  }) async {
    state = state.copyWith(isLoading: false);
  }

  @override
  Future<void> setPreciseView({
    required String childId,
    required bool precise,
  }) async {
    state = state.copyWith(preciseView: precise);
  }

  @override
  Future<void> recalculate({required String childId}) async {
    state = state.copyWith(lastHint: 'Still okay. Schedule recalculated.');
  }
}
