import 'dart:async';
import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/app_user_profile.dart';
import '../models/local_news_story.dart';
import '../utils/location_label_helper.dart';

class LocalNewsException implements Exception {
  const LocalNewsException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocalNewsService {
  LocalNewsService({
    http.Client? httpClient,
    Future<SharedPreferences>? sharedPreferences,
    DateTime Function()? now,
    String? apiKey,
  })  : _httpClient = httpClient ?? http.Client(),
        _sharedPreferencesFuture =
            sharedPreferences ?? SharedPreferences.getInstance(),
        _now = now ?? DateTime.now,
        _apiKey = apiKey;

  final http.Client _httpClient;
  final Future<SharedPreferences> _sharedPreferencesFuture;
  final DateTime Function() _now;
  final String? _apiKey;

  static const String _serpApiBaseUrl = 'https://serpapi.com/search.json';
  static const Duration _resultTtl = Duration(minutes: 45);
  static const Duration _summaryTtl = Duration(hours: 8);
  static const Duration _requestTimeout = Duration(seconds: 10);
  static const int _storyLimit = 5;
  static const int _articleFetchConcurrency = 2;
  static const String _resultCachePrefix = 'local_news_result_v1_';
  static const String _summaryCachePrefix = 'local_news_summary_v1_';

  Future<LocalNewsResult> fetchLocalNews(
    AppUserProfile profile, {
    bool forceRefresh = false,
  }) async {
    final location = await resolveLocation(profile);
    if (location.normalizedCacheKey.isEmpty) {
      throw const LocalNewsException(
        'Add a saved city or area in your profile to load local stories.',
      );
    }

    final prefs = await _sharedPreferencesFuture;
    final cached = await readCachedResult(location.normalizedCacheKey);
    final hasFreshCache = cached != null &&
        _now().difference(cached.generatedAt) <= _resultTtl &&
        cached.stories.length == _storyLimit;

    if (!forceRefresh && hasFreshCache) {
      return cached;
    }

    try {
      final apiKey = _apiKey ?? AppConfig.serpApiKey;
      if (apiKey.trim().isEmpty) {
        throw const LocalNewsException(
          'SerpApi key is missing in AppConfig.serpApiKey for the Local News POC.',
        );
      }

      final rawStories = await _searchStories(
        location: location,
        apiKey: apiKey,
        forceRefresh: forceRefresh,
      );

      if (rawStories.length < _storyLimit) {
        throw const LocalNewsException(
          'We could not find five local stories for this saved location just now.',
        );
      }

      final summarizedStories = await _summarizeStories(rawStories);
      final result = LocalNewsResult(
        location: location,
        stories: summarizedStories.take(_storyLimit).toList(),
        generatedAt: _now(),
        isStale: false,
        usedCache: false,
        isPartial: summarizedStories.any(
          (LocalNewsStory story) => story.extractionFailed,
        ),
        errorMessage: null,
      );
      await prefs.setString(
        '$_resultCachePrefix${location.normalizedCacheKey}',
        jsonEncode(result.toMap()),
      );
      return result;
    } catch (error) {
      if (cached != null && cached.stories.length == _storyLimit) {
        final stale = LocalNewsResult(
          location: cached.location,
          stories: cached.stories
              .map((LocalNewsStory story) => story.copyWith(fromCache: true))
              .toList(),
          generatedAt: cached.generatedAt,
          isStale: true,
          usedCache: true,
          isPartial: cached.isPartial,
          errorMessage: error.toString(),
        );
        return stale;
      }
      rethrow;
    }
  }

  Future<LocalNewsResult?> readCachedResult(String normalizedCacheKey) async {
    final prefs = await _sharedPreferencesFuture;
    final raw = prefs.getString('$_resultCachePrefix$normalizedCacheKey');
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return LocalNewsResult.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Future<LocalNewsLocation> resolveLocation(AppUserProfile profile) async {
    final label = LocationLabelHelper.bestLabelFromProfile(
      locationLabel: profile.locationLabel,
      latitude: profile.locationLatitude,
      longitude: profile.locationLongitude,
    );

    if (label.isNotEmpty) {
      final parsed = _parseLabel(label);
      return LocalNewsLocation(
        label: label,
        normalizedCacheKey: _normalizeCacheKey(label),
        city: parsed.city,
        stateOrRegion: parsed.stateOrRegion,
        country: parsed.country,
        countyOrMetro: parsed.countyOrMetro,
        latitude: profile.locationLatitude,
        longitude: profile.locationLongitude,
      );
    }

    if (profile.locationLatitude != null && profile.locationLongitude != null) {
      try {
        final placemarks = await placemarkFromCoordinates(
          profile.locationLatitude!,
          profile.locationLongitude!,
        ).timeout(_requestTimeout);
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final city = _cleanToken(
            placemark.locality ??
                placemark.subAdministrativeArea ??
                placemark.subLocality,
          );
          final region = _cleanToken(
            placemark.administrativeArea ?? placemark.country,
          );
          final countyOrMetro = _cleanCountyOrMetro(
            placemark.subAdministrativeArea ?? '',
          );
          final resolvedLabel =
              _joinLocationLabel(city, region, placemark.country ?? '');
          return LocalNewsLocation(
            label: resolvedLabel,
            normalizedCacheKey: _normalizeCacheKey(resolvedLabel),
            city: city,
            stateOrRegion: region,
            country: _cleanToken(placemark.country),
            countyOrMetro: countyOrMetro,
            latitude: profile.locationLatitude,
            longitude: profile.locationLongitude,
          );
        }
      } catch (_) {
        // Fall through to coordinate fallback.
      }
    }

    final coordinateLabel =
        (profile.locationLatitude != null && profile.locationLongitude != null)
            ? LocationLabelHelper.fallbackLatLngLabel(
                profile.locationLatitude!,
                profile.locationLongitude!,
              )
            : '';
    return LocalNewsLocation(
      label: coordinateLabel,
      normalizedCacheKey: _normalizeCacheKey(coordinateLabel),
      city: '',
      stateOrRegion: '',
      country: '',
      countyOrMetro: '',
      latitude: profile.locationLatitude,
      longitude: profile.locationLongitude,
    );
  }

  List<String> buildQueryFallbackChain(LocalNewsLocation location) {
    final queries = <String>[];
    final city = location.city;
    final stateOrRegion = location.stateOrRegion;
    final countyOrMetro = location.countyOrMetro;
    final label = location.label;

    if (city.isNotEmpty && stateOrRegion.isNotEmpty) {
      queries.add('$city $stateOrRegion local news');
      queries.add('$city $stateOrRegion breaking news');
      queries.add('$city $stateOrRegion community news');
    }
    if (city.isNotEmpty) {
      queries.add('$city local news');
      queries.add('$city news');
    }
    if (countyOrMetro.isNotEmpty) {
      queries.add('$countyOrMetro local news');
      queries.add('$countyOrMetro news');
    }
    if (label.isNotEmpty) {
      queries.add('local news $label');
    } else if (location.latitude != null && location.longitude != null) {
      queries.add(
        'local news near ${location.latitude!.toStringAsFixed(2)},${location.longitude!.toStringAsFixed(2)}',
      );
    }
    queries.add('local community updates ${city.isNotEmpty ? city : label}');

    return queries
        .map(_normalizeWhitespace)
        .where((String item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  LocalNewsStory parseSerpApiStory(
    Map<String, dynamic> raw,
    int rank,
  ) {
    final title = _normalizeWhitespace(raw['title'] as String? ?? '');
    final url = _canonicalizeUrl(raw['link'] as String? ?? '');
    final rawSource = raw['source'];
    final source = _normalizeWhitespace(
      rawSource is Map<String, dynamic>
          ? rawSource['name'] as String? ?? ''
          : rawSource as String? ?? '',
    );
    final snippet = _normalizeWhitespace(
      raw['snippet'] as String? ??
          raw['title_snippet'] as String? ??
          raw['story'] as String? ?? '',
    );
    final thumbnailUrl = _normalizeWhitespace(
      raw['thumbnail'] as String? ?? raw['thumbnail_small'] as String? ?? '',
    );
    final publishedAt = _parseDateCandidate(
      raw['iso_date'] as String? ??
          raw['date'] as String? ??
          raw['published_at'] as String? ??
          raw['timestamp'] as String?,
    );

    return LocalNewsStory(
      id: _storyId(url, title),
      rank: rank,
      title: title,
      url: url,
      source: source,
      snippet: snippet,
      thumbnailUrl: thumbnailUrl,
      publishedAt: publishedAt,
      relativeTimeLabel: _relativeTimeLabel(publishedAt),
      calmHeadline: '',
      bullets: const <String>[],
      readTimeLabel: '',
      extractionFailed: false,
      fromCache: false,
    );
  }

  List<LocalNewsStory> dedupeStories(Iterable<LocalNewsStory> stories) {
    final seenKeys = <String>{};
    final deduped = <LocalNewsStory>[];

    for (final story in stories) {
      final key = story.url.isNotEmpty
          ? story.url
          : _normalizeCacheKey(story.title.toLowerCase());
      if (seenKeys.add(key)) {
        deduped.add(story);
      }
    }

    return deduped;
  }

  List<String> buildFallbackBullets(
    LocalNewsStory story, {
    String bodyText = '',
  }) {
    final bullets = <String>[];
    final normalizedBody = _normalizeWhitespace(bodyText);

    if (normalizedBody.isNotEmpty) {
      final sentences = _splitIntoSentences(normalizedBody);
      for (final sentence in sentences) {
        final bullet = _toCalmBullet(sentence);
        if (bullet.isNotEmpty && !bullets.contains(bullet)) {
          bullets.add(bullet);
        }
        if (bullets.length == 2) {
          break;
        }
      }
    }

    if (bullets.length < 2 && story.snippet.isNotEmpty) {
      final bullet = _toCalmBullet(story.snippet);
      if (bullet.isNotEmpty && !bullets.contains(bullet)) {
        bullets.add(bullet);
      }
    }

    if (bullets.length < 2 && story.source.isNotEmpty) {
      final timing = story.relativeTimeLabel.isNotEmpty
          ? ' shared ${story.relativeTimeLabel.toLowerCase()}'
          : '';
      final bullet = _toCalmBullet('Covered by ${story.source}$timing');
      if (bullet.isNotEmpty && !bullets.contains(bullet)) {
        bullets.add(bullet);
      }
    }

    if (bullets.length < 2 && story.title.isNotEmpty) {
      final bullet = _toCalmBullet('The update centers on ${_cleanHeadline(story.title)}');
      if (bullet.isNotEmpty && !bullets.contains(bullet)) {
        bullets.add(bullet);
      }
    }

    if (bullets.length < 2) {
      bullets.add('Open the full article for the complete local context.');
    }

    return bullets.take(2).toList();
  }

  String buildCalmHeadline(LocalNewsStory story, {String bodyText = ''}) {
    final title = _cleanHeadline(story.title);
    final normalizedBody = _normalizeWhitespace(bodyText);
    if (normalizedBody.isNotEmpty) {
      final firstSentence = _splitIntoSentences(normalizedBody).firstOrNull ?? '';
      final summary = _normalizeWhitespace(firstSentence);
      if (summary.isNotEmpty) {
        final lead = summary[0].toLowerCase() + summary.substring(1);
        return _trimToWords('A steady local update: $lead', 16);
      }
    }
    if (title.isNotEmpty) {
      return _trimToWords('A steady local update on $title.', 16);
    }
    if (story.snippet.isNotEmpty) {
      return _trimToWords(
        'A steady local update: ${story.snippet.toLowerCase()}',
        16,
      );
    }
    return 'A steady local update for your area.';
  }

  String extractReadableText(String html) {
    final document = html_parser.parse(html);
    document.querySelectorAll(
      'script,style,svg,nav,footer,header,form,noscript,aside',
    ).forEach((element) => element.remove());

    final article = document.querySelector('article');
    final candidates =
        article?.querySelectorAll('p') ?? document.querySelectorAll('p');
    final paragraphs = candidates
        .map((element) => _normalizeWhitespace(element.text))
        .where((String text) => text.split(' ').length >= 8)
        .toList();

    if (paragraphs.isNotEmpty) {
      return paragraphs.take(5).join(' ');
    }

    final bodyText = _normalizeWhitespace(document.body?.text ?? '');
    return bodyText;
  }

  Future<List<LocalNewsStory>> _searchStories({
    required LocalNewsLocation location,
    required String apiKey,
    required bool forceRefresh,
  }) async {
    final queries = buildQueryFallbackChain(location);
    final aggregated = <LocalNewsStory>[];

    for (final query in queries) {
      for (final mode in _searchModes(location, apiKey, query, forceRefresh)) {
        final response = await _getJson(mode.uri);
        final stories = _extractStoriesFromResponse(response, mode.kind);
        aggregated.addAll(
          stories
              .map(
                (Map<String, dynamic> item) => parseSerpApiStory(
                  item,
                  aggregated.length + 1,
                ),
              )
              .where(
                (LocalNewsStory story) =>
                    story.title.isNotEmpty && story.url.startsWith('http'),
              ),
        );

        final deduped = dedupeStories(aggregated);
        if (deduped.length >= _storyLimit) {
          return deduped.take(_storyLimit).toList();
        }
      }
    }

    return dedupeStories(aggregated).take(_storyLimit).toList();
  }

  Iterable<_SerpSearchMode> _searchModes(
    LocalNewsLocation location,
    String apiKey,
    String query,
    bool forceRefresh,
  ) sync* {
    final common = <String, String>{
      'api_key': apiKey,
      'hl': 'en',
      'gl': 'us',
      if (forceRefresh) 'no_cache': 'true',
    };

    yield _SerpSearchMode(
      kind: _SerpSearchKind.localNews,
      uri: Uri.parse(_serpApiBaseUrl).replace(
        queryParameters: <String, String>{
          ...common,
          'engine': 'google',
          'q': query,
          if (location.label.isNotEmpty) 'location': location.label,
        },
      ),
    );

    yield _SerpSearchMode(
      kind: _SerpSearchKind.newsResults,
      uri: Uri.parse(_serpApiBaseUrl).replace(
        queryParameters: <String, String>{
          ...common,
          'engine': 'google_news_light',
          'q': query,
          if (location.label.isNotEmpty) 'location': location.label,
        },
      ),
    );

    yield _SerpSearchMode(
      kind: _SerpSearchKind.newsResults,
      uri: Uri.parse(_serpApiBaseUrl).replace(
        queryParameters: <String, String>{
          ...common,
          'engine': 'google_news',
          'q': query,
          'so': '1',
        },
      ),
    );
  }

  List<Map<String, dynamic>> _extractStoriesFromResponse(
    Map<String, dynamic> response,
    _SerpSearchKind preferredKind,
  ) {
    final candidates = <dynamic>[
      if (preferredKind == _SerpSearchKind.localNews) response['local_news'],
      response['news_results'],
      response['local_news'],
      response['stories_results'],
    ];

    final stories = <Map<String, dynamic>>[];
    for (final candidate in candidates) {
      if (candidate is! List) {
        continue;
      }
      for (final item in candidate) {
        if (item is! Map) {
          continue;
        }
        stories.add(Map<String, dynamic>.from(item as Map));
      }
    }
    return stories;
  }

  Future<List<LocalNewsStory>> _summarizeStories(
    List<LocalNewsStory> stories,
  ) async {
    final queue = List<LocalNewsStory>.from(stories.take(_storyLimit));
    final results = <LocalNewsStory>[];

    while (queue.isNotEmpty) {
      final batch = queue.take(_articleFetchConcurrency).toList();
      queue.removeRange(0, batch.length);
      final batchResults = await Future.wait(batch.map(_summarizeStory));
      results.addAll(batchResults);
    }

    return results.asMap().entries.map((entry) {
      return entry.value.copyWith(rank: entry.key + 1);
    }).toList();
  }

  Future<LocalNewsStory> _summarizeStory(LocalNewsStory story) async {
    final prefs = await _sharedPreferencesFuture;
    final summaryKey = '$_summaryCachePrefix${_normalizeCacheKey(story.url)}';
    final cachedRaw = prefs.getString(summaryKey);

    if (cachedRaw != null && cachedRaw.isNotEmpty) {
      try {
        final cachedMap = jsonDecode(cachedRaw) as Map<String, dynamic>;
        final cachedAt =
            DateTime.tryParse(cachedMap['cachedAt'] as String? ?? '');
        if (cachedAt != null && _now().difference(cachedAt) <= _summaryTtl) {
          final cachedStory = LocalNewsStory.fromMap(
            Map<String, dynamic>.from(cachedMap['story'] as Map),
          );
          return cachedStory.copyWith(fromCache: true, rank: story.rank);
        }
      } catch (_) {
        // Ignore corrupted cache entries.
      }
    }

    LocalNewsStory summarized;
    try {
      final bodyText = await _fetchArticleText(story.url);
      summarized = story.copyWith(
        calmHeadline: buildCalmHeadline(story, bodyText: bodyText),
        bullets: buildFallbackBullets(story, bodyText: bodyText),
        readTimeLabel: _estimateReadTime(bodyText),
        extractionFailed: bodyText.trim().isEmpty,
      );
    } catch (_) {
      summarized = story.copyWith(
        calmHeadline: buildCalmHeadline(story),
        bullets: buildFallbackBullets(story),
        readTimeLabel: story.snippet.isNotEmpty ? 'Quick update' : 'Short read',
        extractionFailed: true,
      );
    }

    await prefs.setString(
      summaryKey,
      jsonEncode(<String, dynamic>{
        'cachedAt': _now().toIso8601String(),
        'story': summarized.toMap(),
      }),
    );
    return summarized;
  }

  Future<String> _fetchArticleText(String url) async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _httpClient
            .get(
              Uri.parse(url),
              headers: const <String, String>{
                'User-Agent':
                    'Mozilla/5.0 (compatible; NANA Local News POC/1.0; +https://openai.com)',
              },
            )
            .timeout(_requestTimeout);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return extractReadableText(response.body);
        }
        lastError = 'HTTP ${response.statusCode}';
      } catch (error) {
        lastError = error;
      }
    }
    throw LocalNewsException('Article extraction failed: $lastError');
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _httpClient.get(uri).timeout(_requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LocalNewsException(
        'Local news request failed (${response.statusCode}).',
      );
    }
    final data = Map<String, dynamic>.from(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    final error = _normalizeWhitespace(data['error'] as String? ?? '');
    if (error.isNotEmpty) {
      throw LocalNewsException(error);
    }
    return data;
  }

  _ParsedLabel _parseLabel(String label) {
    final tokens = label
        .split(',')
        .map(_cleanToken)
        .where((String token) => token.isNotEmpty)
        .toList();

    final city = tokens.isNotEmpty ? tokens.first : '';
    final stateOrRegion = tokens.length > 1 ? tokens[1] : '';
    final country = tokens.length > 2 ? tokens.last : '';
    final countyOrMetro = tokens.firstWhere(
      (String token) =>
          token.toLowerCase().contains('county') ||
          token.toLowerCase().contains('metro'),
      orElse: () => '',
    );

    return _ParsedLabel(
      city: city,
      stateOrRegion: stateOrRegion,
      country: country,
      countyOrMetro: _cleanCountyOrMetro(countyOrMetro),
    );
  }

  String _estimateReadTime(String bodyText) {
    final words = bodyText
        .split(RegExp(r'\s+'))
        .where((String word) => word.trim().isNotEmpty)
        .length;
    if (words <= 60) {
      return 'Quick update';
    }
    final minutes = (words / 180).ceil().clamp(1, 9);
    return '$minutes min read';
  }

  String _relativeTimeLabel(DateTime? publishedAt) {
    if (publishedAt == null) {
      return 'Recently';
    }

    final difference = _now().difference(publishedAt);
    if (difference.isNegative) {
      return 'Recently';
    }
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes.clamp(1, 59);
      return '$minutes min ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  }

  DateTime? _parseDateCandidate(String? input) {
    final value = _normalizeWhitespace(input ?? '');
    if (value.isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return parsed.toLocal();
    }

    final relativeMatch = RegExp(
      r'(\d+)\s+(minute|hour|day)s?\s+ago',
      caseSensitive: false,
    ).firstMatch(value);
    if (relativeMatch != null) {
      final amount = int.tryParse(relativeMatch.group(1) ?? '') ?? 0;
      final unit = (relativeMatch.group(2) ?? '').toLowerCase();
      switch (unit) {
        case 'minute':
          return _now().subtract(Duration(minutes: amount));
        case 'hour':
          return _now().subtract(Duration(hours: amount));
        case 'day':
          return _now().subtract(Duration(days: amount));
      }
    }
    return null;
  }

  String _storyId(String url, String title) {
    final source = url.isNotEmpty ? url : title;
    return _normalizeCacheKey(source);
  }

  String _canonicalizeUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      return trimmed;
    }
    final sanitized = uri.replace(
      fragment: '',
      queryParameters: Map<String, String>.fromEntries(
        uri.queryParameters.entries.where(
          (MapEntry<String, String> entry) =>
              !entry.key.toLowerCase().startsWith('utm_'),
        ),
      ),
    );
    return sanitized.toString();
  }

  String _normalizeCacheKey(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'https?://'), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  String _normalizeWhitespace(String input) {
    return input.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<String> _splitIntoSentences(String text) {
    return text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map(_normalizeWhitespace)
        .where((String sentence) => sentence.isNotEmpty)
        .toList();
  }

  String _toCalmBullet(String input) {
    final cleaned = _trimToWords(
      _normalizeWhitespace(
        input
            .replaceAll(RegExp(r'^[•\-\s]+'), '')
            .replaceAll(RegExp(r'\s*[—-]\s*'), ' ')
            .replaceAll(RegExp(r'!+'), '.'),
      ),
      18,
    );

    if (cleaned.isEmpty) {
      return '';
    }

    final sentence = cleaned[0].toUpperCase() + cleaned.substring(1);
    return sentence.endsWith('.') ? sentence : '$sentence.';
  }

  String _cleanHeadline(String input) {
    return _normalizeWhitespace(
      input
          .replaceAll(RegExp(r'\s*[|\-–—]\s*[^|\-–—]+$'), '')
          .replaceAll(RegExp(r'["“”]'), ''),
    );
  }

  String _trimToWords(String text, int maxWords) {
    final normalized = _normalizeWhitespace(text);
    if (normalized.isEmpty) {
      return '';
    }
    final words = normalized.split(' ');
    if (words.length <= maxWords) {
      return words.join(' ').trim();
    }
    return '${words.take(maxWords).join(' ').trim()}…';
  }

  String _cleanToken(String? input) {
    return _normalizeWhitespace(input ?? '');
  }

  String _cleanCountyOrMetro(String input) {
    return _normalizeWhitespace(
      input.replaceAll(RegExp(r'^(county of)\s+', caseSensitive: false), ''),
    );
  }

  String _joinLocationLabel(String city, String region, String country) {
    final parts = <String>[
      if (city.isNotEmpty) city,
      if (region.isNotEmpty && region.toLowerCase() != city.toLowerCase()) region,
      if (country.isNotEmpty &&
          country.toLowerCase() != region.toLowerCase() &&
          country.toLowerCase() != city.toLowerCase())
        country,
    ];
    return parts.join(', ');
  }
}

class _ParsedLabel {
  const _ParsedLabel({
    required this.city,
    required this.stateOrRegion,
    required this.country,
    required this.countyOrMetro,
  });

  final String city;
  final String stateOrRegion;
  final String country;
  final String countyOrMetro;
}

enum _SerpSearchKind {
  localNews,
  newsResults,
}

class _SerpSearchMode {
  const _SerpSearchMode({
    required this.kind,
    required this.uri,
  });

  final _SerpSearchKind kind;
  final Uri uri;
}

extension _FirstOrNullExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
