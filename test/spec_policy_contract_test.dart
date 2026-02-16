import 'package:flutter_test/flutter_test.dart';
import 'package:settle/services/spec_policy.dart';

void main() {
  test('spec policy constants match Settle OS v1 hard constraints', () {
    expect(SpecPolicy.nightRoutingStartHour, 19);
    expect(SpecPolicy.nightRoutingEndHourExclusive, 6);
    expect(SpecPolicy.helpNowTapBudgetFromHome, 2);
    expect(SpecPolicy.helpNowSayMaxWords, 10);
    expect(SpecPolicy.helpNowTimerMinMinutes, 2);
    expect(SpecPolicy.helpNowTimerMaxMinutes, 10);
    expect(SpecPolicy.helpNowTimeToActionSeconds, 10);
    expect(SpecPolicy.sleepTonightStartPlanSeconds, 60);
    expect(SpecPolicy.insightWindowDays, 14);
    expect(SpecPolicy.insightSimilarEventsThreshold, 3);
    expect(SpecPolicy.insightSleepNightsThreshold, 2);
  });

  test(
    'night routing window helper uses 19:00-06:00 inclusive/exclusive rule',
    () {
      expect(SpecPolicy.isNight(DateTime(2026, 2, 13, 19, 0)), isTrue);
      expect(SpecPolicy.isNight(DateTime(2026, 2, 13, 23, 59)), isTrue);
      expect(SpecPolicy.isNight(DateTime(2026, 2, 13, 5, 59)), isTrue);
      expect(SpecPolicy.isNight(DateTime(2026, 2, 13, 6, 0)), isFalse);
      expect(SpecPolicy.isNight(DateTime(2026, 2, 13, 18, 59)), isFalse);
      expect(SpecPolicy.nightWindowLabel(), '19:00–06:00');
    },
  );

  test('Now handoff helpers keep canonical mode routing contract', () {
    expect(
      SpecPolicy.nowUri(mode: SpecPolicy.nowModeIncident),
      '/now?mode=incident',
    );
    expect(SpecPolicy.nowUri(mode: SpecPolicy.nowModeSleep), '/now?mode=sleep');
    expect(
      SpecPolicy.helpNowNightRouteUri(),
      '/sleep/tonight?source=help_now_night',
    );
    expect(
      SpecPolicy.helpNowIncidentSleepRouteUri('bedtime_protest'),
      '/sleep/tonight?source=help_now&incident=bedtime_protest',
    );
    expect(SpecPolicy.nowNightUri(), '/sleep/tonight');
    expect(
      SpecPolicy.nowNightUri(source: 'home_night'),
      '/sleep/tonight?source=home_night',
    );
    expect(
      SpecPolicy.nowResetUri(
        source: 'sleep',
        returnMode: SpecPolicy.nowModeSleep,
      ),
      '/breathe?source=sleep&return_mode=sleep',
    );
  });

  test(
    'Now sleep handoff rule triggers on night, sleep incidents, or active plan',
    () {
      expect(
        SpecPolicy.shouldRouteNowToSleep(
          timestamp: DateTime(2026, 2, 13, 14),
          hasActiveSleepPlan: false,
          sleepIncident: false,
        ),
        isFalse,
      );
      expect(
        SpecPolicy.shouldRouteNowToSleep(
          timestamp: DateTime(2026, 2, 13, 21),
          hasActiveSleepPlan: false,
          sleepIncident: false,
        ),
        isTrue,
      );
      expect(
        SpecPolicy.shouldRouteNowToSleep(
          timestamp: DateTime(2026, 2, 13, 14),
          hasActiveSleepPlan: true,
          sleepIncident: false,
        ),
        isTrue,
      );
      expect(
        SpecPolicy.shouldRouteNowToSleep(
          timestamp: DateTime(2026, 2, 13, 14),
          hasActiveSleepPlan: false,
          sleepIncident: true,
        ),
        isTrue,
      );
    },
  );
}
