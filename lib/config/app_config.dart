class AppConfig {
  static const functionsRegion = 'us-central1';
  static const serpApiKey = String.fromEnvironment('SERPAPI_API_KEY');

  static const bottomTabs = <String>[
    'Home',
    'Local',
    'Nourish',
    'Unwind',
    'Care',
  ];

  static const defaultTopics = <String>[
    'Local News',
    'Easy Recipes',
    'Calm Videos',
    'Weather',
    'Family Savings',
    'Good News',
    'Cozy Games',
    'Nostalgia',
    'Home Routines',
    'Community Events',
  ];
}
