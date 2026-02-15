import 'package:hive_flutter/hive_flutter.dart';

import 'sleep_session.dart';
import 'night_wake.dart';

part 'day_plan.g.dart';

/// A day's worth of sleep data — used by the Today screen's plan and week tabs.
@HiveType(typeId: 13)
class DayPlan extends HiveObject {
  /// The date this plan represents (time component zeroed).
  @HiveField(0)
  DateTime date;

  /// All sleep sessions for this day.
  @HiveField(1)
  List<SleepSession> sessions;

  /// Night wakes (only for overnight sessions that overlap this day).
  @HiveField(2)
  List<NightWake> nightWakes;

  DayPlan({
    required this.date,
    List<SleepSession>? sessions,
    List<NightWake>? nightWakes,
  })  : sessions = sessions ?? [],
        nightWakes = nightWakes ?? [];

  /// Total nap minutes for the day.
  int get totalNapMinutes => sessions
      .where((s) => !s.isNight && !s.isActive)
      .fold(0, (sum, s) => sum + s.duration.inMinutes);

  /// Total night sleep minutes.
  int get totalNightMinutes => sessions
      .where((s) => s.isNight && !s.isActive)
      .fold(0, (sum, s) => sum + s.duration.inMinutes);

  /// Number of completed naps.
  int get napCount => sessions.where((s) => !s.isNight && !s.isActive).length;

  /// Number of night wakes.
  int get wakeCount => nightWakes.length;
}
