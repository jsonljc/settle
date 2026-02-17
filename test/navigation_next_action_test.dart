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
import 'package:settle/screens/learn.dart';
import 'package:settle/screens/today.dart';

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

  Future<void> tapLabel(WidgetTester tester, String label) async {
    final finder = find.text(label);
    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().isNotEmpty) {
      for (var i = 0; i < scrollables.evaluate().length; i++) {
        try {
          await tester.scrollUntilVisible(
            finder,
            260,
            scrollable: scrollables.at(i),
            maxScrolls: 25,
          );
          break;
        } catch (_) {
          // Try the next scrollable when the target is not inside this one.
        }
      }
    }
    await tester.ensureVisible(finder);
    final logicalHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    for (var i = 0; i < 6; i++) {
      final center = tester.getCenter(finder, warnIfMissed: false);
      if (center.dy < logicalHeight - 20) {
        break;
      }
      if (scrollables.evaluate().isEmpty) {
        break;
      }
      await tester.drag(scrollables.last, const Offset(0, -140));
      await tester.pump();
    }
    final tappable = find.ancestor(
      of: finder,
      matching: find.byType(GestureDetector),
    );
    if (tappable.evaluate().isNotEmpty) {
      await tester.tap(tappable.first);
      return;
    }
    await tester.tap(finder);
  }

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('settle_navigation_next');
    Hive.init(dir.path);
    await registerHiveAdapters();
    final box = await Hive.openBox<dynamic>('release_rollout_v1');
    await box.put('state', {
      'schema_version': 3,
      'v2_navigation_enabled': true,
    });
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  testWidgets(
    'Logs screen routes to plan and learn next actions',
    (tester) async {
      setPhoneViewport(tester);

      final router = GoRouter(
        initialLocation: '/library/logs',
        routes: [
          GoRoute(
            path: '/library/logs',
            builder: (context, state) => const TodayScreen(),
          ),
          GoRoute(
            path: '/plan',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('PLAN_ROUTE'))),
          ),
          GoRoute(
            path: '/library/learn',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('LEARN_ROUTE'))),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Logs'), findsOneWidget);
      expect(find.text('Open Plan Focus'), findsOneWidget);
      expect(find.text('Open Learn Q&A'), findsOneWidget);

      await tapLabel(tester, 'Open Plan Focus');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('PLAN_ROUTE'), findsOneWidget);

      router.go('/library/logs');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tapLabel(tester, 'Open Learn Q&A');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('LEARN_ROUTE'), findsOneWidget);
    },
    skip: true,
  ); // Async rollout load; v2 routing in router_v2_shell_hardening_test

  testWidgets(
    'Learn screen routes to plan and logs next actions',
    (tester) async {
      setPhoneViewport(tester);

      final router = GoRouter(
        initialLocation: '/library/learn',
        routes: [
          GoRoute(
            path: '/library/learn',
            builder: (context, state) => const LearnScreen(),
          ),
          GoRoute(
            path: '/plan',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('PLAN_ROUTE'))),
          ),
          GoRoute(
            path: '/library/logs',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('LOGS_ROUTE'))),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Learn'), findsOneWidget);

      await tapLabel(tester, 'Open Plan Focus');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('PLAN_ROUTE'), findsOneWidget);

      router.go('/library/learn');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tapLabel(tester, 'Open Logs');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('LOGS_ROUTE'), findsOneWidget);
    },
    skip: true,
  ); // Async rollout load; v2 routing in router_v2_shell_hardening_test
}
