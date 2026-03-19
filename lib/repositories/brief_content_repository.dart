import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user_profile.dart';
import '../models/brief_content.dart';
import '../models/onboarding_topic.dart';
import 'package:http/http.dart' as http;
import '../services/brief_content_service.dart';
import '../services/local_news_service.dart';
import '../services/recipes_service.dart';
import 'topic_preferences_repository.dart';

class BriefContentRepository {
  BriefContentRepository({
    BriefContentService? briefContentService,
    TopicPreferencesRepository? topicPreferencesRepository,
    Future<SharedPreferences>? sharedPreferences,
    DateTime Function()? now,
    http.Client? httpClient,
    LocalNewsService? localNewsService,
    RecipesService? recipesService,
    String? apiKey,
  })  : _topicPreferencesRepository =
            topicPreferencesRepository ?? TopicPreferencesRepository(),
        _sharedPreferencesFuture =
            sharedPreferences ?? SharedPreferences.getInstance(),
        _now = now ?? DateTime.now,
        _briefContentService =
            briefContentService ??
                BriefContentService(
                  httpClient: httpClient,
                  localNewsService: localNewsService,
                  recipesService: recipesService,
                  now: now,
                  apiKey: apiKey,
                );

  final BriefContentService _briefContentService;
  final TopicPreferencesRepository _topicPreferencesRepository;
  final Future<SharedPreferences> _sharedPreferencesFuture;
  final DateTime Function() _now;

  static const Duration _cacheTtl = Duration(minutes: 30);
  static const String _cachePrefix = 'brief_content_section_v1_';

  final Map<String, _MemorySectionCacheEntry> _memoryCache =
      <String, _MemorySectionCacheEntry>{};

  Future<BriefPage> loadBriefPage(
    AppUserProfile profile, {
    Iterable<dynamic>? selectedTopics,
    bool forceRefresh = false,
  }) async {
    final resolvedTopics = await _resolveSelectedTopics(profile, selectedTopics);
    final location = await _briefContentService.resolveLocationContext(profile);

    final sections = await Future.wait(
      resolvedTopics.map(
        (SelectedBriefTopic topic) => _loadSection(
          topic: topic,
          profile: profile,
          location: location,
          forceRefresh: forceRefresh,
        ),
      ),
    );

    return BriefPage(
      generatedAt: _now(),
      selectedTopics: resolvedTopics,
      sections: sections,
    );
  }

  Future<BriefSection> _loadSection({
    required SelectedBriefTopic topic,
    required AppUserProfile profile,
    required BriefLocationContext location,
    required bool forceRefresh,
  }) async {
    final cacheKey = _cacheKey(topic, location);
    final cached = forceRefresh ? null : await _readCachedSection(cacheKey);
    final isCacheFresh = cached != null &&
        _now().difference(cached.generatedAt) <= _cacheTtl &&
        cached.state == BriefSectionLoadState.ready;

    if (isCacheFresh) {
      return cached.copyWith(isFromCache: true);
    }

    try {
      final fetched = await _briefContentService.fetchSection(
        topic: topic,
        profile: profile,
        location: location,
        forceRefresh: forceRefresh,
      );
      await _writeCachedSection(cacheKey, fetched);
      return fetched;
    } catch (error) {
      if (cached != null) {
        return cached.copyWith(
          isFromCache: true,
          isStale: true,
          errorMessage: error.toString(),
        );
      }

      return BriefSection(
        topic: topic,
        kind: _fallbackKind(topic.topic),
        state: BriefSectionLoadState.error,
        eyebrow: _fallbackEyebrow(topic.topic),
        title: topic.label,
        description: 'This section could not be refreshed right now.',
        summary: null,
        items: const <BriefContentItem>[],
        generatedAt: _now(),
        errorMessage: error.toString(),
        queryUsed: null,
        isFromCache: false,
        isStale: false,
      );
    }
  }

  Future<List<SelectedBriefTopic>> _resolveSelectedTopics(
    AppUserProfile profile,
    Iterable<dynamic>? selectedTopics,
  ) async {
    if (selectedTopics != null) {
      final explicit = SelectedBriefTopic.fromIterable(selectedTopics);
      if (explicit.isNotEmpty) {
        return explicit;
      }
    }

    final stored = await _topicPreferencesRepository.readSelectedTopics();
    final topicValues = stored.isNotEmpty
        ? stored
        : TopicPreferencesRepository.stabilizeTopics(profile.topics);
    final resolved = topicValues.isNotEmpty
        ? topicValues
        : OnboardingTopic.defaultSelection;

    return resolved
        .map(SelectedBriefTopic.fromTopic)
        .toList(growable: false);
  }

  Future<BriefSection?> _readCachedSection(String cacheKey) async {
    final memoryHit = _memoryCache[cacheKey];
    if (memoryHit != null) {
      return memoryHit.section;
    }

    final prefs = await _sharedPreferencesFuture;
    final raw = prefs.getString('$_cachePrefix$cacheKey');
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final section = BriefSection.fromMap(decoded);
      _memoryCache[cacheKey] = _MemorySectionCacheEntry(section);
      return section;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCachedSection(String cacheKey, BriefSection section) async {
    _memoryCache[cacheKey] = _MemorySectionCacheEntry(section);
    final prefs = await _sharedPreferencesFuture;
    await prefs.setString(
      '$_cachePrefix$cacheKey',
      jsonEncode(section.toMap()),
    );
  }

  String _cacheKey(SelectedBriefTopic topic, BriefLocationContext location) {
    final localizedTopics = <OnboardingTopic>{
      OnboardingTopic.localNews,
      OnboardingTopic.weather,
      OnboardingTopic.communityEvents,
    };
    final suffix = localizedTopics.contains(topic.topic)
        ? location.normalizedCacheKey
        : 'generic';
    return '${topic.id}_$suffix';
  }

  BriefSectionKind _fallbackKind(OnboardingTopic topic) {
    switch (topic) {
      case OnboardingTopic.weather:
        return BriefSectionKind.weather;
      case OnboardingTopic.easyRecipes:
        return BriefSectionKind.recipes;
      case OnboardingTopic.calmVideos:
        return BriefSectionKind.videos;
      case OnboardingTopic.cozyGames:
        return BriefSectionKind.curated;
      case OnboardingTopic.communityEvents:
        return BriefSectionKind.events;
      case OnboardingTopic.localNews:
      case OnboardingTopic.familySavings:
      case OnboardingTopic.goodNews:
      case OnboardingTopic.nostalgia:
      case OnboardingTopic.homeRoutines:
        return BriefSectionKind.roundup;
    }
  }

  String _fallbackEyebrow(OnboardingTopic topic) {
    switch (topic) {
      case OnboardingTopic.localNews:
        return 'Close to home';
      case OnboardingTopic.easyRecipes:
        return 'Low-lift meals';
      case OnboardingTopic.calmVideos:
        return 'A gentler scroll';
      case OnboardingTopic.weather:
        return 'Plan with less friction';
      case OnboardingTopic.familySavings:
        return 'Useful little wins';
      case OnboardingTopic.goodNews:
        return 'A brighter note';
      case OnboardingTopic.cozyGames:
        return 'Curated comfort';
      case OnboardingTopic.nostalgia:
        return 'Comfortingly familiar';
      case OnboardingTopic.homeRoutines:
        return 'Gentle structure';
      case OnboardingTopic.communityEvents:
        return 'Around you';
    }
  }
}

class _MemorySectionCacheEntry {
  const _MemorySectionCacheEntry(this.section);

  final BriefSection section;
}
