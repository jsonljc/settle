import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settle/services/event_bus_service.dart';

void main() {
  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('settle_success_metrics');
    Hive.init(dir.path);
    await EventBusService.clearAll();
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  test('help now incident writes time-to-action metadata', () async {
    await EventBusService.emitHelpNowIncidentUsed(
      childId: 'child-1',
      type: EventTypes.hnUsedTantrum,
      incident: 'screaming_crying',
      ageBand: '3-5',
      timerMinutes: 3,
      timeToActionSeconds: 7,
      location: EventContextLocation.home,
    );

    final events = await EventBusService.allEvents();
    expect(events, hasLength(1));
    final metadata = Map<String, dynamic>.from(
      events.single['metadata'] as Map,
    );
    expect(metadata[EventMetadataKeys.timeToActionSeconds], '7');
  });

  test('sleep plan started writes time-to-start metadata', () async {
    await EventBusService.emitSleepPlanStarted(
      childId: 'child-1',
      linkedPlanId: 'plan-1',
      scenario: 'night_wakes',
      preference: 'standard',
      methodId: 'fading_chair',
      flowId: 'flow-a',
      policyVersion: 'v1',
      timeToStartSeconds: 42,
    );

    final events = await EventBusService.allEvents();
    expect(events, hasLength(1));
    final metadata = Map<String, dynamic>.from(
      events.single['metadata'] as Map,
    );
    expect(metadata[EventMetadataKeys.timeToStartSeconds], '42');
  });
}
