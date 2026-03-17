import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../app.dart';
import '../models/app_user_profile.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  AndroidFlutterLocalNotificationsPlugin? _androidNotifications;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _routeToBriefing();
      },
    );

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    const androidChannel = AndroidNotificationChannel(
      'nana_briefing_channel',
      'NANA Calm Cues',
      description: 'Daily calm-tech cue notifications',
      importance: Importance.max,
    );

    _androidNotifications ??= _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await _androidNotifications?.createNotificationChannel(androidChannel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await _showFromRemoteMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _routeToBriefing();
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _routeToBriefing();
    }

    _initialized = true;
  }

  Future<void> bindForegroundNavigation() async {
    // placeholder for later routing/state sync expansion
  }

  Future<String?> getFcmToken() {
    return _messaging.getToken();
  }

  Future<void> requestFullScreenPermission() async {
    _androidNotifications ??= _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await _androidNotifications?.requestFullScreenIntentPermission();
  }

  Future<void> syncDailyBriefSchedules(NotificationPreference preference) async {
    try {
      for (final daypart in BriefDaypart.values) {
        await _localNotifications.cancel(id: daypart.notificationId);
      }

      if (!preference.enabled) {
        debugPrint('NOTIFICATIONS: Daily briefs disabled, schedules cleared.');
        return;
      }

      await _prepareAndroidExactAlarmPermissionIfNeeded();

      final location = _resolveLocation(preference.timeZone);
      final schedules = preference.resolvedBriefSchedules;

      for (final daypart in BriefDaypart.values) {
        final schedule = schedules[daypart.key]!;
        if (!schedule.enabled) {
          continue;
        }
        final next = _nextScheduleTime(
          location,
          schedule.hour,
          schedule.minute,
        );
        try {
          await _scheduleZoned(
            id: daypart.notificationId,
            title: 'Your ${daypart.label.toLowerCase()} is ready',
            body: 'Take a calm look at today’s local weather, recipes, and resets.',
            scheduledDate: next,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                'nana_briefing_channel',
                'NANA Calm Cues',
                channelDescription: 'Daily calm-tech cue notifications',
                importance: Importance.max,
                priority: Priority.high,
                fullScreenIntent: preference.fullScreenIntent,
              ),
              iOS: const DarwinNotificationDetails(),
            ),
            payload: 'briefing_${daypart.key}',
          );
        } catch (error, st) {
          debugPrint(
            'NOTIFICATIONS: Failed to schedule ${daypart.key} briefing: $error',
          );
          debugPrint('$st');
        }
      }
    } catch (error, st) {
      debugPrint('NOTIFICATIONS: Failed to sync daily brief schedules: $error');
      debugPrint('$st');
    }
  }

  Future<void> _prepareAndroidExactAlarmPermissionIfNeeded() async {
    _androidNotifications ??= _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (_androidNotifications == null) {
      debugPrint('NOTIFICATIONS: Android notification plugin unavailable.');
      return;
    }

    try {
      final dynamic androidNotifications = _androidNotifications;
      final bool? granted =
          await androidNotifications.requestExactAlarmsPermission();
      debugPrint(
        'NOTIFICATIONS: requestExactAlarmsPermission result: $granted',
      );
    } catch (error, st) {
      debugPrint(
        'NOTIFICATIONS: Exact alarm permission request unavailable/failed: $error',
      );
      debugPrint('$st');
    }
  }

  Future<void> _scheduleZoned({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required String payload,
  }) async {
    try {
      debugPrint('NOTIFICATIONS: Scheduling notification $id with exact mode.');
      await _localNotifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
      return;
    } on PlatformException catch (error) {
      if (!_isExactAlarmPermissionError(error)) {
        rethrow;
      }

      debugPrint(
        'NOTIFICATIONS: Exact alarms unavailable for $id, retrying with inexact mode.',
      );
      await _localNotifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
      debugPrint('NOTIFICATIONS: Scheduled notification $id with inexact mode.');
    }
  }

  bool _isExactAlarmPermissionError(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = error.message?.toLowerCase() ?? '';
    return code.contains('exact_alarms_not_permitted') ||
        message.contains('exact alarms are not permitted');
  }

  tz.Location _resolveLocation(String timeZone) {
    try {
      return tz.getLocation(timeZone);
    } catch (_) {
      return tz.local;
    }
  }

  tz.TZDateTime _nextScheduleTime(tz.Location location, int hour, int minute) {
    final now = tz.TZDateTime.now(location);
    var scheduled = tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> showPreviewBriefing({
    required String title,
    required String body,
    bool fullScreenIntent = false,
  }) async {
    await _localNotifications.show(
      id: 9001,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'nana_briefing_channel',
          'NANA Calm Cues',
          channelDescription: 'Daily calm-tech cue notifications',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: fullScreenIntent,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: 'briefing',
    );
  }

  Future<void> _showFromRemoteMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? 'Your NANA calm cue is ready';
    final body =
        message.notification?.body ?? 'Take a calm look at today’s local weather, recipes, and resets.';
    final fullScreen = message.data['fullScreenIntent'] == 'true';

    await showPreviewBriefing(
      title: title,
      body: body,
      fullScreenIntent: fullScreen,
    );
  }

  void _routeToBriefing() {
    final context = nanaNavigatorKey.currentContext;
    if (context == null) return;

    FocusManager.instance.primaryFocus?.unfocus();

    // Add navigation later when your briefing route is finalized.
    // Example:
    // Navigator.of(context).pushNamed('/briefing');
  }
}
