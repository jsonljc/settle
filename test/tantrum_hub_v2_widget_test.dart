import 'dart:io';

import 'package:flutter/material.dart';
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
import 'package:settle/providers/tantrum_providers.dart';
import 'package:settle/router.dart';
import 'package:settle/tantrum/providers/tantrum_module_providers.dart';

void main() {
  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('settle_tantrum_hub_v2');
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tantrumEventsProvider.overrideWith(
            (ref) => TantrumEventsNotifier(persist: false),
          ),
          deckStateProvider.overrideWith(
            (ref) => TantrumDeckNotifier(persist: false),
          ),
        ],
        child: const SettleApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<void> goTo(WidgetTester tester, String path) async {
    router.go(path);
    await tester.pumpAndSettle();
  }

  Future<void> waitForFinder(
    WidgetTester tester,
    Finder finder, {
    required String label,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 80));
    }
    fail('Timed out waiting for $label');
  }

  testWidgets('canonical tantrum routes and legacy redirects resolve', (
    tester,
  ) async {
    setPhoneViewport(tester);
    await pumpApp(tester);

    await goTo(tester, '/tantrum');
    expect(find.text('Capture'), findsWidgets);

    await goTo(tester, '/tantrum/now');
    expect(find.text('Capture'), findsWidgets);
    expect(find.text('Log & Get Card'), findsOneWidget);

    await goTo(tester, '/tantrum/deck');
    expect(find.text('Deck'), findsWidgets);

    await goTo(tester, '/tantrum/cards');
    expect(find.text('Deck'), findsWidgets);

    await goTo(tester, '/tantrum/insights');
    expect(find.text('Insights'), findsWidgets);

    await goTo(tester, '/tantrum/learn');
    expect(find.text('Insights'), findsWidgets);
  });

  testWidgets(
    'capture flow requires no typing and reaches one card in two taps',
    (tester) async {
      setPhoneViewport(tester);
      await pumpApp(tester);

      await goTo(tester, '/tantrum/capture');
      expect(find.byType(TextField), findsNothing);

      var taps = 0;
      await tester.tap(find.text('Transition').first);
      taps += 1;
      await tester.pump(const Duration(milliseconds: 120));

      await tester.tap(find.text('Log & Get Card'));
      taps += 1;
      await waitForFinder(
        tester,
        find.text('Remember'),
        label: 'Remember card section',
      );

      expect(taps, lessThanOrEqualTo(3));
      expect(find.text('Remember'), findsOneWidget);
      expect(find.text('Say'), findsOneWidget);
      expect(find.text('Do'), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
    },
  );

  testWidgets('insights unlock by fifth log and use supportive language', (
    tester,
  ) async {
    setPhoneViewport(tester);
    await pumpApp(tester);
    await goTo(tester, '/tantrum/capture');

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Transition').first);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(find.text('Log & Get Card'));
      await waitForFinder(tester, find.text('Done'), label: 'Done button');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
    }

    await goTo(tester, '/tantrum/insights');

    expect(find.textContaining('Insights unlock at 5 logs'), findsNothing);
    expect(find.textContaining('You may notice'), findsWidgets);
    expect(find.textContaining('You should'), findsNothing);
  });
}
