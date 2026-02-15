import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settle/services/event_bus_service.dart';
import 'package:settle/services/release_metrics_service.dart';

void main() {
  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('settle_release_metrics');
    Hive.init(dir.path);
    await EventBusService.clearAll();
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  test('release metrics aggregates KPIs from event bus', () async {
    final now = DateTime.now();

    await EventBusService.emit(
      childId: 'child-1',
      pillar: Pillars.helpNow,
      type: EventTypes.hnUsedTantrum,
      timestamp: now.subtract(const Duration(days: 1)),
      metadata: const {
        EventMetadataKeys.incident: 'screaming_crying',
        EventMetadataKeys.ageBand: '3-5',
        EventMetadataKeys.timerMinutes: '3',
        EventMetadataKeys.timeToActionSeconds: '8',
      },
    );
    await EventBusService.emit(
      childId: 'child-1',
      pillar: Pillars.helpNow,
      type: EventTypes.hnUsedAggression,
      metadata: const {
        EventMetadataKeys.incident: 'hitting_throwing',
        EventMetadataKeys.ageBand: '3-5',
        EventMetadataKeys.timerMinutes: '3',
        EventMetadataKeys.timeToActionSeconds: '12',
      },
    );
    await EventBusService.emitHelpNowOutcomeRecorded(
      childId: 'child-1',
      incident: 'hitting_throwing',
      ageBand: '3-5',
      timerMinutes: 3,
      location: EventContextLocation.home,
      outcome: EventOutcomes.improved,
    );

    await EventBusService.emit(
      childId: 'child-1',
      pillar: Pillars.sleepTonight,
      type: EventTypes.stPlanStarted,
      linkedPlanId: 'plan-1',
      timestamp: now.subtract(const Duration(days: 1)),
      metadata: const {
        EventMetadataKeys.scenario: 'night_wakes',
        EventMetadataKeys.preference: 'standard',
        EventMetadataKeys.methodId: 'fading_chair',
        EventMetadataKeys.flowId: 'flow_a',
        EventMetadataKeys.policyVersion: 'v1',
        EventMetadataKeys.templateId: 'flow_a',
        EventMetadataKeys.timeToStartSeconds: '30',
      },
    );
    await EventBusService.emit(
      childId: 'child-1',
      pillar: Pillars.sleepTonight,
      type: EventTypes.stPlanStarted,
      linkedPlanId: 'plan-2',
      metadata: const {
        EventMetadataKeys.scenario: 'night_wakes',
        EventMetadataKeys.preference: 'standard',
        EventMetadataKeys.methodId: 'fading_chair',
        EventMetadataKeys.flowId: 'flow_a',
        EventMetadataKeys.policyVersion: 'v1',
        EventMetadataKeys.templateId: 'flow_a',
        EventMetadataKeys.timeToStartSeconds: '70',
      },
    );
    await EventBusService.emitSleepMorningReviewComplete(
      childId: 'child-1',
      linkedPlanId: 'plan-1',
      wakesLogged: 1,
    );

    await EventBusService.emitFamilyDiffAccepted(
      childId: 'child-1',
      ruleId: 'screens_default',
      diffId: 'd-1',
    );
    await EventBusService.emitFamilyDiffAccepted(
      childId: 'child-1',
      ruleId: 'snacks_default',
      diffId: 'd-2',
    );

    final snapshot = await const ReleaseMetricsService().loadSnapshot(
      childId: 'child-1',
      windowDays: 14,
    );

    expect(snapshot.sleepAdoptionRate, closeTo(2 / 14, 0.0001));
    expect(snapshot.sleepActiveDays, 2);
    expect(snapshot.sleepTimeToGuidanceMedianSeconds, 50);
    expect(snapshot.sleepTimeToGuidanceSamples, 2);
    expect(snapshot.sleepRecapCompletionRate, 0.5);
    expect(snapshot.helpNowMedianSeconds, 10);
    expect(snapshot.helpNowMedianSamples, 2);
    expect(snapshot.sleepStartMedianSeconds, 50);
    expect(snapshot.sleepStartMedianSamples, 2);
    expect(snapshot.helpNowOutcomeRate, 0.5);
    expect(snapshot.sleepMorningReviewRate, 0.5);
    expect(snapshot.repeatUseMet, isTrue);
    expect(snapshot.repeatUseActiveDays7d, greaterThanOrEqualTo(2));
    expect(snapshot.familyDiffAccepted7d, 2);
  });
}
