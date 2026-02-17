import '../models/pattern_insight.dart';
import '../models/regulation_event.dart';
import '../models/usage_event.dart';
import '../models/v2_enums.dart';

/// Pure computation: analyzes usage and regulation events, produces [PatternInsight]s.
/// No Flutter deps; call from provider or service with in-memory lists.
class PatternEngine {
  PatternEngine._();

  static const List<String> _triggerOrder = [
    'transitions',
    'bedtime_battles',
    'public_meltdowns',
    'no_to_everything',
    'sibling_conflict',
    'overwhelmed',
  ];

  /// Default trigger order when no usage data; use for loading/fallback.
  static List<String> get defaultTriggerOrder => List.unmodifiable(_triggerOrder);

  static const _dayNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  /// Compute pattern insights from events. [cardIdToTriggerType] maps cardId → triggerType (e.g. from registry).
  static List<PatternInsight> compute(
    List<UsageEvent> usageEvents,
    List<RegulationEvent> regulationEvents,
    Map<String, String> cardIdToTriggerType,
  ) {
    final insights = <PatternInsight>[];

    if (usageEvents.length >= 10) {
      final timeInsight = _computeTimePattern(
        usageEvents,
        cardIdToTriggerType,
      );
      if (timeInsight != null) insights.add(timeInsight);
    }

    final strategyInsights = _computeStrategyPatterns(
      usageEvents,
      cardIdToTriggerType,
    );
    insights.addAll(strategyInsights);

    if (regulationEvents.length >= 5) {
      final regInsight = _computeRegulationPattern(regulationEvents);
      if (regInsight != null) insights.add(regInsight);
    }

    return insights;
  }

  /// Return trigger types ordered by usage frequency (most used first). Unused triggers appear at end in default order.
  static List<String> orderTriggersByUsage(
    List<UsageEvent> usageEvents,
    Map<String, String> cardIdToTriggerType,
  ) {
    final counts = <String, int>{};
    for (final t in _triggerOrder) {
      counts[t] = 0;
    }
    for (final e in usageEvents) {
      final trigger = cardIdToTriggerType[e.cardId];
      if (trigger != null && counts.containsKey(trigger)) {
        counts[trigger] = counts[trigger]! + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).toList();
  }

  static PatternInsight? _computeTimePattern(
    List<UsageEvent> usageEvents,
    Map<String, String> cardIdToTriggerType,
  ) {
    // Group by (triggerType, weekday, hourBucket 2h)
    final buckets = <_TimeBucket, int>{};
    for (final e in usageEvents) {
      final trigger = cardIdToTriggerType[e.cardId];
      if (trigger == null) continue;
      final d = e.timestamp;
      final weekday = d.weekday % 7; // 1=Mon -> 0=Mon
      final hourBucket = d.hour ~/ 2;
      final key = _TimeBucket(trigger, weekday, hourBucket);
      buckets[key] = (buckets[key] ?? 0) + 1;
    }
    if (buckets.isEmpty) return null;
    final best = buckets.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    final triggerLabel = _triggerLabel(best.key.trigger);
    final dayRange = _describeDayRange(best.key.weekday);
    final timeRange = '${best.key.hourBucket * 2}-${best.key.hourBucket * 2 + 2}';
    final total = usageEvents.length;
    final confidence = (best.value / total).clamp(0.0, 1.0);
    return PatternInsight(
      patternType: PatternType.time,
      insight: '$triggerLabel hardest $dayRange $timeRange',
      confidence: confidence,
      basedOnEvents: total,
    );
  }

  static List<PatternInsight> _computeStrategyPatterns(
    List<UsageEvent> usageEvents,
    Map<String, String> cardIdToTriggerType,
  ) {
    final byCard = <String, List<UsageEvent>>{};
    for (final e in usageEvents) {
      byCard.putIfAbsent(e.cardId, () => []).add(e);
    }
    final insights = <PatternInsight>[];
    for (final entry in byCard.entries) {
      final list = entry.value;
      if (list.length < 5) continue;
      final great = list.where((e) => e.outcome == UsageOutcome.great).length;
      final trigger = cardIdToTriggerType[entry.key] ?? entry.key;
      final label = _triggerLabel(trigger);
      final confidence = great / list.length;
      insights.add(
        PatternInsight(
          patternType: PatternType.strategy,
          insight: '"$label" works great ($great/${list.length} times)',
          confidence: confidence,
          basedOnEvents: list.length,
        ),
      );
    }
    return insights;
  }

  static PatternInsight? _computeRegulationPattern(
    List<RegulationEvent> regulationEvents,
  ) {
    // Morning 6-12, afternoon 12-17, evening 17-21, night 21-6
    final buckets = <String, (int completed, int total)>{};
    for (final label in ['Morning', 'Afternoon', 'Evening', 'Night']) {
      buckets[label] = (0, 0);
    }
    for (final e in regulationEvents) {
      final h = e.timestamp.hour;
      String label;
      if (h >= 6 && h < 12) {
        label = 'Morning';
      } else if (h >= 12 && h < 17) {
        label = 'Afternoon';
      } else if (h >= 17 && h < 21) {
        label = 'Evening';
      } else {
        label = 'Night';
      }
      final current = buckets[label]!;
      buckets[label] = (
        current.$1 + (e.completed ? 1 : 0),
        current.$2 + 1,
      );
    }
    String? bestLabel;
    double bestRate = 0;
    for (final entry in buckets.entries) {
      if (entry.value.$2 < 2) continue;
      final rate = entry.value.$1 / entry.value.$2;
      if (rate > bestRate) {
        bestRate = rate;
        bestLabel = entry.key;
      }
    }
    if (bestLabel == null) return null;
    return PatternInsight(
      patternType: PatternType.regulation,
      insight: 'You stay calmest in the $bestLabel',
      confidence: bestRate,
      basedOnEvents: regulationEvents.length,
    );
  }

  static String _triggerLabel(String trigger) {
    return trigger
        .split('_')
        .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }

  static String _describeDayRange(int weekday) {
    // Single day or range: if we have data for one weekday we show "Tue" or "Tue-Thu" for a run
    return _dayNames[weekday];
  }
}

class _TimeBucket {
  _TimeBucket(this.trigger, this.weekday, this.hourBucket);
  final String trigger;
  final int weekday;
  final int hourBucket;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TimeBucket &&
          trigger == other.trigger &&
          weekday == other.weekday &&
          hourBucket == other.hourBucket;
  @override
  int get hashCode => Object.hash(trigger, weekday, hourBucket);
}
