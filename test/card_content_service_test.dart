import 'package:flutter_test/flutter_test.dart';
import 'package:settle/services/card_content_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads registry cards by id', () async {
    final card = await CardContentService.instance.getCardById(
      'transitions_timer_choice',
    );
    expect(card, isNotNull);
    expect(card?.triggerType, 'transitions');
  });

  test('selects highest-specificity match rule first', () async {
    final card = await CardContentService.instance.selectBestCard(
      triggerType: 'overwhelmed',
      parentReaction: 'already_yelled',
    );
    expect(card, isNotNull);
    expect(card?.id, 'overwhelmed_repair_after_yell');
  });

  test(
    'falls back to trigger-only match when specific rule not found',
    () async {
      final card = await CardContentService.instance.selectBestCard(
        triggerType: 'no_to_everything',
        intensity: 'intense',
      );
      expect(card, isNotNull);
      expect(card?.triggerType, 'no_to_everything');
    },
  );
}
