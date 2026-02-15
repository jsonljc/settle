import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settle/providers/family_rules_provider.dart';
import 'package:settle/services/event_bus_service.dart';

Future<void> _waitForLoaded(FamilyRulesNotifier notifier) async {
  for (var i = 0; i < 80; i++) {
    if (!notifier.state.isLoading) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('FamilyRulesNotifier did not finish loading.');
}

Map<String, String> _rules() {
  return const {
    'boundary_public': 'Old boundary',
    'screens_default': 'Old screens',
    'snacks_default': 'Old snacks',
    'bedtime_routine': 'Old bedtime',
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('settle_rules_conflict');
    Hive.init(dir.path);
    await EventBusService.clearAll();
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  test(
    'resolveConflict ignores same-rule diffs outside overlap window',
    () async {
      final box = await Hive.openBox<dynamic>('family_rules_v1');
      await box.put('state', {
        'schema_version': 1,
        'ruleset_version': 4,
        'rules': _rules(),
        'pending_diffs': [
          {
            'schema_version': 1,
            'diff_id': 'd-late',
            'changed_rule_id': 'screens_default',
            'old_value': 'Old screens',
            'new_value': 'Late update',
            'author': 'Caregiver A',
            'timestamp': '2026-02-10T15:30:00.000',
            'ruleset_version': 4,
            'status': 'pending',
          },
          {
            'schema_version': 1,
            'diff_id': 'd-early',
            'changed_rule_id': 'screens_default',
            'old_value': 'Old screens',
            'new_value': 'Early update',
            'author': 'Caregiver B',
            'timestamp': '2026-02-10T10:00:00.000',
            'ruleset_version': 3,
            'status': 'pending',
          },
        ],
        'change_feed': const [],
      });

      final notifier = FamilyRulesNotifier();
      await _waitForLoaded(notifier);

      await notifier.resolveConflict(
        childId: 'child-1',
        ruleId: 'screens_default',
        chosenDiffId: 'd-late',
        resolver: 'Primary caregiver',
      );

      expect(notifier.state.pendingDiffs, hasLength(2));
      final events = await EventBusService.allEvents();
      expect(
        events.where((e) => e['type'] == EventTypes.frConflictResolved),
        isEmpty,
      );
    },
  );

  test(
    'resolveConflict clears only overlap-cluster diffs for that rule',
    () async {
      final box = await Hive.openBox<dynamic>('family_rules_v1');
      await box.put('state', {
        'schema_version': 1,
        'ruleset_version': 5,
        'rules': _rules(),
        'pending_diffs': [
          {
            'schema_version': 1,
            'diff_id': 'd-outside',
            'changed_rule_id': 'screens_default',
            'old_value': 'Old screens',
            'new_value': 'Outside window update',
            'author': 'Caregiver A',
            'timestamp': '2026-02-10T06:00:00.000',
            'ruleset_version': 2,
            'status': 'pending',
          },
          {
            'schema_version': 1,
            'diff_id': 'd-a',
            'changed_rule_id': 'screens_default',
            'old_value': 'Old screens',
            'new_value': 'Conflict option A',
            'author': 'Caregiver B',
            'timestamp': '2026-02-10T10:00:00.000',
            'ruleset_version': 4,
            'status': 'pending',
          },
          {
            'schema_version': 1,
            'diff_id': 'd-b',
            'changed_rule_id': 'screens_default',
            'old_value': 'Old screens',
            'new_value': 'Conflict option B',
            'author': 'Caregiver C',
            'timestamp': '2026-02-10T10:30:00.000',
            'ruleset_version': 5,
            'status': 'pending',
          },
        ],
        'change_feed': const [],
      });

      final notifier = FamilyRulesNotifier();
      await _waitForLoaded(notifier);

      await notifier.resolveConflict(
        childId: 'child-1',
        ruleId: 'screens_default',
        chosenDiffId: 'd-a',
        resolver: 'Primary caregiver',
      );

      expect(notifier.state.rules['screens_default'], 'Conflict option A');
      expect(notifier.state.pendingDiffs, hasLength(1));
      expect(notifier.state.pendingDiffs.single.diffId, 'd-outside');

      final events = await EventBusService.allEvents();
      final conflictEvents = events
          .where((e) => e['type'] == EventTypes.frConflictResolved)
          .toList();
      expect(conflictEvents, hasLength(1));
    },
  );
}
