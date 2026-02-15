import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Notification IDs — stable so we can cancel specific notifications.
class _Ids {
  static const int wakeWindowNudge = 1;
}

/// Handles all local notifications for Settle.
///
/// Currently supports:
/// - **Wake window nudge**: scheduled when a sleep session ends (baby wakes).
///   Fires at [maxWakeWindow − 15] minutes, saying
///   "Nap window opening soon for [name]."
///   Cancelled automatically when a new sleep session starts.
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
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          _androidChannel.id,
          _androidChannel.name,
          description: _androidChannel.description,
          importance: _androidChannel.importance,
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
    final fireAt = tz.TZDateTime.now(tz.local).add(
      Duration(minutes: delayMinutes),
    );

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
}
