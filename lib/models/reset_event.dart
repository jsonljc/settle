import 'package:hive_flutter/hive_flutter.dart';

part 'reset_event.g.dart';

/// A single "reset" entry-point event for the product spine.
/// Persisted for analytics and optional replay; does not affect flow structure.
@HiveType(typeId: 60)
class ResetEvent extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  /// Optional context: general, sleep, tantrum. Stored as string for schema simplicity.
  @HiveField(2)
  final String? context;

  /// Who the reset was for: "self" or "child".
  @HiveField(3)
  final String? state;

  /// Card ids shown this session (order seen).
  @HiveField(4)
  final List<String> cardIdsSeen;

  /// Card id kept in playbook, or null if user closed without keeping.
  @HiveField(5)
  final String? cardIdKept;

  ResetEvent({
    required this.id,
    required this.timestamp,
    this.context,
    this.state,
    this.cardIdsSeen = const [],
    this.cardIdKept,
  });
}
