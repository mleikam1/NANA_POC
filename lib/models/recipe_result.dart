class RecipeResult {
  const RecipeResult({
    required this.recipes,
    required this.generatedAt,
    required this.isStale,
    required this.usedCache,
    required this.isPartial,
    required this.queryUsed,
    required this.errorMessage,
  });

  final List<RecipeCard> recipes;
  final DateTime generatedAt;
  final bool isStale;
  final bool usedCache;
  final bool isPartial;
  final String queryUsed;
  final String? errorMessage;

  factory RecipeResult.fromMap(Map<String, dynamic> map) {
    return RecipeResult(
      recipes: ((map['recipes'] as List?) ?? const <dynamic>[])
          .map(
            (dynamic item) =>
                RecipeCard.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      generatedAt: DateTime.tryParse(map['generatedAt'] as String? ?? '') ??
          DateTime.now(),
      isStale: map['isStale'] as bool? ?? false,
      usedCache: map['usedCache'] as bool? ?? false,
      isPartial: map['isPartial'] as bool? ?? false,
      queryUsed: map['queryUsed'] as String? ?? '',
      errorMessage: map['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'recipes': recipes.map((RecipeCard recipe) => recipe.toMap()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
      'isStale': isStale,
      'usedCache': usedCache,
      'isPartial': isPartial,
      'queryUsed': queryUsed,
      'errorMessage': errorMessage,
    };
  }
}

class RecipeCard {
  const RecipeCard({
    required this.id,
    required this.title,
    required this.link,
    required this.source,
    required this.thumbnailUrl,
    required this.totalTime,
    required this.rating,
    required this.reviews,
    required this.ingredients,
    required this.totalIngredients,
    required this.badge,
    required this.video,
  });

  final String id;
  final String title;
  final String link;
  final String source;
  final String thumbnailUrl;
  final String totalTime;
  final double? rating;
  final int? reviews;
  final List<String> ingredients;
  final int? totalIngredients;
  final String badge;
  final String video;

  factory RecipeCard.fromMap(Map<String, dynamic> map) {
    return RecipeCard(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      link: map['link'] as String? ?? '',
      source: map['source'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      totalTime: map['totalTime'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble(),
      reviews: map['reviews'] as int?,
      ingredients: List<String>.from(map['ingredients'] as List? ?? const []),
      totalIngredients: map['totalIngredients'] as int?,
      badge: map['badge'] as String? ?? '',
      video: map['video'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'link': link,
      'source': source,
      'thumbnailUrl': thumbnailUrl,
      'totalTime': totalTime,
      'rating': rating,
      'reviews': reviews,
      'ingredients': ingredients,
      'totalIngredients': totalIngredients,
      'badge': badge,
      'video': video,
    };
  }
}
