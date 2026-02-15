import 'package:flutter_test/flutter_test.dart';
import 'package:settle/models/approach.dart';
import 'package:settle/services/help_now_age_band_mapper.dart';

void main() {
  test('maps all supported profile age brackets to a Help Now age band', () {
    for (final age in AgeBracket.values) {
      final mapped = HelpNowAgeBandMapper.map(age);
      expect(mapped, isNotEmpty, reason: 'Missing mapping for ${age.name}');
    }
  });

  test(
    'uses deterministic bucket mapping aligned to Help Now picker bands',
    () {
      expect(HelpNowAgeBandMapper.map(AgeBracket.newborn), '1-2');
      expect(HelpNowAgeBandMapper.map(AgeBracket.nineToTwelveMonths), '1-2');
      expect(
        HelpNowAgeBandMapper.map(AgeBracket.nineteenToTwentyFourMonths),
        '1-2',
      );
      expect(HelpNowAgeBandMapper.map(AgeBracket.twoToThreeYears), '3-5');
      expect(HelpNowAgeBandMapper.map(AgeBracket.fourToFiveYears), '3-5');
      expect(HelpNowAgeBandMapper.map(AgeBracket.fiveToSixYears), '6-8');
    },
  );
}
