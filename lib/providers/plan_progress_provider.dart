import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/event_bus_service.dart';

const _planProgressBox = 'plan_progress_v1';

class PlanProgressState {
  const PlanProgressState({
    required this.isLoading,
    required this.bottleneck,
    required this.experiment,
    required this.evidence,
    required this.rhythm,
    required this.insightEligible,
  });

  final bool isLoading;
  final String? bottleneck;
  final String? experiment;
  final String? evidence;
  final Map<String, String> rhythm;
  final bool insightEligible;

  static const initial = PlanProgressState(
    isLoading: true,
    bottleneck: null,
    experiment: null,
    evidence: null,
    rhythm: {
      'wake': '',
      'nap': '',
      'meals': '',
      'milk': '',
      'bedtime_routine': '',
    },
    insightEligible: false,
  );

  PlanProgressState copyWith({
    bool? isLoading,
    Object? bottleneck = _noValue,
    Object? experiment = _noValue,
    Object? evidence = _noValue,
    Map<String, String>? rhythm,
    bool? insightEligible,
  }) {
    return PlanProgressState(
      isLoading: isLoading ?? this.isLoading,
      bottleneck: identical(bottleneck, _noValue)
          ? this.bottleneck
          : bottleneck as String?,
      experiment: identical(experiment, _noValue)
          ? this.experiment
          : experiment as String?,
      evidence: identical(evidence, _noValue)
          ? this.evidence
          : evidence as String?,
      rhythm: rhythm ?? this.rhythm,
      insightEligible: insightEligible ?? this.insightEligible,
    );
  }
}

const _noValue = Object();

final planProgressProvider =
    StateNotifierProvider<PlanProgressNotifier, PlanProgressState>((ref) {
      return PlanProgressNotifier();
    });

class PlanProgressNotifier extends StateNotifier<PlanProgressState> {
  PlanProgressNotifier() : super(PlanProgressState.initial);

  Box<dynamic>? _box;

  Future<Box<dynamic>> _ensureBox() async {
    _box ??= await Hive.openBox<dynamic>(_planProgressBox);
    return _box!;
  }

  String _keyFor(String childId) => 'plan_progress:$childId';

  Future<void> load({required String childId}) async {
    state = state.copyWith(isLoading: true);
    final box = await _ensureBox();
    final raw = box.get(_keyFor(childId));
    final isEligible = await EventBusService.isInsightEligible(
      childId: childId,
    );

    if (raw is Map) {
      state = state.copyWith(
        isLoading: false,
        bottleneck: raw['bottleneck'] as String?,
        experiment: raw['experiment'] as String?,
        evidence: raw['evidence'] as String?,
        rhythm:
            (raw['rhythm'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ) ??
            state.rhythm,
        insightEligible: isEligible,
      );
    } else {
      state = state.copyWith(isLoading: false, insightEligible: isEligible);
    }
  }

  Future<void> _persist(String childId) async {
    final box = await _ensureBox();
    await box.put(_keyFor(childId), {
      'bottleneck': state.bottleneck,
      'experiment': state.experiment,
      'evidence': state.evidence,
      'rhythm': state.rhythm,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> setBottleneck({
    required String childId,
    required String bottleneck,
    required String evidence,
  }) async {
    state = state.copyWith(bottleneck: bottleneck, evidence: evidence);
    await _persist(childId);
  }

  Future<void> setExperiment({
    required String childId,
    required String experiment,
  }) async {
    state = state.copyWith(experiment: experiment);
    await _persist(childId);

    await EventBusService.emitPlanExperimentSet(
      childId: childId,
      experiment: experiment,
    );
  }

  Future<void> completeExperiment({
    required String childId,
    required String experiment,
  }) async {
    await EventBusService.emitPlanExperimentCompleted(
      childId: childId,
      experiment: experiment,
      outcome: EventOutcomes.improved,
    );
  }

  Future<void> updateRhythmBlock({
    required String childId,
    required String block,
    required String value,
  }) async {
    final nextRhythm = {...state.rhythm, block: value};
    state = state.copyWith(rhythm: nextRhythm);
    await _persist(childId);

    await EventBusService.emitPlanRhythmUpdated(childId: childId, block: block);
  }
}
