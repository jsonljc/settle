// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_plan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DayPlanAdapter extends TypeAdapter<DayPlan> {
  @override
  final int typeId = 13;

  @override
  DayPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DayPlan(
      date: fields[0] as DateTime,
      sessions: (fields[1] as List?)?.cast<SleepSession>(),
      nightWakes: (fields[2] as List?)?.cast<NightWake>(),
    );
  }

  @override
  void write(BinaryWriter writer, DayPlan obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.sessions)
      ..writeByte(2)
      ..write(obj.nightWakes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
