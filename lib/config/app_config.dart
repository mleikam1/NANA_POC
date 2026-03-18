class AppConfig {
  static const functionsRegion = 'us-central1';
  // POC-only hardcoded key so Local News works without --dart-define.
  static const serpApiKey =
      'd314d50129060440c039a90701193541056ee3f0d11da024d9a3a8918a479773';

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
