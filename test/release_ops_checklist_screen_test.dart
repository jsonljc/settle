import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settle/models/approach.dart';
import 'package:settle/models/baby_profile.dart';
import 'package:settle/models/day_plan.dart';
import 'package:settle/models/night_wake.dart';
import 'package:settle/models/sleep_session.dart';
import 'package:settle/models/tantrum_profile.dart';
import 'package:settle/providers/release_rollout_provider.dart';
import 'package:settle/screens/release_ops_checklist.dart';
import 'package:settle/services/release_ops_service.dart';

class _StaticRolloutNotifier extends StateNotifier<ReleaseRolloutState>
    implements ReleaseRolloutNotifier {
  _StaticRolloutNotifier(super.state);

  Future<void> _set(ReleaseRolloutState next) async {
    state = next;
  }

  @override
  Future<void> setHelpNowEnabled(bool value) async {
    await _set(state.copyWith(helpNowEnabled: value));
  }

  @override
  Future<void> setSleepTonightEnabled(bool value) async {
    await _set(state.copyWith(sleepTonightEnabled: value));
  }

  @override
  Future<void> setPlanProgressEnabled(bool value) async {
    await _set(state.copyWith(planProgressEnabled: value));
  }

  @override
  Future<void> setFamilyRulesEnabled(bool value) async {
    await _set(state.copyWith(familyRulesEnabled: value));
  }

  @override
  Future<void> setMetricsDashboardEnabled(bool value) async {
    await _set(state.copyWith(metricsDashboardEnabled: value));
  }

  @override
  Future<void> setComplianceChecklistEnabled(bool value) async {
    await _set(state.copyWith(complianceChecklistEnabled: value));
  }

  @override
  Future<void> setSleepBoundedAiEnabled(bool value) async {
    await _set(state.copyWith(sleepBoundedAiEnabled: value));
  }

  @override
  Future<void> setSleepRhythmSurfacesEnabled(bool value) async {
    await _set(state.copyWith(sleepRhythmSurfacesEnabled: value));
  }

  @override
  Future<void> setRhythmShiftDetectorPromptsEnabled(bool value) async {
    await _set(state.copyWith(rhythmShiftDetectorPromptsEnabled: value));
  }

  @override
  Future<void> setWindDownNotificationsEnabled(bool value) async {
    await _set(state.copyWith(windDownNotificationsEnabled: value));
  }

  @override
  Future<void> setScheduleDriftNotificationsEnabled(bool value) async {
    await _set(state.copyWith(scheduleDriftNotificationsEnabled: value));
  }

  @override
  Future<void> setPlanTabEnabled(bool value) async {
    await _set(state.copyWith(planTabEnabled: value));
  }

  @override
  Future<void> setFamilyTabEnabled(bool value) async {
    await _set(state.copyWith(familyTabEnabled: value));
  }

  @override
  Future<void> setLibraryTabEnabled(bool value) async {
    await _set(state.copyWith(libraryTabEnabled: value));
  }

  @override
  Future<void> setPocketEnabled(bool value) async {
    await _set(state.copyWith(pocketEnabled: value));
  }

  @override
  Future<void> setRegulateEnabled(bool value) async {
    await _set(state.copyWith(regulateEnabled: value));
  }

  @override
  Future<void> setSmartNudgesEnabled(bool value) async {
    await _set(state.copyWith(smartNudgesEnabled: value));
  }

  @override
  Future<void> setPatternDetectionEnabled(bool value) async {
    await _set(state.copyWith(patternDetectionEnabled: value));
  }

  @override
  Future<void> setUiV3Enabled(bool value) async {
    await _set(state.copyWith(uiV3Enabled: value));
  }
}

class _FakeReleaseOpsService extends ReleaseOpsService {
  const _FakeReleaseOpsService({required this.snapshot});

  final ReleaseOpsSnapshot snapshot;

  @override
  Future<ReleaseOpsSnapshot> loadSnapshot({
    String? childId,
    int windowDays = 14,
  }) async {
    return snapshot;
  }
}

const _snapshotNotReady = ReleaseOpsSnapshot(
  generatedAtIso: '2026-02-16T00:00:00.000Z',
  rolloutReady: false,
  requiredPassCount: 3,
  requiredTotal: 5,
  advisoryPassCount: 1,
  advisoryTotal: 4,
  gates: [
    ReleaseOpsGate(
      id: 'required_1',
      title: 'Required gate one',
      detail: 'Simulated required gate',
      required: true,
      passed: true,
    ),
    ReleaseOpsGate(
      id: 'required_2',
      title: 'Required gate two',
      detail: 'Simulated required gate',
      required: true,
      passed: false,
    ),
    ReleaseOpsGate(
      id: 'advisory_1',
      title: 'Advisory gate one',
      detail: 'Simulated advisory gate',
      required: false,
      passed: true,
    ),
  ],
);

Future<void> _waitForChecklistLoad(WidgetTester tester) async {
  for (var i = 0; i < 60; i++) {
    if (find.text('Quick controls').evaluate().isNotEmpty) return;
    if (find.text('Unable to load release checklist.').evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('settle_release_ops_ui');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive
        ..registerAdapter(ApproachAdapter())
        ..registerAdapter(AgeBracketAdapter())
        ..registerAdapter(FamilyStructureAdapter())
        ..registerAdapter(RegulationLevelAdapter())
        ..registerAdapter(PrimaryChallengeAdapter())
        ..registerAdapter(FeedingTypeAdapter())
        ..registerAdapter(FocusModeAdapter())
        ..registerAdapter(TantrumTypeAdapter())
        ..registerAdapter(TriggerTypeAdapter())
        ..registerAdapter(ParentPatternAdapter())
        ..registerAdapter(ResponsePriorityAdapter())
        ..registerAdapter(TantrumIntensityAdapter())
        ..registerAdapter(PatternTrendAdapter())
        ..registerAdapter(NormalizationStatusAdapter())
        ..registerAdapter(DayBucketAdapter())
        ..registerAdapter(BabyProfileAdapter())
        ..registerAdapter(TantrumProfileAdapter())
        ..registerAdapter(TantrumEventAdapter())
        ..registerAdapter(WeeklyTantrumPatternAdapter())
        ..registerAdapter(SleepSessionAdapter())
        ..registerAdapter(NightWakeAdapter())
        ..registerAdapter(DayPlanAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  Future<void> pumpOps(
    WidgetTester tester,
    _StaticRolloutNotifier rollout,
    _FakeReleaseOpsService service,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [releaseRolloutProvider.overrideWith((ref) => rollout)],
        child: MaterialApp(home: ReleaseOpsChecklistScreen(service: service)),
      ),
    );
    await tester.pump();
    await _waitForChecklistLoad(tester);
    expect(
      find.text('Unable to load release checklist.'),
      findsNothing,
      reason: 'Release ops checklist should load in widget tests.',
    );
  }

  testWidgets('shows Phase 1 controls and dependency copy', (tester) async {
    final rollout = _StaticRolloutNotifier(
      const ReleaseRolloutState(
        isLoading: false,
        helpNowEnabled: true,
        sleepTonightEnabled: true,
        planProgressEnabled: true,
        familyRulesEnabled: true,
        metricsDashboardEnabled: true,
        complianceChecklistEnabled: true,
        sleepBoundedAiEnabled: true,
        sleepRhythmSurfacesEnabled: true,
        rhythmShiftDetectorPromptsEnabled: true,
        windDownNotificationsEnabled: true,
        scheduleDriftNotificationsEnabled: false,
        planTabEnabled: false,
        familyTabEnabled: false,
        libraryTabEnabled: false,
        pocketEnabled: false,
        regulateEnabled: false,
        smartNudgesEnabled: false,
        patternDetectionEnabled: false,
      ),
    );
    const service = _FakeReleaseOpsService(snapshot: _snapshotNotReady);

    await pumpOps(tester, rollout, service);

    expect(find.text('Phase 1 controls'), findsOneWidget);
    expect(find.text('Plan tab'), findsOneWidget);
    expect(find.text('Family tab'), findsOneWidget);
    expect(find.text('Library tab'), findsOneWidget);
    expect(find.text('Regulate route'), findsOneWidget);
  });
}
