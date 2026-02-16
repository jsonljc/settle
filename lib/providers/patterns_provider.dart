import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/pattern_insight.dart';

const _patternsBoxName = 'patterns';

final patternsProvider =
    StateNotifierProvider<PatternsNotifier, List<PatternInsight>>((ref) {
      return PatternsNotifier();
    });

class PatternsNotifier extends StateNotifier<List<PatternInsight>> {
  PatternsNotifier({bool persist = true})
    : _persist = persist,
      super(const []) {
    if (_persist) {
      _load();
    }
  }

  final bool _persist;
  Box<PatternInsight>? _box;

  Future<Box<PatternInsight>> _ensureBox() async {
    _box ??= await Hive.openBox<PatternInsight>(_patternsBoxName);
    return _box!;
  }

  Future<void> _load() async {
    final box = await _ensureBox();
    final insights = box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = insights;
  }

  Future<void> setInsights(List<PatternInsight> insights) async {
    if (!_persist) {
      state = [...insights]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return;
    }

    final box = await _ensureBox();
    await box.clear();
    await box.addAll(insights);
    await _load();
  }

  Future<void> addInsight(PatternInsight insight) async {
    if (!_persist) {
      state = [insight, ...state]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return;
    }

    final box = await _ensureBox();
    await box.add(insight);
    await _load();
  }
}
