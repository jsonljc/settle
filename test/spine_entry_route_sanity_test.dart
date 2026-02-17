import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settle/models/approach.dart';
import 'package:settle/models/baby_profile.dart';
import 'package:settle/models/day_plan.dart';
import 'package:settle/models/night_wake.dart';
import 'package:settle/models/reset_event.dart';
import 'package:settle/models/sleep_session.dart';
import 'package:settle/models/tantrum_profile.dart';
import 'package:settle/models/user_card.dart';
import 'package:settle/router.dart';
import 'package:settle/screens/library/saved_playbook_screen.dart';
import 'package:settle/screens/plan/plan_spine_stub_screens.dart';
import 'package:settle/screens/sleep_tonight.dart';

void main() {
  setUpAll(() async {
    final hiveDir = Directory.systemTemp.createTempSync('settle_spine_routes');
    Hive.init(hiveDir.path);
    _registerAdapters();
    await Future.wait([
      Hive.openBox<dynamic>('release_rollout_v1'),
      Hive.openBox<dynamic>('spine_store'),
      Hive.openBox<UserCard>('user_cards'),
    ]);
  });

  testWidgets('5 spine entry points reach screens and exit cleanly', (
    tester,
  ) async {
    final goRouter = buildRouter(regulateEnabled: true);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: goRouter)),
    );
    await _settleRoute(tester);

    final routeChecks = <_RouteCheck>[
      _RouteCheck('/plan/reset', ResetStubScreen, '/plan'),
      _RouteCheck('/library/saved', SavedPlaybookScreen, '/library'),
      _RouteCheck('/plan/moment', MomentStubScreen, '/plan'),
      _RouteCheck(
        '/plan/tantrum-just-happened',
        TantrumJustHappenedStubScreen,
        '/plan',
      ),
    ];

    for (final check in routeChecks) {
      goRouter.go(check.path);
      await _settleRoute(tester);
      expect(find.byType(check.screenType), findsOneWidget);

      await _tapBack(tester);
      await _settleRoute(tester);

      expect(
        goRouter.routeInformationProvider.value.uri.path,
        check.exitPath,
        reason: 'Expected ${check.path} to exit to ${check.exitPath}.',
      );
    }

    goRouter.go('/sleep/tonight');
    await _settleRoute(tester);
    expect(find.byType(SleepTonightScreen), findsOneWidget);

    await _tapBack(tester);
    await _settleRoute(tester);

    final sleepExitPath = goRouter.routeInformationProvider.value.uri.path;
    expect(sleepExitPath, '/sleep');
    expect(
      find.byType(SleepTonightScreen),
      findsNothing,
      reason: 'Sleep Tonight should close after back.',
    );

    goRouter.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

class _RouteCheck {
  const _RouteCheck(this.path, this.screenType, this.exitPath);

  final String path;
  final Type screenType;
  final String exitPath;
}

Future<void> _settleRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump(const Duration(milliseconds: 450));
}

Future<void> _tapBack(WidgetTester tester) async {
  final backIcon = find.byIcon(Icons.arrow_back_ios_rounded);
  if (backIcon.evaluate().isNotEmpty) {
    await tester.tap(backIcon.first);
    return;
  }
  await tester.tap(find.bySemanticsLabel('Back').first);
}

void _registerAdapters() {
  if (Hive.isAdapterRegistered(0)) {
    return;
  }

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
    ..registerAdapter(DayPlanAdapter())
    ..registerAdapter(UserCardAdapter())
    ..registerAdapter(ResetEventAdapter());
}
