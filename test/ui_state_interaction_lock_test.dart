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
import 'package:settle/providers/sleep_tonight_provider.dart';
import 'package:settle/screens/home.dart';
import 'package:settle/theme/glass_components.dart';
import 'package:settle/widgets/release_surfaces.dart';

void main() {
  const childId = 'ui-state-child-1';

  BabyProfile buildProfile() {
    return BabyProfile(
      name: 'Ari',
      ageBracket: AgeBracket.twoToThreeYears,
      familyStructure: FamilyStructure.twoParents,
      approach: Approach.stayAndSupport,
      primaryChallenge: PrimaryChallenge.nightWaking,
      feedingType: FeedingType.combo,
      focusMode: FocusMode.both,
      createdAt: childId,
    );
  }

  Future<void> registerHive() async {
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

  Future<void> seedRollout({
    required bool helpNowEnabled,
    required bool sleepTonightEnabled,
    required bool planProgressEnabled,
    required bool familyRulesEnabled,
  }) async {
    final box = await Hive.openBox<dynamic>('release_rollout_v1');
    await box.put('state', {
      'schema_version': 1,
      'help_now_enabled': helpNowEnabled,
      'sleep_tonight_enabled': sleepTonightEnabled,
      'plan_progress_enabled': planProgressEnabled,
      'family_rules_enabled': familyRulesEnabled,
      'metrics_dashboard_enabled': true,
      'compliance_checklist_enabled': true,
    });
  }

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('settle_ui_state_lock');
    Hive.init(dir.path);
    await registerHive();
    await seedRollout(
      helpNowEnabled: false,
      sleepTonightEnabled: false,
      planProgressEnabled: false,
      familyRulesEnabled: false,
    );
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  testWidgets('profile-required state has recovery CTA to onboarding', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/required',
      routes: [
        GoRoute(
          path: '/required',
          builder: (context, state) =>
              const ProfileRequiredView(title: 'Sleep Tonight'),
        ),
        GoRoute(
          path: '/onboard',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('ONBOARD_SCREEN'))),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Sleep Tonight'), findsOneWidget);
    expect(find.text('Continue setup'), findsOneWidget);

    await tester.tap(find.text('Continue setup'));
    await tester.pumpAndSettle();

    expect(find.text('ONBOARD_SCREEN'), findsOneWidget);
  });

  testWidgets('paused module back button falls back to shell', (tester) async {
    final router = GoRouter(
      initialLocation: '/paused',
      routes: [
        GoRoute(
          path: '/paused',
          builder: (context, state) =>
              const FeaturePausedView(title: 'Family Rules'),
        ),
        GoRoute(
          path: '/now',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('SHELL_SCREEN'))),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Family Rules'), findsOneWidget);
    expect(find.text('This section is unavailable right now.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('SHELL_SCREEN'), findsOneWidget);
  });

  testWidgets('home paused CTA is non-interactive when disabled', (
    tester,
  ) async {
    final profile = buildProfile();
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

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData.dark(
            useMaterial3: true,
          ).copyWith(scaffoldBackgroundColor: Colors.transparent),
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
    await tester.pump(const Duration(milliseconds: 900));

    final unavailable = find.text('Some sections are taking a short break.');
    expect(unavailable, findsWidgets);

    await tester.tap(unavailable.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Start here'), findsOneWidget);
  });

  testWidgets('Glass CTA and Pill ignore taps when disabled', (tester) async {
    var ctaTapped = false;
    var pillTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              GlassCta(
                label: 'Disabled CTA',
                enabled: false,
                onTap: () => ctaTapped = true,
              ),
              GlassPill(
                label: 'Disabled Pill',
                enabled: false,
                onTap: () => pillTapped = true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Disabled CTA'));
    await tester.tap(find.text('Disabled Pill'));
    await tester.pumpAndSettle();

    expect(ctaTapped, isFalse);
    expect(pillTapped, isFalse);
  });
}
