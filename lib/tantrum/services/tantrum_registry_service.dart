import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/tantrum_card.dart';
import '../models/tantrum_lesson.dart';

/// Loads tantrum cards and lessons from assets/guidance/tantrum_registry_v1.json.
/// Does not touch Sleep or Help Now registries.
class TantrumRegistryService {
  TantrumRegistryService._();

  static final TantrumRegistryService instance = TantrumRegistryService._();

  static const _registryPath = 'assets/guidance/tantrum_registry_v1.json';

  List<TantrumCard>? _cards;
  List<TantrumLesson>? _lessons;

  Future<void> _ensureLoaded() async {
    if (_cards != null) return;
    final raw = await rootBundle.loadString(_registryPath);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final cardsList = map['cards'] as List<dynamic>? ?? [];
    final lessonsList = map['lessons'] as List<dynamic>? ?? [];
    _cards = cardsList
        .map((e) => TantrumCard.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    _lessons = lessonsList
        .map((e) =>
            TantrumLesson.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<TantrumCard>> getCards() async {
    await _ensureLoaded();
    return List.unmodifiable(_cards!);
  }

  Future<List<TantrumLesson>> getLessons() async {
    await _ensureLoaded();
    return List.unmodifiable(_lessons!);
  }

  Future<TantrumCard?> getCardById(String id) async {
    await _ensureLoaded();
    try {
      return _cards!.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<TantrumLesson?> getLessonById(String id) async {
    await _ensureLoaded();
    try {
      return _lessons!.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }
}
