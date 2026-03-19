import 'onboarding_topic.dart';

class SelectedBriefTopic {
  const SelectedBriefTopic({
    required this.topic,
    required this.label,
  });

  final OnboardingTopic topic;
  final String label;

  String get id => topic.storageKey;

  factory SelectedBriefTopic.fromTopic(OnboardingTopic topic) {
    return SelectedBriefTopic(topic: topic, label: topic.label);
  }

  factory SelectedBriefTopic.fromStoredValue(String value) {
    final resolved = OnboardingTopic.fromStoredValue(value);
    if (resolved == null) {
      throw ArgumentError.value(value, 'value', 'Unknown onboarding topic');
    }
    return SelectedBriefTopic.fromTopic(resolved);
  }

  static List<SelectedBriefTopic> fromIterable(Iterable<dynamic> values) {
    final ordered = <SelectedBriefTopic>[];
    final seen = <String>{};

    for (final value in values) {
      final SelectedBriefTopic? resolved;
      if (value is SelectedBriefTopic) {
        resolved = value;
      } else if (value is OnboardingTopic) {
        resolved = SelectedBriefTopic.fromTopic(value);
      } else if (value is String) {
        final topic = OnboardingTopic.fromStoredValue(value.trim());
        resolved = topic == null ? null : SelectedBriefTopic.fromTopic(topic);
      } else {
        resolved = null;
      }

      if (resolved == null || !seen.add(resolved.id)) {
        continue;
      }
      ordered.add(resolved);
    }

    return ordered;
  }
}

enum BriefSectionKind {
  roundup,
  weather,
  recipes,
  videos,
  curated,
  events,
}

enum BriefSectionLoadState {
  idle,
  loading,
  ready,
  error,
}

class BriefContentItem {
  const BriefContentItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.source,
    required this.badge,
    this.link,
    this.imageUrl,
    this.metadata = const <String, String>{},
  });

  final String id;
  final String title;
  final String subtitle;
  final String source;
  final String badge;
  final String? link;
  final String? imageUrl;
  final Map<String, String> metadata;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'source': source,
      'badge': badge,
      'link': link,
      'imageUrl': imageUrl,
      'metadata': metadata,
    };
  }

  factory BriefContentItem.fromMap(Map<String, dynamic> map) {
    return BriefContentItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      source: map['source'] as String? ?? '',
      badge: map['badge'] as String? ?? '',
      link: map['link'] as String?,
      imageUrl: map['imageUrl'] as String?,
      metadata: Map<String, String>.from(
        map['metadata'] as Map? ?? const <String, String>{},
      ),
    );
  }
}

class BriefSection {
  const BriefSection({
    required this.topic,
    required this.kind,
    required this.state,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.items,
    required this.generatedAt,
    this.summary,
    this.errorMessage,
    this.queryUsed,
    this.isFromCache = false,
    this.isStale = false,
  });

  final SelectedBriefTopic topic;
  final BriefSectionKind kind;
  final BriefSectionLoadState state;
  final String eyebrow;
  final String title;
  final String description;
  final String? summary;
  final List<BriefContentItem> items;
  final DateTime generatedAt;
  final String? errorMessage;
  final String? queryUsed;
  final bool isFromCache;
  final bool isStale;

  BriefSection copyWith({
    SelectedBriefTopic? topic,
    BriefSectionKind? kind,
    BriefSectionLoadState? state,
    String? eyebrow,
    String? title,
    String? description,
    String? summary,
    List<BriefContentItem>? items,
    DateTime? generatedAt,
    String? errorMessage,
    String? queryUsed,
    bool? isFromCache,
    bool? isStale,
  }) {
    return BriefSection(
      topic: topic ?? this.topic,
      kind: kind ?? this.kind,
      state: state ?? this.state,
      eyebrow: eyebrow ?? this.eyebrow,
      title: title ?? this.title,
      description: description ?? this.description,
      summary: summary ?? this.summary,
      items: items ?? this.items,
      generatedAt: generatedAt ?? this.generatedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      queryUsed: queryUsed ?? this.queryUsed,
      isFromCache: isFromCache ?? this.isFromCache,
      isStale: isStale ?? this.isStale,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'topic': topic.id,
      'kind': kind.name,
      'state': state.name,
      'eyebrow': eyebrow,
      'title': title,
      'description': description,
      'summary': summary,
      'items': items.map((BriefContentItem item) => item.toMap()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
      'errorMessage': errorMessage,
      'queryUsed': queryUsed,
      'isFromCache': isFromCache,
      'isStale': isStale,
    };
  }

  factory BriefSection.fromMap(Map<String, dynamic> map) {
    final topicValue = map['topic'] as String? ?? OnboardingTopic.localNews.storageKey;
    final resolvedTopic = OnboardingTopic.fromStoredValue(topicValue) ??
        OnboardingTopic.localNews;

    return BriefSection(
      topic: SelectedBriefTopic.fromTopic(resolvedTopic),
      kind: BriefSectionKind.values.byName(
        map['kind'] as String? ?? BriefSectionKind.roundup.name,
      ),
      state: BriefSectionLoadState.values.byName(
        map['state'] as String? ?? BriefSectionLoadState.ready.name,
      ),
      eyebrow: map['eyebrow'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      summary: map['summary'] as String?,
      items: ((map['items'] as List?) ?? const <dynamic>[])
          .map(
            (dynamic item) => BriefContentItem.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      generatedAt: DateTime.tryParse(map['generatedAt'] as String? ?? '') ??
          DateTime.now(),
      errorMessage: map['errorMessage'] as String?,
      queryUsed: map['queryUsed'] as String?,
      isFromCache: map['isFromCache'] as bool? ?? false,
      isStale: map['isStale'] as bool? ?? false,
    );
  }
}

class BriefPage {
  const BriefPage({
    required this.generatedAt,
    required this.selectedTopics,
    required this.sections,
  });

  final DateTime generatedAt;
  final List<SelectedBriefTopic> selectedTopics;
  final List<BriefSection> sections;
}
