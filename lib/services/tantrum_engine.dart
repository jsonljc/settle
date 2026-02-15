import '../models/approach.dart';
import '../models/tantrum_profile.dart';

class PracticeScenario {
  const PracticeScenario({
    required this.setup,
    required this.breath,
    required this.assess,
    required this.responseCards,
    required this.repair,
    required this.debrief,
  });

  final String setup;
  final String breath;
  final String assess;
  final List<String> responseCards;
  final String repair;
  final String debrief;
}

class TantrumEngine {
  const TantrumEngine._();

  static WeeklyTantrumPattern computePattern({
    required List<TantrumEvent> events,
    required AgeBracket ageBracket,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final weekStart = _startOfDay(current.subtract(const Duration(days: 6)));
    final weekEnd = _startOfDay(current).add(const Duration(days: 1));

    final currentWeek =
        events
            .where(
              (e) =>
                  !e.timestamp.isBefore(weekStart) &&
                  e.timestamp.isBefore(weekEnd),
            )
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final prevWeekStart = weekStart.subtract(const Duration(days: 7));
    final prevWeek = events
        .where(
          (e) =>
              !e.timestamp.isBefore(prevWeekStart) &&
              e.timestamp.isBefore(weekStart),
        )
        .length;

    final triggerCounts = <TriggerType, int>{
      for (final t in TriggerType.values) t: 0,
    };
    final dayCounts = <DayBucket, int>{for (final d in DayBucket.values) d: 0};
    final intensityCounts = <TantrumIntensity, int>{
      for (final i in TantrumIntensity.values) i: 0,
    };
    final helperCounts = <String, int>{};

    for (final event in currentWeek) {
      if (event.trigger != null) {
        triggerCounts[event.trigger!] =
            (triggerCounts[event.trigger!] ?? 0) + 1;
      }
      final bucket = DayBucket.fromDateTime(event.timestamp);
      dayCounts[bucket] = (dayCounts[bucket] ?? 0) + 1;
      intensityCounts[event.intensity] =
          (intensityCounts[event.intensity] ?? 0) + 1;

      for (final helper in event.whatHelped) {
        final k = helper.trim();
        if (k.isEmpty) continue;
        helperCounts[k] = (helperCounts[k] ?? 0) + 1;
      }
    }

    final topHelpers = helperCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return WeeklyTantrumPattern(
      weekStart: weekStart,
      totalEvents: currentWeek.length,
      triggerCounts: triggerCounts,
      timeOfDayCounts: dayCounts,
      intensityDistribution: intensityCounts,
      topHelpers: topHelpers.take(3).map((e) => e.key).toList(),
      trend: _trend(currentWeek.length, prevWeek),
      normalizationStatus: getNormalization(
        events: currentWeek,
        ageBracket: ageBracket,
      ),
    );
  }

  static NormalizationStatus getNormalization({
    required List<TantrumEvent> events,
    required AgeBracket ageBracket,
  }) {
    if (!ageBracket.supportsTantrumFeatures) {
      return NormalizationStatus.withinNormal;
    }

    final perDay = events.length / 7.0;
    final hasVeryLong = events.any((e) => (e.durationSeconds ?? 0) >= 1500);
    if (hasVeryLong) return NormalizationStatus.flagged;

    final (approachThreshold, flagThreshold) = switch (ageBracket) {
      AgeBracket.nineteenToTwentyFourMonths => (3.0, 5.0),
      AgeBracket.twoToThreeYears => (3.0, 5.0),
      AgeBracket.threeToFourYears => (2.0, 3.0),
      AgeBracket.fourToFiveYears => (1.5, 2.5),
      AgeBracket.fiveToSixYears => (1.0, 2.0),
      _ => (3.0, 5.0),
    };

    if (perDay >= flagThreshold) return NormalizationStatus.flagged;
    if (perDay >= approachThreshold) {
      return NormalizationStatus.approachingConcern;
    }
    return NormalizationStatus.withinNormal;
  }

  static List<String> generateFlashcard(TantrumType tantrumType) {
    return switch (tantrumType) {
      TantrumType.explosive => const [
        'Breathe. Step back. Give space.',
        'Wait for screaming to shift to crying.',
        'Then: "You were really angry."',
      ],
      TantrumType.shutdown => const [
        'Breathe. Get close. Sit near.',
        'Quiet voice: "I\'m right here."',
        'Wait. Don\'t rush to fix.',
      ],
      TantrumType.escalating => const [
        'Breathe. Acknowledge once.',
        'Then calm silence. Do not engage spiral.',
        'When tears come: now comfort.',
      ],
      TantrumType.mixed => const [
        'Breathe. Watch for 10 seconds.',
        'Reaching = get close. Pushing = give space.',
        'When it shifts: "Big feeling."',
      ],
    };
  }

  static PracticeScenario generateScenario({
    required AgeBracket ageBracket,
    required TantrumType tantrumType,
    required List<TriggerType> triggers,
    String childName = 'your child',
  }) {
    final trigger = triggers.isNotEmpty
        ? triggers.first
        : TriggerType.transitions;
    final setup = _scenarioSetup(ageBracket, trigger, childName);

    return PracticeScenario(
      setup: setup,
      breath:
          'Before you do anything: one breath in through the nose, out through the mouth.',
      assess: 'Is $childName safe? Is anyone getting hurt right now?',
      responseCards: _responseCards(tantrumType),
      repair: ageBracket.index >= AgeBracket.threeToFourYears.index
          ? 'That was hard for both of us. I love you. What was the hard part?'
          : 'That was big. Come here. I love you even when it\'s hard.',
      debrief:
          'You will not do this perfectly. Calm enough + repair is the goal.',
    );
  }

  static String repairScriptForAge(AgeBracket ageBracket) {
    if (ageBracket.index >= AgeBracket.threeToFourYears.index) {
      return 'That was hard. I love you. What was the hardest part?';
    }
    return 'That was big. Come here.';
  }

  static String normalizationMessage(
    NormalizationStatus status,
    AgeBracket ageBracket,
  ) {
    final age = ageBracket.label;
    return switch (status) {
      NormalizationStatus.withinNormal =>
        'This pattern is within the typical range for $age.',
      NormalizationStatus.approachingConcern =>
        'This pattern is higher than usual for $age. Keep tracking, and consider a pediatric check-in if it continues.',
      NormalizationStatus.flagged =>
        'This pattern is clearly above usual for $age. Bring this log to your pediatrician so you can review it together.',
    };
  }

  static PatternTrend _trend(int current, int previous) {
    if (previous == 0 && current == 0) return PatternTrend.stable;
    if (previous == 0 && current > 0) return PatternTrend.increasing;

    final delta = (current - previous) / previous;
    if (delta >= 0.2) return PatternTrend.increasing;
    if (delta <= -0.2) return PatternTrend.decreasing;
    return PatternTrend.stable;
  }

  static DateTime _startOfDay(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  static String _scenarioSetup(
    AgeBracket age,
    TriggerType trigger,
    String childName,
  ) {
    final ageLabel = age.label;
    return switch (trigger) {
      TriggerType.transitions =>
        'It\'s late afternoon. You say it\'s time to leave. $childName ($ageLabel) drops to the floor and screams "No".',
      TriggerType.frustration =>
        '$childName is trying something hard and it does not work yet. Frustration rises quickly into big overwhelm.',
      TriggerType.sensory =>
        'You are in a loud place near dinner time. $childName looks overwhelmed and starts to unravel.',
      TriggerType.boundaries =>
        'You set a clear "no" and hold it. $childName reacts with intense protest.',
      TriggerType.unpredictable =>
        'The mood shifts fast with no obvious trigger. $childName is suddenly in a big emotional storm.',
    };
  }

  static List<String> _responseCards(TantrumType tantrumType) {
    return switch (tantrumType) {
      TantrumType.explosive => const [
        'Give space first. Remove unsafe objects. Stay nearby, not in the middle.',
        'Wait for peak intensity to pass before approaching.',
        'Then get low and say: "You were really angry."',
      ],
      TantrumType.shutdown => const [
        'Get close and stay quiet: "I\'m right here."',
        'Offer comfort only if accepted.',
        'Name gently: "You seem really sad."',
      ],
      TantrumType.escalating => const [
        'Acknowledge once: "You want X. The answer is Y."',
        'Do not keep negotiating. Silence is the tool.',
        'When anger becomes tears, connect and comfort.',
      ],
      TantrumType.mixed => const [
        'Observe 10 seconds before acting.',
        'Match their body cues: approach if seeking you, space if pushing away.',
        'When intensity drops: "You had a really big feeling."',
      ],
    };
  }
}
