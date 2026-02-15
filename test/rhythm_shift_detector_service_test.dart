import 'package:flutter_test/flutter_test.dart';
import 'package:settle/models/rhythm_models.dart';
import 'package:settle/services/rhythm_shift_detector_service.dart';

void main() {
  const detector = RhythmShiftDetectorService.instance;

  DateTime day(int d) => DateTime(2026, 2, d, 8);

  test('detects hard trigger on 3+ rough nights in last 5', () {
    final recaps = [
      MorningRecapEntry(
        dateKey: '2026-02-15',
        nightQuality: MorningRecapNightQuality.rough,
        wakesBucket: MorningRecapWakesBucket.threePlus,
        longestAwakeBucket: MorningRecapLongestAwakeBucket.over30,
        createdAt: day(15),
      ),
      MorningRecapEntry(
        dateKey: '2026-02-14',
        nightQuality: MorningRecapNightQuality.rough,
        wakesBucket: MorningRecapWakesBucket.threePlus,
        longestAwakeBucket: MorningRecapLongestAwakeBucket.over30,
        createdAt: day(14),
      ),
      MorningRecapEntry(
        dateKey: '2026-02-13',
        nightQuality: MorningRecapNightQuality.rough,
        wakesBucket: MorningRecapWakesBucket.oneToTwo,
        longestAwakeBucket: MorningRecapLongestAwakeBucket.tenTo30,
        createdAt: day(13),
      ),
    ];

    final assessment = detector.detect(
      ageMonths: 8,
      recapHistory: recaps,
      dailySignals: const [],
      now: day(15),
    );

    expect(assessment.shouldSuggestUpdate, isTrue);
    expect(assessment.softPromptOnly, isFalse);
    expect(
      assessment.reasons.any(
        (r) => r.type == RhythmShiftReasonType.roughNights,
      ),
      isTrue,
    );
  });

  test('detects pattern shift from repeated short naps and early wakes', () {
    final signals = [
      RhythmDailySignal(
        dateKey: '2026-02-15',
        shortNapCount: 1,
        skippedNapCount: 0,
        earlyWakeLogged: true,
        bedtimeResistance: false,
        bedtimeDelayMinutes: 0,
        createdAt: day(15),
      ),
      RhythmDailySignal(
        dateKey: '2026-02-14',
        shortNapCount: 2,
        skippedNapCount: 0,
        earlyWakeLogged: true,
        bedtimeResistance: false,
        bedtimeDelayMinutes: 0,
        createdAt: day(14),
      ),
      RhythmDailySignal(
        dateKey: '2026-02-13',
        shortNapCount: 1,
        skippedNapCount: 1,
        earlyWakeLogged: true,
        bedtimeResistance: false,
        bedtimeDelayMinutes: 0,
        createdAt: day(13),
      ),
    ];

    final assessment = detector.detect(
      ageMonths: 9,
      recapHistory: const [],
      dailySignals: signals,
      now: day(15),
    );

    expect(assessment.shouldSuggestUpdate, isTrue);
    expect(
      assessment.reasons.any((r) => r.type == RhythmShiftReasonType.shortNaps),
      isTrue,
    );
    expect(
      assessment.reasons.any((r) => r.type == RhythmShiftReasonType.earlyWakes),
      isTrue,
    );
  });

  test('age transition window creates soft prompt', () {
    final assessment = detector.detect(
      ageMonths: 11,
      recapHistory: const [],
      dailySignals: const [],
      now: day(15),
    );

    expect(assessment.shouldSuggestUpdate, isTrue);
    expect(assessment.softPromptOnly, isTrue);
    expect(
      assessment.reasons.any(
        (r) => r.type == RhythmShiftReasonType.ageTransition,
      ),
      isTrue,
    );
  });

  test('stable data keeps current rhythm', () {
    final recaps = [
      MorningRecapEntry(
        dateKey: '2026-02-15',
        nightQuality: MorningRecapNightQuality.good,
        wakesBucket: MorningRecapWakesBucket.zero,
        longestAwakeBucket: MorningRecapLongestAwakeBucket.under10,
        createdAt: day(15),
      ),
      MorningRecapEntry(
        dateKey: '2026-02-14',
        nightQuality: MorningRecapNightQuality.ok,
        wakesBucket: MorningRecapWakesBucket.oneToTwo,
        longestAwakeBucket: MorningRecapLongestAwakeBucket.tenTo30,
        createdAt: day(14),
      ),
    ];

    final assessment = detector.detect(
      ageMonths: 7,
      recapHistory: recaps,
      dailySignals: const [],
      now: day(15),
    );

    expect(assessment.shouldSuggestUpdate, isFalse);
    expect(assessment.reasons, isEmpty);
  });
}
