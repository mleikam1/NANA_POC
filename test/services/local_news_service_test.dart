import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nana_poc/models/app_user_profile.dart';
import 'package:nana_poc/models/local_news_story.dart';
import 'package:nana_poc/services/local_news_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime fixedNow;
  late AppUserProfile profile;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    fixedNow = DateTime(2026, 3, 18, 12);
    profile = AppUserProfile(
      uid: 'user-1',
      firstName: 'Nana',
      locationLabel: 'Austin, TX, USA',
      locationLatitude: 30.2672,
      locationLongitude: -97.7431,
      topics: const <String>['Local News'],
      onboardingComplete: true,
      notificationPreferences: NotificationPreference.defaults(),
    );
  });

  group('buildQueryFallbackChain', () {
    test('builds location-first query fallbacks in order', () {
      final service = LocalNewsService(
        sharedPreferences: SharedPreferences.getInstance(),
        now: () => fixedNow,
        apiKey: 'test-key',
      );
      const location = LocalNewsLocation(
        label: 'Austin, TX, USA',
        normalizedCacheKey: 'austin_tx_usa',
        city: 'Austin',
        stateOrRegion: 'TX',
        country: 'USA',
        countyOrMetro: 'Travis County',
        latitude: 30.2,
        longitude: -97.7,
      );

      expect(
        service.buildQueryFallbackChain(location),
        <String>[
          'Austin TX local news',
          'Austin news',
          'Travis County news',
          'local news Austin, TX, USA',
        ],
      );
    });
  });

  group('parse + dedupe', () {
    test('parses serp api stories and removes duplicate canonical urls', () {
      final service = LocalNewsService(
        sharedPreferences: SharedPreferences.getInstance(),
        now: () => fixedNow,
        apiKey: 'test-key',
      );

      final storyA = service.parseSerpApiStory(<String, dynamic>{
        'title': 'City council adopts new tree plan',
        'link':
            'https://example.com/article?utm_source=newsletter&utm_medium=email',
        'source': <String, dynamic>{'name': 'Example News'},
        'snippet': 'A new planting plan was approved after months of meetings.',
        'date': '2 hours ago',
      }, 1);
      final storyB = service.parseSerpApiStory(<String, dynamic>{
        'title': 'City council adopts new tree plan',
        'link': 'https://example.com/article',
        'source': 'Example News',
      }, 2);

      final deduped = service.dedupeStories(<LocalNewsStory>[storyA, storyB]);

      expect(deduped, hasLength(1));
      expect(deduped.single.url, 'https://example.com/article');
      expect(deduped.single.relativeTimeLabel, '2 hr ago');
    });
  });

  group('fallback summarization', () {
    test('creates deterministic calm summary when extraction fails', () {
      final service = LocalNewsService(
        sharedPreferences: SharedPreferences.getInstance(),
        now: () => fixedNow,
        apiKey: 'test-key',
      );
      final story = LocalNewsStory(
        id: '1',
        rank: 1,
        title: 'Neighbors open a new weekend market downtown',
        url: 'https://example.com/story',
        source: 'Daily Local',
        snippet: 'The market will feature produce, baked goods, and music on Saturdays.',
        thumbnailUrl: '',
        publishedAt: fixedNow.subtract(const Duration(hours: 3)),
        relativeTimeLabel: '3 hr ago',
        calmHeadline: '',
        bullets: const <String>[],
        readTimeLabel: '',
        extractionFailed: false,
        fromCache: false,
      );

      final headline = service.buildCalmHeadline(story);
      final bullets = service.buildFallbackBullets(story);

      expect(headline, 'A steady local update on Neighbors open a new weekend market downtown.');
      expect(
        bullets,
        <String>[
          'The market will feature produce, baked goods, and music on Saturdays.',
          'Covered by Daily Local shared 3 hr ago.',
        ],
      );
    });
  });

  group('cache behavior', () {
    test('returns cached result on repeated call within ttl', () async {
      var serpRequests = 0;
      final client = MockClient((http.Request request) async {
        if (request.url.host == 'serpapi.com') {
          serpRequests++;
          return http.Response(
            jsonEncode(<String, dynamic>{
              'news_results': List<Map<String, dynamic>>.generate(5, (int index) {
                return <String, dynamic>{
                  'title': 'Story ${index + 1}',
                  'link': 'https://example.com/story-${index + 1}',
                  'source': <String, dynamic>{'name': 'Source ${index + 1}'},
                  'snippet': 'Snippet ${index + 1}',
                  'date': '1 hour ago',
                };
              }),
            }),
            200,
          );
        }
        return http.Response(
          '<html><body><article><p>Paragraph one with useful local context for this story.</p>'
          '<p>Paragraph two keeps the update grounded and calm for readers.</p></article></body></html>',
          200,
        );
      });
      final service = LocalNewsService(
        httpClient: client,
        sharedPreferences: SharedPreferences.getInstance(),
        now: () => fixedNow,
        apiKey: 'test-key',
      );

      final first = await service.fetchLocalNews(profile);
      final second = await service.fetchLocalNews(profile);

      expect(first.stories, hasLength(5));
      expect(second.usedCache, isFalse);
      expect(serpRequests, 1);
    });

    test('prefers stale cache when refresh fails', () async {
      final prefs = await SharedPreferences.getInstance();
      final staleResult = LocalNewsResult(
        location: const LocalNewsLocation(
          label: 'Austin, TX, USA',
          normalizedCacheKey: 'austin_tx_usa',
          city: 'Austin',
          stateOrRegion: 'TX',
          country: 'USA',
          countyOrMetro: '',
          latitude: 30.2,
          longitude: -97.7,
        ),
        stories: const <LocalNewsStory>[
          LocalNewsStory(
            id: '1',
            rank: 1,
            title: 'Saved story',
            url: 'https://example.com/saved',
            source: 'Saved Source',
            snippet: 'Saved snippet',
            thumbnailUrl: '',
            publishedAt: null,
            relativeTimeLabel: 'Recently',
            calmHeadline: 'A steady saved update.',
            bullets: <String>['Saved bullet one.', 'Saved bullet two.'],
            readTimeLabel: 'Quick update',
            extractionFailed: false,
            fromCache: false,
          ),
        ],
        generatedAt: fixedNow.subtract(const Duration(hours: 2)),
        isStale: false,
        usedCache: false,
        isPartial: false,
        errorMessage: null,
      );
      await prefs.setString(
        'local_news_result_v1_austin_tx_usa',
        jsonEncode(staleResult.toMap()),
      );

      final service = LocalNewsService(
        httpClient: MockClient((http.Request request) async {
          return http.Response('error', 500);
        }),
        sharedPreferences: Future<SharedPreferences>.value(prefs),
        now: () => fixedNow,
        apiKey: 'test-key',
      );

      final result = await service.fetchLocalNews(profile, forceRefresh: true);

      expect(result.usedCache, isTrue);
      expect(result.isStale, isTrue);
      expect(result.stories.single.fromCache, isTrue);
    });
  });
}
