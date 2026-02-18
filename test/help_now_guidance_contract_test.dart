import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:settle/services/spec_policy.dart';

Map<String, dynamic> _readGuidance() {
  const path = 'assets/guidance/help_now_guidance_v1.json';
  final file = File(path);
  if (!file.existsSync()) {
    fail('Missing Help Now guidance asset: $path');
  }
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map) {
    fail('Expected top-level object in help_now_guidance_v1.json');
  }
  return Map<String, dynamic>.from(decoded);
}

int _wordCount(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return 0;
  return trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
}

int _sentenceEndingCount(String input) {
  return RegExp(r'[.!?]').allMatches(input).length;
}

void main() {
  test('help now guidance keeps v1 incident set and routing rule shape', () {
    final guidance = _readGuidance();
    final incidents = (guidance['incidents'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final ids = incidents
        .map((e) => e['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    expect(incidents.length >= 6 && incidents.length <= 8, isTrue);
    expect(ids.contains('screaming_crying'), isTrue);
    expect(ids.contains('hitting_throwing'), isTrue);
    expect(ids.contains('unsafe_bolting'), isTrue);
    expect(ids.contains('refusal_wont'), isTrue);
    expect(ids.contains('public_meltdown'), isTrue);
    expect(ids.contains('parent_overwhelmed'), isTrue);

    final nightRouting = Map<String, dynamic>.from(
      guidance['nightRouting'] as Map,
    );
    expect(nightRouting['startHour'], SpecPolicy.nightRoutingStartHour);
    expect(
      nightRouting['endHourExclusive'],
      SpecPolicy.nightRoutingEndHourExclusive,
    );
  });

  test('help now outputs respect SAY/DO/TIMER constraints', () {
    final guidance = _readGuidance();
    final incidents = (guidance['incidents'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    for (final incident in incidents) {
      final id = incident['id']?.toString() ?? 'unknown';
      final defaults = Map<String, dynamic>.from(incident['default'] as Map);

      final say = defaults['say']?.toString() ?? '';
      final doStep = defaults['doStep']?.toString() ?? '';
      final ifEscalates = defaults['ifEscalates']?.toString() ?? '';
      final timerMinutes = defaults['timerMinutes'] as int? ?? 0;

      expect(say.trim().isNotEmpty, isTrue, reason: '$id missing SAY');
      expect(
        _wordCount(say) <= SpecPolicy.helpNowSayMaxWords,
        isTrue,
        reason: '$id SAY exceeds ${SpecPolicy.helpNowSayMaxWords} words',
      );
      expect(
        _sentenceEndingCount(say) <= 2,
        isTrue,
        reason: '$id SAY should stay concise (max two short sentences)',
      );
      expect(doStep.trim().isNotEmpty, isTrue, reason: '$id missing DO');
      expect(
        timerMinutes >= SpecPolicy.helpNowTimerMinMinutes &&
            timerMinutes <= SpecPolicy.helpNowTimerMaxMinutes,
        isTrue,
        reason:
            '$id timer must be ${SpecPolicy.helpNowTimerMinMinutes}-${SpecPolicy.helpNowTimerMaxMinutes} minutes',
      );
      expect(
        ifEscalates.trim().isNotEmpty,
        isTrue,
        reason: '$id missing IF escalates branch',
      );
    }
  });
}
