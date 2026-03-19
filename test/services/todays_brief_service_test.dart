import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nana_poc/models/app_user_profile.dart';
import 'package:nana_poc/services/todays_brief_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('loadPreview builds sections for selected topics and keeps stable order', () async {
    final client = MockClient((http.Request request) async {
      final query = request.url.queryParameters['q'] ?? '';
      if (query.startsWith('weather in ')) {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'answer_box': <String, dynamic>{
              'location': 'Austin, TX',
              'temperature': '71',
              'weather': 'Sunny',
              'forecast': <Map<String, dynamic>>[
                <String, dynamic>{'high': '75', 'low': '58'},
              ],
              'hourly_forecast': <Map<String, dynamic>>[
                <String, dynamic>{
                  'time': '9 AM',
                  'temperature': '71',
                  'weather': 'Sunny',
                },
              ],
            },
          }),
          200,
        );
      }

      return http.Response(
        jsonEncode(<String, dynamic>{
          'organic_results': <Map<String, dynamic>>[
            <String, dynamic>{
              'title': 'Helpful result for $query',
              'snippet': 'A calm snippet.',
              'source': 'SerpApi stub',
              'link': 'https://example.com/${Uri.encodeComponent(query)}',
            },
          ],
        }),
        200,
      );
    });

    final service = TodaysBriefService(
      httpClient: client,
      apiKey: 'poc-key',
    );

    final profile = AppUserProfile(
      uid: 'abc',
      firstName: 'Nina',
      locationLabel: 'Austin, TX',
      topics: const <String>['Weather', 'Cozy Games', 'Good News'],
      onboardingComplete: true,
      notificationPreferences: NotificationPreference.defaults(),
    );

    final preview = await service.loadPreview(profile);

    expect(preview.topics, <String>['Weather', 'Good News', 'Cozy Games']);
    expect(preview.sections.map((section) => section.topic), preview.topics);
    expect(preview.sections.first.weather?.location, 'Austin, TX');
    expect(preview.sections[1].items.single.title, contains('good news uplifting stories today'));
    expect(preview.sections[2].items, isNotEmpty);
  });
}
