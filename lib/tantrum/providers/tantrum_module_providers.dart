import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/tantrum_card.dart';
import '../models/tantrum_lesson.dart';
import '../services/tantrum_registry_service.dart';

const _protocolBoxName = 'tantrum_protocol';
const _pinnedKey = 'pinned_ids';
const _maxPinned = 10;

final tantrumCardsProvider = FutureProvider<List<TantrumCard>>((ref) async {
  return TantrumRegistryService.instance.getCards();
});

final tantrumLessonsProvider = FutureProvider<List<TantrumLesson>>((ref) async {
  return TantrumRegistryService.instance.getLessons();
});

final tantrumCardByIdProvider =
    FutureProvider.family<TantrumCard?, String>((ref, id) async {
  return TantrumRegistryService.instance.getCardById(id);
});

final tantrumLessonByIdProvider =
    FutureProvider.family<TantrumLesson?, String>((ref, id) async {
  return TantrumRegistryService.instance.getLessonById(id);
});

/// Pinned card IDs for Protocol (5–10 cards stored locally).
final protocolPinnedIdsProvider =
    StateNotifierProvider<ProtocolPinnedNotifier, List<String>>((ref) {
  return ProtocolPinnedNotifier();
});

/// Protocol cards (resolved from pinned IDs). Order matches pinned list.
final protocolCardsProvider = Provider<List<TantrumCard>>((ref) {
  final pinnedIds = ref.watch(protocolPinnedIdsProvider);
  final cardsAsync = ref.watch(tantrumCardsProvider);
  return cardsAsync.when(
    data: (all) {
      final byId = {for (final c in all) c.id: c};
      return pinnedIds
          .map((id) => byId[id])
          .whereType<TantrumCard>()
          .toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

class ProtocolPinnedNotifier extends StateNotifier<List<String>> {
  ProtocolPinnedNotifier() : super([]) {
    _load();
  }

  Box<dynamic>? _box;

  Future<Box<dynamic>> _ensureBox() async {
    _box ??= await Hive.openBox<dynamic>(_protocolBoxName);
    return _box!;
  }

  Future<void> _load() async {
    final box = await _ensureBox();
    final raw = box.get(_pinnedKey);
    if (raw == null || (raw is String && raw.isEmpty)) {
      state = [];
      return;
    }
    try {
      final list = jsonDecode(raw.toString()) as List<dynamic>;
      state = list.map((e) => e.toString()).toList();
    } catch (_) {
      state = [];
    }
  }

  Future<void> _save(List<String> ids) async {
    final box = await _ensureBox();
    await box.put(_pinnedKey, jsonEncode(ids));
    state = List.from(ids);
  }

  Future<bool> pin(String cardId) async {
    if (state.contains(cardId)) return true;
    if (state.length >= _maxPinned) return false;
    await _save([...state, cardId]);
    return true;
  }

  Future<void> unpin(String cardId) async {
    if (!state.contains(cardId)) return;
    await _save(state.where((id) => id != cardId).toList());
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || newIndex < 0 || oldIndex >= state.length || newIndex >= state.length) return;
    final list = List<String>.from(state);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    await _save(list);
  }

  bool get isAtMax => state.length >= _maxPinned;
}

/// Resolves the card to show in Crisis View: by id, or first protocol card, or first from registry.
final effectiveCrisisCardProvider =
    Provider.family<AsyncValue<TantrumCard?>, String?>((ref, cardId) {
  if (cardId != null && cardId.isNotEmpty) {
    return ref.watch(tantrumCardByIdProvider(cardId)).when(
          data: (c) => AsyncValue.data(c),
          loading: () => const AsyncValue.loading(),
          error: (e, s) => AsyncValue.error(e, s),
        );
  }
  final protocol = ref.watch(protocolCardsProvider);
  if (protocol.isNotEmpty) return AsyncValue.data(protocol.first);
  final all = ref.watch(tantrumCardsProvider);
  return all.when(
    data: (list) => AsyncValue.data(list.isNotEmpty ? list.first : null),
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});
