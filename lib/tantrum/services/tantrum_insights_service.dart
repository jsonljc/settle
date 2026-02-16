import '../../models/tantrum_profile.dart';

class TantrumInsightsService {
  const TantrumInsightsService._();

  static const int unlockThreshold = 5;

  static List<String> buildInsights(
    List<TantrumEvent> events, {
    int maxLines = 3,
  }) {
    if (events.length < unlockThreshold) return const [];

    final recent = List<TantrumEvent>.from(events)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final sample = recent.take(30).toList();

    final lines = <String>[];

    final triggerLine = _buildTriggerInsight(sample);
    if (triggerLine != null) lines.add(triggerLine);

    final timeLine = _buildTimeInsight(sample);
    if (timeLine != null) lines.add(timeLine);

    final reactionLine = _buildReactionInsight(sample);
    if (reactionLine != null) lines.add(reactionLine);

    final locationLine = _buildLocationInsight(sample);
    if (locationLine != null && lines.length < maxLines) {
      lines.add(locationLine);
    }

    if (lines.isEmpty) {
      lines.add(
        'You may notice clearer patterns as you keep logging moments in the same quick way.',
      );
    }

    return lines.take(maxLines).toList();
  }

  static String? _buildTriggerInsight(List<TantrumEvent> events) {
    final counts = <String, int>{};
    for (final event in events) {
      final key = _triggerKey(event);
      if (key == null) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    if (top.value < 2) return null;

    final label = _triggerLabel(top.key).toLowerCase();
    return 'You may notice most hard moments begin during $label.';
  }

  static String? _buildTimeInsight(List<TantrumEvent> events) {
    final byBucket = <DayBucket, _IntensityStats>{
      for (final b in DayBucket.values) b: _IntensityStats(),
    };

    for (final event in events) {
      final bucket = DayBucket.fromDateTime(event.timestamp);
      byBucket[bucket]!.add(_intensityScore(event.intensity));
    }

    final ranked =
        byBucket.entries.where((entry) => entry.value.count > 0).toList()
          ..sort((a, b) => b.value.average.compareTo(a.value.average));

    if (ranked.isEmpty) return null;
    final top = ranked.first;
    if (top.value.count < 2) return null;

    return 'You may notice ${top.key.label.toLowerCase()} intensity tends to run higher.';
  }

  static String? _buildReactionInsight(List<TantrumEvent> events) {
    final calm = _IntensityStats();
    final other = _IntensityStats();

    for (final event in events) {
      final reaction = event.parentReaction?.trim();
      final score = _intensityScore(event.intensity);
      if (reaction == 'stayed_calm') {
        calm.add(score);
      } else if (reaction != null && reaction.isNotEmpty) {
        other.add(score);
      }
    }

    if (calm.count < 2) return null;

    if (other.count >= 2 && calm.average <= other.average - 0.15) {
      return 'You may notice moments where you stayed calm tended to settle at lower intensity.';
    }

    return 'You may notice staying calm creates more room for repair during hard moments.';
  }

  static String? _buildLocationInsight(List<TantrumEvent> events) {
    final counts = <String, int>{};
    for (final event in events) {
      final location = event.location?.trim();
      if (location == null || location.isEmpty) continue;
      counts[location] = (counts[location] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;

    final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    if (top.value < 2) return null;

    return 'You may notice ${_locationLabel(top.key).toLowerCase()} is where hard moments show up most often.';
  }

  static String? _triggerKey(TantrumEvent event) {
    final capture = event.captureTrigger?.trim();
    if (capture != null && capture.isNotEmpty) return capture;

    final trigger = event.trigger;
    if (trigger == null) return null;

    switch (trigger) {
      case TriggerType.transitions:
        return 'transition';
      case TriggerType.boundaries:
        return 'no_limit';
      case TriggerType.frustration:
        return 'attention_conflict';
      case TriggerType.sensory:
        return 'unknown';
      case TriggerType.unpredictable:
        return 'unknown';
    }
  }

  static String _triggerLabel(String key) {
    switch (key) {
      case 'transition':
        return 'transitions';
      case 'no_limit':
        return 'limit setting';
      case 'tired_hungry':
        return 'tired or hungry windows';
      case 'attention_conflict':
        return 'attention conflicts';
      case 'sibling_conflict':
        return 'sibling conflict';
      case 'unknown':
        return 'unclear moments';
      default:
        return key.replaceAll('_', ' ');
    }
  }

  static String _locationLabel(String key) {
    switch (key) {
      case 'home':
        return 'Home';
      case 'public':
        return 'Public settings';
      case 'car':
        return 'Car transitions';
      case 'school':
        return 'School contexts';
      case 'other':
        return 'Other settings';
      default:
        return key.replaceAll('_', ' ');
    }
  }

  static double _intensityScore(TantrumIntensity value) {
    switch (value) {
      case TantrumIntensity.mild:
        return 1;
      case TantrumIntensity.moderate:
        return 2;
      case TantrumIntensity.intense:
        return 3;
    }
  }
}

class _IntensityStats {
  int count = 0;
  double sum = 0;

  void add(double value) {
    count += 1;
    sum += value;
  }

  double get average => count == 0 ? 0 : sum / count;
}
