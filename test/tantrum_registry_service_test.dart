import 'package:flutter_test/flutter_test.dart';
import 'package:settle/tantrum/models/tantrum_card.dart';
import 'package:settle/tantrum/services/tantrum_registry_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TantrumRegistryService v2', () {
    test('loads cards with v2 fields and free tier count', () async {
      final cards = await TantrumRegistryService.instance.getCards();
      expect(cards, isNotEmpty);

      final freeCards = await TantrumRegistryService.instance.getCardsByTier(
        TantrumCardTier.free,
      );
      expect(freeCards.length, 20);
      expect(
        freeCards.every((card) => card.remember.trim().isNotEmpty),
        isTrue,
      );
    });

    test('selects exact rule before trigger fallback', () async {
      final exact = await TantrumRegistryService.instance.selectBestCard(
        trigger: 'transition',
        intensity: 'medium',
        parentReaction: 'raised_voice',
      );
      expect(exact, isNotNull);
      expect(exact!.id, 'transition_medium_raised_voice');

      final fallback = await TantrumRegistryService.instance.selectBestCard(
        trigger: 'no_limit',
        intensity: 'intense',
        parentReaction: 'stayed_calm',
      );
      expect(fallback, isNotNull);
      expect(fallback!.id, 'no_limit_fallback');
    });
  });
}
