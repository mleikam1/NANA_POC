import 'package:flutter/material.dart';

import '../models/briefing_bundle.dart';
import '../theme/nana_theme.dart';

class LocalScreen extends StatelessWidget {
  const LocalScreen({
    super.key,
    required this.bundle,
    required this.loading,
    required this.onRefresh,
  });

  final BriefingBundle? bundle;
  final bool loading;
  final Future<void> Function() onRefresh;

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
                  ? const Text('Weather will appear here once your first bundle loads.')
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
            Text(
              'Local News',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            if (loading && (bundle?.localNews.isEmpty ?? true))
              const _LocalLoading()
            else
              ...((bundle?.localNews ?? const <ContentCard>[])
                  .map(
                    (ContentCard item) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.cardSoft,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(item.subtitle),
                          const SizedBox(height: 8),
                          Text(
                            item.source,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _LocalLoading extends StatelessWidget {
  const _LocalLoading();

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Column(
      children: List<Widget>.generate(3, (int index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 92,
          decoration: BoxDecoration(
            color: index.isEven ? colors.cardSoft : colors.cardBlue,
            borderRadius: BorderRadius.circular(24),
          ),
        );
      }),
    );
  }
}
