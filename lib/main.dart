import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/approach.dart';
import 'models/baby_profile.dart';
import 'models/day_plan.dart';
import 'models/family_member.dart';
import 'models/nudge_record.dart';
import 'models/night_wake.dart';
import 'models/pattern_insight.dart';
import 'models/regulation_event.dart';
import 'models/reset_event.dart';
import 'models/sleep_session.dart';
import 'models/tantrum_profile.dart';
import 'models/usage_event.dart';
import 'models/user_card.dart';
import 'models/v2_enums.dart';
import 'data/app_repository.dart';
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
    ..registerAdapter(NudgeTypeAdapter())
    ..registerAdapter(FamilyMemberAdapter())
    ..registerAdapter(ResetEventAdapter());

  await Future.wait([
    Hive.openBox<UserCard>('user_cards'),
    Hive.openBox<UsageEvent>('usage_events'),
    Hive.openBox<RegulationEvent>('regulation_events'),
    Hive.openBox<PatternInsight>('patterns'),
    Hive.openBox<NudgeRecord>('nudges'),
    Hive.openBox<FamilyMember>('family_members'),
    Hive.openBox<dynamic>('family_members_meta'),
    Hive.openBox<dynamic>('nudge_settings'),
    Hive.openBox<dynamic>('release_rollout_v1'),
    Hive.openBox<dynamic>('weekly_reflection_meta'),
    Hive.openBox<dynamic>('spine_store'),
  ]);
  _ensureSpineSchemaVersion();
  refreshRouterFromRollout();

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

void _ensureSpineSchemaVersion() {
  try {
    final box = Hive.box<dynamic>('spine_store');
    if (box.get('schema_version') == null) {
      box.put('schema_version', spineSchemaVersion);
    }
  } catch (_) {
    // Graceful fallback: app still works
  }
}

class SettleApp extends StatelessWidget {
  const SettleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Settle',
      debugShowCheckedModeBanner: false,
      theme: SettleTheme.dataV3,
      routerConfig: router,
    );
  }
}
