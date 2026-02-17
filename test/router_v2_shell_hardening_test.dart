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
import 'package:settle/models/nudge_record.dart';
import 'package:settle/models/pattern_insight.dart';
import 'package:settle/models/regulation_event.dart';
import 'package:settle/models/sleep_session.dart';
import 'package:settle/models/tantrum_profile.dart';
import 'package:settle/models/usage_event.dart';
import 'package:settle/models/user_card.dart';
import 'package:settle/models/v2_enums.dart';
import 'package:settle/router.dart';

void main() {
  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('settle_router_v2_harden');
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
        ..registerAdapter(DayPlanAdapter())
        ..registerAdapter(UserCardAdapter())
        ..registerAdapter(UsageEventAdapter())
        ..registerAdapter(RegulationEventAdapter())
        ..registerAdapter(PatternInsightAdapter())
        ..registerAdapter(NudgeRecordAdapter())
        ..registerAdapter(UsageOutcomeAdapter())
        ..registerAdapter(RegulationTriggerAdapter())
        ..registerAdapter(PatternTypeAdapter())
        ..registerAdapter(NudgeTypeAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  Future<void> pumpWithRouter(WidgetTester tester, GoRouter router) async {
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pump();
  }

  Future<void> goTo(WidgetTester tester, GoRouter router, String path) async {
    router.go(path);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 650));
  }

  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
  }

  testWidgets('v2 shell renders v2 tabs and hides legacy tab labels', (
    tester,
  ) async {
    final router = buildRouter(regulateEnabled: false);

    await pumpWithRouter(tester, router);
    await goTo(tester, router, '/plan');

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Family'), findsWidgets);
    expect(find.text('Sleep'), findsWidgets);
    expect(find.text('Library'), findsWidgets);

    expect(find.text('Help Now'), findsNothing);
    expect(find.text('Progress'), findsNothing);
    expect(find.text('Tantrum'), findsNothing);
    await disposeTree(tester);
  });

  testWidgets('v2 compatibility redirects land on v2 destinations', (
    tester,
  ) async {
    final router = buildRouter(regulateEnabled: false);

    await pumpWithRouter(tester, router);

    await goTo(tester, router, '/progress');
    expect(router.routeInformationProvider.value.uri.path, '/library');

    await goTo(tester, router, '/now');
    expect(router.routeInformationProvider.value.uri.path, '/plan');

    await goTo(tester, router, '/tantrum/capture');
    expect(router.routeInformationProvider.value.uri.path, '/plan');
    await disposeTree(tester);
  });

  testWidgets('plan regulate route shows full regulate flow (not SOS stub)', (
    tester,
  ) async {
    final router = buildRouter(regulateEnabled: false);

    await pumpWithRouter(tester, router);

    await goTo(tester, router, '/plan/regulate');
    expect(router.routeInformationProvider.value.uri.path, '/plan/regulate');
    expect(find.text('You\'re having a hard moment too.'), findsOneWidget);

    await goTo(tester, router, '/sos');
    expect(router.routeInformationProvider.value.uri.path, '/breathe');
    expect(find.text('Take a Breath'), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('v2 enabled regulate route avoids redirect loops', (
    tester,
  ) async {
    final router = buildRouter(regulateEnabled: true);

    await pumpWithRouter(tester, router);

    await goTo(tester, router, '/sos');
    expect(router.routeInformationProvider.value.uri.path, '/plan/regulate');
    expect(find.text('You\'re having a hard moment too.'), findsOneWidget);

    await goTo(tester, router, '/breathe');
    expect(router.routeInformationProvider.value.uri.path, '/plan/regulate');
    expect(find.text('You\'re having a hard moment too.'), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('library subroutes render saved and patterns screens', (
    tester,
  ) async {
    final router = buildRouter(regulateEnabled: false);

    await pumpWithRouter(tester, router);

    await goTo(tester, router, '/library/saved');
    expect(router.routeInformationProvider.value.uri.path, '/library/saved');
    expect(find.text('Saved playbook'), findsOneWidget);

    await goTo(tester, router, '/library/patterns');
    expect(router.routeInformationProvider.value.uri.path, '/library/patterns');
    expect(find.text('Your patterns'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('library card detail opens from direct route', (tester) async {
    final router = buildRouter(regulateEnabled: false);

    await pumpWithRouter(tester, router);

    await goTo(tester, router, '/library/cards/transitions_timer_choice');
    expect(
      router.routeInformationProvider.value.uri.path,
      '/library/cards/transitions_timer_choice',
    );
    expect(find.text('Script'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('library insights and family routes resolve', (tester) async {
    final router = buildRouter(regulateEnabled: false);

    await pumpWithRouter(tester, router);

    await goTo(tester, router, '/library/insights');
    expect(router.routeInformationProvider.value.uri.path, '/library/insights');
    expect(find.text('Monthly insight'), findsOneWidget);

    await goTo(tester, router, '/family/activity');
    expect(router.routeInformationProvider.value.uri.path, '/family/activity');
    expect(find.text('Activity'), findsAtLeastNWidgets(1));

    await goTo(tester, router, '/family/invite');
    expect(router.routeInformationProvider.value.uri.path, '/family/invite');
    await disposeTree(tester);
  });

  testWidgets('plan log route shows Logs screen', (tester) async {
    final router = buildRouter(regulateEnabled: false);

    await pumpWithRouter(tester, router);
    await goTo(tester, router, '/plan/log');
    expect(router.routeInformationProvider.value.uri.path, '/plan/log');
    expect(find.text('Logs'), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('v2 compatibility today and learn redirect to library', (
    tester,
  ) async {
    final router = buildRouter(regulateEnabled: false);

    await pumpWithRouter(tester, router);

    await goTo(tester, router, '/today');
    expect(router.routeInformationProvider.value.uri.path, '/library/logs');

    await goTo(tester, router, '/learn');
    expect(router.routeInformationProvider.value.uri.path, '/library/learn');
    await disposeTree(tester);
  });
}
