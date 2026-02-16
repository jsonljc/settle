import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settle/services/event_bus_service.dart';
import 'package:settle/services/release_ops_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('settle_release_ops');
    Hive.init(dir.path);
    await EventBusService.clearAll();
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  test(
    'rolloutReady is false when required latency gates have no signal',
    () async {
      final snapshot = await const ReleaseOpsService().loadSnapshot(
        childId: 'child-1',
        windowDays: 14,
      );

      expect(snapshot.requiredTotal, 5);
      expect(snapshot.rolloutReady, isFalse);
      expect(snapshot.requiredPassCount, lessThan(snapshot.requiredTotal));
    },
  );

  test('rolloutReady turns true when required gates pass', () async {
    final now = DateTime.now();
    await EventBusService.emitHelpNowIncidentUsed(
      childId: 'child-1',
      type: EventTypes.hnUsedTantrum,
      incident: 'screaming_crying',
      ageBand: '3-5',
      timerMinutes: 3,
      timeToActionSeconds: 7,
      location: EventContextLocation.home,
      tags: const [],
    );
    await EventBusService.emitHelpNowIncidentUsed(
      childId: 'child-1',
      type: EventTypes.hnUsedAggression,
      incident: 'hitting_throwing',
      ageBand: '3-5',
      timerMinutes: 3,
      timeToActionSeconds: 9,
      location: EventContextLocation.home,
      tags: const [],
    );
    await EventBusService.emit(
      childId: 'child-1',
      pillar: Pillars.helpNow,
      type: EventTypes.hnUsedAggression,
      timestamp: now.subtract(const Duration(days: 1)),
      metadata: const {
        EventMetadataKeys.incident: 'hitting_throwing',
        EventMetadataKeys.ageBand: '3-5',
        EventMetadataKeys.timerMinutes: '3',
        EventMetadataKeys.timeToActionSeconds: '8',
      },
    );

    await EventBusService.emitSleepPlanStarted(
      childId: 'child-1',
      linkedPlanId: 'plan-1',
      scenario: 'night_wakes',
      preference: 'standard',
      methodId: 'fading_chair',
      flowId: 'flow-a',
      policyVersion: 'v1',
      timeToStartSeconds: 40,
    );
    await EventBusService.emitSleepPlanStarted(
      childId: 'child-1',
      linkedPlanId: 'plan-2',
      scenario: 'night_wakes',
      preference: 'standard',
      methodId: 'fading_chair',
      flowId: 'flow-a',
      policyVersion: 'v1',
      timeToStartSeconds: 45,
    );
    await EventBusService.emit(
      childId: 'child-1',
      pillar: Pillars.sleepTonight,
      type: EventTypes.stPlanStarted,
      linkedPlanId: 'plan-3',
      timestamp: now.subtract(const Duration(days: 1)),
      metadata: const {
        EventMetadataKeys.scenario: 'night_wakes',
        EventMetadataKeys.preference: 'standard',
        EventMetadataKeys.methodId: 'fading_chair',
        EventMetadataKeys.flowId: 'flow-a',
        EventMetadataKeys.policyVersion: 'v1',
        EventMetadataKeys.templateId: 'flow-a',
        EventMetadataKeys.timeToStartSeconds: '50',
      },
    );
    await EventBusService.emitSleepMorningReviewComplete(
      childId: 'child-1',
      linkedPlanId: 'plan-1',
      wakesLogged: 1,
    );
    await EventBusService.emitSleepMorningReviewComplete(
      childId: 'child-1',
      linkedPlanId: 'plan-3',
      wakesLogged: 2,
    );
    await EventBusService.emitPlanAppSessionStarted(
      childId: 'app_global',
      appVersion: 'test',
    );
    await EventBusService.emitPlanAppSessionStarted(
      childId: 'app_global',
      appVersion: 'test',
    );

    final snapshot = await const ReleaseOpsService().loadSnapshot(
      childId: 'child-1',
      windowDays: 14,
    );

    expect(snapshot.requiredTotal, 5);
    expect(snapshot.requiredPassCount, 5);
    expect(snapshot.rolloutReady, isTrue);
  });
}
