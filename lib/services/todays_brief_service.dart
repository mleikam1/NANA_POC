import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/app_user_profile.dart';
import '../models/todays_brief_preview.dart';
import '../repositories/topic_preferences_repository.dart';
import '../utils/location_label_helper.dart';
import 'local_news_service.dart';
import 'recipes_service.dart';

class TodaysBriefService {
  TodaysBriefService({
    http.Client? httpClient,
    LocalNewsService? localNewsService,
    RecipesService? recipesService,
    DateTime Function()? now,
    String? apiKey,
    TopicPreferencesRepository? topicPreferencesRepository,
  })  : _httpClient = httpClient ?? http.Client(),
        _localNewsService = localNewsService,
        _recipesService = recipesService,
        _now = now ?? DateTime.now,
        _apiKey = apiKey,
        _topicPreferencesRepository =
            topicPreferencesRepository ?? TopicPreferencesRepository();

  final http.Client _httpClient;
  final LocalNewsService? _localNewsService;
  final RecipesService? _recipesService;
  final DateTime Function() _now;
  final String? _apiKey;
  final TopicPreferencesRepository _topicPreferencesRepository;

  static const String _serpApiBaseUrl = 'https://serpapi.com/search.json';
  static const Duration _requestTimeout = Duration(seconds: 10);

  Future<TodaysBriefPreview> loadPreview(AppUserProfile profile) async {
    final topics = await _topicPreferencesRepository.resolveSelectedTopics(
      profile.topics,
    );
    final selectedTopics = topics.isEmpty
        ? AppConfig.defaultTopics.take(3).toList(growable: false)
        : topics;

    final sections = await Future.wait(
      selectedTopics.map((String topic) => _buildSection(profile, topic)),
    );

    return TodaysBriefPreview(
      generatedAt: _now(),
      topics: selectedTopics,
      sections: sections,
    );
  }

  Future<BriefPreviewSection> _buildSection(
    AppUserProfile profile,
    String topic,
  ) async {
    switch (topic) {
      case 'Local News':
        return _buildLocalNewsSection(profile);
      case 'Easy Recipes':
        return _buildRecipesSection();
      case 'Weather':
        return _buildWeatherSection(profile);
      case 'Calm Videos':
        return _buildGenericRoundupSection(
          topic: topic,
          eyebrow: 'A softer scroll',
          description: 'Short, gentle videos for a calmer pause.',
          query: 'calm videos relaxing reset youtube',
        );
      case 'Family Savings':
        return _buildGenericRoundupSection(
          topic: topic,
          eyebrow: 'Small practical wins',
          description: 'Useful ideas to stretch the week a little further.',
          query: 'family savings tips grocery budget deals this week',
        );
      case 'Good News':
        return _buildGenericRoundupSection(
          topic: topic,
          eyebrow: 'A brighter note',
          description: 'A few uplifting stories without the noise.',
          query: 'good news uplifting stories today',
        );
      case 'Cozy Games':
        return _buildCozyGamesSection();
      case 'Nostalgia':
        return _buildGenericRoundupSection(
          topic: topic,
          eyebrow: 'Comfortingly familiar',
          description: 'Throwback reads and feel-good callbacks.',
          query: 'nostalgia pop culture throwback feel good',
        );
      case 'Home Routines':
        return _buildGenericRoundupSection(
          topic: topic,
          eyebrow: 'Gentle structure',
          description: 'Low-pressure routines that help the home feel lighter.',
          query: 'simple home routines tidy reset tips',
        );
      case 'Community Events':
        final location = _locationLabel(profile);
        return _buildGenericRoundupSection(
          topic: topic,
          eyebrow: 'Around you',
          description: 'A few nearby ideas worth considering this week.',
          query: 'community events ${location == 'your area' ? '' : location} this weekend'.trim(),
        );
      default:
        return _buildGenericRoundupSection(
          topic: topic,
          eyebrow: 'For today',
          description: 'A calm roundup for this part of your brief.',
          query: topic,
        );
    }
  }

  Future<BriefPreviewSection> _buildLocalNewsSection(AppUserProfile profile) async {
    try {
      final result = await (_localNewsService ?? LocalNewsService()).fetchLocalNews(profile);
      final items = result.stories.take(4).map((story) {
        return BriefPreviewItem(
          title: story.title,
          subtitle:
              story.calmHeadline.isNotEmpty ? story.calmHeadline : story.snippet,
          source: story.source,
          badge: story.readTimeLabel.isNotEmpty ? story.readTimeLabel : 'Local',
          link: story.url,
          metadata: <String, String>{
            if (story.relativeTimeLabel.isNotEmpty)
              'Updated': story.relativeTimeLabel,
          },
        );
      }).toList(growable: false);

      return BriefPreviewSection(
        topic: 'Local News',
        kind: BriefPreviewSectionKind.roundup,
        eyebrow: 'Close to home',
        title: result.location.label.isNotEmpty
            ? 'Local News for ${result.location.label}'
            : 'Local News',
        description: 'A calmer look at what is happening nearby.',
        items: items,
        errorMessage: result.errorMessage,
      );
    } catch (error) {
      return BriefPreviewSection(
        topic: 'Local News',
        kind: BriefPreviewSectionKind.roundup,
        eyebrow: 'Close to home',
        title: 'Local News',
        description: 'We could not refresh local headlines right now.',
        items: const <BriefPreviewItem>[],
        errorMessage: error.toString(),
      );
    }
  }

  Future<BriefPreviewSection> _buildRecipesSection() async {
    try {
      final result = await (_recipesService ?? RecipesService()).fetchRecipes();
      final items = result.recipes.take(3).map((recipe) {
        return BriefPreviewItem(
          title: recipe.title,
          subtitle: recipe.ingredients.take(3).join(' • '),
          source: recipe.source,
          badge: recipe.totalTime.isNotEmpty ? recipe.totalTime : 'Easy',
          link: recipe.link,
          metadata: <String, String>{
            if (recipe.rating != null) 'Rating': recipe.rating!.toStringAsFixed(1),
            if (recipe.totalIngredients != null)
              'Ingredients': recipe.totalIngredients.toString(),
          },
        );
      }).toList(growable: false);

      return BriefPreviewSection(
        topic: 'Easy Recipes',
        kind: BriefPreviewSectionKind.recipes,
        eyebrow: 'Low-lift meals',
        title: 'Easy Recipes',
        description: 'Simple ideas to make tonight feel lighter.',
        items: items,
        errorMessage: result.errorMessage,
      );
    } catch (error) {
      return BriefPreviewSection(
        topic: 'Easy Recipes',
        kind: BriefPreviewSectionKind.recipes,
        eyebrow: 'Low-lift meals',
        title: 'Easy Recipes',
        description: 'Recipe ideas are taking a moment to load.',
        items: const <BriefPreviewItem>[],
        errorMessage: error.toString(),
      );
    }
  }

  Future<BriefPreviewSection> _buildWeatherSection(AppUserProfile profile) async {
    final location = _locationLabel(profile);
    try {
      final response = await _getJson(
        Uri.parse(_serpApiBaseUrl).replace(
          queryParameters: <String, String>{
            'engine': 'google',
            'q': 'weather in $location',
            'hl': 'en',
            'gl': 'us',
            'api_key': _resolvedApiKey,
          },
        ),
      );
      final answerBox = Map<String, dynamic>.from(
        response['answer_box'] as Map? ?? const <String, dynamic>{},
      );
      final forecast = ((answerBox['forecast'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((Map item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
      final hourly = ((answerBox['hourly_forecast'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((Map item) => Map<String, dynamic>.from(item))
          .toList(growable: false);

      final weather = BriefPreviewWeather(
        location: _stringValue(answerBox['location']).isNotEmpty
            ? _stringValue(answerBox['location'])
            : location,
        temperature: _stringValue(answerBox['temperature']).replaceAll(RegExp(r'[^0-9-]'), ''),
        condition: _stringValue(answerBox['weather']),
        high: forecast.isNotEmpty ? _stringValue(forecast.first['high']) : '--',
        low: forecast.isNotEmpty ? _stringValue(forecast.first['low']) : '--',
        hourly: hourly.take(4).map((Map<String, dynamic> item) {
          return BriefPreviewWeatherHour(
            label: _stringValue(item['time']),
            temperature: _stringValue(item['temperature']),
            condition: _stringValue(item['weather']),
          );
        }).toList(growable: false),
      );

      return BriefPreviewSection(
        topic: 'Weather',
        kind: BriefPreviewSectionKind.weather,
        eyebrow: 'Plan with less friction',
        title: 'Weather',
        description: 'A soft snapshot for ${weather.location}.',
        items: const <BriefPreviewItem>[],
        weather: weather,
      );
    } catch (error) {
      return BriefPreviewSection(
        topic: 'Weather',
        kind: BriefPreviewSectionKind.weather,
        eyebrow: 'Plan with less friction',
        title: 'Weather',
        description: 'Weather is unavailable right now for $location.',
        items: const <BriefPreviewItem>[],
        errorMessage: error.toString(),
      );
    }
  }

  Future<BriefPreviewSection> _buildGenericRoundupSection({
    required String topic,
    required String eyebrow,
    required String description,
    required String query,
  }) async {
    try {
      final response = await _getJson(
        Uri.parse(_serpApiBaseUrl).replace(
          queryParameters: <String, String>{
            'engine': 'google',
            'q': query,
            'hl': 'en',
            'gl': 'us',
            'api_key': _resolvedApiKey,
          },
        ),
      );
      final organic = ((response['organic_results'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((Map item) => Map<String, dynamic>.from(item))
          .take(4)
          .toList(growable: false);

      final items = organic.map((Map<String, dynamic> item) {
        final sitelinks = ((item['sitelinks'] as Map?)?['inline'] as List?) ??
            const <dynamic>[];
        return BriefPreviewItem(
          title: _stringValue(item['title']),
          subtitle: _stringValue(item['snippet']),
          source: _stringValue(item['source']),
          badge: sitelinks.isNotEmpty ? '${sitelinks.length} quick links' : topic,
          link: _stringValue(item['link']),
          metadata: <String, String>{
            if (_stringValue(item['date']).isNotEmpty) 'When': _stringValue(item['date']),
          },
        );
      }).where((BriefPreviewItem item) => item.title.isNotEmpty).toList(growable: false);

      return BriefPreviewSection(
        topic: topic,
        kind: topic == 'Calm Videos'
            ? BriefPreviewSectionKind.videos
            : BriefPreviewSectionKind.roundup,
        eyebrow: eyebrow,
        title: topic,
        description: description,
        items: items,
      );
    } catch (error) {
      return BriefPreviewSection(
        topic: topic,
        kind: topic == 'Calm Videos'
            ? BriefPreviewSectionKind.videos
            : BriefPreviewSectionKind.roundup,
        eyebrow: eyebrow,
        title: topic,
        description: description,
        items: const <BriefPreviewItem>[],
        errorMessage: error.toString(),
      );
    }
  }

  BriefPreviewSection _buildCozyGamesSection() {
    const items = <BriefPreviewItem>[
      BriefPreviewItem(
        title: 'A Little to the Left',
        subtitle: 'Gentle sorting puzzles with satisfying tiny wins.',
        source: 'Curated cozy pick',
        badge: '10–15 min',
        metadata: <String, String>{'Best for': 'A quick reset'},
      ),
      BriefPreviewItem(
        title: 'Unpacking',
        subtitle: 'A quiet, story-rich organizing game with no rush.',
        source: 'Curated cozy pick',
        badge: 'Story cozy',
        metadata: <String, String>{'Mood': 'Warm and reflective'},
      ),
      BriefPreviewItem(
        title: 'Dorfromantik',
        subtitle: 'Build soft landscapes one tile at a time.',
        source: 'Curated cozy pick',
        badge: 'Zen strategy',
        metadata: <String, String>{'Best for': 'Slowing down'},
      ),
    ];

    return const BriefPreviewSection(
      topic: 'Cozy Games',
      kind: BriefPreviewSectionKind.curated,
      eyebrow: 'Locally curated for the POC',
      title: 'Cozy Games',
      description: 'A static shortlist for now while the rest of the brief uses SerpAPI.',
      items: items,
    );
  }

  String get _resolvedApiKey {
    final apiKey = (_apiKey ?? AppConfig.serpApiKey).trim();
    if (apiKey.isEmpty) {
      throw StateError(
        'SerpApi key is missing in lib/config/app_config.dart for the Today\'s brief POC.',
      );
    }
    return apiKey;
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _httpClient.get(uri).timeout(_requestTimeout);
    if (response.statusCode != 200) {
      throw StateError('SerpApi request failed with status ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Unexpected SerpApi response format.');
    }
    return Map<String, dynamic>.from(decoded as Map);
  }

  String _locationLabel(AppUserProfile profile) {
    final label = LocationLabelHelper.bestLabelFromProfile(
      locationLabel: profile.locationLabel,
      latitude: profile.locationLatitude,
      longitude: profile.locationLongitude,
    );
    return label.isEmpty ? 'your area' : label;
  }

  String _stringValue(Object? value) {
    return value?.toString().replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
  }
}
