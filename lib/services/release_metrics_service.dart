import 'event_bus_service.dart';

class ReleaseMetricsSnapshot {
  const ReleaseMetricsSnapshot({
    required this.windowDays,
    required this.sleepAdoptionRate,
    required this.sleepActiveDays,
    required this.sleepTimeToGuidanceMedianSeconds,
    required this.sleepTimeToGuidanceSamples,
    required this.sleepRecapCompletionRate,
    required this.helpNowMedianSeconds,
    required this.helpNowMedianSamples,
    required this.sleepStartMedianSeconds,
    required this.sleepStartMedianSamples,
    required this.helpNowOutcomeRate,
    required this.helpNowSessions,
    required this.helpNowOutcomes,
    required this.sleepMorningReviewRate,
    required this.sleepPlans,
    required this.sleepMorningReviews,
    required this.repeatUseActiveDays7d,
    required this.repeatUseMet,
    required this.familyDiffAccepted7d,
  });

  final int windowDays;
  final double? sleepAdoptionRate;
  final int sleepActiveDays;
  final double? sleepTimeToGuidanceMedianSeconds;
  final int sleepTimeToGuidanceSamples;
  final double? sleepRecapCompletionRate;
  final double? helpNowMedianSeconds;
  final int helpNowMedianSamples;
  final double? sleepStartMedianSeconds;
  final int sleepStartMedianSamples;
  final double? helpNowOutcomeRate;
  final int helpNowSessions;
  final int helpNowOutcomes;
  final double? sleepMorningReviewRate;
  final int sleepPlans;
  final int sleepMorningReviews;
  final int repeatUseActiveDays7d;
  final bool repeatUseMet;
  final int familyDiffAccepted7d;
}

class ReleaseMetricsService {
  const ReleaseMetricsService();

  static const _helpNowIncidentTypes = {
    EventTypes.hnUsedTantrum,
    EventTypes.hnUsedAggression,
    EventTypes.hnUsedUnsafe,
    EventTypes.hnUsedRefusal,
    EventTypes.hnUsedPublic,
    EventTypes.hnUsedParentOverwhelm,
  };

  Future<ReleaseMetricsSnapshot> loadSnapshot({
    String? childId,
    int windowDays = 14,
  }) async {
    final recent = await EventBusService.eventsInLastDaysForChild(
      days: windowDays,
      childId: childId,
    );
    final week = await EventBusService.eventsInLastDaysForChild(
      days: 7,
      childId: childId,
    );

    final helpNowSessions = recent
        .where((e) => _helpNowIncidentTypes.contains(e['type']))
        .toList();
    final helpNowOutcomes = recent
        .where((e) => e['type'] == EventTypes.hnOutcomeRecorded)
        .toList();
    final helpNowTimes = helpNowSessions
        .map((e) => _metadataInt(e, EventMetadataKeys.timeToActionSeconds))
        .whereType<int>()
        .toList();

    final sleepPlans = recent
        .where((e) => e['type'] == EventTypes.stPlanStarted)
        .toList();
    final sleepStartTimes = sleepPlans
        .map((e) => _metadataInt(e, EventMetadataKeys.timeToStartSeconds))
        .whereType<int>()
        .toList();
    final morningReviews = recent
        .where((e) => e['type'] == EventTypes.stMorningReviewComplete)
        .toList();
    final sleepActiveDays = recent
        .where((e) => e['pillar'] == Pillars.sleepTonight)
        .map(_dayKeyFor)
        .whereType<String>()
        .toSet();

    final planIdsStarted = sleepPlans
        .map(_planKeyFor)
        .whereType<String>()
        .toSet();
    final planIdsReviewed = morningReviews
        .map(_planKeyFor)
        .whereType<String>()
        .toSet();

    final activeDays = week
        .where(
          (e) =>
              _helpNowIncidentTypes.contains(e['type']) ||
              e['type'] == EventTypes.stPlanStarted,
        )
        .map(_dayKeyFor)
        .whereType<String>()
        .toSet();

    final acceptedDiffs = week
        .where((e) => e['type'] == EventTypes.frDiffAccepted)
        .length;

    final helpNowOutcomeRate = helpNowSessions.isEmpty
        ? null
        : helpNowOutcomes.length / helpNowSessions.length;
    final sleepMorningReviewRate = planIdsStarted.isEmpty
        ? null
        : planIdsReviewed.length / planIdsStarted.length;
    final sleepAdoptionRate = sleepActiveDays.isEmpty
        ? null
        : sleepActiveDays.length / windowDays;

    return ReleaseMetricsSnapshot(
      windowDays: windowDays,
      sleepAdoptionRate: sleepAdoptionRate,
      sleepActiveDays: sleepActiveDays.length,
      sleepTimeToGuidanceMedianSeconds: _median(sleepStartTimes),
      sleepTimeToGuidanceSamples: sleepStartTimes.length,
      sleepRecapCompletionRate: sleepMorningReviewRate,
      helpNowMedianSeconds: _median(helpNowTimes),
      helpNowMedianSamples: helpNowTimes.length,
      sleepStartMedianSeconds: _median(sleepStartTimes),
      sleepStartMedianSamples: sleepStartTimes.length,
      helpNowOutcomeRate: helpNowOutcomeRate,
      helpNowSessions: helpNowSessions.length,
      helpNowOutcomes: helpNowOutcomes.length,
      sleepMorningReviewRate: sleepMorningReviewRate,
      sleepPlans: planIdsStarted.length,
      sleepMorningReviews: planIdsReviewed.length,
      repeatUseActiveDays7d: activeDays.length,
      repeatUseMet: activeDays.length >= 2,
      familyDiffAccepted7d: acceptedDiffs,
    );
  }

  static int? _metadataInt(Map<String, dynamic> event, String key) {
    final meta = event['metadata'];
    if (meta is! Map) return null;
    final raw = meta[key]?.toString();
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  static String? _planKeyFor(Map<String, dynamic> event) {
    final linkedPlan = event['linked_plan_id']?.toString();
    if (linkedPlan != null && linkedPlan.isNotEmpty) {
      return linkedPlan;
    }
    return _dayKeyFor(event);
  }

  static String? _dayKeyFor(Map<String, dynamic> event) {
    final tsRaw = event['timestamp']?.toString();
    if (tsRaw == null) return null;
    final ts = DateTime.tryParse(tsRaw);
    if (ts == null) return null;
    return '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}';
  }

  static double? _median(List<int> values) {
    if (values.isEmpty) return null;
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[mid].toDouble();
    }
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }
}
