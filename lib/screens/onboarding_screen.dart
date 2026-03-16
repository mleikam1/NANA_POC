import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../config/app_config.dart';
import '../models/app_user_profile.dart';
import '../theme/nana_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onComplete,
    this.existingProfile,
  });

  final AppUserProfile? existingProfile;
  final Future<void> Function(AppUserProfile profile) onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  late final AnimationController _animationController =
      AnimationController(vsync: this, duration: const Duration(seconds: 10))
        ..repeat();

  final Set<String> _selectedTopics = <String>{};
  bool _notificationEnabled = true;
  bool _fullScreenIntent = true;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _requestingLocation = false;
  String _locationHint = "City or ZIP code";
  double? _selectedLatitude;
  double? _selectedLongitude;

  int _pageIndex = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingProfile;
    if (existing != null) {
      _selectedTopics.addAll(existing.topics);
      _firstNameController.text = existing.firstName;
      _locationController.text = existing.locationLabel;
      _selectedLatitude = existing.locationLatitude;
      _selectedLongitude = existing.locationLongitude;
      _notificationEnabled = existing.notificationPreferences.enabled;
      _fullScreenIntent = existing.notificationPreferences.fullScreenIntent;
      _selectedTime = TimeOfDay(
        hour: existing.notificationPreferences.hour,
        minute: existing.notificationPreferences.minute,
      );
    } else {
      _selectedTopics.addAll(const <String>[
        'Local News',
        'Easy Recipes',
        'Calm Videos',
      ]);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _firstNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _chooseTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (selected != null) {
      setState(() => _selectedTime = selected);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _requestingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationHint = "Enable device location, or type your city manually";
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationHint = "Permission denied. You can type your city manually.";
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 10));
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
        _locationController.text =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _locationHint =
            "Current location saved. You can still edit city or ZIP code anytime.";
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationHint =
              "Couldn't fetch your current location. Enter city or ZIP manually.";
        });
      }
    } finally {
      if (mounted) {
        setState(() => _requestingLocation = false);
      }
    }
  }

  Future<void> _finish() async {
    final firstName = _firstNameController.text.trim();
    final locationLabel = _locationController.text.trim();

    if (firstName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add your first name.')),
      );
      return;
    }

    if (locationLabel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a city or ZIP code for the briefing.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final existingUid = widget.existingProfile?.uid ?? '';
      final profile = AppUserProfile(
        uid: existingUid,
        firstName: firstName,
        locationLabel: locationLabel,
        locationLatitude: _selectedLatitude,
        locationLongitude: _selectedLongitude,
        topics: _selectedTopics.toList()..sort(),
        onboardingComplete: true,
        notificationPreferences: NotificationPreference(
          enabled: _notificationEnabled,
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          timeZone: 'America/Chicago',
          fullScreenIntent: _fullScreenIntent,
        ),
        messagingTokens: widget.existingProfile?.messagingTokens ?? const [],
      );

      await widget.onComplete(profile);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  bool get _isPersonalizationValid {
    return _firstNameController.text.trim().isNotEmpty &&
        _locationController.text.trim().isNotEmpty;
  }

  Widget _buildOrb() {
    final colors = NanaColors.of(context);
    return SizedBox(
      height: 220,
      width: 220,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (_, __) {
          final value = _animationController.value;
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              for (int index = 0; index < 3; index++)
                Transform.rotate(
                  angle: value * math.pi * 2 * (index + 1) / 3,
                  child: Container(
                    width: 180 - (index * 30),
                    height: 180 - (index * 30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: <Color>[
                          colors.skyMist.withValues(alpha: 0.5),
                          colors.forestSage.withValues(alpha: 0.6),
                          colors.sunGlow.withValues(alpha: 0.8),
                        ][index],
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.sunGlow,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                      color: colors.sunGlow.withValues(alpha: 0.28),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _introPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Spacer(),
        Center(child: _buildOrb()),
        const SizedBox(height: 28),
        Text(
          'Meet your calmer daily companion',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 16),
        Text(
          'NANA is designed to lower the noise of the day. Instead of chasing breaking alerts and chaotic feeds, it gives you useful, gentle guidance around your life: weather, local headlines, recipes, and short resets.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 18),
        _FeaturePillRow(
          labels: const <String>[
            'Protective filter',
            'Daily calm briefings',
            'Meaningful utility',
          ],
        ),
        const Spacer(),
      ],
    );
  }

  Widget _topicsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 18),
        Text(
          'What should NANA help with most?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          'Pick the topics that feel most useful right now. You can change them any time later.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AppConfig.defaultTopics.map((String topic) {
            final selected = _selectedTopics.contains(topic);
            return FilterChip(
              label: Text(topic),
              selected: selected,
              onSelected: (bool value) {
                setState(() {
                  if (value) {
                    _selectedTopics.add(topic);
                  } else {
                    _selectedTopics.remove(topic);
                  }
                });
              },
            );
          }).toList(),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _locationPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 18),
        Text(
          "Let's personalize your briefing",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          'Tell us your name and where you are so we can tailor your weather, local news, and welcome experience.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _firstNameController,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'First name',
            prefixIcon: Icon(Icons.sentiment_satisfied_alt_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _locationController,
          onChanged: (_) {
            setState(() {
              _selectedLatitude = null;
              _selectedLongitude = null;
            });
          },
          decoration: InputDecoration(
            hintText: _locationHint,
            prefixIcon: const Icon(Icons.place_outlined),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _requestingLocation ? null : _useCurrentLocation,
          icon: _requestingLocation
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location_rounded),
          label: const Text('Use my current location'),
        ),
        const SizedBox(height: 10),
        Text(
          'Sharing location helps NANA localize weather and nearby headlines. Prefer not to? Enter city or ZIP instead.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const Spacer(),
      ],
    );
  }

  Widget _notificationsPage() {
    final colors = NanaColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 18),
        Text(
          'Choose your daily calm moment',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          'Set the time you want your briefing delivered. For Android, this starter also includes a full-screen-intent preview path for POC testing.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        SwitchListTile.adaptive(
          value: _notificationEnabled,
          contentPadding: EdgeInsets.zero,
          title: const Text('Daily briefing notifications'),
          subtitle: const Text('A scheduled prompt for your daily calm-tech briefing'),
          onChanged: (bool value) => setState(() => _notificationEnabled = value),
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.cardSoft,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Scheduled delivery',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedTime.format(context)} every day',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: _chooseTime,
                child: const Text('Change'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile.adaptive(
          value: _fullScreenIntent,
          contentPadding: EdgeInsets.zero,
          title: const Text('Use Android full-screen style preview'),
          subtitle: const Text(
            'Best for POC testing. Production behavior depends on Android policy and device settings.',
          ),
          onChanged: (bool value) => setState(() => _fullScreenIntent = value),
        ),
        const Spacer(),
      ],
    );
  }

  Future<void> _next() async {
    if (_pageIndex == 2 && !_isPersonalizationValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add your first name and location to continue.'),
        ),
      );
      return;
    }

    if (_pageIndex == 3) {
      await _finish();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    'nana',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  Text(
                    '${_pageIndex + 1}/4',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (_pageIndex + 1) / 4,
                borderRadius: BorderRadius.circular(100),
                minHeight: 6,
                backgroundColor: colors.skyMist.withValues(alpha: 0.22),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (int value) => setState(() => _pageIndex = value),
                  children: <Widget>[
                    _introPage(),
                    _topicsPage(),
                    _locationPage(),
                    _notificationsPage(),
                  ],
                ),
              ),
              Row(
                children: <Widget>[
                  if (_pageIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_pageIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving || (_pageIndex == 2 && !_isPersonalizationValid)
                          ? null
                          : _next,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_pageIndex == 3 ? 'Start NANA' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePillRow extends StatelessWidget {
  const _FeaturePillRow({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: labels.map((String label) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: NanaColors.of(context).cardSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label),
        );
      }).toList(),
    );
  }
}
