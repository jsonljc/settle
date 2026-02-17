import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:settle/services/spec_policy.dart';

int _wordCount(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((token) => token.trim().isNotEmpty);
  return words.length;
}

void main() {
  test('plan card registry copy respects v3 word limits', () async {
    final file = File('assets/guidance/cards_registry_v2.json');
    expect(file.existsSync(), isTrue);

    final raw = await file.readAsString();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final cards = decoded['cards'] as List<dynamic>? ?? const [];
    expect(cards, isNotEmpty);

    for (final item in cards) {
      final card = Map<String, dynamic>.from(item as Map);
      final id = card['id']?.toString() ?? 'unknown';
      final prevent = card['prevent']?.toString() ?? '';
      final say = card['say']?.toString() ?? '';
      final doStep = card['do']?.toString() ?? '';
      final escalates = card['ifEscalates']?.toString() ?? '';

      expect(
        _wordCount(prevent) <= SpecPolicy.planPreventMaxWords,
        isTrue,
        reason: '$id prevent exceeds ${SpecPolicy.planPreventMaxWords} words',
      );
      expect(
        _wordCount(say) <= SpecPolicy.planSayMaxWords,
        isTrue,
        reason: '$id say exceeds ${SpecPolicy.planSayMaxWords} words',
      );
      expect(
        _wordCount(doStep) <= SpecPolicy.planDoMaxWords,
        isTrue,
        reason: '$id do exceeds ${SpecPolicy.planDoMaxWords} words',
      );
      if (escalates.trim().isNotEmpty) {
        expect(
          _wordCount(escalates) <= SpecPolicy.planEscalatesMaxWords,
          isTrue,
          reason:
              '$id ifEscalates exceeds ${SpecPolicy.planEscalatesMaxWords} words',
        );
      }
    }
  });
}
