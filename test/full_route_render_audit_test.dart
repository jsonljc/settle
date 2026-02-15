import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settle/main.dart';
import 'package:settle/models/approach.dart';
import 'package:settle/models/baby_profile.dart';
import 'package:settle/models/day_plan.dart';
import 'package:settle/models/night_wake.dart';
import 'package:settle/models/sleep_session.dart';
import 'package:settle/models/tantrum_profile.dart';
import 'package:settle/router.dart';
import 'package:settle/screens/family_rules.dart';
import 'package:settle/screens/help_now.dart';

import 'package:settle/screens/current_rhythm_screen.dart';
import 'package:settle/screens/learn.dart';
import 'package:settle/screens/onboarding/onboarding_screen.dart';
import 'package:settle/screens/plan_progress.dart';
import 'package:settle/screens/release_compliance_checklist.dart';
import 'package:settle/screens/release_metrics.dart';
import 'package:settle/screens/release_ops_checklist.dart';
import 'package:settle/screens/settings.dart';
import 'package:settle/screens/sleep_tonight.dart';
import 'package:settle/screens/sos.dart';
import 'package:settle/screens/splash.dart';
import 'package:settle/screens/update_rhythm_screen.dart';
import 'package:settle/screens/today.dart';
import 'package:settle/widgets/release_surfaces.dart';

void main() {
  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('settle_full_route_audit');
    Hive.init(dir.path);
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
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SettleApp()));
    await tester.pump();
  }

  Future<void> goTo(WidgetTester tester, String path) async {
    router.go(path);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
  }

  void expectAnyScreen(List<Type> types, {required String routePath}) {
    final hits = types.fold<int>(
      0,
      (sum, type) => sum + find.byType(type).evaluate().length,
    );
    expect(
      hits,
      greaterThan(0),
      reason:
          'Expected one of ${types.join(', ')} after routing to $routePath.',
    );
  }

  void expectNoUncaughtException(String routePath, WidgetTester tester) {
    Object? firstError;
    while (true) {
      final error = tester.takeException();
      if (error == null) break;
      firstError ??= error;
    }
    expect(
      firstError,
      isNull,
      reason: 'Uncaught exception while rendering route $routePath.',
    );
  }

  testWidgets('all declared routes render without runtime exceptions', (
    tester,
  ) async {
    await pumpApp(tester);

    final checks = <_RouteCheck>[
      _RouteCheck(path: '/', expectedTypes: [SplashScreen]),
      _RouteCheck(path: '/onboard', expectedTypes: [OnboardingScreen]),
      // /home redirects to /now (shell Help Now tab).
      _RouteCheck(
        path: '/home',
        expectedTypes: [HelpNowScreen, SleepTonightScreen],
      ),
      // Shell tab routes.
      _RouteCheck(
        path: '/now',
        expectedTypes: [HelpNowScreen, SleepTonightScreen],
      ),
      _RouteCheck(path: '/sleep', expectedTypes: [SleepTonightScreen]),
      _RouteCheck(path: '/sleep/rhythm', expectedTypes: [CurrentRhythmScreen]),
      _RouteCheck(
        path: '/sleep/update-rhythm',
        expectedTypes: [UpdateRhythmScreen],
      ),
      _RouteCheck(path: '/progress', expectedTypes: [PlanProgressScreen]),
      _RouteCheck(path: '/progress/logs', expectedTypes: [TodayScreen]),
      _RouteCheck(path: '/progress/learn', expectedTypes: [LearnScreen]),
      // Overlay screens (push on top of shell).
      _RouteCheck(path: '/night-mode', expectedTypes: [SleepTonightScreen]),
      _RouteCheck(path: '/breathe', expectedTypes: [SosScreen]),
      _RouteCheck(path: '/rules', expectedTypes: [FamilyRulesScreen]),
      _RouteCheck(path: '/settings', expectedTypes: [SettingsScreen]),
      // Compatibility redirects.
      _RouteCheck(
        path: '/help-now',
        expectedTypes: [HelpNowScreen, SleepTonightScreen],
      ),
      _RouteCheck(path: '/sleep-tonight', expectedTypes: [SleepTonightScreen]),
      _RouteCheck(
        path: '/current-rhythm',
        expectedTypes: [CurrentRhythmScreen],
      ),
      _RouteCheck(path: '/update-rhythm', expectedTypes: [UpdateRhythmScreen]),
      _RouteCheck(path: '/plan-progress', expectedTypes: [PlanProgressScreen]),
      _RouteCheck(path: '/plan', expectedTypes: [PlanProgressScreen]),
      _RouteCheck(path: '/family-rules', expectedTypes: [FamilyRulesScreen]),
      _RouteCheck(path: '/night', expectedTypes: [SleepTonightScreen]),
      _RouteCheck(path: '/today', expectedTypes: [TodayScreen]),
      _RouteCheck(path: '/learn', expectedTypes: [LearnScreen]),
      _RouteCheck(path: '/sos', expectedTypes: [SosScreen]),
      // Internal tooling.
      _RouteCheck(
        path: '/release-metrics',
        expectedTypes: [ReleaseMetricsScreen, RouteUnavailableView],
      ),
      _RouteCheck(
        path: '/release-compliance',
        expectedTypes: [ReleaseComplianceChecklistScreen, RouteUnavailableView],
      ),
      _RouteCheck(
        path: '/release-ops',
        expectedTypes: [ReleaseOpsChecklistScreen, RouteUnavailableView],
      ),
      // Unknown routes.
      _RouteCheck(path: '/legacy/today', expectedTypes: [RouteUnavailableView]),
    ];

    for (final check in checks) {
      await goTo(tester, check.path);
      expectNoUncaughtException(check.path, tester);
      expectAnyScreen(check.expectedTypes, routePath: check.path);
    }
  });
}

class _RouteCheck {
  const _RouteCheck({required this.path, required this.expectedTypes});

  final String path;
  final List<Type> expectedTypes;
}
