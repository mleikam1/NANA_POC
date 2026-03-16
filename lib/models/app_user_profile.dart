class AppUserProfile {
  const AppUserProfile({
    required this.uid,
    required this.firstName,
    required this.locationLabel,
    required this.topics,
    required this.onboardingComplete,
    required this.notificationPreferences,
    this.locationLatitude,
    this.locationLongitude,
    this.messagingTokens = const [],
  });

  final String uid;
  final String firstName;
  final String locationLabel;
  // Stored for downstream weather/news personalization (for example, SerpAPI locality).
  final double? locationLatitude;
  final double? locationLongitude;
  final List<String> topics;
  final bool onboardingComplete;
  final NotificationPreference notificationPreferences;
  final List<String> messagingTokens;

  AppUserProfile copyWith({
    String? uid,
    String? firstName,
    String? locationLabel,
    double? locationLatitude,
    double? locationLongitude,
    List<String>? topics,
    bool? onboardingComplete,
    NotificationPreference? notificationPreferences,
    List<String>? messagingTokens,
  }) {
    return AppUserProfile(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      locationLabel: locationLabel ?? this.locationLabel,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      topics: topics ?? this.topics,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      messagingTokens: messagingTokens ?? this.messagingTokens,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'firstName': firstName,
      'locationLabel': locationLabel,
      'locationLatitude': locationLatitude,
      'locationLongitude': locationLongitude,
      'topics': topics,
      'onboardingComplete': onboardingComplete,
      'notificationPreferences': notificationPreferences.toMap(),
      'messagingTokens': messagingTokens,
    };
  }

  factory AppUserProfile.fromMap(Map<String, dynamic> map) {
    return AppUserProfile(
      uid: map['uid'] as String? ?? '',
      firstName: map['firstName'] as String? ?? '',
      locationLabel: map['locationLabel'] as String? ?? '',
      locationLatitude: (map['locationLatitude'] as num?)?.toDouble(),
      locationLongitude: (map['locationLongitude'] as num?)?.toDouble(),
      topics: List<String>.from(map['topics'] as List? ?? const []),
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
      notificationPreferences: NotificationPreference.fromMap(
        Map<String, dynamic>.from(
          map['notificationPreferences'] as Map? ?? const {},
        ),
      ),
      messagingTokens:
          List<String>.from(map['messagingTokens'] as List? ?? const []),
    );
  }
}

class NotificationPreference {
  const NotificationPreference({
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.timeZone,
    required this.fullScreenIntent,
  });

  final bool enabled;
  final int hour;
  final int minute;
  final String timeZone;
  final bool fullScreenIntent;

  NotificationPreference copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    String? timeZone,
    bool? fullScreenIntent,
  }) {
    return NotificationPreference(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      timeZone: timeZone ?? this.timeZone,
      fullScreenIntent: fullScreenIntent ?? this.fullScreenIntent,
    );
  }

  String get formattedTime {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final paddedMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$paddedMinute $period';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enabled': enabled,
      'hour': hour,
      'minute': minute,
      'timeZone': timeZone,
      'fullScreenIntent': fullScreenIntent,
    };
  }

  factory NotificationPreference.fromMap(Map<String, dynamic> map) {
    return NotificationPreference(
      enabled: map['enabled'] as bool? ?? false,
      hour: map['hour'] as int? ?? 8,
      minute: map['minute'] as int? ?? 0,
      timeZone: map['timeZone'] as String? ?? 'America/Chicago',
      fullScreenIntent: map['fullScreenIntent'] as bool? ?? false,
    );
  }

  factory NotificationPreference.defaults() {
    return const NotificationPreference(
      enabled: true,
      hour: 8,
      minute: 0,
      timeZone: 'America/Chicago',
      fullScreenIntent: true,
    );
  }
}
