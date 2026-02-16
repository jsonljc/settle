import 'package:hive_flutter/hive_flutter.dart';

import 'v2_enums.dart';

part 'nudge_record.g.dart';

@HiveType(typeId: 54)
class NudgeRecord extends HiveObject {
  @HiveField(0)
  NudgeType nudgeType;

  @HiveField(1)
  DateTime sentAt;

  @HiveField(2)
  bool opened;

  @HiveField(3)
  bool actedOn;

  NudgeRecord({
    required this.nudgeType,
    DateTime? sentAt,
    this.opened = false,
    this.actedOn = false,
  }) : sentAt = sentAt ?? DateTime.now();

  NudgeRecord copyWith({
    NudgeType? nudgeType,
    DateTime? sentAt,
    bool? opened,
    bool? actedOn,
  }) {
    return NudgeRecord(
      nudgeType: nudgeType ?? this.nudgeType,
      sentAt: sentAt ?? this.sentAt,
      opened: opened ?? this.opened,
      actedOn: actedOn ?? this.actedOn,
    );
  }
}
