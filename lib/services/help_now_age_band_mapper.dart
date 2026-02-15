import '../models/approach.dart';

class HelpNowAgeBandMapper {
  const HelpNowAgeBandMapper._();

  static String map(AgeBracket age) {
    return switch (age) {
      AgeBracket.newborn ||
      AgeBracket.twoToThreeMonths ||
      AgeBracket.fourToFiveMonths ||
      AgeBracket.sixToEightMonths ||
      AgeBracket.nineToTwelveMonths ||
      AgeBracket.twelveToEighteenMonths ||
      AgeBracket.nineteenToTwentyFourMonths => '1-2',
      AgeBracket.twoToThreeYears ||
      AgeBracket.threeToFourYears ||
      AgeBracket.fourToFiveYears => '3-5',
      AgeBracket.fiveToSixYears => '6-8',
    };
  }
}
