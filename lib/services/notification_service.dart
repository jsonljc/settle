import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Notification IDs — stable so we can cancel specific notifications.
class _Ids {
  static const int wakeWindowNudge = 1;
  static const int windDownReminder = 2;
  static const int scheduleDriftPrompt = 3;
  static const int eveningCheckIn = 4;
  // Plan nudges (v2)
  static const int nudgePredictable = 10;
  static const int nudgePattern = 11;
  static const int nudgeContent = 12;
}

/// Handles all local notifications for Settle.
///
/// Currently supports:
/// - **Wake window nudge**: scheduled when a sleep session ends (baby wakes).
///   Fires at [maxWakeWindow − 15] minutes, saying
///   "Nap window opening soon for [name]."
///   Cancelled automatically when a new sleep session starts.
/// - **Wind-down reminder**: one high-signal reminder 10–20 minutes before
///   the next nap/bedtime target.
/// - **Schedule drift prompt**: optional one-shot prompt when rhythm drift is
///   detected.
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ───────────────────────────────────────────
  //  Android channel
  // ───────────────────────────────────────────

  static const _androidChannel = AndroidNotificationChannel(
    'settle_wake_window',
    'Wake window nudges',
    description: 'Gentle reminder when the nap window is opening',
    importance: Importance.high,
  );

  static const _sleepSignalChannel = AndroidNotificationChannel(
    'settle_sleep_signal',
    'Sleep high-signal reminders',
    description: 'Wind-down and drift reminders',
    importance: Importance.high,
  );

  static const _planNudgeChannel = AndroidNotificationChannel(
    'settle_plan_nudges',
    'Plan nudges',
    description: 'Gentle reminders for scripts and patterns',
    importance: Importance.defaultImportance,
  );

  static DateTime? _lastWindDownScheduledAt;
  static DateTime? _lastDriftPromptScheduledAt;

  // ───────────────────────────────────────────
  //  Initialization
  // ───────────────────────────────────────────

  /// Call once during app startup (in main.dart).
  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    // Android settings — use the app icon as the notification icon.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS / macOS settings — request permission on first init.
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(initSettings);

    // Create the Android notification channel.
    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          _androidChannel.id,
          _androidChannel.name,
          description: _androidChannel.description,
          importance: _androidChannel.importance,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          _sleepSignalChannel.id,
          _sleepSignalChannel.name,
          description: _sleepSignalChannel.description,
          importance: _sleepSignalChannel.importance,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          _planNudgeChannel.id,
          _planNudgeChannel.name,
          description: _planNudgeChannel.description,
          importance: _planNudgeChannel.importance,
        ),
      );
      // Request exact alarm permission (Android 12+).
      await androidPlugin?.requestExactAlarmsPermission();
      // Request notification permission (Android 13+).
      await androidPlugin?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  // ───────────────────────────────────────────
  //  Wake window nudge
  // ───────────────────────────────────────────

  /// Schedule a "nap window opening soon" notification.
  ///
  /// [maxWakeWindowMinutes] — the upper end of the age-bracket wake window.
  /// The notification fires 15 minutes before that maximum.
  /// [babyName] — used in the notification body.
  ///
  /// Call this when a sleep session ends (baby wakes up).
  static Future<void> scheduleWakeWindowNudge({
    required int maxWakeWindowMinutes,
    required String babyName,
  }) async {
    if (!_initialized) return;

    // Fire 15 min before the max wake window.
    final delayMinutes = (maxWakeWindowMinutes - 15).clamp(5, 600);
    final fireAt = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(minutes: delayMinutes));

    await _plugin.zonedSchedule(
      _Ids.wakeWindowNudge,
      'Nap window opening soon',
      'Nap window opening soon for $babyName.',
      fireAt,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          // Gentle — no persistent sound, just default
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null, // one-shot, not recurring
    );
  }

  static Future<void> scheduleWindDownReminder({
    required DateTime targetTime,
    required String babyName,
    required bool bedtime,
    int leadMinutes = 15,
  }) async {
    if (!_initialized) return;

    final boundedLead = leadMinutes.clamp(10, 20);
    final fireAtDateTime = targetTime.subtract(Duration(minutes: boundedLead));
    final now = DateTime.now();

    if (!fireAtDateTime.isAfter(now.add(const Duration(minutes: 1)))) {
      return;
    }

    // High-signal only: avoid rapid re-scheduling.
    final last = _lastWindDownScheduledAt;
    if (last != null && now.difference(last).inMinutes < 30) {
      return;
    }
    _lastWindDownScheduledAt = now;

    final fireAt = tz.TZDateTime.from(fireAtDateTime, tz.local);
    final body = bedtime
        ? 'Bedtime wind-down starts in about $boundedLead minutes for $babyName.'
        : 'Nap wind-down starts in about $boundedLead minutes for $babyName.';

    await _plugin.zonedSchedule(
      _Ids.windDownReminder,
      bedtime ? 'Bedtime wind-down soon' : 'Nap wind-down soon',
      body,
      fireAt,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _sleepSignalChannel.id,
          _sleepSignalChannel.name,
          channelDescription: _sleepSignalChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  static Future<void> cancelWindDownReminder() async {
    if (!_initialized) return;
    await _plugin.cancel(_Ids.windDownReminder);
  }

  static Future<void> scheduleDriftDetectedPrompt({
    required String babyName,
  }) async {
    if (!_initialized) return;

    final now = DateTime.now();
    final last = _lastDriftPromptScheduledAt;

    // High-signal only: max one drift prompt in a 12h window.
    if (last != null && now.difference(last).inHours < 12) {
      return;
    }
    _lastDriftPromptScheduledAt = now;

    final fireAt = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 2));
    await _plugin.zonedSchedule(
      _Ids.scheduleDriftPrompt,
      'Rhythm check-in',
      'Rhythm shifted for $babyName. Update tonight\'s plan when ready.',
      fireAt,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _sleepSignalChannel.id,
          _sleepSignalChannel.name,
          channelDescription: _sleepSignalChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  static Future<void> cancelScheduleDriftPrompt() async {
    if (!_initialized) return;
    await _plugin.cancel(_Ids.scheduleDriftPrompt);
  }

  /// Cancel any pending wake window nudge.
  ///
  /// Call this when a new sleep session starts — the baby is asleep,
  /// so the nudge is no longer relevant.
  static Future<void> cancelWakeWindowNudge() async {
    if (!_initialized) return;
    await _plugin.cancel(_Ids.wakeWindowNudge);
  }

  /// Cancel all pending notifications.
  static Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  // ───────────────────────────────────────────
  //  Evening check-in (opt-in, 1h before bedtime)
  // ───────────────────────────────────────────

  /// Schedules a single evening check-in at [fireAt].
  /// Copy: "Tonight's sleep plan is ready". Once per day; caller must ensure
  /// [fireAt] is 1h before user bedtime and not in quiet hours.
  static Future<void> scheduleEveningCheckIn(DateTime fireAt) async {
    if (!_initialized) return;
    final now = DateTime.now();
    if (!fireAt.isAfter(now.add(const Duration(minutes: 1)))) return;

    final tzFireAt = tz.TZDateTime.from(fireAt, tz.local);
    await _plugin.zonedSchedule(
      _Ids.eveningCheckIn,
      "Tonight's sleep plan is ready",
      'Open Settle to see your plan for tonight.',
      tzFireAt,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _sleepSignalChannel.id,
          _sleepSignalChannel.name,
          channelDescription: _sleepSignalChannel.description,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  /// Cancel the evening check-in notification (e.g. when user opens app within 2h of fire time).
  static Future<void> cancelEveningCheckIn() async {
    if (!_initialized) return;
    await _plugin.cancel(_Ids.eveningCheckIn);
  }

  // ───────────────────────────────────────────
  //  Plan nudges (v2)
  // ───────────────────────────────────────────

  /// Schedule a plan nudge at [fireAt]. [id] must be one of [_Ids.nudgePredictable], [_Ids.nudgePattern], [_Ids.nudgeContent].
  static Future<void> schedulePlanNudge({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
  }) async {
    if (!_initialized) return;
    final tzFireAt = tz.TZDateTime.from(fireAt, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzFireAt,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _planNudgeChannel.id,
          _planNudgeChannel.name,
          channelDescription: _planNudgeChannel.description,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  /// Cancel all plan nudges (predictable, pattern, content).
  static Future<void> cancelPlanNudges() async {
    if (!_initialized) return;
    await _plugin.cancel(_Ids.nudgePredictable);
    await _plugin.cancel(_Ids.nudgePattern);
    await _plugin.cancel(_Ids.nudgeContent);
  }
}
