import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/recipe_result.dart';

class RecipesException implements Exception {
  const RecipesException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RecipesService {
  RecipesService({
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
  static const Duration _resultTtl = Duration(hours: 4);
  static const Duration _requestTimeout = Duration(seconds: 10);
  static const int _recipeLimit = 3;
  static const String _resultCacheKey = 'recipes_result_v1';
  static const List<String> _queryFallbackChain = <String>[
    'healthy dinner recipes',
    'easy dinner recipes',
    'recipes to try this week',
    'quick weeknight recipes',
  ];

  Future<RecipeResult> fetchRecipes({bool forceRefresh = false}) async {
    final prefs = await _sharedPreferencesFuture;
    final cached = await readCachedResult();
    final hasFreshCache = cached != null &&
        _now().difference(cached.generatedAt) <= _resultTtl &&
        cached.recipes.isNotEmpty;

    if (!forceRefresh && hasFreshCache) {
      return cached;
    }

    try {
      final apiKey = _apiKey ?? AppConfig.serpApiKey;
      if (apiKey.trim().isEmpty) {
        throw const RecipesException(
          'SerpApi key is missing in AppConfig.serpApiKey for the Recipes POC.',
        );
      }

      final fetched = await _fetchRecipesFromQueries(
        apiKey: apiKey,
        forceRefresh: forceRefresh,
      );
      final recipes = dedupeRecipes(fetched.recipes).take(_recipeLimit).toList();

      if (recipes.isEmpty) {
        throw const RecipesException(
          'We could not find recipe ideas just now. Please try again in a moment.',
        );
      }

      final result = RecipeResult(
        recipes: recipes,
        generatedAt: _now(),
        isStale: false,
        usedCache: false,
        isPartial: recipes.length < _recipeLimit,
        queryUsed: fetched.queryUsed,
        errorMessage: null,
      );
      await prefs.setString(_resultCacheKey, jsonEncode(result.toMap()));
      return result;
    } catch (error) {
      if (cached != null && cached.recipes.isNotEmpty) {
        return RecipeResult(
          recipes: cached.recipes,
          generatedAt: cached.generatedAt,
          isStale: true,
          usedCache: true,
          isPartial: cached.isPartial,
          queryUsed: cached.queryUsed,
          errorMessage: error.toString(),
        );
      }
      rethrow;
    }
  }

  Future<RecipeResult?> readCachedResult() async {
    final prefs = await _sharedPreferencesFuture;
    final raw = prefs.getString(_resultCacheKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return RecipeResult.fromMap(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  List<String> buildQueryFallbackChain() => List<String>.from(_queryFallbackChain);

  RecipeCard parseSerpApiRecipe(Map<String, dynamic> raw) {
    final title = _normalizeWhitespace(raw['title'] as String? ?? '');
    final link = _canonicalizeUrl(raw['link'] as String? ?? '');
    final ingredients = ((raw['ingredients'] as List?) ?? const <dynamic>[])
        .map((dynamic item) => _normalizeWhitespace(item.toString()))
        .where((String item) => item.isNotEmpty)
        .toList();

    return RecipeCard(
      id: _recipeId(link, title),
      title: title,
      link: link,
      source: _normalizeWhitespace(raw['source'] as String? ?? ''),
      thumbnailUrl: _normalizeWhitespace(raw['thumbnail'] as String? ?? ''),
      totalTime: _normalizeWhitespace(raw['total_time'] as String? ?? ''),
      rating: _parseDouble(raw['rating']),
      reviews: _parseInt(raw['reviews']),
      ingredients: ingredients,
      totalIngredients: _parseInt(raw['total_ingredients']),
      badge: _normalizeWhitespace(raw['badge'] as String? ?? ''),
      video: _normalizeWhitespace(raw['video'] as String? ?? ''),
    );
  }

  List<RecipeCard> dedupeRecipes(Iterable<RecipeCard> recipes) {
    final seenKeys = <String>{};
    final deduped = <RecipeCard>[];

    for (final recipe in recipes) {
      final key = recipe.link.isNotEmpty
          ? recipe.link
          : _normalizeCacheKey(recipe.title.toLowerCase());
      if (seenKeys.add(key)) {
        deduped.add(recipe);
      }
    }

    return deduped;
  }

  Future<_RecipeSearchResponse> _fetchRecipesFromQueries({
    required String apiKey,
    required bool forceRefresh,
  }) async {
    final aggregated = <RecipeCard>[];
    var lastQuery = '';

    for (final query in _queryFallbackChain) {
      lastQuery = query;
      final response = await _getJson(
        Uri.parse(_serpApiBaseUrl).replace(
          queryParameters: <String, String>{
            'engine': 'google',
            'q': query,
            'hl': 'en',
            'gl': 'us',
            'num': '10',
            'api_key': apiKey,
            if (forceRefresh) 'no_cache': 'true',
          },
        ),
      );

      final recipes = ((response['recipes_results'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((Map item) => parseSerpApiRecipe(Map<String, dynamic>.from(item)))
          .where(
            (RecipeCard recipe) =>
                recipe.title.isNotEmpty && recipe.link.startsWith('http'),
          )
          .toList();

      aggregated.addAll(recipes);
      final deduped = dedupeRecipes(aggregated);
      if (deduped.length >= _recipeLimit) {
        return _RecipeSearchResponse(recipes: deduped, queryUsed: query);
      }
    }

    return _RecipeSearchResponse(
      recipes: dedupeRecipes(aggregated),
      queryUsed: lastQuery,
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _httpClient.get(uri).timeout(_requestTimeout);
    if (response.statusCode != 200) {
      throw RecipesException(
        'Recipes search returned ${response.statusCode}. Please try again soon.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const RecipesException('Recipes search returned an unexpected response.');
    }

    return Map<String, dynamic>.from(decoded as Map);
  }

  String _recipeId(String link, String title) {
    final source = link.isNotEmpty ? link : title;
    return _normalizeCacheKey(source);
  }

  String _canonicalizeUrl(String url) {
    final trimmed = _normalizeWhitespace(url);
    if (trimmed.isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return trimmed;
    }

    final filteredQuery = Map<String, String>.fromEntries(
      uri.queryParameters.entries.where(
        (MapEntry<String, String> entry) =>
            !entry.key.toLowerCase().startsWith('utm_') &&
            entry.key.toLowerCase() != 'ref',
      ),
    );

    return uri.replace(
      queryParameters: filteredQuery.isEmpty ? null : filteredQuery,
      fragment: '',
    ).toString();
  }

  String _normalizeWhitespace(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _normalizeCacheKey(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'https?://'), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  double? _parseDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  int? _parseInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    }
    return null;
  }
}

class _RecipeSearchResponse {
  const _RecipeSearchResponse({
    required this.recipes,
    required this.queryUsed,
  });

  final List<RecipeCard> recipes;
  final String queryUsed;
}
