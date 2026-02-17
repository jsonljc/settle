import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/adaptive_scheduler.dart';
import 'profile_provider.dart';

/// Provides the adaptive scheduler's recommendation.
///
/// Re-analyses after each session ends (via [refresh]) and exposes
/// the recommended target wake window and insight data.
final adaptiveProvider = StateNotifierProvider<AdaptiveNotifier, AdaptiveState>(
  (ref) {
    final profile = ref.watch(profileProvider);
    final ageMidpoint = profile?.targetWakeMinutes ?? 90;
    return AdaptiveNotifier(ageMidpointMinutes: ageMidpoint);
  },
);

class AdaptiveState {
  const AdaptiveState({
    required this.recommendedMinutes,
    required this.insight,
    required this.isLoading,
  });

  /// The adaptive target wake window, or null if not enough data.
  final int? recommendedMinutes;

  /// Human-readable insight (null while loading or no data at all).
  final AdaptiveInsight? insight;

  /// True while an analysis is in progress.
  final bool isLoading;

  static const initial = AdaptiveState(
    recommendedMinutes: null,
    insight: null,
    isLoading: true,
  );
}

class AdaptiveNotifier extends StateNotifier<AdaptiveState> {
  AdaptiveNotifier({required this.ageMidpointMinutes})
    : super(AdaptiveState.initial) {
    _load();
  }

  final int ageMidpointMinutes;

  /// Load the last recommendation without re-analysing.
  Future<void> _load() async {
    final rec = await AdaptiveScheduler.lastRecommendation();
    final insight = await AdaptiveScheduler.insight(
      ageMidpointMinutes: ageMidpointMinutes,
    );
    if (!mounted) return;
    state = AdaptiveState(
      recommendedMinutes: rec,
      insight: insight,
      isLoading: false,
    );
  }

  /// Re-analyse all session history and update the recommendation.
  /// Call this after a session ends.
  Future<void> refresh() async {
    state = AdaptiveState(
      recommendedMinutes: state.recommendedMinutes,
      insight: state.insight,
      isLoading: true,
    );

    final rec = await AdaptiveScheduler.analyse(
      ageMidpointMinutes: ageMidpointMinutes,
    );
    final insight = await AdaptiveScheduler.insight(
      ageMidpointMinutes: ageMidpointMinutes,
    );
    if (!mounted) return;
    state = AdaptiveState(
      recommendedMinutes: rec,
      insight: insight,
      isLoading: false,
    );
  }
}
