import 'package:flutter_test/flutter_test.dart';
import 'package:settle/models/rhythm_models.dart';
import 'package:settle/services/rhythm_engine_service.dart';

void main() {
  const engine = RhythmEngineService.instance;

  test('default rhythm is canonical and age-banded', () {
    final rhythm = engine.defaultRhythmForAge(ageMonths: 7);

    expect(rhythm.napCountTarget, 3);
    expect(rhythm.napTargetsBySlotMinutes.containsKey('nap1'), isTrue);
    expect(rhythm.wakeWindowsBySlotMinutes.containsKey('nap1'), isTrue);
    expect(rhythm.wakeWindowsBySlotMinutes.containsKey('bedtime'), isTrue);
    expect(rhythm.locks.bedtimeAnchorLocked, isTrue);
    expect(rhythm.hysteresisMinutes, greaterThanOrEqualTo(15));
  });

  test('day schedule emits centerline and soft windows', () {
    final rhythm = engine.defaultRhythmForAge(ageMonths: 10);
    final schedule = engine.buildDaySchedule(
      rhythm: rhythm,
      wakeTimeMinutes: 7 * 60,
      wakeTimeKnown: true,
      events: const [],
    );

    final wake = schedule.blocks.first;
    final nap1 = schedule.blocks.firstWhere((b) => b.id == 'nap1');
    final bedtime = schedule.blocks.firstWhere((b) => b.id == 'bedtime');

    expect(wake.id, 'wake');
    expect(nap1.windowStartMinutes, isNot(equals(nap1.centerlineMinutes)));
    expect(nap1.windowEndMinutes, isNot(equals(nap1.centerlineMinutes)));
    expect(bedtime.anchorLocked, isTrue);
  });

  test('hysteresis keeps schedule stable under small wake-time shifts', () {
    final rhythm = engine.defaultRhythmForAge(ageMonths: 8);
    final baseline = engine.buildDaySchedule(
      rhythm: rhythm,
      wakeTimeMinutes: 7 * 60,
      wakeTimeKnown: true,
      events: const [],
    );

    final slightShift = engine.buildDaySchedule(
      rhythm: rhythm,
      wakeTimeMinutes: (7 * 60) + 10,
      wakeTimeKnown: true,
      events: const [],
      previousSchedule: baseline,
    );

    final largeShift = engine.buildDaySchedule(
      rhythm: rhythm,
      wakeTimeMinutes: (7 * 60) + 45,
      wakeTimeKnown: true,
      events: const [],
      previousSchedule: baseline,
    );

    final baselineNap1 = baseline.blocks.firstWhere((b) => b.id == 'nap1');
    final slightNap1 = slightShift.blocks.firstWhere((b) => b.id == 'nap1');
    final largeNap1 = largeShift.blocks.firstWhere((b) => b.id == 'nap1');

    expect(slightShift.appliedHysteresis, isTrue);
    expect(slightNap1.centerlineMinutes, baselineNap1.centerlineMinutes);
    expect(largeNap1.centerlineMinutes, isNot(baselineNap1.centerlineMinutes));
  });

  test('short nap and skipped nap events affect projected durations', () {
    final rhythm = engine.defaultRhythmForAge(ageMonths: 9);

    final schedule = engine.buildDaySchedule(
      rhythm: rhythm,
      wakeTimeMinutes: 7 * 60,
      wakeTimeKnown: true,
      events: [
        RhythmDayEvent(
          type: RhythmDayEventType.shortNap,
          napIndex: 1,
          createdAt: DateTime(2026, 2, 15, 9),
        ),
        RhythmDayEvent(
          type: RhythmDayEventType.skippedNap,
          napIndex: 2,
          createdAt: DateTime(2026, 2, 15, 13),
        ),
      ],
    );

    final nap1 = schedule.blocks.firstWhere((b) => b.id == 'nap1');
    final nap2 = schedule.blocks.firstWhere((b) => b.id == 'nap2');

    expect(nap1.expectedDurationMinMinutes, lessThan(60));
    expect(nap2.expectedDurationMaxMinutes, 0);
  });

  test(
    'update rhythm output returns 1-2 week plan with anchor recommendation',
    () {
      final current = engine.defaultRhythmForAge(ageMonths: 9);
      final plan = engine.buildUpdatedRhythm(
        currentRhythm: current,
        ageMonths: 9,
        wakeRangeStartMinutes: (6 * 60) + 30,
        wakeRangeEndMinutes: 7 * 60,
        daycareMode: false,
        napCountReality: 2,
        issue: RhythmUpdateIssue.earlyWakes,
        whyNow: 'Why update now: repeated early wakes.',
        now: DateTime(2026, 2, 15, 8),
      );

      expect(plan.rhythm.napCountTarget, 2);
      expect(
        plan.rhythm.bedtimeAnchorMinutes,
        isNot(current.bedtimeAnchorMinutes),
      );
      expect(plan.anchorRecommendation, contains('Recommended anchor:'));
      expect(plan.changeSummary.isNotEmpty, isTrue);
    },
  );
}
