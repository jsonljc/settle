import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/nudge_record.dart';
import '../models/v2_enums.dart';

const _nudgesBoxName = 'nudges';

final nudgesProvider = StateNotifierProvider<NudgesNotifier, List<NudgeRecord>>(
  (ref) {
    return NudgesNotifier();
  },
);

class NudgesNotifier extends StateNotifier<List<NudgeRecord>> {
  NudgesNotifier({bool persist = true}) : _persist = persist, super(const []) {
    if (_persist) {
      _load();
    }
  }

  final bool _persist;
  Box<NudgeRecord>? _box;

  Future<Box<NudgeRecord>> _ensureBox() async {
    _box ??= await Hive.openBox<NudgeRecord>(_nudgesBoxName);
    return _box!;
  }

  Future<void> _load() async {
    final box = await _ensureBox();
    final records = box.values.toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    state = records;
  }

  Future<void> addRecord(NudgeRecord record) async {
    if (!_persist) {
      state = [record, ...state]..sort((a, b) => b.sentAt.compareTo(a.sentAt));
      return;
    }

    final box = await _ensureBox();
    await box.add(record);
    await _load();
  }

  Future<void> log(NudgeType type, {DateTime? sentAt}) {
    return addRecord(NudgeRecord(nudgeType: type, sentAt: sentAt));
  }

  Future<void> clear() async {
    if (!_persist) {
      state = const [];
      return;
    }

    final box = await _ensureBox();
    await box.clear();
    state = const [];
  }
}
