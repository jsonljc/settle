import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/tantrum_profile.dart';
import '../services/prevention_engine.dart';
import '../services/tantrum_engine.dart';
import '../tantrum/services/tantrum_insights_service.dart';
import 'profile_provider.dart';

const _eventsBoxName = 'tantrum_events';

final focusModeProvider = Provider<FocusMode>((ref) {
  final profile = ref.watch(profileProvider);
  return profile?.focusMode ?? FocusMode.sleepOnly;
});

final tantrumProfileProvider = Provider<TantrumProfile?>((ref) {
  return ref.watch(profileProvider)?.tantrumProfile;
});

final tantrumEventsProvider =
    StateNotifierProvider<TantrumEventsNotifier, List<TantrumEvent>>((ref) {
      return TantrumEventsNotifier();
    });

final patternProvider = Provider<WeeklyTantrumPattern?>((ref) {
  final profile = ref.watch(profileProvider);
  final tantrumProfile = ref.watch(tantrumProfileProvider);
  if (profile == null || tantrumProfile == null) return null;

  final events = ref.watch(tantrumEventsProvider);
  return TantrumEngine.computePattern(
    events: events,
    ageBracket: profile.ageBracket,
  );
});

final flashcardProvider = Provider<List<String>>((ref) {
  final tantrumProfile = ref.watch(tantrumProfileProvider);
  final type = tantrumProfile?.tantrumType ?? TantrumType.mixed;
  return TantrumEngine.generateFlashcard(type);
});

final preventionProvider = Provider<List<String>>((ref) {
  final profile = ref.watch(profileProvider);
  final tantrumProfile = ref.watch(tantrumProfileProvider);
  final pattern = ref.watch(patternProvider);
  if (profile == null || tantrumProfile == null || pattern == null) {
    return const [];
  }

  return PreventionEngine.dailyStrategies(
    ageBracket: profile.ageBracket,
    profile: tantrumProfile,
    pattern: pattern,
    now: DateTime.now(),
  );
});

final normalizationProvider = Provider<NormalizationStatus?>((ref) {
  return ref.watch(patternProvider)?.normalizationStatus;
});

final scenarioProvider = Provider<PracticeScenario?>((ref) {
  final profile = ref.watch(profileProvider);
  final tantrumProfile = ref.watch(tantrumProfileProvider);
  if (profile == null || tantrumProfile == null) return null;

  return TantrumEngine.generateScenario(
    ageBracket: profile.ageBracket,
    tantrumType: tantrumProfile.tantrumType,
    triggers: tantrumProfile.commonTriggers,
    childName: profile.name,
  );
});

final tantrumInsightProvider = Provider<String>((ref) {
  final pattern = ref.watch(patternProvider);
  final prevention = ref.watch(preventionProvider);
  final profile = ref.watch(profileProvider);
  final name = profile?.name ?? 'Your child';

  if (pattern == null || pattern.totalEvents == 0) {
    return 'Ready when you need it.';
  }

  final topTriggerEntry =
      pattern.triggerCounts.entries.where((e) => e.value > 0).toList()
        ..sort((a, b) => b.value.compareTo(a.value));

  if (topTriggerEntry.isNotEmpty) {
    final trigger = topTriggerEntry.first.key.label.toLowerCase();
    return '$name shows the most intensity around $trigger. ${prevention.isNotEmpty ? prevention.first : ''}'
        .trim();
  }

  return 'You logged ${pattern.totalEvents} hard moments this week. Keep tracking for a clearer pattern.';
});

final tantrumInsightsUnlockedProvider = Provider<bool>((ref) {
  final events = ref.watch(tantrumEventsProvider);
  return events.length >= TantrumInsightsService.unlockThreshold;
});

final tantrumInsightsLinesProvider = Provider<List<String>>((ref) {
  final events = ref.watch(tantrumEventsProvider);
  return TantrumInsightsService.buildInsights(events);
});

final hasTantrumFeatureProvider = Provider<bool>((ref) {
  final profile = ref.watch(profileProvider);
  if (profile == null) return false;
  return profile.focusMode != FocusMode.sleepOnly &&
      profile.ageBracket.supportsTantrumFeatures &&
      profile.tantrumProfile != null;
});

class TantrumEventsNotifier extends StateNotifier<List<TantrumEvent>> {
  TantrumEventsNotifier({bool persist = true})
    : _persist = persist,
      super(const []) {
    if (_persist) _load();
  }

  final bool _persist;
  Box<TantrumEvent>? _box;
  Future<Box<TantrumEvent>>? _boxFuture;

  Future<Box<TantrumEvent>> _ensureBox() async {
    final existing = _box;
    if (existing != null) return existing;

    _boxFuture ??= Hive.openBox<TantrumEvent>(_eventsBoxName).then((box) {
      _box = box;
      return box;
    });

    try {
      return await _boxFuture!;
    } catch (_) {
      _boxFuture = null;
      rethrow;
    }
  }

  Future<void> _load() async {
    final box = await _ensureBox();
    final events = box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = events;
  }

  Future<void> addEvent(TantrumEvent event) async {
    if (!_persist) {
      state = [event, ...state]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return;
    }
    final box = await _ensureBox();
    await box.add(event);
    await _load();
  }

  Future<void> addDebrief({
    TriggerType? trigger,
    required TantrumIntensity intensity,
    required List<String> whatHelped,
    String? notes,
    bool flashcardUsed = false,
  }) {
    final event = TantrumEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      trigger: trigger,
      intensity: intensity,
      whatHelped: whatHelped,
      notes: notes,
      flashcardUsed: flashcardUsed,
    );
    return addEvent(event);
  }

  /// Quick-capture logging path for Tantrum Hub v2.
  Future<String> addCapture({
    required String trigger,
    String? intensity,
    String? location,
    String? parentReaction,
    String? selectedCardId,
  }) async {
    final event = TantrumEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      trigger: _mapCaptureTrigger(trigger),
      intensity: _mapCaptureIntensity(intensity),
      whatHelped: const [],
      flashcardUsed: false,
      location: location,
      parentReaction: parentReaction,
      selectedCardId: selectedCardId,
      captureTrigger: trigger,
      captureIntensity: intensity,
    );
    await addEvent(event);
    return event.id;
  }

  TriggerType _mapCaptureTrigger(String trigger) {
    switch (trigger) {
      case 'transition':
        return TriggerType.transitions;
      case 'no_limit':
        return TriggerType.boundaries;
      case 'tired_hungry':
        return TriggerType.frustration;
      case 'attention_conflict':
        return TriggerType.frustration;
      case 'sibling_conflict':
        return TriggerType.boundaries;
      case 'unknown':
      default:
        return TriggerType.unpredictable;
    }
  }

  TantrumIntensity _mapCaptureIntensity(String? intensity) {
    switch (intensity) {
      case 'mild':
        return TantrumIntensity.mild;
      case 'intense':
        return TantrumIntensity.intense;
      case 'medium':
      default:
        return TantrumIntensity.moderate;
    }
  }

  Future<void> clear() async {
    if (!_persist) {
      state = const [];
      return;
    }
    final box = await _ensureBox();
    await box.clear();
    state = const [];
  }
}
