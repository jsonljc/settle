import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settle/models/approach.dart';
import 'package:settle/models/baby_profile.dart';
import 'package:settle/models/day_plan.dart';
import 'package:settle/models/night_wake.dart';
import 'package:settle/models/sleep_session.dart';
import 'package:settle/models/tantrum_profile.dart';
import 'package:settle/providers/family_rules_provider.dart';
import 'package:settle/providers/release_rollout_provider.dart';
import 'package:settle/providers/sleep_tonight_provider.dart';
import 'package:settle/providers/tantrum_providers.dart';
import 'package:settle/screens/home.dart';
import 'package:settle/screens/sleep_tonight.dart';
import 'package:settle/screens/tantrum/tantrum_hub.dart';

class _StaticRolloutNotifier extends StateNotifier<ReleaseRolloutState>
    implements ReleaseRolloutNotifier {
  _StaticRolloutNotifier(super.state);

  @override
  Future<void> setHelpNowEnabled(bool value) async {
    state = state.copyWith(helpNowEnabled: value);
  }

  @override
  Future<void> setSleepTonightEnabled(bool value) async {
    state = state.copyWith(sleepTonightEnabled: value);
  }

  @override
  Future<void> setPlanProgressEnabled(bool value) async {
    state = state.copyWith(planProgressEnabled: value);
  }

  @override
  Future<void> setFamilyRulesEnabled(bool value) async {
    state = state.copyWith(familyRulesEnabled: value);
  }

  @override
  Future<void> setMetricsDashboardEnabled(bool value) async {
    state = state.copyWith(metricsDashboardEnabled: value);
  }

  @override
  Future<void> setComplianceChecklistEnabled(bool value) async {
    state = state.copyWith(complianceChecklistEnabled: value);
  }

  @override
  Future<void> setSleepBoundedAiEnabled(bool value) async {
    state = state.copyWith(sleepBoundedAiEnabled: value);
  }

  @override
  Future<void> setSleepRhythmSurfacesEnabled(bool value) async {
    state = state.copyWith(sleepRhythmSurfacesEnabled: value);
  }

  @override
  Future<void> setRhythmShiftDetectorPromptsEnabled(bool value) async {
    state = state.copyWith(rhythmShiftDetectorPromptsEnabled: value);
  }

  @override
  Future<void> setWindDownNotificationsEnabled(bool value) async {
    state = state.copyWith(windDownNotificationsEnabled: value);
  }

  @override
  Future<void> setScheduleDriftNotificationsEnabled(bool value) async {
    state = state.copyWith(scheduleDriftNotificationsEnabled: value);
  }

  @override
  Future<void> setPlanTabEnabled(bool value) async {
    state = state.copyWith(planTabEnabled: value);
  }

  @override
  Future<void> setFamilyTabEnabled(bool value) async {
    state = state.copyWith(familyTabEnabled: value);
  }

  @override
  Future<void> setLibraryTabEnabled(bool value) async {
    state = state.copyWith(libraryTabEnabled: value);
  }

  @override
  Future<void> setPocketEnabled(bool value) async {
    state = state.copyWith(pocketEnabled: value);
  }

  @override
  Future<void> setRegulateEnabled(bool value) async {
    state = state.copyWith(regulateEnabled: value);
  }

  @override
  Future<void> setSmartNudgesEnabled(bool value) async {
    state = state.copyWith(smartNudgesEnabled: value);
  }

  @override
  Future<void> setPatternDetectionEnabled(bool value) async {
    state = state.copyWith(patternDetectionEnabled: value);
  }

  @override
  Future<void> setUiV3Enabled(bool value) async {
    state = state.copyWith(uiV3Enabled: value);
  }
}

void main() {
  Future<void> registerHiveAdapters() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive
        ..registerAdapter(ApproachAdapter())
        ..registerAdapter(AgeBracketAdapter())
        ..registerAdapter(FamilyStructureAdapter())
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
  }

  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync(
      'settle_nav_label_contract',
    );
    Hive.init(dir.path);
    await registerHiveAdapters();
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  final profile = BabyProfile(
    name: 'Ari',
    ageBracket: AgeBracket.twoToThreeYears,
    familyStructure: FamilyStructure.twoParents,
    approach: Approach.stayAndSupport,
    primaryChallenge: PrimaryChallenge.nightWaking,
    feedingType: FeedingType.combo,
    focusMode: FocusMode.both,
    createdAt: 'child-label-contract',
  );

  const sleepState = SleepTonightState(
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

  const rulesState = FamilyRulesState(
    isLoading: false,
    rulesetVersion: 1,
    rules: {
      'boundary_public': 'One script.',
      'screens_default': 'No screens before breakfast.',
      'snacks_default': 'Snack windows only.',
      'bedtime_routine': 'Bath, books, bed.',
    },
    pendingDiffs: [],
    changeFeed: [],
    error: null,
  );

  testWidgets('Home uses calm primary + collapsed secondary labels', (
    tester,
  ) async {
    setPhoneViewport(tester);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: HomeScreen(
            now: () => DateTime(2026, 2, 13, 14),
            profileOverride: profile,
            sleepStateOverride: sleepState,
            rulesStateOverride: rulesState,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Start here'), findsOneWidget);
    expect(find.text('Help with what\'s happening'), findsWidgets);
    expect(find.text('More actions'), findsOneWidget);

    await tester.tap(find.text('More actions'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Rules'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    expect(find.text('Help Now'), findsNothing);
    expect(find.text('Plan & Progress'), findsNothing);
    expect(find.text('Family Rules'), findsNothing);
    expect(find.text('Now'), findsNothing);
    expect(find.text('Now: Sleep Tonight'), findsNothing);
  });

  testWidgets('Sleep paused fallback uses Now mode label', (tester) async {
    setPhoneViewport(tester);

    const rolloutState = ReleaseRolloutState(
      isLoading: false,
      helpNowEnabled: true,
      sleepTonightEnabled: false,
      planProgressEnabled: true,
      familyRulesEnabled: true,
      metricsDashboardEnabled: true,
      complianceChecklistEnabled: true,
      sleepBoundedAiEnabled: true,
      sleepRhythmSurfacesEnabled: true,
      rhythmShiftDetectorPromptsEnabled: true,
      windDownNotificationsEnabled: true,
      scheduleDriftNotificationsEnabled: false,
    );

    final router = GoRouter(
      initialLocation: '/sleep-tonight',
      routes: [
        GoRoute(
          path: '/sleep-tonight',
          builder: (context, state) => const SleepTonightScreen(),
        ),
        GoRoute(
          path: '/now',
          builder: (context, state) {
            final mode = state.uri.queryParameters['mode'] ?? 'incident';
            return Scaffold(body: Center(child: Text('NOW_MODE_$mode')));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          releaseRolloutProvider.overrideWith(
            (ref) => _StaticRolloutNotifier(rolloutState),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Open Now: Incident'), findsOneWidget);
  });

  test('Reset mode uses calm label', () {
    final source = File('lib/screens/sos.dart').readAsStringSync();
    expect(source.contains("Text('Take a Breath'"), isTrue);
    expect(source.contains('Mode: Reset'), isFalse);
  });

  testWidgets('Legacy tantrum hub label maps to Now: Incident', (tester) async {
    setPhoneViewport(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hasTantrumFeatureProvider.overrideWith((ref) => false)],
        child: const MaterialApp(home: TantrumHubScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Now: Incident'), findsOneWidget);
    expect(find.text('Overwhelm support'), findsNothing);
  });
}
