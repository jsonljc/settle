import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/rules_diff.dart';
import '../services/family_rules_guidance_service.dart';
import '../services/event_bus_service.dart';
import '../services/spec_policy.dart';

const _familyRulesBox = 'family_rules_v1';
const _familyRulesKey = 'state';
const _familyRulesSchemaVersion = 1;

class FamilyRulesState {
  const FamilyRulesState({
    required this.isLoading,
    required this.rulesetVersion,
    required this.rules,
    required this.pendingDiffs,
    required this.changeFeed,
    required this.error,
  });

  final bool isLoading;
  final int rulesetVersion;
  final Map<String, String> rules;
  final List<RulesDiff> pendingDiffs;
  final List<Map<String, dynamic>> changeFeed;
  final String? error;

  int get unreadCount => pendingDiffs.length;

  List<RulesDiff> conflictsForRule(String ruleId) {
    return pendingDiffs.where((d) => d.changedRuleId == ruleId).toList();
  }

  List<RulesDiff> overlapConflictsForRule(
    String ruleId, {
    int overlapMinutes = SpecPolicy.familyRulesConflictOverlapMinutes,
  }) {
    final diffs = conflictsForRule(ruleId);
    if (diffs.length < 2) return const [];

    final sorted = [...diffs]
      ..sort((a, b) => _parseTs(b).compareTo(_parseTs(a)));
    final anchor = _parseTs(sorted.first);
    final window = Duration(minutes: overlapMinutes);
    final inWindow = sorted
        .where((d) => anchor.difference(_parseTs(d)).abs() <= window)
        .toList();
    if (inWindow.length < 2) return const [];
    return inWindow;
  }

  static DateTime _parseTs(RulesDiff diff) {
    return DateTime.tryParse(diff.timestamp) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static FamilyRulesState initial() {
    return const FamilyRulesState(
      isLoading: true,
      rulesetVersion: 1,
      rules: {
        'boundary_public': 'I stay calm, one sentence, then hold line.',
        'screens_default': 'No screens before breakfast or bedtime routine.',
        'snacks_default': 'Offer snack windows, no grazing all day.',
        'bedtime_routine': 'Bath, books, bed. Same order nightly.',
      },
      pendingDiffs: [],
      changeFeed: [],
      error: null,
    );
  }

  FamilyRulesState copyWith({
    bool? isLoading,
    int? rulesetVersion,
    Map<String, String>? rules,
    List<RulesDiff>? pendingDiffs,
    List<Map<String, dynamic>>? changeFeed,
    Object? error = _noValue,
  }) {
    return FamilyRulesState(
      isLoading: isLoading ?? this.isLoading,
      rulesetVersion: rulesetVersion ?? this.rulesetVersion,
      rules: rules ?? this.rules,
      pendingDiffs: pendingDiffs ?? this.pendingDiffs,
      changeFeed: changeFeed ?? this.changeFeed,
      error: identical(error, _noValue) ? this.error : error as String?,
    );
  }
}

const _noValue = Object();

final familyRulesProvider =
    StateNotifierProvider<FamilyRulesNotifier, FamilyRulesState>((ref) {
      return FamilyRulesNotifier();
    });

class FamilyRulesNotifier extends StateNotifier<FamilyRulesState> {
  FamilyRulesNotifier() : super(FamilyRulesState.initial()) {
    _load();
  }

  /// Reload rules from storage. Use for retry after error.
  Future<void> load() => _load();

  Box<dynamic>? _box;
  final FamilyRulesGuidanceService _guidance =
      FamilyRulesGuidanceService.instance;

  Future<Box<dynamic>> _ensureBox() async {
    _box ??= await Hive.openBox<dynamic>(_familyRulesBox);
    return _box!;
  }

  String _newDiffId() {
    final rand = Random().nextInt(1 << 20).toRadixString(16);
    return '${DateTime.now().microsecondsSinceEpoch}-$rand';
  }

  List<RulesDiff> _parsePendingDiffs(dynamic rawDiffs) {
    if (rawDiffs is! List) return const [];
    return rawDiffs.map(RulesDiff.tryFrom).whereType<RulesDiff>().toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  bool _needsRulesMigration(
    Map<String, dynamic> mapped,
    FamilyRulesState next,
  ) {
    if (mapped['schema_version'] != _familyRulesSchemaVersion) {
      return true;
    }

    final rawDiffs = mapped['pending_diffs'];
    if (rawDiffs is! List) return true;
    final normalizedDiffs = next.pendingDiffs.map((d) => d.toMap()).toList();
    return jsonEncode(rawDiffs) != jsonEncode(normalizedDiffs);
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final defaultRules = await _guidance.defaultRules();
      final box = await _ensureBox();
      final raw = box.get(_familyRulesKey);
      if (raw is Map) {
        final mapped = Map<String, dynamic>.from(raw);
        final parsedRules =
            (mapped['rules'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ) ??
            const <String, String>{};
        final next = state.copyWith(
          isLoading: false,
          rulesetVersion: mapped['ruleset_version'] as int? ?? 1,
          rules: parsedRules.isEmpty ? defaultRules : parsedRules,
          pendingDiffs: _parsePendingDiffs(mapped['pending_diffs']),
          changeFeed:
              (mapped['change_feed'] as List?)
                  ?.whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              [],
        );
        state = next;

        if (_needsRulesMigration(mapped, next)) {
          await _persist(next);
        }
      } else {
        final seeded = FamilyRulesState.initial().copyWith(
          isLoading: false,
          rules: defaultRules,
        );
        await _persist(seeded);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _persist(FamilyRulesState next) async {
    final box = await _ensureBox();
    await box.put(_familyRulesKey, {
      'schema_version': _familyRulesSchemaVersion,
      'ruleset_version': next.rulesetVersion,
      'rules': next.rules,
      'pending_diffs': next.pendingDiffs.map((d) => d.toMap()).toList(),
      'change_feed': next.changeFeed,
      'updated_at': DateTime.now().toIso8601String(),
    });
    state = next;
  }

  Future<void> updateRule({
    required String childId,
    required String ruleId,
    required String newValue,
    required String author,
  }) async {
    final allowedRuleIds = await _guidance.allowedRuleIds();
    if (!allowedRuleIds.contains(ruleId)) {
      throw ArgumentError.value(ruleId, 'ruleId', 'Unknown rule id.');
    }

    final oldValue = state.rules[ruleId] ?? '';
    final diff = RulesDiff(
      diffId: _newDiffId(),
      changedRuleId: ruleId,
      oldValue: oldValue,
      newValue: newValue,
      author: author,
      timestamp: DateTime.now().toIso8601String(),
      rulesetVersion: state.rulesetVersion + 1,
      status: RulesDiffStatus.pending,
    );

    final nextRules = {...state.rules, ruleId: newValue};
    final nextPending = [...state.pendingDiffs, diff];
    final nextFeed = [
      {
        'kind': 'rule_updated',
        'message': '$author updated $ruleId',
        'timestamp': DateTime.now().toIso8601String(),
      },
      ...state.changeFeed,
    ];

    final next = state.copyWith(
      rulesetVersion: state.rulesetVersion + 1,
      rules: nextRules,
      pendingDiffs: nextPending,
      changeFeed: nextFeed,
    );

    await _persist(next);

    await EventBusService.emitFamilyRuleUpdated(
      childId: childId,
      ruleId: ruleId,
      author: author,
    );

    await EventBusService.emitFamilyDiffReceived(
      childId: childId,
      ruleId: ruleId,
      diffId: diff.diffId,
    );
  }

  Future<void> acceptDiff({
    required String childId,
    required String diffId,
    required String reviewer,
  }) async {
    final idx = state.pendingDiffs.indexWhere((d) => d.diffId == diffId);
    if (idx == -1) return;

    final diff = state.pendingDiffs[idx];
    final ruleId = diff.changedRuleId;
    final nextRules = {...state.rules, ruleId: diff.newValue};
    final nextPending = state.pendingDiffs
        .where((d) => d.diffId != diffId)
        .toList();

    final nextFeed = [
      {
        'kind': 'diff_accepted',
        'message': '$reviewer accepted changes for $ruleId',
        'timestamp': DateTime.now().toIso8601String(),
      },
      ...state.changeFeed,
    ];

    await _persist(
      state.copyWith(
        rules: nextRules,
        pendingDiffs: nextPending,
        changeFeed: nextFeed,
      ),
    );

    await EventBusService.emitFamilyDiffAccepted(
      childId: childId,
      ruleId: ruleId,
      diffId: diffId,
    );
  }

  Future<void> resolveConflict({
    required String childId,
    required String ruleId,
    required String chosenDiffId,
    required String resolver,
  }) async {
    final conflicts = state.overlapConflictsForRule(ruleId);
    if (conflicts.length < 2) return;

    final chosenMatches = conflicts.where((d) => d.diffId == chosenDiffId);
    if (chosenMatches.isEmpty) return;
    final chosen = chosenMatches.first;

    final nextRules = {...state.rules, ruleId: chosen.newValue};

    final conflictIds = conflicts.map((d) => d.diffId).toSet();
    final nextPending = state.pendingDiffs
        .where((d) => !conflictIds.contains(d.diffId))
        .toList();

    final nextFeed = [
      {
        'kind': 'conflict_resolved',
        'message': '$resolver resolved conflict on $ruleId',
        'timestamp': DateTime.now().toIso8601String(),
      },
      ...state.changeFeed,
    ];

    await _persist(
      state.copyWith(
        rules: nextRules,
        pendingDiffs: nextPending,
        changeFeed: nextFeed,
      ),
    );

    await EventBusService.emitFamilyConflictResolved(
      childId: childId,
      ruleId: ruleId,
      chosenDiffId: chosenDiffId,
    );
  }
}
