import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settle/models/rhythm_models.dart';
import 'package:settle/providers/rhythm_provider.dart';

void main() {
  int rank(RhythmConfidence confidence) {
    return switch (confidence) {
      RhythmConfidence.low => 0,
      RhythmConfidence.medium => 1,
      RhythmConfidence.high => 2,
    };
  }

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('settle_phase4_logging');
    Hive.init(dir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  test('missing logs lowers confidence but never blocks planning', () async {
    final notifier = RhythmNotifier();
    await notifier.load(
      childId: 'phase4-missing',
      ageMonths: 8,
      now: DateTime(2026, 2, 15, 8),
    );

    expect(notifier.state.todaySchedule, isNotNull);
    final initialConfidence = notifier.state.todaySchedule!.confidence;
    expect(
      initialConfidence == RhythmConfidence.medium ||
          initialConfidence == RhythmConfidence.low,
      isTrue,
    );

    await notifier.recalculate(childId: 'phase4-missing');
    expect(notifier.state.todaySchedule, isNotNull);
  });

  test(
    'optional day taps + recap improve confidence from completeness',
    () async {
      final notifier = RhythmNotifier();
      await notifier.load(
        childId: 'phase4-complete',
        ageMonths: 9,
        now: DateTime(2026, 2, 15, 8),
      );
      final baseline = notifier.state.todaySchedule!.confidence;

      await notifier.setWakeTime(
        childId: 'phase4-complete',
        wakeTimeMinutes: 7 * 60,
        known: true,
      );
      await notifier.submitMorningRecap(
        childId: 'phase4-complete',
        nightQuality: MorningRecapNightQuality.good,
        wakesBucket: MorningRecapWakesBucket.zero,
        longestAwakeBucket: MorningRecapLongestAwakeBucket.under10,
        now: DateTime(2026, 2, 15, 9),
      );
      await notifier.markNapQualityTap(
        childId: 'phase4-complete',
        quality: NapQualityTap.ok,
      );
      await notifier.setAdvancedDayLogging(
        childId: 'phase4-complete',
        enabled: true,
      );
      await notifier.markNapStarted(childId: 'phase4-complete');
      await notifier.markNapEnded(childId: 'phase4-complete');
      await notifier.recalculate(childId: 'phase4-complete');

      final signal = notifier.state.dailySignals.first;
      expect(signal.okNapCount, greaterThanOrEqualTo(1));
      expect(signal.advancedNapStartCount, greaterThanOrEqualTo(1));
      expect(signal.advancedNapEndCount, greaterThanOrEqualTo(1));
      expect(
        rank(notifier.state.todaySchedule!.confidence),
        greaterThanOrEqualTo(rank(baseline)),
      );
    },
  );
}
