import 'package:flutter_test/flutter_test.dart';
import 'package:settle/models/rhythm_models.dart';
import 'package:settle/services/rhythm_engine_service.dart';
import 'package:settle/services/sleep_ai_explainer_service.dart';

void main() {
  const engine = RhythmEngineService.instance;

  test('buildDaySchedule is deterministic for identical inputs', () {
    final now = DateTime(2026, 2, 15, 7, 30);
    final rhythm = engine.defaultRhythmForAge(ageMonths: 7, now: now);
    final events = [
      RhythmDayEvent(
        type: RhythmDayEventType.shortNap,
        napIndex: 1,
        createdAt: now,
      ),
    ];

    final a = engine.buildDaySchedule(
      rhythm: rhythm,
      wakeTimeMinutes: 420,
      wakeTimeKnown: true,
      events: events,
      previousSchedule: null,
      now: now,
    );
    final b = engine.buildDaySchedule(
      rhythm: rhythm,
      wakeTimeMinutes: 420,
      wakeTimeKnown: true,
      events: events,
      previousSchedule: null,
      now: now,
    );

    expect(a.toMap(), b.toMap());
  });

  test('buildUpdatedRhythm is deterministic for identical inputs', () {
    final now = DateTime(2026, 2, 15, 8);
    final base = engine.defaultRhythmForAge(ageMonths: 10, now: now);

    final a = engine.buildUpdatedRhythm(
      currentRhythm: base,
      ageMonths: 10,
      wakeRangeStartMinutes: 390,
      wakeRangeEndMinutes: 420,
      daycareMode: false,
      napCountReality: 2,
      issue: RhythmUpdateIssue.nightWakes,
      whyNow: 'Why update now: repeated night wakes.',
      now: now,
    );
    final b = engine.buildUpdatedRhythm(
      currentRhythm: base,
      ageMonths: 10,
      wakeRangeStartMinutes: 390,
      wakeRangeEndMinutes: 420,
      daycareMode: false,
      napCountReality: 2,
      issue: RhythmUpdateIssue.nightWakes,
      whyNow: 'Why update now: repeated night wakes.',
      now: now,
    );

    expect(a.rhythm.toMap(), b.rhythm.toMap());
    expect(a.anchorRecommendation, b.anchorRecommendation);
    expect(a.changeSummary, b.changeSummary);
  });

  test(
    'bounded AI explainer does not alter deterministic schedule outputs',
    () {
      final now = DateTime(2026, 2, 15, 7, 30);
      final rhythm = engine.defaultRhythmForAge(ageMonths: 7, now: now);

      final before = engine.buildDaySchedule(
        rhythm: rhythm,
        wakeTimeMinutes: 420,
        wakeTimeKnown: true,
        events: const [],
        previousSchedule: null,
        now: now,
      );

      SleepAiExplainerService.instance.summarizeRhythm(
        schedule: before,
        shiftAssessment: RhythmShiftAssessment.none,
        recapHistory: const [],
        dailySignals: const [],
      );

      final after = engine.buildDaySchedule(
        rhythm: rhythm,
        wakeTimeMinutes: 420,
        wakeTimeKnown: true,
        events: const [],
        previousSchedule: null,
        now: now,
      );

      expect(after.toMap(), before.toMap());
    },
  );
}
