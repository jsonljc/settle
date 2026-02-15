import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settle/services/event_bus_service.dart';

void main() {
  setUp(() async {
    final dir = Directory.systemTemp.createTempSync(
      'settle_plan_progress_evidence_gate',
    );
    Hive.init(dir.path);
    await EventBusService.clearAll();
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  test('insight gating ignores non-signal admin events', () async {
    for (var i = 0; i < 3; i++) {
      await EventBusService.emitFamilyRuleUpdated(
        childId: 'child-1',
        ruleId: 'screens_default',
        author: 'Caregiver',
      );
    }

    final eligible = await EventBusService.isInsightEligible(
      childId: 'child-1',
    );
    expect(eligible, isFalse);
  });

  test('insight gating unlocks on 3 similar behavioral events', () async {
    for (var i = 0; i < 3; i++) {
      await EventBusService.emitHelpNowIncidentUsed(
        childId: 'child-1',
        type: EventTypes.hnUsedRefusal,
        incident: 'refusal_wont',
        ageBand: '3-5',
        timerMinutes: 3,
        location: EventContextLocation.home,
      );
    }

    final eligible = await EventBusService.isInsightEligible(
      childId: 'child-1',
    );
    expect(eligible, isTrue);
  });

  test(
    'sleep-night eligibility requires actual logs, not plan starts alone',
    () async {
      await EventBusService.emitSleepPlanStarted(
        childId: 'child-1',
        linkedPlanId: 'plan-night-1',
        scenario: 'night_wakes',
        preference: 'standard',
        methodId: 'fading_chair',
        flowId: 'flow-a',
        policyVersion: 'v1',
      );
      await EventBusService.emitSleepPlanStarted(
        childId: 'child-1',
        linkedPlanId: 'plan-night-2',
        scenario: 'night_wakes',
        preference: 'standard',
        methodId: 'fading_chair',
        flowId: 'flow-a',
        policyVersion: 'v1',
      );

      final eligible = await EventBusService.isInsightEligible(
        childId: 'child-1',
      );
      expect(eligible, isFalse);
    },
  );

  test('sleep-night eligibility unlocks with logs across two nights', () async {
    await EventBusService.emitSleepNightWakeLogged(
      childId: 'child-1',
      linkedPlanId: 'plan-night-1',
      wakeCount: 1,
    );
    await EventBusService.emitSleepNightWakeLogged(
      childId: 'child-1',
      linkedPlanId: 'plan-night-2',
      wakeCount: 1,
    );

    final eligible = await EventBusService.isInsightEligible(
      childId: 'child-1',
    );
    expect(eligible, isTrue);
  });
}
