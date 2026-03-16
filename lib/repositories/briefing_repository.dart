import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';

import '../config/app_config.dart';
import '../models/app_user_profile.dart';
import '../models/briefing_bundle.dart';
import '../utils/location_label_helper.dart';

class BriefingRepository {
  BriefingRepository()
      : _functions =
            FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);

  final FirebaseFunctions _functions;

  Future<BriefingBundle> getDailyBriefing(AppUserProfile profile) async {
    try {
      final requestLocationLabel = LocationLabelHelper.bestLabelFromProfile(
        locationLabel: profile.locationLabel,
        latitude: profile.locationLatitude,
        longitude: profile.locationLongitude,
      );
      final callable = _functions.httpsCallable('getDailyBriefing');
      final response = await callable.call(<String, dynamic>{
        'locationLabel': requestLocationLabel,
        'locationLatitude': profile.locationLatitude,
        'locationLongitude': profile.locationLongitude,
        'topics': profile.topics,
      });

      return BriefingBundle.fromMap(
        Map<String, dynamic>.from(response.data as Map),
      );
    } catch (_) {
      return _mockBundle(profile);
    }
  }

  BriefingBundle _mockBundle(AppUserProfile profile) {
    final seed = LocationLabelHelper.bestLabelFromProfile(
      locationLabel: profile.locationLabel,
      latitude: profile.locationLatitude,
      longitude: profile.locationLongitude,
    );
    final visibleSeed = seed.isEmpty ? 'your area' : seed;
    return BriefingBundle(
      weather: WeatherSummary(
        location: visibleSeed,
        temperature: '72',
        unit: 'Fahrenheit',
        weather: 'Soft sunshine',
        humidity: '38%',
        wind: '6 mph',
        date: 'Today 8:00 AM',
        thumbnail: '',
        forecast: const <WeatherForecastDay>[
          WeatherForecastDay(day: 'Mon', high: '74', low: '58', weather: 'Sunny'),
          WeatherForecastDay(day: 'Tue', high: '76', low: '60', weather: 'Bright'),
          WeatherForecastDay(day: 'Wed', high: '73', low: '57', weather: 'Breezy'),
        ],
        hourlyForecast: const <WeatherForecastHour>[
          WeatherForecastHour(time: '8 AM', temperature: '69', weather: 'Sunny'),
          WeatherForecastHour(time: '9 AM', temperature: '71', weather: 'Sunny'),
          WeatherForecastHour(time: '10 AM', temperature: '72', weather: 'Clear'),
          WeatherForecastHour(time: '11 AM', temperature: '74', weather: 'Bright'),
        ],
      ),
      localNews: List<ContentCard>.generate(3, (int index) {
        return ContentCard(
          id: 'news_$index',
          title: 'A calmer local headline ${index + 1} for $visibleSeed',
          subtitle: '${index + 6} sources • ${4 + index} min read',
          source: 'Local Roundup',
          link: '',
          imageUrl: '',
          label: 'Local',
          metadata: <String, dynamic>{},
        );
      }),
      recipes: const <ContentCard>[
        ContentCard(
          id: 'recipe_1',
          title: 'Easy Weeknight Spaghetti',
          subtitle: 'PREP 10m • COOK 20m • TOTAL 30m',
          source: 'NANA Kitchen',
          link: '',
          imageUrl: '',
          label: 'Nourish',
          metadata: <String, dynamic>{'costPerServing': '\$3.60'},
        ),
        ContentCard(
          id: 'recipe_2',
          title: 'Sheet Pan Chicken and Veggies',
          subtitle: 'PREP 15m • COOK 25m • TOTAL 40m',
          source: 'NANA Kitchen',
          link: '',
          imageUrl: '',
          label: 'Nourish',
          metadata: <String, dynamic>{'costPerServing': '\$4.10'},
        ),
      ],
      shortVideos: const <ContentCard>[
        ContentCard(
          id: 'video_1',
          title: '5-minute reset for your morning',
          subtitle: 'A short calm-tech pause',
          source: 'Short Videos',
          link: '',
          imageUrl: '',
          label: 'Unwind',
          metadata: <String, dynamic>{'duration': '0:45'},
        ),
        ContentCard(
          id: 'video_2',
          title: 'Simple lunch prep that lowers the day’s chaos',
          subtitle: 'Small routines, less noise',
          source: 'Short Videos',
          link: '',
          imageUrl: '',
          label: 'Unwind',
          metadata: <String, dynamic>{'duration': '0:58'},
        ),
      ],
      aiOverviewTitle: 'Today’s nana note',
      aiOverviewBullets: <String>[
        'Start with one useful win, not ten noisy tabs.',
        'The weather stays mild, so errands are easiest before lunch.',
        'A simple pasta or sheet-pan dinner keeps tonight low effort.',
        'Use the Unwind tab for a 5-minute reset instead of doomscrolling.',
      ],
      generatedAt: DateTime.now().subtract(Duration(minutes: Random().nextInt(7))),
    );
  }
}
