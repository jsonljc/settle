import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settle/models/user_card.dart';
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
    if (!Hive.isAdapterRegistered(50)) {
      Hive.registerAdapter(UserCardAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  test(
    'migrates rollout schema v1 data and backfills schema v4 flags',
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
      expect(notifier.state.planTabEnabled, isTrue);
      expect(notifier.state.familyTabEnabled, isTrue);
      expect(notifier.state.libraryTabEnabled, isTrue);
      expect(notifier.state.pocketEnabled, isTrue);
      expect(notifier.state.regulateEnabled, isTrue);
      expect(notifier.state.smartNudgesEnabled, isFalse);
      expect(notifier.state.patternDetectionEnabled, isFalse);
      expect(notifier.state.uiV3Enabled, isTrue);

      final migrated = Map<String, dynamic>.from(box.get('state') as Map);
      expect(migrated['schema_version'], 4);
      expect(migrated['sleep_rhythm_surfaces_enabled'], isTrue);
      expect(migrated['rhythm_shift_detector_prompts_enabled'], isTrue);
      expect(migrated['pattern_detection_enabled'], isFalse);
      expect(migrated['ui_v3_enabled'], isTrue);
    },
  );

  test('persists and restores new rollout kill-switches', () async {
    final notifier = ReleaseRolloutNotifier();
    await waitLoaded(notifier);

    await notifier.setSleepRhythmSurfacesEnabled(false);
    await notifier.setRhythmShiftDetectorPromptsEnabled(false);
    await notifier.setWindDownNotificationsEnabled(false);
    await notifier.setPatternDetectionEnabled(true);
    await notifier.setUiV3Enabled(true);

    final reloaded = ReleaseRolloutNotifier();
    await waitLoaded(reloaded);

    expect(reloaded.state.sleepRhythmSurfacesEnabled, isFalse);
    expect(reloaded.state.rhythmShiftDetectorPromptsEnabled, isFalse);
    expect(reloaded.state.windDownNotificationsEnabled, isFalse);
    expect(reloaded.state.patternDetectionEnabled, isTrue);
    expect(reloaded.state.uiV3Enabled, isTrue);
  });

  test('migrates tantrum deck cards once on load', () async {
    final rolloutBox = await Hive.openBox<dynamic>('release_rollout_v1');
    await rolloutBox.put('state', {
      'schema_version': 4,
      'help_now_enabled': true,
      'sleep_tonight_enabled': true,
      'plan_progress_enabled': true,
      'family_rules_enabled': true,
      'metrics_dashboard_enabled': true,
      'compliance_checklist_enabled': true,
      'sleep_bounded_ai_enabled': true,
      'sleep_rhythm_surfaces_enabled': true,
      'rhythm_shift_detector_prompts_enabled': true,
      'wind_down_notifications_enabled': true,
      'schedule_drift_notifications_enabled': false,
      'plan_tab_enabled': true,
      'family_tab_enabled': true,
      'library_tab_enabled': true,
      'pocket_enabled': true,
      'regulate_enabled': true,
      'smart_nudges_enabled': false,
      'pattern_detection_enabled': false,
      'ui_v3_enabled': false,
    });

    final deckBox = await Hive.openBox<dynamic>('tantrum_deck');
    await deckBox.put(
      'deck_state_v2',
      jsonEncode({
        'savedIds': ['card_a', 'card_b'],
        'favoriteIds': ['card_c'],
        'pinnedIds': ['card_b'],
      }),
    );

    final notifier = ReleaseRolloutNotifier();
    await waitLoaded(notifier);

    final userCardsBox = await Hive.openBox<UserCard>('user_cards');
    expect(userCardsBox.length, 3);
    expect(userCardsBox.get('card_a')?.pinned, isFalse);
    expect(userCardsBox.get('card_b')?.pinned, isTrue);
    expect(userCardsBox.get('card_c')?.pinned, isFalse);

    expect(rolloutBox.get('v2_tantrum_deck_migrated'), isTrue);

    final cardB = userCardsBox.get('card_b');
    await userCardsBox.put('card_b', cardB!.copyWith(usageCount: 7));

    final notifier2 = ReleaseRolloutNotifier();
    await waitLoaded(notifier2);
    expect(userCardsBox.length, 3);
    expect(userCardsBox.get('card_b')?.usageCount, 7);
  });
}
