import 'package:hive_flutter/hive_flutter.dart';

part 'family_member.g.dart';

/// Local persisted family/caregiver member for Family tab (MVP, no backend sync).
@HiveType(typeId: 59)
class FamilyMember extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String role;

  @HiveField(3)
  DateTime invitedAt;

  FamilyMember({
    required this.id,
    required this.name,
    required this.role,
    DateTime? invitedAt,
  }) : invitedAt = invitedAt ?? DateTime.now();

  FamilyMember copyWith({
    String? id,
    String? name,
    String? role,
    DateTime? invitedAt,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      invitedAt: invitedAt ?? this.invitedAt,
    );
  }
}
