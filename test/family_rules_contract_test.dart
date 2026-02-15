import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settle/models/rules_diff.dart';
import 'package:settle/providers/family_rules_provider.dart';

Future<void> _waitForLoaded(FamilyRulesNotifier notifier) async {
  for (var i = 0; i < 80; i++) {
    if (!notifier.state.isLoading) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('FamilyRulesNotifier did not finish loading.');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('settle_family_rules');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  test('family rules persists schema version and typed diffs', () async {
    final notifier = FamilyRulesNotifier();
    await _waitForLoaded(notifier);

    await notifier.updateRule(
      childId: 'child-1',
      ruleId: 'screens_default',
      newValue: 'No screens before breakfast.',
      author: 'Primary caregiver',
    );

    expect(notifier.state.rulesetVersion, 2);
    expect(notifier.state.pendingDiffs, hasLength(1));
    final diff = notifier.state.pendingDiffs.single;
    expect(diff.changedRuleId, 'screens_default');
    expect(diff.status, RulesDiffStatus.pending);
    expect(diff.schemaVersion, RulesDiff.schemaVersionV1);

    final box = await Hive.openBox<dynamic>('family_rules_v1');
    final raw = Map<String, dynamic>.from(box.get('state') as Map);
    expect(raw['schema_version'], 1);

    final pending = (raw['pending_diffs'] as List).single;
    final storedDiff = Map<String, dynamic>.from(pending as Map);
    expect(storedDiff['schema_version'], RulesDiff.schemaVersionV1);
    expect(storedDiff['status'], RulesDiffStatus.pending);
    expect(storedDiff['changed_rule_id'], 'screens_default');
  });

  test('family rules migrates legacy pending diff maps on load', () async {
    final box = await Hive.openBox<dynamic>('family_rules_v1');
    await box.put('state', {
      'ruleset_version': 3,
      'rules': {
        'boundary_public': 'Old',
        'screens_default': 'Old',
        'snacks_default': 'Old',
        'bedtime_routine': 'Old',
      },
      'pending_diffs': [
        {
          'diff_id': 'd-1',
          'changed_rule_id': 'screens_default',
          'old_value': 'Old',
          'new_value': 'New',
          'author': 'Caregiver A',
          'timestamp': '2026-02-10T10:00:00.000',
          'ruleset_version': 3,
        },
      ],
      'change_feed': const [],
    });

    final notifier = FamilyRulesNotifier();
    await _waitForLoaded(notifier);

    expect(notifier.state.pendingDiffs, hasLength(1));
    final diff = notifier.state.pendingDiffs.single;
    expect(diff.diffId, 'd-1');
    expect(diff.status, RulesDiffStatus.pending);
    expect(diff.schemaVersion, RulesDiff.schemaVersionV1);

    final migrated = Map<String, dynamic>.from(box.get('state') as Map);
    expect(migrated['schema_version'], 1);
    final migratedDiff = Map<String, dynamic>.from(
      (migrated['pending_diffs'] as List).single as Map,
    );
    expect(migratedDiff['schema_version'], RulesDiff.schemaVersionV1);
    expect(migratedDiff['status'], RulesDiffStatus.pending);
  });
}
