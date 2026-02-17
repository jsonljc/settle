import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _boxName = 'settings';
const _key = 'disruption_mode';

/// Tracks whether disruption mode is active.
///
/// When enabled:
/// - Wake windows expand by 20%
/// - Night guidance text is softened (gentler language, shorter waits)
///
/// Persisted to Hive so the toggle survives app restarts.
final disruptionProvider = StateNotifierProvider<DisruptionNotifier, bool>((
  ref,
) {
  return DisruptionNotifier();
});

class DisruptionNotifier extends StateNotifier<bool> {
  DisruptionNotifier() : super(false) {
    _load();
  }

  late Box<dynamic> _box;

  Future<void> _load() async {
    _box = await Hive.openBox(_boxName);
    state = _box.get(_key, defaultValue: false) as bool;
  }

  Future<void> toggle() async {
    state = !state;
    await _box.put(_key, state);
  }

  Future<void> set(bool value) async {
    state = value;
    await _box.put(_key, value);
  }
}
