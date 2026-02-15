import 'package:hive_flutter/hive_flutter.dart';

import 'approach.dart';
import 'tantrum_profile.dart';

part 'baby_profile.g.dart';

/// Persisted baby profile — created during onboarding, editable in settings.
@HiveType(typeId: 10)
class BabyProfile extends HiveObject {
  static const _noChange = Object();

  @HiveField(0)
  String name;

  @HiveField(1)
  AgeBracket ageBracket;

  @HiveField(2)
  FamilyStructure familyStructure;

  @HiveField(3)
  Approach approach;

  @HiveField(4)
  PrimaryChallenge primaryChallenge;

  @HiveField(5)
  FeedingType feedingType;

  /// ISO 8601 date string of when the profile was created.
  @HiveField(6)
  String createdAt;

  /// Optional tantrum profile for users who enable tantrum support.
  @HiveField(7)
  TantrumProfile? tantrumProfile;

  /// Feature focus for home layout and content switching.
  @HiveField(8)
  FocusMode focusMode;

  BabyProfile({
    required this.name,
    required this.ageBracket,
    required this.familyStructure,
    required this.approach,
    required this.primaryChallenge,
    required this.feedingType,
    this.tantrumProfile,
    FocusMode? focusMode,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String(),
       focusMode =
           focusMode ??
           (ageBracket.supportsTantrumFeatures
               ? FocusMode.both
               : FocusMode.sleepOnly);

  /// Convenience: wake window range in minutes from the age bracket.
  (int, int) get wakeWindowMinutes => ageBracket.wakeWindowMinutes;

  /// Midpoint of the wake window range — used as the "target" for the arc.
  int get targetWakeMinutes {
    final (lo, hi) = wakeWindowMinutes;
    return ((lo + hi) / 2).round();
  }

  BabyProfile copyWith({
    String? name,
    AgeBracket? ageBracket,
    FamilyStructure? familyStructure,
    Approach? approach,
    PrimaryChallenge? primaryChallenge,
    FeedingType? feedingType,
    Object? tantrumProfile = _noChange,
    FocusMode? focusMode,
  }) {
    return BabyProfile(
      name: name ?? this.name,
      ageBracket: ageBracket ?? this.ageBracket,
      familyStructure: familyStructure ?? this.familyStructure,
      approach: approach ?? this.approach,
      primaryChallenge: primaryChallenge ?? this.primaryChallenge,
      feedingType: feedingType ?? this.feedingType,
      tantrumProfile: identical(tantrumProfile, _noChange)
          ? this.tantrumProfile
          : tantrumProfile as TantrumProfile?,
      focusMode: focusMode ?? this.focusMode,
      createdAt: createdAt,
    );
  }
}
