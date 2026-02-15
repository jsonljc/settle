import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:settle/models/approach.dart';
import 'package:settle/models/baby_profile.dart';
import 'package:settle/models/sleep_session.dart';
import 'package:settle/models/night_wake.dart';
import 'package:settle/models/day_plan.dart';
import 'package:settle/models/tantrum_profile.dart';
import 'package:settle/main.dart';

void main() {
  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('settle_test');
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

  testWidgets('Splash screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SettleApp()));
    // First frame — splash content visible
    await tester.pump();

    expect(find.text('settle'), findsOneWidget);
    expect(find.text('One step at a time.'), findsOneWidget);

    // Drain the 2.2s redirect timer + flutter_animate fadeIn timers
    await tester.pump(const Duration(seconds: 3));
    // After redirect fires, we're on /onboard which has flutter_animate
    // staggered animations. Pump repeatedly to drain them all.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  });
}
