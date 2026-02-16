import 'dart:convert';

import 'package:flutter/services.dart';

class CardMatchRule {
  const CardMatchRule({
    required this.trigger,
    this.intensity,
    this.parentReaction,
  });

  final String trigger;
  final String? intensity;
  final String? parentReaction;

  bool get isTriggerOnly => intensity == null && parentReaction == null;

  int get specificity {
    var value = 1;
    if (intensity != null) value += 1;
    if (parentReaction != null) value += 1;
    return value;
  }

  bool matches({
    required String trigger,
    String? intensity,
    String? parentReaction,
  }) {
    if (this.trigger != trigger) return false;
    if (this.intensity != null && this.intensity != intensity) return false;
    if (this.parentReaction != null && this.parentReaction != parentReaction) {
      return false;
    }
    return true;
  }

  factory CardMatchRule.fromJson(Map<String, dynamic> json) {
    final intensity = (json['intensity'] as String?)?.trim();
    final parentReaction = (json['parentReaction'] as String?)?.trim();
    return CardMatchRule(
      trigger: (json['trigger'] as String).trim(),
      intensity: intensity == null || intensity.isEmpty ? null : intensity,
      parentReaction: parentReaction == null || parentReaction.isEmpty
          ? null
          : parentReaction,
    );
  }
}

class CardContent {
  const CardContent({
    required this.id,
    required this.triggerType,
    required this.prevent,
    required this.say,
    required this.doStep,
    this.ifEscalates,
    this.evidence,
    this.ageRange,
    this.matchRules = const [],
  });

  final String id;
  final String triggerType;
  final String prevent;
  final String say;
  final String doStep;
  final String? ifEscalates;
  final String? evidence;
  final String? ageRange;
  final List<CardMatchRule> matchRules;

  factory CardContent.fromJson(Map<String, dynamic> json) {
    final triggerType = (json['triggerType'] as String).trim();
    final matchRaw = json['match'];
    final parsedMatch = matchRaw is List
        ? matchRaw
              .whereType<Map>()
              .map((e) => CardMatchRule.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <CardMatchRule>[];

    return CardContent(
      id: (json['id'] as String).trim(),
      triggerType: triggerType,
      prevent: (json['prevent'] as String).trim(),
      say: (json['say'] as String).trim(),
      doStep: (json['do'] as String).trim(),
      ifEscalates: (json['ifEscalates'] as String?)?.trim(),
      evidence: (json['evidence'] as String?)?.trim(),
      ageRange: (json['ageRange'] as String?)?.trim(),
      matchRules: parsedMatch.isEmpty
          ? [CardMatchRule(trigger: triggerType)]
          : parsedMatch,
    );
  }
}

class CardContentService {
  CardContentService._();

  static final CardContentService instance = CardContentService._();
  static const _registryPath = 'assets/guidance/cards_registry_v2.json';

  List<CardContent>? _cards;

  Future<void> _ensureLoaded() async {
    if (_cards != null) return;

    final raw = await rootBundle.loadString(_registryPath);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final cards = map['cards'] as List<dynamic>? ?? [];
    _cards = cards
        .whereType<Map>()
        .map((entry) => CardContent.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }

  Future<List<CardContent>> getCards() async {
    await _ensureLoaded();
    return List.unmodifiable(_cards!);
  }

  Future<CardContent?> getCardById(String id) async {
    await _ensureLoaded();
    try {
      return _cards!.firstWhere((card) => card.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<CardContent?> selectBestCard({
    required String triggerType,
    String? intensity,
    String? parentReaction,
  }) async {
    await _ensureLoaded();
    return _selectBestCard(
      cards: _cards!,
      trigger: triggerType,
      intensity: intensity,
      parentReaction: parentReaction,
    );
  }

  CardContent? _selectBestCard({
    required List<CardContent> cards,
    required String trigger,
    String? intensity,
    String? parentReaction,
  }) {
    if (cards.isEmpty) return null;

    CardContent? best;
    var bestScore = -1;

    for (final card in cards) {
      for (final rule in card.matchRules) {
        if (!rule.matches(
          trigger: trigger,
          intensity: intensity,
          parentReaction: parentReaction,
        )) {
          continue;
        }
        final score = rule.specificity;
        if (score > bestScore) {
          best = card;
          bestScore = score;
        }
      }
    }

    if (best != null) return best;

    for (final card in cards) {
      final hasFallback = card.matchRules.any(
        (rule) => rule.trigger == trigger && rule.isTriggerOnly,
      );
      if (hasFallback) return card;
    }

    return cards.first;
  }
}
