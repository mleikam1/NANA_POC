import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../data/cozy_games_curated_cards.dart';
import '../models/app_user_profile.dart';
import '../models/brief_content.dart';
import '../models/local_news_story.dart';
import '../models/onboarding_topic.dart';
import '../models/recipe_result.dart';
import '../utils/location_label_helper.dart';
import 'local_news_service.dart';
import 'recipes_service.dart';

class BriefContentException implements Exception {
  const BriefContentException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BriefContentService {
  BriefContentService({
    http.Client? httpClient,
    LocalNewsService? localNewsService,
    RecipesService? recipesService,
    DateTime Function()? now,
    String? apiKey,
  })  : _httpClient = httpClient ?? http.Client(),
        _localNewsService = localNewsService,
        _recipesService = recipesService,
        _now = now ?? DateTime.now,
        _apiKey = apiKey;

  final http.Client _httpClient;
  final LocalNewsService? _localNewsService;
  final RecipesService? _recipesService;
  final DateTime Function() _now;
  final String? _apiKey;

  static const String _serpApiBaseUrl = 'https://serpapi.com/search.json';
  static const Duration _requestTimeout = Duration(seconds: 10);
  static const int _defaultItemLimit = 3;

  Future<BriefLocationContext> resolveLocationContext(
    AppUserProfile profile,
  ) async {
    final resolved = await (_localNewsService ?? LocalNewsService()).resolveLocation(
      profile,
    );
    final fallbackLabel = LocationLabelHelper.bestLabelFromProfile(
      locationLabel: profile.locationLabel,
      latitude: profile.locationLatitude,
      longitude: profile.locationLongitude,
    );
    final locationLabel = resolved.label.isNotEmpty
        ? resolved.label
        : (fallbackLabel.isNotEmpty ? fallbackLabel : 'United States');

    return BriefLocationContext(
      label: locationLabel,
      city: resolved.city,
      stateOrRegion: resolved.stateOrRegion,
      country: resolved.country,
      normalizedCacheKey: resolved.normalizedCacheKey.isNotEmpty
          ? resolved.normalizedCacheKey
          : 'united_states',
      latitude: resolved.latitude,
      longitude: resolved.longitude,
      hasPreciseLocation: resolved.city.isNotEmpty || resolved.stateOrRegion.isNotEmpty,
    );
  }

  Future<BriefSection> fetchSection({
    required SelectedBriefTopic topic,
    required AppUserProfile profile,
    required BriefLocationContext location,
    bool forceRefresh = false,
  }) async {
    switch (topic.topic) {
      case OnboardingTopic.localNews:
        return _buildLocalNewsSection(topic, profile, location, forceRefresh);
      case OnboardingTopic.easyRecipes:
        return _buildRecipesSection(topic, forceRefresh);
      case OnboardingTopic.calmVideos:
        return _buildSerpRoundupSection(
          topic: topic,
          kind: BriefSectionKind.videos,
          eyebrow: 'A gentler scroll',
          title: 'Calm Videos',
          description: 'Short breathing, stretching, and meditation picks.',
          mapping: topicQueryMapping(topic.topic, location),
          responseKeys: const <String>['video_results', 'organic_results'],
          itemLimit: 3,
          forceRefresh: forceRefresh,
        );
      case OnboardingTopic.weather:
        return _buildWeatherSection(topic, location, forceRefresh);
      case OnboardingTopic.familySavings:
        return _buildSerpRoundupSection(
          topic: topic,
          kind: BriefSectionKind.roundup,
          eyebrow: 'Useful little wins',
          title: 'Family Savings',
          description: 'Deals, coupons, and practical ways to stretch the week.',
          mapping: topicQueryMapping(topic.topic, location),
          responseKeys: const <String>['organic_results'],
          itemLimit: 3,
          forceRefresh: forceRefresh,
        );
      case OnboardingTopic.goodNews:
        return _buildSerpRoundupSection(
          topic: topic,
          kind: BriefSectionKind.roundup,
          eyebrow: 'A brighter note',
          title: 'Good News',
          description: 'Positive stories chosen to keep the brief light.',
          mapping: topicQueryMapping(topic.topic, location),
          responseKeys: const <String>['news_results', 'organic_results'],
          itemLimit: 3,
          forceRefresh: forceRefresh,
        );
      case OnboardingTopic.cozyGames:
        return _buildCozyGamesSection(topic);
      case OnboardingTopic.nostalgia:
        return _buildSerpRoundupSection(
          topic: topic,
          kind: BriefSectionKind.roundup,
          eyebrow: 'Comfortingly familiar',
          title: 'Nostalgia',
          description: 'Throwback picks with a warm, feel-good tone.',
          mapping: topicQueryMapping(topic.topic, location),
          responseKeys: const <String>['organic_results', 'news_results'],
          itemLimit: 3,
          forceRefresh: forceRefresh,
        );
      case OnboardingTopic.homeRoutines:
        return _buildSerpRoundupSection(
          topic: topic,
          kind: BriefSectionKind.roundup,
          eyebrow: 'Gentle structure',
          title: 'Home Routines',
          description: 'Easy reset ideas that feel doable on a busy day.',
          mapping: topicQueryMapping(topic.topic, location),
          responseKeys: const <String>['organic_results'],
          itemLimit: 3,
          forceRefresh: forceRefresh,
        );
      case OnboardingTopic.communityEvents:
        return _buildSerpRoundupSection(
          topic: topic,
          kind: BriefSectionKind.events,
          eyebrow: 'Around you',
          title: 'Community Events',
          description: 'Nearby happenings with a low-pressure, family-friendly feel.',
          mapping: topicQueryMapping(topic.topic, location),
          responseKeys: const <String>['events_results', 'organic_results'],
          itemLimit: 3,
          forceRefresh: forceRefresh,
        );
    }
  }

  BriefTopicQueryMapping topicQueryMapping(
    OnboardingTopic topic,
    BriefLocationContext location,
  ) {
    final localized = location.hasPreciseLocation
        ? location.cityAndRegionLabel
        : 'United States';

    switch (topic) {
      case OnboardingTopic.localNews:
        return BriefTopicQueryMapping(
          query: location.hasPreciseLocation
              ? '${location.cityAndRegionLabel} local news'
              : 'local news United States',
          fallbackQuery: 'community news United States',
          locationOverride: location.hasPreciseLocation ? location.label : null,
        );
      case OnboardingTopic.easyRecipes:
        return const BriefTopicQueryMapping(
          query: 'easy recipes quick dinner snack ideas',
          fallbackQuery: 'easy family recipes weeknight meals',
        );
      case OnboardingTopic.calmVideos:
        return const BriefTopicQueryMapping(
          query: 'calming breathing meditation stretching videos',
          fallbackQuery: '5 minute breathing exercise meditation videos',
          extraParameters: <String, String>{'tbm': 'vid'},
        );
      case OnboardingTopic.weather:
        return BriefTopicQueryMapping(
          query: 'weather in $localized',
          fallbackQuery: 'weather in United States',
          locationOverride: location.hasPreciseLocation ? location.label : null,
        );
      case OnboardingTopic.familySavings:
        return BriefTopicQueryMapping(
          query: 'family savings deals coupons grocery budget $localized',
          fallbackQuery: 'family savings deals coupons this week',
        );
      case OnboardingTopic.goodNews:
        return const BriefTopicQueryMapping(
          query: 'positive uplifting good news today',
          fallbackQuery: 'feel good news uplifting stories',
        );
      case OnboardingTopic.cozyGames:
        return const BriefTopicQueryMapping(query: 'cozy games');
      case OnboardingTopic.nostalgia:
        return const BriefTopicQueryMapping(
          query: 'nostalgia throwback feel good stories pop culture',
          fallbackQuery: 'throwback nostalgia feel good reads',
        );
      case OnboardingTopic.homeRoutines:
        return const BriefTopicQueryMapping(
          query: 'easy home reset routine habit checklist',
          fallbackQuery: 'simple home routines low effort habits',
        );
      case OnboardingTopic.communityEvents:
        return BriefTopicQueryMapping(
          query: location.hasPreciseLocation
              ? 'community events near ${location.cityAndRegionLabel}'
              : 'community events near United States',
          fallbackQuery: 'free family friendly events this weekend United States',
          locationOverride: location.hasPreciseLocation ? location.label : null,
        );
    }
  }

  Future<BriefSection> _buildLocalNewsSection(
    SelectedBriefTopic topic,
    AppUserProfile profile,
    BriefLocationContext location,
    bool forceRefresh,
  ) async {
    if (!location.hasPreciseLocation) {
      return _buildSerpRoundupSection(
        topic: topic,
        kind: BriefSectionKind.roundup,
        eyebrow: 'Close to home',
        title: 'Local News',
        description: 'A calmer pass through nearby headlines.',
        mapping: topicQueryMapping(topic.topic, location),
        responseKeys: const <String>['news_results', 'organic_results'],
        itemLimit: 3,
        forceRefresh: forceRefresh,
      );
    }

    final result = await (_localNewsService ?? LocalNewsService()).fetchLocalNews(
      profile,
      forceRefresh: forceRefresh,
    );

    final items = result.stories.take(_defaultItemLimit).map((LocalNewsStory story) {
      return BriefContentItem(
        id: story.id,
        title: story.title,
        subtitle: story.calmHeadline.isNotEmpty ? story.calmHeadline : story.snippet,
        source: story.source.isNotEmpty ? story.source : 'Local news',
        badge: story.readTimeLabel.isNotEmpty ? story.readTimeLabel : 'Local',
        link: story.url,
        imageUrl: story.thumbnailUrl.isNotEmpty ? story.thumbnailUrl : null,
        metadata: <String, String>{
          if (story.relativeTimeLabel.isNotEmpty) 'Updated': story.relativeTimeLabel,
          if (story.bullets.isNotEmpty) 'Highlights': story.bullets.join(' • '),
        },
      );
    }).toList(growable: false);

    return BriefSection(
      topic: topic,
      kind: BriefSectionKind.roundup,
      state: BriefSectionLoadState.ready,
      eyebrow: 'Close to home',
      title: result.location.label.isNotEmpty
          ? 'Local News for ${result.location.label}'
          : 'Local News',
      description: 'A calmer pass through nearby headlines.',
      summary: result.location.label.isNotEmpty ? 'Focused on ${result.location.label}.' : null,
      items: items,
      generatedAt: result.generatedAt,
      errorMessage: result.errorMessage,
      queryUsed: result.location.label,
      isFromCache: result.usedCache,
      isStale: result.isStale,
    );
  }

  Future<BriefSection> _buildRecipesSection(
    SelectedBriefTopic topic,
    bool forceRefresh,
  ) async {
    final result = await (_recipesService ?? RecipesService()).fetchRecipes(
      forceRefresh: forceRefresh,
    );
    final items = result.recipes.take(_defaultItemLimit).map((RecipeCard recipe) {
      return BriefContentItem(
        id: recipe.id,
        title: recipe.title,
        subtitle: recipe.ingredients.take(3).join(' • '),
        source: recipe.source.isNotEmpty ? recipe.source : 'Recipes',
        badge: recipe.totalTime.isNotEmpty ? recipe.totalTime : 'Easy',
        link: recipe.link,
        imageUrl: recipe.thumbnailUrl.isNotEmpty ? recipe.thumbnailUrl : null,
        metadata: <String, String>{
          if (recipe.rating != null) 'Rating': recipe.rating!.toStringAsFixed(1),
          if (recipe.totalIngredients != null)
            'Ingredients': recipe.totalIngredients.toString(),
        },
      );
    }).toList(growable: false);

    return BriefSection(
      topic: topic,
      kind: BriefSectionKind.recipes,
      state: BriefSectionLoadState.ready,
      eyebrow: 'Low-lift meals',
      title: 'Easy Recipes',
      description: 'Snackable recipe cards meant to keep dinner simple.',
      summary: result.queryUsed.isNotEmpty ? 'Based on: ${result.queryUsed}.' : null,
      items: items,
      generatedAt: result.generatedAt,
      errorMessage: result.errorMessage,
      queryUsed: result.queryUsed,
      isFromCache: result.usedCache,
      isStale: result.isStale,
    );
  }

  BriefSection _buildCozyGamesSection(SelectedBriefTopic topic) {
    return BriefSection(
      topic: topic,
      kind: BriefSectionKind.curated,
      state: BriefSectionLoadState.ready,
      eyebrow: 'Curated comfort',
      title: 'Cozy Games',
      description: 'Hand-picked low-pressure games while the POC stays client-side.',
      summary: 'Static curated content for now.',
      items: CozyGamesCuratedCards.cards,
      generatedAt: _now(),
      queryUsed: 'static_curated_cards',
    );
  }

  Future<BriefSection> _buildWeatherSection(
    SelectedBriefTopic topic,
    BriefLocationContext location,
    bool forceRefresh,
  ) async {
    final mapping = topicQueryMapping(topic.topic, location);
    final response = await _getJson(
      Uri.parse(_serpApiBaseUrl).replace(
        queryParameters: <String, String>{
          'engine': 'google',
          'q': mapping.query,
          'hl': 'en',
          'gl': 'us',
          'api_key': _resolvedApiKey,
          if (mapping.locationOverride != null) 'location': mapping.locationOverride!,
          if (forceRefresh) 'no_cache': 'true',
        },
      ),
    );

    final answerBox = Map<String, dynamic>.from(
      response['answer_box'] as Map? ?? const <String, dynamic>{},
    );
    if (answerBox.isEmpty) {
      throw const BriefContentException(
        'Weather summary is unavailable right now.',
      );
    }

    final weatherLocation = _stringValue(answerBox['location']).isNotEmpty
        ? _stringValue(answerBox['location'])
        : location.label;
    final condition = _stringValue(answerBox['weather']);
    final temperature = _stringValue(answerBox['temperature']);
    final forecast = ((answerBox['forecast'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map((Map item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    final hourly = ((answerBox['hourly_forecast'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map((Map item) => Map<String, dynamic>.from(item))
        .toList(growable: false);

    final items = <BriefContentItem>[
      BriefContentItem(
        id: 'weather_now_${_normalizeId(weatherLocation)}',
        title: _normalizeWhitespace(
          '${temperature.isNotEmpty ? '$temperature° ' : ''}${condition.isNotEmpty ? condition : 'Weather'}',
        ),
        subtitle: 'Today in $weatherLocation',
        source: 'Google Weather via SerpApi',
        badge: 'Now',
        metadata: <String, String>{
          if (forecast.isNotEmpty) 'High': _stringValue(forecast.first['high']),
          if (forecast.isNotEmpty) 'Low': _stringValue(forecast.first['low']),
          if (_stringValue(answerBox['humidity']).isNotEmpty)
            'Humidity': _stringValue(answerBox['humidity']),
          if (_stringValue(answerBox['wind']).isNotEmpty)
            'Wind': _stringValue(answerBox['wind']),
        },
      ),
      ...hourly.take(2).map((Map<String, dynamic> item) {
        return BriefContentItem(
          id: 'weather_hour_${_normalizeId(_stringValue(item['time']))}',
          title: _stringValue(item['time']),
          subtitle: _stringValue(item['weather']),
          source: 'Google Weather via SerpApi',
          badge: _stringValue(item['temperature']),
          metadata: const <String, String>{},
        );
      }),
    ];

    return BriefSection(
      topic: topic,
      kind: BriefSectionKind.weather,
      state: BriefSectionLoadState.ready,
      eyebrow: 'Plan with less friction',
      title: 'Weather',
      description: 'A soft snapshot for ${location.hasPreciseLocation ? weatherLocation : 'the U.S.'}.',
      summary: _weatherSummary(
        temperature: temperature,
        condition: condition,
        weatherLocation: weatherLocation,
      ),
      items: items,
      generatedAt: _now(),
      queryUsed: mapping.query,
    );
  }

  Future<BriefSection> _buildSerpRoundupSection({
    required SelectedBriefTopic topic,
    required BriefSectionKind kind,
    required String eyebrow,
    required String title,
    required String description,
    required BriefTopicQueryMapping mapping,
    required List<String> responseKeys,
    required int itemLimit,
    required bool forceRefresh,
  }) async {
    final response = await _getJson(
      Uri.parse(_serpApiBaseUrl).replace(
        queryParameters: <String, String>{
          'engine': 'google',
          'q': mapping.query,
          'hl': 'en',
          'gl': 'us',
          'num': '8',
          'api_key': _resolvedApiKey,
          if (mapping.locationOverride != null) 'location': mapping.locationOverride!,
          if (forceRefresh) 'no_cache': 'true',
          ...mapping.extraParameters,
        },
      ),
    );

    var items = _extractCards(response, responseKeys).take(itemLimit).toList(growable: false);
    var queryUsed = mapping.query;

    if (items.isEmpty && mapping.fallbackQuery != null) {
      final fallbackResponse = await _getJson(
        Uri.parse(_serpApiBaseUrl).replace(
          queryParameters: <String, String>{
            'engine': 'google',
            'q': mapping.fallbackQuery!,
            'hl': 'en',
            'gl': 'us',
            'num': '8',
            'api_key': _resolvedApiKey,
            if (forceRefresh) 'no_cache': 'true',
            ...mapping.extraParameters,
          },
        ),
      );
      items = _extractCards(fallbackResponse, responseKeys)
          .take(itemLimit)
          .toList(growable: false);
      queryUsed = mapping.fallbackQuery!;
    }

    if (items.isEmpty) {
      throw BriefContentException('$title content is unavailable right now.');
    }

    return BriefSection(
      topic: topic,
      kind: kind,
      state: BriefSectionLoadState.ready,
      eyebrow: eyebrow,
      title: title,
      description: description,
      summary: mapping.locationOverride != null
          ? 'Personalized for ${mapping.locationOverride}.'
          : 'Falling back to a general U.S. search.',
      items: items,
      generatedAt: _now(),
      queryUsed: queryUsed,
    );
  }

  String _weatherSummary({
    required String temperature,
    required String condition,
    required String weatherLocation,
  }) {
    final lead = <String>[
      if (temperature.isNotEmpty) '$temperature°',
      if (condition.isNotEmpty) condition,
    ].join(' and ');
    if (lead.isEmpty) {
      return 'Weather details for $weatherLocation.';
    }
    return '$lead in $weatherLocation.';
  }

  List<BriefContentItem> _extractCards(
    Map<String, dynamic> response,
    List<String> responseKeys,
  ) {
    final candidates = <Map<String, dynamic>>[];

    for (final key in responseKeys) {
      final value = response[key];
      if (value is! List) {
        continue;
      }
      for (final item in value) {
        if (item is Map) {
          candidates.add(Map<String, dynamic>.from(item as Map));
        }
      }
    }

    final seen = <String>{};
    final results = <BriefContentItem>[];

    for (final item in candidates) {
      final card = _parseSerpCard(item);
      if (card == null) {
        continue;
      }
      final dedupeKey = card.link?.isNotEmpty == true ? card.link! : card.id;
      if (seen.add(dedupeKey)) {
        results.add(card);
      }
    }

    return results;
  }

  BriefContentItem? _parseSerpCard(Map<String, dynamic> raw) {
    final title = _normalizeWhitespace(_stringValue(raw['title']));
    final link = _canonicalizeUrl(_stringValue(raw['link']));
    if (title.isEmpty || link.isEmpty) {
      return null;
    }

    final subtitleCandidates = <String>[
      _stringValue(raw['snippet']),
      _stringValue(raw['description']),
      _stringValue(raw['snippet_highlighted_words']),
      _stringValue(raw['channel']),
    ];
    final subtitle = subtitleCandidates
        .map(_normalizeWhitespace)
        .firstWhere((String value) => value.isNotEmpty, orElse: () => '');

    final sourceCandidates = <String>[
      _stringValue(raw['source']),
      _stringValue(raw['channel']),
      _stringValue(raw['date']),
    ];
    final source = sourceCandidates
        .map(_normalizeWhitespace)
        .firstWhere((String value) => value.isNotEmpty, orElse: () => 'Web');

    final badgeCandidates = <String>[
      _stringValue(raw['date']),
      _stringValue(raw['duration']),
      _stringValue(raw['position']),
      _stringValue(raw['type']),
    ];
    final badge = badgeCandidates
        .map(_normalizeWhitespace)
        .firstWhere((String value) => value.isNotEmpty, orElse: () => 'Open');

    return BriefContentItem(
      id: _normalizeId(link),
      title: title,
      subtitle: subtitle,
      source: source,
      badge: badge,
      link: link,
      imageUrl: _stringValue(raw['thumbnail']).isNotEmpty
          ? _stringValue(raw['thumbnail'])
          : null,
      metadata: <String, String>{
        if (_stringValue(raw['rich_snippet']).isNotEmpty)
          'Details': _stringValue(raw['rich_snippet']),
      },
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _httpClient.get(uri).timeout(_requestTimeout);
    if (response.statusCode != 200) {
      throw BriefContentException(
        'SerpApi content fetch returned ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const BriefContentException('Unexpected SerpApi response format.');
    }

    final data = Map<String, dynamic>.from(decoded as Map);
    final error = _normalizeWhitespace(_stringValue(data['error']));
    if (error.isNotEmpty) {
      throw BriefContentException(error);
    }
    return data;
  }

  String get _resolvedApiKey {
    final apiKey = (_apiKey ?? AppConfig.serpApiKey).trim();
    if (apiKey.isEmpty) {
      throw const BriefContentException(
        'SerpApi key is missing. Configure AppConfig.serpApiKey for the POC.',
      );
    }
    return apiKey;
  }

  String _stringValue(dynamic value) {
    if (value is List) {
      return value.map((dynamic item) => item.toString()).join(' ');
    }
    return value?.toString() ?? '';
  }

  String _normalizeWhitespace(String input) {
    return input.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _canonicalizeUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return trimmed;
    }

    return uri.replace(
      fragment: '',
      queryParameters: Map<String, String>.fromEntries(
        uri.queryParameters.entries.where(
          (MapEntry<String, String> entry) =>
              !entry.key.toLowerCase().startsWith('utm_'),
        ),
      ),
    ).toString();
  }

  String _normalizeId(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'https?://'), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}

class BriefLocationContext {
  const BriefLocationContext({
    required this.label,
    required this.city,
    required this.stateOrRegion,
    required this.country,
    required this.normalizedCacheKey,
    required this.latitude,
    required this.longitude,
    required this.hasPreciseLocation,
  });

  final String label;
  final String city;
  final String stateOrRegion;
  final String country;
  final String normalizedCacheKey;
  final double? latitude;
  final double? longitude;
  final bool hasPreciseLocation;

  String get cityAndRegionLabel {
    if (city.isNotEmpty && stateOrRegion.isNotEmpty) {
      return '$city, $stateOrRegion';
    }
    if (city.isNotEmpty) {
      return city;
    }
    if (stateOrRegion.isNotEmpty) {
      return stateOrRegion;
    }
    return label;
  }
}

class BriefTopicQueryMapping {
  const BriefTopicQueryMapping({
    required this.query,
    this.fallbackQuery,
    this.locationOverride,
    this.extraParameters = const <String, String>{},
  });

  final String query;
  final String? fallbackQuery;
  final String? locationOverride;
  final Map<String, String> extraParameters;
}
