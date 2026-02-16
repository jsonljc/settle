import 'package:flutter_test/flutter_test.dart';
import 'package:settle/tantrum/models/tantrum_card.dart';
import 'package:settle/tantrum/services/tantrum_card_selector_service.dart';

void main() {
  TantrumCard card({
    required String id,
    required List<TantrumCardMatch> match,
  }) {
    return TantrumCard(
      id: id,
      title: id,
      remember: 'remember',
      say: 'say',
      doStep: 'do',
      ifEscalates: 'if',
      packId: 'base',
      tier: TantrumCardTier.free,
      matchRules: match,
    );
  }

  test('prefers highest specificity match', () {
    final cards = [
      card(
        id: 'fallback',
        match: const [TantrumCardMatch(trigger: 'transition')],
      ),
      card(
        id: 'trigger_intensity',
        match: const [
          TantrumCardMatch(trigger: 'transition', intensity: 'medium'),
        ],
      ),
      card(
        id: 'exact',
        match: const [
          TantrumCardMatch(
            trigger: 'transition',
            intensity: 'medium',
            parentReaction: 'raised_voice',
          ),
        ],
      ),
    ];

    final selected = TantrumCardSelectorService.selectBestCard(
      availableCards: cards,
      trigger: 'transition',
      intensity: 'medium',
      parentReaction: 'raised_voice',
    );

    expect(selected, isNotNull);
    expect(selected!.id, 'exact');
  });

  test('falls back to trigger-only card when exact is missing', () {
    final cards = [
      card(
        id: 'fallback',
        match: const [TantrumCardMatch(trigger: 'no_limit')],
      ),
      card(
        id: 'other',
        match: const [TantrumCardMatch(trigger: 'transition')],
      ),
    ];

    final selected = TantrumCardSelectorService.selectBestCard(
      availableCards: cards,
      trigger: 'no_limit',
      intensity: 'intense',
      parentReaction: 'stayed_calm',
    );

    expect(selected, isNotNull);
    expect(selected!.id, 'fallback');
  });
}
