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
import 'providers/nudge_settings_provider.dart';
import 'providers/profile_provider.dart';
import 'router.dart';
import 'services/event_bus_service.dart';
import 'services/notification_service.dart';
import 'services/spec_policy.dart';
import 'theme/settle_design_system.dart';

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

  // Open storage boxes; continue on partial failure so app can show calm fallback.
  final boxes = <Future<void>>[
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
    Hive.openBox<dynamic>('close_moment_suppress'),
  ];
  for (final f in boxes) {
    try {
      await f;
    } catch (_) {
      // One box failed; others may have opened. App continues with partial storage.
    }
  }
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
    if (!Hive.isBoxOpen('spine_store')) return;
    final box = Hive.box<dynamic>('spine_store');
    if (box.get('schema_version') == null) {
      box.put('schema_version', spineSchemaVersion);
    }
  } catch (_) {
    // Graceful fallback: app still works with default schema
  }
}

class SettleApp extends ConsumerStatefulWidget {
  const SettleApp({super.key});

  @override
  ConsumerState<SettleApp> createState() => _SettleAppState();
}

class _SettleAppState extends ConsumerState<SettleApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _scheduleEveningCheckInOnBackground();
    } else if (state == AppLifecycleState.resumed) {
      _cancelEveningCheckInIfRecentlyOpened();
    }
  }

  /// Default bedtime 6 PM when profile has no preferred bedtime.
  static (int, int) _bedtimeHourMin(String? preferredBedtime) {
    if (preferredBedtime != null && preferredBedtime.trim().isNotEmpty) {
      final parts = preferredBedtime.trim().split(RegExp(r'[:\s]'));
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0].trim());
        final m = int.tryParse(parts[1].trim());
        if (h != null && m != null && h >= 0 && h <= 23 && m >= 0 && m <= 59) {
          return (h, m);
        }
      }
    }
    return (18, 0);
  }

  void _scheduleEveningCheckInOnBackground() {
    final settings = ref.read(nudgeSettingsProvider);
    if (!settings.eveningCheckInEnabled) return;

    final profile = ref.read(profileProvider);
    final (h, m) = _bedtimeHourMin(profile?.preferredBedtime);
    final now = DateTime.now();
    var fireAt = DateTime(
      now.year,
      now.month,
      now.day,
      h,
      m,
    ).subtract(const Duration(hours: 1));
    if (!fireAt.isAfter(now.add(const Duration(minutes: 1)))) {
      fireAt = fireAt.add(const Duration(days: 1));
    }
    if (settings.isQuietHour(fireAt.hour)) return;

    NotificationService.scheduleEveningCheckIn(fireAt);
  }

  void _cancelEveningCheckInIfRecentlyOpened() {
    final settings = ref.read(nudgeSettingsProvider);
    if (!settings.eveningCheckInEnabled) return;

    final profile = ref.read(profileProvider);
    final (h, m) = _bedtimeHourMin(profile?.preferredBedtime);
    final now = DateTime.now();
    var fireAt = DateTime(
      now.year,
      now.month,
      now.day,
      h,
      m,
    ).subtract(const Duration(hours: 1));
    if (fireAt.isBefore(now)) {
      fireAt = fireAt.add(const Duration(days: 1));
    }
    final windowStart = fireAt.subtract(const Duration(hours: 2));
    final windowEnd = fireAt.add(const Duration(minutes: 15));
    if (!now.isBefore(windowStart) && !now.isAfter(windowEnd)) {
      NotificationService.cancelEveningCheckIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const _SmartThemeWrapper();
  }
}

/// Wraps the app so theme is driven by smart dark mode:
/// - Sleep Tonight and Reset routes always dark
/// - After 7 PM or before 6 AM: dark (time-of-day fallback)
/// - 6 AM–7 PM: follow system brightness
/// Transition between modes: 300ms fade (via AnimatedTheme).
class _SmartThemeWrapper extends StatefulWidget {
  const _SmartThemeWrapper();

  @override
  State<_SmartThemeWrapper> createState() => _SmartThemeWrapperState();
}

class _SmartThemeWrapperState extends State<_SmartThemeWrapper> {
  static const _themeTransitionDuration = Duration(milliseconds: 300);

  static bool _forceDarkForRoute(String path) {
    final p = path.toLowerCase();
    return p.contains('sleep/tonight') || p.contains('plan/reset');
  }

  static bool _resolveIsDark({
    required String path,
    required Brightness platformBrightness,
    required DateTime now,
  }) {
    if (_forceDarkForRoute(path)) return true;
    if (SpecPolicy.isNight(now)) return true;
    return platformBrightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    return ListenableBuilder(
      listenable: router.routeInformationProvider,
      builder: (context, _) {
        final path = router.routerDelegate.currentConfiguration.fullPath;
        final pathStr = path.isEmpty ? '/' : path;
        final now = DateTime.now();
        final isDark = _resolveIsDark(
          path: pathStr,
          platformBrightness: platformBrightness,
          now: now,
        );
        final themeData =
            isDark ? SettleTheme.dark : SettleTheme.light;
        return AnimatedTheme(
          data: themeData,
          duration: _themeTransitionDuration,
          curve: Curves.easeInOut,
          child: MaterialApp.router(
            title: 'Settle',
            debugShowCheckedModeBanner: false,
            theme: themeData,
            darkTheme: themeData,
            themeMode: ThemeMode.dark,
            routerConfig: router,
            scrollBehavior: const _SettleScrollBehavior(),
          ),
        );
      },
    );
  }
}

/// iOS-style bounce, no overscroll glow (Android).
class _SettleScrollBehavior extends MaterialScrollBehavior {
  const _SettleScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;
}
