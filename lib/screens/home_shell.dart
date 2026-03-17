import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_user_profile.dart';
import '../models/briefing_bundle.dart';
import '../repositories/briefing_repository.dart';
import '../repositories/profile_repository.dart';
import '../services/notification_service.dart';
import '../theme/nana_theme.dart';
import 'care_screen.dart';
import 'home_screen.dart';
import 'local_screen.dart';
import 'nourish_screen.dart';
import 'unwind_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.initialProfile,
    required this.profileRepository,
  });

  final AppUserProfile initialProfile;
  final ProfileRepository profileRepository;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final BriefingRepository _briefingRepository = BriefingRepository();

  late AppUserProfile _profile = widget.initialProfile;
  BriefingBundle? _bundle;
  bool _loading = true;
  int _index = 0;
  StreamSubscription<AppUserProfile>? _profileSubscription;

  @override
  void initState() {
    super.initState();
    unawaited(_loadBundle());
    _profileSubscription =
        widget.profileRepository.watchProfile(_profile.uid).listen((profile) {
      if (!mounted) return;
      setState(() => _profile = profile);
    });
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadBundle() async {
    setState(() => _loading = true);
    final bundle = await _briefingRepository.getDailyBriefing(_profile);
    if (!mounted) return;
    setState(() {
      _bundle = bundle;
      _loading = false;
    });
  }

  Future<void> _updateProfile(AppUserProfile profile) async {
    await widget.profileRepository.saveProfile(profile);
    await NotificationService.instance
        .syncDailyBriefSchedules(profile.notificationPreferences);
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    final pages = <Widget>[
      HomeScreen(
        profile: _profile,
        bundle: _bundle,
        loading: _loading,
        onRefresh: _loadBundle,
      ),
      LocalScreen(
        bundle: _bundle,
        loading: _loading,
        onRefresh: _loadBundle,
      ),
      NourishScreen(
        bundle: _bundle,
        loading: _loading,
        onRefresh: _loadBundle,
      ),
      UnwindScreen(
        bundle: _bundle,
        loading: _loading,
        onRefresh: _loadBundle,
      ),
      CareScreen(
        profile: _profile,
        onProfileChanged: _updateProfile,
        onPreviewNotification: () async {
          await NotificationService.instance.showPreviewBriefing(
            title: 'Your NANA briefing is ready',
            body: 'Take a calm look at today’s local weather, recipes, and resets.',
            fullScreenIntent: _profile.notificationPreferences.fullScreenIntent,
          );
        },
      ),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: pages[_index],
      ),
      bottomNavigationBar: NavigationBar(
        height: 76,
        selectedIndex: _index,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        backgroundColor: colors.ricePaper,
        onDestinationSelected: (int value) {
          setState(() => _index = value);
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny_rounded),
            label: 'Local',
          ),
          NavigationDestination(
            icon: Icon(Icons.soup_kitchen_outlined),
            selectedIcon: Icon(Icons.soup_kitchen_rounded),
            label: 'Nourish',
          ),
          NavigationDestination(
            icon: Icon(Icons.spa_outlined),
            selectedIcon: Icon(Icons.spa_rounded),
            label: 'Unwind',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Care',
          ),
        ],
      ),
    );
  }
}
