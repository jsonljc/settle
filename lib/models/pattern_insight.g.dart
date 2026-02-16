// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pattern_insight.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PatternInsightAdapter extends TypeAdapter<PatternInsight> {
  @override
  final int typeId = 53;

  @override
  PatternInsight read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PatternInsight(
      patternType: fields[0] as PatternType,
      insight: fields[1] as String,
      confidence: fields[2] as double,
      basedOnEvents: fields[3] as int,
      createdAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PatternInsight obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.patternType)
      ..writeByte(1)
      ..write(obj.insight)
      ..writeByte(2)
      ..write(obj.confidence)
      ..writeByte(3)
      ..write(obj.basedOnEvents)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatternInsightAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
