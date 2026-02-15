import 'package:hive_flutter/hive_flutter.dart';

part 'night_wake.g.dart';

/// A single night-time wake event during an overnight session.
@HiveType(typeId: 12)
class NightWake extends HiveObject {
  @HiveField(0)
  DateTime occurredAt;

  /// Whether a feed was given during this wake.
  @HiveField(1)
  bool fed;

  /// How long the baby took to resettle (in minutes). Null if ongoing.
  @HiveField(2)
  int? resettleMinutes;

  /// Optional notes.
  @HiveField(3)
  String? notes;

  NightWake({
    required this.occurredAt,
    this.fed = false,
    this.resettleMinutes,
    this.notes,
  });

  NightWake copyWith({
    DateTime? occurredAt,
    bool? fed,
    int? resettleMinutes,
    String? notes,
  }) {
    return NightWake(
      occurredAt: occurredAt ?? this.occurredAt,
      fed: fed ?? this.fed,
      resettleMinutes: resettleMinutes ?? this.resettleMinutes,
      notes: notes ?? this.notes,
    );
  }
}
