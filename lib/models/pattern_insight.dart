import 'package:hive_flutter/hive_flutter.dart';

import 'v2_enums.dart';

part 'pattern_insight.g.dart';

@HiveType(typeId: 53)
class PatternInsight extends HiveObject {
  @HiveField(0)
  PatternType patternType;

  @HiveField(1)
  String insight;

  @HiveField(2)
  double confidence;

  @HiveField(3)
  int basedOnEvents;

  @HiveField(4)
  DateTime createdAt;

  PatternInsight({
    required this.patternType,
    required this.insight,
    required this.confidence,
    required this.basedOnEvents,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
