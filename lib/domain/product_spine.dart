// Product spine: context, state, and stage used across entry points and flows.
// Context and State align with RepairCardContext / RepairCardState.
// Stage is derived from child age and affects content weight only, not flow structure.

import '../models/approach.dart';
import '../models/repair_card.dart';

/// Flow context — general, sleep, or tantrum.
typedef SpineContext = RepairCardContext;

/// Who the flow is for — self (parent) or child.
typedef SpineState = RepairCardState;

/// Content stage derived from child age. Affects content weight only, not flow structure.
enum Stage {
  infant,
  toddler,
  preschool,
}

/// Derives stage from child age (age bracket or months).
/// Returns [Stage.infant] when age is unknown.
Stage stageFromAge(AgeBracket? ageBracket, int? ageMonths) {
  final months = ageMonths ?? _ageBracketToMonths(ageBracket);
  if (months <= 0) return Stage.infant;
  if (months < 18) return Stage.infant;
  if (months < 36) return Stage.toddler;
  return Stage.preschool;
}

int _ageBracketToMonths(AgeBracket? b) {
  if (b == null) return 0;
  return switch (b) {
    AgeBracket.newborn => 2,
    AgeBracket.twoToThreeMonths => 3,
    AgeBracket.fourToFiveMonths => 5,
    AgeBracket.sixToEightMonths => 7,
    AgeBracket.nineToTwelveMonths => 10,
    AgeBracket.twelveToEighteenMonths => 15,
    AgeBracket.nineteenToTwentyFourMonths => 21,
    AgeBracket.twoToThreeYears => 30,
    AgeBracket.threeToFourYears => 42,
    AgeBracket.fourToFiveYears => 54,
    AgeBracket.fiveToSixYears => 66,
  };
}
