class SpecPolicy {
  const SpecPolicy._();

  // Canonical Now routing.
  static const String nowPath = '/now';
  static const String nowModeParam = 'mode';
  static const String nowModeIncident = 'incident';
  static const String nowModeSleep = 'sleep';

  // Settle OS v1 hard routing window.
  static const int nightRoutingStartHour = 19;
  static const int nightRoutingEndHourExclusive = 6;

  // Help Now constraints.
  static const int helpNowTapBudgetFromHome = 2;
  static const int helpNowSayMaxWords = 10;
  static const int helpNowTimerMinMinutes = 2;
  static const int helpNowTimerMaxMinutes = 10;
  static const int helpNowTimeToActionSeconds = 10;

  // Plan card copy constraints (v3 density contract).
  static const int planPreventMaxWords = 12;
  static const int planSayMaxWords = 13;
  static const int planDoMaxWords = 12;
  static const int planEscalatesMaxWords = 11;

  // Sleep Tonight and Plan & Progress constraints.
  static const int sleepTonightStartPlanSeconds = 60;
  static const int insightWindowDays = 14;
  static const int insightSimilarEventsThreshold = 3;
  static const int insightSleepNightsThreshold = 2;
  static const int familyRulesConflictOverlapMinutes = 120;

  static bool isNight(DateTime timestamp) {
    final h = timestamp.hour;
    return h >= nightRoutingStartHour || h < nightRoutingEndHourExclusive;
  }

  static String nightWindowLabel() {
    String hh(int v) => v.toString().padLeft(2, '0');
    return '${hh(nightRoutingStartHour)}:00–${hh(nightRoutingEndHourExclusive)}:00';
  }

  static bool shouldRouteNowToSleep({
    required DateTime timestamp,
    bool hasActiveSleepPlan = false,
    bool sleepIncident = false,
    bool explicitIncidentChoice = false,
  }) {
    if (explicitIncidentChoice) return false;
    return hasActiveSleepPlan || sleepIncident || isNight(timestamp);
  }

  static String nowUri({
    required String mode,
    Map<String, String> query = const {},
  }) {
    final merged = <String, String>{...query, nowModeParam: mode};
    return Uri(path: nowPath, queryParameters: merged).toString();
  }

  static String homeHelpNowEntryUri({
    required DateTime timestamp,
    bool hasActiveSleepPlan = false,
  }) {
    final routeToSleep = shouldRouteNowToSleep(
      timestamp: timestamp,
      hasActiveSleepPlan: hasActiveSleepPlan,
    );
    if (!routeToSleep) {
      return nowUri(mode: nowModeIncident);
    }
    return nowUri(
      mode: nowModeSleep,
      query: {'source': isNight(timestamp) ? 'home_night' : 'home_active_plan'},
    );
  }

  static String helpNowNightRouteUri() {
    return '/sleep/tonight?source=help_now_night';
  }

  static String helpNowIncidentSleepRouteUri(String incidentId) {
    return '/sleep/tonight?source=help_now&incident=$incidentId';
  }

  static String sleepTonightEntryUri({String? source}) {
    if (source != null && source.isNotEmpty) {
      return '/sleep/tonight?source=$source';
    }
    return '/sleep/tonight';
  }

  static String sleepTonightScenarioUri(String scenario, {String? source}) {
    final buf = StringBuffer('/sleep/tonight?scenario=$scenario');
    if (source != null && source.isNotEmpty) {
      buf.write('&source=$source');
    }
    return buf.toString();
  }

  static String nowIncidentUri({String? source, String? incident}) {
    final query = <String, String>{};
    if (source != null && source.isNotEmpty) {
      query['source'] = source;
    }
    if (incident != null && incident.isNotEmpty) {
      query['incident'] = incident;
    }
    return nowUri(mode: nowModeIncident, query: query);
  }

  static String nowNightUri({String? source}) {
    if (source != null && source.isNotEmpty) {
      return '/sleep/tonight?source=$source';
    }
    return '/sleep/tonight';
  }

  static String nowResetUri({String? source, String? returnMode}) {
    final parts = <String>[];
    if (source != null && source.isNotEmpty) {
      parts.add('source=$source');
    }
    if (returnMode != null && returnMode.isNotEmpty) {
      parts.add('return_mode=$returnMode');
    }
    return parts.isEmpty ? '/breathe' : '/breathe?${parts.join('&')}';
  }
}
