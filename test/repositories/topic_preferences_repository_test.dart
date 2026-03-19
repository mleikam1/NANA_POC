import 'package:flutter_test/flutter_test.dart';
import 'package:nana_poc/repositories/topic_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('stabilizeTopics keeps onboarding order and removes unknown topics', () {
    final topics = TopicPreferencesRepository.stabilizeTopics(const <String>[
      'Good News',
      'Unknown',
      'Local News',
      'Cozy Games',
    ]);

    expect(topics, <String>['Local News', 'Good News', 'Cozy Games']);
  });

  test('saveSelectedTopics persists stable topic order', () async {
    final repository = TopicPreferencesRepository(
      sharedPreferences: SharedPreferences.getInstance(),
    );

    await repository.saveSelectedTopics(const <String>[
      'Cozy Games',
      'Local News',
      'Good News',
    ]);

    expect(
      await repository.readSelectedTopics(),
      <String>['Local News', 'Good News', 'Cozy Games'],
    );
  });
}
