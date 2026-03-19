import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class TopicPreferencesRepository {
  TopicPreferencesRepository({
    Future<SharedPreferences>? sharedPreferences,
  }) : _sharedPreferencesFuture =
            sharedPreferences ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _sharedPreferencesFuture;

  static const String _selectedTopicsKey = 'selected_onboarding_topics_v1';

  Future<List<String>> readSelectedTopics() async {
    final prefs = await _sharedPreferencesFuture;
    final stored = prefs.getStringList(_selectedTopicsKey) ?? const <String>[];
    return stabilizeTopics(stored);
  }

  Future<List<String>> resolveSelectedTopics(List<String> profileTopics) async {
    final stored = await readSelectedTopics();
    if (stored.isNotEmpty) {
      return stored;
    }
    return stabilizeTopics(profileTopics);
  }

  Future<void> saveSelectedTopics(Iterable<String> topics) async {
    final prefs = await _sharedPreferencesFuture;
    await prefs.setStringList(_selectedTopicsKey, stabilizeTopics(topics));
  }

  static List<String> stabilizeTopics(Iterable<String> topics) {
    final selected = topics.map((String topic) => topic.trim()).toSet();
    return AppConfig.defaultTopics
        .where((String topic) => selected.contains(topic))
        .toList(growable: false);
  }
}
