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
import 'package:settle/screens/update_rhythm_screen.dart';

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
        ageBracket: AgeBracket.nineToTwelveMonths,
        familyStructure: FamilyStructure.twoParents,
        approach: Approach.rhythmFirst,
        primaryChallenge: PrimaryChallenge.schedule,
        feedingType: FeedingType.combo,
        focusMode: FocusMode.both,
        createdAt: 'child-update-1',
      ),
    );
  }

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('settle_update_rhythm');
    Hive.init(dir.path);
    await registerHiveAdapters();
    await seedProfile();
  });

  tearDownAll(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  testWidgets('update flow builds and renders new rhythm output', (
    tester,
  ) async {
    final fakeNotifier = _FakeUpdateRhythmNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [rhythmProvider.overrideWith((ref) => fakeNotifier)],
        child: const MaterialApp(home: UpdateRhythmScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Update Rhythm'), findsWidgets);
    expect(find.text('Build next 1–2 week rhythm'), findsOneWidget);

    await tester.ensureVisible(find.text('Build next 1–2 week rhythm'));
    await tester.pump();
    await tester.tap(find.text('Build next 1–2 week rhythm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('New rhythm ready'), findsOneWidget);
    expect(find.textContaining('Recommended anchor:'), findsOneWidget);
    expect(find.textContaining('Confidence:'), findsOneWidget);
  });
}

class _FakeUpdateRhythmNotifier extends RhythmNotifier {
  _FakeUpdateRhythmNotifier() {
    final rhythm = Rhythm(
      id: 'rhythm_update_test',
      ageMonths: 10,
      napCountTarget: 2,
      napTargetsBySlotMinutes: const {'nap1': 90, 'nap2': 75},
      wakeWindowsBySlotMinutes: const {
        'nap1': 150,
        'nap2': 180,
        'bedtime': 210,
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
  }) async {
    state = state.copyWith(isLoading: false);
  }

  @override
  Future<void> applyRhythmUpdate({
    required String childId,
    required int ageMonths,
    required int wakeRangeStartMinutes,
    required int wakeRangeEndMinutes,
    required bool daycareMode,
    required int? napCountReality,
    required RhythmUpdateIssue issue,
    DateTime? now,
  }) async {
    final updated = state.rhythm!.copyWith(
      bedtimeAnchorMinutes: (state.rhythm!.bedtimeAnchorMinutes - 15),
      confidence: RhythmConfidence.high,
    );
    state = state.copyWith(
      rhythm: updated,
      lastUpdatePlan: RhythmUpdatePlan(
        rhythm: updated,
        anchorRecommendation: 'Recommended anchor: 19:15 (lock for 7-14 days).',
        confidence: RhythmConfidence.high,
        changeSummary: const ['Moved bedtime earlier by 15 minutes.'],
        whyNow: 'Why update now: 3 rough nights in the last 5.',
      ),
    );
  }
}
