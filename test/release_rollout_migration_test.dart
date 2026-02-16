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
    'migrates rollout schema v1 data and backfills schema v3 flags',
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
      expect(notifier.state.v2NavigationEnabled, isFalse);
      expect(notifier.state.v2OnboardingEnabled, isFalse);
      expect(notifier.state.planTabEnabled, isFalse);
      expect(notifier.state.familyTabEnabled, isFalse);
      expect(notifier.state.libraryTabEnabled, isFalse);
      expect(notifier.state.pocketEnabled, isFalse);
      expect(notifier.state.regulateEnabled, isFalse);
      expect(notifier.state.smartNudgesEnabled, isFalse);
      expect(notifier.state.patternDetectionEnabled, isFalse);

      final migrated = Map<String, dynamic>.from(box.get('state') as Map);
      expect(migrated['schema_version'], 3);
      expect(migrated['sleep_rhythm_surfaces_enabled'], isTrue);
      expect(migrated['rhythm_shift_detector_prompts_enabled'], isTrue);
      expect(migrated['v2_navigation_enabled'], isFalse);
      expect(migrated['pattern_detection_enabled'], isFalse);
    },
  );

  test('persists and restores new rollout kill-switches', () async {
    final notifier = ReleaseRolloutNotifier();
    await waitLoaded(notifier);

    await notifier.setSleepRhythmSurfacesEnabled(false);
    await notifier.setRhythmShiftDetectorPromptsEnabled(false);
    await notifier.setWindDownNotificationsEnabled(false);
    await notifier.setV2NavigationEnabled(true);
    await notifier.setPatternDetectionEnabled(true);

    final reloaded = ReleaseRolloutNotifier();
    await waitLoaded(reloaded);

    expect(reloaded.state.sleepRhythmSurfacesEnabled, isFalse);
    expect(reloaded.state.rhythmShiftDetectorPromptsEnabled, isFalse);
    expect(reloaded.state.windDownNotificationsEnabled, isFalse);
    expect(reloaded.state.v2NavigationEnabled, isTrue);
    expect(reloaded.state.patternDetectionEnabled, isTrue);
  });

  test('migrates tantrum deck cards once when v2 nav is enabled', () async {
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

    await notifier.setV2NavigationEnabled(true);

    final userCardsBox = await Hive.openBox<UserCard>('user_cards');
    expect(userCardsBox.length, 3);
    expect(userCardsBox.get('card_a')?.pinned, isFalse);
    expect(userCardsBox.get('card_b')?.pinned, isTrue);
    expect(userCardsBox.get('card_c')?.pinned, isFalse);

    final rolloutBox = await Hive.openBox<dynamic>('release_rollout_v1');
    expect(rolloutBox.get('v2_tantrum_deck_migrated'), isTrue);

    final cardB = userCardsBox.get('card_b');
    await userCardsBox.put('card_b', cardB!.copyWith(usageCount: 7));

    await notifier.setV2NavigationEnabled(false);
    await notifier.setV2NavigationEnabled(true);

    expect(userCardsBox.length, 3);
    expect(userCardsBox.get('card_b')?.usageCount, 7);
  });
}
