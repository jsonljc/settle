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

  ResetEvent({
    required this.id,
    required this.timestamp,
    this.context,
  });
}
