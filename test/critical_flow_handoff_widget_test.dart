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
import 'package:settle/screens/help_now.dart';
import 'package:settle/screens/home.dart';
import 'package:settle/services/spec_policy.dart';

void main() {
  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1440, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  final profile = BabyProfile(
    name: 'Ari',
    ageBracket: AgeBracket.twoToThreeYears,
    familyStructure: FamilyStructure.twoParents,
    approach: Approach.stayAndSupport,
    primaryChallenge: PrimaryChallenge.nightWaking,
    feedingType: FeedingType.combo,
    focusMode: FocusMode.both,
    createdAt: 'child-1',
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

  const inactiveSleepState = SleepTonightState(
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

  const activeSleepState = SleepTonightState(
    isLoading: false,
    activePlan: {'is_active': true},
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

  Widget nowModeMarker(BuildContext context, GoRouterState state) {
    final mode =
        state.uri.queryParameters[SpecPolicy.nowModeParam] ??
        SpecPolicy.nowModeIncident;
    return Scaffold(body: Center(child: Text('NOW_MODE_$mode')));
  }

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('settle_critical_flow');
    Hive.init(dir.path);
    await registerHiveAdapters();
  });

  tearDownAll(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  testWidgets('Help Now nighttime flow shows choice modal', (tester) async {
    setPhoneViewport(tester);

    final router = GoRouter(
      initialLocation: '/help',
      routes: [
        GoRoute(
          path: '/help',
          builder: (context, state) =>
              HelpNowScreen(now: () => DateTime(2026, 2, 13, 21)),
        ),
        GoRoute(path: '/now', builder: nowModeMarker),
        GoRoute(
          path: '/sleep/tonight',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('SLEEP_TAB'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    // Modal should appear with two choices
    expect(find.text('It\'s nighttime'), findsOneWidget);
    expect(find.text('Sleep support'), findsOneWidget);
    expect(find.text('Crisis help \u2014 stay here'), findsOneWidget);

    // Tap sleep support to route
    await tester.tap(find.text('Sleep support'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('SLEEP_TAB'), findsOneWidget);
  });

  testWidgets('Help Now sleep incident routes to Sleep tab during day', (
    tester,
  ) async {
    setPhoneViewport(tester);

    final router = GoRouter(
      initialLocation: '/help',
      routes: [
        GoRoute(
          path: '/help',
          builder: (context, state) =>
              HelpNowScreen(now: () => DateTime(2026, 2, 13, 14)),
        ),
        GoRoute(path: '/now', builder: nowModeMarker),
        GoRoute(
          path: '/sleep/tonight',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('SLEEP_TAB'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pump();

    final moreSituations = find.text('More situations');
    await tester.ensureVisible(moreSituations);
    await tester.tap(moreSituations);
    await tester.pumpAndSettle();

    final bedtimeProtest = find.text('Bedtime protest');
    await tester.ensureVisible(bedtimeProtest);
    await tester.tap(bedtimeProtest);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('SLEEP_TAB'), findsOneWidget);
  });

  testWidgets('Help Now reaches output flow in two taps when age is unknown', (
    tester,
  ) async {
    setPhoneViewport(tester);

    final router = GoRouter(
      initialLocation: '/help',
      routes: [
        GoRoute(
          path: '/help',
          builder: (context, state) =>
              HelpNowScreen(now: () => DateTime(2026, 2, 13, 14)),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pump();

    final screaming = find.text('Crying / loud upset');
    await tester.ensureVisible(screaming);
    await tester.tap(screaming);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Child age'), findsOneWidget);

    final ageBand = find.text('3-5');
    await tester.ensureVisible(ageBand);
    await tester.tap(ageBand);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Guided Beats: first beat is "Say this" with advance CTA
    expect(find.text('Say this'), findsOneWidget);
    expect(find.text('I said it →'), findsOneWidget);
    // "Do this" appears only after advancing
    expect(find.text('Do this'), findsNothing);

    await tester.tap(find.text('I said it →'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Do this'), findsOneWidget);
    expect(find.text('Done →'), findsOneWidget);
  });

  testWidgets(
    'Home shows Continue tonight\'s plan when an active plan exists',
    (tester) async {
      setPhoneViewport(tester);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: HomeScreen(
              now: () => DateTime(2026, 2, 13, 14),
              profileOverride: profile,
              sleepStateOverride: activeSleepState,
              rulesStateOverride: rulesState,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('More actions'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Continue tonight\'s plan'), findsOneWidget);
    },
  );

  testWidgets('Home night primary CTA routes to Help Now', (tester) async {
    setPhoneViewport(tester);

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => HomeScreen(
            now: () => DateTime(2026, 2, 13, 21),
            profileOverride: profile,
            sleepStateOverride: inactiveSleepState,
            rulesStateOverride: rulesState,
          ),
        ),
        GoRoute(
          path: '/now',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('HELP_NOW_SCREEN'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pump();

    await tester.tap(find.text('Help with what\'s happening').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('HELP_NOW_SCREEN'), findsOneWidget);
  });

  testWidgets('Home day primary CTA routes to Help Now when no plan', (
    tester,
  ) async {
    setPhoneViewport(tester);

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => HomeScreen(
            now: () => DateTime(2026, 2, 13, 14),
            profileOverride: profile,
            sleepStateOverride: inactiveSleepState,
            rulesStateOverride: rulesState,
          ),
        ),
        GoRoute(
          path: '/now',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('HELP_NOW_SCREEN'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pump();

    await tester.tap(find.text('Help with what\'s happening').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('HELP_NOW_SCREEN'), findsOneWidget);
  });

  testWidgets('Home day active plan primary CTA routes to Help Now', (
    tester,
  ) async {
    setPhoneViewport(tester);

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => HomeScreen(
            now: () => DateTime(2026, 2, 13, 14),
            profileOverride: profile,
            sleepStateOverride: activeSleepState,
            rulesStateOverride: rulesState,
          ),
        ),
        GoRoute(
          path: '/now',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('HELP_NOW_SCREEN'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pump();

    await tester.tap(find.text('Help with what\'s happening').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('HELP_NOW_SCREEN'), findsOneWidget);
  });
}
