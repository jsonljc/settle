import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _boxName = 'weekly_reflection_meta';
const _keyDismissedWeek = 'dismissed_week';

/// Week key for comparison: YYYY-MM-DD of Monday of the week containing [date].
String weekKeyFor(DateTime date) {
  final monday = date.subtract(Duration(days: date.weekday - 1));
  return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
}

final weeklyReflectionProvider =
    StateNotifierProvider<WeeklyReflectionNotifier, String?>((ref) {
      return WeeklyReflectionNotifier();
    });

/// True if the user dismissed the weekly reflection banner this week (Monday–Sunday).
final weeklyReflectionDismissedThisWeekProvider = Provider<bool>((ref) {
  final dismissedWeek = ref.watch(weeklyReflectionProvider);
  if (dismissedWeek == null) return false;
  return dismissedWeek == weekKeyFor(DateTime.now());
});

class WeeklyReflectionNotifier extends StateNotifier<String?> {
  WeeklyReflectionNotifier() : super(null) {
    _load();
  }

  Box<dynamic>? _box;

  Future<Box<dynamic>> _ensureBox() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
    return _box!;
  }

  Future<void> _load() async {
    try {
      final box = await _ensureBox();
      final raw = box.get(_keyDismissedWeek);
      if (raw is String) state = raw;
    } catch (_) {}
  }

  Future<void> dismissThisWeek() async {
    final key = weekKeyFor(DateTime.now());
    state = key;
    try {
      final box = await _ensureBox();
      await box.put(_keyDismissedWeek, key);
    } catch (_) {}
  }
}
