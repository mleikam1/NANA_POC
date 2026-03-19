import 'package:flutter/material.dart';

import '../models/app_user_profile.dart';
import '../models/brief_content.dart';
import '../models/onboarding_topic.dart';
import '../repositories/brief_content_repository.dart';
import '../repositories/topic_preferences_repository.dart';
import '../screens/todays_brief_preview_screen.dart';

class FullScreenCalmCueLauncher {
  FullScreenCalmCueLauncher({
    TopicPreferencesRepository? topicPreferencesRepository,
    BriefContentRepository? briefContentRepository,
  })  : _topicPreferencesRepository =
            topicPreferencesRepository ?? TopicPreferencesRepository(),
        _briefContentRepository =
            briefContentRepository ?? BriefContentRepository();

  final TopicPreferencesRepository _topicPreferencesRepository;
  final BriefContentRepository _briefContentRepository;

  static const List<OnboardingTopic> _fallbackTopics = <OnboardingTopic>[
    OnboardingTopic.weather,
    OnboardingTopic.goodNews,
    OnboardingTopic.easyRecipes,
  ];

  Future<void> open({
    required BuildContext context,
    required AppUserProfile profile,
  }) async {
    final prepared = await prepare(profile: profile);

    if (!context.mounted) {
      return;
    }

    if (prepared.usedFallbackTopics) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No topics were saved yet, so NANA built a gentle preview with Weather, Good News, and Easy Recipes.',
          ),
        ),
      );
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TodaysBriefPreviewScreen(
          profile: profile,
          selectedTopics: prepared.selectedTopics,
          initialBriefFuture: prepared.briefFuture,
        ),
      ),
    );
  }

  Future<PreparedFullScreenCalmCue> prepare({
    required AppUserProfile profile,
  }) async {
    final storedTopics = await _topicPreferencesRepository.readSelectedTopics();
    final profileTopics = TopicPreferencesRepository.stabilizeTopics(
      profile.topics,
    );
    final selectedTopics = storedTopics.isNotEmpty
        ? storedTopics
        : (profileTopics.isNotEmpty ? profileTopics : _fallbackTopics);
    final usedFallbackTopics = storedTopics.isEmpty && profileTopics.isEmpty;

    return PreparedFullScreenCalmCue(
      selectedTopics: selectedTopics,
      usedFallbackTopics: usedFallbackTopics,
      briefFuture: _briefContentRepository.loadBriefPage(
        profile,
        selectedTopics: selectedTopics,
      ),
    );
  }
}

class PreparedFullScreenCalmCue {
  const PreparedFullScreenCalmCue({
    required this.selectedTopics,
    required this.usedFallbackTopics,
    required this.briefFuture,
  });

  final List<OnboardingTopic> selectedTopics;
  final bool usedFallbackTopics;
  final Future<BriefPage> briefFuture;
}
