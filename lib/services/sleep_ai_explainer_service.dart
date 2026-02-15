import '../models/rhythm_models.dart';

class NightWakeAiExplanation {
  const NightWakeAiExplanation({
    required this.whatChanged,
    required this.why,
    required this.patternSummary,
  });

  final String whatChanged;
  final String why;
  final String patternSummary;
}

class RhythmAiSummary {
  const RhythmAiSummary({
    required this.headline,
    required this.whatChanged,
    required this.why,
    required this.patternSummary,
  });

  final String headline;
  final String whatChanged;
  final String why;
  final String patternSummary;
}

/// Bounded AI layer:
/// - Reads deterministic outputs.
/// - Returns calm explanation copy only.
/// - Never modifies planning rules, schedules, or training logic.
class SleepAiExplainerService {
  const SleepAiExplainerService._();

  static const SleepAiExplainerService instance = SleepAiExplainerService._();

  NightWakeAiExplanation explainNightWake({
    required Map<String, dynamic> plan,
    required bool comfortMode,
    required bool somethingFeelsOff,
  }) {
    final wakes = plan['wakes_logged'] as int? ?? 0;
    final earlyWakes = plan['early_wakes_logged'] as int? ?? 0;
    final currentStep = plan['current_step'] as int? ?? 0;
    final steps = (plan['steps'] as List?)?.cast<Map>() ?? const <Map>[];
    final stepCount = steps.length;
    final stepMinutes = stepCount == 0
        ? 3
        : (steps[currentStep.clamp(0, stepCount - 1)]['minutes'] as int? ?? 3);

    final whatChanged = switch ((somethingFeelsOff, comfortMode, currentStep)) {
      (true, _, _) =>
        'Changed to comfort-first because you tapped "Something feels off."',
      (false, true, _) => 'Changed to Comfort Mode based on your toggle.',
      (false, false, > 0) =>
        'Guidance advanced to step ${currentStep + 1} after a logged wake.',
      _ => 'No major change. Keep the same brief response.',
    };

    final why = switch ((somethingFeelsOff, comfortMode)) {
      (true, _) =>
        'Safety and parent instinct come first. Training expectations stay paused tonight.',
      (false, true) =>
        'Comfort Mode reduces friction during harder nights while keeping responses consistent.',
      _ =>
        'Current step timing is about $stepMinutes minutes to keep responses predictable and repeatable.',
    };

    final patternSummary = () {
      if (wakes == 0 && earlyWakes == 0) {
        return 'Pattern so far: no wakes logged yet tonight.';
      }
      if (earlyWakes == 0) {
        return 'Pattern so far: $wakes wake(s) logged tonight.';
      }
      return 'Pattern so far: $wakes wake(s), including $earlyWakes early wake(s).';
    }();

    return NightWakeAiExplanation(
      whatChanged: whatChanged,
      why: why,
      patternSummary: patternSummary,
    );
  }

  RhythmAiSummary summarizeRhythm({
    required DaySchedule schedule,
    required RhythmShiftAssessment shiftAssessment,
    required List<MorningRecapEntry> recapHistory,
    required List<RhythmDailySignal> dailySignals,
  }) {
    final recentRecaps = recapHistory.take(5).toList();
    final roughNights = recentRecaps
        .where((r) => r.nightQuality == MorningRecapNightQuality.rough)
        .length;
    final shortNapDays = dailySignals
        .take(5)
        .where((s) => (s.shortNapCount + s.skippedNapCount) > 0)
        .length;
    final bedtimeDriftDays = dailySignals
        .take(5)
        .where((s) => s.bedtimeResistance || s.bedtimeDelayMinutes >= 20)
        .length;

    final headline = shiftAssessment.shouldSuggestUpdate
        ? 'Rhythm shift detected'
        : 'Rhythm is currently stable';

    final whatChanged = schedule.appliedHysteresis
        ? 'Schedule stayed anchored instead of jittering on small deviations.'
        : 'Schedule reflects today’s wake time and logged events.';

    final why = shiftAssessment.shouldSuggestUpdate
        ? shiftAssessment.explanation
        : 'No major shift trigger is active, so the current rhythm remains in place.';

    final patternSummary =
        'Recent pattern: '
        '$roughNights rough night(s), '
        '$shortNapDays short/skip nap day(s), '
        '$bedtimeDriftDays bedtime drift day(s) in the last 5.';

    return RhythmAiSummary(
      headline: headline,
      whatChanged: whatChanged,
      why: why,
      patternSummary: patternSummary,
    );
  }
}
