import 'package:hive_flutter/hive_flutter.dart';

part 'sleep_session.g.dart';

/// A single sleep period — nap or overnight. Active session has null [endedAt].
@HiveType(typeId: 11)
class SleepSession extends HiveObject {
  @HiveField(0)
  DateTime startedAt;

  @HiveField(1)
  DateTime? endedAt;

  /// True for overnight sleep, false for naps.
  @HiveField(2)
  bool isNight;

  /// Optional notes attached to this session.
  @HiveField(3)
  String? notes;

  /// Minutes baby was awake before this session started (wake window length).
  /// Captured at session start for adaptive scheduler analysis.
  @HiveField(4)
  int? wakeWindowAtStart;

  /// Sleep onset latency — minutes from "put down" to "asleep".
  /// Set when the parent taps "baby is asleep" after starting a session,
  /// or estimated from session start to first sustained sleep period.
  @HiveField(5)
  int? sleepOnsetLatency;

  SleepSession({
    required this.startedAt,
    this.endedAt,
    this.isNight = false,
    this.notes,
    this.wakeWindowAtStart,
    this.sleepOnsetLatency,
  });

  bool get isActive => endedAt == null;

  Duration get duration => (endedAt ?? DateTime.now()).difference(startedAt);

  /// Minutes since sleep started (for the timer display).
  int get elapsedMinutes => duration.inMinutes;

  SleepSession copyWith({
    DateTime? startedAt,
    DateTime? endedAt,
    bool? isNight,
    String? notes,
    int? wakeWindowAtStart,
    int? sleepOnsetLatency,
  }) {
    return SleepSession(
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      isNight: isNight ?? this.isNight,
      notes: notes ?? this.notes,
      wakeWindowAtStart: wakeWindowAtStart ?? this.wakeWindowAtStart,
      sleepOnsetLatency: sleepOnsetLatency ?? this.sleepOnsetLatency,
    );
  }
}
