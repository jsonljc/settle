import '../models/tantrum_card.dart';

class TantrumCardSelectorService {
  const TantrumCardSelectorService._();

  /// Selects best matching card from the available card set.
  ///
  /// Priority:
  /// 1) Highest-specificity rule match (trigger + optional intensity/reaction)
  /// 2) Trigger-only fallback
  /// 3) First available card
  static TantrumCard? selectBestCard({
    required List<TantrumCard> availableCards,
    required String trigger,
    String? intensity,
    String? parentReaction,
  }) {
    if (availableCards.isEmpty) return null;

    TantrumCard? best;
    var bestScore = -1;

    for (final card in availableCards) {
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

    for (final card in availableCards) {
      final hasFallback = card.matchRules.any(
        (rule) => rule.trigger == trigger && rule.isTriggerOnly,
      );
      if (hasFallback) return card;
    }

    return availableCards.first;
  }
}
