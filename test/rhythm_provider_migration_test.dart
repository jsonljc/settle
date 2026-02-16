import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settle/providers/rhythm_provider.dart';

void main() {
  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('settle_rhythm_migration');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  test(
    'loads legacy rhythm daily signals without new logging fields',
    () async {
      final box = await Hive.openBox<dynamic>('rhythm_v1');
      await box.put('rhythm:child-legacy', {
        'rhythm': {
          'id': 'legacy_rhythm',
          'age_months': 7,
          'nap_count_target': 3,
          'nap_targets_by_slot_minutes': {'nap1': 80, 'nap2': 75, 'nap3': 45},
          'wake_windows_by_slot_minutes': {
            'nap1': 120,
            'nap2': 150,
            'nap3': 165,
            'bedtime': 180,
          },
          'bedtime_anchor_minutes': 1170,
          'soft_window_minutes': 20,
          'rescue_nap_enabled': true,
          'locks': {
            'bedtime_anchor_locked': true,
            'daycare_nap_blocks_locked': false,
            'hard_constraint_blocks_locked': false,
          },
          'confidence': 'medium',
          'hysteresis_minutes': 20,
          'updated_at': '2026-02-14T08:00:00.000',
        },
        'today_schedule': {
          'date_key': '2026-02-14',
          'wake_time_minutes': 420,
          'wake_time_known': true,
          'blocks': [
            {
              'id': 'wake',
              'label': 'Wake',
              'centerline_minutes': 420,
              'window_start_minutes': 420,
              'window_end_minutes': 420,
              'anchor_locked': false,
            },
            {
              'id': 'bedtime',
              'label': 'Bedtime',
              'centerline_minutes': 1170,
              'window_start_minutes': 1150,
              'window_end_minutes': 1190,
              'anchor_locked': true,
            },
          ],
          'confidence': 'medium',
          'applied_hysteresis': true,
          'generated_at': '2026-02-14T08:00:00.000',
        },
        'daily_signals': [
          {
            'date_key': '2026-02-14',
            'short_nap_count': 1,
            'skipped_nap_count': 0,
            'early_wake_logged': false,
            'bedtime_resistance': true,
            'bedtime_delay_minutes': 25,
            'created_at': '2026-02-14T21:00:00.000',
          },
        ],
        'recap_history': const [],
        'wake_time_minutes': 420,
        'wake_time_known': true,
        'precise_view': true,
      });

      final notifier = RhythmNotifier();
      await notifier.load(
        childId: 'child-legacy',
        ageMonths: 7,
        now: DateTime(2026, 2, 15, 8),
      );

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.todaySchedule, isNotNull);
      expect(notifier.state.dailySignals, isNotEmpty);
      expect(notifier.state.dailySignals.first.okNapCount, 0);
      expect(notifier.state.dailySignals.first.longNapCount, 0);
      expect(notifier.state.dailySignals.first.advancedNapStartCount, 0);
      expect(notifier.state.dailySignals.first.advancedNapEndCount, 0);
    },
  );
}
