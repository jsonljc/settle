// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'regulation_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RegulationEventAdapter extends TypeAdapter<RegulationEvent> {
  @override
  final int typeId = 52;

  @override
  RegulationEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RegulationEvent(
      timestamp: fields[0] as DateTime?,
      trigger: fields[1] as RegulationTrigger,
      completed: fields[2] as bool,
      durationSeconds: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, RegulationEvent obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.trigger)
      ..writeByte(2)
      ..write(obj.completed)
      ..writeByte(3)
      ..write(obj.durationSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegulationEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
