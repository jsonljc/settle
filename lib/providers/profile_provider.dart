import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/approach.dart';
import '../models/baby_profile.dart';
import '../models/tantrum_profile.dart';
import '../services/focus_mode_rules.dart';

const _boxName = 'profile';
const _key = 'baby';

final _profileLoadedStateProvider = StateProvider<bool>((ref) => false);

/// Provides the current [BabyProfile], persisted to Hive.
/// Null when onboarding hasn't been completed yet.
final profileProvider = StateNotifierProvider<ProfileNotifier, BabyProfile?>((
  ref,
) {
  return ProfileNotifier(ref);
});

/// True once persisted profile state has finished loading from storage.
final profileLoadedProvider = Provider<bool>((ref) {
  // Ensure profile provider is instantiated so the async load can start.
  ref.watch(profileProvider.notifier);
  return ref.watch(_profileLoadedStateProvider);
});

class ProfileNotifier extends StateNotifier<BabyProfile?> {
  ProfileNotifier(this._ref) : super(null) {
    _load();
  }

  final Ref _ref;
  Box<BabyProfile>? _box;

  Future<Box<BabyProfile>> _ensureBox() async {
    _box ??= await Hive.openBox<BabyProfile>(_boxName);
    return _box!;
  }

  Future<void> _load() async {
    try {
      final box = await _ensureBox();
      state = box.get(_key);
    } catch (_) {
      state = null;
    } finally {
      _ref.read(_profileLoadedStateProvider.notifier).state = true;
    }
  }

  Future<void> save(BabyProfile profile) async {
    final box = await _ensureBox();
    final normalized = FocusModeRules.normalizeProfile(profile);
    await box.put(_key, normalized);
    state = normalized;
  }

  Future<void> updateApproach(Approach approach) async {
    if (state == null) return;
    await save(state!.copyWith(approach: approach));
  }

  Future<void> updateAge(AgeBracket age) async {
    if (state == null) return;
    await save(state!.copyWith(ageBracket: age));
  }

  Future<void> updateFocusMode(FocusMode focusMode) async {
    if (state == null) return;
    await save(state!.copyWith(focusMode: focusMode));
  }

  Future<void> updateTantrumProfile(TantrumProfile? tantrumProfile) async {
    if (state == null) return;
    await save(state!.copyWith(tantrumProfile: tantrumProfile));
  }

  Future<void> clear() async {
    final box = await _ensureBox();
    await box.delete(_key);
    state = null;
  }
}
