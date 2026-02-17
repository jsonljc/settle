import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/user_card.dart';
import '../router.dart';

const _rolloutBox = 'release_rollout_v1';
const _rolloutKey = 'state';
const _rolloutSchemaVersion = 4;

const _v2DeckMigrationGuardKey = 'v2_tantrum_deck_migrated';
const _tantrumDeckBoxName = 'tantrum_deck';
const _tantrumDeckStateKey = 'deck_state_v2';
const _userCardsBoxName = 'user_cards';

class ReleaseRolloutState {
  const ReleaseRolloutState({
    required this.isLoading,
    required this.helpNowEnabled,
    required this.sleepTonightEnabled,
    required this.planProgressEnabled,
    required this.familyRulesEnabled,
    required this.metricsDashboardEnabled,
    required this.complianceChecklistEnabled,
    required this.sleepBoundedAiEnabled,
    required this.sleepRhythmSurfacesEnabled,
    required this.rhythmShiftDetectorPromptsEnabled,
    required this.windDownNotificationsEnabled,
    required this.scheduleDriftNotificationsEnabled,
    this.planTabEnabled = true,
    this.familyTabEnabled = true,
    this.libraryTabEnabled = true,
    this.pocketEnabled = true,
    this.regulateEnabled = true,
    this.smartNudgesEnabled = false,
    this.patternDetectionEnabled = false,
    this.uiV3Enabled = true,
  });

  final bool isLoading;
  final bool helpNowEnabled;
  final bool sleepTonightEnabled;
  final bool planProgressEnabled;
  final bool familyRulesEnabled;
  final bool metricsDashboardEnabled;
  final bool complianceChecklistEnabled;
  final bool sleepBoundedAiEnabled;
  final bool sleepRhythmSurfacesEnabled;
  final bool rhythmShiftDetectorPromptsEnabled;
  final bool windDownNotificationsEnabled;
  final bool scheduleDriftNotificationsEnabled;

  final bool planTabEnabled;
  final bool familyTabEnabled;
  final bool libraryTabEnabled;
  final bool pocketEnabled;
  final bool regulateEnabled;
  final bool smartNudgesEnabled;
  final bool patternDetectionEnabled;
  final bool uiV3Enabled;

  static const initial = ReleaseRolloutState(
    isLoading: true,
    helpNowEnabled: true,
    sleepTonightEnabled: true,
    planProgressEnabled: true,
    familyRulesEnabled: true,
    metricsDashboardEnabled: true,
    complianceChecklistEnabled: true,
    sleepBoundedAiEnabled: true,
    sleepRhythmSurfacesEnabled: true,
    rhythmShiftDetectorPromptsEnabled: true,
    windDownNotificationsEnabled: true,
    scheduleDriftNotificationsEnabled: false,
    planTabEnabled: true,
    familyTabEnabled: true,
    libraryTabEnabled: true,
    pocketEnabled: true,
    regulateEnabled: true,
    smartNudgesEnabled: false,
    patternDetectionEnabled: false,
    uiV3Enabled: true,
  );

  ReleaseRolloutState copyWith({
    bool? isLoading,
    bool? helpNowEnabled,
    bool? sleepTonightEnabled,
    bool? planProgressEnabled,
    bool? familyRulesEnabled,
    bool? metricsDashboardEnabled,
    bool? complianceChecklistEnabled,
    bool? sleepBoundedAiEnabled,
    bool? sleepRhythmSurfacesEnabled,
    bool? rhythmShiftDetectorPromptsEnabled,
    bool? windDownNotificationsEnabled,
    bool? scheduleDriftNotificationsEnabled,
    bool? planTabEnabled,
    bool? familyTabEnabled,
    bool? libraryTabEnabled,
    bool? pocketEnabled,
    bool? regulateEnabled,
    bool? smartNudgesEnabled,
    bool? patternDetectionEnabled,
    bool? uiV3Enabled,
  }) {
    return ReleaseRolloutState(
      isLoading: isLoading ?? this.isLoading,
      helpNowEnabled: helpNowEnabled ?? this.helpNowEnabled,
      sleepTonightEnabled: sleepTonightEnabled ?? this.sleepTonightEnabled,
      planProgressEnabled: planProgressEnabled ?? this.planProgressEnabled,
      familyRulesEnabled: familyRulesEnabled ?? this.familyRulesEnabled,
      metricsDashboardEnabled:
          metricsDashboardEnabled ?? this.metricsDashboardEnabled,
      complianceChecklistEnabled:
          complianceChecklistEnabled ?? this.complianceChecklistEnabled,
      sleepBoundedAiEnabled:
          sleepBoundedAiEnabled ?? this.sleepBoundedAiEnabled,
      sleepRhythmSurfacesEnabled:
          sleepRhythmSurfacesEnabled ?? this.sleepRhythmSurfacesEnabled,
      rhythmShiftDetectorPromptsEnabled:
          rhythmShiftDetectorPromptsEnabled ??
          this.rhythmShiftDetectorPromptsEnabled,
      windDownNotificationsEnabled:
          windDownNotificationsEnabled ?? this.windDownNotificationsEnabled,
      scheduleDriftNotificationsEnabled:
          scheduleDriftNotificationsEnabled ??
          this.scheduleDriftNotificationsEnabled,
      planTabEnabled: planTabEnabled ?? this.planTabEnabled,
      familyTabEnabled: familyTabEnabled ?? this.familyTabEnabled,
      libraryTabEnabled: libraryTabEnabled ?? this.libraryTabEnabled,
      pocketEnabled: pocketEnabled ?? this.pocketEnabled,
      regulateEnabled: regulateEnabled ?? this.regulateEnabled,
      smartNudgesEnabled: smartNudgesEnabled ?? this.smartNudgesEnabled,
      patternDetectionEnabled:
          patternDetectionEnabled ?? this.patternDetectionEnabled,
      uiV3Enabled: uiV3Enabled ?? this.uiV3Enabled,
    );
  }
}

final releaseRolloutProvider =
    StateNotifierProvider<ReleaseRolloutNotifier, ReleaseRolloutState>((ref) {
      return ReleaseRolloutNotifier();
    });

class ReleaseRolloutNotifier extends StateNotifier<ReleaseRolloutState> {
  ReleaseRolloutNotifier() : super(ReleaseRolloutState.initial) {
    if (_hiveReady()) {
      _safeLoad();
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _safeLoad() async {
    try {
      await _load();
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Box<dynamic>? _box;

  bool _hiveReady() {
    try {
      final dynamic hive = Hive;
      final homePath = hive.homePath;
      return homePath is String && homePath.isNotEmpty;
    } catch (_) {
      // If homePath is unavailable on a custom backend, attempt normal flow.
      return true;
    }
  }

  Future<Box<dynamic>> _ensureBox() async {
    _box ??= await Hive.openBox<dynamic>(_rolloutBox);
    return _box!;
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    try {
      final box = await _ensureBox();
      final raw = box.get(_rolloutKey);
      if (raw is Map) {
        final schemaVersion =
            raw['schema_version'] as int? ??
            int.tryParse(raw['schema_version']?.toString() ?? '') ??
            1;
        final next = state.copyWith(
          isLoading: false,
          helpNowEnabled: raw['help_now_enabled'] as bool? ?? true,
          sleepTonightEnabled: raw['sleep_tonight_enabled'] as bool? ?? true,
          planProgressEnabled: raw['plan_progress_enabled'] as bool? ?? true,
          familyRulesEnabled: raw['family_rules_enabled'] as bool? ?? true,
          metricsDashboardEnabled:
              raw['metrics_dashboard_enabled'] as bool? ?? true,
          complianceChecklistEnabled:
              raw['compliance_checklist_enabled'] as bool? ?? true,
          sleepBoundedAiEnabled:
              raw['sleep_bounded_ai_enabled'] as bool? ?? true,
          sleepRhythmSurfacesEnabled:
              raw['sleep_rhythm_surfaces_enabled'] as bool? ?? true,
          rhythmShiftDetectorPromptsEnabled:
              raw['rhythm_shift_detector_prompts_enabled'] as bool? ?? true,
          windDownNotificationsEnabled:
              raw['wind_down_notifications_enabled'] as bool? ?? true,
          scheduleDriftNotificationsEnabled:
              raw['schedule_drift_notifications_enabled'] as bool? ?? false,
          planTabEnabled: raw['plan_tab_enabled'] as bool? ?? true,
          familyTabEnabled: raw['family_tab_enabled'] as bool? ?? true,
          libraryTabEnabled: raw['library_tab_enabled'] as bool? ?? true,
          pocketEnabled: raw['pocket_enabled'] as bool? ?? true,
          regulateEnabled: raw['regulate_enabled'] as bool? ?? true,
          smartNudgesEnabled: raw['smart_nudges_enabled'] as bool? ?? false,
          patternDetectionEnabled:
              raw['pattern_detection_enabled'] as bool? ?? false,
          uiV3Enabled: raw['ui_v3_enabled'] as bool? ?? true,
        );

        await _migrateTantrumDeckIfNeeded();

        if (schemaVersion < _rolloutSchemaVersion) {
          await _persist(next);
        } else {
          state = next;
        }
      } else {
        state = state.copyWith(isLoading: false);
        await _persist(state);
      }
    } catch (_) {
      // If Hive isn't initialized in a test harness, keep safe defaults.
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _persist(ReleaseRolloutState next) async {
    try {
      final box = await _ensureBox();
      await box.put(_rolloutKey, {
        'schema_version': _rolloutSchemaVersion,
        'help_now_enabled': next.helpNowEnabled,
        'sleep_tonight_enabled': next.sleepTonightEnabled,
        'plan_progress_enabled': next.planProgressEnabled,
        'family_rules_enabled': next.familyRulesEnabled,
        'metrics_dashboard_enabled': next.metricsDashboardEnabled,
        'compliance_checklist_enabled': next.complianceChecklistEnabled,
        'sleep_bounded_ai_enabled': next.sleepBoundedAiEnabled,
        'sleep_rhythm_surfaces_enabled': next.sleepRhythmSurfacesEnabled,
        'rhythm_shift_detector_prompts_enabled':
            next.rhythmShiftDetectorPromptsEnabled,
        'wind_down_notifications_enabled': next.windDownNotificationsEnabled,
        'schedule_drift_notifications_enabled':
            next.scheduleDriftNotificationsEnabled,
        'plan_tab_enabled': next.planTabEnabled,
        'family_tab_enabled': next.familyTabEnabled,
        'library_tab_enabled': next.libraryTabEnabled,
        'pocket_enabled': next.pocketEnabled,
        'regulate_enabled': next.regulateEnabled,
        'smart_nudges_enabled': next.smartNudgesEnabled,
        'pattern_detection_enabled': next.patternDetectionEnabled,
        'ui_v3_enabled': next.uiV3Enabled,
      });
    } catch (_) {
      // Non-fatal in test contexts.
    }
    state = next;
  }

  Future<void> _migrateTantrumDeckIfNeeded() async {
    try {
      final box = await _ensureBox();
      final migrated = box.get(_v2DeckMigrationGuardKey) as bool? ?? false;
      if (migrated) return;

      await _migrateTantrumDeck();
      await box.put(_v2DeckMigrationGuardKey, true);
    } catch (_) {
      // Non-fatal migration path.
    }
  }

  Future<void> _migrateTantrumDeck() async {
    final deckBox = await Hive.openBox<dynamic>(_tantrumDeckBoxName);
    final rawDeck = deckBox.get(_tantrumDeckStateKey);
    final deckState = _decodeDeckState(rawDeck);
    if (deckState == null) return;

    final savedIds = _readStringList(deckState['savedIds']);
    final favoriteIds = _readStringList(deckState['favoriteIds']);
    final pinnedIds = _readStringList(deckState['pinnedIds']);

    final allIds = _unique([...savedIds, ...favoriteIds, ...pinnedIds]);
    if (allIds.isEmpty) return;

    final userCardsBox = await Hive.openBox<UserCard>(_userCardsBoxName);
    final now = DateTime.now();

    for (final cardId in allIds) {
      final existing = userCardsBox.get(cardId);
      final merged = (existing ?? UserCard(cardId: cardId, savedAt: now))
          .copyWith(
            pinned: (existing?.pinned ?? false) || pinnedIds.contains(cardId),
            savedAt: existing?.savedAt ?? now,
            usageCount: existing?.usageCount ?? 0,
            lastUsed: existing?.lastUsed,
          );
      await userCardsBox.put(cardId, merged);
    }
  }

  Map<String, dynamic>? _decodeDeckState(dynamic rawDeck) {
    if (rawDeck is Map) {
      return Map<String, dynamic>.from(rawDeck);
    }

    if (rawDeck is String && rawDeck.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawDeck);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  List<String> _readStringList(dynamic raw) {
    if (raw is! List) return const [];
    return _unique(raw.map((e) => e.toString()));
  }

  List<String> _unique(Iterable<String> ids) {
    final seen = <String>{};
    final out = <String>[];
    for (final id in ids) {
      final trimmed = id.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) continue;
      seen.add(trimmed);
      out.add(trimmed);
    }
    return out;
  }

  Future<void> setHelpNowEnabled(bool value) async {
    await _persist(state.copyWith(helpNowEnabled: value));
  }

  Future<void> setSleepTonightEnabled(bool value) async {
    await _persist(state.copyWith(sleepTonightEnabled: value));
  }

  Future<void> setPlanProgressEnabled(bool value) async {
    await _persist(state.copyWith(planProgressEnabled: value));
  }

  Future<void> setFamilyRulesEnabled(bool value) async {
    await _persist(state.copyWith(familyRulesEnabled: value));
  }

  Future<void> setMetricsDashboardEnabled(bool value) async {
    await _persist(state.copyWith(metricsDashboardEnabled: value));
  }

  Future<void> setComplianceChecklistEnabled(bool value) async {
    await _persist(state.copyWith(complianceChecklistEnabled: value));
  }

  Future<void> setSleepBoundedAiEnabled(bool value) async {
    await _persist(state.copyWith(sleepBoundedAiEnabled: value));
  }

  Future<void> setSleepRhythmSurfacesEnabled(bool value) async {
    await _persist(state.copyWith(sleepRhythmSurfacesEnabled: value));
  }

  Future<void> setRhythmShiftDetectorPromptsEnabled(bool value) async {
    await _persist(state.copyWith(rhythmShiftDetectorPromptsEnabled: value));
  }

  Future<void> setWindDownNotificationsEnabled(bool value) async {
    await _persist(state.copyWith(windDownNotificationsEnabled: value));
  }

  Future<void> setScheduleDriftNotificationsEnabled(bool value) async {
    await _persist(state.copyWith(scheduleDriftNotificationsEnabled: value));
  }

  Future<void> setPlanTabEnabled(bool value) async {
    await _persist(state.copyWith(planTabEnabled: value));
  }

  Future<void> setFamilyTabEnabled(bool value) async {
    await _persist(state.copyWith(familyTabEnabled: value));
  }

  Future<void> setLibraryTabEnabled(bool value) async {
    await _persist(state.copyWith(libraryTabEnabled: value));
  }

  Future<void> setPocketEnabled(bool value) async {
    await _persist(state.copyWith(pocketEnabled: value));
  }

  Future<void> setRegulateEnabled(bool value) async {
    await _persist(state.copyWith(regulateEnabled: value));
    refreshRouterFromRollout();
  }

  Future<void> setSmartNudgesEnabled(bool value) async {
    await _persist(state.copyWith(smartNudgesEnabled: value));
  }

  Future<void> setPatternDetectionEnabled(bool value) async {
    await _persist(state.copyWith(patternDetectionEnabled: value));
  }

  Future<void> setUiV3Enabled(bool value) async {
    await _persist(state.copyWith(uiV3Enabled: value));
  }
}
