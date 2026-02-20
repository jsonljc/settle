import 'package:hive_flutter/hive_flutter.dart';

/// Persists "Close the moment" sheet suppression: if user taps "I'm good"
/// 3+ times in a row, we don't show the sheet for 7 days.
class CloseMomentSuppress {
  CloseMomentSuppress._();

  static const _boxName = 'close_moment_suppress';
  static const _keyConsecutive = 'consecutive_im_good';
  static const _keySuppressUntil = 'suppress_until_iso';

  static Box<dynamic>? _box;

  static Future<Box<dynamic>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<dynamic>(_boxName);
    return _box!;
  }

  /// Returns true if the Close moment sheet should be shown (not suppressed).
  static Future<bool> shouldShowCloseMomentSheet() async {
    final box = await _getBox();
    final suppressUntilIso = box.get(_keySuppressUntil) as String?;
    if (suppressUntilIso == null || suppressUntilIso.isEmpty) return true;
    final suppressUntil = DateTime.tryParse(suppressUntilIso);
    if (suppressUntil == null) return true;
    if (DateTime.now().isBefore(suppressUntil)) return false;
    // Suppression expired; clear so state stays clean
    await box.put(_keySuppressUntil, null);
    await box.put(_keyConsecutive, 0);
    return true;
  }

  /// Call when user taps "I'm good". Increments consecutive count; if >= 3, suppresses for 7 days.
  static Future<void> recordImGood() async {
    final box = await _getBox();
    final count = (box.get(_keyConsecutive) as int?) ?? 0;
    final next = count + 1;
    await box.put(_keyConsecutive, next);
    if (next >= 3) {
      final until = DateTime.now().add(const Duration(days: 7));
      await box.put(_keySuppressUntil, until.toIso8601String());
    }
  }

  /// Call when user taps "Reset · 15s". Resets consecutive count so sheet shows again next time.
  static Future<void> recordReset() async {
    final box = await _getBox();
    await box.put(_keyConsecutive, 0);
    await box.put(_keySuppressUntil, null);
  }
}
