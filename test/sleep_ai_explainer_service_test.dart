import 'package:flutter_test/flutter_test.dart';
import 'package:settle/models/rhythm_models.dart';
import 'package:settle/services/sleep_ai_explainer_service.dart';

void main() {
  test(
    'night wake explanation summarizes mode/changes without rule mutation',
    () {
      const plan = <String, dynamic>{
        'current_step': 1,
        'wakes_logged': 2,
        'early_wakes_logged': 1,
        'steps': [
          {'minutes': 3},
          {'minutes': 5},
        ],
      };

      final explanation = SleepAiExplainerService.instance.explainNightWake(
        plan: plan,
        comfortMode: false,
        somethingFeelsOff: false,
      );

      expect(explanation.whatChanged, contains('step 2'));
      expect(explanation.why, contains('5 minutes'));
      expect(explanation.patternSummary, contains('2 wake(s)'));
    },
  );

  test('rhythm summary uses deterministic shift assessment copy', () {
    final schedule = DaySchedule(
      dateKey: '2026-02-15',
      wakeTimeMinutes: 420,
      wakeTimeKnown: true,
      blocks: const [],
      confidence: RhythmConfidence.medium,
      appliedHysteresis: true,
      generatedAt: DateTime(2026, 2, 15, 7),
    );
    final recapHistory = [
      MorningRecapEntry(
        dateKey: '2026-02-14',
        nightQuality: MorningRecapNightQuality.rough,
        wakesBucket: MorningRecapWakesBucket.threePlus,
        longestAwakeBucket: MorningRecapLongestAwakeBucket.over30,
        createdAt: DateTime(2026, 2, 14, 7),
      ),
    ];
    final dailySignals = [
      RhythmDailySignal(
        dateKey: '2026-02-14',
        shortNapCount: 1,
        skippedNapCount: 0,
        earlyWakeLogged: false,
        bedtimeResistance: true,
        bedtimeDelayMinutes: 25,
        createdAt: DateTime(2026, 2, 14, 21),
      ),
    ];
    const shift = RhythmShiftAssessment(
      shouldSuggestUpdate: true,
      softPromptOnly: false,
      reasons: [],
      explanation: 'Why update now: 3 rough nights in the last 5.',
    );

    final summary = SleepAiExplainerService.instance.summarizeRhythm(
      schedule: schedule,
      shiftAssessment: shift,
      recapHistory: recapHistory,
      dailySignals: dailySignals,
    );

    expect(summary.headline, 'Rhythm shift detected');
    expect(summary.whatChanged, contains('anchored'));
    expect(summary.why, shift.explanation);
    expect(summary.patternSummary, contains('rough night(s)'));
  });
}
