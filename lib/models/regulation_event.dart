import 'package:hive_flutter/hive_flutter.dart';

import 'v2_enums.dart';

part 'regulation_event.g.dart';

@HiveType(typeId: 52)
class RegulationEvent extends HiveObject {
  @HiveField(0)
  DateTime timestamp;

  @HiveField(1)
  RegulationTrigger trigger;

  @HiveField(2)
  bool completed;

  @HiveField(3)
  int durationSeconds;

  RegulationEvent({
    DateTime? timestamp,
    required this.trigger,
    this.completed = false,
    this.durationSeconds = 0,
  }) : timestamp = timestamp ?? DateTime.now();
}
