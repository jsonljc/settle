// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v2_enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UsageOutcomeAdapter extends TypeAdapter<UsageOutcome> {
  @override
  final int typeId = 55;

  @override
  UsageOutcome read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UsageOutcome.great;
      case 1:
        return UsageOutcome.okay;
      case 2:
        return UsageOutcome.didntWork;
      case 3:
        return UsageOutcome.didntTry;
      default:
        return UsageOutcome.great;
    }
  }

  @override
  void write(BinaryWriter writer, UsageOutcome obj) {
    switch (obj) {
      case UsageOutcome.great:
        writer.writeByte(0);
        break;
      case UsageOutcome.okay:
        writer.writeByte(1);
        break;
      case UsageOutcome.didntWork:
        writer.writeByte(2);
        break;
      case UsageOutcome.didntTry:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageOutcomeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RegulationTriggerAdapter extends TypeAdapter<RegulationTrigger> {
  @override
  final int typeId = 56;

  @override
  RegulationTrigger read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RegulationTrigger.aboutToLoseIt;
      case 1:
        return RegulationTrigger.childMelting;
      case 2:
        return RegulationTrigger.alreadyYelled;
      case 3:
        return RegulationTrigger.needMinute;
      default:
        return RegulationTrigger.aboutToLoseIt;
    }
  }

  @override
  void write(BinaryWriter writer, RegulationTrigger obj) {
    switch (obj) {
      case RegulationTrigger.aboutToLoseIt:
        writer.writeByte(0);
        break;
      case RegulationTrigger.childMelting:
        writer.writeByte(1);
        break;
      case RegulationTrigger.alreadyYelled:
        writer.writeByte(2);
        break;
      case RegulationTrigger.needMinute:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegulationTriggerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PatternTypeAdapter extends TypeAdapter<PatternType> {
  @override
  final int typeId = 57;

  @override
  PatternType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PatternType.time;
      case 1:
        return PatternType.strategy;
      case 2:
        return PatternType.regulation;
      default:
        return PatternType.time;
    }
  }

  @override
  void write(BinaryWriter writer, PatternType obj) {
    switch (obj) {
      case PatternType.time:
        writer.writeByte(0);
        break;
      case PatternType.strategy:
        writer.writeByte(1);
        break;
      case PatternType.regulation:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatternTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NudgeTypeAdapter extends TypeAdapter<NudgeType> {
  @override
  final int typeId = 58;

  @override
  NudgeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NudgeType.predictable;
      case 1:
        return NudgeType.pattern;
      case 2:
        return NudgeType.content;
      case 3:
        return NudgeType.family;
      default:
        return NudgeType.predictable;
    }
  }

  @override
  void write(BinaryWriter writer, NudgeType obj) {
    switch (obj) {
      case NudgeType.predictable:
        writer.writeByte(0);
        break;
      case NudgeType.pattern:
        writer.writeByte(1);
        break;
      case NudgeType.content:
        writer.writeByte(2);
        break;
      case NudgeType.family:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NudgeTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
