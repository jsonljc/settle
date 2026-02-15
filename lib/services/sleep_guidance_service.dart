import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

class SleepGuidanceStep {
  const SleepGuidanceStep({
    required this.stepId,
    required this.title,
    required this.say,
    required this.doStep,
    required this.minutes,
  });

  final String stepId;
  final String title;
  final String say;
  final String doStep;
  final int minutes;
}

class SleepGuidancePlanTemplate {
  const SleepGuidancePlanTemplate({
    required this.methodId,
    required this.flowId,
    required this.feedPolicyId,
    required this.policyVersion,
    required this.evidenceRefs,
    required this.steps,
    required this.escalationRule,
  });

  final String methodId;
  final String flowId;
  final String feedPolicyId;
  final String policyVersion;
  final List<String> evidenceRefs;
  final List<SleepGuidanceStep> steps;
  final String escalationRule;
}

class SleepGuidanceStopResult {
  const SleepGuidanceStopResult({
    required this.blocked,
    required this.message,
    required this.triggeredRuleIds,
    required this.evidenceRefs,
  });

  final bool blocked;
  final String message;
  final List<String> triggeredRuleIds;
  final List<String> evidenceRefs;
}

class SleepDayPlanWindow {
  const SleepDayPlanWindow({
    required this.slotId,
    required this.startWindowMinutes,
    required this.endWindowMinutes,
    required this.targetDurationMinutes,
    required this.optional,
  });

  final String slotId;
  final int startWindowMinutes;
  final int endWindowMinutes;
  final int targetDurationMinutes;
  final bool optional;
}

class SleepDayRuntimePlan {
  const SleepDayRuntimePlan({
    required this.ageBandId,
    required this.templateId,
    required this.wakeWindowProfileId,
    required this.rulesetId,
    required this.policyVersion,
    required this.evidenceRefs,
    required this.napWindows,
    required this.bedtimeWindowEarliest,
    required this.bedtimeWindowLatest,
    required this.appliedRuleIds,
    required this.appliedConstraintIds,
    required this.rescueProtocolIds,
    required this.notes,
    required this.recommendedSupportMode,
  });

  final String ageBandId;
  final String templateId;
  final String wakeWindowProfileId;
  final String rulesetId;
  final String policyVersion;
  final List<String> evidenceRefs;
  final List<SleepDayPlanWindow> napWindows;
  final int bedtimeWindowEarliest;
  final int bedtimeWindowLatest;
  final List<String> appliedRuleIds;
  final List<String> appliedConstraintIds;
  final List<String> rescueProtocolIds;
  final List<String> notes;
  final String? recommendedSupportMode;
}

class SleepEvidenceSource {
  const SleepEvidenceSource({
    required this.id,
    required this.citation,
    required this.publisher,
    required this.url,
    required this.year,
    required this.type,
  });

  final String id;
  final String citation;
  final String publisher;
  final String url;
  final int? year;
  final String type;
}

class SleepEvidenceItem {
  const SleepEvidenceItem({
    required this.id,
    required this.title,
    required this.claim,
    required this.evidenceLevel,
    required this.sources,
  });

  final String id;
  final String title;
  final String claim;
  final String evidenceLevel;
  final List<SleepEvidenceSource> sources;
}

class SleepGuidanceService {
  SleepGuidanceService._();

  static final SleepGuidanceService instance = SleepGuidanceService._();

  static const _nightModulePath = 'assets/guidance/sleep_tonight_complete.json';
  static const _dayModulePath =
      'assets/guidance/sleep_day_planner_complete.json';
  static const _evidencePath =
      'assets/guidance/sleep_evidence_registry_v1.json';

  Map<String, dynamic>? _nightModule;
  Map<String, dynamic>? _dayModule;
  Map<String, dynamic>? _evidenceRegistry;

  Future<void> _ensureLoaded() async {
    _nightModule ??= await _loadJson(_nightModulePath);
    _dayModule ??= await _loadJson(_dayModulePath);
    _evidenceRegistry ??= await _loadJson(_evidencePath);
  }

  Future<Map<String, dynamic>> _loadJson(String path) async {
    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw StateError('Expected top-level object in $path');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<SleepGuidanceStopResult> evaluateStopRules({
    required bool redFlagHealthFlag,
    required bool unsafeSleepEnvironmentFlag,
    bool dehydrationSigns = false,
    bool repeatedVomiting = false,
    bool severePainIndicators = false,
    bool feedingRefusalWithPainSigns = false,
    int episodeDurationMinutes = 0,
  }) async {
    await _ensureLoaded();

    final medicalRedFlag =
        redFlagHealthFlag ||
        dehydrationSigns ||
        repeatedVomiting ||
        severePainIndicators ||
        feedingRefusalWithPainSigns;

    final metrics = <String, dynamic>{
      'red_flag_health_flag': medicalRedFlag,
      'unsafe_sleep_environment_flag': unsafeSleepEnvironmentFlag,
      'episode_duration_minutes': episodeDurationMinutes,
      'dehydration_signs': dehydrationSigns,
      'repeated_vomiting': repeatedVomiting,
      'severe_pain_indicators': severePainIndicators,
      'feeding_refusal_with_pain_signs': feedingRefusalWithPainSigns,
    };

    final safety = _asMap(_nightModule?['safety']);
    final stopRules = _asMapList(safety['stopRules']);

    final matched = <Map<String, dynamic>>[];
    for (final rule in stopRules) {
      final enabled = rule['enabled'] as bool? ?? true;
      if (!enabled) continue;
      if (_matchesRule(rule, metrics)) {
        matched.add(rule);
      }
    }

    matched.sort(
      (a, b) => (a['priority'] as int? ?? 999).compareTo(
        b['priority'] as int? ?? 999,
      ),
    );

    if (matched.isEmpty) {
      return const SleepGuidanceStopResult(
        blocked: false,
        message: '',
        triggeredRuleIds: [],
        evidenceRefs: [],
      );
    }

    final first = matched.first;
    final copyKey = first['copyKey'] as String? ?? '';
    final message = _nightText(
      copyKey,
      fallback: 'Pause plan, comfort first, and seek guidance if concerned.',
    );

    final ruleIds = matched
        .map((r) => r['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    final refs = <String>{};
    for (final ruleId in ruleIds) {
      refs.addAll(_registryBindings('stopRules', ruleId));
    }

    return SleepGuidanceStopResult(
      blocked: true,
      message: message,
      triggeredRuleIds: ruleIds,
      evidenceRefs: refs.toList()..sort(),
    );
  }

  Future<SleepGuidancePlanTemplate> buildTonightPlan({
    required int ageMonths,
    required String scenario,
    required String preference,
    required bool feedingAssociation,
    required String feedMode,
    String? lockedMethodId,
    String supportMode = 'none',
  }) async {
    await _ensureLoaded();

    final boundedAge = ageMonths.clamp(0, 35);
    final ageBand = _ageBandForMonths(boundedAge);

    var methodId = _resolveMethodIdForTonight(
      preference: preference,
      ageBand: ageBand,
      lockedMethodId: lockedMethodId,
    );
    var method = _methodById(methodId);
    if (method == null) {
      methodId = ageBand['defaultMethodId']?.toString() ?? 'check_console';
      method = _methodById(methodId);
    }
    method ??= _methodById('check_console') ?? _asMap({});

    final episodeType = _episodeForScenario(scenario);
    final flowsByEpisode = _asMap(method['flowsByEpisode']);
    var flowId =
        _asMap(flowsByEpisode[episodeType])['flowId']?.toString() ?? '';
    if (flowId.isEmpty) {
      flowId = _asMap(flowsByEpisode['bedtime'])['flowId']?.toString() ?? '';
    }

    var flow = _flowById(flowId);
    if (flow == null) {
      final flows = _asMapList(_nightModule?['flows']);
      flow = flows.isNotEmpty ? flows.first : _asMap({});
      flowId = flow['id']?.toString() ?? 'fallback_flow';
    }

    final methodTimers = _asMapList(method['timerProfiles']);
    final steps = _asMapList(flow['steps']);

    final outSteps = <SleepGuidanceStep>[];
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      final stepId = step['id']?.toString() ?? 'step_$i';
      final title = _nightText(
        step['titleKey']?.toString() ?? '',
        fallback: 'Step ${i + 1}',
      );
      final say = _firstTextFromKeys(
        step['sayKeys'],
        fallback: 'It is sleep time.',
      );
      final doStep = _firstTextFromKeys(
        step['doKeys'],
        fallback: 'Keep response short and consistent.',
      );
      final timerId = step['timerProfileId']?.toString() ?? '';
      final timer = _timerMinutes(timerId, methodTimers);

      outSteps.add(
        SleepGuidanceStep(
          stepId: stepId,
          title: title,
          say: say,
          doStep: doStep,
          minutes: timer,
        ),
      );
    }

    final feedPolicyId = _feedPolicyFor(
      feedMode: feedMode,
      feedingAssociation: feedingAssociation,
      ageBand: ageBand,
    );

    final evidenceRefs = <String>{
      ..._registryBindings('methods', methodId),
      if (feedingAssociation)
        ..._registryBindings('feedingPolicies', feedPolicyId),
    };

    final escalationRule = _rescueRuleForEpisode(episodeType);

    final nightMeta = _asMap(_nightModule?['meta']);
    final evidenceMeta = _asMap(_evidenceRegistry?['meta']);
    final policyVersion =
        '${nightMeta['schemaVersion'] ?? 'sleep_tonight_module'}|${evidenceMeta['schemaVersion'] ?? 'sleep_evidence_registry'}';

    return SleepGuidancePlanTemplate(
      methodId: methodId,
      flowId: flowId,
      feedPolicyId: feedPolicyId,
      policyVersion: policyVersion,
      evidenceRefs: evidenceRefs.toList()..sort(),
      steps: outSteps,
      escalationRule: escalationRule,
    );
  }

  Future<SleepDayRuntimePlan> buildDayPlannerRuntime({
    required int ageMonths,
    required int wakeAnchorMinutes,
    required int bedtimeTargetMinutes,
    bool daycareConstrained = false,
    bool lateNapFlag = false,
    bool travelFlag = false,
    String supportMode = 'none',
    bool earlyWakeToday = false,
    bool bedtimeResistanceToday = false,
    bool shortNapsRecent = false,
    bool overtiredSignsToday = false,
    bool undertiredSignsToday = false,
    bool splitNightRecent = false,
    bool falseStartRecent = false,
    bool longNapsRecent = false,
    bool napTransitionInProgress = false,
    int lastNapDurationMinutes = 0,
    String lastNapSlotId = 'nap2',
    int totalDaySleepMinutesToday = 0,
    bool allNapsFailedToday = false,
    bool microNapFeasible = true,
    int minutesUntilBedtime = 240,
  }) async {
    await _ensureLoaded();

    final boundedAge = ageMonths.clamp(0, 35);
    final dayAgeBand = _dayAgeBandForMonths(boundedAge);
    final ageBandId = dayAgeBand['id']?.toString() ?? '6_9m';
    final template = _selectDayTemplate(
      ageBandId: ageBandId,
      napTransitionInProgress: napTransitionInProgress,
    );

    final templateId = template['id']?.toString() ?? 'unknown_template';
    final wakeWindowProfileId =
        template['wakeWindowProfileId']?.toString() ?? 'unknown_profile';
    final rulesetId = template['rulesetId']?.toString() ?? 'rules_standard';

    final metrics = <String, dynamic>{
      'age_band_id': ageBandId,
      'daycare_constrained': daycareConstrained,
      'late_nap_flag': lateNapFlag,
      'travel_flag': travelFlag,
      'support_mode': supportMode,
      'early_wake_today': earlyWakeToday,
      'bedtime_resistance_today': bedtimeResistanceToday,
      'short_naps_recent': shortNapsRecent,
      'overtired_signs_today': overtiredSignsToday,
      'undertired_signs_today': undertiredSignsToday,
      'split_night_recent': splitNightRecent,
      'false_start_recent': falseStartRecent,
      'long_naps_recent': longNapsRecent,
      'nap_transition_in_progress': napTransitionInProgress,
      'last_nap_duration_minutes': lastNapDurationMinutes,
      'last_nap_slot_id': lastNapSlotId,
      'total_day_sleep_minutes_today': totalDaySleepMinutesToday,
      'all_naps_failed_today': allNapsFailedToday,
      'micro_nap_feasible': microNapFeasible,
      'minutes_until_bedtime': minutesUntilBedtime,
      'early_wake_pattern': splitNightRecent || earlyWakeToday,
    };

    final wakeProfile = _dayWakeProfileById(wakeWindowProfileId);
    final napWindows = _buildDayNapWindows(
      wakeAnchorMinutes: wakeAnchorMinutes,
      template: template,
      wakeProfile: wakeProfile,
    );

    var bedtimeWindow = _initialBedtimeWindow(
      wakeAnchorMinutes: wakeAnchorMinutes,
      bedtimeTargetMinutes: bedtimeTargetMinutes,
      template: template,
    );

    final appliedConstraintIds = <String>[];
    final appliedRuleIds = <String>[];
    final rescueProtocolIds = <String>{};
    final notes = <String>[];
    String? recommendedSupportMode;

    final constraints = _asMapList(_dayModule?['constraints'])
      ..sort(
        (a, b) => (a['priority'] as int? ?? 999).compareTo(
          b['priority'] as int? ?? 999,
        ),
      );
    for (final constraint in constraints) {
      if (!_matchesRule(constraint, metrics)) continue;
      appliedConstraintIds.add(constraint['id']?.toString() ?? 'constraint');
      final rescueId = constraint['rescueProtocolId']?.toString();
      if (rescueId != null && rescueId.isNotEmpty) {
        rescueProtocolIds.add(rescueId);
      }
      final note = _dayText(
        constraint['notesKey']?.toString() ?? '',
        fallback: '',
      );
      if (note.isNotEmpty) notes.add(note);

      final fixed = constraint['fixedNapTimes'];
      if (fixed is List) {
        for (final item in fixed.whereType<Map>()) {
          final slotId = item['slotId']?.toString() ?? '';
          if (slotId.isEmpty) continue;
          final window = _asMap(item['startWindowMinutes']);
          final duration = _asMap(item['durationMinutes']);
          _upsertNapWindow(
            napWindows: napWindows,
            slotId: slotId,
            startEarliest:
                window['earliest'] as int? ?? wakeAnchorMinutes + 180,
            startLatest: window['latest'] as int? ?? wakeAnchorMinutes + 210,
            durationTarget:
                ((duration['min'] as int? ?? 45) +
                    (duration['max'] as int? ?? 90)) ~/
                2,
            optional: false,
          );
        }
      }

      final effects = _asMapList(constraint['effects']);
      for (final effect in effects) {
        recommendedSupportMode = _applyDayAction(
          action: effect,
          wakeAnchorMinutes: wakeAnchorMinutes,
          napWindows: napWindows,
          bedtimeWindow: bedtimeWindow,
          existingSupportMode: recommendedSupportMode,
        );
      }
    }

    final ruleset = _dayRulesetById(rulesetId);
    final rules = _asMapList(ruleset?['rules'])
      ..sort(
        (a, b) => (a['priority'] as int? ?? 999).compareTo(
          b['priority'] as int? ?? 999,
        ),
      );
    for (final rule in rules) {
      if (!_matchesRule(rule, metrics)) continue;
      appliedRuleIds.add(rule['id']?.toString() ?? 'rule');
      final note = _dayText(rule['notesKey']?.toString() ?? '', fallback: '');
      if (note.isNotEmpty) notes.add(note);

      final actions = _asMapList(rule['actions']);
      for (final action in actions) {
        recommendedSupportMode = _applyDayAction(
          action: action,
          wakeAnchorMinutes: wakeAnchorMinutes,
          napWindows: napWindows,
          bedtimeWindow: bedtimeWindow,
          existingSupportMode: recommendedSupportMode,
        );
      }
    }

    final napOutcomes = _asMapList(_dayModule?['napOutcomeAdjustments'])
      ..sort(
        (a, b) => (a['priority'] as int? ?? 999).compareTo(
          b['priority'] as int? ?? 999,
        ),
      );
    for (final adj in napOutcomes) {
      if (!_matchesRule(adj, metrics)) continue;
      appliedRuleIds.add(adj['id']?.toString() ?? 'nap_adjust');
      final note = _dayText(adj['notesKey']?.toString() ?? '', fallback: '');
      if (note.isNotEmpty) notes.add(note);
      final rescueId = adj['rescueProtocolId']?.toString();
      if (rescueId != null && rescueId.isNotEmpty) {
        rescueProtocolIds.add(rescueId);
      }
      final actions = _asMapList(adj['actions']);
      for (final action in actions) {
        recommendedSupportMode = _applyDayAction(
          action: action,
          wakeAnchorMinutes: wakeAnchorMinutes,
          napWindows: napWindows,
          bedtimeWindow: bedtimeWindow,
          existingSupportMode: recommendedSupportMode,
        );
      }
    }

    final bridgeRules = _asMapList(_dayModule?['bridgeDecisionRules'])
      ..sort(
        (a, b) => (a['priority'] as int? ?? 999).compareTo(
          b['priority'] as int? ?? 999,
        ),
      );
    for (final bridge in bridgeRules) {
      if (!_matchesRule(bridge, metrics)) continue;
      appliedRuleIds.add(bridge['id']?.toString() ?? 'bridge_rule');
      final note = _dayText(bridge['notesKey']?.toString() ?? '', fallback: '');
      if (note.isNotEmpty) notes.add(note);
      final rescueId = bridge['rescueProtocolId']?.toString();
      if (rescueId != null && rescueId.isNotEmpty) {
        rescueProtocolIds.add(rescueId);
      }
      final actions = _asMapList(bridge['actions']);
      for (final action in actions) {
        recommendedSupportMode = _applyDayAction(
          action: action,
          wakeAnchorMinutes: wakeAnchorMinutes,
          napWindows: napWindows,
          bedtimeWindow: bedtimeWindow,
          existingSupportMode: recommendedSupportMode,
        );
      }
    }

    final anchorRule = _selectMorningAnchorRule(
      ageBandId: ageBandId,
      metrics: metrics,
    );
    if (anchorRule.isNotEmpty) {
      final note = _dayText(
        anchorRule['notesKey']?.toString() ?? '',
        fallback: '',
      );
      if (note.isNotEmpty) notes.add(note);
      final lightNote = _dayText(
        anchorRule['lightExposureRecommendationKey']?.toString() ?? '',
        fallback: '',
      );
      if (lightNote.isNotEmpty) notes.add(lightNote);
      appliedRuleIds.add(anchorRule['id']?.toString() ?? 'anchor_rule');
    }

    _applyDaySafetyCaps(ageBandId: ageBandId, napWindows: napWindows);

    final evidenceRefs = <String>{
      ..._registryBindings('dayPlannerRulesets', rulesetId),
    };
    final dayMeta = _asMap(_dayModule?['meta']);
    final evidenceMeta = _asMap(_evidenceRegistry?['meta']);
    final policyVersion =
        '${dayMeta['schemaVersion'] ?? 'sleep_day_planner_module'}|${evidenceMeta['schemaVersion'] ?? 'sleep_evidence_registry'}';

    return SleepDayRuntimePlan(
      ageBandId: ageBandId,
      templateId: templateId,
      wakeWindowProfileId: wakeWindowProfileId,
      rulesetId: rulesetId,
      policyVersion: policyVersion,
      evidenceRefs: evidenceRefs.toList()..sort(),
      napWindows: napWindows
          .map(
            (n) => SleepDayPlanWindow(
              slotId: n['slot_id']?.toString() ?? 'nap',
              startWindowMinutes:
                  n['start_earliest'] as int? ?? wakeAnchorMinutes,
              endWindowMinutes:
                  n['start_latest'] as int? ?? wakeAnchorMinutes + 30,
              targetDurationMinutes: n['target_duration'] as int? ?? 60,
              optional: n['optional'] as bool? ?? false,
            ),
          )
          .toList(),
      bedtimeWindowEarliest:
          bedtimeWindow['earliest'] ?? bedtimeTargetMinutes - 30,
      bedtimeWindowLatest: bedtimeWindow['latest'] ?? bedtimeTargetMinutes + 30,
      appliedRuleIds: appliedRuleIds.toSet().toList()..sort(),
      appliedConstraintIds: appliedConstraintIds.toSet().toList()..sort(),
      rescueProtocolIds: rescueProtocolIds.toList()..sort(),
      notes: notes.toSet().toList(),
      recommendedSupportMode: recommendedSupportMode,
    );
  }

  Future<List<SleepEvidenceItem>> getEvidenceItems(
    List<String> evidenceIds,
  ) async {
    await _ensureLoaded();
    if (evidenceIds.isEmpty) return const [];

    final wanted = evidenceIds.toSet();
    final entries = _asMapList(_evidenceRegistry?['evidenceItems']);
    final out = <SleepEvidenceItem>[];

    for (final entry in entries) {
      final id = entry['id']?.toString() ?? '';
      if (!wanted.contains(id)) continue;

      final sources = _asMapList(entry['sourceRefs'])
          .map(
            (s) => SleepEvidenceSource(
              id: s['id']?.toString() ?? '',
              citation: s['citation']?.toString() ?? '',
              publisher: s['publisher']?.toString() ?? '',
              url: s['url']?.toString() ?? '',
              year: s['year'] is int
                  ? s['year'] as int
                  : int.tryParse(s['year']?.toString() ?? ''),
              type: s['type']?.toString() ?? '',
            ),
          )
          .toList();

      out.add(
        SleepEvidenceItem(
          id: id,
          title: entry['title']?.toString() ?? id,
          claim: entry['claim']?.toString() ?? '',
          evidenceLevel: entry['evidenceLevel']?.toString() ?? 'unspecified',
          sources: sources,
        ),
      );
    }

    out.sort((a, b) => a.title.compareTo(b.title));
    return out;
  }

  Map<String, dynamic> _ageBandForMonths(int ageMonths) {
    final bands = _asMapList(_nightModule?['ageBands']);
    for (final band in bands) {
      final lo = band['minMonthsInclusive'] as int? ?? 0;
      final hi = band['maxMonthsExclusive'] as int? ?? 36;
      if (ageMonths >= lo && ageMonths < hi) {
        return band;
      }
    }
    if (bands.isNotEmpty) {
      return bands.last;
    }
    return _asMap({
      'id': '6_18m',
      'trainingAllowed': true,
      'defaultMethodId': 'check_console',
    });
  }

  String _methodForPreference(String preference, Map<String, dynamic> ageBand) {
    final trainingAllowed = ageBand['trainingAllowed'] as bool? ?? true;
    if (!trainingAllowed) return 'foundations_only';

    final id = switch (preference) {
      'gentle' => 'check_console',
      'firm' => 'extinction',
      _ => 'fading_chair',
    };

    final method = _methodById(id);
    final eligible = _asStringList(method?['eligibleAgeBandIds']);
    final ageBandId = ageBand['id']?.toString() ?? '';
    if (eligible.isNotEmpty && !eligible.contains(ageBandId)) {
      return ageBand['defaultMethodId']?.toString() ?? 'check_console';
    }
    return id;
  }

  String _resolveMethodIdForTonight({
    required String preference,
    required Map<String, dynamic> ageBand,
    String? lockedMethodId,
  }) {
    final explicit = lockedMethodId?.trim() ?? '';
    if (explicit.isNotEmpty) {
      final method = _methodById(explicit);
      if (method != null) {
        final eligible = _asStringList(method['eligibleAgeBandIds']);
        final ageBandId = ageBand['id']?.toString() ?? '';
        if (eligible.isEmpty || eligible.contains(ageBandId)) {
          return explicit;
        }
      }
    }
    return _methodForPreference(preference, ageBand);
  }

  String _episodeForScenario(String scenario) {
    return switch (scenario) {
      'night_wakes' => 'night_wake',
      'early_wakes' => 'early_wake',
      'split_nights' => 'split_night',
      _ => 'bedtime',
    };
  }

  int _timerMinutes(
    String timerProfileId,
    List<Map<String, dynamic>> profiles,
  ) {
    final profile = profiles.firstWhere(
      (p) => p['id'] == timerProfileId,
      orElse: () => {},
    );
    if (profile.isEmpty) return 2;

    final fixedSeconds = profile['fixedSeconds'];
    if (fixedSeconds is num && fixedSeconds > 0) {
      return max(1, (fixedSeconds / 60).ceil());
    }

    final sequence = profile['sequenceSeconds'];
    if (sequence is List && sequence.isNotEmpty) {
      final first = sequence.first;
      if (first is num && first > 0) {
        return max(1, (first / 60).ceil());
      }
    }

    return 2;
  }

  String _rescueRuleForEpisode(String episodeType) {
    final rescues = _asMapList(_nightModule?['rescueProtocols'])
      ..sort(
        (a, b) => (a['priority'] as int? ?? 999).compareTo(
          b['priority'] as int? ?? 999,
        ),
      );

    final rescue = rescues.firstWhere(
      (r) => r['episodeType'] == episodeType,
      orElse: () => {},
    );

    if (rescue.isEmpty) {
      return 'If escalation continues, keep response brief and consistent.';
    }

    final tonight = _asMap(rescue['tonight']);
    final headline = _nightText(
      tonight['headlineKey']?.toString() ?? '',
      fallback: 'If escalation continues',
    );
    final doText = _firstTextFromKeys(
      tonight['doKeys'],
      fallback: 'Return to plan.',
    );
    return '$headline: $doText';
  }

  String _feedPolicyFor({
    required String feedMode,
    required bool feedingAssociation,
    required Map<String, dynamic> ageBand,
  }) {
    if (!feedingAssociation) {
      return ageBand['defaultFeedingPolicyId']?.toString() ?? 'feed_windows';
    }

    return switch (feedMode) {
      'reduce_gradually' => 'night_wean_in_progress',
      'separate_feed_sleep' => 'feed_windows',
      _ => ageBand['defaultFeedingPolicyId']?.toString() ?? 'feed_windows',
    };
  }

  Map<String, dynamic> _dayAgeBandForMonths(int ageMonths) {
    final bands = _asMapList(_dayModule?['ageBands']);
    for (final band in bands) {
      final lo = band['minMonthsInclusive'] as int? ?? 0;
      final hi = band['maxMonthsExclusive'] as int? ?? 36;
      if (ageMonths >= lo && ageMonths < hi) return band;
    }
    if (bands.isNotEmpty) return bands.last;
    return _asMap({'id': '6_9m'});
  }

  Map<String, dynamic> _selectDayTemplate({
    required String ageBandId,
    required bool napTransitionInProgress,
  }) {
    final templates = _asMapList(
      _dayModule?['scheduleTemplates'],
    ).where((t) => t['ageBandId']?.toString() == ageBandId).toList();
    if (templates.isEmpty) {
      final all = _asMapList(_dayModule?['scheduleTemplates']);
      return all.isNotEmpty ? all.first : _asMap({});
    }
    if (napTransitionInProgress) {
      final transitioning = templates.where(
        (t) =>
            t['id']?.toString().contains('transition') == true ||
            t['id']?.toString().contains('3to2') == true ||
            t['id']?.toString().contains('2to1') == true,
      );
      if (transitioning.isNotEmpty) return transitioning.first;
    }
    return templates.first;
  }

  Map<String, dynamic>? _dayWakeProfileById(String profileId) {
    final profiles = _asMapList(_dayModule?['wakeWindowProfiles']);
    for (final p in profiles) {
      if (p['id']?.toString() == profileId) return p;
    }
    return null;
  }

  List<Map<String, dynamic>> _buildDayNapWindows({
    required int wakeAnchorMinutes,
    required Map<String, dynamic> template,
    required Map<String, dynamic>? wakeProfile,
  }) {
    final windows = <Map<String, dynamic>>[];
    final profile = wakeProfile ?? _asMap({});
    final rule = profile['rule']?.toString() ?? 'rolling';
    var cursor = wakeAnchorMinutes;

    final napTargetsBySlot = <String, int>{};
    final napTargets = _asMapList(template['napTargets']);
    for (final target in napTargets) {
      final slot = target['slotId']?.toString() ?? '';
      if (slot.isEmpty) continue;
      final d = _asMap(target['durationMinutes']);
      napTargetsBySlot[slot] =
          ((d['min'] as int? ?? 45) + (d['max'] as int? ?? 90)) ~/ 2;
    }

    final defaultDurationTarget = (() {
      final target = _asMap(template['napDurationTargetMinutes']);
      if (target.isNotEmpty) {
        return ((target['min'] as int? ?? 45) +
                (target['max'] as int? ?? 90)) ~/
            2;
      }
      return 60;
    })();

    if (rule == 'by_slot') {
      final slots = _asMapList(profile['slots']);
      for (final slot in slots) {
        final slotId = slot['slotId']?.toString() ?? '';
        if (slotId.isEmpty || slotId == 'bedtime') continue;
        final ww = _asMap(slot['wakeWindowMinutes']);
        final startEarliest = cursor + (ww['targetMin'] as int? ?? 120);
        final startLatest = cursor + (ww['targetMax'] as int? ?? 150);
        final duration = napTargetsBySlot[slotId] ?? defaultDurationTarget;
        windows.add({
          'slot_id': slotId,
          'start_earliest': startEarliest,
          'start_latest': startLatest,
          'target_duration': duration,
          'optional': false,
        });
        cursor = startLatest + duration;
      }
      return windows;
    }

    final napCount = _asMap(template['napCount']);
    final maxNaps = napCount['max'] as int? ?? 4;
    final rolling = _asMap(profile['defaultWakeWindowMinutes']);
    final targetMin = rolling['targetMin'] as int? ?? 60;
    final targetMax = rolling['targetMax'] as int? ?? 90;
    for (var i = 0; i < maxNaps; i++) {
      final slotId = 'nap${i + 1}';
      final startEarliest = cursor + targetMin;
      final startLatest = cursor + targetMax;
      windows.add({
        'slot_id': slotId,
        'start_earliest': startEarliest,
        'start_latest': startLatest,
        'target_duration': defaultDurationTarget,
        'optional': i >= 3,
      });
      cursor = startLatest + defaultDurationTarget;
    }
    return windows;
  }

  Map<String, int> _initialBedtimeWindow({
    required int wakeAnchorMinutes,
    required int bedtimeTargetMinutes,
    required Map<String, dynamic> template,
  }) {
    final absolute = _asMap(template['bedtimeWindowMinutes']);
    if (absolute.isNotEmpty) {
      return {
        'earliest': absolute['earliest'] as int? ?? bedtimeTargetMinutes - 30,
        'latest': absolute['latest'] as int? ?? bedtimeTargetMinutes + 30,
      };
    }

    final fromAnchor = _asMap(template['bedtimeWindowMinutesFromAnchor']);
    if (fromAnchor.isNotEmpty) {
      return {
        'earliest': wakeAnchorMinutes + (fromAnchor['earliest'] as int? ?? 600),
        'latest': wakeAnchorMinutes + (fromAnchor['latest'] as int? ?? 720),
      };
    }

    return {
      'earliest': bedtimeTargetMinutes - 30,
      'latest': bedtimeTargetMinutes + 30,
    };
  }

  void _upsertNapWindow({
    required List<Map<String, dynamic>> napWindows,
    required String slotId,
    required int startEarliest,
    required int startLatest,
    required int durationTarget,
    required bool optional,
  }) {
    final existingIndex = napWindows.indexWhere((w) => w['slot_id'] == slotId);
    final next = {
      'slot_id': slotId,
      'start_earliest': startEarliest,
      'start_latest': startLatest,
      'target_duration': durationTarget,
      'optional': optional,
    };
    if (existingIndex >= 0) {
      napWindows[existingIndex] = next;
    } else {
      napWindows.add(next);
    }
  }

  String? _applyDayAction({
    required Map<String, dynamic> action,
    required int wakeAnchorMinutes,
    required List<Map<String, dynamic>> napWindows,
    required Map<String, int> bedtimeWindow,
    required String? existingSupportMode,
  }) {
    final type = action['type']?.toString() ?? '';
    switch (type) {
      case 'shift_bedtime_minutes':
        final shift = action['minutesValue'] as int? ?? 0;
        bedtimeWindow['earliest'] = (bedtimeWindow['earliest'] ?? 0) + shift;
        bedtimeWindow['latest'] = (bedtimeWindow['latest'] ?? 0) + shift;
        return existingSupportMode;
      case 'cap_nap_minutes':
        final slotId = action['slotId']?.toString() ?? '';
        final cap = action['minutesValue'] as int? ?? 90;
        if (napWindows.isEmpty) return existingSupportMode;
        if (slotId == 'last') {
          final last = napWindows.last;
          last['target_duration'] = min(
            last['target_duration'] as int? ?? cap,
            cap,
          );
          return existingSupportMode;
        }
        if (slotId == 'next') {
          final first = napWindows.first;
          first['target_duration'] = min(
            first['target_duration'] as int? ?? cap,
            cap,
          );
          return existingSupportMode;
        }
        for (final window in napWindows) {
          if (window['slot_id']?.toString() == slotId) {
            window['target_duration'] = min(
              window['target_duration'] as int? ?? cap,
              cap,
            );
          }
        }
        return existingSupportMode;
      case 'shorten_wake_window_percent':
      case 'lengthen_wake_window_percent':
        final percent = action['percentValue'] as int? ?? 10;
        final factor = type == 'shorten_wake_window_percent'
            ? (1 - (percent / 100))
            : (1 + (percent / 100));
        final slotId = action['slotId']?.toString();
        for (final window in napWindows) {
          final currentSlotId = window['slot_id']?.toString() ?? '';
          if (slotId != null &&
              slotId.isNotEmpty &&
              slotId != currentSlotId &&
              slotId != 'bedtime') {
            continue;
          }
          final earliest =
              window['start_earliest'] as int? ?? wakeAnchorMinutes;
          final latest =
              window['start_latest'] as int? ?? wakeAnchorMinutes + 30;
          window['start_earliest'] =
              wakeAnchorMinutes +
              ((earliest - wakeAnchorMinutes) * factor).round();
          window['start_latest'] =
              wakeAnchorMinutes +
              ((latest - wakeAnchorMinutes) * factor).round();
        }
        return existingSupportMode;
      case 'cap_total_day_sleep':
        final cap = action['minutesValue'] as int? ?? 240;
        final total = napWindows.fold<int>(
          0,
          (sum, w) => sum + (w['target_duration'] as int? ?? 0),
        );
        if (total > cap && napWindows.isNotEmpty) {
          final overBy = total - cap;
          final last = napWindows.last;
          final current = last['target_duration'] as int? ?? 60;
          last['target_duration'] = max(15, current - overBy);
        }
        return existingSupportMode;
      case 'add_micro_nap':
        final minutesValue = action['minutesValue'] as int? ?? 20;
        if (!napWindows.any((w) => w['slot_id'] == 'micro_nap')) {
          napWindows.add({
            'slot_id': 'micro_nap',
            'start_earliest': max(0, (bedtimeWindow['earliest'] ?? 1200) - 150),
            'start_latest': max(0, (bedtimeWindow['earliest'] ?? 1200) - 120),
            'target_duration': minutesValue,
            'optional': true,
          });
        }
        return existingSupportMode;
      case 'avoid_early_first_nap':
      case 'enforce_morning_anchor':
        if (napWindows.isNotEmpty) {
          final first = napWindows.first;
          first['start_earliest'] = max(
            first['start_earliest'] as int? ?? wakeAnchorMinutes,
            wakeAnchorMinutes + 120,
          );
          first['start_latest'] = max(
            first['start_latest'] as int? ?? wakeAnchorMinutes + 30,
            wakeAnchorMinutes + 150,
          );
        }
        return existingSupportMode;
      case 'recommend_support_mode':
        final supportModeId = action['supportModeId']?.toString();
        return supportModeId ?? existingSupportMode;
      default:
        return existingSupportMode;
    }
  }

  Map<String, dynamic>? _dayRulesetById(String rulesetId) {
    final rulesets = _asMapList(_dayModule?['planRulesets']);
    for (final ruleset in rulesets) {
      if (ruleset['id']?.toString() == rulesetId) return ruleset;
    }
    return null;
  }

  Map<String, dynamic> _selectMorningAnchorRule({
    required String ageBandId,
    required Map<String, dynamic> metrics,
  }) {
    final policy = _asMap(_dayModule?['morningAnchorPolicy']);
    final rules = _asMapList(policy['rules'])
      ..sort(
        (a, b) => (a['priority'] as int? ?? 999).compareTo(
          b['priority'] as int? ?? 999,
        ),
      );
    for (final rule in rules) {
      final appliesTo = _asStringList(rule['appliesToAgeBandIds']);
      if (appliesTo.isNotEmpty && !appliesTo.contains(ageBandId)) {
        continue;
      }
      final when = _asMap(rule['when']);
      if (when.isNotEmpty && !_matchesWhen(when, metrics)) {
        continue;
      }
      return rule;
    }
    return {};
  }

  void _applyDaySafetyCaps({
    required String ageBandId,
    required List<Map<String, dynamic>> napWindows,
  }) {
    final safetyLimits = _asMap(_dayModule?['safetyLimits']);
    final maxSingleNap = safetyLimits['maxSingleNapDuration'] as int? ?? 180;
    for (final nap in napWindows) {
      final current = nap['target_duration'] as int? ?? 60;
      nap['target_duration'] = min(current, maxSingleNap);
    }

    final maxByAge = _asMapList(safetyLimits['maxTotalDaySleepByAge']);
    final cap =
        maxByAge.firstWhere(
              (e) => e['ageBandId']?.toString() == ageBandId,
              orElse: () => {},
            )['maxMinutes']
            as int?;
    if (cap == null) return;

    var total = napWindows.fold<int>(
      0,
      (sum, n) => sum + (n['target_duration'] as int? ?? 0),
    );
    if (total <= cap) return;

    for (var i = napWindows.length - 1; i >= 0 && total > cap; i--) {
      final nap = napWindows[i];
      final current = nap['target_duration'] as int? ?? 60;
      final reducible = max(0, current - 15);
      final needed = total - cap;
      final reduceBy = min(reducible, needed);
      nap['target_duration'] = current - reduceBy;
      total -= reduceBy;
    }
  }

  bool _matchesRule(Map<String, dynamic> rule, Map<String, dynamic> metrics) {
    final when = _asMap(rule['when']);
    return _matchesWhen(when, metrics);
  }

  bool _matchesWhen(Map<String, dynamic> when, Map<String, dynamic> metrics) {
    final allOf = when['allOf'];
    if (allOf is List) {
      for (final clause in allOf.whereType<Map>()) {
        if (!_matchesClause(
          clause.map((k, v) => MapEntry(k.toString(), v)),
          metrics,
        )) {
          return false;
        }
      }
      return true;
    }

    final anyOf = when['anyOf'];
    if (anyOf is List) {
      for (final clause in anyOf.whereType<Map>()) {
        if (_matchesClause(
          clause.map((k, v) => MapEntry(k.toString(), v)),
          metrics,
        )) {
          return true;
        }
      }
      return false;
    }

    return false;
  }

  bool _matchesClause(
    Map<String, dynamic> clause,
    Map<String, dynamic> metrics,
  ) {
    final metric = clause['metric']?.toString() ?? '';
    final op = clause['op']?.toString() ?? 'eq';
    final expected = clause['value'];
    final actual = metrics[metric];

    switch (op) {
      case 'exists':
        final shouldExist = expected == true;
        return shouldExist
            ? metrics.containsKey(metric)
            : !metrics.containsKey(metric);
      case 'eq':
        return actual == expected;
      case 'neq':
        return actual != expected;
      case 'gte':
        return _asNum(actual) >= _asNum(expected);
      case 'gt':
        return _asNum(actual) > _asNum(expected);
      case 'lte':
        return _asNum(actual) <= _asNum(expected);
      case 'lt':
        return _asNum(actual) < _asNum(expected);
      case 'in':
        if (expected is List) {
          return expected.contains(actual);
        }
        return false;
      default:
        return false;
    }
  }

  String _firstTextFromKeys(Object? keys, {required String fallback}) {
    if (keys is! List) return fallback;
    for (final key in keys) {
      final text = _nightText(key?.toString() ?? '', fallback: '');
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  String _nightText(String key, {required String fallback}) {
    if (key.isEmpty) return fallback;
    final copy = _asMap(_nightModule?['copy']);
    final strings = _asMap(copy['strings']);
    final entry = _asMap(strings[key]);
    final text = entry['text']?.toString() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _dayText(String key, {required String fallback}) {
    if (key.isEmpty) return fallback;
    final copy = _asMap(_dayModule?['copy']);
    final strings = _asMap(copy['strings']);
    final entry = _asMap(strings[key]);
    final text = entry['text']?.toString() ?? '';
    return text.isEmpty ? fallback : text;
  }

  List<String> _registryBindings(String section, String id) {
    final policy = _asMap(_evidenceRegistry?['policyBindings']);
    final sectionMap = _asMap(policy[section]);
    final raw = sectionMap[id];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }

  Map<String, dynamic>? _methodById(String methodId) {
    final methods = _asMapList(_nightModule?['methods']);
    for (final m in methods) {
      if (m['id']?.toString() == methodId) {
        return m;
      }
    }
    return null;
  }

  Map<String, dynamic>? _flowById(String flowId) {
    final flows = _asMapList(_nightModule?['flows']);
    for (final f in flows) {
      if (f['id']?.toString() == flowId) {
        return f;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _asMapList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is! Map) return <String, dynamic>{};
    return value.map((k, v) => MapEntry(k.toString(), v));
  }

  List<String> _asStringList(Object? value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).toList();
  }

  double _asNum(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
