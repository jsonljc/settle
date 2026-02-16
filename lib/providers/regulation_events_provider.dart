import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/regulation_event.dart';
import '../models/v2_enums.dart';

const _regulationEventsBoxName = 'regulation_events';

final regulationEventsProvider =
    StateNotifierProvider<RegulationEventsNotifier, List<RegulationEvent>>((
      ref,
    ) {
      return RegulationEventsNotifier();
    });

class RegulationEventsNotifier extends StateNotifier<List<RegulationEvent>> {
  RegulationEventsNotifier({bool persist = true})
    : _persist = persist,
      super(const []) {
    if (_persist) {
      _load();
    }
  }

  final bool _persist;
  Box<RegulationEvent>? _box;

  Future<Box<RegulationEvent>> _ensureBox() async {
    _box ??= await Hive.openBox<RegulationEvent>(_regulationEventsBoxName);
    return _box!;
  }

  Future<void> _load() async {
    final box = await _ensureBox();
    final events = box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = events;
  }

  Future<void> addEvent(RegulationEvent event) async {
    if (!_persist) {
      state = [event, ...state]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return;
    }

    final box = await _ensureBox();
    await box.add(event);
    await _load();
  }

  Future<void> log({
    required RegulationTrigger trigger,
    bool completed = false,
    int durationSeconds = 0,
    DateTime? timestamp,
  }) {
    return addEvent(
      RegulationEvent(
        trigger: trigger,
        completed: completed,
        durationSeconds: durationSeconds,
        timestamp: timestamp,
      ),
    );
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
