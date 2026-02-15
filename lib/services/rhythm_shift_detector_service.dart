import '../models/rhythm_models.dart';

class RhythmShiftDetectorService {
  const RhythmShiftDetectorService._();

  static const RhythmShiftDetectorService instance =
      RhythmShiftDetectorService._();

  RhythmShiftAssessment detect({
    required int ageMonths,
    required List<MorningRecapEntry> recapHistory,
    required List<RhythmDailySignal> dailySignals,
    DateTime? now,
  }) {
    final recentRecaps = _dedupRecaps(recapHistory).take(5).toList();
    final recentSignals = _dedupSignals(dailySignals).take(5).toList();
    final reasons = <RhythmShiftReason>[];

    final roughNights = recentRecaps
        .where((r) => r.nightQuality == MorningRecapNightQuality.rough)
        .length;
    if (roughNights >= 3) {
      reasons.add(
        RhythmShiftReason(
          type: RhythmShiftReasonType.roughNights,
          title: 'Rough nights pattern',
          detail: '$roughNights rough nights in the last 5',
          hardTrigger: true,
        ),
      );
    }

    final earlyWakeDays = recentSignals.where((s) => s.earlyWakeLogged).length;
    if (earlyWakeDays >= 3) {
      reasons.add(
        RhythmShiftReason(
          type: RhythmShiftReasonType.earlyWakes,
          title: 'Early wakes pattern',
          detail: '$earlyWakeDays days with early wakes in the last 5',
          hardTrigger: true,
        ),
      );
    }

    final shortNapDays = recentSignals
        .where((s) => (s.shortNapCount + s.skippedNapCount) > 0)
        .length;
    if (shortNapDays >= 3) {
      reasons.add(
        RhythmShiftReason(
          type: RhythmShiftReasonType.shortNaps,
          title: 'Short naps pattern',
          detail: '$shortNapDays days with short/skipped naps in the last 5',
          hardTrigger: true,
        ),
      );
    }

    final bedtimeDriftDays = recentSignals
        .where((s) => s.bedtimeResistance || s.bedtimeDelayMinutes >= 20)
        .length;
    if (bedtimeDriftDays >= 3) {
      reasons.add(
        RhythmShiftReason(
          type: RhythmShiftReasonType.bedtimeDrift,
          title: 'Bedtime drift pattern',
          detail:
              '$bedtimeDriftDays days with bedtime delay/resistance in the last 5',
          hardTrigger: true,
        ),
      );
    }

    final nextTransition = _nextTransitionAge(ageMonths);
    final inTransitionWindow =
        nextTransition != null && (nextTransition - ageMonths) <= 1;
    if (inTransitionWindow) {
      reasons.add(
        RhythmShiftReason(
          type: RhythmShiftReasonType.ageTransition,
          title: 'Age transition approaching',
          detail: 'Transition window approaching around $nextTransition months',
          hardTrigger: false,
        ),
      );
    }

    if (reasons.isEmpty) return RhythmShiftAssessment.none;

    final hardReasons = reasons.where((r) => r.hardTrigger).toList();
    final softOnly = hardReasons.isEmpty;
    final topDetails = (softOnly ? reasons : hardReasons)
        .take(2)
        .map((r) => r.detail)
        .join(' + ');

    return RhythmShiftAssessment(
      shouldSuggestUpdate: true,
      softPromptOnly: softOnly,
      reasons: reasons,
      explanation: 'Why update now: $topDetails.',
    );
  }

  List<MorningRecapEntry> _dedupRecaps(List<MorningRecapEntry> input) {
    final byDate = <String, MorningRecapEntry>{};
    for (final recap in input) {
      final previous = byDate[recap.dateKey];
      if (previous == null || recap.createdAt.isAfter(previous.createdAt)) {
        byDate[recap.dateKey] = recap;
      }
    }
    final values = byDate.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }

  List<RhythmDailySignal> _dedupSignals(List<RhythmDailySignal> input) {
    final byDate = <String, RhythmDailySignal>{};
    for (final signal in input) {
      final previous = byDate[signal.dateKey];
      if (previous == null || signal.createdAt.isAfter(previous.createdAt)) {
        byDate[signal.dateKey] = signal;
      }
    }
    final values = byDate.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }

  int? _nextTransitionAge(int ageMonths) {
    const transitions = [4, 6, 9, 12];
    for (final transition in transitions) {
      if (ageMonths < transition) return transition;
    }
    return null;
  }
}
