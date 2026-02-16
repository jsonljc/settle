import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/tantrum_card.dart';
import '../models/tantrum_lesson.dart';
import '../services/tantrum_registry_service.dart';

const _deckBoxName = 'tantrum_deck';
const _deckStateKey = 'deck_state_v2';
const _legacyProtocolBoxName = 'tantrum_protocol';
const _legacyPinnedKey = 'pinned_ids';
const maxPinnedCards = 3;

final tantrumCardsProvider = FutureProvider<List<TantrumCard>>((ref) async {
  return TantrumRegistryService.instance.getCards();
});

final tantrumLessonsProvider = FutureProvider<List<TantrumLesson>>((ref) async {
  return TantrumRegistryService.instance.getLessons();
});

final tantrumCardByIdProvider = FutureProvider.family<TantrumCard?, String>((
  ref,
  id,
) async {
  return TantrumRegistryService.instance.getCardById(id);
});

final tantrumLessonByIdProvider = FutureProvider.family<TantrumLesson?, String>(
  (ref, id) async {
    return TantrumRegistryService.instance.getLessonById(id);
  },
);

class TantrumDeckState {
  const TantrumDeckState({
    this.savedIds = const [],
    this.favoriteIds = const [],
    this.pinnedIds = const [],
    this.purchasedPackIds = const {},
  });

  final List<String> savedIds;
  final List<String> favoriteIds;
  final List<String> pinnedIds;
  final Set<String> purchasedPackIds;

  bool isSaved(String cardId) => savedIds.contains(cardId);
  bool isFavorite(String cardId) => favoriteIds.contains(cardId);
  bool isPinned(String cardId) => pinnedIds.contains(cardId);

  TantrumDeckState copyWith({
    List<String>? savedIds,
    List<String>? favoriteIds,
    List<String>? pinnedIds,
    Set<String>? purchasedPackIds,
  }) {
    return TantrumDeckState(
      savedIds: savedIds ?? this.savedIds,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      pinnedIds: pinnedIds ?? this.pinnedIds,
      purchasedPackIds: purchasedPackIds ?? this.purchasedPackIds,
    );
  }

  factory TantrumDeckState.fromJson(Map<String, dynamic> json) {
    List<String> readList(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      return _unique(raw.map((e) => e.toString()));
    }

    final saved = readList('savedIds');
    final favorites = readList(
      'favoriteIds',
    ).where((id) => saved.contains(id)).toList();
    final pinned = readList(
      'pinnedIds',
    ).where((id) => saved.contains(id)).take(maxPinnedCards).toList();

    final purchasedRaw = json['purchasedPackIds'];
    final purchased = purchasedRaw is List
        ? purchasedRaw.map((e) => e.toString()).toSet()
        : <String>{};

    return TantrumDeckState(
      savedIds: saved,
      favoriteIds: favorites,
      pinnedIds: pinned,
      purchasedPackIds: purchased,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'savedIds': savedIds,
      'favoriteIds': favoriteIds,
      'pinnedIds': pinnedIds,
      'purchasedPackIds': purchasedPackIds.toList(),
    };
  }

  static List<String> _unique(Iterable<String> ids) {
    final seen = <String>{};
    final out = <String>[];
    for (final id in ids) {
      final trimmed = id.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) continue;
      seen.add(trimmed);
      out.add(trimmed);
    }
    return out;
  }
}

final deckStateProvider =
    StateNotifierProvider<TantrumDeckNotifier, TantrumDeckState>((ref) {
      return TantrumDeckNotifier();
    });

class TantrumDeckNotifier extends StateNotifier<TantrumDeckState> {
  TantrumDeckNotifier({bool persist = true})
    : _persist = persist,
      super(const TantrumDeckState()) {
    if (_persist) _load();
  }

  final bool _persist;
  Box<dynamic>? _box;

  Future<Box<dynamic>> _ensureBox() async {
    _box ??= await Hive.openBox<dynamic>(_deckBoxName);
    return _box!;
  }

  Future<void> _load() async {
    final box = await _ensureBox();
    final raw = box.get(_deckStateKey);

    Map<String, dynamic>? map;
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        map = Map<String, dynamic>.from(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        map = null;
      }
    } else if (raw is Map) {
      map = Map<String, dynamic>.from(raw);
    }

    if (map != null) {
      state = TantrumDeckState.fromJson(map);
      return;
    }

    await _migrateLegacyProtocol();
  }

  Future<void> _migrateLegacyProtocol() async {
    final legacy = await Hive.openBox<dynamic>(_legacyProtocolBoxName);
    final raw = legacy.get(_legacyPinnedKey);
    if (raw == null) {
      state = const TantrumDeckState();
      return;
    }

    try {
      final list = jsonDecode(raw.toString()) as List<dynamic>;
      final ids = TantrumDeckState._unique(list.map((e) => e.toString()));
      final migrated = TantrumDeckState(
        savedIds: ids,
        pinnedIds: ids.take(maxPinnedCards).toList(),
      );
      await _save(migrated);
    } catch (_) {
      state = const TantrumDeckState();
    }
  }

  Future<void> _save(TantrumDeckState next) async {
    if (!_persist) {
      state = next;
      return;
    }
    final box = await _ensureBox();
    await box.put(_deckStateKey, jsonEncode(next.toJson()));
    state = next;
  }

  Future<void> toggleSaved(String cardId) async {
    if (state.isSaved(cardId)) {
      await unsave(cardId);
      return;
    }
    await save(cardId);
  }

  Future<void> save(String cardId) async {
    if (state.isSaved(cardId)) return;
    final saved = [...state.savedIds, cardId];
    await _save(state.copyWith(savedIds: saved));
  }

  Future<void> unsave(String cardId) async {
    if (!state.isSaved(cardId)) return;
    final saved = state.savedIds.where((id) => id != cardId).toList();
    final favorites = state.favoriteIds.where((id) => id != cardId).toList();
    final pinned = state.pinnedIds.where((id) => id != cardId).toList();
    await _save(
      state.copyWith(
        savedIds: saved,
        favoriteIds: favorites,
        pinnedIds: pinned,
      ),
    );
  }

  Future<void> toggleFavorite(String cardId) async {
    if (state.isFavorite(cardId)) {
      final favorites = state.favoriteIds.where((id) => id != cardId).toList();
      await _save(state.copyWith(favoriteIds: favorites));
      return;
    }

    final saved = state.isSaved(cardId)
        ? state.savedIds
        : [...state.savedIds, cardId];
    final favorites = [...state.favoriteIds, cardId];
    await _save(state.copyWith(savedIds: saved, favoriteIds: favorites));
  }

  Future<bool> pin(String cardId) async {
    if (state.isPinned(cardId)) return true;
    if (state.pinnedIds.length >= maxPinnedCards) return false;

    final saved = state.isSaved(cardId)
        ? state.savedIds
        : [...state.savedIds, cardId];
    final pinned = [...state.pinnedIds, cardId];
    await _save(state.copyWith(savedIds: saved, pinnedIds: pinned));
    return true;
  }

  Future<void> unpin(String cardId) async {
    if (!state.isPinned(cardId)) return;
    final pinned = state.pinnedIds.where((id) => id != cardId).toList();
    await _save(state.copyWith(pinnedIds: pinned));
  }

  Future<void> reorderPinned(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || newIndex < 0) return;
    if (oldIndex >= state.pinnedIds.length ||
        newIndex >= state.pinnedIds.length) {
      return;
    }

    final list = List<String>.from(state.pinnedIds);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    await _save(state.copyWith(pinnedIds: list));
  }

  Future<void> togglePackPurchased(String packId) async {
    if (packId == 'base') return;
    final next = Set<String>.from(state.purchasedPackIds);
    if (next.contains(packId)) {
      next.remove(packId);
    } else {
      next.add(packId);
    }
    await _save(state.copyWith(purchasedPackIds: next));
  }

  bool get isAtPinnedMax => state.pinnedIds.length >= maxPinnedCards;
}

final deckSavedIdsProvider = Provider<List<String>>(
  (ref) => ref.watch(deckStateProvider).savedIds,
);

final deckFavoriteIdsProvider = Provider<List<String>>(
  (ref) => ref.watch(deckStateProvider).favoriteIds,
);

final deckPinnedIdsProvider = Provider<List<String>>(
  (ref) => ref.watch(deckStateProvider).pinnedIds,
);

final deckPurchasedPackIdsProvider = Provider<Set<String>>(
  (ref) => ref.watch(deckStateProvider).purchasedPackIds,
);

List<TantrumCard> _resolveCards(List<TantrumCard> all, List<String> ids) {
  final byId = {for (final card in all) card.id: card};
  return ids.map((id) => byId[id]).whereType<TantrumCard>().toList();
}

final deckSavedCardsProvider = Provider<List<TantrumCard>>((ref) {
  final ids = ref.watch(deckSavedIdsProvider);
  final all = ref.watch(tantrumCardsProvider);
  return all.when(
    data: (cards) => _resolveCards(cards, ids),
    loading: () => const [],
    error: (_, __) => const [],
  );
});

final deckPinnedCardsProvider = Provider<List<TantrumCard>>((ref) {
  final ids = ref.watch(deckPinnedIdsProvider);
  final all = ref.watch(tantrumCardsProvider);
  return all.when(
    data: (cards) => _resolveCards(cards, ids),
    loading: () => const [],
    error: (_, __) => const [],
  );
});

final deckFavoriteCardsProvider = Provider<List<TantrumCard>>((ref) {
  final ids = ref.watch(deckFavoriteIdsProvider);
  final all = ref.watch(tantrumCardsProvider);
  return all.when(
    data: (cards) => _resolveCards(cards, ids),
    loading: () => const [],
    error: (_, __) => const [],
  );
});

/// Backward-compatible alias retained for older callsites.
final protocolPinnedIdsProvider = Provider<List<String>>(
  (ref) => ref.watch(deckPinnedIdsProvider),
);

/// Backward-compatible alias retained for older callsites.
final protocolCardsProvider = Provider<List<TantrumCard>>(
  (ref) => ref.watch(deckPinnedCardsProvider),
);

/// Resolves the card to show in Crisis View: by id, or first pinned card, or first from registry.
final effectiveCrisisCardProvider =
    Provider.family<AsyncValue<TantrumCard?>, String?>((ref, cardId) {
      if (cardId != null && cardId.isNotEmpty) {
        return ref
            .watch(tantrumCardByIdProvider(cardId))
            .when(
              data: (c) => AsyncValue.data(c),
              loading: () => const AsyncValue.loading(),
              error: (e, s) => AsyncValue.error(e, s),
            );
      }
      final pinned = ref.watch(deckPinnedCardsProvider);
      if (pinned.isNotEmpty) return AsyncValue.data(pinned.first);
      final all = ref.watch(tantrumCardsProvider);
      return all.when(
        data: (list) => AsyncValue.data(list.isNotEmpty ? list.first : null),
        loading: () => const AsyncValue.loading(),
        error: (e, s) => AsyncValue.error(e, s),
      );
    });
