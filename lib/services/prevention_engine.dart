import '../models/approach.dart';
import '../models/tantrum_profile.dart';

class PreventionEngine {
  const PreventionEngine._();

  static List<String> dailyStrategies({
    required AgeBracket ageBracket,
    required TantrumProfile profile,
    required WeeklyTantrumPattern pattern,
    required DateTime now,
  }) {
    final strategies = <String>{};

    final topTrigger = _topTrigger(pattern.triggerCounts);
    final topBucket = _topBucket(pattern.timeOfDayCounts);

    if (topTrigger != null) {
      strategies.add(_triggerStrategy(topTrigger, ageBracket));
    }

    if (topBucket != null) {
      strategies.add(_timingStrategy(topBucket));
    }

    strategies.add(_priorityStrategy(profile.responsePriority));

    if (profile.commonTriggers.contains(TriggerType.transitions)) {
      strategies.add(
        'Preview transitions: "5 minutes, then 2 minutes, then go."',
      );
    }

    if (profile.commonTriggers.contains(TriggerType.boundaries)) {
      strategies.add('Use constrained choices: "Red cup or blue cup?"');
    }

    if (now.hour >= 15) {
      strategies.add(
        'Late-day buffer: snack + quiet activity before transitions.',
      );
    }

    return strategies.take(3).toList();
  }

  static TriggerType? _topTrigger(Map<TriggerType, int> counts) {
    TriggerType? top;
    var max = 0;
    for (final entry in counts.entries) {
      if (entry.value > max) {
        max = entry.value;
        top = entry.key;
      }
    }
    return top;
  }

  static DayBucket? _topBucket(Map<DayBucket, int> counts) {
    DayBucket? top;
    var max = 0;
    for (final entry in counts.entries) {
      if (entry.value > max) {
        max = entry.value;
        top = entry.key;
      }
    }
    return top;
  }

  static String _triggerStrategy(TriggerType trigger, AgeBracket age) {
    return switch (trigger) {
      TriggerType.transitions =>
        'Transitions are a hotspot. Give countdown cues and one simple next step.',
      TriggerType.frustration =>
        age.index >= AgeBracket.threeToFourYears.index
            ? 'When frustration spikes, coach with: "Try once more, then I help."'
            : 'When frustration spikes, shift to co-play before the point of overwhelm.',
      TriggerType.sensory =>
        'Protect from overload: reduce noise, lower light, and offer a regulation break.',
      TriggerType.boundaries =>
        'Hold boundaries with one sentence and calm body language. Avoid repeated debates.',
      TriggerType.unpredictable =>
        'Patterns are mixed. Keep routines stable and track details for two more weeks.',
    };
  }

  static String _timingStrategy(DayBucket bucket) {
    return switch (bucket) {
      DayBucket.morning =>
        'Morning pattern: start with connection before demands (play or cuddle first).',
      DayBucket.midday =>
        'Midday pattern: pre-empt with snack + hydration before difficult transitions.',
      DayBucket.afternoon =>
        'Afternoon pattern: lower demands and keep instructions short and concrete.',
      DayBucket.evening =>
        'Evening pattern: protect bedtime rhythm and simplify choices after dinner.',
    };
  }

  static String _priorityStrategy(ResponsePriority priority) {
    return switch (priority) {
      ResponsePriority.coRegulation =>
        'Anchor phrase: "I can stay calm and close, even when it is loud."',
      ResponsePriority.structure =>
        'Boundary script: "You can be mad. I will keep us safe."',
      ResponsePriority.insight =>
        'After calm: ask "What was the hardest part?" and capture one note.',
      ResponsePriority.scripts =>
        'Keep one script ready: "Big feeling. I am here. We will get through it."',
    };
  }
}
