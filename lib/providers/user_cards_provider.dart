import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/user_card.dart';

const _userCardsBoxName = 'user_cards';

final userCardsProvider =
    StateNotifierProvider<UserCardsNotifier, List<UserCard>>((ref) {
      return UserCardsNotifier();
    });

final pinnedUserCardsProvider = Provider<List<UserCard>>((ref) {
  return ref.watch(userCardsProvider).where((card) => card.pinned).toList();
});

class UserCardsNotifier extends StateNotifier<List<UserCard>> {
  UserCardsNotifier({bool persist = true})
    : _persist = persist,
      super(const []) {
    if (_persist) {
      _load();
    }
  }

  final bool _persist;
  Box<UserCard>? _box;

  Future<Box<UserCard>> _ensureBox() async {
    _box ??= await Hive.openBox<UserCard>(_userCardsBoxName);
    return _box!;
  }

  Future<void> _load() async {
    final box = await _ensureBox();
    state = _sorted(box.values.toList());
  }

  List<UserCard> _sorted(List<UserCard> cards) {
    final next = [...cards];
    next.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.savedAt.compareTo(a.savedAt);
    });
    return next;
  }

  UserCard? _findById(String cardId) {
    for (final card in state) {
      if (card.cardId == cardId) return card;
    }
    return null;
  }

  Future<void> upsert(UserCard card) async {
    if (!_persist) {
      final other = state.where((c) => c.cardId != card.cardId).toList();
      state = _sorted([card, ...other]);
      return;
    }

    final box = await _ensureBox();
    await box.put(card.cardId, card);
    await _load();
  }

  Future<void> save(String cardId, {bool pinned = false}) async {
    final existing = _findById(cardId);
    if (existing != null) {
      if (pinned && !existing.pinned) {
        await upsert(existing.copyWith(pinned: true));
      }
      return;
    }
    await upsert(UserCard(cardId: cardId, pinned: pinned));
  }

  Future<void> unsave(String cardId) async {
    if (!_persist) {
      state = state.where((card) => card.cardId != cardId).toList();
      return;
    }
    final box = await _ensureBox();
    await box.delete(cardId);
    await _load();
  }

  Future<void> pin(String cardId) async {
    await save(cardId, pinned: true);
    final existing = _findById(cardId);
    if (existing != null && !existing.pinned) {
      await upsert(existing.copyWith(pinned: true));
    }
  }

  Future<void> unpin(String cardId) async {
    final existing = _findById(cardId);
    if (existing == null || !existing.pinned) return;
    await upsert(existing.copyWith(pinned: false));
  }

  Future<void> incrementUsage(String cardId, {DateTime? usedAt}) async {
    final existing = _findById(cardId);
    final now = usedAt ?? DateTime.now();
    if (existing == null) {
      await upsert(UserCard(cardId: cardId, usageCount: 1, lastUsed: now));
      return;
    }

    await upsert(
      existing.copyWith(usageCount: existing.usageCount + 1, lastUsed: now),
    );
  }
}
