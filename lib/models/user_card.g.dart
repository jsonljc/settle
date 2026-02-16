// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_card.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserCardAdapter extends TypeAdapter<UserCard> {
  @override
  final int typeId = 50;

  @override
  UserCard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserCard(
      cardId: fields[0] as String,
      pinned: fields[1] as bool,
      savedAt: fields[2] as DateTime?,
      usageCount: fields[3] as int,
      lastUsed: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserCard obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.cardId)
      ..writeByte(1)
      ..write(obj.pinned)
      ..writeByte(2)
      ..write(obj.savedAt)
      ..writeByte(3)
      ..write(obj.usageCount)
      ..writeByte(4)
      ..write(obj.lastUsed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserCardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
