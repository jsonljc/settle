// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approach.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ApproachAdapter extends TypeAdapter<Approach> {
  @override
  final int typeId = 0;

  @override
  Approach read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Approach.stayAndSupport;
      case 1:
        return Approach.checkAndReassure;
      case 2:
        return Approach.cueBased;
      case 3:
        return Approach.rhythmFirst;
      case 4:
        return Approach.extinction;
      default:
        return Approach.stayAndSupport;
    }
  }

  @override
  void write(BinaryWriter writer, Approach obj) {
    switch (obj) {
      case Approach.stayAndSupport:
        writer.writeByte(0);
        break;
      case Approach.checkAndReassure:
        writer.writeByte(1);
        break;
      case Approach.cueBased:
        writer.writeByte(2);
        break;
      case Approach.rhythmFirst:
        writer.writeByte(3);
        break;
      case Approach.extinction:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApproachAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AgeBracketAdapter extends TypeAdapter<AgeBracket> {
  @override
  final int typeId = 1;

  @override
  AgeBracket read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AgeBracket.newborn;
      case 1:
        return AgeBracket.twoToThreeMonths;
      case 2:
        return AgeBracket.fourToFiveMonths;
      case 3:
        return AgeBracket.sixToEightMonths;
      case 4:
        return AgeBracket.nineToTwelveMonths;
      case 5:
        return AgeBracket.twelveToEighteenMonths;
      case 6:
        return AgeBracket.nineteenToTwentyFourMonths;
      case 7:
        return AgeBracket.twoToThreeYears;
      case 8:
        return AgeBracket.threeToFourYears;
      case 9:
        return AgeBracket.fourToFiveYears;
      case 10:
        return AgeBracket.fiveToSixYears;
      default:
        return AgeBracket.newborn;
    }
  }

  @override
  void write(BinaryWriter writer, AgeBracket obj) {
    switch (obj) {
      case AgeBracket.newborn:
        writer.writeByte(0);
        break;
      case AgeBracket.twoToThreeMonths:
        writer.writeByte(1);
        break;
      case AgeBracket.fourToFiveMonths:
        writer.writeByte(2);
        break;
      case AgeBracket.sixToEightMonths:
        writer.writeByte(3);
        break;
      case AgeBracket.nineToTwelveMonths:
        writer.writeByte(4);
        break;
      case AgeBracket.twelveToEighteenMonths:
        writer.writeByte(5);
        break;
      case AgeBracket.nineteenToTwentyFourMonths:
        writer.writeByte(6);
        break;
      case AgeBracket.twoToThreeYears:
        writer.writeByte(7);
        break;
      case AgeBracket.threeToFourYears:
        writer.writeByte(8);
        break;
      case AgeBracket.fourToFiveYears:
        writer.writeByte(9);
        break;
      case AgeBracket.fiveToSixYears:
        writer.writeByte(10);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgeBracketAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FamilyStructureAdapter extends TypeAdapter<FamilyStructure> {
  @override
  final int typeId = 2;

  @override
  FamilyStructure read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FamilyStructure.twoParents;
      case 1:
        return FamilyStructure.singleParent;
      case 2:
        return FamilyStructure.withSupport;
      case 3:
        return FamilyStructure.other;
      case 4:
        return FamilyStructure.coParent;
      case 5:
        return FamilyStructure.blended;
      default:
        return FamilyStructure.twoParents;
    }
  }

  @override
  void write(BinaryWriter writer, FamilyStructure obj) {
    switch (obj) {
      case FamilyStructure.twoParents:
        writer.writeByte(0);
        break;
      case FamilyStructure.singleParent:
        writer.writeByte(1);
        break;
      case FamilyStructure.withSupport:
        writer.writeByte(2);
        break;
      case FamilyStructure.other:
        writer.writeByte(3);
        break;
      case FamilyStructure.coParent:
        writer.writeByte(4);
        break;
      case FamilyStructure.blended:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyStructureAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RegulationLevelAdapter extends TypeAdapter<RegulationLevel> {
  @override
  final int typeId = 43;

  @override
  RegulationLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RegulationLevel.calm;
      case 1:
        return RegulationLevel.stressed;
      case 2:
        return RegulationLevel.anxious;
      case 3:
        return RegulationLevel.angry;
      default:
        return RegulationLevel.calm;
    }
  }

  @override
  void write(BinaryWriter writer, RegulationLevel obj) {
    switch (obj) {
      case RegulationLevel.calm:
        writer.writeByte(0);
        break;
      case RegulationLevel.stressed:
        writer.writeByte(1);
        break;
      case RegulationLevel.anxious:
        writer.writeByte(2);
        break;
      case RegulationLevel.angry:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegulationLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PrimaryChallengeAdapter extends TypeAdapter<PrimaryChallenge> {
  @override
  final int typeId = 3;

  @override
  PrimaryChallenge read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PrimaryChallenge.fallingAsleep;
      case 1:
        return PrimaryChallenge.nightWaking;
      case 2:
        return PrimaryChallenge.shortNaps;
      case 3:
        return PrimaryChallenge.schedule;
      default:
        return PrimaryChallenge.fallingAsleep;
    }
  }

  @override
  void write(BinaryWriter writer, PrimaryChallenge obj) {
    switch (obj) {
      case PrimaryChallenge.fallingAsleep:
        writer.writeByte(0);
        break;
      case PrimaryChallenge.nightWaking:
        writer.writeByte(1);
        break;
      case PrimaryChallenge.shortNaps:
        writer.writeByte(2);
        break;
      case PrimaryChallenge.schedule:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrimaryChallengeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FeedingTypeAdapter extends TypeAdapter<FeedingType> {
  @override
  final int typeId = 4;

  @override
  FeedingType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FeedingType.breast;
      case 1:
        return FeedingType.formula;
      case 2:
        return FeedingType.combo;
      case 3:
        return FeedingType.solids;
      default:
        return FeedingType.breast;
    }
  }

  @override
  void write(BinaryWriter writer, FeedingType obj) {
    switch (obj) {
      case FeedingType.breast:
        writer.writeByte(0);
        break;
      case FeedingType.formula:
        writer.writeByte(1);
        break;
      case FeedingType.combo:
        writer.writeByte(2);
        break;
      case FeedingType.solids:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedingTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
