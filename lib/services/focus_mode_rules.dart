import '../models/approach.dart';
import '../models/baby_profile.dart';
import '../models/tantrum_profile.dart';

class FocusModeRules {
  const FocusModeRules._();

  static List<FocusMode> allowedModesForAge(AgeBracket ageBracket) {
    if (ageBracket.isSleepOnlyAge) return const [FocusMode.sleepOnly];
    if (ageBracket.isHybridAge) {
      return const [FocusMode.sleepOnly, FocusMode.tantrumOnly, FocusMode.both];
    }
    return const [FocusMode.tantrumOnly, FocusMode.both];
  }

  static FocusMode normalizeMode({
    required AgeBracket ageBracket,
    required FocusMode requestedMode,
  }) {
    final allowed = allowedModesForAge(ageBracket);
    if (allowed.contains(requestedMode)) return requestedMode;
    return allowed.first;
  }

  static TantrumProfile? normalizeTantrumProfile({
    required AgeBracket ageBracket,
    required FocusMode focusMode,
    required TantrumProfile? tantrumProfile,
  }) {
    final shouldHaveTantrumProfile =
        ageBracket.supportsTantrumFeatures && focusMode != FocusMode.sleepOnly;
    if (!shouldHaveTantrumProfile) return null;
    return tantrumProfile ?? defaultTantrumProfile;
  }

  static BabyProfile normalizeProfile(BabyProfile profile) {
    final mode = normalizeMode(
      ageBracket: profile.ageBracket,
      requestedMode: profile.focusMode,
    );
    final tantrumProfile = normalizeTantrumProfile(
      ageBracket: profile.ageBracket,
      focusMode: mode,
      tantrumProfile: profile.tantrumProfile,
    );
    return profile.copyWith(focusMode: mode, tantrumProfile: tantrumProfile);
  }

  static TantrumProfile get defaultTantrumProfile => TantrumProfile(
    tantrumType: TantrumType.mixed,
    commonTriggers: const [TriggerType.unpredictable],
    parentPattern: ParentPattern.freezes,
    responsePriority: ResponsePriority.scripts,
  );
}
