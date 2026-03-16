class BriefingBundle {
  const BriefingBundle({
    required this.weather,
    required this.localNews,
    required this.recipes,
    required this.shortVideos,
    required this.aiOverviewTitle,
    required this.aiOverviewBullets,
    required this.generatedAt,
  });

  final WeatherSummary? weather;
  final List<ContentCard> localNews;
  final List<ContentCard> recipes;
  final List<ContentCard> shortVideos;
  final String aiOverviewTitle;
  final List<String> aiOverviewBullets;
  final DateTime generatedAt;

  factory BriefingBundle.fromMap(Map<String, dynamic> map) {
    return BriefingBundle(
      weather: map['weather'] == null
          ? null
          : WeatherSummary.fromMap(
              Map<String, dynamic>.from(map['weather'] as Map),
            ),
      localNews: ((map['localNews'] as List?) ?? const [])
          .map((dynamic item) =>
              ContentCard.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
      recipes: ((map['recipes'] as List?) ?? const [])
          .map((dynamic item) =>
              ContentCard.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
      shortVideos: ((map['shortVideos'] as List?) ?? const [])
          .map((dynamic item) =>
              ContentCard.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
      aiOverviewTitle: map['aiOverviewTitle'] as String? ?? 'Today’s calm take',
      aiOverviewBullets:
          List<String>.from(map['aiOverviewBullets'] as List? ?? const []),
      generatedAt: DateTime.tryParse(map['generatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'weather': weather?.toMap(),
      'localNews': localNews.map((card) => card.toMap()).toList(),
      'recipes': recipes.map((card) => card.toMap()).toList(),
      'shortVideos': shortVideos.map((card) => card.toMap()).toList(),
      'aiOverviewTitle': aiOverviewTitle,
      'aiOverviewBullets': aiOverviewBullets,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}

class WeatherSummary {
  const WeatherSummary({
    required this.location,
    required this.temperature,
    required this.unit,
    required this.weather,
    required this.humidity,
    required this.wind,
    required this.date,
    required this.thumbnail,
    required this.forecast,
    required this.hourlyForecast,
  });

  final String location;
  final String temperature;
  final String unit;
  final String weather;
  final String humidity;
  final String wind;
  final String date;
  final String thumbnail;
  final List<WeatherForecastDay> forecast;
  final List<WeatherForecastHour> hourlyForecast;

  factory WeatherSummary.fromMap(Map<String, dynamic> map) {
    return WeatherSummary(
      location: map['location'] as String? ?? '',
      temperature: map['temperature'] as String? ?? '',
      unit: map['unit'] as String? ?? 'F',
      weather: map['weather'] as String? ?? '',
      humidity: map['humidity'] as String? ?? '',
      wind: map['wind'] as String? ?? '',
      date: map['date'] as String? ?? '',
      thumbnail: map['thumbnail'] as String? ?? '',
      forecast: ((map['forecast'] as List?) ?? const [])
          .map((dynamic item) => WeatherForecastDay.fromMap(
              Map<String, dynamic>.from(item as Map)))
          .toList(),
      hourlyForecast: ((map['hourlyForecast'] as List?) ?? const [])
          .map((dynamic item) => WeatherForecastHour.fromMap(
              Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'location': location,
      'temperature': temperature,
      'unit': unit,
      'weather': weather,
      'humidity': humidity,
      'wind': wind,
      'date': date,
      'thumbnail': thumbnail,
      'forecast': forecast.map((item) => item.toMap()).toList(),
      'hourlyForecast': hourlyForecast.map((item) => item.toMap()).toList(),
    };
  }
}

class WeatherForecastDay {
  const WeatherForecastDay({
    required this.day,
    required this.high,
    required this.low,
    required this.weather,
  });

  final String day;
  final String high;
  final String low;
  final String weather;

  factory WeatherForecastDay.fromMap(Map<String, dynamic> map) {
    return WeatherForecastDay(
      day: map['day'] as String? ?? '',
      high: map['high'] as String? ?? '',
      low: map['low'] as String? ?? '',
      weather: map['weather'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'day': day,
      'high': high,
      'low': low,
      'weather': weather,
    };
  }
}

class WeatherForecastHour {
  const WeatherForecastHour({
    required this.time,
    required this.temperature,
    required this.weather,
  });

  final String time;
  final String temperature;
  final String weather;

  factory WeatherForecastHour.fromMap(Map<String, dynamic> map) {
    return WeatherForecastHour(
      time: map['time'] as String? ?? '',
      temperature: map['temperature'] as String? ?? '',
      weather: map['weather'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'time': time,
      'temperature': temperature,
      'weather': weather,
    };
  }
}

class ContentCard {
  const ContentCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.source,
    required this.link,
    required this.imageUrl,
    required this.label,
    required this.metadata,
  });

  final String id;
  final String title;
  final String subtitle;
  final String source;
  final String link;
  final String imageUrl;
  final String label;
  final Map<String, dynamic> metadata;

  factory ContentCard.fromMap(Map<String, dynamic> map) {
    return ContentCard(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      source: map['source'] as String? ?? '',
      link: map['link'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      label: map['label'] as String? ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? const {}),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'source': source,
      'link': link,
      'imageUrl': imageUrl,
      'label': label,
      'metadata': metadata,
    };
  }
}
