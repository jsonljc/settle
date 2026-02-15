// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'night_wake.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NightWakeAdapter extends TypeAdapter<NightWake> {
  @override
  final int typeId = 12;

  @override
  NightWake read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NightWake(
      occurredAt: fields[0] as DateTime,
      fed: fields[1] as bool,
      resettleMinutes: fields[2] as int?,
      notes: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NightWake obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.occurredAt)
      ..writeByte(1)
      ..write(obj.fed)
      ..writeByte(2)
      ..write(obj.resettleMinutes)
      ..writeByte(3)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NightWakeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
