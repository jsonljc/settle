// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reset_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ResetEventAdapter extends TypeAdapter<ResetEvent> {
  @override
  final int typeId = 60;

  @override
  ResetEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ResetEvent(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      context: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ResetEvent obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.context);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResetEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
