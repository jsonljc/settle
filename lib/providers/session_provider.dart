import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/sleep_session.dart';

const _boxName = 'sessions';

/// Tracks the currently active [SleepSession] (null when baby is awake)
/// and persists all sessions to Hive.
final sessionProvider = StateNotifierProvider<SessionNotifier, SleepSession?>((
  ref,
) {
  return SessionNotifier();
});

class SessionNotifier extends StateNotifier<SleepSession?> {
  SessionNotifier() : super(null) {
    _load();
  }

  Box<SleepSession>? _box;
  DateTime? _cachedLastWokeAt;

  Future<Box<SleepSession>> _ensureBox() async {
    if (_box == null) {
      _box = await Hive.openBox<SleepSession>(_boxName);
      _updateLastWokeAt();
    }
    return _box!;
  }

  void _updateLastWokeAt() {
    if (_box == null) return;
    DateTime? latest;
    for (final s in _box!.values) {
      if (s.endedAt != null) {
        if (latest == null || s.endedAt!.isAfter(latest)) {
          latest = s.endedAt;
        }
      }
    }
    _cachedLastWokeAt = latest;
  }

  Future<void> _load() async {
    final box = await _ensureBox();
    // Restore any active (non-ended) session.
    for (final session in box.values) {
      if (session.isActive) {
        state = session;
        return;
      }
    }
  }

  /// Start a new sleep session.
  ///
  /// [wakeWindowMinutes] — the wake window length at the time of put-down,
  /// used by the adaptive scheduler to correlate window length with SOL.
  Future<void> start({bool isNight = false, int? wakeWindowMinutes}) async {
    final box = await _ensureBox();
    final session = SleepSession(
      startedAt: DateTime.now(),
      isNight: isNight,
      wakeWindowAtStart: wakeWindowMinutes,
    );
    await box.add(session);
    state = session;
  }

  /// Undo the most recently started session (if still active).
  /// Used for the 30-second undo after accidental sleep log.
  Future<void> undoStart() async {
    if (state == null) return;
    final session = state!;
    state = null;
    await session.delete(); // Remove from Hive box
  }

  /// End the current session.
  Future<void> end() async {
    if (state == null) return;
    state!.endedAt = DateTime.now();
    await state!.save();
    _updateLastWokeAt();
    state = null;
  }

  /// Record the sleep onset latency for the current session.
  /// Called when the parent taps "baby is asleep" after starting a session.
  Future<void> recordSleepOnset(int latencyMinutes) async {
    if (state == null) return;
    state!.sleepOnsetLatency = latencyMinutes;
    await state!.save();
    // Don't change state reference — session is still active
  }

  /// All completed sessions, newest first.
  Future<List<SleepSession>> get history async {
    final box = await _ensureBox();
    return box.values.where((s) => !s.isActive).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  /// Sessions for a specific date.
  Future<List<SleepSession>> forDate(DateTime date) async {
    final box = await _ensureBox();
    return box.values.where((s) {
      final d = s.startedAt;
      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).toList();
  }

  /// The time the baby last woke up (= most recent session's endedAt).
  /// Null if no sessions have been recorded yet or box isn't initialized.
  DateTime? get lastWokeAt => _cachedLastWokeAt;

  /// Count of completed sessions with SOL data (for adaptive scheduler UI).
  Future<int> get sessionsWithSolCount async {
    final box = await _ensureBox();
    return box.values
        .where(
          (s) =>
              !s.isActive &&
              s.sleepOnsetLatency != null &&
              s.wakeWindowAtStart != null,
        )
        .length;
  }
}
