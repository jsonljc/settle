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

      expect(snapshot.requiredTotal, 3);
      expect(snapshot.rolloutReady, isFalse);
      expect(snapshot.requiredPassCount, lessThan(snapshot.requiredTotal));
    },
  );

  test('rolloutReady turns true when required gates pass', () async {
    await EventBusService.emitHelpNowIncidentUsed(
      childId: 'child-1',
      type: EventTypes.hnUsedTantrum,
      incident: 'screaming_crying',
      ageBand: '3-5',
      timerMinutes: 3,
      timeToActionSeconds: 7,
      location: EventContextLocation.home,
    );
    await EventBusService.emitHelpNowIncidentUsed(
      childId: 'child-1',
      type: EventTypes.hnUsedAggression,
      incident: 'hitting_throwing',
      ageBand: '3-5',
      timerMinutes: 3,
      timeToActionSeconds: 9,
      location: EventContextLocation.home,
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

    final snapshot = await const ReleaseOpsService().loadSnapshot(
      childId: 'child-1',
      windowDays: 14,
    );

    expect(snapshot.requiredTotal, 3);
    expect(snapshot.requiredPassCount, 3);
    expect(snapshot.rolloutReady, isTrue);
  });
}
