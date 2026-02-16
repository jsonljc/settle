import 'package:hive_flutter/hive_flutter.dart';

import 'v2_enums.dart';

part 'usage_event.g.dart';

@HiveType(typeId: 51)
class UsageEvent extends HiveObject {
  @HiveField(0)
  String cardId;

  @HiveField(1)
  DateTime timestamp;

  @HiveField(2)
  UsageOutcome? outcome;

  @HiveField(3)
  String? context;

  @HiveField(4)
  bool regulationUsed;

  UsageEvent({
    required this.cardId,
    DateTime? timestamp,
    this.outcome,
    this.context,
    this.regulationUsed = false,
  }) : timestamp = timestamp ?? DateTime.now();
}
