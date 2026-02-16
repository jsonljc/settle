// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nudge_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NudgeRecordAdapter extends TypeAdapter<NudgeRecord> {
  @override
  final int typeId = 54;

  @override
  NudgeRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NudgeRecord(
      nudgeType: fields[0] as NudgeType,
      sentAt: fields[1] as DateTime?,
      opened: fields[2] as bool,
      actedOn: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, NudgeRecord obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.nudgeType)
      ..writeByte(1)
      ..write(obj.sentAt)
      ..writeByte(2)
      ..write(obj.opened)
      ..writeByte(3)
      ..write(obj.actedOn);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NudgeRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
