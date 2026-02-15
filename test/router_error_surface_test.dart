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
    final dir = Directory.systemTemp.createTempSync('settle_route_error_ui');
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

  testWidgets('unknown route renders graceful fallback surface', (
    tester,
  ) async {
    await pumpApp(tester);

    router.go('/this-route-does-not-exist');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('This page is unavailable'), findsOneWidget);
    expect(
      find.text(
        'We couldn\'t open that page. Please go to Home and try again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Go to Home'), findsOneWidget);
  });
}
