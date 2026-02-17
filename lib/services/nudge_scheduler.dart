import '../models/baby_profile.dart';
import '../models/pattern_insight.dart';
import '../models/v2_enums.dart';
import '../providers/nudge_settings_provider.dart'; // NudgeSettings, NudgeFrequency
import 'notification_service.dart';

class _NudgeCandidate {
  const _NudgeCandidate({
    required this.id,
    required this.title,
    required this.body,
    required this.fireAt,
  });
  final int id;
  final String title;
  final String body;
  final DateTime fireAt;
}

/// Schedules plan nudges (predictable, pattern, content) via [NotificationService].
/// Respects [NudgeSettings.frequency]: minimal ≈1/week, smart ≈2–3/week, more = all relevant.
/// Call after profile/patterns/settings are available (e.g. from Settings or app start).
class NudgeScheduler {
  NudgeScheduler._();

  /// Recompute and schedule all enabled plan nudges. Cancels existing plan nudges first.
  static Future<void> scheduleNudges({
    required BabyProfile? profile,
    required List<PatternInsight> patterns,
    required NudgeSettings settings,
  }) async {
    await NotificationService.cancelPlanNudges();

    final now = DateTime.now();
    final candidates = <_NudgeCandidate>[];

    if (settings.predictableEnabled && profile?.preferredBedtime != null) {
      final c = _predictableCandidate(profile!, settings, now);
      if (c != null) candidates.add(c);
    }

    if (settings.patternEnabled && patterns.isNotEmpty) {
      final c = _patternCandidate(patterns, settings, now);
      if (c != null) candidates.add(c);
    }

    if (settings.contentEnabled && profile != null) {
      final c = _contentCandidate(profile, settings, now);
      if (c != null) candidates.add(c);
    }

    final weekFromNow = now.add(const Duration(days: 7));
    final inWindow =
        candidates
            .where(
              (c) => c.fireAt.isAfter(now) && c.fireAt.isBefore(weekFromNow),
            )
            .toList()
          ..sort((a, b) => a.fireAt.compareTo(b.fireAt));

    final toSchedule = _applyFrequencyCap(inWindow, settings.frequency);

    for (final c in toSchedule) {
      await NotificationService.schedulePlanNudge(
        id: c.id,
        title: c.title,
        body: c.body,
        fireAt: c.fireAt,
      );
    }
  }

  /// minimal = 1 in next 7 days, smart = up to 3, more = all (up to 7).
  static List<_NudgeCandidate> _applyFrequencyCap(
    List<_NudgeCandidate> sorted,
    NudgeFrequency frequency,
  ) {
    final maxCount = switch (frequency) {
      NudgeFrequency.minimal => 1,
      NudgeFrequency.smart => 3,
      NudgeFrequency.more => 7,
    };
    return sorted.take(maxCount).toList();
  }

  static _NudgeCandidate? _predictableCandidate(
    BabyProfile profile,
    NudgeSettings settings,
    DateTime now,
  ) {
    final bedtime = _parseBedtime(profile.preferredBedtime);
    if (bedtime == null) return null;

    var fireAt = DateTime(
      now.year,
      now.month,
      now.day,
      bedtime.$1,
      bedtime.$2,
    ).subtract(const Duration(minutes: 30));
    if (!fireAt.isAfter(now)) {
      fireAt = fireAt.add(const Duration(days: 1));
    }
    if (settings.isQuietHour(fireAt.hour)) return null;

    return _NudgeCandidate(
      id: 10,
      title: 'Bedtime prep in 30 min',
      body: 'Preview a script for ${profile.name} before the rush.',
      fireAt: fireAt,
    );
  }

  static (int, int)? _parseBedtime(String? preferredBedtime) {
    if (preferredBedtime == null || preferredBedtime.isEmpty) return null;
    final parts = preferredBedtime.split(RegExp(r'[:\s]'));
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return (h, m);
  }

  static _NudgeCandidate? _patternCandidate(
    List<PatternInsight> patterns,
    NudgeSettings settings,
    DateTime now,
  ) {
    final timePatterns = patterns
        .where((p) => p.patternType == PatternType.time)
        .toList();
    if (timePatterns.isEmpty) return null;

    final insight = timePatterns.first.insight;
    final match = RegExp(r'(\d{1,2})-(\d{1,2})').firstMatch(insight);
    if (match == null) return null;
    final startHour = int.tryParse(match.group(1) ?? '') ?? 16;
    if (settings.isQuietHour(startHour - 1)) return null;

    var fireAt = DateTime(now.year, now.month, now.day, startHour - 1, 30);
    if (!fireAt.isAfter(now)) {
      fireAt = fireAt.add(const Duration(days: 1));
    }
    if (settings.isQuietHour(fireAt.hour)) return null;

    return _NudgeCandidate(
      id: 11,
      title: 'Pattern reminder',
      body: 'Based on your patterns: $insight. Preview a script?',
      fireAt: fireAt,
    );
  }

  static _NudgeCandidate? _contentCandidate(
    BabyProfile profile,
    NudgeSettings settings,
    DateTime now,
  ) {
    final ageMonths = profile.ageMonths ?? 24;
    if (ageMonths < 12) return null;

    var fireAt = DateTime(now.year, now.month, now.day, 10, 0);
    if (!fireAt.isAfter(now)) {
      fireAt = fireAt.add(const Duration(days: 1));
    }
    fireAt = fireAt.add(const Duration(days: 3));
    if (settings.isQuietHour(fireAt.hour)) return null;

    return _NudgeCandidate(
      id: 12,
      title: 'A script for this age',
      body:
          'Your ${ageMonths ~/ 12}-year-old might benefit from a quick script. Open Plan to try one.',
      fireAt: fireAt,
    );
  }
}
