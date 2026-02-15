// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'baby_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BabyProfileAdapter extends TypeAdapter<BabyProfile> {
  @override
  final int typeId = 10;

  @override
  BabyProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BabyProfile(
      name: fields[0] as String,
      ageBracket: fields[1] as AgeBracket,
      familyStructure: fields[2] as FamilyStructure,
      approach: fields[3] as Approach,
      primaryChallenge: fields[4] as PrimaryChallenge,
      feedingType: fields[5] as FeedingType,
      tantrumProfile: fields[7] as TantrumProfile?,
      focusMode: fields[8] as FocusMode?,
      createdAt: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BabyProfile obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.ageBracket)
      ..writeByte(2)
      ..write(obj.familyStructure)
      ..writeByte(3)
      ..write(obj.approach)
      ..writeByte(4)
      ..write(obj.primaryChallenge)
      ..writeByte(5)
      ..write(obj.feedingType)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.tantrumProfile)
      ..writeByte(8)
      ..write(obj.focusMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BabyProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
