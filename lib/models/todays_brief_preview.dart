enum BriefPreviewSectionKind {
  weather,
  recipes,
  videos,
  curated,
  roundup,
}

class TodaysBriefPreview {
  const TodaysBriefPreview({
    required this.generatedAt,
    required this.topics,
    required this.sections,
  });

  final DateTime generatedAt;
  final List<String> topics;
  final List<BriefPreviewSection> sections;
}

class BriefPreviewSection {
  const BriefPreviewSection({
    required this.topic,
    required this.kind,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.items,
    this.weather,
    this.errorMessage,
  });

  final String topic;
  final BriefPreviewSectionKind kind;
  final String eyebrow;
  final String title;
  final String description;
  final List<BriefPreviewItem> items;
  final BriefPreviewWeather? weather;
  final String? errorMessage;
}

class BriefPreviewItem {
  const BriefPreviewItem({
    required this.title,
    required this.subtitle,
    required this.source,
    required this.badge,
    this.link,
    this.metadata = const <String, String>{},
  });

  final String title;
  final String subtitle;
  final String source;
  final String badge;
  final String? link;
  final Map<String, String> metadata;
}

class BriefPreviewWeather {
  const BriefPreviewWeather({
    required this.location,
    required this.temperature,
    required this.condition,
    required this.high,
    required this.low,
    required this.hourly,
  });

  final String location;
  final String temperature;
  final String condition;
  final String high;
  final String low;
  final List<BriefPreviewWeatherHour> hourly;
}

class BriefPreviewWeatherHour {
  const BriefPreviewWeatherHour({
    required this.label,
    required this.temperature,
    required this.condition,
  });

  final String label;
  final String temperature;
  final String condition;
}
