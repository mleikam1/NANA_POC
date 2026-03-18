import 'package:flutter/material.dart';

import '../models/app_user_profile.dart';
import '../models/briefing_bundle.dart';
import '../services/local_news_service.dart';
import '../theme/nana_theme.dart';
import '../widgets/local_news_block.dart';

class LocalScreen extends StatelessWidget {
  const LocalScreen({
    super.key,
    required this.profile,
    required this.bundle,
    required this.loading,
    required this.onRefresh,
    required this.focusSignal,
    this.localNewsService,
  });

  final AppUserProfile profile;
  final BriefingBundle? bundle;
  final bool loading;
  final Future<void> Function() onRefresh;
  final int focusSignal;
  final LocalNewsService? localNewsService;

  @override
  Widget build(BuildContext context) {
    final weather = bundle?.weather;
    final colors = NanaColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Local')),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.cardBlue,
                borderRadius: BorderRadius.circular(28),
              ),
              child: weather == null
                  ? Text(
                      loading
                          ? 'Loading your local weather snapshot...'
                          : 'Weather will appear here once your first bundle loads.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${weather.location} • ${weather.temperature}°',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${weather.weather} • Humidity ${weather.humidity} • Wind ${weather.wind}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: weather.hourlyForecast.take(4).map((hour) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: colors.ricePaper.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text('${hour.time} • ${hour.temperature}°'),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            LocalNewsBlock(
              profile: profile,
              focusSignal: focusSignal,
              service: localNewsService,
            ),
          ],
        ),
      ),
    );
  }
}
