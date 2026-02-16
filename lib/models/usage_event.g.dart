// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UsageEventAdapter extends TypeAdapter<UsageEvent> {
  @override
  final int typeId = 51;

  @override
  UsageEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UsageEvent(
      cardId: fields[0] as String,
      timestamp: fields[1] as DateTime?,
      outcome: fields[2] as UsageOutcome?,
      context: fields[3] as String?,
      regulationUsed: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UsageEvent obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.cardId)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.outcome)
      ..writeByte(3)
      ..write(obj.context)
      ..writeByte(4)
      ..write(obj.regulationUsed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
