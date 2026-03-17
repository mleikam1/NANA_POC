import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
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
      'NANA Briefings',
      description: 'Daily calm-tech briefing notifications',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

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
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestFullScreenIntentPermission();
  }

  Future<void> syncDailyBriefSchedules(NotificationPreference preference) async {
    for (final daypart in BriefDaypart.values) {
      await _localNotifications.cancel(daypart.notificationId);
    }

    if (!preference.enabled) {
      return;
    }

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
      await _localNotifications.zonedSchedule(
        id: daypart.notificationId,
        title: 'Your ${daypart.label.toLowerCase()} is ready',
        body: 'Take a gentle pause with your NANA briefing.',
        scheduledDate: next,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'nana_briefing_channel',
            'NANA Briefings',
            channelDescription: 'Daily calm-tech briefing notifications',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: preference.fullScreenIntent,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'briefing_${daypart.key}',
      );
    }
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
          'NANA Briefings',
          channelDescription: 'Daily calm-tech briefing notifications',
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
    final title = message.notification?.title ?? 'Your NANA briefing is ready';
    final body =
        message.notification?.body ?? 'A calmer daily summary is waiting for you.';
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
