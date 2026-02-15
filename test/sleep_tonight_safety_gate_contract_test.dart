import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settle/providers/sleep_tonight_provider.dart';

void main() {
  setUp(() async {
    final dir = Directory.systemTemp.createTempSync(
      'settle_sleep_tonight_gate',
    );
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  test('loadTonightPlan resets transient red-flag toggles', () async {
    final box = await Hive.openBox<dynamic>('sleep_tonight_v1');
    await box.put('child-1:2026-02-13', {
      'plan_id': 'plan-1',
      'child_id': 'child-1',
      'date': '2026-02-13',
      'is_active': true,
      'safe_sleep_confirmed': true,
      'steps': const [],
    });

    final notifier = SleepTonightNotifier();
    notifier.updateSafetyGate(
      breathingDifficulty: true,
      dehydrationSigns: true,
      repeatedVomiting: true,
      severePainIndicators: true,
      feedingRefusalWithPainSigns: true,
      safeSleepConfirmed: false,
    );

    await notifier.loadTonightPlan('child-1', now: DateTime(2026, 2, 13, 21));

    final state = notifier.state;
    expect(state.breathingDifficulty, isFalse);
    expect(state.dehydrationSigns, isFalse);
    expect(state.repeatedVomiting, isFalse);
    expect(state.severePainIndicators, isFalse);
    expect(state.feedingRefusalWithPainSigns, isFalse);
    expect(state.safeSleepConfirmed, isTrue);
    expect(state.hasActivePlan, isTrue);
  });

  test('loadTonightPlan with no saved plan clears safety state', () async {
    final notifier = SleepTonightNotifier();
    notifier.updateSafetyGate(
      breathingDifficulty: true,
      dehydrationSigns: true,
      repeatedVomiting: false,
      severePainIndicators: true,
      feedingRefusalWithPainSigns: false,
      safeSleepConfirmed: true,
    );

    await notifier.loadTonightPlan('child-2', now: DateTime(2026, 2, 13, 21));

    final state = notifier.state;
    expect(state.hasActivePlan, isFalse);
    expect(state.redFlagTriggered, isFalse);
    expect(state.safeSleepConfirmed, isFalse);
  });
}
