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
import 'package:settle/screens/settings.dart';

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

  final profile = BabyProfile(
    name: 'Ari',
    ageBracket: AgeBracket.twoToThreeYears,
    familyStructure: FamilyStructure.twoParents,
    approach: Approach.stayAndSupport,
    primaryChallenge: PrimaryChallenge.nightWaking,
    feedingType: FeedingType.combo,
    focusMode: FocusMode.both,
    createdAt: 'child-nav-flow-1',
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

  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('settle_nav_cta');
    Hive.init(dir.path);
    await registerHiveAdapters();
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  Future<void> tapLabel(WidgetTester tester, String text) async {
    final all = find.text(text);
    if (all.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        all,
        280,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 20,
      );
    }
    final target = all.last;
    await tester.ensureVisible(target);
    await tester.tap(target);
  }

  Future<void> expandMoreActionsIfNeeded(
    WidgetTester tester, {
    required String targetLabel,
  }) async {
    if (find.text(targetLabel).evaluate().isNotEmpty) return;
    await tapLabel(tester, 'More actions');
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Home primary and secondary actions navigate to expected screens',
    (tester) async {
      setPhoneViewport(tester);

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => HomeScreen(
              now: () => DateTime(2026, 2, 13, 14),
              profileOverride: profile,
              sleepStateOverride: sleepState,
              rulesStateOverride: rulesState,
            ),
          ),
          GoRoute(
            path: '/now',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('NOW_ROUTE'))),
          ),
          GoRoute(
            path: '/sleep',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('SLEEP_ROUTE'))),
          ),
          GoRoute(
            path: '/breathe',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('BREATHE_ROUTE'))),
          ),
          GoRoute(
            path: '/plan',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('PLAN_ROUTE'))),
          ),
          GoRoute(
            path: '/rules',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('RULES_ROUTE'))),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('SETTINGS_ROUTE'))),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pump();

      await tapLabel(tester, 'Help with what\'s happening');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('NOW_ROUTE'), findsOneWidget);

      router.go('/home');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await expandMoreActionsIfNeeded(tester, targetLabel: 'Take a breath');
      await tapLabel(tester, 'Take a breath');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('BREATHE_ROUTE'), findsOneWidget);

      router.go('/home');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await expandMoreActionsIfNeeded(
        tester,
        targetLabel: 'Continue tonight\'s plan',
      );
      await tapLabel(tester, 'Continue tonight\'s plan');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('SLEEP_ROUTE'), findsOneWidget);

      router.go('/home');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await expandMoreActionsIfNeeded(tester, targetLabel: 'Plan');
      await tapLabel(tester, 'Plan');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('PLAN_ROUTE'), findsOneWidget);

      router.go('/home');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await expandMoreActionsIfNeeded(tester, targetLabel: 'Rules');
      await tapLabel(tester, 'Rules');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('RULES_ROUTE'), findsOneWidget);

      router.go('/home');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await expandMoreActionsIfNeeded(tester, targetLabel: 'Settings');
      await tapLabel(tester, 'Settings');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('SETTINGS_ROUTE'), findsOneWidget);
    },
  );

  testWidgets('Settings hides release tooling from parent-facing surface', (
    tester,
  ) async {
    setPhoneViewport(tester);

    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('RELEASE'), findsNothing);
    expect(find.text('Open Release Ops'), findsNothing);
    expect(find.text('Open Release Metrics'), findsNothing);
    expect(find.text('Open Compliance Checklist'), findsNothing);
  });
}
