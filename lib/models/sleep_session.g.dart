// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SleepSessionAdapter extends TypeAdapter<SleepSession> {
  @override
  final int typeId = 11;

  @override
  SleepSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SleepSession(
      startedAt: fields[0] as DateTime,
      endedAt: fields[1] as DateTime?,
      isNight: fields[2] as bool,
      notes: fields[3] as String?,
      wakeWindowAtStart: fields[4] as int?,
      sleepOnsetLatency: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, SleepSession obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.startedAt)
      ..writeByte(1)
      ..write(obj.endedAt)
      ..writeByte(2)
      ..write(obj.isNight)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.wakeWindowAtStart)
      ..writeByte(5)
      ..write(obj.sleepOnsetLatency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
