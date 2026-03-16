import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../app.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

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
    final body = message.notification?.body ??
        'A calmer daily summary is waiting for you.';
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