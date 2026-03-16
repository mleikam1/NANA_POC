import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('BG: Firebase initialized for background message');
  } catch (e, st) {
    debugPrint('BG: Firebase init failed: $e');
    debugPrint('$st');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('MAIN: Widgets binding initialized');

  String? startupError;

  try {
    debugPrint('MAIN: Starting Firebase.initializeApp...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 12));
    debugPrint('MAIN: Firebase initialized');

    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );
    debugPrint('MAIN: Background message handler registered');

    debugPrint('MAIN: Starting NotificationService.initialize...');
    await NotificationService.instance
        .initialize()
        .timeout(const Duration(seconds: 8));
    debugPrint('MAIN: Notification service initialized');
  } catch (e, st) {
    startupError = e.toString();
    debugPrint('MAIN: Startup failed: $e');
    debugPrint('$st');
  }

  debugPrint('MAIN: Calling runApp');
  runApp(NanaApp(startupErrorMessage: startupError));
}