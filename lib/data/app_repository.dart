import 'package:hive_flutter/hive_flutter.dart';

import '../models/approach.dart';
import '../models/baby_profile.dart';
import '../models/reset_event.dart';
import '../models/user_card.dart';

/// Schema version for spine storage. Bump when migrating.
const int spineSchemaVersion = 1;

const _spineBoxName = 'spine_store';
const _spineKeySchemaVersion = 'schema_version';
const _spineKeyResetEvents = 'reset_events';
const _profileBoxName = 'profile';
const _profileKey = 'baby';
const _userCardsBoxName = 'user_cards';

/// Single repository for product spine and local persistence.
/// Persists: reset events, saved cards (Playbook), settings (child age, name).
/// Graceful fallback: on storage failure the app still works; data is not remembered.
abstract class AppRepository {
  /// Current schema version. Returns 0 if unset or on error.
  int get schemaVersion;

  /// Writes schema version for future migrations.
  Future<void> setSchemaVersion(int version);

  /// All reset events, newest first.
  Future<List<ResetEvent>> getResetEvents();

  /// Appends a reset event. Context/state optional. cardIdsSeen and cardIdKept
  /// record what was shown and whether user kept a card.
  Future<void> addResetEvent({
    String? context,
    String? state,
    List<String> cardIdsSeen = const [],
    String? cardIdKept,
  });

  /// Saved playbook card ids.
  Future<List<String>> getSavedCardIds();

  /// Saves a card to the playbook.
  Future<void> addSavedCard(String cardId, {bool pinned = false});

  /// Removes a card from the playbook.
  Future<void> removeSavedCard(String cardId);

  /// Child display name, if set.
  Future<String?> getChildName();

  /// Child age bracket and optional precise months.
  Future<(AgeBracket?, int?)> getChildAge();

  /// Updates child name. No-op if profile does not exist.
  Future<void> setChildName(String? name);

  /// Updates child age. No-op if profile does not exist.
  Future<void> setChildAge(AgeBracket? ageBracket, int? ageMonths);
}

/// Default implementation using Hive. Catches storage errors and returns safe defaults.
class AppRepositoryImpl implements AppRepository {
  AppRepositoryImpl._();

  static final AppRepositoryImpl instance = AppRepositoryImpl._();

  Box<dynamic>? _spineBox;
  Box<BabyProfile>? _profileBox;
  Box<UserCard>? _userCardsBox;

  Future<Box<dynamic>> _spineBoxSafe() async {
    if (_spineBox != null) return _spineBox!;
    try {
      _spineBox = await Hive.openBox<dynamic>(_spineBoxName);
      return _spineBox!;
    } catch (_) {
      rethrow;
    }
  }

  Future<Box<BabyProfile>?> _profileBoxSafe() async {
    if (_profileBox != null) return _profileBox;
    try {
      _profileBox = await Hive.openBox<BabyProfile>(_profileBoxName);
      return _profileBox;
    } catch (_) {
      return null;
    }
  }

  Future<Box<UserCard>?> _userCardsBoxSafe() async {
    if (_userCardsBox != null) return _userCardsBox;
    try {
      _userCardsBox = await Hive.openBox<UserCard>(_userCardsBoxName);
      return _userCardsBox;
    } catch (_) {
      return null;
    }
  }

  @override
  int get schemaVersion {
    try {
      if (_spineBox == null || !_spineBox!.isOpen) return 0;
      final v = _spineBox!.get(_spineKeySchemaVersion);
      if (v is int) return v;
      return 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> setSchemaVersion(int version) async {
    try {
      final box = await _spineBoxSafe();
      await box.put(_spineKeySchemaVersion, version);
    } catch (_) {
      // Graceful fallback: do not throw
    }
  }

  @override
  Future<List<ResetEvent>> getResetEvents() async {
    try {
      final box = await _spineBoxSafe();
      final raw = box.get(_spineKeyResetEvents);
      if (raw is List) {
        final list = raw.whereType<ResetEvent>().toList();
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return list;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> addResetEvent({
    String? context,
    String? state,
    List<String> cardIdsSeen = const [],
    String? cardIdKept,
  }) async {
    try {
      final box = await _spineBoxSafe();
      final raw = box.get(_spineKeyResetEvents);
      final list = raw is List
          ? List<ResetEvent>.from(raw.whereType<ResetEvent>())
          : <ResetEvent>[];
      list.add(
        ResetEvent(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          context: context,
          state: state,
          cardIdsSeen: cardIdsSeen,
          cardIdKept: cardIdKept,
        ),
      );
      await box.put(_spineKeyResetEvents, list);
    } catch (_) {
      // Graceful fallback
    }
  }

  @override
  Future<List<String>> getSavedCardIds() async {
    try {
      final box = await _userCardsBoxSafe();
      if (box == null) return [];
      return box.values.map((c) => c.cardId).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> addSavedCard(String cardId, {bool pinned = false}) async {
    try {
      final box = await _userCardsBoxSafe();
      if (box == null) return;
      final existing = box.get(cardId);
      if (existing != null) {
        if (pinned && !existing.pinned) {
          await box.put(cardId, existing.copyWith(pinned: true));
        }
        return;
      }
      await box.put(cardId, UserCard(cardId: cardId, pinned: pinned));
    } catch (_) {
      // Graceful fallback
    }
  }

  @override
  Future<void> removeSavedCard(String cardId) async {
    try {
      final box = await _userCardsBoxSafe();
      if (box == null) return;
      await box.delete(cardId);
    } catch (_) {
      // Graceful fallback
    }
  }

  @override
  Future<String?> getChildName() async {
    try {
      final box = await _profileBoxSafe();
      if (box == null) return null;
      final p = box.get(_profileKey);
      return p?.name;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<(AgeBracket?, int?)> getChildAge() async {
    try {
      final box = await _profileBoxSafe();
      if (box == null) return (null, null);
      final p = box.get(_profileKey);
      if (p == null) return (null, null);
      return (p.ageBracket, p.ageMonths);
    } catch (_) {
      return (null, null);
    }
  }

  @override
  Future<void> setChildName(String? name) async {
    try {
      final box = await _profileBoxSafe();
      if (box == null) return;
      final p = box.get(_profileKey);
      if (p == null) return;
      await box.put(_profileKey, p.copyWith(name: name ?? p.name));
    } catch (_) {
      // Graceful fallback
    }
  }

  @override
  Future<void> setChildAge(AgeBracket? ageBracket, int? ageMonths) async {
    try {
      final box = await _profileBoxSafe();
      if (box == null) return;
      final p = box.get(_profileKey);
      if (p == null) return;
      await box.put(
        _profileKey,
        p.copyWith(
          ageBracket: ageBracket ?? p.ageBracket,
          ageMonths: ageMonths,
        ),
      );
    } catch (_) {
      // Graceful fallback
    }
  }
}
