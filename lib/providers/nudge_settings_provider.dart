import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _boxName = 'nudge_settings';
const _key = 'settings';

/// Frequency of nudge notifications.
enum NudgeFrequency {
  minimal, // ~1 per week
  smart,   // 2-3 per week
  more,   // daily when relevant
}

/// Persisted nudge preferences: per-type toggles, quiet hours, frequency.
class NudgeSettings {
  const NudgeSettings({
    this.predictableEnabled = true,
    this.patternEnabled = true,
    this.contentEnabled = true,
    this.quietStartHour = 20,
    this.quietEndHour = 7,
    this.frequency = NudgeFrequency.smart,
    this.eveningCheckInEnabled = false,
  });

  final bool predictableEnabled;
  final bool patternEnabled;
  final bool contentEnabled;
  final int quietStartHour;
  final int quietEndHour;
  final NudgeFrequency frequency;
  /// Evening check-in: one notification 1h before bedtime. Off by default (opt-in).
  final bool eveningCheckInEnabled;

  NudgeSettings copyWith({
    bool? predictableEnabled,
    bool? patternEnabled,
    bool? contentEnabled,
    int? quietStartHour,
    int? quietEndHour,
    NudgeFrequency? frequency,
    bool? eveningCheckInEnabled,
  }) {
    return NudgeSettings(
      predictableEnabled: predictableEnabled ?? this.predictableEnabled,
      patternEnabled: patternEnabled ?? this.patternEnabled,
      contentEnabled: contentEnabled ?? this.contentEnabled,
      quietStartHour: quietStartHour ?? this.quietStartHour,
      quietEndHour: quietEndHour ?? this.quietEndHour,
      frequency: frequency ?? this.frequency,
      eveningCheckInEnabled:
          eveningCheckInEnabled ?? this.eveningCheckInEnabled,
    );
  }

  static NudgeSettings fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const NudgeSettings();
    final freq = map['frequency'];
    return NudgeSettings(
      predictableEnabled: map['predictable_enabled'] as bool? ?? true,
      patternEnabled: map['pattern_enabled'] as bool? ?? true,
      contentEnabled: map['content_enabled'] as bool? ?? true,
      quietStartHour: map['quiet_start_hour'] as int? ?? 20,
      quietEndHour: map['quiet_end_hour'] as int? ?? 7,
      frequency: freq == 'minimal'
          ? NudgeFrequency.minimal
          : freq == 'more'
              ? NudgeFrequency.more
              : NudgeFrequency.smart,
      eveningCheckInEnabled: map['evening_check_in_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'predictable_enabled': predictableEnabled,
      'pattern_enabled': patternEnabled,
      'content_enabled': contentEnabled,
      'quiet_start_hour': quietStartHour,
      'quiet_end_hour': quietEndHour,
      'frequency': frequency == NudgeFrequency.minimal
          ? 'minimal'
          : frequency == NudgeFrequency.more
              ? 'more'
              : 'smart',
      'evening_check_in_enabled': eveningCheckInEnabled,
    };
  }

  /// True if [hour] (0-23) is inside quiet window (e.g. 20-7 = 8pm to 7am).
  bool isQuietHour(int hour) {
    if (quietStartHour > quietEndHour) {
      return hour >= quietStartHour || hour < quietEndHour;
    }
    return hour >= quietStartHour && hour < quietEndHour;
  }
}

final nudgeSettingsProvider =
    StateNotifierProvider<NudgeSettingsNotifier, NudgeSettings>((ref) {
  return NudgeSettingsNotifier();
});

class NudgeSettingsNotifier extends StateNotifier<NudgeSettings> {
  NudgeSettingsNotifier() : super(const NudgeSettings()) {
    _load();
  }

  Box<dynamic>? _box;

  Future<Box<dynamic>> _ensureBox() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
    return _box!;
  }

  Future<void> _load() async {
    try {
      final box = await _ensureBox();
      final raw = box.get(_key);
      if (raw is Map) {
        state = NudgeSettings.fromMap(Map<dynamic, dynamic>.from(raw));
      }
    } catch (_) {
      state = const NudgeSettings();
    }
  }

  Future<void> _persist() async {
    try {
      final box = await _ensureBox();
      await box.put(_key, state.toMap());
    } catch (_) {}
  }

  Future<void> setPredictableEnabled(bool value) async {
    state = state.copyWith(predictableEnabled: value);
    await _persist();
  }

  Future<void> setPatternEnabled(bool value) async {
    state = state.copyWith(patternEnabled: value);
    await _persist();
  }

  Future<void> setContentEnabled(bool value) async {
    state = state.copyWith(contentEnabled: value);
    await _persist();
  }

  Future<void> setQuietHours(int startHour, int endHour) async {
    state = state.copyWith(quietStartHour: startHour, quietEndHour: endHour);
    await _persist();
  }

  Future<void> setFrequency(NudgeFrequency value) async {
    state = state.copyWith(frequency: value);
    await _persist();
  }

  Future<void> setEveningCheckInEnabled(bool value) async {
    state = state.copyWith(eveningCheckInEnabled: value);
    await _persist();
  }
}
