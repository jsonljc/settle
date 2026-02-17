import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/baby_profile.dart';
import '../models/approach.dart';
import '../models/family_member.dart';

const _boxName = 'family_members';
const _metaBoxName = 'family_members_meta';
const _backfillKey = 'backfill_done';

final familyMembersProvider =
    StateNotifierProvider<FamilyMembersNotifier, List<FamilyMember>>((ref) {
      return FamilyMembersNotifier();
    });

class FamilyMembersNotifier extends StateNotifier<List<FamilyMember>> {
  FamilyMembersNotifier({bool persist = true}) : _persist = persist, super([]) {
    if (_persist) {
      _load();
    }
  }

  final bool _persist;
  Box<FamilyMember>? _box;
  Box<dynamic>? _metaBox;

  Future<Box<FamilyMember>> _ensureBox() async {
    _box ??= await Hive.openBox<FamilyMember>(_boxName);
    return _box!;
  }

  Future<Box<dynamic>> _ensureMetaBox() async {
    _metaBox ??= await Hive.openBox<dynamic>(_metaBoxName);
    return _metaBox!;
  }

  Future<void> _load() async {
    try {
      final box = await _ensureBox();
      state = box.values.toList();
    } catch (_) {
      state = [];
    }
  }

  /// Call when Family tab is first opened with a profile. Backfills one member from profile if box is empty.
  Future<void> ensureBackfillFromProfile(BabyProfile? profile) async {
    if (!_persist || profile == null) return;
    final meta = await _ensureMetaBox();
    if (meta.get(_backfillKey) == true) return;
    final box = await _ensureBox();
    if (box.isNotEmpty) {
      await meta.put(_backfillKey, true);
      return;
    }
    final role = _defaultRoleForStructure(profile.familyStructure);
    final member = FamilyMember(
      id: 'member_${DateTime.now().millisecondsSinceEpoch}',
      name: 'You',
      role: role,
    );
    await box.put(member.id, member);
    await meta.put(_backfillKey, true);
    await _load();
  }

  String _defaultRoleForStructure(FamilyStructure structure) {
    return switch (structure) {
      FamilyStructure.twoParents => 'Primary caregiver',
      FamilyStructure.coParent => 'Co-parent',
      FamilyStructure.singleParent => 'Primary caregiver',
      FamilyStructure.withSupport => 'Primary caregiver',
      FamilyStructure.blended => 'Caregiver',
      FamilyStructure.other => 'Caregiver',
    };
  }

  Future<void> addMember(FamilyMember member) async {
    if (!_persist) {
      state = [...state, member];
      return;
    }
    final box = await _ensureBox();
    await box.put(member.id, member);
    await _load();
  }

  Future<void> removeMember(String id) async {
    if (!_persist) {
      state = state.where((m) => m.id != id).toList();
      return;
    }
    final box = await _ensureBox();
    await box.delete(id);
    await _load();
  }

  Future<void> updateMember(FamilyMember member) async {
    if (!_persist) {
      state = [...state.where((m) => m.id != member.id), member];
      return;
    }
    final box = await _ensureBox();
    await box.put(member.id, member);
    await _load();
  }
}
