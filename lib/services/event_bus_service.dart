import 'dart:convert';
import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';

import 'spec_policy.dart';

class Pillars {
  static const helpNow = 'HELP_NOW';
  static const sleepTonight = 'SLEEP_TONIGHT';
  static const planProgress = 'PLAN_PROGRESS';
  static const familyRules = 'FAMILY_RULES';
}

class EventTypes {
  // Help Now
  static const hnUsedTantrum = 'HN_USED_TANTRUM';
  static const hnUsedAggression = 'HN_USED_AGGRESSION';
  static const hnUsedUnsafe = 'HN_USED_UNSAFE';
  static const hnUsedRefusal = 'HN_USED_REFUSAL';
  static const hnUsedPublic = 'HN_USED_PUBLIC';
  static const hnUsedParentOverwhelm = 'HN_USED_PARENT_OVERWHELM';
  static const hnOutcomeRecorded = 'HN_OUTCOME_RECORDED';

  // Sleep Tonight
  static const stPlanStarted = 'ST_PLAN_STARTED';
  static const stStepCompleted = 'ST_STEP_COMPLETED';
  static const stNightWakeLogged = 'ST_NIGHT_WAKE_LOGGED';
  static const stEarlyWakeLogged = 'ST_EARLY_WAKE_LOGGED';
  static const stPlanAborted = 'ST_PLAN_ABORTED';
  static const stFeedTaperStep = 'ST_FEED_TAPER_STEP';
  static const stMorningReviewComplete = 'ST_MORNING_REVIEW_COMPLETE';
  static const stTonightOpen = 'ST_TONIGHT_OPEN';
  static const stFirstGuidanceRendered = 'ST_FIRST_GUIDANCE_RENDERED';
  static const stMoreOptionsOpen = 'ST_MORE_OPTIONS_OPEN';
  static const stScenarioChanged = 'ST_SCENARIO_CHANGED';
  static const stNextStepTapped = 'ST_NEXT_STEP_TAPPED';
  static const stRecapCompleted = 'ST_RECAP_COMPLETED';
  static const stMethodChangeInitiated = 'ST_METHOD_CHANGE_INITIATED';
  static const stMethodChanged = 'ST_METHOD_CHANGED';
  static const stUpdateWizardCompleted = 'ST_UPDATE_WIZARD_COMPLETED';

  // Plan & Progress
  static const ppExperimentSet = 'PP_EXPERIMENT_SET';
  static const ppExperimentCompleted = 'PP_EXPERIMENT_COMPLETED';
  static const ppRhythmUpdated = 'PP_RHYTHM_UPDATED';
  static const ppAppSessionStarted = 'PP_APP_SESSION_STARTED';
  static const ppAppCrash = 'PP_APP_CRASH';

  // Family Rules
  static const frRuleUpdated = 'FR_RULE_UPDATED';
  static const frDiffReceived = 'FR_DIFF_RECEIVED';
  static const frDiffAccepted = 'FR_DIFF_ACCEPTED';
  static const frConflictResolved = 'FR_CONFLICT_RESOLVED';
}

class EventOutcomes {
  static const improved = 'improved';
  static const unchanged = 'unchanged';
  static const escalated = 'escalated';
  static const aborted = 'aborted';
}

class EventTags {
  static const screen = 'screen';
  static const hunger = 'hunger';
  static const meals = 'meals';
  static const transition = 'transition';
  static const tired = 'tired';
  static const night = 'night';
  static const publicTag = 'public';
  static const screens = 'screens';
}

class EventContextLocation {
  static const home = 'home';
  static const publicLocation = 'public';
}

class EventMetadataKeys {
  static const incident = 'incident';
  static const ageBand = 'age_band';
  static const timerMinutes = 'timer_minutes';
  static const timeToActionSeconds = 'time_to_action_seconds';
  static const nearMeal = 'near_meal';
  static const screenOffRelated = 'screen_off_related';
  static const scenario = 'scenario';
  static const preference = 'preference';
  static const methodId = 'method_id';
  static const flowId = 'flow_id';
  static const policyVersion = 'policy_version';
  static const templateId = 'template_id';
  static const evidenceRefs = 'evidence_refs';
  static const timeToStartSeconds = 'time_to_start_seconds';
  static const completedStep = 'completed_step';
  static const wakeCount = 'wake_count';
  static const earlyWakeCount = 'early_wake_count';
  static const feedMode = 'feed_mode';
  static const wakesLogged = 'wakes_logged';
  static const experiment = 'experiment';
  static const block = 'block';
  static const ruleId = 'rule_id';
  static const author = 'author';
  static const diffId = 'diff_id';
  static const chosenDiffId = 'chosen_diff_id';
  static const appVersion = 'app_version';
  static const crashSource = 'crash_source';
  static const timeToFirstGuidanceMs = 'time_to_first_guidance_ms';
  static const timeBucket = 'time_bucket';
  static const effectiveTiming = 'effective_timing';
  static const reason = 'reason';
  static const toApproach = 'to_approach';
  static const durationMs = 'duration_ms';
  static const outcome = 'outcome';
}

class EventBusService {
  static const _boxName = 'event_bus_v1';
  static const schemaVersion = 1;
  static const taxonomyVersion = 1;

  static final Set<String> _allowedPillars = {
    Pillars.helpNow,
    Pillars.sleepTonight,
    Pillars.planProgress,
    Pillars.familyRules,
  };

  static final Set<String> _allowedTypes = {
    // Help Now
    EventTypes.hnUsedTantrum,
    EventTypes.hnUsedAggression,
    EventTypes.hnUsedUnsafe,
    EventTypes.hnUsedRefusal,
    EventTypes.hnUsedPublic,
    EventTypes.hnUsedParentOverwhelm,
    EventTypes.hnOutcomeRecorded,
    // Sleep Tonight
    EventTypes.stPlanStarted,
    EventTypes.stStepCompleted,
    EventTypes.stNightWakeLogged,
    EventTypes.stEarlyWakeLogged,
    EventTypes.stPlanAborted,
    EventTypes.stFeedTaperStep,
    EventTypes.stMorningReviewComplete,
    EventTypes.stTonightOpen,
    EventTypes.stFirstGuidanceRendered,
    EventTypes.stMoreOptionsOpen,
    EventTypes.stScenarioChanged,
    EventTypes.stNextStepTapped,
    EventTypes.stRecapCompleted,
    EventTypes.stMethodChangeInitiated,
    EventTypes.stMethodChanged,
    EventTypes.stUpdateWizardCompleted,
    // Plan & Progress
    EventTypes.ppExperimentSet,
    EventTypes.ppExperimentCompleted,
    EventTypes.ppRhythmUpdated,
    EventTypes.ppAppSessionStarted,
    EventTypes.ppAppCrash,
    // Family Rules
    EventTypes.frRuleUpdated,
    EventTypes.frDiffReceived,
    EventTypes.frDiffAccepted,
    EventTypes.frConflictResolved,
  };

  // Evidence-gating signals for Plan & Progress eligibility.
  // Intentionally excludes admin/config events (e.g., Family Rules updates).
  static const Set<String> _insightSimilarSignalTypes = {
    EventTypes.hnUsedTantrum,
    EventTypes.hnUsedAggression,
    EventTypes.hnUsedUnsafe,
    EventTypes.hnUsedRefusal,
    EventTypes.hnUsedPublic,
    EventTypes.hnUsedParentOverwhelm,
    EventTypes.stNightWakeLogged,
    EventTypes.stEarlyWakeLogged,
  };

  // "Sleep nights with logs" requires intervention/log events, not just plan start.
  static const Set<String> _insightSleepNightLogTypes = {
    EventTypes.stStepCompleted,
    EventTypes.stNightWakeLogged,
    EventTypes.stEarlyWakeLogged,
    EventTypes.stFeedTaperStep,
    EventTypes.stMorningReviewComplete,
  };

  static final Map<String, Set<String>> _typesByPillar = {
    Pillars.helpNow: {
      EventTypes.hnUsedTantrum,
      EventTypes.hnUsedAggression,
      EventTypes.hnUsedUnsafe,
      EventTypes.hnUsedRefusal,
      EventTypes.hnUsedPublic,
      EventTypes.hnUsedParentOverwhelm,
      EventTypes.hnOutcomeRecorded,
    },
    Pillars.sleepTonight: {
      EventTypes.stPlanStarted,
      EventTypes.stStepCompleted,
      EventTypes.stNightWakeLogged,
      EventTypes.stEarlyWakeLogged,
      EventTypes.stPlanAborted,
      EventTypes.stFeedTaperStep,
      EventTypes.stMorningReviewComplete,
      EventTypes.stTonightOpen,
      EventTypes.stFirstGuidanceRendered,
      EventTypes.stMoreOptionsOpen,
      EventTypes.stScenarioChanged,
      EventTypes.stNextStepTapped,
      EventTypes.stRecapCompleted,
      EventTypes.stMethodChangeInitiated,
      EventTypes.stMethodChanged,
      EventTypes.stUpdateWizardCompleted,
    },
    Pillars.planProgress: {
      EventTypes.ppExperimentSet,
      EventTypes.ppExperimentCompleted,
      EventTypes.ppRhythmUpdated,
      EventTypes.ppAppSessionStarted,
      EventTypes.ppAppCrash,
    },
    Pillars.familyRules: {
      EventTypes.frRuleUpdated,
      EventTypes.frDiffReceived,
      EventTypes.frDiffAccepted,
      EventTypes.frConflictResolved,
    },
  };

  static final Set<String> _allowedOutcomes = {
    EventOutcomes.improved,
    EventOutcomes.unchanged,
    EventOutcomes.escalated,
    EventOutcomes.aborted,
  };

  static final Set<String> _allowedIntensities = {'low', 'med', 'high'};
  static final Set<String> _allowedLocations = {
    EventContextLocation.home,
    EventContextLocation.publicLocation,
  };
  static final Set<String> _allowedTags = {
    EventTags.hunger,
    EventTags.meals,
    EventTags.transition,
    EventTags.tired,
    EventTags.night,
    EventTags.publicTag,
    EventTags.screens,
  };

  static const _metadataKeyPattern = r'^[a-z0-9_]{1,40}$';
  static const _maxMetadataEntries = 16;
  static const _maxMetadataValueLength = 180;
  static final Map<String, Set<String>> _allowedMetadataKeysByType = {
    EventTypes.hnUsedTantrum: {
      EventMetadataKeys.incident,
      EventMetadataKeys.ageBand,
      EventMetadataKeys.timerMinutes,
      EventMetadataKeys.timeToActionSeconds,
      EventMetadataKeys.nearMeal,
      EventMetadataKeys.screenOffRelated,
    },
    EventTypes.hnUsedAggression: {
      EventMetadataKeys.incident,
      EventMetadataKeys.ageBand,
      EventMetadataKeys.timerMinutes,
      EventMetadataKeys.timeToActionSeconds,
      EventMetadataKeys.nearMeal,
      EventMetadataKeys.screenOffRelated,
    },
    EventTypes.hnUsedUnsafe: {
      EventMetadataKeys.incident,
      EventMetadataKeys.ageBand,
      EventMetadataKeys.timerMinutes,
      EventMetadataKeys.timeToActionSeconds,
      EventMetadataKeys.nearMeal,
      EventMetadataKeys.screenOffRelated,
    },
    EventTypes.hnUsedRefusal: {
      EventMetadataKeys.incident,
      EventMetadataKeys.ageBand,
      EventMetadataKeys.timerMinutes,
      EventMetadataKeys.timeToActionSeconds,
      EventMetadataKeys.nearMeal,
      EventMetadataKeys.screenOffRelated,
    },
    EventTypes.hnUsedPublic: {
      EventMetadataKeys.incident,
      EventMetadataKeys.ageBand,
      EventMetadataKeys.timerMinutes,
      EventMetadataKeys.timeToActionSeconds,
      EventMetadataKeys.nearMeal,
      EventMetadataKeys.screenOffRelated,
    },
    EventTypes.hnUsedParentOverwhelm: {
      EventMetadataKeys.incident,
      EventMetadataKeys.ageBand,
      EventMetadataKeys.timerMinutes,
      EventMetadataKeys.timeToActionSeconds,
      EventMetadataKeys.nearMeal,
      EventMetadataKeys.screenOffRelated,
    },
    EventTypes.hnOutcomeRecorded: {
      EventMetadataKeys.incident,
      EventMetadataKeys.ageBand,
      EventMetadataKeys.timerMinutes,
      EventMetadataKeys.nearMeal,
      EventMetadataKeys.screenOffRelated,
    },
    EventTypes.stPlanStarted: {
      EventMetadataKeys.scenario,
      EventMetadataKeys.preference,
      EventMetadataKeys.methodId,
      EventMetadataKeys.flowId,
      EventMetadataKeys.policyVersion,
      EventMetadataKeys.templateId,
      EventMetadataKeys.evidenceRefs,
      EventMetadataKeys.timeToStartSeconds,
    },
    EventTypes.stStepCompleted: {EventMetadataKeys.completedStep},
    EventTypes.stNightWakeLogged: {EventMetadataKeys.wakeCount},
    EventTypes.stEarlyWakeLogged: {EventMetadataKeys.earlyWakeCount},
    EventTypes.stPlanAborted: <String>{},
    EventTypes.stFeedTaperStep: {EventMetadataKeys.feedMode},
    EventTypes.stMorningReviewComplete: {EventMetadataKeys.wakesLogged},
    EventTypes.stTonightOpen: <String>{},
    EventTypes.stFirstGuidanceRendered: {
      EventMetadataKeys.timeToFirstGuidanceMs,
      EventMetadataKeys.scenario,
    },
    EventTypes.stMoreOptionsOpen: <String>{},
    EventTypes.stScenarioChanged: {EventMetadataKeys.scenario},
    EventTypes.stNextStepTapped: <String>{},
    EventTypes.stRecapCompleted: {
      EventMetadataKeys.outcome,
      EventMetadataKeys.timeBucket,
    },
    EventTypes.stMethodChangeInitiated: <String>{},
    EventTypes.stMethodChanged: {
      EventMetadataKeys.reason,
      EventMetadataKeys.effectiveTiming,
      EventMetadataKeys.toApproach,
    },
    EventTypes.stUpdateWizardCompleted: {EventMetadataKeys.durationMs},
    EventTypes.ppExperimentSet: {EventMetadataKeys.experiment},
    EventTypes.ppExperimentCompleted: {EventMetadataKeys.experiment},
    EventTypes.ppRhythmUpdated: {EventMetadataKeys.block},
    EventTypes.ppAppSessionStarted: {EventMetadataKeys.appVersion},
    EventTypes.ppAppCrash: {
      EventMetadataKeys.appVersion,
      EventMetadataKeys.crashSource,
    },
    EventTypes.frRuleUpdated: {
      EventMetadataKeys.ruleId,
      EventMetadataKeys.author,
    },
    EventTypes.frDiffReceived: {
      EventMetadataKeys.ruleId,
      EventMetadataKeys.diffId,
    },
    EventTypes.frDiffAccepted: {
      EventMetadataKeys.ruleId,
      EventMetadataKeys.diffId,
    },
    EventTypes.frConflictResolved: {
      EventMetadataKeys.ruleId,
      EventMetadataKeys.chosenDiffId,
    },
  };

  static Box<dynamic>? _box;

  static Future<Box<dynamic>> _ensureBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<dynamic>(_boxName);
    }
    return _box!;
  }

  static bool _isNight(DateTime dt) {
    return SpecPolicy.isNight(dt);
  }

  static Set<String> _applyAutoTags({
    required String type,
    required Set<String> tags,
    required Map<String, String> metadata,
  }) {
    if (type == EventTypes.stNightWakeLogged ||
        type == EventTypes.stEarlyWakeLogged) {
      tags.add(EventTags.tired);
      tags.add(EventTags.night);
    }

    if (type == EventTypes.hnUsedPublic) {
      tags.add(EventTags.publicTag);
    }

    if (type == EventTypes.hnUsedRefusal && metadata['near_meal'] == '1') {
      tags.add(EventTags.hunger);
      tags.add(EventTags.meals);
    }

    if (metadata['incident'] == 'transition_meltdown') {
      tags.add(EventTags.transition);
    }

    if (metadata['screen_off_related'] == '1') {
      tags.add(EventTags.screens);
    }

    return tags;
  }

  static String _makeEventId(DateTime ts) {
    final rand = Random().nextInt(1 << 20).toRadixString(16);
    return '${ts.microsecondsSinceEpoch}-$rand';
  }

  static String _canonicalTag(String rawTag) {
    final tag = rawTag.trim().toLowerCase();
    if (tag == EventTags.screen) return EventTags.screens;
    return tag;
  }

  static List<String> _sanitizeTags(List<String> rawTags) {
    final sanitized = <String>{};
    for (final tag in rawTags) {
      final canonical = _canonicalTag(tag);
      if (!_allowedTags.contains(canonical)) {
        throw ArgumentError.value(
          tag,
          'tags',
          'Unknown tag "$tag". Allowed: ${_allowedTags.toList()..sort()}',
        );
      }
      sanitized.add(canonical);
    }
    return sanitized.toList()..sort();
  }

  static Map<String, String> _sanitizeMetadata(Map<String, String> metadata) {
    if (metadata.length > _maxMetadataEntries) {
      throw ArgumentError.value(
        metadata.length,
        'metadata.length',
        'Metadata supports up to $_maxMetadataEntries entries.',
      );
    }

    final keyRegex = RegExp(_metadataKeyPattern);
    final out = <String, String>{};
    for (final entry in metadata.entries) {
      final key = entry.key.trim();
      final value = entry.value.trim();
      if (!keyRegex.hasMatch(key)) {
        throw ArgumentError.value(
          key,
          'metadata',
          'Metadata keys must match $_metadataKeyPattern.',
        );
      }
      if (value.length > _maxMetadataValueLength) {
        throw ArgumentError.value(
          value,
          'metadata[$key]',
          'Metadata values are limited to $_maxMetadataValueLength chars.',
        );
      }
      out[key] = value;
    }
    return out;
  }

  static Map<String, String> _enforceMetadataKeysForType({
    required String type,
    required Map<String, String> metadata,
    required bool strict,
  }) {
    final allowed = _allowedMetadataKeysByType[type] ?? const <String>{};
    if (metadata.isEmpty) return const <String, String>{};

    final out = <String, String>{};
    for (final entry in metadata.entries) {
      if (!allowed.contains(entry.key)) {
        if (strict) {
          throw ArgumentError.value(
            entry.key,
            'metadata',
            'Metadata key "${entry.key}" is not allowed for event type $type.',
          );
        }
        continue;
      }
      out[entry.key] = entry.value;
    }
    return out;
  }

  static Map<String, dynamic> _normalizeContext({
    required DateTime ts,
    dynamic rawContext,
  }) {
    if (rawContext is! Map) {
      return {'night': _isNight(ts), 'location': EventContextLocation.home};
    }
    final mapped = Map<String, dynamic>.from(rawContext);
    final rawNight = mapped['night'];
    final rawLocation =
        mapped['location']?.toString() ?? EventContextLocation.home;
    final night = rawNight is bool ? rawNight : _isNight(ts);
    final location = _allowedLocations.contains(rawLocation)
        ? rawLocation
        : EventContextLocation.home;
    return {'night': night, 'location': location};
  }

  static String _pillarForType(String type) {
    for (final entry in _typesByPillar.entries) {
      if (entry.value.contains(type)) return entry.key;
    }
    return '';
  }

  static Map<String, dynamic>? _normalizeEvent(dynamic raw) {
    if (raw is! Map) return null;
    final mapped = Map<String, dynamic>.from(raw);

    final ts = DateTime.tryParse(mapped['timestamp']?.toString() ?? '');
    if (ts == null) return null;

    final type = mapped['type']?.toString() ?? '';
    if (!_allowedTypes.contains(type)) return null;

    var pillar = mapped['pillar']?.toString() ?? '';
    if (!_allowedPillars.contains(pillar) ||
        !(_typesByPillar[pillar]?.contains(type) ?? false)) {
      pillar = _pillarForType(type);
    }
    if (!_allowedPillars.contains(pillar)) return null;

    final childId = mapped['child_id']?.toString() ?? '';
    if (childId.isEmpty) return null;

    final rawTags = (mapped['tags'] is List)
        ? (mapped['tags'] as List).map((e) => e.toString()).toList()
        : <String>[];
    List<String> tags;
    try {
      tags = _sanitizeTags(rawTags);
    } catch (_) {
      tags = const <String>[];
    }

    final rawMetadata = mapped['metadata'];
    final metadata = <String, String>{};
    if (rawMetadata is Map) {
      for (final entry in rawMetadata.entries) {
        metadata[entry.key.toString()] = entry.value.toString();
      }
    }
    Map<String, String> sanitizedMetadata;
    try {
      sanitizedMetadata = _sanitizeMetadata(metadata);
      sanitizedMetadata = _enforceMetadataKeysForType(
        type: type,
        metadata: sanitizedMetadata,
        strict: false,
      );
    } catch (_) {
      sanitizedMetadata = const <String, String>{};
    }
    final autoTagged = _applyAutoTags(
      type: type,
      tags: tags.toSet(),
      metadata: sanitizedMetadata,
    ).toList()..sort();

    final linkedPlanIdRaw = mapped['linked_plan_id']?.toString();
    final linkedPlanId = (linkedPlanIdRaw == null || linkedPlanIdRaw.isEmpty)
        ? null
        : linkedPlanIdRaw;

    final outcomeRaw = mapped['outcome']?.toString();
    final outcome = outcomeRaw == null || outcomeRaw.isEmpty
        ? null
        : outcomeRaw.toLowerCase();
    if (outcome != null && !_allowedOutcomes.contains(outcome)) {
      return null;
    }

    final intensityRaw = mapped['intensity']?.toString();
    final intensity = intensityRaw == null || intensityRaw.isEmpty
        ? null
        : intensityRaw.toLowerCase();
    if (intensity != null && !_allowedIntensities.contains(intensity)) {
      return null;
    }

    return {
      'schema_version': schemaVersion,
      'taxonomy_version': taxonomyVersion,
      'event_id': mapped['event_id']?.toString().isNotEmpty == true
          ? mapped['event_id'].toString()
          : _makeEventId(ts),
      'timestamp': ts.toIso8601String(),
      'child_id': childId,
      'pillar': pillar,
      'type': type,
      'context': _normalizeContext(ts: ts, rawContext: mapped['context']),
      'tags': autoTagged,
      'intensity': intensity,
      'linked_plan_id': linkedPlanId,
      'outcome': outcome,
      'metadata': sanitizedMetadata,
    };
  }

  static Future<void> emit({
    required String childId,
    required String pillar,
    required String type,
    String location = EventContextLocation.home,
    List<String> tags = const [],
    String? intensity,
    String? linkedPlanId,
    String? outcome,
    Map<String, String> metadata = const {},
    DateTime? timestamp,
  }) async {
    if (childId.trim().isEmpty) {
      throw ArgumentError.value(childId, 'childId', 'childId cannot be empty.');
    }
    if (!_allowedPillars.contains(pillar)) {
      throw ArgumentError.value(
        pillar,
        'pillar',
        'Unknown pillar. Allowed: ${_allowedPillars.toList()..sort()}',
      );
    }
    if (!_allowedTypes.contains(type)) {
      throw ArgumentError.value(
        type,
        'type',
        'Unknown event type. Allowed taxonomy v$taxonomyVersion',
      );
    }
    if (!(_typesByPillar[pillar]?.contains(type) ?? false)) {
      throw ArgumentError('Event type $type is not valid for pillar $pillar.');
    }
    if (!_allowedLocations.contains(location)) {
      throw ArgumentError.value(
        location,
        'location',
        'Unknown location. Allowed: ${_allowedLocations.toList()..sort()}',
      );
    }
    final normalizedOutcome = outcome?.toLowerCase();
    if (normalizedOutcome != null &&
        !_allowedOutcomes.contains(normalizedOutcome)) {
      throw ArgumentError.value(
        outcome,
        'outcome',
        'Unknown outcome. Allowed: ${_allowedOutcomes.toList()..sort()}',
      );
    }
    final normalizedIntensity = intensity?.toLowerCase();
    if (normalizedIntensity != null &&
        !_allowedIntensities.contains(normalizedIntensity)) {
      throw ArgumentError.value(
        intensity,
        'intensity',
        'Unknown intensity. Allowed: ${_allowedIntensities.toList()..sort()}',
      );
    }

    final ts = timestamp ?? DateTime.now();
    final box = await _ensureBox();
    final sanitizedMetadata = _sanitizeMetadata(metadata);
    final typedMetadata = _enforceMetadataKeysForType(
      type: type,
      metadata: sanitizedMetadata,
      strict: true,
    );
    final sanitizedTags = _sanitizeTags(tags);
    final mergedTags = _applyAutoTags(
      type: type,
      tags: sanitizedTags.toSet(),
      metadata: typedMetadata,
    ).toList()..sort();

    final event = <String, dynamic>{
      'schema_version': schemaVersion,
      'taxonomy_version': taxonomyVersion,
      'event_id': _makeEventId(ts),
      'timestamp': ts.toIso8601String(),
      'child_id': childId.trim(),
      'pillar': pillar,
      'type': type,
      'context': <String, dynamic>{'night': _isNight(ts), 'location': location},
      'tags': mergedTags,
      'intensity': normalizedIntensity,
      'linked_plan_id': linkedPlanId,
      'outcome': normalizedOutcome,
      'metadata': typedMetadata,
    };

    await box.add(event);
  }

  static Future<void> emitHelpNowIncidentUsed({
    required String childId,
    required String type,
    required String incident,
    required String ageBand,
    required int timerMinutes,
    required String location,
    int? timeToActionSeconds,
    List<String> tags = const [],
    bool nearMeal = false,
    bool screenOffRelated = false,
  }) {
    const allowedIncidentTypes = <String>{
      EventTypes.hnUsedTantrum,
      EventTypes.hnUsedAggression,
      EventTypes.hnUsedUnsafe,
      EventTypes.hnUsedRefusal,
      EventTypes.hnUsedPublic,
      EventTypes.hnUsedParentOverwhelm,
    };
    if (!allowedIncidentTypes.contains(type)) {
      throw ArgumentError.value(
        type,
        'type',
        'Not a valid Help Now incident event type.',
      );
    }

    return emit(
      childId: childId,
      pillar: Pillars.helpNow,
      type: type,
      location: location,
      tags: tags,
      metadata: {
        EventMetadataKeys.incident: incident,
        EventMetadataKeys.ageBand: ageBand,
        EventMetadataKeys.timerMinutes: '$timerMinutes',
        if (timeToActionSeconds != null)
          EventMetadataKeys.timeToActionSeconds: '$timeToActionSeconds',
        if (nearMeal) EventMetadataKeys.nearMeal: '1',
        if (screenOffRelated) EventMetadataKeys.screenOffRelated: '1',
      },
    );
  }

  static Future<void> emitHelpNowOutcomeRecorded({
    required String childId,
    required String incident,
    required String ageBand,
    required int timerMinutes,
    required String location,
    required String outcome,
    List<String> tags = const [],
    bool nearMeal = false,
    bool screenOffRelated = false,
  }) {
    return emit(
      childId: childId,
      pillar: Pillars.helpNow,
      type: EventTypes.hnOutcomeRecorded,
      location: location,
      tags: tags,
      outcome: outcome,
      metadata: {
        EventMetadataKeys.incident: incident,
        EventMetadataKeys.ageBand: ageBand,
        EventMetadataKeys.timerMinutes: '$timerMinutes',
        if (nearMeal) EventMetadataKeys.nearMeal: '1',
        if (screenOffRelated) EventMetadataKeys.screenOffRelated: '1',
      },
    );
  }

  static Future<void> emitSleepPlanStarted({
    required String childId,
    required String linkedPlanId,
    required String scenario,
    required String preference,
    required String methodId,
    required String flowId,
    required String policyVersion,
    String? templateId,
    int? timeToStartSeconds,
    List<String> evidenceRefs = const [],
  }) {
    return emit(
      childId: childId,
      pillar: Pillars.sleepTonight,
      type: EventTypes.stPlanStarted,
      linkedPlanId: linkedPlanId,
      metadata: {
        EventMetadataKeys.scenario: scenario,
        EventMetadataKeys.preference: preference,
        EventMetadataKeys.methodId: methodId,
        EventMetadataKeys.flowId: flowId,
        EventMetadataKeys.policyVersion: policyVersion,
        EventMetadataKeys.templateId: templateId ?? flowId,
        if (timeToStartSeconds != null)
          EventMetadataKeys.timeToStartSeconds: '$timeToStartSeconds',
        if (evidenceRefs.isNotEmpty)
          EventMetadataKeys.evidenceRefs: evidenceRefs.join(','),
      },
    );
  }

  static Future<void> emitSleepStepCompleted({
    required String childId,
    required String linkedPlanId,
    required int completedStep,
  }) {
    return emit(
      childId: childId,
      pillar: Pillars.sleepTonight,
      type: EventTypes.stStepCompleted,
      linkedPlanId: linkedPlanId,
      metadata: {EventMetadataKeys.completedStep: '$completedStep'},
    );
  }

  static Future<void> emitSleepNightWakeLogged({
    required String childId,
    required String linkedPlanId,
    required int wakeCount,
  }) {
    return emit(
      childId: childId,
      pillar: Pillars.sleepTonight,
      type: EventTypes.stNightWakeLogged,
      linkedPlanId: linkedPlanId,
      metadata: {EventMetadataKeys.wakeCount: '$wakeCount'},
    );
  }

  static Future<void> emitSleepEarlyWakeLogged({
    required String childId,
    required String linkedPlanId,
    required int earlyWakeCount,
  }) {
    return emit(
      childId: childId,
      pillar: Pillars.sleepTonight,
      type: EventTypes.stEarlyWakeLogged,
      linkedPlanId: linkedPlanId,
      metadata: {EventMetadataKeys.earlyWakeCount: '$earlyWakeCount'},
    );
  }

  static Future<void> emitSleepFeedTaperStep({
    required String childId,
    required String linkedPlanId,
    required String feedMode,
  }) {
    return emit(
      childId: childId,
      pillar: Pillars.sleepTonight,
      type: EventTypes.stFeedTaperStep,
      linkedPlanId: linkedPlanId,
      metadata: {EventMetadataKeys.feedMode: feedMode},
    );
  }

  static Future<void> emitSleepPlanAborted({
    required String childId,
    required String linkedPlanId,
  }) {
    return emit(
      childId: childId,
      pillar: Pillars.sleepTonight,
      type: EventTypes.stPlanAborted,
      linkedPlanId: linkedPlanId,
      outcome: EventOutcomes.aborted,
    );
  }

  static Future<void> emitSleepMorningReviewComplete({
    required String childId,
    required String linkedPlanId,
    required int wakesLogged,
  }) {
    return emit(
      childId: childId,
      pillar: Pillars.sleepTonight,
      type: EventTypes.stMorningReviewComplete,
      linkedPlanId: linkedPlanId,
      metadata: {EventMetadataKeys.wakesLogged: '$wakesLogged'},
    );
  }

  static Future<void> emitPlanExperimentSet({
    required String childId,
    required String experiment,
  }) {
    return emit(
      childId: childId,
      pillar: Pillars.planProgress,
      type: EventTypes.ppExperimentSet,
      metadata: {EventMetadataKeys.experiment: experiment},
    );
  }

  static Future<void> emitPlanExperimentCompleted({
    required String childId,
    required String experiment,
    String outcome = EventOutcomes.improved,
  }) {
    return emit(
      childId: childId,
      pillar: Pillars.planProgress,
      type: EventTypes.ppExperimentCompleted,
      metadata: {EventMetadataKeys.experiment: experiment},
      outcome: outcome,
    );
  }

  static Future<void> emitPlanRhythmUpdated({
    required String childId,
    required String block,
  }) {
    return emit(
      childId: childId,
      pillar: Pillars.planProgress,
      type: EventTypes.ppRhythmUpdated,
      metadata: {EventMetadataKeys.block: block},
    );
  }

  static Future<void> emitPlanAppSessionStarted({
    required String childId,
    String? appVersion,
  }) {
    return emit(
      childId: childId,
      pillar: Pillars.planProgress,
      type: EventTypes.ppAppSessionStarted,
      metadata: {
        if (appVersion != null && appVersion.isNotEmpty)
          EventMetadataKeys.appVersion: appVersion,
      },
    );
  }

  static Future<void> emitPlanAppCrash({
    required String childId,
    String? appVersion,
    String? crashSource,
  }) {
    return emit(
      childId: childId,
      pillar: Pillars.planProgress,
      type: EventTypes.ppAppCrash,
      outcome: EventOutcomes.escalated,
      metadata: {
        if (appVersion != null && appVersion.isNotEmpty)
          EventMetadataKeys.appVersion: appVersion,
        if (crashSource != null && crashSource.isNotEmpty)
          EventMetadataKeys.crashSource: crashSource,
      },
    );
  }

  static Future<void> emitFamilyRuleUpdated({
    required String childId,
    required String ruleId,
    required String author,
  }) {
    return emit(
      childId: childId,
      pillar: Pillars.familyRules,
      type: EventTypes.frRuleUpdated,
      metadata: {
        EventMetadataKeys.ruleId: ruleId,
        EventMetadataKeys.author: author,
      },
    );
  }

  static Future<void> emitFamilyDiffReceived({
    required String childId,
    required String ruleId,
    required String diffId,
  }) {
    return emit(
      childId: childId,
      pillar: Pillars.familyRules,
      type: EventTypes.frDiffReceived,
      metadata: {
        EventMetadataKeys.ruleId: ruleId,
        EventMetadataKeys.diffId: diffId,
      },
    );
  }

  static Future<void> emitFamilyDiffAccepted({
    required String childId,
    required String ruleId,
    required String diffId,
  }) {
    return emit(
      childId: childId,
      pillar: Pillars.familyRules,
      type: EventTypes.frDiffAccepted,
      metadata: {
        EventMetadataKeys.ruleId: ruleId,
        EventMetadataKeys.diffId: diffId,
      },
    );
  }

  static Future<void> emitFamilyConflictResolved({
    required String childId,
    required String ruleId,
    required String chosenDiffId,
  }) {
    return emit(
      childId: childId,
      pillar: Pillars.familyRules,
      type: EventTypes.frConflictResolved,
      metadata: {
        EventMetadataKeys.ruleId: ruleId,
        EventMetadataKeys.chosenDiffId: chosenDiffId,
      },
    );
  }

  static Future<List<Map<String, dynamic>>> allEvents() async {
    final box = await _ensureBox();
    final entries = box.toMap().entries;
    final out = <Map<String, dynamic>>[];

    for (final entry in entries) {
      final normalized = _normalizeEvent(entry.value);
      if (normalized == null) continue;

      final raw = entry.value is Map
          ? Map<String, dynamic>.from(entry.value as Map)
          : <String, dynamic>{};
      if (jsonEncode(raw) != jsonEncode(normalized)) {
        await box.put(entry.key, normalized);
      }
      out.add(normalized);
    }

    out.sort((a, b) {
      final aTs = DateTime.tryParse(a['timestamp']?.toString() ?? '');
      final bTs = DateTime.tryParse(b['timestamp']?.toString() ?? '');
      if (aTs == null && bTs == null) return 0;
      if (aTs == null) return 1;
      if (bTs == null) return -1;
      return bTs.compareTo(aTs);
    });
    return out;
  }

  static Future<List<Map<String, dynamic>>> eventsInLastDays(int days) async {
    return eventsInLastDaysForChild(days: days);
  }

  static Future<List<Map<String, dynamic>>> eventsInLastDaysForChild({
    required int days,
    String? childId,
  }) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final events = await allEvents();
    return events.where((e) {
      if (childId != null && e['child_id'] != childId) {
        return false;
      }
      final tsRaw = e['timestamp'];
      if (tsRaw is! String) return false;
      final ts = DateTime.tryParse(tsRaw);
      if (ts == null) return false;
      return !ts.isBefore(since);
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> eventsByTypeInLastDays({
    required String type,
    required int days,
    String? childId,
  }) async {
    final events = await eventsInLastDaysForChild(days: days, childId: childId);
    return events.where((e) => e['type'] == type).toList();
  }

  static Future<bool> isInsightEligible({required String childId}) async {
    final recent = await eventsInLastDaysForChild(
      days: SpecPolicy.insightWindowDays,
      childId: childId,
    );
    final counts = <String, int>{};

    for (final e in recent) {
      final type = e['type'];
      if (type is! String || !_insightSimilarSignalTypes.contains(type)) {
        continue;
      }
      counts[type] = (counts[type] ?? 0) + 1;
    }

    final hasEnoughSimilar = counts.values.any(
      (count) => count >= SpecPolicy.insightSimilarEventsThreshold,
    );
    if (hasEnoughSimilar) return true;

    final all = await allEvents();
    final loggedSleepNights = <String>{};

    for (final e in all) {
      if (e['child_id'] != childId) continue;
      final type = e['type'];
      if (type is! String || !_insightSleepNightLogTypes.contains(type)) {
        continue;
      }

      final linkedPlanId = e['linked_plan_id'];
      if (linkedPlanId is String && linkedPlanId.isNotEmpty) {
        loggedSleepNights.add(linkedPlanId);
        continue;
      }

      final tsRaw = e['timestamp'];
      if (tsRaw is! String) continue;
      final ts = DateTime.tryParse(tsRaw);
      if (ts == null) continue;
      final dayKey =
          '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}';
      loggedSleepNights.add(dayKey);
    }

    return loggedSleepNights.length >= SpecPolicy.insightSleepNightsThreshold;
  }

  static Future<void> clearAll() async {
    final box = await _ensureBox();
    await box.clear();
  }
}
