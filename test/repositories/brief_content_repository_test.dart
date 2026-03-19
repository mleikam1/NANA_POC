import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nana_poc/models/app_user_profile.dart';
import 'package:nana_poc/models/brief_content.dart';
import 'package:nana_poc/models/onboarding_topic.dart';
import 'package:nana_poc/repositories/brief_content_repository.dart';
import 'package:nana_poc/services/brief_content_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('BriefContentService topicQueryMapping', () {
    test('uses precise location for local topics when available', () {
      final service = BriefContentService(apiKey: 'poc-key');
      const location = BriefLocationContext(
        label: 'Austin, TX',
        city: 'Austin',
        stateOrRegion: 'TX',
        country: 'United States',
        normalizedCacheKey: 'austin_tx',
        latitude: null,
        longitude: null,
        hasPreciseLocation: true,
      );

      final mapping = service.topicQueryMapping(
        OnboardingTopic.communityEvents,
        location,
      );

      expect(mapping.query, 'community events near Austin, TX');
      expect(mapping.locationOverride, 'Austin, TX');
    });

    test('falls back to U.S. query when location is unavailable', () {
      final service = BriefContentService(apiKey: 'poc-key');
      const location = BriefLocationContext(
        label: 'United States',
        city: '',
        stateOrRegion: '',
        country: '',
        normalizedCacheKey: 'united_states',
        latitude: null,
        longitude: null,
        hasPreciseLocation: false,
      );

      final weatherMapping = service.topicQueryMapping(
        OnboardingTopic.weather,
        location,
      );
      final localNewsMapping = service.topicQueryMapping(
        OnboardingTopic.localNews,
        location,
      );

      expect(weatherMapping.query, 'weather in United States');
      expect(localNewsMapping.query, 'local news United States');
      expect(localNewsMapping.locationOverride, isNull);
    });
  });

  test('loadBriefPage fails per section and preserves successful sections', () async {
    final requestedQueries = <String>[];
    final client = MockClient((http.Request request) async {
      final query = request.url.queryParameters['q'] ?? '';
      requestedQueries.add(query);

      if (query == 'weather in United States') {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'answer_box': <String, dynamic>{
              'location': 'United States',
              'temperature': '68',
              'weather': 'Partly cloudy',
              'forecast': <Map<String, dynamic>>[
                <String, dynamic>{'high': '72', 'low': '56'},
              ],
              'hourly_forecast': <Map<String, dynamic>>[
                <String, dynamic>{
                  'time': '10 AM',
                  'temperature': '68',
                  'weather': 'Partly cloudy',
                },
              ],
            },
          }),
          200,
        );
      }

      if (query == 'positive uplifting good news today') {
        return http.Response('server error', 500);
      }

      return http.Response(
        jsonEncode(<String, dynamic>{
          'organic_results': <Map<String, dynamic>>[
            <String, dynamic>{
              'title': 'Fallback result for $query',
              'snippet': 'A calm result.',
              'source': 'SerpApi stub',
              'link': 'https://example.com/${Uri.encodeComponent(query)}',
            },
          ],
        }),
        200,
      );
    });

    final repository = BriefContentRepository(
      httpClient: client,
      apiKey: 'poc-key',
    );

    final profile = AppUserProfile(
      uid: 'user-1',
      firstName: 'Nina',
      locationLabel: '',
      topics: const <String>[],
      onboardingComplete: true,
      notificationPreferences: NotificationPreference.defaults(),
    );

    final page = await repository.loadBriefPage(
      profile,
      selectedTopics: const <OnboardingTopic>[
        OnboardingTopic.weather,
        OnboardingTopic.goodNews,
        OnboardingTopic.cozyGames,
      ],
    );

    expect(page.sections, hasLength(3));
    expect(page.sections[0].topic.topic, OnboardingTopic.weather);
    expect(page.sections[0].state, BriefSectionLoadState.ready);
    expect(page.sections[0].summary, contains('United States'));

    expect(page.sections[1].topic.topic, OnboardingTopic.goodNews);
    expect(page.sections[1].state, BriefSectionLoadState.error);
    expect(page.sections[1].items, isEmpty);

    expect(page.sections[2].topic.topic, OnboardingTopic.cozyGames);
    expect(page.sections[2].state, BriefSectionLoadState.ready);
    expect(page.sections[2].items, isNotEmpty);

    expect(requestedQueries, contains('weather in United States'));
    expect(requestedQueries, contains('positive uplifting good news today'));
  });
}
