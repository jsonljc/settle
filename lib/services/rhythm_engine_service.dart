import 'dart:math';

import '../models/rhythm_models.dart';

class RhythmEngineService {
  const RhythmEngineService._();

  static const RhythmEngineService instance = RhythmEngineService._();

  Rhythm defaultRhythmForAge({
    required int ageMonths,
    bool daycareMode = false,
    DateTime? now,
  }) {
    final boundedAge = ageMonths.clamp(0, 60);
    final napCount = _napTargetForAge(boundedAge);
    final bedtimeAnchor = _defaultBedtimeAnchor(boundedAge);
    final napDurationProfile = _napDurationProfileForCount(napCount);

    final wakeWindows = <String, int>{};
    final napTargets = <String, int>{};
    var current = _baseWakeWindowForAge(boundedAge);
    for (var i = 1; i <= napCount; i++) {
      wakeWindows['nap$i'] = current;
      napTargets['nap$i'] =
          napDurationProfile[(i - 1).clamp(0, napDurationProfile.length - 1)];
      current += 15;
    }
    wakeWindows['bedtime'] = current;

    return Rhythm(
      id: 'rhythm_${boundedAge}m_$napCount',
      ageMonths: boundedAge,
      napCountTarget: napCount,
      napTargetsBySlotMinutes: napTargets,
      wakeWindowsBySlotMinutes: wakeWindows,
      bedtimeAnchorMinutes: bedtimeAnchor,
      softWindowMinutes: daycareMode ? 25 : 20,
      rescueNapEnabled: napCount >= 2,
      locks: RhythmLocks(
        bedtimeAnchorLocked: true,
        daycareNapBlocksLocked: daycareMode,
        hardConstraintBlocksLocked: false,
      ),
      confidence: RhythmConfidence.medium,
      hysteresisMinutes: 20,
      updatedAt: now ?? DateTime.now(),
    );
  }

  RhythmUpdatePlan buildUpdatedRhythm({
    required Rhythm currentRhythm,
    required int ageMonths,
    required int wakeRangeStartMinutes,
    required int wakeRangeEndMinutes,
    required bool daycareMode,
    required int? napCountReality,
    required RhythmUpdateIssue issue,
    required String whyNow,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final boundedAge = ageMonths.clamp(0, 60);
    final base = defaultRhythmForAge(
      ageMonths: boundedAge,
      daycareMode: daycareMode,
      now: timestamp,
    );
    final napCount = (napCountReality ?? base.napCountTarget).clamp(1, 4);
    final napTargets = <String, int>{};
    final wakeWindows = <String, int>{};
    final napProfile = _napDurationProfileForCount(napCount);

    var wakeCursor = _baseWakeWindowForAge(boundedAge);
    for (var i = 1; i <= napCount; i++) {
      wakeWindows['nap$i'] = wakeCursor;
      napTargets['nap$i'] = napProfile[(i - 1).clamp(0, napProfile.length - 1)];
      wakeCursor += 15;
    }
    wakeWindows['bedtime'] = wakeCursor;

    var bedtimeAnchor = base.bedtimeAnchorMinutes;
    var softWindow = daycareMode ? 25 : 20;
    var confidenceScore = 70;
    final summary = <String>[];

    switch (issue) {
      case RhythmUpdateIssue.earlyWakes:
        bedtimeAnchor = _normalizeMinutes(bedtimeAnchor - 15);
        for (var i = 1; i <= napCount; i++) {
          final key = 'nap$i';
          wakeWindows[key] = max(75, (wakeWindows[key] ?? 120) - 10);
        }
        summary.add('Moved bedtime anchor 15 minutes earlier.');
        summary.add('Shortened daytime wake windows slightly.');
        confidenceScore += 6;
      case RhythmUpdateIssue.nightWakes:
        bedtimeAnchor = _normalizeMinutes(bedtimeAnchor - 10);
        wakeWindows['bedtime'] = max(130, (wakeWindows['bedtime'] ?? 180) - 10);
        softWindow += 5;
        summary.add('Protected bedtime with an earlier anchor.');
        summary.add('Added a slightly wider soft window overnight.');
        confidenceScore += 4;
      case RhythmUpdateIssue.shortNaps:
        for (var i = 1; i <= napCount; i++) {
          final key = 'nap$i';
          wakeWindows[key] = max(75, (wakeWindows[key] ?? 120) - 15);
        }
        wakeWindows['bedtime'] = max(135, (wakeWindows['bedtime'] ?? 180) - 10);
        softWindow += 5;
        summary.add('Pulled nap timing earlier to protect nap pressure.');
        summary.add('Adjusted bedtime protection to avoid overtired spirals.');
        confidenceScore += 2;
      case RhythmUpdateIssue.bedtimeBattles:
        bedtimeAnchor = _normalizeMinutes(bedtimeAnchor + 15);
        wakeWindows['bedtime'] = min(300, (wakeWindows['bedtime'] ?? 180) + 15);
        summary.add('Shifted bedtime anchor 15 minutes later.');
        summary.add('Extended pre-bed wake target to reduce bedtime protest.');
        confidenceScore += 3;
    }

    final wakeRangeWidth = _circularMinuteDiff(
      wakeRangeStartMinutes,
      wakeRangeEndMinutes,
    );
    if (wakeRangeWidth <= 30) {
      confidenceScore += 10;
    } else if (wakeRangeWidth > 90) {
      confidenceScore -= 12;
    }
    if (napCountReality == null) confidenceScore -= 8;
    if (daycareMode) confidenceScore -= 4;

    final confidence = switch (confidenceScore) {
      >= 80 => RhythmConfidence.high,
      >= 60 => RhythmConfidence.medium,
      _ => RhythmConfidence.low,
    };

    final nextRhythm = Rhythm(
      id: 'rhythm_${boundedAge}m_${napCount}_${issue.wire}',
      ageMonths: boundedAge,
      napCountTarget: napCount,
      napTargetsBySlotMinutes: napTargets,
      wakeWindowsBySlotMinutes: wakeWindows,
      bedtimeAnchorMinutes: bedtimeAnchor,
      softWindowMinutes: softWindow,
      rescueNapEnabled: napCount >= 2 || issue == RhythmUpdateIssue.shortNaps,
      locks: base.locks.copyWith(
        bedtimeAnchorLocked: true,
        daycareNapBlocksLocked: daycareMode,
      ),
      confidence: confidence,
      hysteresisMinutes: currentRhythm.hysteresisMinutes,
      updatedAt: timestamp,
    );

    final wakeCenter = _normalizeMinutes(
      wakeRangeStartMinutes +
          (_circularMinuteDiff(wakeRangeStartMinutes, wakeRangeEndMinutes) ~/
              2),
    );
    summary.add('Wake range centered around ${_formatClock(wakeCenter)}.');

    return RhythmUpdatePlan(
      rhythm: nextRhythm,
      anchorRecommendation:
          'Recommended anchor: ${_formatClock(bedtimeAnchor)} (lock for 7-14 days).',
      confidence: confidence,
      changeSummary: summary.take(3).toList(),
      whyNow: whyNow,
    );
  }

  DaySchedule buildDaySchedule({
    required Rhythm rhythm,
    required int wakeTimeMinutes,
    required bool wakeTimeKnown,
    required List<RhythmDayEvent> events,
    DaySchedule? previousSchedule,
    DateTime? now,
  }) {
    final normalizedWake = _normalizeMinutes(wakeTimeMinutes);
    final today = now ?? DateTime.now();
    final dayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final previousById = <String, RhythmScheduleBlock>{};
    for (final block
        in previousSchedule?.blocks ?? const <RhythmScheduleBlock>[]) {
      previousById[block.id] = block;
    }

    final blocks = <RhythmScheduleBlock>[
      RhythmScheduleBlock(
        id: 'wake',
        label: 'Wake',
        centerlineMinutes: normalizedWake,
        windowStartMinutes: normalizedWake,
        windowEndMinutes: normalizedWake,
        anchorLocked: false,
      ),
    ];

    var wakeCursor = normalizedWake;
    var appliedHysteresis = false;

    for (var napIndex = 1; napIndex <= rhythm.napCountTarget; napIndex++) {
      final slotId = 'nap$napIndex';
      final ww =
          rhythm.wakeWindowsBySlotMinutes[slotId] ??
          rhythm.wakeWindowsBySlotMinutes['nap1'] ??
          120;
      final rawCenter = _normalizeMinutes(wakeCursor + ww);
      final previousCenter = previousById[slotId]?.centerlineMinutes;
      final center = _applyHysteresis(
        raw: rawCenter,
        previous: previousCenter,
        thresholdMinutes: rhythm.hysteresisMinutes,
      );
      if (previousCenter != null &&
          center == previousCenter &&
          center != rawCenter) {
        appliedHysteresis = true;
      }

      final durationTarget =
          rhythm.napTargetsBySlotMinutes[slotId] ??
          _durationTargetForNap(
            napCount: rhythm.napCountTarget,
            napIndex: napIndex,
          );
      final shortNap = events.any(
        (e) => e.type == RhythmDayEventType.shortNap && e.napIndex == napIndex,
      );
      final skippedNap = events.any(
        (e) =>
            e.type == RhythmDayEventType.skippedNap && e.napIndex == napIndex,
      );

      final effectiveTarget = skippedNap
          ? 0
          : (shortNap ? max(30, durationTarget ~/ 2) : durationTarget);
      final durationMin = skippedNap ? 0 : max(20, effectiveTarget - 15);
      final durationMax = skippedNap ? 0 : effectiveTarget + 15;
      final margin = _windowMarginFor(
        baseSoftMinutes: rhythm.softWindowMinutes,
        confidence: rhythm.confidence,
      );

      blocks.add(
        RhythmScheduleBlock(
          id: slotId,
          label: 'Nap $napIndex',
          centerlineMinutes: center,
          windowStartMinutes: _normalizeMinutes(center - margin),
          windowEndMinutes: _normalizeMinutes(center + margin),
          expectedDurationMinMinutes: durationMin,
          expectedDurationMaxMinutes: durationMax,
          anchorLocked: rhythm.locks.daycareNapBlocksLocked,
        ),
      );

      wakeCursor = _normalizeMinutes(center + effectiveTarget);
    }

    final bedtimeWw =
        rhythm.wakeWindowsBySlotMinutes['bedtime'] ??
        _baseWakeWindowForAge(rhythm.ageMonths);
    var rawBedtime = _normalizeMinutes(wakeCursor + bedtimeWw);
    if (rhythm.locks.bedtimeAnchorLocked) {
      rawBedtime = _normalizeMinutes(rhythm.bedtimeAnchorMinutes);
    }

    final previousBedtime = previousById['bedtime']?.centerlineMinutes;
    final bedtimeCenter = _applyHysteresis(
      raw: rawBedtime,
      previous: previousBedtime,
      thresholdMinutes: rhythm.hysteresisMinutes,
    );
    if (previousBedtime != null &&
        bedtimeCenter == previousBedtime &&
        bedtimeCenter != rawBedtime) {
      appliedHysteresis = true;
    }

    final bedtimeMargin = _windowMarginFor(
      baseSoftMinutes: rhythm.softWindowMinutes,
      confidence: rhythm.confidence,
    );
    blocks.add(
      RhythmScheduleBlock(
        id: 'bedtime',
        label: 'Bedtime',
        centerlineMinutes: bedtimeCenter,
        windowStartMinutes: _normalizeMinutes(bedtimeCenter - bedtimeMargin),
        windowEndMinutes: _normalizeMinutes(bedtimeCenter + bedtimeMargin),
        anchorLocked: rhythm.locks.bedtimeAnchorLocked,
      ),
    );

    final confidence = _scoreConfidence(
      wakeTimeKnown: wakeTimeKnown,
      eventCount: events.length,
      appliedHysteresis: appliedHysteresis,
      napCount: rhythm.napCountTarget,
    );

    return DaySchedule(
      dateKey: dayKey,
      wakeTimeMinutes: normalizedWake,
      wakeTimeKnown: wakeTimeKnown,
      blocks: blocks,
      confidence: confidence,
      appliedHysteresis: appliedHysteresis,
      generatedAt: today,
    );
  }

  int _napTargetForAge(int ageMonths) {
    if (ageMonths < 4) return 4;
    if (ageMonths < 9) return 3;
    if (ageMonths <= 12) return 2;
    return 1;
  }

  int _baseWakeWindowForAge(int ageMonths) {
    if (ageMonths < 4) return 90;
    if (ageMonths < 6) return 120;
    if (ageMonths < 9) return 150;
    if (ageMonths <= 12) return 180;
    return 240;
  }

  int _defaultBedtimeAnchor(int ageMonths) {
    if (ageMonths <= 6) return 19 * 60;
    if (ageMonths <= 12) return (19 * 60) + 30;
    return 20 * 60;
  }

  int _durationTargetForNap({required int napCount, required int napIndex}) {
    final profile = _napDurationProfileForCount(napCount);
    final i = (napIndex - 1).clamp(0, profile.length - 1);
    return profile[i];
  }

  List<int> _napDurationProfileForCount(int napCount) {
    return switch (napCount) {
      4 => const [55, 55, 45, 35],
      3 => const [80, 75, 45],
      2 => const [90, 75],
      _ => const [120],
    };
  }

  int _windowMarginFor({
    required int baseSoftMinutes,
    required RhythmConfidence confidence,
  }) {
    return switch (confidence) {
      RhythmConfidence.high => baseSoftMinutes,
      RhythmConfidence.medium => baseSoftMinutes + 5,
      RhythmConfidence.low => baseSoftMinutes + 10,
    };
  }

  int _applyHysteresis({
    required int raw,
    required int? previous,
    required int thresholdMinutes,
  }) {
    if (previous == null) return raw;
    final diff = _circularMinuteDiff(raw, previous).abs();
    if (diff <= thresholdMinutes) return previous;
    return raw;
  }

  RhythmConfidence _scoreConfidence({
    required bool wakeTimeKnown,
    required int eventCount,
    required bool appliedHysteresis,
    required int napCount,
  }) {
    var score = 100;
    if (!wakeTimeKnown) score -= 25;
    score -= min(4, eventCount) * 12;
    if (appliedHysteresis) score += 5;
    if (napCount >= 4) score -= 8;

    if (score >= 78) return RhythmConfidence.high;
    if (score >= 55) return RhythmConfidence.medium;
    return RhythmConfidence.low;
  }

  int _normalizeMinutes(int minutes) {
    return ((minutes % 1440) + 1440) % 1440;
  }

  String _formatClock(int minutes) {
    final normalized = _normalizeMinutes(minutes);
    final h = normalized ~/ 60;
    final m = normalized % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  int _circularMinuteDiff(int a, int b) {
    final diff = (a - b).abs();
    return min(diff, 1440 - diff);
  }
}
