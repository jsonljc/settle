import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../models/repair_card.dart';

/// Loads and queries repair cards from bundled seed content.
/// Content layer only — no UI. Weights reserved for future weighted selection.
class CardRepository {
  CardRepository._();

  static final CardRepository instance = CardRepository._();
  static const _seedPath = 'assets/guidance/repair_cards_seed.json';

  List<RepairCard>? _cards;
  final Random _rng = Random();

  Future<void> _ensureLoaded() async {
    if (_cards != null) return;
    final raw = await rootBundle.loadString(_seedPath);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final list = map['cards'] as List<dynamic>? ?? [];
    _cards = list
        .whereType<Map>()
        .map((e) => RepairCard.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Loads and returns all cards.
  Future<List<RepairCard>> loadAll() async {
    await _ensureLoaded();
    return List.unmodifiable(_cards!);
  }

  /// Returns the repair card with the given id, or null if not found.
  Future<RepairCard?> getById(String id) async {
    await _ensureLoaded();
    try {
      return _cards!.firstWhere((c) => c.id == id);
    } on StateError {
      return null;
    }
  }

  /// Filters by context and optional state. Omitted filters are not applied.
  Future<List<RepairCard>> filter({
    RepairCardContext? context,
    RepairCardState? state,
  }) async {
    await _ensureLoaded();
    var list = _cards!;
    if (context != null) {
      list = list.where((c) => c.context == context).toList();
    }
    if (state != null) {
      list = list.where((c) => c.state == state).toList();
    }
    return List.unmodifiable(list);
  }

  /// Returns one card from the filtered set using weighted-random selection.
  /// Weight = warmthWeight + structureWeight (both in [0,1]), so higher warmth
  /// or structure increases chance of being picked. Returns null if no match.
  Future<RepairCard?> pickOne({
    RepairCardContext? context,
    RepairCardState? state,
  }) async {
    final list = await filter(context: context, state: state);
    if (list.isEmpty) return null;
    return _weightedPick(list);
  }

  /// Like [pickOne] but excludes cards whose id is in [excludeIds].
  Future<RepairCard?> pickOneExcluding({
    Set<String> excludeIds = const {},
    RepairCardContext? context,
    RepairCardState? state,
  }) async {
    final list = await filter(context: context, state: state);
    final available = list.where((c) => !excludeIds.contains(c.id)).toList();
    if (available.isEmpty) return null;
    return _weightedPick(available);
  }

  /// Picks one card from [list] with probability proportional to
  /// (warmthWeight + structureWeight). Minimum weight 0.01 so every card is pickable.
  RepairCard _weightedPick(List<RepairCard> list) {
    final weights = list.map((c) {
      final w = c.warmthWeight + c.structureWeight;
      return w < 0.01 ? 0.01 : w;
    }).toList();
    final sum = weights.fold<double>(0, (a, b) => a + b);
    var r = _rng.nextDouble() * sum;
    for (var i = 0; i < list.length; i++) {
      r -= weights[i];
      if (r <= 0) return list[i];
    }
    return list.last;
  }
}
