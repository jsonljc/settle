import 'package:hive_flutter/hive_flutter.dart';

part 'user_card.g.dart';

@HiveType(typeId: 50)
class UserCard extends HiveObject {
  @HiveField(0)
  String cardId;

  @HiveField(1)
  bool pinned;

  @HiveField(2)
  DateTime savedAt;

  @HiveField(3)
  int usageCount;

  @HiveField(4)
  DateTime? lastUsed;

  UserCard({
    required this.cardId,
    this.pinned = false,
    DateTime? savedAt,
    this.usageCount = 0,
    this.lastUsed,
  }) : savedAt = savedAt ?? DateTime.now();

  UserCard copyWith({
    String? cardId,
    bool? pinned,
    DateTime? savedAt,
    int? usageCount,
    DateTime? lastUsed,
  }) {
    return UserCard(
      cardId: cardId ?? this.cardId,
      pinned: pinned ?? this.pinned,
      savedAt: savedAt ?? this.savedAt,
      usageCount: usageCount ?? this.usageCount,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
}
