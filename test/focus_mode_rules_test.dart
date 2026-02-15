import 'package:flutter_test/flutter_test.dart';

import 'package:settle/models/approach.dart';
import 'package:settle/models/baby_profile.dart';
import 'package:settle/models/tantrum_profile.dart';
import 'package:settle/services/focus_mode_rules.dart';

void main() {
  test('sleep-only ages force sleep mode and clear tantrum profile', () {
    final profile = BabyProfile(
      name: 'Ari',
      ageBracket: AgeBracket.newborn,
      familyStructure: FamilyStructure.twoParents,
      approach: Approach.stayAndSupport,
      primaryChallenge: PrimaryChallenge.fallingAsleep,
      feedingType: FeedingType.breast,
      focusMode: FocusMode.both,
      tantrumProfile: FocusModeRules.defaultTantrumProfile,
    );

    final normalized = FocusModeRules.normalizeProfile(profile);
    expect(normalized.focusMode, FocusMode.sleepOnly);
    expect(normalized.tantrumProfile, isNull);
  });

  test('tantrum-primary ages disallow sleep-only mode', () {
    final profile = BabyProfile(
      name: 'Milo',
      ageBracket: AgeBracket.fourToFiveYears,
      familyStructure: FamilyStructure.withSupport,
      approach: Approach.rhythmFirst,
      primaryChallenge: PrimaryChallenge.schedule,
      feedingType: FeedingType.solids,
      focusMode: FocusMode.sleepOnly,
      tantrumProfile: null,
    );

    final normalized = FocusModeRules.normalizeProfile(profile);
    expect(normalized.focusMode, FocusMode.tantrumOnly);
    expect(normalized.tantrumProfile, isNotNull);
  });

  test('hybrid ages allow both and provision default tantrum profile', () {
    final profile = BabyProfile(
      name: 'Noah',
      ageBracket: AgeBracket.twoToThreeYears,
      familyStructure: FamilyStructure.singleParent,
      approach: Approach.cueBased,
      primaryChallenge: PrimaryChallenge.shortNaps,
      feedingType: FeedingType.combo,
      focusMode: FocusMode.both,
      tantrumProfile: null,
    );

    final normalized = FocusModeRules.normalizeProfile(profile);
    expect(normalized.focusMode, FocusMode.both);
    expect(normalized.tantrumProfile, isNotNull);
  });

  test('allowed modes differ by age group', () {
    expect(
      FocusModeRules.allowedModesForAge(AgeBracket.nineToTwelveMonths),
      const [FocusMode.sleepOnly],
    );
    expect(
      FocusModeRules.allowedModesForAge(AgeBracket.twoToThreeYears),
      const [FocusMode.sleepOnly, FocusMode.tantrumOnly, FocusMode.both],
    );
    expect(FocusModeRules.allowedModesForAge(AgeBracket.fiveToSixYears), const [
      FocusMode.tantrumOnly,
      FocusMode.both,
    ]);
  });
}
