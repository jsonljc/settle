import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/approach.dart';
import 'models/baby_profile.dart';
import 'models/sleep_session.dart';
import 'models/night_wake.dart';
import 'models/day_plan.dart';
import 'models/tantrum_profile.dart';
import 'router.dart';
import 'services/event_bus_service.dart';
import 'services/notification_service.dart';
import 'theme/settle_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register all Hive type adapters.
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

  // Initialize local notifications (timezone, channels, permissions).
  await NotificationService.init();

  const telemetryChildId = 'app_global';
  await EventBusService.emitPlanAppSessionStarted(
    childId: telemetryChildId,
    appVersion: 'v1',
  );

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(
      EventBusService.emitPlanAppCrash(
        childId: telemetryChildId,
        appVersion: 'v1',
        crashSource: 'flutter_error',
      ),
    );
  };

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
  );

  runApp(const ProviderScope(child: SettleApp()));
}

class SettleApp extends StatelessWidget {
  const SettleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Settle',
      debugShowCheckedModeBanner: false,
      theme: SettleTheme.data,
      routerConfig: router,
    );
  }
}
