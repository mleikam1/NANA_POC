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
    this.briefSchedules = const <String, BriefSchedule>{},
  });

  final bool enabled;
  final int hour;
  final int minute;
  final String timeZone;
  final bool fullScreenIntent;
  final Map<String, BriefSchedule> briefSchedules;

  static const String defaultTimeZone = 'America/Chicago';

  NotificationPreference copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    String? timeZone,
    bool? fullScreenIntent,
    Map<String, BriefSchedule>? briefSchedules,
  }) {
    return NotificationPreference(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      timeZone: timeZone ?? this.timeZone,
      fullScreenIntent: fullScreenIntent ?? this.fullScreenIntent,
      briefSchedules: briefSchedules ?? this.briefSchedules,
    );
  }

  Map<String, BriefSchedule> get resolvedBriefSchedules {
    if (briefSchedules.isEmpty) {
      return defaultBriefSchedules(
        morningEnabled: enabled,
        morningHour: hour,
        morningMinute: minute,
        eveningEnabled: false,
      );
    }

    final merged = defaultBriefSchedules();
    for (final entry in briefSchedules.entries) {
      merged[entry.key] = entry.value;
    }
    return merged;
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
      'briefSchedules': <String, dynamic>{
        for (final entry in resolvedBriefSchedules.entries)
          entry.key: entry.value.toMap(),
      },
    };
  }

  factory NotificationPreference.fromMap(Map<String, dynamic> map) {
    return NotificationPreference(
      enabled: map['enabled'] as bool? ?? false,
      hour: map['hour'] as int? ?? 8,
      minute: map['minute'] as int? ?? 0,
      timeZone: map['timeZone'] as String? ?? defaultTimeZone,
      fullScreenIntent: map['fullScreenIntent'] as bool? ?? false,
      briefSchedules: _parseBriefSchedules(
        Map<String, dynamic>.from(
          map['briefSchedules'] as Map? ?? const <String, dynamic>{},
        ),
      ),
    );
  }

  factory NotificationPreference.defaults() {
    return NotificationPreference(
      enabled: true,
      hour: 8,
      minute: 0,
      timeZone: defaultTimeZone,
      fullScreenIntent: true,
      briefSchedules: defaultBriefSchedules(),
    );
  }

  static Map<String, BriefSchedule> defaultBriefSchedules({
    bool morningEnabled = true,
    int morningHour = 8,
    int morningMinute = 0,
    bool eveningEnabled = true,
  }) {
    return <String, BriefSchedule>{
      BriefDaypart.morning.key: BriefSchedule(
        daypart: BriefDaypart.morning,
        enabled: morningEnabled,
        hour: morningHour,
        minute: morningMinute,
      ),
      BriefDaypart.afternoon.key: const BriefSchedule(
        daypart: BriefDaypart.afternoon,
        enabled: false,
        hour: 12,
        minute: 30,
      ),
      BriefDaypart.evening.key: BriefSchedule(
        daypart: BriefDaypart.evening,
        enabled: eveningEnabled,
        hour: 19,
        minute: 0,
      ),
      BriefDaypart.night.key: const BriefSchedule(
        daypart: BriefDaypart.night,
        enabled: false,
        hour: 22,
        minute: 0,
      ),
    };
  }

  static Map<String, BriefSchedule> _parseBriefSchedules(
    Map<String, dynamic> map,
  ) {
    final parsed = <String, BriefSchedule>{};
    for (final entry in map.entries) {
      final daypart = BriefDaypartX.fromKey(entry.key);
      if (daypart == null) {
        continue;
      }
      final value = entry.value;
      if (value is! Map) {
        continue;
      }
      parsed[entry.key] = BriefSchedule.fromMap(
        daypart,
        Map<String, dynamic>.from(value as Map),
      );
    }
    return parsed;
  }
}

enum BriefDaypart {
  morning,
  afternoon,
  evening,
  night,
}

extension BriefDaypartX on BriefDaypart {
  String get key => name;

  String get label {
    switch (this) {
      case BriefDaypart.morning:
        return 'Morning brief';
      case BriefDaypart.afternoon:
        return 'Afternoon brief';
      case BriefDaypart.evening:
        return 'Evening brief';
      case BriefDaypart.night:
        return 'Night brief';
    }
  }

  int get notificationId {
    switch (this) {
      case BriefDaypart.morning:
        return 8101;
      case BriefDaypart.afternoon:
        return 8102;
      case BriefDaypart.evening:
        return 8103;
      case BriefDaypart.night:
        return 8104;
    }
  }

  static BriefDaypart? fromKey(String key) {
    for (final daypart in BriefDaypart.values) {
      if (daypart.key == key) {
        return daypart;
      }
    }
    return null;
  }
}

class BriefSchedule {
  const BriefSchedule({
    required this.daypart,
    required this.enabled,
    required this.hour,
    required this.minute,
    this.userSelectedTime = false,
  });

  final BriefDaypart daypart;
  final bool enabled;
  final int hour;
  final int minute;
  final bool userSelectedTime;

  BriefSchedule copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    bool? userSelectedTime,
  }) {
    return BriefSchedule(
      daypart: daypart,
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      userSelectedTime: userSelectedTime ?? this.userSelectedTime,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enabled': enabled,
      'hour': hour,
      'minute': minute,
      'userSelectedTime': userSelectedTime,
    };
  }

  factory BriefSchedule.fromMap(BriefDaypart daypart, Map<String, dynamic> map) {
    final defaults = NotificationPreference.defaultBriefSchedules()[daypart.key]!;
    return BriefSchedule(
      daypart: daypart,
      enabled: map['enabled'] as bool? ?? defaults.enabled,
      hour: map['hour'] as int? ?? defaults.hour,
      minute: map['minute'] as int? ?? defaults.minute,
      userSelectedTime: map['userSelectedTime'] as bool? ?? false,
    );
  }
}
