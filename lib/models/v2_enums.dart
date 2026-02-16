import 'package:hive_flutter/hive_flutter.dart';

part 'v2_enums.g.dart';

@HiveType(typeId: 55)
enum UsageOutcome {
  @HiveField(0)
  great,
  @HiveField(1)
  okay,
  @HiveField(2)
  didntWork,
  @HiveField(3)
  didntTry,
}

@HiveType(typeId: 56)
enum RegulationTrigger {
  @HiveField(0)
  aboutToLoseIt,
  @HiveField(1)
  childMelting,
  @HiveField(2)
  alreadyYelled,
  @HiveField(3)
  needMinute,
}

@HiveType(typeId: 57)
enum PatternType {
  @HiveField(0)
  time,
  @HiveField(1)
  strategy,
  @HiveField(2)
  regulation,
}

@HiveType(typeId: 58)
enum NudgeType {
  @HiveField(0)
  predictable,
  @HiveField(1)
  pattern,
  @HiveField(2)
  content,
  @HiveField(3)
  family,
}
