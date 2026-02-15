import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/event_bus_service.dart';
import '../services/sleep_guidance_service.dart';

const _sleepTonightBox = 'sleep_tonight_v1';

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
  final String? lastError;

  bool get hasActivePlan =>
      activePlan != null && (activePlan!['is_active'] as bool? ?? false);

  bool get redFlagTriggered =>
      breathingDifficulty ||
      dehydrationSigns ||
      repeatedVomiting ||
      severePainIndicators ||
      feedingRefusalWithPainSigns;

  static const initial = SleepTonightState(
    isLoading: true,
    activePlan: null,
    breathingDifficulty: false,
    dehydrationSigns: false,
    repeatedVomiting: false,
    severePainIndicators: false,
    feedingRefusalWithPainSigns: false,
    safeSleepConfirmed: false,
    comfortMode: false,
    somethingFeelsOff: false,
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

  String _keyFor(String childId, DateTime date) {
    final dayKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$childId:$dayKey';
  }

  Future<void> loadTonightPlan(String childId, {DateTime? now}) async {
    state = state.copyWith(isLoading: true, lastError: null);
    try {
      final box = await _ensureBox();
      final ts = now ?? DateTime.now();
      final key = _keyFor(childId, _nightAnchorDate(ts));
      final raw = box.get(key);
      if (raw is Map) {
        state = state.copyWith(
          isLoading: false,
          activePlan: Map<String, dynamic>.from(raw),
          breathingDifficulty: false,
          dehydrationSigns: false,
          repeatedVomiting: false,
          severePainIndicators: false,
          feedingRefusalWithPainSigns: false,
          safeSleepConfirmed: raw['safe_sleep_confirmed'] as bool? ?? false,
          comfortMode: raw['comfort_mode'] as bool? ?? false,
          somethingFeelsOff: raw['something_feels_off'] as bool? ?? false,
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
          safeSleepConfirmed: false,
          comfortMode: false,
          somethingFeelsOff: false,
          lastError: null,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, lastError: e.toString());
    }
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

    final plan = <String, dynamic>{
      'plan_id': planId,
      'child_id': childId,
      'date':
          '${nightDate.year}-${nightDate.month.toString().padLeft(2, '0')}-${nightDate.day.toString().padLeft(2, '0')}',
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
      'runner_hint': '',
      'created_at': DateTime.now().toIso8601String(),
      'last_updated_at': DateTime.now().toIso8601String(),
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

  Future<void> completeMorningReview() async {
    final plan = state.activePlan;
    if (plan == null) return;

    plan['morning_review_complete'] = true;
    plan['runner_hint'] = 'Morning review captured.';
    plan['last_updated_at'] = DateTime.now().toIso8601String();
    await _persistPlan(plan);

    await EventBusService.emitSleepMorningReviewComplete(
      childId: plan['child_id'] as String,
      linkedPlanId: plan['plan_id'] as String,
      wakesLogged: plan['wakes_logged'] as int? ?? 0,
    );
  }
}
