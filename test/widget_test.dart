import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nana_poc/models/app_user_profile.dart';
import 'package:nana_poc/models/todays_brief_preview.dart';
import 'package:nana_poc/screens/todays_brief_preview_screen.dart';
import 'package:nana_poc/services/todays_brief_service.dart';
import 'package:nana_poc/theme/nana_theme.dart';

class _FakeTodaysBriefService extends TodaysBriefService {
  _FakeTodaysBriefService()
      : super(
          apiKey: 'test-key',
        );

  @override
  Future<TodaysBriefPreview> loadPreview(AppUserProfile profile) async {
    return TodaysBriefPreview(
      generatedAt: DateTime(2026, 3, 19),
      topics: const <String>['Local News'],
      sections: const <BriefPreviewSection>[
        BriefPreviewSection(
          topic: 'Local News',
          kind: BriefPreviewSectionKind.roundup,
          eyebrow: 'Close to home',
          title: 'Local News',
          description: 'A calmer look nearby.',
          items: <BriefPreviewItem>[
            BriefPreviewItem(
              title: 'Neighborhood garden day',
              subtitle: 'Volunteers are refreshing the block garden.',
              source: 'Community Post',
              badge: 'Local',
            ),
          ],
        ),
      ],
    );
  }
}

void main() {
  testWidgets('full screen calm cue preview renders heading and completion page', (
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
          service: _FakeTodaysBriefService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Today’s brief'), findsOneWidget);
    expect(find.text('Neighborhood garden day'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('You’re all caught up!'), findsOneWidget);
  });
}
