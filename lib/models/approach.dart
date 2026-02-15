import 'package:hive_flutter/hive_flutter.dart';

part 'approach.g.dart';

/// The four discrete settling approaches. NOT a spectrum — each is
/// qualitatively different with its own cited research base.
@HiveType(typeId: 0)
enum Approach {
  /// Stay nearby throughout. Guided by presence.
  @HiveField(0)
  stayAndSupport,

  /// Timed check-ins with increasing intervals.
  @HiveField(1)
  checkAndReassure,

  /// Read baby's cues — fussing vs crying distinction.
  @HiveField(2)
  cueBased,

  /// Environmental and scheduling interventions first.
  @HiveField(3)
  rhythmFirst;

  String get label => switch (this) {
    stayAndSupport => 'Stay & Support',
    checkAndReassure => 'Check & Reassure',
    cueBased => 'Cue-Based',
    rhythmFirst => 'Rhythm First',
  };

  String get description => switch (this) {
    stayAndSupport => 'Stay nearby and offer comfort throughout settling.',
    checkAndReassure =>
      'Leave the room, return at timed intervals to reassure.',
    cueBased => 'Respond based on the type of cry — fussing vs distress.',
    rhythmFirst =>
      'Focus on environment, timing, and routine before intervention.',
  };
}

/// Age brackets with research-backed nap counts and wake windows.
@HiveType(typeId: 1)
enum AgeBracket {
  @HiveField(0)
  newborn, // 0–8 weeks
  @HiveField(1)
  twoToThreeMonths, // 2–3 months
  @HiveField(2)
  fourToFiveMonths, // 4–5 months
  @HiveField(3)
  sixToEightMonths, // 6–8 months
  @HiveField(4)
  nineToTwelveMonths, // 9–12 months
  @HiveField(5)
  twelveToEighteenMonths, // 12–18 months

  // Tantrum feature brackets
  @HiveField(6)
  nineteenToTwentyFourMonths, // 19–24 months
  @HiveField(7)
  twoToThreeYears, // 25–36 months
  @HiveField(8)
  threeToFourYears, // 3–4 years
  @HiveField(9)
  fourToFiveYears, // 4–5 years
  @HiveField(10)
  fiveToSixYears; // 5–6 years

  String get label => switch (this) {
    newborn => '0–8 weeks',
    twoToThreeMonths => '2–3 months',
    fourToFiveMonths => '4–5 months',
    sixToEightMonths => '6–8 months',
    nineToTwelveMonths => '9–12 months',
    twelveToEighteenMonths => '12–18 months',
    nineteenToTwentyFourMonths => '19–24 months',
    twoToThreeYears => '2–3 years',
    threeToFourYears => '3–4 years',
    fourToFiveYears => '4–5 years',
    fiveToSixYears => '5–6 years',
  };

  /// Typical number of naps for this age.
  int get naps => switch (this) {
    newborn => 5,
    twoToThreeMonths => 4,
    fourToFiveMonths => 3,
    sixToEightMonths => 3,
    nineToTwelveMonths => 2,
    twelveToEighteenMonths => 1,
    nineteenToTwentyFourMonths => 1,
    twoToThreeYears => 1,
    threeToFourYears => 0,
    fourToFiveYears => 0,
    fiveToSixYears => 0,
  };

  /// Wake window range in minutes: (min, max).
  (int, int) get wakeWindowMinutes => switch (this) {
    newborn => (45, 75),
    twoToThreeMonths => (60, 90),
    fourToFiveMonths => (90, 120),
    sixToEightMonths => (120, 180),
    nineToTwelveMonths => (150, 210),
    twelveToEighteenMonths => (180, 300),
    nineteenToTwentyFourMonths => (300, 420),
    twoToThreeYears => (360, 480),
    threeToFourYears => (420, 600),
    fourToFiveYears => (480, 660),
    fiveToSixYears => (540, 720),
  };

  String get wakeWindowLabel {
    final (lo, hi) = wakeWindowMinutes;
    return '${lo ~/ 60}h ${lo % 60}m – ${hi ~/ 60}h ${hi % 60}m';
  }

  bool get isSleepOnlyAge => index <= twelveToEighteenMonths.index;

  bool get isHybridAge =>
      this == nineteenToTwentyFourMonths || this == twoToThreeYears;

  bool get isTantrumPrimaryAge => index >= threeToFourYears.index;

  bool get supportsTantrumFeatures => !isSleepOnlyAge;
}

/// Family structure options.
@HiveType(typeId: 2)
enum FamilyStructure {
  @HiveField(0)
  twoParents,
  @HiveField(1)
  singleParent,
  @HiveField(2)
  withSupport, // grandparents, nanny, etc.
  @HiveField(3)
  other;

  String get label => switch (this) {
    twoParents => 'Two parents',
    singleParent => 'Single parent',
    withSupport => 'With support',
    other => 'Other',
  };
}

/// Primary challenge — "what is hardest right now".
@HiveType(typeId: 3)
enum PrimaryChallenge {
  @HiveField(0)
  fallingAsleep,
  @HiveField(1)
  nightWaking,
  @HiveField(2)
  shortNaps,
  @HiveField(3)
  schedule;

  String get label => switch (this) {
    fallingAsleep => 'Falling asleep',
    nightWaking => 'Night waking',
    shortNaps => 'Short naps',
    schedule => 'Schedule',
  };
}

/// Feeding type.
@HiveType(typeId: 4)
enum FeedingType {
  @HiveField(0)
  breast,
  @HiveField(1)
  formula,
  @HiveField(2)
  combo,
  @HiveField(3)
  solids;

  String get label => switch (this) {
    breast => 'Breast',
    formula => 'Formula',
    combo => 'Combo',
    solids => 'Solids',
  };
}
