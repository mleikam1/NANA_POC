enum OnboardingTopic {
  localNews('local_news', 'Local News'),
  easyRecipes('easy_recipes', 'Easy Recipes'),
  calmVideos('calm_videos', 'Calm Videos'),
  weather('weather', 'Weather'),
  familySavings('family_savings', 'Family Savings'),
  goodNews('good_news', 'Good News'),
  cozyGames('cozy_games', 'Cozy Games'),
  nostalgia('nostalgia', 'Nostalgia'),
  homeRoutines('home_routines', 'Home Routines'),
  communityEvents('community_events', 'Community Events');

  const OnboardingTopic(this.storageKey, this.label);

  final String storageKey;
  final String label;

  static const List<OnboardingTopic> defaultSelection = <OnboardingTopic>[
    OnboardingTopic.localNews,
    OnboardingTopic.easyRecipes,
    OnboardingTopic.calmVideos,
  ];

  static OnboardingTopic? fromStoredValue(String value) {
    for (final topic in OnboardingTopic.values) {
      if (topic.storageKey == value || topic.label == value) {
        return topic;
      }
    }
    return null;
  }
}
