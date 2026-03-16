import 'package:flutter/material.dart';

import '../models/app_user_profile.dart';
import '../utils/location_label_helper.dart';
import '../services/notification_service.dart';

class CareScreen extends StatefulWidget {
  const CareScreen({
    super.key,
    required this.profile,
    required this.onProfileChanged,
    required this.onPreviewNotification,
  });

  final AppUserProfile profile;
  final Future<void> Function(AppUserProfile profile) onProfileChanged;
  final Future<void> Function() onPreviewNotification;

  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen> {
  late final TextEditingController _locationController = TextEditingController(
    text: LocationLabelHelper.bestLabelFromProfile(
      locationLabel: widget.profile.locationLabel,
      latitude: widget.profile.locationLatitude,
      longitude: widget.profile.locationLongitude,
    ),
  );

  late bool _enabled = widget.profile.notificationPreferences.enabled;
  late bool _fullScreenIntent =
      widget.profile.notificationPreferences.fullScreenIntent;
  late TimeOfDay _time = TimeOfDay(
    hour: widget.profile.notificationPreferences.hour,
    minute: widget.profile.notificationPreferences.minute,
  );

  bool _saving = false;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final selection = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (selection != null) {
      setState(() => _time = selection);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final profile = widget.profile.copyWith(
        locationLabel: _locationController.text.trim(),
        notificationPreferences: widget.profile.notificationPreferences.copyWith(
          enabled: _enabled,
          hour: _time.hour,
          minute: _time.minute,
          fullScreenIntent: _fullScreenIntent,
        ),
      );
      await widget.onProfileChanged(profile);

      if (_fullScreenIntent) {
        await NotificationService.instance.requestFullScreenPermission();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NANA care settings saved.')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topics = widget.profile.topics.join(' • ');
    return Scaffold(
      appBar: AppBar(title: const Text('Care')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: <Widget>[
          Text(
            'Preferences',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location label',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Your topics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(topics.isEmpty ? 'No topics selected yet.' : topics),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SwitchListTile.adaptive(
            value: _enabled,
            title: const Text('Daily briefing schedule'),
            subtitle: const Text('Turn on scheduled prompts for your calm-tech briefing'),
            onChanged: (bool value) => setState(() => _enabled = value),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Delivery time'),
            subtitle: Text(_time.format(context)),
            trailing: OutlinedButton(
              onPressed: _selectTime,
              child: const Text('Change'),
            ),
          ),
          SwitchListTile.adaptive(
            value: _fullScreenIntent,
            title: const Text('Android full-screen preview path'),
            subtitle: const Text(
              'Useful for POC testing. Final production behavior depends on Android policies.',
            ),
            onChanged: (bool value) => setState(() => _fullScreenIntent = value),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: widget.onPreviewNotification,
            child: const Text('Preview briefing notification'),
          ),
          const SizedBox(height: 12),
          Text(
            'Note: For production, daily unlock-style experiences may need to be implemented as alarm-like reminders rather than assuming unrestricted full-screen lockscreen launches.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save settings'),
          ),
        ],
      ),
    );
  }
}
