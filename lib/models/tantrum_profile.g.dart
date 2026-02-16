// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tantrum_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TantrumProfileAdapter extends TypeAdapter<TantrumProfile> {
  @override
  final int typeId = 40;

  @override
  TantrumProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TantrumProfile(
      tantrumType: fields[0] as TantrumType,
      commonTriggers: (fields[1] as List).cast<TriggerType>(),
      parentPattern: fields[2] as ParentPattern,
      responsePriority: fields[3] as ResponsePriority,
    );
  }

  @override
  void write(BinaryWriter writer, TantrumProfile obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.tantrumType)
      ..writeByte(1)
      ..write(obj.commonTriggers)
      ..writeByte(2)
      ..write(obj.parentPattern)
      ..writeByte(3)
      ..write(obj.responsePriority);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TantrumProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TantrumEventAdapter extends TypeAdapter<TantrumEvent> {
  @override
  final int typeId = 41;

  @override
  TantrumEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TantrumEvent(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      intensity: fields[3] as TantrumIntensity,
      whatHelped: (fields[5] as List).cast<String>(),
      trigger: fields[2] as TriggerType?,
      durationSeconds: fields[4] as int?,
      notes: fields[6] as String?,
      flashcardUsed: fields[7] as bool? ?? false,
      location: fields[8] as String?,
      parentReaction: fields[9] as String?,
      selectedCardId: fields[10] as String?,
      captureTrigger: fields[11] as String?,
      captureIntensity: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TantrumEvent obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.trigger)
      ..writeByte(3)
      ..write(obj.intensity)
      ..writeByte(4)
      ..write(obj.durationSeconds)
      ..writeByte(5)
      ..write(obj.whatHelped)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.flashcardUsed)
      ..writeByte(8)
      ..write(obj.location)
      ..writeByte(9)
      ..write(obj.parentReaction)
      ..writeByte(10)
      ..write(obj.selectedCardId)
      ..writeByte(11)
      ..write(obj.captureTrigger)
      ..writeByte(12)
      ..write(obj.captureIntensity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TantrumEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WeeklyTantrumPatternAdapter extends TypeAdapter<WeeklyTantrumPattern> {
  @override
  final int typeId = 42;

  @override
  WeeklyTantrumPattern read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeeklyTantrumPattern(
      weekStart: fields[0] as DateTime,
      totalEvents: fields[1] as int,
      triggerCounts: (fields[2] as Map).cast<TriggerType, int>(),
      timeOfDayCounts: (fields[3] as Map).cast<DayBucket, int>(),
      intensityDistribution: (fields[4] as Map).cast<TantrumIntensity, int>(),
      topHelpers: (fields[5] as List).cast<String>(),
      trend: fields[6] as PatternTrend,
      normalizationStatus: fields[7] as NormalizationStatus,
    );
  }

  @override
  void write(BinaryWriter writer, WeeklyTantrumPattern obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.weekStart)
      ..writeByte(1)
      ..write(obj.totalEvents)
      ..writeByte(2)
      ..write(obj.triggerCounts)
      ..writeByte(3)
      ..write(obj.timeOfDayCounts)
      ..writeByte(4)
      ..write(obj.intensityDistribution)
      ..writeByte(5)
      ..write(obj.topHelpers)
      ..writeByte(6)
      ..write(obj.trend)
      ..writeByte(7)
      ..write(obj.normalizationStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyTantrumPatternAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FocusModeAdapter extends TypeAdapter<FocusMode> {
  @override
  final int typeId = 30;

  @override
  FocusMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FocusMode.sleepOnly;
      case 1:
        return FocusMode.tantrumOnly;
      case 2:
        return FocusMode.both;
      default:
        return FocusMode.sleepOnly;
    }
  }

  @override
  void write(BinaryWriter writer, FocusMode obj) {
    switch (obj) {
      case FocusMode.sleepOnly:
        writer.writeByte(0);
        break;
      case FocusMode.tantrumOnly:
        writer.writeByte(1);
        break;
      case FocusMode.both:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TantrumTypeAdapter extends TypeAdapter<TantrumType> {
  @override
  final int typeId = 31;

  @override
  TantrumType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TantrumType.explosive;
      case 1:
        return TantrumType.shutdown;
      case 2:
        return TantrumType.escalating;
      case 3:
        return TantrumType.mixed;
      default:
        return TantrumType.explosive;
    }
  }

  @override
  void write(BinaryWriter writer, TantrumType obj) {
    switch (obj) {
      case TantrumType.explosive:
        writer.writeByte(0);
        break;
      case TantrumType.shutdown:
        writer.writeByte(1);
        break;
      case TantrumType.escalating:
        writer.writeByte(2);
        break;
      case TantrumType.mixed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TantrumTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TriggerTypeAdapter extends TypeAdapter<TriggerType> {
  @override
  final int typeId = 32;

  @override
  TriggerType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TriggerType.transitions;
      case 1:
        return TriggerType.frustration;
      case 2:
        return TriggerType.sensory;
      case 3:
        return TriggerType.boundaries;
      case 4:
        return TriggerType.unpredictable;
      default:
        return TriggerType.transitions;
    }
  }

  @override
  void write(BinaryWriter writer, TriggerType obj) {
    switch (obj) {
      case TriggerType.transitions:
        writer.writeByte(0);
        break;
      case TriggerType.frustration:
        writer.writeByte(1);
        break;
      case TriggerType.sensory:
        writer.writeByte(2);
        break;
      case TriggerType.boundaries:
        writer.writeByte(3);
        break;
      case TriggerType.unpredictable:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TriggerTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ParentPatternAdapter extends TypeAdapter<ParentPattern> {
  @override
  final int typeId = 33;

  @override
  ParentPattern read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ParentPattern.reasons;
      case 1:
        return ParentPattern.givesIn;
      case 2:
        return ParentPattern.getsAngry;
      case 3:
        return ParentPattern.freezes;
      default:
        return ParentPattern.reasons;
    }
  }

  @override
  void write(BinaryWriter writer, ParentPattern obj) {
    switch (obj) {
      case ParentPattern.reasons:
        writer.writeByte(0);
        break;
      case ParentPattern.givesIn:
        writer.writeByte(1);
        break;
      case ParentPattern.getsAngry:
        writer.writeByte(2);
        break;
      case ParentPattern.freezes:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParentPatternAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ResponsePriorityAdapter extends TypeAdapter<ResponsePriority> {
  @override
  final int typeId = 34;

  @override
  ResponsePriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ResponsePriority.coRegulation;
      case 1:
        return ResponsePriority.structure;
      case 2:
        return ResponsePriority.insight;
      case 3:
        return ResponsePriority.scripts;
      default:
        return ResponsePriority.coRegulation;
    }
  }

  @override
  void write(BinaryWriter writer, ResponsePriority obj) {
    switch (obj) {
      case ResponsePriority.coRegulation:
        writer.writeByte(0);
        break;
      case ResponsePriority.structure:
        writer.writeByte(1);
        break;
      case ResponsePriority.insight:
        writer.writeByte(2);
        break;
      case ResponsePriority.scripts:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResponsePriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TantrumIntensityAdapter extends TypeAdapter<TantrumIntensity> {
  @override
  final int typeId = 35;

  @override
  TantrumIntensity read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TantrumIntensity.mild;
      case 1:
        return TantrumIntensity.moderate;
      case 2:
        return TantrumIntensity.intense;
      default:
        return TantrumIntensity.mild;
    }
  }

  @override
  void write(BinaryWriter writer, TantrumIntensity obj) {
    switch (obj) {
      case TantrumIntensity.mild:
        writer.writeByte(0);
        break;
      case TantrumIntensity.moderate:
        writer.writeByte(1);
        break;
      case TantrumIntensity.intense:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TantrumIntensityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PatternTrendAdapter extends TypeAdapter<PatternTrend> {
  @override
  final int typeId = 36;

  @override
  PatternTrend read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PatternTrend.decreasing;
      case 1:
        return PatternTrend.stable;
      case 2:
        return PatternTrend.increasing;
      default:
        return PatternTrend.decreasing;
    }
  }

  @override
  void write(BinaryWriter writer, PatternTrend obj) {
    switch (obj) {
      case PatternTrend.decreasing:
        writer.writeByte(0);
        break;
      case PatternTrend.stable:
        writer.writeByte(1);
        break;
      case PatternTrend.increasing:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatternTrendAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NormalizationStatusAdapter extends TypeAdapter<NormalizationStatus> {
  @override
  final int typeId = 37;

  @override
  NormalizationStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NormalizationStatus.withinNormal;
      case 1:
        return NormalizationStatus.approachingConcern;
      case 2:
        return NormalizationStatus.flagged;
      default:
        return NormalizationStatus.withinNormal;
    }
  }

  @override
  void write(BinaryWriter writer, NormalizationStatus obj) {
    switch (obj) {
      case NormalizationStatus.withinNormal:
        writer.writeByte(0);
        break;
      case NormalizationStatus.approachingConcern:
        writer.writeByte(1);
        break;
      case NormalizationStatus.flagged:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NormalizationStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DayBucketAdapter extends TypeAdapter<DayBucket> {
  @override
  final int typeId = 38;

  @override
  DayBucket read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DayBucket.morning;
      case 1:
        return DayBucket.midday;
      case 2:
        return DayBucket.afternoon;
      case 3:
        return DayBucket.evening;
      default:
        return DayBucket.morning;
    }
  }

  @override
  void write(BinaryWriter writer, DayBucket obj) {
    switch (obj) {
      case DayBucket.morning:
        writer.writeByte(0);
        break;
      case DayBucket.midday:
        writer.writeByte(1);
        break;
      case DayBucket.afternoon:
        writer.writeByte(2);
        break;
      case DayBucket.evening:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayBucketAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
