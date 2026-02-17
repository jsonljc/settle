import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/event_bus_service.dart';
import '../services/sleep_guidance_service.dart';

const _sleepTonightBox = 'sleep_tonight_v1';

enum SleepRecapOutcome { settled, neededHelp, notResolved }

extension SleepRecapOutcomeWire on SleepRecapOutcome {
  String get wire => switch (this) {
    SleepRecapOutcome.settled => 'settled',
    SleepRecapOutcome.neededHelp => 'needed_help',
    SleepRecapOutcome.notResolved => 'not_resolved',
  };

  String get label => switch (this) {
    SleepRecapOutcome.settled => 'Settled',
    SleepRecapOutcome.neededHelp => 'Needed help',
    SleepRecapOutcome.notResolved => 'Not resolved',
  };

  static SleepRecapOutcome fromString(String raw) {
    return switch (raw) {
      'settled' => SleepRecapOutcome.settled,
      'needed_help' => SleepRecapOutcome.neededHelp,
      'not_resolved' => SleepRecapOutcome.notResolved,
      _ => SleepRecapOutcome.settled,
    };
  }
}

class SleepTonightState {
  const SleepTonightState({
    required this.isLoading,
    required this.activePlan,
    required this.breathingDifficulty,
    required this.dehydrationSigns,
    required this.repeatedVomiting,
    required this.severePainIndicators,
    required this.feedingRefusalWithPainSigns,
    required this.safeSleepConfirmed,
    required this.comfortMode,
    required this.somethingFeelsOff,
    this.selectedApproachId = '',
    this.commitmentStartDate,
    this.commitmentNightsDefault = 3,
    this.switchHistory = const [],
    this.pendingApproachId,
    this.pendingEffectiveDate,
    this.pendingSwitchReason,
    this.hasSleepSetup = false,
    this.sharedRoom = false,
    this.caregiverConsistency = 'unsure',
    this.cryingTolerance = 'med',
    this.canLeaveRoom = true,
    this.nightFeedsExpected = true,
    this.quickDoneEnabled = false,
    this.lastRecapOutcome,
    this.lastTimeToSettleBucket,
    required this.lastError,
  });

  final bool isLoading;
  final Map<String, dynamic>? activePlan;
  final bool breathingDifficulty;
  final bool dehydrationSigns;
  final bool repeatedVomiting;
  final bool severePainIndicators;
  final bool feedingRefusalWithPainSigns;
  final bool safeSleepConfirmed;
  final bool comfortMode;
  final bool somethingFeelsOff;

  final String selectedApproachId;
  final DateTime? commitmentStartDate;
  final int commitmentNightsDefault;
  final List<Map<String, dynamic>> switchHistory;
  final String? pendingApproachId;
  final DateTime? pendingEffectiveDate;
  final String? pendingSwitchReason;
  final bool hasSleepSetup;
  final bool sharedRoom;
  final String caregiverConsistency;
  final String cryingTolerance;
  final bool canLeaveRoom;
  final bool nightFeedsExpected;
  final bool quickDoneEnabled;
  final SleepRecapOutcome? lastRecapOutcome;
  final String? lastTimeToSettleBucket;

  final String? lastError;

  bool get hasActivePlan =>
      activePlan != null && (activePlan!['is_active'] as bool? ?? false);

  bool get redFlagTriggered =>
      breathingDifficulty ||
      dehydrationSigns ||
      repeatedVomiting ||
      severePainIndicators ||
      feedingRefusalWithPainSigns;

  int get commitmentNight {
    final start = commitmentStartDate;
    if (start == null) return 1;
    final startDate = DateTime(start.year, start.month, start.day);
    final now = DateTime.now();
    final nowDate = DateTime(now.year, now.month, now.day);
    final raw = nowDate.difference(startDate).inDays + 1;
    final bounded = raw < 1 ? 1 : raw;
    return bounded > commitmentNightsDefault
        ? commitmentNightsDefault
        : bounded;
  }

  static const initial = SleepTonightState(
    isLoading: true,
    activePlan: null,
    breathingDifficulty: false,
    dehydrationSigns: false,
    repeatedVomiting: false,
    severePainIndicators: false,
    feedingRefusalWithPainSigns: false,
    safeSleepConfirmed: true,
    comfortMode: false,
    somethingFeelsOff: false,
    selectedApproachId: '',
    commitmentStartDate: null,
    commitmentNightsDefault: 3,
    switchHistory: [],
    pendingApproachId: null,
    pendingEffectiveDate: null,
    pendingSwitchReason: null,
    hasSleepSetup: false,
    sharedRoom: false,
    caregiverConsistency: 'unsure',
    cryingTolerance: 'med',
    canLeaveRoom: true,
    nightFeedsExpected: true,
    quickDoneEnabled: false,
    lastRecapOutcome: null,
    lastTimeToSettleBucket: null,
    lastError: null,
  );

  SleepTonightState copyWith({
    bool? isLoading,
    Object? activePlan = _noChange,
    bool? breathingDifficulty,
    bool? dehydrationSigns,
    bool? repeatedVomiting,
    bool? severePainIndicators,
    bool? feedingRefusalWithPainSigns,
    bool? safeSleepConfirmed,
    bool? comfortMode,
    bool? somethingFeelsOff,
    String? selectedApproachId,
    Object? commitmentStartDate = _noChange,
    int? commitmentNightsDefault,
    List<Map<String, dynamic>>? switchHistory,
    Object? pendingApproachId = _noChange,
    Object? pendingEffectiveDate = _noChange,
    Object? pendingSwitchReason = _noChange,
    bool? hasSleepSetup,
    bool? sharedRoom,
    String? caregiverConsistency,
    String? cryingTolerance,
    bool? canLeaveRoom,
    bool? nightFeedsExpected,
    bool? quickDoneEnabled,
    Object? lastRecapOutcome = _noChange,
    Object? lastTimeToSettleBucket = _noChange,
    Object? lastError = _noChange,
  }) {
    return SleepTonightState(
      isLoading: isLoading ?? this.isLoading,
      activePlan: identical(activePlan, _noChange)
          ? this.activePlan
          : activePlan as Map<String, dynamic>?,
      breathingDifficulty: breathingDifficulty ?? this.breathingDifficulty,
      dehydrationSigns: dehydrationSigns ?? this.dehydrationSigns,
      repeatedVomiting: repeatedVomiting ?? this.repeatedVomiting,
      severePainIndicators: severePainIndicators ?? this.severePainIndicators,
      feedingRefusalWithPainSigns:
          feedingRefusalWithPainSigns ?? this.feedingRefusalWithPainSigns,
      safeSleepConfirmed: safeSleepConfirmed ?? this.safeSleepConfirmed,
      comfortMode: comfortMode ?? this.comfortMode,
      somethingFeelsOff: somethingFeelsOff ?? this.somethingFeelsOff,
      selectedApproachId: selectedApproachId ?? this.selectedApproachId,
      commitmentStartDate: identical(commitmentStartDate, _noChange)
          ? this.commitmentStartDate
          : commitmentStartDate as DateTime?,
      commitmentNightsDefault:
          commitmentNightsDefault ?? this.commitmentNightsDefault,
      switchHistory: switchHistory ?? this.switchHistory,
      pendingApproachId: identical(pendingApproachId, _noChange)
          ? this.pendingApproachId
          : pendingApproachId as String?,
      pendingEffectiveDate: identical(pendingEffectiveDate, _noChange)
          ? this.pendingEffectiveDate
          : pendingEffectiveDate as DateTime?,
      pendingSwitchReason: identical(pendingSwitchReason, _noChange)
          ? this.pendingSwitchReason
          : pendingSwitchReason as String?,
      hasSleepSetup: hasSleepSetup ?? this.hasSleepSetup,
      sharedRoom: sharedRoom ?? this.sharedRoom,
      caregiverConsistency: caregiverConsistency ?? this.caregiverConsistency,
      cryingTolerance: cryingTolerance ?? this.cryingTolerance,
      canLeaveRoom: canLeaveRoom ?? this.canLeaveRoom,
      nightFeedsExpected: nightFeedsExpected ?? this.nightFeedsExpected,
      quickDoneEnabled: quickDoneEnabled ?? this.quickDoneEnabled,
      lastRecapOutcome: identical(lastRecapOutcome, _noChange)
          ? this.lastRecapOutcome
          : lastRecapOutcome as SleepRecapOutcome?,
      lastTimeToSettleBucket: identical(lastTimeToSettleBucket, _noChange)
          ? this.lastTimeToSettleBucket
          : lastTimeToSettleBucket as String?,
      lastError: identical(lastError, _noChange)
          ? this.lastError
          : lastError as String?,
    );
  }
}

const _noChange = Object();

final sleepTonightProvider =
    StateNotifierProvider<SleepTonightNotifier, SleepTonightState>((ref) {
      return SleepTonightNotifier();
    });

class SleepTonightNotifier extends StateNotifier<SleepTonightState> {
  SleepTonightNotifier() : super(SleepTonightState.initial);

  Box<dynamic>? _box;
  final SleepGuidanceService _guidance = SleepGuidanceService.instance;

  Future<Box<dynamic>> _ensureBox() async {
    _box ??= await Hive.openBox<dynamic>(_sleepTonightBox);
    return _box!;
  }

  DateTime _nightAnchorDate(DateTime timestamp) {
    final dateOnly = DateTime(timestamp.year, timestamp.month, timestamp.day);
    if (timestamp.hour < 6) {
      return dateOnly.subtract(const Duration(days: 1));
    }
    return dateOnly;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _keyFor(String childId, DateTime date) {
    return '$childId:${_dateKey(date)}';
  }

  String _metaKeyFor(String childId) => 'meta:$childId';

  Map<String, dynamic> _defaultMeta({String? selectedApproachId}) {
    return {
      'selected_approach_id': selectedApproachId ?? '',
      'commitment_start_date': DateTime.now().toIso8601String(),
      'commitment_nights_default': 3,
      'switch_history': <Map<String, dynamic>>[],
      'pending_approach_id': null,
      'pending_effective_date': null,
      'pending_switch_reason': null,
      'home_context_set': false,
      'shared_room': false,
      'caregiver_consistency': 'unsure',
      'crying_tolerance': 'med',
      'can_leave_room': true,
      'night_feeds_expected': true,
      'quick_done_enabled': false,
      'last_recap_outcome': null,
      'last_recap_time_bucket': null,
    };
  }

  DateTime _effectiveDateFor(String timing, DateTime now) {
    final anchor = _nightAnchorDate(now);
    if (timing == 'tomorrow') {
      return anchor.add(const Duration(days: 1));
    }
    return anchor;
  }

  Future<Map<String, dynamic>> _readMeta(
    String childId, {
    String? selectedApproachId,
  }) async {
    final box = await _ensureBox();
    final raw = box.get(_metaKeyFor(childId));
    final meta = raw is Map
        ? Map<String, dynamic>.from(raw)
        : _defaultMeta(selectedApproachId: selectedApproachId);

    if ((meta['selected_approach_id']?.toString() ?? '').isEmpty &&
        selectedApproachId != null &&
        selectedApproachId.isNotEmpty) {
      meta['selected_approach_id'] = selectedApproachId;
    }

    return meta;
  }

  Future<void> _persistMeta(String childId, Map<String, dynamic> meta) async {
    final box = await _ensureBox();
    await box.put(_metaKeyFor(childId), meta);
  }

  void _syncStateFromMeta(Map<String, dynamic> meta) {
    final switchHistoryRaw = (meta['switch_history'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    state = state.copyWith(
      selectedApproachId: meta['selected_approach_id']?.toString() ?? '',
      commitmentStartDate: DateTime.tryParse(
        meta['commitment_start_date']?.toString() ?? '',
      ),
      commitmentNightsDefault: meta['commitment_nights_default'] as int? ?? 3,
      switchHistory: switchHistoryRaw,
      pendingApproachId: meta['pending_approach_id']?.toString(),
      pendingEffectiveDate: DateTime.tryParse(
        meta['pending_effective_date']?.toString() ?? '',
      ),
      pendingSwitchReason: meta['pending_switch_reason']?.toString(),
      hasSleepSetup: meta['home_context_set'] as bool? ?? false,
      sharedRoom: meta['shared_room'] as bool? ?? false,
      caregiverConsistency:
          meta['caregiver_consistency']?.toString() ?? 'unsure',
      cryingTolerance: meta['crying_tolerance']?.toString() ?? 'med',
      canLeaveRoom: meta['can_leave_room'] as bool? ?? true,
      nightFeedsExpected: meta['night_feeds_expected'] as bool? ?? true,
      quickDoneEnabled: meta['quick_done_enabled'] as bool? ?? false,
      lastRecapOutcome: meta['last_recap_outcome'] == null
          ? null
          : SleepRecapOutcomeWire.fromString(
              meta['last_recap_outcome']?.toString() ?? '',
            ),
      lastTimeToSettleBucket: meta['last_recap_time_bucket']?.toString(),
    );
  }

  bool _applyPendingSwitchIfDue({
    required Map<String, dynamic> meta,
    required DateTime nightDate,
  }) {
    final pendingApproach = meta['pending_approach_id']?.toString() ?? '';
    final pendingDate = DateTime.tryParse(
      meta['pending_effective_date']?.toString() ?? '',
    );
    if (pendingApproach.isEmpty || pendingDate == null) {
      return false;
    }
    if (_nightAnchorDate(nightDate).isBefore(_nightAnchorDate(pendingDate))) {
      return false;
    }
    meta['selected_approach_id'] = pendingApproach;
    meta['commitment_start_date'] = nightDate.toIso8601String();
    meta['pending_approach_id'] = null;
    meta['pending_effective_date'] = null;
    meta['pending_switch_reason'] = null;
    return true;
  }

  Future<void> syncMethodSelection({
    required String childId,
    required String selectedApproachId,
  }) async {
    final meta = await _readMeta(
      childId,
      selectedApproachId: selectedApproachId,
    );
    final current = meta['selected_approach_id']?.toString() ?? '';
    if (current.isEmpty) {
      meta['selected_approach_id'] = selectedApproachId;
      meta['commitment_start_date'] = DateTime.now().toIso8601String();
      await _persistMeta(childId, meta);
    }
    _syncStateFromMeta(meta);
  }

  Future<void> changeApproachWithCommitment({
    required String childId,
    required String toApproachId,
    required String reason,
    required String effectiveTiming,
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    final meta = await _readMeta(childId);
    final from = meta['selected_approach_id']?.toString() ?? '';
    final effectiveDate = _effectiveDateFor(effectiveTiming, ts);

    final history = (meta['switch_history'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    history.insert(0, {
      'from_approach_id': from,
      'to_approach_id': toApproachId,
      'reason': reason,
      'effective_timing': effectiveTiming,
      'effective_date': effectiveDate.toIso8601String(),
      'created_at': ts.toIso8601String(),
    });

    if (effectiveTiming == 'tonight') {
      meta['selected_approach_id'] = toApproachId;
      meta['commitment_start_date'] = ts.toIso8601String();
      meta['pending_approach_id'] = null;
      meta['pending_effective_date'] = null;
      meta['pending_switch_reason'] = null;
    } else {
      meta['pending_approach_id'] = toApproachId;
      meta['pending_effective_date'] = effectiveDate.toIso8601String();
      meta['pending_switch_reason'] = reason;
    }

    meta['switch_history'] = history.take(20).toList();
    await _persistMeta(childId, meta);
    _syncStateFromMeta(meta);
  }

  Future<void> setQuickDoneEnabled({
    required String childId,
    required bool enabled,
  }) async {
    final meta = await _readMeta(childId);
    meta['quick_done_enabled'] = enabled;
    await _persistMeta(childId, meta);
    _syncStateFromMeta(meta);
  }

  Future<void> setHomeContext({
    required String childId,
    required bool sharedRoom,
    required String caregiverConsistency,
    required String cryingTolerance,
    required bool canLeaveRoom,
    required bool nightFeedsExpected,
  }) async {
    final meta = await _readMeta(childId);
    meta['home_context_set'] = true;
    meta['shared_room'] = sharedRoom;
    meta['caregiver_consistency'] = caregiverConsistency;
    meta['crying_tolerance'] = cryingTolerance;
    meta['can_leave_room'] = canLeaveRoom;
    meta['night_feeds_expected'] = nightFeedsExpected;
    await _persistMeta(childId, meta);
    _syncStateFromMeta(meta);
  }

  Future<void> loadTonightPlan(String childId, {DateTime? now}) async {
    state = state.copyWith(isLoading: true, lastError: null);
    try {
      final box = await _ensureBox();
      final ts = now ?? DateTime.now();
      final nightDate = _nightAnchorDate(ts);
      final key = _keyFor(childId, nightDate);
      final raw = box.get(key);

      final meta = await _readMeta(
        childId,
        selectedApproachId: state.selectedApproachId.isEmpty
            ? null
            : state.selectedApproachId,
      );
      final metaMutated = _applyPendingSwitchIfDue(meta: meta, nightDate: ts);
      if (metaMutated) {
        await _persistMeta(childId, meta);
      }
      _syncStateFromMeta(meta);

      if (raw is Map) {
        state = state.copyWith(
          isLoading: false,
          activePlan: Map<String, dynamic>.from(raw),
          breathingDifficulty: false,
          dehydrationSigns: false,
          repeatedVomiting: false,
          severePainIndicators: false,
          feedingRefusalWithPainSigns: false,
          safeSleepConfirmed: raw['safe_sleep_confirmed'] as bool? ?? true,
          comfortMode: raw['comfort_mode'] as bool? ?? false,
          somethingFeelsOff: raw['something_feels_off'] as bool? ?? false,
          lastError: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          activePlan: null,
          breathingDifficulty: false,
          dehydrationSigns: false,
          repeatedVomiting: false,
          severePainIndicators: false,
          feedingRefusalWithPainSigns: false,
          safeSleepConfirmed: true,
          comfortMode: false,
          somethingFeelsOff: false,
          lastError: null,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, lastError: e.toString());
    }
  }

  /// Clears the active plan from state so the situation picker shows again.
  Future<void> clearActivePlan(String childId) async {
    final plan = state.activePlan;
    if (plan == null) return;
    final box = await _ensureBox();
    final dateRaw = plan['date'] as String?;
    if (dateRaw != null) {
      final date = DateTime.tryParse('${dateRaw}T00:00:00') ?? DateTime.now();
      await box.delete(_keyFor(childId, date));
    }
    state = state.copyWith(activePlan: null);
  }

  void updateSafetyGate({
    required bool breathingDifficulty,
    required bool dehydrationSigns,
    required bool repeatedVomiting,
    required bool severePainIndicators,
    required bool feedingRefusalWithPainSigns,
    required bool safeSleepConfirmed,
  }) {
    state = state.copyWith(
      breathingDifficulty: breathingDifficulty,
      dehydrationSigns: dehydrationSigns,
      repeatedVomiting: repeatedVomiting,
      severePainIndicators: severePainIndicators,
      feedingRefusalWithPainSigns: feedingRefusalWithPainSigns,
      safeSleepConfirmed: safeSleepConfirmed,
    );
  }

  List<Map<String, dynamic>> _buildFallbackSteps({
    required String scenario,
    required String preference,
    required bool feedingAssociation,
    required String feedMode,
  }) {
    final base = <Map<String, dynamic>>[];

    switch (scenario) {
      case 'night_wakes':
        base.addAll([
          {
            'title': 'Pause and observe',
            'script': 'I am here. You are safe.',
            'minutes': preference == 'gentle' ? 2 : 3,
          },
          {
            'title': 'Single check-in',
            'script': 'I will keep this short and calm.',
            'minutes': preference == 'firm' ? 4 : 3,
          },
          {
            'title': 'Return to baseline',
            'script': 'Back to sleep. I love you.',
            'minutes': preference == 'gentle' ? 3 : 5,
          },
        ]);
        break;
      case 'early_wakes':
        base.addAll([
          {
            'title': 'Hold low-stimulation environment',
            'script': 'It is still sleep time.',
            'minutes': 5,
          },
          {
            'title': 'Brief reassurance',
            'script': 'I hear you. Time to rest.',
            'minutes': preference == 'firm' ? 3 : 4,
          },
          {
            'title': 'Start day only after threshold',
            'script': 'We start the day at our set time.',
            'minutes': 6,
          },
        ]);
        break;
      case 'split_nights':
        base.addAll([
          {
            'title': 'Reset body cues',
            'script': 'Dark room. Quiet voice. No play.',
            'minutes': 4,
          },
          {
            'title': 'One settling cycle',
            'script': 'I stay calm and brief.',
            'minutes': preference == 'gentle' ? 4 : 5,
          },
          {
            'title': 'Repeat once, then stop escalating',
            'script': 'Consistent and predictable helps most.',
            'minutes': 6,
          },
        ]);
        break;
      case 'bedtime_protest':
      default:
        base.addAll([
          {
            'title': 'Set boundary and script',
            'script': 'Bedtime now. I will help you settle.',
            'minutes': preference == 'gentle' ? 2 : 3,
          },
          {
            'title': 'One calm intervention',
            'script': 'I keep this brief and steady.',
            'minutes': preference == 'firm' ? 4 : 3,
          },
          {
            'title': 'Pause before next response',
            'script': 'I stay consistent. You are safe.',
            'minutes': preference == 'gentle' ? 3 : 5,
          },
        ]);
    }

    if (feedingAssociation) {
      final feedScript = switch (feedMode) {
        'reduce_gradually' => 'Reduce feed gradually; keep routine consistent.',
        'separate_feed_sleep' => 'Move feed earlier in routine tonight.',
        _ => 'Keep age-appropriate feed and resume plan.',
      };
      base.add({'title': 'Feed decision', 'script': feedScript, 'minutes': 2});
    }

    return base;
  }

  int _adjustMinutesForHomeContext(int minutes) {
    var adjusted = minutes;
    if (state.cryingTolerance == 'low') {
      adjusted = adjusted > 1 ? adjusted - 1 : adjusted;
    }
    if (state.sharedRoom) {
      adjusted = adjusted > 2 ? adjusted - 1 : adjusted;
    }
    if (!state.canLeaveRoom) {
      adjusted = adjusted > 3 ? 3 : adjusted;
    }
    if (state.caregiverConsistency == 'rotating') {
      adjusted = adjusted > 4 ? 4 : adjusted;
    }
    if (state.caregiverConsistency == 'unsure') {
      adjusted = adjusted > 5 ? 5 : adjusted;
    }
    return adjusted.clamp(1, 8);
  }

  List<Map<String, dynamic>> _applyHomeContextToSteps(
    List<Map<String, dynamic>> steps,
  ) {
    return steps.map((raw) {
      final step = Map<String, dynamic>.from(raw);
      final minutes = step['minutes'] as int? ?? 3;
      step['minutes'] = _adjustMinutesForHomeContext(minutes);
      return step;
    }).toList();
  }

  Future<void> createTonightPlan({
    required String childId,
    required int ageMonths,
    required String scenario,
    required String preference,
    required bool feedingAssociation,
    required String feedMode,
    required bool safeSleepConfirmed,
    String? lockedMethodId,
    int? timeToStartSeconds,
    DateTime? now,
  }) async {
    state = state.copyWith(lastError: null);

    final stop = await _guidance.evaluateStopRules(
      redFlagHealthFlag: state.breathingDifficulty,
      unsafeSleepEnvironmentFlag: !safeSleepConfirmed,
      dehydrationSigns: state.dehydrationSigns,
      repeatedVomiting: state.repeatedVomiting,
      severePainIndicators: state.severePainIndicators,
      feedingRefusalWithPainSigns: state.feedingRefusalWithPainSigns,
    );
    if (stop.blocked) {
      state = state.copyWith(lastError: stop.message);
      return;
    }

    final date = now ?? DateTime.now();
    final nightDate = _nightAnchorDate(date);
    final planId = '${childId}_${date.microsecondsSinceEpoch}';

    String methodId = 'fallback_method';
    String flowId = 'fallback_flow';
    String feedPolicyId = 'feed_windows';
    String policyVersion = 'fallback_policy_v1';
    List<String> evidenceRefs = const [];
    String escalationRule =
        'If escalation continues after one cycle, reset to step 1 with shorter response.';

    List<Map<String, dynamic>> steps;
    try {
      final template = await _guidance.buildTonightPlan(
        ageMonths: ageMonths,
        scenario: scenario,
        preference: preference,
        feedingAssociation: feedingAssociation,
        feedMode: feedMode,
        lockedMethodId: lockedMethodId,
      );

      methodId = template.methodId;
      flowId = template.flowId;
      feedPolicyId = template.feedPolicyId;
      policyVersion = template.policyVersion;
      evidenceRefs = template.evidenceRefs;
      escalationRule = template.escalationRule;
      steps = template.steps
          .map(
            (s) => {
              'id': s.stepId,
              'title': s.title,
              'script': s.say,
              'do_step': s.doStep,
              'minutes': s.minutes,
            },
          )
          .toList();
    } catch (_) {
      steps = _buildFallbackSteps(
        scenario: scenario,
        preference: preference,
        feedingAssociation: feedingAssociation,
        feedMode: feedMode,
      );
    }
    steps = _applyHomeContextToSteps(steps);

    final plan = <String, dynamic>{
      'plan_id': planId,
      'child_id': childId,
      'date': _dateKey(nightDate),
      'scenario': scenario,
      'preference': preference,
      'method_id': methodId,
      'flow_id': flowId,
      'feeding_association': feedingAssociation,
      'feed_mode': feedMode,
      'locked_method_id': lockedMethodId ?? '',
      'feed_policy_id': feedPolicyId,
      'policy_version': policyVersion,
      'evidence_refs': evidenceRefs,
      'safe_sleep_confirmed': safeSleepConfirmed,
      'comfort_mode': false,
      'something_feels_off': false,
      'training_paused': false,
      'steps': steps,
      'current_step': 0,
      'wakes_logged': 0,
      'early_wakes_logged': 0,
      'is_active': true,
      'escalation_rule': escalationRule,
      'morning_review_complete': false,
      'recap_outcome': null,
      'recap_time_bucket': null,
      'recap_note': null,
      'runner_hint': '',
      'created_at': date.toIso8601String(),
      'last_updated_at': date.toIso8601String(),
    };

    final box = await _ensureBox();
    final key = _keyFor(childId, nightDate);
    await box.put(key, plan);
    state = state.copyWith(
      activePlan: plan,
      safeSleepConfirmed: safeSleepConfirmed,
      comfortMode: false,
      somethingFeelsOff: false,
    );

    await EventBusService.emitSleepPlanStarted(
      childId: childId,
      linkedPlanId: planId,
      scenario: scenario,
      preference: preference,
      methodId: methodId,
      flowId: flowId,
      policyVersion: policyVersion,
      templateId: flowId,
      timeToStartSeconds: timeToStartSeconds,
      evidenceRefs: evidenceRefs,
    );
  }

  Future<void> _persistPlan(Map<String, dynamic> plan) async {
    final box = await _ensureBox();
    final childId = plan['child_id'] as String;
    final dateRaw = plan['date'] as String;
    final date = DateTime.tryParse('${dateRaw}T00:00:00') ?? DateTime.now();
    await box.put(_keyFor(childId, date), plan);
    state = state.copyWith(
      activePlan: plan,
      comfortMode: plan['comfort_mode'] as bool? ?? false,
      somethingFeelsOff: plan['something_feels_off'] as bool? ?? false,
    );
  }

  Future<void> setComfortMode(bool enabled) async {
    final plan = state.activePlan;
    if (plan == null) {
      state = state.copyWith(comfortMode: enabled);
      return;
    }

    plan['comfort_mode'] = enabled;
    plan['training_paused'] = enabled;
    plan['runner_hint'] = enabled
        ? 'Comfort mode on. Pause training expectations tonight.'
        : 'Training mode resumed. Keep responses brief and consistent.';
    plan['last_updated_at'] = DateTime.now().toIso8601String();
    await _persistPlan(plan);
  }

  Future<void> markSomethingFeelsOff() async {
    final plan = state.activePlan;
    if (plan == null) {
      state = state.copyWith(comfortMode: true, somethingFeelsOff: true);
      return;
    }

    plan['comfort_mode'] = true;
    plan['something_feels_off'] = true;
    plan['training_paused'] = true;
    plan['runner_hint'] = 'Something feels off. Comfort first tonight.';
    plan['last_updated_at'] = DateTime.now().toIso8601String();
    await _persistPlan(plan);
  }

  Future<void> completeCurrentStep() async {
    final plan = state.activePlan;
    if (plan == null) return;

    final step = plan['current_step'] as int? ?? 0;
    final steps = (plan['steps'] as List?)?.cast<Map>() ?? <Map>[];

    if (step < steps.length - 1) {
      final next = step + 1;
      plan['current_step'] = next;
      plan['runner_hint'] = 'Step complete. Start step ${next + 1} now.';
    } else {
      plan['runner_hint'] =
          'Step complete. Hold this response unless a wake is logged.';
    }

    plan['last_updated_at'] = DateTime.now().toIso8601String();
    await _persistPlan(plan);

    await EventBusService.emitSleepStepCompleted(
      childId: plan['child_id'] as String,
      linkedPlanId: plan['plan_id'] as String,
      completedStep: step,
    );
  }

  Future<void> logNightWake() async {
    final plan = state.activePlan;
    if (plan == null) return;

    final wakes = plan['wakes_logged'] as int? ?? 0;
    final currentStep = plan['current_step'] as int? ?? 0;
    final steps = (plan['steps'] as List?)?.cast<Map>() ?? <Map>[];
    if (steps.isNotEmpty) {
      final nextStep = (currentStep + 1).clamp(0, steps.length - 1);
      plan['current_step'] = nextStep;
      plan['runner_hint'] = 'Wake logged. Start step ${nextStep + 1} now.';
    } else {
      plan['runner_hint'] = 'Wake logged. Continue with your calming script.';
    }
    plan['wakes_logged'] = wakes + 1;
    plan['last_updated_at'] = DateTime.now().toIso8601String();
    await _persistPlan(plan);

    await EventBusService.emitSleepNightWakeLogged(
      childId: plan['child_id'] as String,
      linkedPlanId: plan['plan_id'] as String,
      wakeCount: wakes + 1,
    );
  }

  Future<void> logEarlyWake() async {
    final plan = state.activePlan;
    if (plan == null) return;

    final wakes = plan['early_wakes_logged'] as int? ?? 0;
    final steps = (plan['steps'] as List?)?.cast<Map>() ?? <Map>[];
    if (steps.isNotEmpty) {
      plan['current_step'] = 0;
      plan['runner_hint'] = 'Early wake logged. Restart at step 1.';
    } else {
      plan['runner_hint'] =
          'Early wake logged. Keep environment low-stimulation.';
    }
    plan['early_wakes_logged'] = wakes + 1;
    plan['last_updated_at'] = DateTime.now().toIso8601String();
    await _persistPlan(plan);

    await EventBusService.emitSleepEarlyWakeLogged(
      childId: plan['child_id'] as String,
      linkedPlanId: plan['plan_id'] as String,
      earlyWakeCount: wakes + 1,
    );
  }

  Future<void> logFeedTaperStep() async {
    final plan = state.activePlan;
    if (plan == null) return;

    await EventBusService.emitSleepFeedTaperStep(
      childId: plan['child_id'] as String,
      linkedPlanId: plan['plan_id'] as String,
      feedMode: plan['feed_mode'] as String? ?? 'keep_feeds',
    );
  }

  Future<void> abortPlan() async {
    final plan = state.activePlan;
    if (plan == null) return;

    plan['is_active'] = false;
    plan['runner_hint'] = 'Plan paused.';
    plan['last_updated_at'] = DateTime.now().toIso8601String();
    await _persistPlan(plan);

    await EventBusService.emitSleepPlanAborted(
      childId: plan['child_id'] as String,
      linkedPlanId: plan['plan_id'] as String,
    );
  }

  Future<void> completeWithRecap({
    required String childId,
    required SleepRecapOutcome outcome,
    String? timeToSettleBucket,
    String? note,
  }) async {
    final plan = state.activePlan;
    if (plan == null) return;

    if ((plan['scenario']?.toString() ?? '') == 'early_wakes') {
      await logEarlyWake();
    }

    plan['morning_review_complete'] = true;
    plan['recap_outcome'] = outcome.wire;
    plan['recap_time_bucket'] = timeToSettleBucket;
    plan['recap_note'] = note?.trim();
    plan['runner_hint'] = 'Recap saved.';
    plan['last_updated_at'] = DateTime.now().toIso8601String();
    await _persistPlan(plan);

    final meta = await _readMeta(childId);
    meta['last_recap_outcome'] = outcome.wire;
    meta['last_recap_time_bucket'] = timeToSettleBucket;
    await _persistMeta(childId, meta);
    _syncStateFromMeta(meta);

    await EventBusService.emitSleepMorningReviewComplete(
      childId: plan['child_id'] as String,
      linkedPlanId: plan['plan_id'] as String,
      wakesLogged: plan['wakes_logged'] as int? ?? 0,
    );
  }

  Future<void> completeMorningReview() async {
    final plan = state.activePlan;
    if (plan == null) return;
    await completeWithRecap(
      childId: plan['child_id'] as String,
      outcome: SleepRecapOutcome.settled,
      timeToSettleBucket: state.lastTimeToSettleBucket,
    );
  }
}
