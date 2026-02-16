import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/rhythm_models.dart';
import '../services/rhythm_engine_service.dart';
import '../services/rhythm_shift_detector_service.dart';

const _rhythmBoxName = 'rhythm_v1';

class RhythmState {
  const RhythmState({
    required this.isLoading,
    required this.rhythm,
    required this.todaySchedule,
    required this.events,
    required this.recapHistory,
    required this.dailySignals,
    required this.shiftAssessment,
    required this.lastUpdatePlan,
    required this.lastRhythmUpdateAt,
    required this.advancedDayLogging,
    required this.preciseView,
    required this.wakeTimeMinutes,
    required this.wakeTimeKnown,
    required this.lastHint,
  });

  final bool isLoading;
  final Rhythm? rhythm;
  final DaySchedule? todaySchedule;
  final List<RhythmDayEvent> events;
  final List<MorningRecapEntry> recapHistory;
  final List<RhythmDailySignal> dailySignals;
  final RhythmShiftAssessment shiftAssessment;
  final RhythmUpdatePlan? lastUpdatePlan;
  final DateTime? lastRhythmUpdateAt;
  final bool advancedDayLogging;
  final bool preciseView;
  final int wakeTimeMinutes;
  final bool wakeTimeKnown;
  final String? lastHint;

  static const initial = RhythmState(
    isLoading: true,
    rhythm: null,
    todaySchedule: null,
    events: [],
    recapHistory: [],
    dailySignals: [],
    shiftAssessment: RhythmShiftAssessment.none,
    lastUpdatePlan: null,
    lastRhythmUpdateAt: null,
    advancedDayLogging: false,
    preciseView: false,
    wakeTimeMinutes: 7 * 60,
    wakeTimeKnown: false,
    lastHint: null,
  );

  RhythmState copyWith({
    bool? isLoading,
    Object? rhythm = _noChange,
    Object? todaySchedule = _noChange,
    List<RhythmDayEvent>? events,
    List<MorningRecapEntry>? recapHistory,
    List<RhythmDailySignal>? dailySignals,
    RhythmShiftAssessment? shiftAssessment,
    Object? lastUpdatePlan = _noChange,
    Object? lastRhythmUpdateAt = _noChange,
    bool? advancedDayLogging,
    bool? preciseView,
    int? wakeTimeMinutes,
    bool? wakeTimeKnown,
    Object? lastHint = _noChange,
  }) {
    return RhythmState(
      isLoading: isLoading ?? this.isLoading,
      rhythm: identical(rhythm, _noChange) ? this.rhythm : rhythm as Rhythm?,
      todaySchedule: identical(todaySchedule, _noChange)
          ? this.todaySchedule
          : todaySchedule as DaySchedule?,
      events: events ?? this.events,
      recapHistory: recapHistory ?? this.recapHistory,
      dailySignals: dailySignals ?? this.dailySignals,
      shiftAssessment: shiftAssessment ?? this.shiftAssessment,
      lastUpdatePlan: identical(lastUpdatePlan, _noChange)
          ? this.lastUpdatePlan
          : lastUpdatePlan as RhythmUpdatePlan?,
      lastRhythmUpdateAt: identical(lastRhythmUpdateAt, _noChange)
          ? this.lastRhythmUpdateAt
          : lastRhythmUpdateAt as DateTime?,
      advancedDayLogging: advancedDayLogging ?? this.advancedDayLogging,
      preciseView: preciseView ?? this.preciseView,
      wakeTimeMinutes: wakeTimeMinutes ?? this.wakeTimeMinutes,
      wakeTimeKnown: wakeTimeKnown ?? this.wakeTimeKnown,
      lastHint: identical(lastHint, _noChange)
          ? this.lastHint
          : lastHint as String?,
    );
  }
}

const _noChange = Object();

final rhythmProvider = StateNotifierProvider<RhythmNotifier, RhythmState>((
  ref,
) {
  return RhythmNotifier();
});

class RhythmNotifier extends StateNotifier<RhythmState> {
  RhythmNotifier() : super(RhythmState.initial);

  Box<dynamic>? _box;
  final RhythmEngineService _engine = RhythmEngineService.instance;
  final RhythmShiftDetectorService _shiftDetector =
      RhythmShiftDetectorService.instance;

  Future<Box<dynamic>> _ensureBox() async {
    _box ??= await Hive.openBox<dynamic>(_rhythmBoxName);
    return _box!;
  }

  String _keyFor(String childId) => 'rhythm:$childId';

  Future<void> load({
    required String childId,
    required int ageMonths,
    DateTime? now,
  }) async {
    state = state.copyWith(isLoading: true, lastHint: null);
    final box = await _ensureBox();
    final raw = box.get(_keyFor(childId));

    Rhythm rhythm;
    DaySchedule? previousSchedule;
    var wakeMinutes = state.wakeTimeMinutes;
    var wakeKnown = state.wakeTimeKnown;
    var preciseView = state.preciseView;
    var recapHistory = <MorningRecapEntry>[];
    var dailySignals = <RhythmDailySignal>[];
    DateTime? lastRhythmUpdateAt;
    var advancedDayLogging = state.advancedDayLogging;

    if (raw is Map) {
      final map = raw.cast<String, dynamic>();
      final rhythmMap = (map['rhythm'] as Map?)?.cast<String, dynamic>();
      final scheduleMap = (map['today_schedule'] as Map?)
          ?.cast<String, dynamic>();
      final recapRaw = (map['recap_history'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => MorningRecapEntry.fromMap(e.cast<String, dynamic>()))
          .toList();
      final signalRaw = (map['daily_signals'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => RhythmDailySignal.fromMap(e.cast<String, dynamic>()))
          .toList();
      rhythm = rhythmMap == null
          ? _engine.defaultRhythmForAge(ageMonths: ageMonths, now: now)
          : Rhythm.fromMap(rhythmMap);
      previousSchedule = scheduleMap == null
          ? null
          : DaySchedule.fromMap(scheduleMap);
      wakeMinutes = map['wake_time_minutes'] as int? ?? wakeMinutes;
      wakeKnown = map['wake_time_known'] as bool? ?? wakeKnown;
      preciseView = map['precise_view'] as bool? ?? preciseView;
      advancedDayLogging =
          map['advanced_day_logging'] as bool? ?? advancedDayLogging;
      recapHistory = recapRaw;
      dailySignals = signalRaw;
      lastRhythmUpdateAt = DateTime.tryParse(
        map['last_rhythm_update_at']?.toString() ?? '',
      );
    } else {
      rhythm = _engine.defaultRhythmForAge(ageMonths: ageMonths, now: now);
    }

    final baseSchedule = _engine.buildDaySchedule(
      rhythm: rhythm,
      wakeTimeMinutes: wakeMinutes,
      wakeTimeKnown: wakeKnown,
      events: const [],
      previousSchedule: previousSchedule,
      now: now,
    );
    final schedule = _scheduleWithConfidence(
      schedule: baseSchedule,
      recapHistory: recapHistory,
      dailySignals: dailySignals,
      now: now ?? DateTime.now(),
    );
    final shiftAssessment = _computeShiftAssessment(
      ageMonths: rhythm.ageMonths,
      recapHistory: recapHistory,
      dailySignals: dailySignals,
      lastRhythmUpdateAt: lastRhythmUpdateAt,
      now: now ?? DateTime.now(),
    );

    state = state.copyWith(
      isLoading: false,
      rhythm: rhythm,
      todaySchedule: schedule,
      wakeTimeMinutes: wakeMinutes,
      wakeTimeKnown: wakeKnown,
      events: const [],
      recapHistory: recapHistory,
      dailySignals: dailySignals,
      shiftAssessment: shiftAssessment,
      lastUpdatePlan: null,
      lastRhythmUpdateAt: lastRhythmUpdateAt,
      advancedDayLogging: advancedDayLogging,
      preciseView: preciseView,
      lastHint: null,
    );
    await _persist(childId);
  }

  Future<void> setPreciseView({
    required String childId,
    required bool precise,
  }) async {
    state = state.copyWith(preciseView: precise);
    await _persist(childId);
  }

  Future<void> setAdvancedDayLogging({
    required String childId,
    required bool enabled,
  }) async {
    final now = DateTime.now();
    state = state.copyWith(
      advancedDayLogging: enabled,
      todaySchedule: _rescoreExistingSchedule(
        recapHistory: state.recapHistory,
        dailySignals: state.dailySignals,
        now: now,
      ),
      lastHint: enabled
          ? 'Advanced day logging is on.'
          : 'Advanced day logging is off.',
    );
    await _persist(childId);
  }

  Future<void> setWakeTime({
    required String childId,
    required int wakeTimeMinutes,
    required bool known,
  }) async {
    final baselineWake =
        state.todaySchedule?.wakeTimeMinutes ?? state.wakeTimeMinutes;
    final earlyWakeLogged = known && wakeTimeMinutes <= (baselineWake - 20);
    final signalNow = DateTime.now();
    final dailySignals = _upsertDailySignal(
      signals: state.dailySignals,
      now: signalNow,
      update: (current) => current.copyWith(
        earlyWakeLogged: current.earlyWakeLogged || earlyWakeLogged,
      ),
    );
    final shiftAssessment = _computeShiftAssessment(
      ageMonths: state.rhythm?.ageMonths ?? 6,
      recapHistory: state.recapHistory,
      dailySignals: dailySignals,
      lastRhythmUpdateAt: state.lastRhythmUpdateAt,
      now: signalNow,
    );

    state = state.copyWith(
      wakeTimeMinutes: wakeTimeMinutes,
      wakeTimeKnown: known,
      dailySignals: dailySignals,
      shiftAssessment: shiftAssessment,
      lastHint: 'Still okay. We adjusted around this wake time.',
    );
    await recalculate(childId: childId);
  }

  Future<void> markShortNap({required String childId}) async {
    final rhythm = state.rhythm;
    if (rhythm == null) return;
    final nextIndex = _nextEventNapIndex(rhythm.napCountTarget);
    final event = RhythmDayEvent(
      type: RhythmDayEventType.shortNap,
      napIndex: nextIndex,
      createdAt: DateTime.now(),
    );
    final signalNow = DateTime.now();
    final dailySignals = _upsertDailySignal(
      signals: state.dailySignals,
      now: signalNow,
      update: (current) =>
          current.copyWith(shortNapCount: current.shortNapCount + 1),
    );
    final shiftAssessment = _computeShiftAssessment(
      ageMonths: state.rhythm?.ageMonths ?? 6,
      recapHistory: state.recapHistory,
      dailySignals: dailySignals,
      lastRhythmUpdateAt: state.lastRhythmUpdateAt,
      now: signalNow,
    );

    state = state.copyWith(
      events: [...state.events, event],
      dailySignals: dailySignals,
      shiftAssessment: shiftAssessment,
      lastHint: 'Still okay. Short nap noted.',
    );
    await recalculate(childId: childId);
  }

  Future<void> markSkippedNap({required String childId}) async {
    final rhythm = state.rhythm;
    if (rhythm == null) return;
    final nextIndex = _nextEventNapIndex(rhythm.napCountTarget);
    final event = RhythmDayEvent(
      type: RhythmDayEventType.skippedNap,
      napIndex: nextIndex,
      createdAt: DateTime.now(),
    );
    final signalNow = DateTime.now();
    final dailySignals = _upsertDailySignal(
      signals: state.dailySignals,
      now: signalNow,
      update: (current) =>
          current.copyWith(skippedNapCount: current.skippedNapCount + 1),
    );
    final shiftAssessment = _computeShiftAssessment(
      ageMonths: state.rhythm?.ageMonths ?? 6,
      recapHistory: state.recapHistory,
      dailySignals: dailySignals,
      lastRhythmUpdateAt: state.lastRhythmUpdateAt,
      now: signalNow,
    );

    state = state.copyWith(
      events: [...state.events, event],
      dailySignals: dailySignals,
      shiftAssessment: shiftAssessment,
      lastHint: 'Still okay. Skipped nap noted.',
    );
    await recalculate(childId: childId);
  }

  Future<void> markNapQualityTap({
    required String childId,
    required NapQualityTap quality,
  }) async {
    switch (quality) {
      case NapQualityTap.short:
        await markShortNap(childId: childId);
        return;
      case NapQualityTap.ok:
        final signalNow = DateTime.now();
        final dailySignals = _upsertDailySignal(
          signals: state.dailySignals,
          now: signalNow,
          update: (current) =>
              current.copyWith(okNapCount: current.okNapCount + 1),
        );
        final shiftAssessment = _computeShiftAssessment(
          ageMonths: state.rhythm?.ageMonths ?? 6,
          recapHistory: state.recapHistory,
          dailySignals: dailySignals,
          lastRhythmUpdateAt: state.lastRhythmUpdateAt,
          now: signalNow,
        );
        state = state.copyWith(
          dailySignals: dailySignals,
          todaySchedule: _rescoreExistingSchedule(
            recapHistory: state.recapHistory,
            dailySignals: dailySignals,
            now: signalNow,
          ),
          shiftAssessment: shiftAssessment,
          lastHint: 'Still okay. Nap quality logged as OK.',
        );
        await _persist(childId);
        return;
      case NapQualityTap.long:
        final signalNow = DateTime.now();
        final dailySignals = _upsertDailySignal(
          signals: state.dailySignals,
          now: signalNow,
          update: (current) =>
              current.copyWith(longNapCount: current.longNapCount + 1),
        );
        final shiftAssessment = _computeShiftAssessment(
          ageMonths: state.rhythm?.ageMonths ?? 6,
          recapHistory: state.recapHistory,
          dailySignals: dailySignals,
          lastRhythmUpdateAt: state.lastRhythmUpdateAt,
          now: signalNow,
        );
        state = state.copyWith(
          dailySignals: dailySignals,
          todaySchedule: _rescoreExistingSchedule(
            recapHistory: state.recapHistory,
            dailySignals: dailySignals,
            now: signalNow,
          ),
          shiftAssessment: shiftAssessment,
          lastHint: 'Still okay. Nap quality logged as long.',
        );
        await _persist(childId);
        return;
    }
  }

  Future<void> markNapStarted({required String childId}) async {
    final signalNow = DateTime.now();
    final dailySignals = _upsertDailySignal(
      signals: state.dailySignals,
      now: signalNow,
      update: (current) => current.copyWith(
        advancedNapStartCount: current.advancedNapStartCount + 1,
      ),
    );
    final shiftAssessment = _computeShiftAssessment(
      ageMonths: state.rhythm?.ageMonths ?? 6,
      recapHistory: state.recapHistory,
      dailySignals: dailySignals,
      lastRhythmUpdateAt: state.lastRhythmUpdateAt,
      now: signalNow,
    );
    state = state.copyWith(
      dailySignals: dailySignals,
      todaySchedule: _rescoreExistingSchedule(
        recapHistory: state.recapHistory,
        dailySignals: dailySignals,
        now: signalNow,
      ),
      shiftAssessment: shiftAssessment,
      lastHint: 'Nap start logged.',
    );
    await _persist(childId);
  }

  Future<void> markNapEnded({required String childId}) async {
    final signalNow = DateTime.now();
    final dailySignals = _upsertDailySignal(
      signals: state.dailySignals,
      now: signalNow,
      update: (current) => current.copyWith(
        advancedNapEndCount: current.advancedNapEndCount + 1,
      ),
    );
    final shiftAssessment = _computeShiftAssessment(
      ageMonths: state.rhythm?.ageMonths ?? 6,
      recapHistory: state.recapHistory,
      dailySignals: dailySignals,
      lastRhythmUpdateAt: state.lastRhythmUpdateAt,
      now: signalNow,
    );
    state = state.copyWith(
      dailySignals: dailySignals,
      todaySchedule: _rescoreExistingSchedule(
        recapHistory: state.recapHistory,
        dailySignals: dailySignals,
        now: signalNow,
      ),
      shiftAssessment: shiftAssessment,
      lastHint: 'Nap end logged.',
    );
    await _persist(childId);
  }

  Future<void> markBedtimeResistance({
    required String childId,
    int delayMinutes = 25,
  }) async {
    final signalNow = DateTime.now();
    final dailySignals = _upsertDailySignal(
      signals: state.dailySignals,
      now: signalNow,
      update: (current) => current.copyWith(
        bedtimeResistance: true,
        bedtimeDelayMinutes: delayMinutes > current.bedtimeDelayMinutes
            ? delayMinutes
            : current.bedtimeDelayMinutes,
      ),
    );
    final shiftAssessment = _computeShiftAssessment(
      ageMonths: state.rhythm?.ageMonths ?? 6,
      recapHistory: state.recapHistory,
      dailySignals: dailySignals,
      lastRhythmUpdateAt: state.lastRhythmUpdateAt,
      now: signalNow,
    );
    state = state.copyWith(
      dailySignals: dailySignals,
      todaySchedule: _rescoreExistingSchedule(
        recapHistory: state.recapHistory,
        dailySignals: dailySignals,
        now: signalNow,
      ),
      shiftAssessment: shiftAssessment,
      lastHint: 'Still okay. Bedtime resistance noted.',
    );
    await _persist(childId);
  }

  Future<void> submitMorningRecap({
    required String childId,
    required MorningRecapNightQuality nightQuality,
    required MorningRecapWakesBucket wakesBucket,
    required MorningRecapLongestAwakeBucket longestAwakeBucket,
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    final nextEntry = MorningRecapEntry(
      dateKey: _dateKey(ts),
      nightQuality: nightQuality,
      wakesBucket: wakesBucket,
      longestAwakeBucket: longestAwakeBucket,
      createdAt: ts,
    );
    final recapHistory = <MorningRecapEntry>[
      nextEntry,
      ...state.recapHistory.where(
        (entry) => entry.dateKey != nextEntry.dateKey,
      ),
    ].take(14).toList();

    final shiftAssessment = _computeShiftAssessment(
      ageMonths: state.rhythm?.ageMonths ?? 6,
      recapHistory: recapHistory,
      dailySignals: state.dailySignals,
      lastRhythmUpdateAt: state.lastRhythmUpdateAt,
      now: ts,
    );
    state = state.copyWith(
      recapHistory: recapHistory,
      todaySchedule: _rescoreExistingSchedule(
        recapHistory: recapHistory,
        dailySignals: state.dailySignals,
        now: ts,
      ),
      shiftAssessment: shiftAssessment,
      lastHint: 'Morning recap saved.',
    );
    await _persist(childId);
  }

  Future<void> applyRhythmUpdate({
    required String childId,
    required int ageMonths,
    required int wakeRangeStartMinutes,
    required int wakeRangeEndMinutes,
    required bool daycareMode,
    required int? napCountReality,
    required RhythmUpdateIssue issue,
    int? napDurationHintMinutes,
    DateTime? now,
  }) async {
    final rhythm = state.rhythm;
    if (rhythm == null) return;

    final ts = now ?? DateTime.now();
    final resolvedIssue =
        napDurationHintMinutes != null &&
            napDurationHintMinutes < 45 &&
            issue == RhythmUpdateIssue.nightWakes
        ? RhythmUpdateIssue.shortNaps
        : issue;
    final whyNow = state.shiftAssessment.shouldSuggestUpdate
        ? state.shiftAssessment.explanation
        : 'Manual rhythm refresh requested.';
    final plan = _engine.buildUpdatedRhythm(
      currentRhythm: rhythm,
      ageMonths: ageMonths,
      wakeRangeStartMinutes: wakeRangeStartMinutes,
      wakeRangeEndMinutes: wakeRangeEndMinutes,
      daycareMode: daycareMode,
      napCountReality: napCountReality,
      issue: resolvedIssue,
      whyNow: whyNow,
      now: ts,
    );
    final baseSchedule = _engine.buildDaySchedule(
      rhythm: plan.rhythm,
      wakeTimeMinutes: state.wakeTimeMinutes,
      wakeTimeKnown: state.wakeTimeKnown,
      events: const [],
      previousSchedule: state.todaySchedule,
      now: ts,
    );
    final nextSchedule = _scheduleWithConfidence(
      schedule: baseSchedule,
      recapHistory: state.recapHistory,
      dailySignals: state.dailySignals,
      now: ts,
    );
    final shiftAssessment = _computeShiftAssessment(
      ageMonths: plan.rhythm.ageMonths,
      recapHistory: state.recapHistory,
      dailySignals: state.dailySignals,
      lastRhythmUpdateAt: ts,
      now: ts,
    );
    state = state.copyWith(
      rhythm: plan.rhythm,
      todaySchedule: nextSchedule,
      events: const [],
      lastUpdatePlan: plan,
      lastRhythmUpdateAt: ts,
      shiftAssessment: shiftAssessment,
      lastHint: napDurationHintMinutes == null
          ? 'Rhythm updated. Run this for 7–14 days before replanning.'
          : 'Rhythm updated using your nap timing input. Run this for 7–14 days before replanning.',
    );
    await _persist(childId);
  }

  Future<void> recalculate({required String childId}) async {
    final rhythm = state.rhythm;
    if (rhythm == null) return;

    final now = DateTime.now();
    final baseNext = _engine.buildDaySchedule(
      rhythm: rhythm,
      wakeTimeMinutes: state.wakeTimeMinutes,
      wakeTimeKnown: state.wakeTimeKnown,
      events: state.events,
      previousSchedule: state.todaySchedule,
      now: now,
    );
    final next = _scheduleWithConfidence(
      schedule: baseNext,
      recapHistory: state.recapHistory,
      dailySignals: state.dailySignals,
      now: now,
    );
    final shiftAssessment = _computeShiftAssessment(
      ageMonths: rhythm.ageMonths,
      recapHistory: state.recapHistory,
      dailySignals: state.dailySignals,
      lastRhythmUpdateAt: state.lastRhythmUpdateAt,
      now: now,
    );

    state = state.copyWith(
      todaySchedule: next,
      shiftAssessment: shiftAssessment,
      lastHint: state.lastHint ?? 'Still okay. Schedule recalculated.',
      // Events are consumed into the day projection after each recalc.
      events: const [],
    );
    await _persist(childId);
  }

  int _nextEventNapIndex(int napCountTarget) {
    final seen = state.events.map((e) => e.napIndex).toSet();
    for (var i = 1; i <= napCountTarget; i++) {
      if (!seen.contains(i)) return i;
    }
    return napCountTarget;
  }

  DaySchedule _scheduleWithConfidence({
    required DaySchedule schedule,
    required List<MorningRecapEntry> recapHistory,
    required List<RhythmDailySignal> dailySignals,
    required DateTime now,
  }) {
    final confidence = _scorePhase4Confidence(
      schedule: schedule,
      recapHistory: recapHistory,
      dailySignals: dailySignals,
      now: now,
    );
    return schedule.copyWith(confidence: confidence);
  }

  DaySchedule? _rescoreExistingSchedule({
    required List<MorningRecapEntry> recapHistory,
    required List<RhythmDailySignal> dailySignals,
    required DateTime now,
  }) {
    final schedule = state.todaySchedule;
    if (schedule == null) return null;
    return _scheduleWithConfidence(
      schedule: schedule,
      recapHistory: recapHistory,
      dailySignals: dailySignals,
      now: now,
    );
  }

  RhythmConfidence _scorePhase4Confidence({
    required DaySchedule schedule,
    required List<MorningRecapEntry> recapHistory,
    required List<RhythmDailySignal> dailySignals,
    required DateTime now,
  }) {
    var score = 85;
    if (!schedule.wakeTimeKnown) score -= 20;

    final hasRecentRecap = recapHistory.any(
      (recap) =>
          now.difference(recap.createdAt).inHours.abs() <= 48 &&
          recap.dateKey.isNotEmpty,
    );
    if (!hasRecentRecap) score -= 20;

    final todayKey = _dateKey(now);
    final todaySignal = dailySignals.firstWhere(
      (signal) => signal.dateKey == todayKey,
      orElse: () => RhythmDailySignal(
        dateKey: todayKey,
        shortNapCount: 0,
        skippedNapCount: 0,
        okNapCount: 0,
        longNapCount: 0,
        advancedNapStartCount: 0,
        advancedNapEndCount: 0,
        earlyWakeLogged: false,
        bedtimeResistance: false,
        bedtimeDelayMinutes: 0,
        createdAt: now,
      ),
    );
    if (todaySignal.dayTapCount == 0) {
      score -= 15;
    } else if (todaySignal.dayTapCount == 1) {
      score -= 8;
    }

    final unstableDays = dailySignals
        .take(5)
        .where(
          (signal) =>
              signal.earlyWakeLogged ||
              signal.bedtimeResistance ||
              (signal.shortNapCount + signal.skippedNapCount) >= 2 ||
              signal.bedtimeDelayMinutes >= 20,
        )
        .length;
    if (unstableDays >= 4) {
      score -= 20;
    } else if (unstableDays >= 2) {
      score -= 12;
    } else {
      score += 3;
    }

    if (schedule.appliedHysteresis) score += 5;

    if (score >= 78) return RhythmConfidence.high;
    if (score >= 55) return RhythmConfidence.medium;
    return RhythmConfidence.low;
  }

  RhythmShiftAssessment _computeShiftAssessment({
    required int ageMonths,
    required List<MorningRecapEntry> recapHistory,
    required List<RhythmDailySignal> dailySignals,
    required DateTime? lastRhythmUpdateAt,
    required DateTime now,
  }) {
    final base = _shiftDetector.detect(
      ageMonths: ageMonths,
      recapHistory: recapHistory,
      dailySignals: dailySignals,
      now: now,
    );
    if (!base.shouldSuggestUpdate) return base;

    if (lastRhythmUpdateAt != null &&
        now.difference(lastRhythmUpdateAt).inDays < 7 &&
        base.softPromptOnly) {
      return RhythmShiftAssessment.none;
    }
    return base;
  }

  List<RhythmDailySignal> _upsertDailySignal({
    required List<RhythmDailySignal> signals,
    required DateTime now,
    required RhythmDailySignal Function(RhythmDailySignal current) update,
  }) {
    final dateKey = _dateKey(now);
    final list = [...signals];
    final index = list.indexWhere((signal) => signal.dateKey == dateKey);
    final base = index >= 0
        ? list[index]
        : RhythmDailySignal(
            dateKey: dateKey,
            shortNapCount: 0,
            skippedNapCount: 0,
            okNapCount: 0,
            longNapCount: 0,
            advancedNapStartCount: 0,
            advancedNapEndCount: 0,
            earlyWakeLogged: false,
            bedtimeResistance: false,
            bedtimeDelayMinutes: 0,
            createdAt: now,
          );
    final next = update(base).copyWith(createdAt: now);
    if (index >= 0) {
      list[index] = next;
    } else {
      list.add(next);
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(14).toList();
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _persist(String childId) async {
    final box = await _ensureBox();
    await box.put(_keyFor(childId), {
      'rhythm': state.rhythm?.toMap(),
      'today_schedule': state.todaySchedule?.toMap(),
      'recap_history': state.recapHistory.map((e) => e.toMap()).toList(),
      'daily_signals': state.dailySignals.map((e) => e.toMap()).toList(),
      'last_rhythm_update_at': state.lastRhythmUpdateAt?.toIso8601String(),
      'advanced_day_logging': state.advancedDayLogging,
      'wake_time_minutes': state.wakeTimeMinutes,
      'wake_time_known': state.wakeTimeKnown,
      'precise_view': state.preciseView,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
