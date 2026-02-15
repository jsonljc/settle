import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _rolloutBox = 'release_rollout_v1';
const _rolloutKey = 'state';
const _rolloutSchemaVersion = 1;

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
    required this.windDownNotificationsEnabled,
    required this.scheduleDriftNotificationsEnabled,
  });

  final bool isLoading;
  final bool helpNowEnabled;
  final bool sleepTonightEnabled;
  final bool planProgressEnabled;
  final bool familyRulesEnabled;
  final bool metricsDashboardEnabled;
  final bool complianceChecklistEnabled;
  final bool sleepBoundedAiEnabled;
  final bool windDownNotificationsEnabled;
  final bool scheduleDriftNotificationsEnabled;

  static const initial = ReleaseRolloutState(
    isLoading: true,
    helpNowEnabled: true,
    sleepTonightEnabled: true,
    planProgressEnabled: true,
    familyRulesEnabled: true,
    metricsDashboardEnabled: true,
    complianceChecklistEnabled: true,
    sleepBoundedAiEnabled: true,
    windDownNotificationsEnabled: true,
    scheduleDriftNotificationsEnabled: false,
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
    bool? windDownNotificationsEnabled,
    bool? scheduleDriftNotificationsEnabled,
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
      windDownNotificationsEnabled:
          windDownNotificationsEnabled ?? this.windDownNotificationsEnabled,
      scheduleDriftNotificationsEnabled:
          scheduleDriftNotificationsEnabled ??
          this.scheduleDriftNotificationsEnabled,
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
        state = state.copyWith(
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
          windDownNotificationsEnabled:
              raw['wind_down_notifications_enabled'] as bool? ?? true,
          scheduleDriftNotificationsEnabled:
              raw['schedule_drift_notifications_enabled'] as bool? ?? false,
        );
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
        'wind_down_notifications_enabled': next.windDownNotificationsEnabled,
        'schedule_drift_notifications_enabled':
            next.scheduleDriftNotificationsEnabled,
      });
    } catch (_) {
      // Non-fatal in test contexts.
    }
    state = next;
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

  Future<void> setWindDownNotificationsEnabled(bool value) async {
    await _persist(state.copyWith(windDownNotificationsEnabled: value));
  }

  Future<void> setScheduleDriftNotificationsEnabled(bool value) async {
    await _persist(state.copyWith(scheduleDriftNotificationsEnabled: value));
  }
}
