import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nana_poc/models/app_user_profile.dart';
import 'package:nana_poc/models/local_news_story.dart';
import 'package:nana_poc/screens/home_screen.dart';
import 'package:nana_poc/screens/local_screen.dart';
import 'package:nana_poc/services/local_news_service.dart';
import 'package:nana_poc/theme/nana_theme.dart';
import 'package:nana_poc/widgets/local_news_block.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppUserProfile profile;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    profile = AppUserProfile(
      uid: 'user-1',
      firstName: 'Nana',
      locationLabel: 'Austin, TX, USA',
      locationLatitude: 30.2672,
      locationLongitude: -97.7431,
      topics: const <String>['Local News'],
      onboardingComplete: true,
      notificationPreferences: NotificationPreference.defaults(),
    );
  });

  testWidgets('Local news block shows loading then success state with footer links',
      (WidgetTester tester) async {
    final service = _FakeLocalNewsService.success();
    await tester.pumpWidget(
      MaterialApp(
        theme: NanaTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: LocalNewsBlock(
              profile: profile,
              focusSignal: 0,
              service: service,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Local News'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('A steady local update on Story 1.'), findsOneWidget);
    expect(find.text('Open original stories'), findsOneWidget);
    expect(find.byKey(const Key('open-original-story-1')), findsOneWidget);
    expect(find.byKey(const Key('open-original-story-5')), findsOneWidget);
  });

  testWidgets('Local news block shows empty state and retry action',
      (WidgetTester tester) async {
    final service = _FakeLocalNewsService.empty();
    await tester.pumpWidget(
      MaterialApp(
        theme: NanaTheme.lightTheme,
        home: Scaffold(
          body: LocalNewsBlock(
            profile: profile,
            focusSignal: 0,
            service: service,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No local stories yet'), findsOneWidget);
    expect(find.text('Refresh'), findsAtLeastNWidgets(1));
  });

  testWidgets('Local news block shows error state', (WidgetTester tester) async {
    final service = _FakeLocalNewsService.error();
    await tester.pumpWidget(
      MaterialApp(
        theme: NanaTheme.lightTheme,
        home: Scaffold(
          body: LocalNewsBlock(
            profile: profile,
            focusSignal: 0,
            service: service,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('We couldn’t load local stories just now'), findsOneWidget);
    expect(find.textContaining('network issue'), findsOneWidget);
  });

  testWidgets('tapping Local Stories moves to Local tab and focuses local news',
      (WidgetTester tester) async {
    final service = _FakeLocalNewsService.success();
    await tester.pumpWidget(
      MaterialApp(
        theme: NanaTheme.lightTheme,
        home: _NavigationHarness(
          profile: profile,
          service: service,
        ),
      ),
    );

    expect(find.text('What’s Included'), findsOneWidget);
    await tester.tap(find.text('Local stories'));
    await tester.pumpAndSettle();

    expect(find.text('Local'), findsWidgets);
    expect(find.byKey(const Key('local-news-title')), findsOneWidget);
  });

  testWidgets('footer link opens in-app reader destination',
      (WidgetTester tester) async {
    final service = _FakeLocalNewsService.success();
    LocalNewsStory? openedStory;
    await tester.pumpWidget(
      MaterialApp(
        theme: NanaTheme.lightTheme,
        home: Scaffold(
          body: LocalNewsBlock(
            profile: profile,
            focusSignal: 0,
            service: service,
            onOpenStory: (LocalNewsStory story) {
              openedStory = story;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-original-story-1')));
    await tester.pumpAndSettle();

    expect(openedStory?.title, 'Story 1');
    expect(openedStory?.url, 'https://example.com/1');
  });
}

class _NavigationHarness extends StatefulWidget {
  const _NavigationHarness({
    required this.profile,
    required this.service,
  });

  final AppUserProfile profile;
  final LocalNewsService service;

  @override
  State<_NavigationHarness> createState() => _NavigationHarnessState();
}

class _NavigationHarnessState extends State<_NavigationHarness> {
  var _index = 0;
  var _focusSignal = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _index == 0
          ? HomeScreen(
              profile: widget.profile,
              bundle: null,
              loading: false,
              onRefresh: () async {},
              onOpenLocalStories: () {
                setState(() {
                  _index = 1;
                  _focusSignal++;
                });
              },
            )
          : LocalScreen(
              profile: widget.profile,
              bundle: null,
              loading: false,
              onRefresh: () async {},
              focusSignal: _focusSignal,
              localNewsService: widget.service,
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.place), label: 'Local'),
        ],
        onDestinationSelected: (int value) {
          setState(() => _index = value);
        },
      ),
    );
  }
}

class _FakeLocalNewsService extends LocalNewsService {
  _FakeLocalNewsService._(this._loader)
      : super(
          sharedPreferences: SharedPreferences.getInstance(),
          apiKey: 'test-key',
        );

  factory _FakeLocalNewsService.success() {
    return _FakeLocalNewsService._((AppUserProfile profile) async {
      return LocalNewsResult(
        location: const LocalNewsLocation(
          label: 'Austin, TX, USA',
          normalizedCacheKey: 'austin_tx_usa',
          city: 'Austin',
          stateOrRegion: 'TX',
          country: 'USA',
          countyOrMetro: '',
          latitude: 30.2,
          longitude: -97.7,
        ),
        stories: List<LocalNewsStory>.generate(5, (int index) {
          final rank = index + 1;
          return LocalNewsStory(
            id: '$rank',
            rank: rank,
            title: 'Story $rank',
            url: 'https://example.com/$rank',
            source: 'Source $rank',
            snippet: 'Snippet $rank',
            thumbnailUrl: '',
            publishedAt: null,
            relativeTimeLabel: 'Recently',
            calmHeadline: 'A steady local update on Story $rank.',
            bullets: <String>[
              'Calm bullet one for story $rank.',
              'Calm bullet two for story $rank.',
            ],
            readTimeLabel: 'Quick update',
            extractionFailed: false,
            fromCache: false,
          );
        }),
        generatedAt: DateTime(2026, 3, 18, 12),
        isStale: false,
        usedCache: false,
        isPartial: false,
        errorMessage: null,
      );
    });
  }

  factory _FakeLocalNewsService.empty() {
    return _FakeLocalNewsService._((AppUserProfile profile) async {
      return LocalNewsResult(
        location: const LocalNewsLocation(
          label: 'Austin, TX, USA',
          normalizedCacheKey: 'austin_tx_usa',
          city: 'Austin',
          stateOrRegion: 'TX',
          country: 'USA',
          countyOrMetro: '',
          latitude: 30.2,
          longitude: -97.7,
        ),
        stories: const <LocalNewsStory>[],
        generatedAt: DateTime(2026, 3, 18, 12),
        isStale: false,
        usedCache: false,
        isPartial: false,
        errorMessage: null,
      );
    });
  }

  factory _FakeLocalNewsService.error() {
    return _FakeLocalNewsService._((AppUserProfile profile) async {
      throw const LocalNewsException('network issue');
    });
  }

  final Future<LocalNewsResult> Function(AppUserProfile profile) _loader;

  @override
  Future<LocalNewsResult> fetchLocalNews(
    AppUserProfile profile, {
    bool forceRefresh = false,
  }) {
    return _loader(profile);
  }
}
