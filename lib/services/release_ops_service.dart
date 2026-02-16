import 'release_metrics_service.dart';
import 'safety_compliance_service.dart';

class ReleaseOpsGate {
  const ReleaseOpsGate({
    required this.id,
    required this.title,
    required this.detail,
    required this.required,
    required this.passed,
  });

  final String id;
  final String title;
  final String detail;
  final bool required;
  final bool passed;
}

class ReleaseOpsSnapshot {
  const ReleaseOpsSnapshot({
    required this.generatedAtIso,
    required this.rolloutReady,
    required this.requiredPassCount,
    required this.requiredTotal,
    required this.advisoryPassCount,
    required this.advisoryTotal,
    required this.gates,
  });

  final String generatedAtIso;
  final bool rolloutReady;
  final int requiredPassCount;
  final int requiredTotal;
  final int advisoryPassCount;
  final int advisoryTotal;
  final List<ReleaseOpsGate> gates;

  List<ReleaseOpsGate> get requiredGates =>
      gates.where((g) => g.required).toList(growable: false);

  List<ReleaseOpsGate> get advisoryGates =>
      gates.where((g) => !g.required).toList(growable: false);
}

class ReleaseOpsService {
  const ReleaseOpsService({
    this.metricsService = const ReleaseMetricsService(),
    this.complianceService = const SafetyComplianceService(),
  });

  final ReleaseMetricsService metricsService;
  final SafetyComplianceService complianceService;

  Future<ReleaseOpsSnapshot> loadSnapshot({
    String? childId,
    int windowDays = 14,
  }) async {
    final metrics = await metricsService.loadSnapshot(
      childId: childId,
      windowDays: windowDays,
    );
    final compliance = await complianceService.loadChecklist();
    final compliancePass = compliance.items.every((item) => item.passed);

    final gates = <ReleaseOpsGate>[
      ReleaseOpsGate(
        id: 'g_required_help_now_latency',
        title: 'Help Now latency target',
        detail:
            'Median ${_secs(metrics.helpNowMedianSeconds)} (target <10s, n=${metrics.helpNowMedianSamples}).',
        required: true,
        passed:
            metrics.helpNowMedianSeconds != null &&
            metrics.helpNowMedianSeconds! < 10,
      ),
      ReleaseOpsGate(
        id: 'g_required_sleep_latency',
        title: 'Sleep Tonight start target',
        detail:
            'Median ${_secs(metrics.sleepStartMedianSeconds)} (target <60s, n=${metrics.sleepStartMedianSamples}).',
        required: true,
        passed:
            metrics.sleepStartMedianSeconds != null &&
            metrics.sleepStartMedianSeconds! < 60,
      ),
      ReleaseOpsGate(
        id: 'g_required_compliance',
        title: 'Safety & compliance controls',
        detail:
            '${compliance.items.where((i) => i.passed).length}/${compliance.items.length} controls mapped.',
        required: true,
        passed: compliancePass,
      ),
      ReleaseOpsGate(
        id: 'g_required_crash_free_7d',
        title: 'Crash-free stability (7d)',
        detail:
            '${_pct(metrics.crashFreeRate7d)} crash-free from ${metrics.appSessions7d} session(s), ${metrics.appCrashes7d} crash event(s).',
        required: true,
        passed: metrics.crashFreeMet7d,
      ),
      ReleaseOpsGate(
        id: 'g_required_core_funnel_stability_7d',
        title: 'Core funnel stability (7d)',
        detail: metrics.coreFunnelStable7d
            ? 'Latency and recap gates remained stable with repeat use in the last 7 days.'
            : 'Core funnel metrics are not yet stable across the last 7 days.',
        required: true,
        passed: metrics.coreFunnelStable7d,
      ),
      ReleaseOpsGate(
        id: 'g_advisory_help_now_completion',
        title: 'Help Now outcome logging',
        detail:
            '${metrics.helpNowOutcomes}/${metrics.helpNowSessions} sessions with outcomes in ${metrics.windowDays}d.',
        required: false,
        passed:
            metrics.helpNowSessions > 0 &&
            metrics.helpNowOutcomes > 0 &&
            metrics.helpNowOutcomeRate != null,
      ),
      ReleaseOpsGate(
        id: 'g_advisory_sleep_review',
        title: 'Sleep morning review signal',
        detail:
            '${metrics.sleepMorningReviews}/${metrics.sleepPlans} nights with morning review.',
        required: false,
        passed:
            metrics.sleepPlans > 0 &&
            metrics.sleepMorningReviews > 0 &&
            metrics.sleepMorningReviewRate != null,
      ),
      ReleaseOpsGate(
        id: 'g_advisory_repeat_use',
        title: '7-day repeat use signal',
        detail:
            '${metrics.repeatUseActiveDays7d} active day(s) with Help Now or Sleep Tonight.',
        required: false,
        passed: metrics.repeatUseMet,
      ),
      ReleaseOpsGate(
        id: 'g_advisory_family_sync',
        title: 'Family sync signal',
        detail:
            '${metrics.familyDiffAccepted7d} accepted Family Rules diff(s) in 7d.',
        required: false,
        passed: metrics.familyDiffAccepted7d > 0,
      ),
    ];

    final requiredGates = gates
        .where((g) => g.required)
        .toList(growable: false);
    final advisoryGates = gates
        .where((g) => !g.required)
        .toList(growable: false);
    final requiredPassCount = requiredGates.where((g) => g.passed).length;
    final advisoryPassCount = advisoryGates.where((g) => g.passed).length;

    return ReleaseOpsSnapshot(
      generatedAtIso: DateTime.now().toIso8601String(),
      rolloutReady: requiredPassCount == requiredGates.length,
      requiredPassCount: requiredPassCount,
      requiredTotal: requiredGates.length,
      advisoryPassCount: advisoryPassCount,
      advisoryTotal: advisoryGates.length,
      gates: gates,
    );
  }

  static String _secs(double? value) {
    if (value == null) return '—';
    return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}s';
  }

  static String _pct(double? value) {
    if (value == null) return '—';
    return '${(value * 100).toStringAsFixed(1)}%';
  }
}
