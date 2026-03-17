import 'dart:async';

import 'package:flutter/material.dart';

import 'repositories/profile_repository.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'theme/nana_theme.dart';

final GlobalKey<NavigatorState> nanaNavigatorKey = GlobalKey<NavigatorState>();

class NanaApp extends StatelessWidget {
  const NanaApp({
    super.key,
    this.startupErrorMessage,
  });

  final String? startupErrorMessage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NANA',
      debugShowCheckedModeBanner: false,
      navigatorKey: nanaNavigatorKey,
      theme: NanaTheme.lightTheme,
      home: startupErrorMessage == null
          ? const SessionGate()
          : SplashScreen(
        subtitle:
        'NANA hit a startup issue before loading.\n\n$startupErrorMessage',
      ),
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  final AuthService _authService = AuthService();
  final ProfileRepository _profileRepository = ProfileRepository();

  bool _loading = true;
  String? _error;
  AppUserProfile? _profile;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      debugPrint('SESSION: Ensuring user is signed in...');
      final user = await _authService.ensureSignedIn();
      debugPrint('SESSION: Signed in as ${user.uid}');

      debugPrint('SESSION: Loading/creating user profile...');
      final profile = await _profileRepository.getOrCreateProfile(user.uid);
      debugPrint('SESSION: Profile ready');

      final token = await NotificationService.instance.getFcmToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('SESSION: Saving FCM token...');
        await _profileRepository.saveMessagingToken(uid: user.uid, token: token);
      }

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });

      unawaited(_repairCoordinateLocationLabel(profile));

      await NotificationService.instance.bindForegroundNavigation();
    } catch (error, st) {
      debugPrint('SESSION: Bootstrap failed: $error');
      debugPrint('$st');

      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }


  Future<void> _repairCoordinateLocationLabel(AppUserProfile profile) async {
    final normalized =
        await _profileRepository.normalizeLocationLabelIfNeeded(profile);
    if (!mounted || normalized.uid != profile.uid) {
      return;
    }
    if (normalized.locationLabel != profile.locationLabel) {
      setState(() => _profile = normalized);
    }
  }

  Future<void> _handleOnboardingComplete(AppUserProfile profile) async {
    await _profileRepository.saveProfile(profile);
    try {
      await NotificationService.instance
          .syncDailyBriefSchedules(profile.notificationPreferences);
    } catch (error, st) {
      debugPrint(
        'ONBOARDING: Notification schedule sync failed, continuing into app: $error',
      );
      debugPrint('$st');
    }
    if (!mounted) return;
    setState(() {
      _profile = profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SplashScreen();
    }

    if (_error != null) {
      return SplashScreen(
        subtitle: 'NANA could not finish setup.\n\n$_error',
      );
    }

    final profile = _profile;
    if (profile == null || !profile.onboardingComplete) {
      return OnboardingScreen(
        existingProfile: profile,
        onComplete: _handleOnboardingComplete,
      );
    }

    return HomeShell(
      initialProfile: profile,
      profileRepository: _profileRepository,
    );
  }
}
