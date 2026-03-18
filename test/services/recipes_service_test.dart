import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nana_poc/models/recipe_result.dart';
import 'package:nana_poc/services/recipes_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime fixedNow;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    fixedNow = DateTime(2026, 3, 18, 12);
  });

  test('builds the expected recipes fallback queries', () {
    final service = RecipesService(
      sharedPreferences: SharedPreferences.getInstance(),
      now: () => fixedNow,
      apiKey: 'test-key',
    );

    expect(
      service.buildQueryFallbackChain(),
      const <String>[
        'healthy dinner recipes',
        'easy dinner recipes',
        'recipes to try this week',
        'quick weeknight recipes',
      ],
    );
  });

  test('parses and deduplicates recipe results by canonical url', () {
    final service = RecipesService(
      sharedPreferences: SharedPreferences.getInstance(),
      now: () => fixedNow,
      apiKey: 'test-key',
    );

    final recipeA = service.parseSerpApiRecipe(<String, dynamic>{
      'title': 'Lemon Chicken Orzo',
      'link':
          'https://example.com/lemon-chicken-orzo?utm_source=newsletter&utm_medium=email',
      'source': 'Example Kitchen',
      'rating': 4.7,
      'reviews': 212,
      'total_time': '35 min',
      'ingredients': <String>['Lemon', 'Chicken', 'Orzo'],
      'total_ingredients': 8,
      'thumbnail': 'https://images.example.com/orzo.jpg',
    });
    final recipeB = service.parseSerpApiRecipe(<String, dynamic>{
      'title': 'Lemon Chicken Orzo',
      'link': 'https://example.com/lemon-chicken-orzo',
      'source': 'Example Kitchen',
    });

    final deduped = service.dedupeRecipes(<RecipeCard>[recipeA, recipeB]);

    expect(deduped, hasLength(1));
    expect(deduped.single.link, 'https://example.com/lemon-chicken-orzo');
    expect(deduped.single.totalIngredients, 8);
    expect(deduped.single.rating, 4.7);
  });

  test('falls back across queries and returns a partial result when fewer than three unique recipes exist', () async {
    var requests = 0;
    final client = MockClient((http.Request request) async {
      requests++;
      final query = request.url.queryParameters['q'];
      if (query == 'healthy dinner recipes') {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'recipes_results': <Map<String, dynamic>>[
              <String, dynamic>{
                'title': 'Herby Salmon Bowl',
                'link': 'https://example.com/herby-salmon-bowl',
                'source': 'Kitchen One',
                'total_time': '25 min',
                'thumbnail': 'https://images.example.com/salmon.jpg',
              },
              <String, dynamic>{
                'title': 'Warm Lentil Skillet',
                'link': 'https://example.com/warm-lentil-skillet',
                'source': 'Kitchen Two',
                'total_time': '30 min',
                'thumbnail': 'https://images.example.com/lentils.jpg',
              },
            ],
          }),
          200,
        );
      }
      return http.Response(jsonEncode(<String, dynamic>{'recipes_results': const <dynamic>[]}), 200);
    });

    final service = RecipesService(
      httpClient: client,
      sharedPreferences: SharedPreferences.getInstance(),
      now: () => fixedNow,
      apiKey: 'test-key',
    );

    final result = await service.fetchRecipes(forceRefresh: true);

    expect(result.recipes, hasLength(2));
    expect(result.isPartial, isTrue);
    expect(result.queryUsed, 'quick weeknight recipes');
    expect(requests, 4);
  });

  test('returns stale cached recipes when refresh fails', () async {
    final prefs = await SharedPreferences.getInstance();
    final cached = RecipeResult(
      recipes: const <RecipeCard>[
        RecipeCard(
          id: 'recipe-1',
          title: 'Saved Pasta',
          link: 'https://example.com/saved-pasta',
          source: 'Saved Kitchen',
          thumbnailUrl: '',
          totalTime: '20 min',
          rating: 4.5,
          reviews: 88,
          ingredients: <String>['Pasta', 'Garlic'],
          totalIngredients: 6,
          badge: '',
          video: '',
        ),
      ],
      generatedAt: fixedNow.subtract(const Duration(hours: 5)),
      isStale: false,
      usedCache: false,
      isPartial: true,
      queryUsed: 'healthy dinner recipes',
      errorMessage: null,
    );
    await prefs.setString('recipes_result_v1', jsonEncode(cached.toMap()));

    final service = RecipesService(
      httpClient: MockClient((http.Request request) async {
        return http.Response('nope', 500);
      }),
      sharedPreferences: Future<SharedPreferences>.value(prefs),
      now: () => fixedNow,
      apiKey: 'test-key',
    );

    final result = await service.fetchRecipes(forceRefresh: true);

    expect(result.usedCache, isTrue);
    expect(result.isStale, isTrue);
    expect(result.recipes.single.title, 'Saved Pasta');
  });
}
