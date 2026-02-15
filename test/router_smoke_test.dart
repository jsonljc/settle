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

void main() {
  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('settle_route_smoke');
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
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 300));
  }

  void expectAnyTitle(List<String> options) {
    final total = options.fold<int>(
      0,
      (count, title) => count + find.text(title).evaluate().length,
    );
    expect(
      total,
      greaterThan(0),
      reason: 'Expected one of titles: ${options.join(', ')}',
    );
  }

  testWidgets('primary destination routes render', (tester) async {
    await pumpApp(tester);

    await goTo(tester, '/now');
    expectAnyTitle(['Help Now', 'Tonight\'s Sleep', 'Sleep Tonight']);

    await goTo(tester, '/sleep');
    expectAnyTitle(['Tonight\'s Sleep', 'Sleep Tonight']);

    await goTo(tester, '/sleep/rhythm');
    expect(find.text('Current Rhythm'), findsWidgets);

    await goTo(tester, '/sleep/update-rhythm');
    expect(find.text('Update Rhythm'), findsWidgets);

    await goTo(tester, '/progress');
    expect(find.text('Progress'), findsWidgets);

    await goTo(tester, '/rules');
    expect(find.text('Family Rules'), findsWidgets);

    await goTo(tester, '/help-now');
    expectAnyTitle(['Help Now', 'Tonight\'s Sleep', 'Sleep Tonight']);

    await goTo(tester, '/sleep-tonight');
    expectAnyTitle(['Tonight\'s Sleep', 'Sleep Tonight']);

    await goTo(tester, '/current-rhythm');
    expect(find.text('Current Rhythm'), findsWidgets);

    await goTo(tester, '/update-rhythm');
    expect(find.text('Update Rhythm'), findsWidgets);

    await goTo(tester, '/plan-progress');
    expect(find.text('Progress'), findsWidgets);

    await goTo(tester, '/family-rules');
    expect(find.text('Family Rules'), findsWidgets);
  });

  testWidgets('key deep links and redirects render target screens', (
    tester,
  ) async {
    await pumpApp(tester);

    await goTo(tester, '/night');
    expectAnyTitle(['Tonight\'s Sleep', 'Sleep Tonight']);

    await goTo(tester, '/today');
    expect(find.text('Logs'), findsWidgets);

    await goTo(tester, '/sleep-tonight');
    expectAnyTitle(['Tonight\'s Sleep', 'Sleep Tonight']);

    await goTo(tester, '/legacy/today');
    expect(find.text('This page is unavailable'), findsOneWidget);
  });
}
