import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/usage_event.dart';
import '../models/v2_enums.dart';

const _usageEventsBoxName = 'usage_events';

final usageEventsProvider =
    StateNotifierProvider<UsageEventsNotifier, List<UsageEvent>>((ref) {
      return UsageEventsNotifier();
    });

class UsageEventsNotifier extends StateNotifier<List<UsageEvent>> {
  UsageEventsNotifier({bool persist = true})
    : _persist = persist,
      super(const []) {
    if (_persist) {
      _load();
    }
  }

  final bool _persist;
  Box<UsageEvent>? _box;

  Future<Box<UsageEvent>> _ensureBox() async {
    _box ??= await Hive.openBox<UsageEvent>(_usageEventsBoxName);
    return _box!;
  }

  Future<void> _load() async {
    final box = await _ensureBox();
    final events = box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = events;
  }

  Future<void> addEvent(UsageEvent event) async {
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
    required String cardId,
    UsageOutcome? outcome,
    String? context,
    bool regulationUsed = false,
    DateTime? timestamp,
  }) {
    return addEvent(
      UsageEvent(
        cardId: cardId,
        outcome: outcome,
        context: context,
        regulationUsed: regulationUsed,
        timestamp: timestamp,
      ),
    );
  }

  List<UsageEvent> eventsForCard(String cardId) {
    return state.where((event) => event.cardId == cardId).toList();
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
