import 'package:flutter_test/flutter_test.dart';
import 'package:settle/services/release_metrics_service.dart';
import 'package:settle/services/release_ops_service.dart';
import 'package:settle/services/safety_compliance_service.dart';

void main() {
  ReleaseMetricsSnapshot metrics({
    double? sleepAdoptionRate = 0.42,
    int sleepActiveDays = 6,
    double? sleepTimeToGuidanceMedianSeconds = 40,
    int sleepTimeToGuidanceSamples = 2,
    double? sleepRecapCompletionRate = 0.5,
    double? helpNowMedianSeconds = 8,
    int helpNowMedianSamples = 3,
    double? sleepStartMedianSeconds = 40,
    int sleepStartMedianSamples = 2,
    double? helpNowOutcomeRate = 0.75,
    int helpNowSessions = 4,
    int helpNowOutcomes = 3,
    double? sleepMorningReviewRate = 0.5,
    int sleepPlans = 2,
    int sleepMorningReviews = 1,
    int repeatUseActiveDays7d = 3,
    bool repeatUseMet = true,
    int familyDiffAccepted7d = 2,
    int appSessions7d = 1000,
    int appCrashes7d = 0,
    double? crashFreeRate7d = 1,
    bool crashFreeMet7d = true,
    bool coreFunnelStable7d = true,
    int windowDays = 14,
  }) {
    return ReleaseMetricsSnapshot(
      windowDays: windowDays,
      sleepAdoptionRate: sleepAdoptionRate,
      sleepActiveDays: sleepActiveDays,
      sleepTimeToGuidanceMedianSeconds: sleepTimeToGuidanceMedianSeconds,
      sleepTimeToGuidanceSamples: sleepTimeToGuidanceSamples,
      sleepRecapCompletionRate: sleepRecapCompletionRate,
      helpNowMedianSeconds: helpNowMedianSeconds,
      helpNowMedianSamples: helpNowMedianSamples,
      sleepStartMedianSeconds: sleepStartMedianSeconds,
      sleepStartMedianSamples: sleepStartMedianSamples,
      helpNowOutcomeRate: helpNowOutcomeRate,
      helpNowSessions: helpNowSessions,
      helpNowOutcomes: helpNowOutcomes,
      sleepMorningReviewRate: sleepMorningReviewRate,
      sleepPlans: sleepPlans,
      sleepMorningReviews: sleepMorningReviews,
      repeatUseActiveDays7d: repeatUseActiveDays7d,
      repeatUseMet: repeatUseMet,
      familyDiffAccepted7d: familyDiffAccepted7d,
      appSessions7d: appSessions7d,
      appCrashes7d: appCrashes7d,
      crashFreeRate7d: crashFreeRate7d,
      crashFreeMet7d: crashFreeMet7d,
      coreFunnelStable7d: coreFunnelStable7d,
    );
  }

  ComplianceChecklistSnapshot compliance({required bool allPassed}) {
    final items = [
      ComplianceChecklistItem(
        id: 'behavioral_not_medical',
        title: 'Behavioral-not-medical boundary',
        detail: 'mapped',
        passed: allPassed,
      ),
      ComplianceChecklistItem(
        id: 'red_flag_redirects',
        title: 'Red-flag redirect gate',
        detail: 'mapped',
        passed: allPassed,
      ),
      ComplianceChecklistItem(
        id: 'feeding_scope_exclusion',
        title: 'Feeding physiological exclusions',
        detail: 'mapped',
        passed: allPassed,
      ),
      ComplianceChecklistItem(
        id: 'privacy_regulatory',
        title: 'Privacy/regulatory checklist',
        detail: 'mapped',
        passed: allPassed,
      ),
    ];
    return ComplianceChecklistSnapshot(items: items, updatedAt: '2026-02-13');
  }

  ReleaseOpsService service({
    required ReleaseMetricsSnapshot metricsSnapshot,
    required ComplianceChecklistSnapshot complianceSnapshot,
  }) {
    return ReleaseOpsService(
      metricsService: _FakeMetricsService(metricsSnapshot),
      complianceService: _FakeComplianceService(complianceSnapshot),
    );
  }

  test(
    'gate runner exposes stable gate ids for required + advisory checks',
    () async {
      final snapshot = await service(
        metricsSnapshot: metrics(),
        complianceSnapshot: compliance(allPassed: true),
      ).loadSnapshot(childId: 'child-1', windowDays: 14);

      expect(snapshot.gates.map((g) => g.id).toList(), [
        'g_required_help_now_latency',
        'g_required_sleep_latency',
        'g_required_compliance',
        'g_required_crash_free_7d',
        'g_required_core_funnel_stability_7d',
        'g_advisory_help_now_completion',
        'g_advisory_sleep_review',
        'g_advisory_repeat_use',
        'g_advisory_family_sync',
      ]);
      expect(snapshot.requiredTotal, 5);
      expect(snapshot.advisoryTotal, 4);
    },
  );

  test('rollout blocks when help-now latency gate fails', () async {
    final snapshot = await service(
      metricsSnapshot: metrics(helpNowMedianSeconds: 12),
      complianceSnapshot: compliance(allPassed: true),
    ).loadSnapshot(childId: 'child-1', windowDays: 14);

    expect(snapshot.rolloutReady, isFalse);
    expect(snapshot.requiredPassCount, 4);
    expect(
      snapshot.gates
          .firstWhere((g) => g.id == 'g_required_help_now_latency')
          .passed,
      isFalse,
    );
  });

  test('rollout blocks when sleep-start latency gate fails', () async {
    final snapshot = await service(
      metricsSnapshot: metrics(sleepStartMedianSeconds: 75),
      complianceSnapshot: compliance(allPassed: true),
    ).loadSnapshot(childId: 'child-1', windowDays: 14);

    expect(snapshot.rolloutReady, isFalse);
    expect(snapshot.requiredPassCount, 4);
    expect(
      snapshot.gates
          .firstWhere((g) => g.id == 'g_required_sleep_latency')
          .passed,
      isFalse,
    );
  });

  test('rollout blocks when compliance gate fails', () async {
    final snapshot = await service(
      metricsSnapshot: metrics(),
      complianceSnapshot: compliance(allPassed: false),
    ).loadSnapshot(childId: 'child-1', windowDays: 14);

    expect(snapshot.rolloutReady, isFalse);
    expect(snapshot.requiredPassCount, 4);
    expect(
      snapshot.gates.firstWhere((g) => g.id == 'g_required_compliance').passed,
      isFalse,
    );
  });

  test('rollout blocks when crash-free gate fails', () async {
    final snapshot = await service(
      metricsSnapshot: metrics(
        appSessions7d: 1000,
        appCrashes7d: 10,
        crashFreeRate7d: 0.99,
        crashFreeMet7d: false,
      ),
      complianceSnapshot: compliance(allPassed: true),
    ).loadSnapshot(childId: 'child-1', windowDays: 14);

    expect(snapshot.rolloutReady, isFalse);
    expect(snapshot.requiredPassCount, 4);
    expect(
      snapshot.gates
          .firstWhere((g) => g.id == 'g_required_crash_free_7d')
          .passed,
      isFalse,
    );
  });

  test('rollout blocks when core funnel stability gate fails', () async {
    final snapshot = await service(
      metricsSnapshot: metrics(coreFunnelStable7d: false),
      complianceSnapshot: compliance(allPassed: true),
    ).loadSnapshot(childId: 'child-1', windowDays: 14);

    expect(snapshot.rolloutReady, isFalse);
    expect(snapshot.requiredPassCount, 4);
    expect(
      snapshot.gates
          .firstWhere((g) => g.id == 'g_required_core_funnel_stability_7d')
          .passed,
      isFalse,
    );
  });

  test(
    'advisory gate failures do not block rollout when required gates pass',
    () async {
      final snapshot = await service(
        metricsSnapshot: metrics(
          helpNowOutcomeRate: null,
          helpNowSessions: 0,
          helpNowOutcomes: 0,
          sleepMorningReviewRate: null,
          sleepPlans: 0,
          sleepMorningReviews: 0,
          repeatUseActiveDays7d: 0,
          repeatUseMet: false,
          familyDiffAccepted7d: 0,
        ),
        complianceSnapshot: compliance(allPassed: true),
      ).loadSnapshot(childId: 'child-1', windowDays: 14);

      expect(snapshot.requiredPassCount, snapshot.requiredTotal);
      expect(snapshot.rolloutReady, isTrue);
      expect(snapshot.advisoryPassCount, 0);
    },
  );
}

class _FakeMetricsService extends ReleaseMetricsService {
  const _FakeMetricsService(this.snapshot);

  final ReleaseMetricsSnapshot snapshot;

  @override
  Future<ReleaseMetricsSnapshot> loadSnapshot({
    String? childId,
    int windowDays = 14,
  }) async {
    return snapshot;
  }
}

class _FakeComplianceService extends SafetyComplianceService {
  const _FakeComplianceService(this.snapshot);

  final ComplianceChecklistSnapshot snapshot;

  @override
  Future<ComplianceChecklistSnapshot> loadChecklist() async {
    return snapshot;
  }
}
