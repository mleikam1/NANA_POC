import 'package:shared_preferences/shared_preferences.dart';

import '../models/onboarding_topic.dart';

class TopicPreferencesRepository {
  TopicPreferencesRepository({
    Future<SharedPreferences>? sharedPreferences,
  }) : _sharedPreferencesFuture =
            sharedPreferences ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _sharedPreferencesFuture;

  static const String _selectedTopicsKey = 'selected_onboarding_topics_v1';

  Future<List<OnboardingTopic>> readSelectedTopics() async {
    final prefs = await _sharedPreferencesFuture;
    final stored = prefs.getStringList(_selectedTopicsKey) ?? const <String>[];
    return stabilizeTopics(stored);
  }

  Future<List<String>> resolveSelectedTopics(List<String> profileTopics) async {
    final stored = await readSelectedTopics();
    if (stored.isNotEmpty) {
      return stored.map((OnboardingTopic topic) => topic.label).toList(
        growable: false,
      );
    }
    return stabilizeTopicLabels(profileTopics);
  }

  Future<void> saveSelectedTopics(Iterable<OnboardingTopic> topics) async {
    final prefs = await _sharedPreferencesFuture;
    await prefs.setStringList(
      _selectedTopicsKey,
      stabilizeTopics(topics)
          .map((OnboardingTopic topic) => topic.storageKey)
          .toList(growable: false),
    );
  }

  static List<String> stabilizeTopicLabels(Iterable<String> topics) {
    return stabilizeTopics(topics)
        .map((OnboardingTopic topic) => topic.label)
        .toList(growable: false);
  }

  static List<OnboardingTopic> stabilizeTopics(Iterable<dynamic> topics) {
    final ordered = <OnboardingTopic>[];
    final seen = <OnboardingTopic>{};

    for (final topic in topics) {
      final OnboardingTopic? resolved;
      if (topic is OnboardingTopic) {
        resolved = topic;
      } else if (topic is String) {
        resolved = OnboardingTopic.fromStoredValue(topic.trim());
      } else {
        resolved = null;
      }

      if (resolved == null || !seen.add(resolved)) {
        continue;
      }
      ordered.add(resolved);
    }

    return ordered;
  }
}
