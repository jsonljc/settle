import 'package:hive_flutter/hive_flutter.dart';

import '../models/sleep_session.dart';

/// Adaptive wake window scheduler.
///
/// After 5+ logged sessions with both [wakeWindowAtStart] and
/// [sleepOnsetLatency], computes the median sleep onset latency (SOL)
/// per wake window length bucket and adjusts the recommended window.
///
/// The goal: find the wake window length that minimises SOL — the
/// "sweet spot" where baby falls asleep fastest.
///
/// All history is read from the Hive `sessions` box. The computed
/// recommendation is persisted to a small Hive box (`adaptive`) so it
/// survives app restarts.
class AdaptiveScheduler {
  static const _sessionsBoxName = 'sessions';
  static const _adaptiveBoxName = 'adaptive';
  static const _recKey = 'recommendation';
  static const _historyKey = 'analysed_count';

  /// Minimum sessions with SOL data before adaptation kicks in.
  static const int minSessions = 5;

  /// Bucket size in minutes for wake window grouping.
  static const int bucketSize = 15;

  /// Maximum adjustment from the age-bracket midpoint (±30 min).
  static const int maxAdjustment = 30;

  // ───────────────────────────────────────────
  //  Public API
  // ───────────────────────────────────────────

  /// Analyse session history and (re)compute the adaptive recommendation.
  ///
  /// Returns the recommended target wake window in minutes, or null if
  /// there isn't enough data yet.
  static Future<int?> analyse({
    required int ageMidpointMinutes,
  }) async {
    final sessionsBox = await Hive.openBox<SleepSession>(_sessionsBoxName);
    final adaptiveBox = await Hive.openBox<dynamic>(_adaptiveBoxName);

    // Collect sessions with both SOL and wake-window data
    final eligible = <_DataPoint>[];
    for (final s in sessionsBox.values) {
      if (s.wakeWindowAtStart != null &&
          s.sleepOnsetLatency != null &&
          !s.isActive) {
        eligible.add(_DataPoint(
          wakeWindow: s.wakeWindowAtStart!,
          sol: s.sleepOnsetLatency!,
        ));
      }
    }

    if (eligible.length < minSessions) {
      // Not enough data — clear any stale recommendation
      await adaptiveBox.delete(_recKey);
      await adaptiveBox.put(_historyKey, eligible.length);
      return null;
    }

    // Group into buckets
    final buckets = <int, List<int>>{}; // bucket center → SOL list
    for (final dp in eligible) {
      final bucketCenter =
          ((dp.wakeWindow / bucketSize).round() * bucketSize);
      buckets.putIfAbsent(bucketCenter, () => []).add(dp.sol);
    }

    // Compute median SOL per bucket
    final bucketMedians = <int, double>{};
    for (final entry in buckets.entries) {
      bucketMedians[entry.key] = _median(entry.value);
    }

    // Find the bucket with the lowest median SOL
    int? bestBucket;
    double bestMedian = double.infinity;
    for (final entry in bucketMedians.entries) {
      if (entry.value < bestMedian) {
        bestMedian = entry.value;
        bestBucket = entry.key;
      }
    }

    if (bestBucket == null) {
      await adaptiveBox.delete(_recKey);
      return null;
    }

    // Clamp to ± maxAdjustment from the age midpoint
    final recommendation = bestBucket.clamp(
      ageMidpointMinutes - maxAdjustment,
      ageMidpointMinutes + maxAdjustment,
    );

    // Persist
    await adaptiveBox.put(_recKey, recommendation);
    await adaptiveBox.put(_historyKey, eligible.length);

    return recommendation;
  }

  /// Read the last computed recommendation without re-analysing.
  /// Returns null if no recommendation exists.
  static Future<int?> lastRecommendation() async {
    final box = await Hive.openBox<dynamic>(_adaptiveBoxName);
    return box.get(_recKey) as int?;
  }

  /// How many sessions have been analysed so far.
  static Future<int> analysedCount() async {
    final box = await Hive.openBox<dynamic>(_adaptiveBoxName);
    return (box.get(_historyKey) as int?) ?? 0;
  }

  /// Whether the adaptive scheduler has enough data to make a
  /// recommendation (≥ [minSessions] sessions with SOL data).
  static Future<bool> get isActive async {
    return (await analysedCount()) >= minSessions;
  }

  /// Compute a human-readable insight for the settings / today screen.
  static Future<AdaptiveInsight?> insight({
    required int ageMidpointMinutes,
  }) async {
    final rec = await lastRecommendation();
    if (rec == null) {
      final count = await analysedCount();
      if (count == 0) return null;
      return AdaptiveInsight(
        hasRecommendation: false,
        sessionsAnalysed: count,
        sessionsNeeded: minSessions - count,
        recommendedMinutes: null,
        deltaFromDefault: null,
        averageSolAtOptimal: null,
      );
    }

    // Re-read the SOL data at the recommended bucket for the insight
    final sessionsBox = await Hive.openBox<SleepSession>(_sessionsBoxName);
    final nearOptimal = sessionsBox.values.where((s) =>
        s.wakeWindowAtStart != null &&
        s.sleepOnsetLatency != null &&
        !s.isActive &&
        (s.wakeWindowAtStart! - rec).abs() <= bucketSize);
    final avgSol = nearOptimal.isEmpty
        ? null
        : nearOptimal
                .map((s) => s.sleepOnsetLatency!)
                .reduce((a, b) => a + b) /
            nearOptimal.length;

    return AdaptiveInsight(
      hasRecommendation: true,
      sessionsAnalysed: await analysedCount(),
      sessionsNeeded: 0,
      recommendedMinutes: rec,
      deltaFromDefault: rec - ageMidpointMinutes,
      averageSolAtOptimal: avgSol?.round(),
    );
  }

  // ───────────────────────────────────────────
  //  Internals
  // ───────────────────────────────────────────

  static double _median(List<int> values) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid].toDouble();
    return (sorted[mid - 1] + sorted[mid]) / 2.0;
  }
}

class _DataPoint {
  const _DataPoint({required this.wakeWindow, required this.sol});
  final int wakeWindow;
  final int sol;
}

/// Human-readable insight from the adaptive scheduler.
class AdaptiveInsight {
  const AdaptiveInsight({
    required this.hasRecommendation,
    required this.sessionsAnalysed,
    required this.sessionsNeeded,
    required this.recommendedMinutes,
    required this.deltaFromDefault,
    required this.averageSolAtOptimal,
  });

  /// True if there's enough data for a recommendation.
  final bool hasRecommendation;

  /// Sessions used in the analysis.
  final int sessionsAnalysed;

  /// How many more sessions needed before adaptation activates.
  final int sessionsNeeded;

  /// The recommended wake window in minutes (null if not enough data).
  final int? recommendedMinutes;

  /// Difference from age-bracket default (positive = longer, negative = shorter).
  final int? deltaFromDefault;

  /// Average SOL in minutes at the optimal wake window length.
  final int? averageSolAtOptimal;
}
