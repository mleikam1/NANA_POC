import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nana_poc/models/app_user_profile.dart';
import 'package:nana_poc/models/brief_content.dart';
import 'package:nana_poc/models/onboarding_topic.dart';
import 'package:nana_poc/screens/todays_brief_preview_screen.dart';
import 'package:nana_poc/theme/nana_theme.dart';

void main() {
  testWidgets('full-screen calm cue preview renders sections and caught-up page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NanaTheme.lightTheme,
        home: TodaysBriefPreviewScreen(
          profile: AppUserProfile(
            uid: 'uid',
            firstName: 'Nina',
            locationLabel: 'Austin, TX',
            topics: const <String>['Local News'],
            onboardingComplete: true,
            notificationPreferences: NotificationPreference.defaults(),
          ),
          initialBriefFuture: Future<BriefPage>.value(
            BriefPage(
              generatedAt: DateTime(2026, 3, 19),
              selectedTopics: const <SelectedBriefTopic>[
                SelectedBriefTopic(
                  topic: OnboardingTopic.localNews,
                  label: 'Local News',
                ),
              ],
              sections: <BriefSection>[
                BriefSection(
                  topic: SelectedBriefTopic.fromTopic(OnboardingTopic.localNews),
                  kind: BriefSectionKind.roundup,
                  state: BriefSectionLoadState.ready,
                  eyebrow: 'Close to home',
                  title: 'Local News',
                  description: 'A calmer look nearby.',
                  items: const <BriefContentItem>[
                    BriefContentItem(
                      id: 'garden-day',
                      title: 'Neighborhood garden day',
                      subtitle: 'Volunteers are refreshing the block garden.',
                      source: 'Community Post',
                      badge: 'Local',
                    ),
                  ],
                  generatedAt: DateTime(2026, 3, 19),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Today’s brief'), findsOneWidget);
    expect(find.text('Neighborhood garden day'), findsOneWidget);
    expect(find.text('Page 1 of 2'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('Caught up'), findsWidgets);
    expect(find.text('Page 2 of 2'), findsOneWidget);
    expect(find.text('You’re all caught up!'), findsOneWidget);
  });

  testWidgets('topic cards fall back gracefully when optional fields are missing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NanaTheme.lightTheme,
        home: TodaysBriefPreviewScreen(
          profile: AppUserProfile(
            uid: 'uid',
            firstName: 'Nina',
            locationLabel: 'Austin, TX',
            topics: const <String>['Good News'],
            onboardingComplete: true,
            notificationPreferences: NotificationPreference.defaults(),
          ),
          initialBriefFuture: Future<BriefPage>.value(
            BriefPage(
              generatedAt: DateTime(2026, 3, 19),
              selectedTopics: const <SelectedBriefTopic>[
                SelectedBriefTopic(
                  topic: OnboardingTopic.goodNews,
                  label: 'Good News',
                ),
              ],
              sections: <BriefSection>[
                BriefSection(
                  topic: SelectedBriefTopic.fromTopic(OnboardingTopic.goodNews),
                  kind: BriefSectionKind.roundup,
                  state: BriefSectionLoadState.ready,
                  eyebrow: '',
                  title: '',
                  description: '',
                  items: const <BriefContentItem>[
                    BriefContentItem(
                      id: 'good-news-1',
                      title: '',
                      subtitle: '',
                      source: '',
                      badge: '',
                    ),
                  ],
                  generatedAt: DateTime(2026, 3, 19),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('A calm cue'), findsOneWidget);
    expect(find.text('Good News'), findsWidgets);
    expect(find.text('A helpful pick'), findsOneWidget);
    expect(find.text('Open for the latest details.'), findsOneWidget);
  });
}
