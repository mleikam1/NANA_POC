class LocalNewsStory {
  const LocalNewsStory({
    required this.id,
    required this.rank,
    required this.title,
    required this.url,
    required this.source,
    required this.snippet,
    required this.thumbnailUrl,
    required this.publishedAt,
    required this.relativeTimeLabel,
    required this.calmHeadline,
    required this.bullets,
    required this.readTimeLabel,
    required this.extractionFailed,
    required this.fromCache,
  });

  final String id;
  final int rank;
  final String title;
  final String url;
  final String source;
  final String snippet;
  final String thumbnailUrl;
  final DateTime? publishedAt;
  final String relativeTimeLabel;
  final String calmHeadline;
  final List<String> bullets;
  final String readTimeLabel;
  final bool extractionFailed;
  final bool fromCache;

  LocalNewsStory copyWith({
    String? id,
    int? rank,
    String? title,
    String? url,
    String? source,
    String? snippet,
    String? thumbnailUrl,
    DateTime? publishedAt,
    String? relativeTimeLabel,
    String? calmHeadline,
    List<String>? bullets,
    String? readTimeLabel,
    bool? extractionFailed,
    bool? fromCache,
  }) {
    return LocalNewsStory(
      id: id ?? this.id,
      rank: rank ?? this.rank,
      title: title ?? this.title,
      url: url ?? this.url,
      source: source ?? this.source,
      snippet: snippet ?? this.snippet,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      relativeTimeLabel: relativeTimeLabel ?? this.relativeTimeLabel,
      calmHeadline: calmHeadline ?? this.calmHeadline,
      bullets: bullets ?? this.bullets,
      readTimeLabel: readTimeLabel ?? this.readTimeLabel,
      extractionFailed: extractionFailed ?? this.extractionFailed,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'rank': rank,
      'title': title,
      'url': url,
      'source': source,
      'snippet': snippet,
      'thumbnailUrl': thumbnailUrl,
      'publishedAt': publishedAt?.toIso8601String(),
      'relativeTimeLabel': relativeTimeLabel,
      'calmHeadline': calmHeadline,
      'bullets': bullets,
      'readTimeLabel': readTimeLabel,
      'extractionFailed': extractionFailed,
      'fromCache': fromCache,
    };
  }

  factory LocalNewsStory.fromMap(Map<String, dynamic> map) {
    return LocalNewsStory(
      id: map['id'] as String? ?? '',
      rank: map['rank'] as int? ?? 0,
      title: map['title'] as String? ?? '',
      url: map['url'] as String? ?? '',
      source: map['source'] as String? ?? '',
      snippet: map['snippet'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      publishedAt: DateTime.tryParse(map['publishedAt'] as String? ?? ''),
      relativeTimeLabel: map['relativeTimeLabel'] as String? ?? '',
      calmHeadline: map['calmHeadline'] as String? ?? '',
      bullets: List<String>.from(map['bullets'] as List? ?? const <String>[]),
      readTimeLabel: map['readTimeLabel'] as String? ?? '',
      extractionFailed: map['extractionFailed'] as bool? ?? false,
      fromCache: map['fromCache'] as bool? ?? false,
    );
  }
}

class LocalNewsLocation {
  const LocalNewsLocation({
    required this.label,
    required this.normalizedCacheKey,
    required this.city,
    required this.stateOrRegion,
    required this.country,
    required this.countyOrMetro,
    this.latitude,
    this.longitude,
  });

  final String label;
  final String normalizedCacheKey;
  final String city;
  final String stateOrRegion;
  final String country;
  final String countyOrMetro;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'label': label,
      'normalizedCacheKey': normalizedCacheKey,
      'city': city,
      'stateOrRegion': stateOrRegion,
      'country': country,
      'countyOrMetro': countyOrMetro,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory LocalNewsLocation.fromMap(Map<String, dynamic> map) {
    return LocalNewsLocation(
      label: map['label'] as String? ?? '',
      normalizedCacheKey: map['normalizedCacheKey'] as String? ?? '',
      city: map['city'] as String? ?? '',
      stateOrRegion: map['stateOrRegion'] as String? ?? '',
      country: map['country'] as String? ?? '',
      countyOrMetro: map['countyOrMetro'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}

class LocalNewsResult {
  const LocalNewsResult({
    required this.location,
    required this.stories,
    required this.generatedAt,
    required this.isStale,
    required this.usedCache,
    required this.isPartial,
    required this.errorMessage,
  });

  final LocalNewsLocation location;
  final List<LocalNewsStory> stories;
  final DateTime generatedAt;
  final bool isStale;
  final bool usedCache;
  final bool isPartial;
  final String? errorMessage;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'location': location.toMap(),
      'stories': stories.map((LocalNewsStory story) => story.toMap()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
      'isStale': isStale,
      'usedCache': usedCache,
      'isPartial': isPartial,
      'errorMessage': errorMessage,
    };
  }

  factory LocalNewsResult.fromMap(Map<String, dynamic> map) {
    return LocalNewsResult(
      location: LocalNewsLocation.fromMap(
        Map<String, dynamic>.from(map['location'] as Map? ?? const <String, dynamic>{}),
      ),
      stories: ((map['stories'] as List?) ?? const <dynamic>[])
          .map(
            (dynamic item) =>
                LocalNewsStory.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      generatedAt:
          DateTime.tryParse(map['generatedAt'] as String? ?? '') ?? DateTime.now(),
      isStale: map['isStale'] as bool? ?? false,
      usedCache: map['usedCache'] as bool? ?? false,
      isPartial: map['isPartial'] as bool? ?? false,
      errorMessage: map['errorMessage'] as String?,
    );
  }
}
