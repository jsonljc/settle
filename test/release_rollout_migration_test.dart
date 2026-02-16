import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settle/providers/release_rollout_provider.dart';

void main() {
  Future<void> waitLoaded(ReleaseRolloutNotifier notifier) async {
    for (var i = 0; i < 40; i++) {
      if (!notifier.state.isLoading) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('ReleaseRolloutNotifier did not finish loading in time.');
  }

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('settle_rollout_migration');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  test(
    'migrates rollout schema v1 data and backfills new kill-switch flags',
    () async {
      final box = await Hive.openBox<dynamic>('release_rollout_v1');
      await box.put('state', {
        'schema_version': 1,
        'help_now_enabled': true,
        'sleep_tonight_enabled': true,
        'plan_progress_enabled': true,
        'family_rules_enabled': true,
        'metrics_dashboard_enabled': true,
        'compliance_checklist_enabled': true,
        'sleep_bounded_ai_enabled': true,
        'wind_down_notifications_enabled': true,
        'schedule_drift_notifications_enabled': false,
      });

      final notifier = ReleaseRolloutNotifier();
      await waitLoaded(notifier);

      expect(notifier.state.sleepRhythmSurfacesEnabled, isTrue);
      expect(notifier.state.rhythmShiftDetectorPromptsEnabled, isTrue);

      final migrated = Map<String, dynamic>.from(box.get('state') as Map);
      expect(migrated['schema_version'], 2);
      expect(migrated['sleep_rhythm_surfaces_enabled'], isTrue);
      expect(migrated['rhythm_shift_detector_prompts_enabled'], isTrue);
    },
  );

  test('persists and restores new rollout kill-switches', () async {
    final notifier = ReleaseRolloutNotifier();
    await waitLoaded(notifier);

    await notifier.setSleepRhythmSurfacesEnabled(false);
    await notifier.setRhythmShiftDetectorPromptsEnabled(false);
    await notifier.setWindDownNotificationsEnabled(false);

    final reloaded = ReleaseRolloutNotifier();
    await waitLoaded(reloaded);

    expect(reloaded.state.sleepRhythmSurfacesEnabled, isFalse);
    expect(reloaded.state.rhythmShiftDetectorPromptsEnabled, isFalse);
    expect(reloaded.state.windDownNotificationsEnabled, isFalse);
  });
}
