import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_user_profile.dart';
import '../models/briefing_bundle.dart';
import '../theme/nana_theme.dart';
import 'in_app_webview_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.profile,
    required this.bundle,
    required this.loading,
    required this.onRefresh,
    required this.onOpenLocalStories,
    required this.onOpenRecipes,
  });

  final AppUserProfile profile;
  final BriefingBundle? bundle;
  final bool loading;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenLocalStories;
  final VoidCallback onOpenRecipes;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    final dateLabel = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: <Widget>[
              Text(
                profile.firstName.isEmpty
                    ? 'Good Morning'
                    : 'Welcome back, ${profile.firstName}',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Morning Cue\n$dateLabel',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              _WeatherHeroCard(
                profile: profile,
                weather: bundle?.weather,
                loading: loading && bundle == null,
              ),
              const SizedBox(height: 20),
              if (loading && bundle == null)
                const _LoadingBlock()
              else ...<Widget>[
                _SectionHeader(
                  title: 'What’s Included',
                  cta: 'Refresh',
                  onTap: () {
                    onRefresh();
                  },
                ),
                const SizedBox(height: 12),
                _WhatIncludedGrid(
                  profile: profile,
                  bundle: bundle,
                  onOpenLocalStories: onOpenLocalStories,
                  onOpenRecipes: onOpenRecipes,
                ),
                const SizedBox(height: 20),
                const _SectionHeader(title: 'Today’s nana note'),
                const SizedBox(height: 12),
                _AiOverviewCard(bundle: bundle),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'A softer way to begin',
                ),
                const SizedBox(height: 12),
                _ActionRow(colors: colors),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherHeroCard extends StatelessWidget {
  const _WeatherHeroCard({
    required this.profile,
    required this.weather,
    required this.loading,
  });

  final AppUserProfile profile;
  final WeatherSummary? weather;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    final defaultLocation = profile.locationLabel.trim().isEmpty
        ? 'Your area'
        : profile.locationLabel.trim();
    final hasWeather = weather != null;
    final location = hasWeather && weather!.location.trim().isNotEmpty
        ? weather!.location
        : defaultLocation;
    final high = hasWeather && weather!.forecast.isNotEmpty
        ? weather!.forecast.first.high
        : '--';
    final low = hasWeather && weather!.forecast.isNotEmpty
        ? weather!.forecast.first.low
        : '--';
    final hourly = hasWeather ? weather!.hourlyForecast.take(6).toList() : const <WeatherForecastHour>[];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBlue,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            location,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.earthUmber.withOpacity(0.85),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  loading
                      ? '--°'
                      : hasWeather
                          ? '${weather!.temperature}°'
                          : '--°',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: colors.earthUmber,
                        height: 0.9,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    loading
                        ? 'Loading forecast...'
                        : hasWeather && weather!.weather.trim().isNotEmpty
                            ? weather!.weather
                            : 'Weather update will appear soon',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.earthUmber,
                        ),
                    textAlign: TextAlign.end,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'H:$high°  L:$low°',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.earthUmber.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hourly.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: hourly
                    .map((WeatherForecastHour hour) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _HourlyForecastChip(hour: hour),
                        ))
                    .toList(),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.ricePaper.withOpacity(0.6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                loading
                    ? 'Finding today’s weather moments...'
                    : 'We’ll bring in your hourly outlook as soon as it’s ready.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          if (!loading && !hasWeather) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              'Pull to refresh in a moment and we’ll try your local weather again.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _HourlyForecastChip extends StatelessWidget {
  const _HourlyForecastChip({required this.hour});

  final WeatherForecastHour hour;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colors.ricePaper.withOpacity(0.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            hour.time,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.earthUmber.withOpacity(0.75),
                ),
          ),
          const SizedBox(height: 10),
          Text(
            '${hour.temperature}°',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            hour.weather,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _WhatIncludedGrid extends StatelessWidget {
  const _WhatIncludedGrid({
    required this.profile,
    required this.bundle,
    required this.onOpenLocalStories,
    required this.onOpenRecipes,
  });

  final AppUserProfile profile;
  final BriefingBundle? bundle;
  final VoidCallback onOpenLocalStories;
  final VoidCallback onOpenRecipes;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    final location = profile.locationLabel.trim();
    final items = <_IncludedItem>[
      _IncludedItem(
        count: '5',
        label: 'Local stories',
        subtitle: 'Near ${location.isEmpty ? 'you' : location}',
        color: colors.softGreen,
        imagePath: 'assets/images/whats_included/local_stories.png',
        imageFit: BoxFit.cover,
        onTap: onOpenLocalStories,
      ),
      _IncludedItem(
        count: '3',
        label: 'Recipes',
        subtitle: 'Low-lift dinner ideas',
        color: colors.softYellow,
        imagePath: 'assets/images/whats_included/recipes.png',
        imageFit: BoxFit.contain,
        onTap: onOpenRecipes,
      ),
      _IncludedItem(
        count: '1',
        label: 'Calm game',
        subtitle: 'A mindful break',
        color: colors.cardBlue,
        imagePath: 'assets/images/whats_included/calm_game.png',
        imageFit: BoxFit.contain,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const InAppWebViewScreen(
                title: 'Calm game',
                url: 'https://games.fotoscapes.com/games/sudoku-blocks/index.html',
              ),
            ),
          );
        },
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const gap = 12.0;
        final width = constraints.maxWidth;
        final cardWidth = (width - gap) / 2;
        final tallHeight = (cardWidth * 1.42).clamp(228.0, 320.0);

        return Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: SizedBox(
                    height: tallHeight,
                    child: _IncludedEditorialCard(
                      item: items[0],
                      prominent: true,
                    ),
                  ),
                ),
                const SizedBox(width: gap),
                Expanded(
                  child: SizedBox(
                    height: tallHeight,
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: _IncludedEditorialCard(
                            item: items[1],
                            prominent: false,
                          ),
                        ),
                        const SizedBox(height: gap),
                        Expanded(
                          child: _IncludedEditorialCard(
                            item: items[2],
                            prominent: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _IncludedEditorialCard extends StatelessWidget {
  const _IncludedEditorialCard({
    required this.item,
    required this.prominent,
  });

  final _IncludedItem item;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final titleStyle = prominent
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.titleMedium;
    final countStyle = (prominent
            ? Theme.of(context).textTheme.displayLarge
            : Theme.of(context).textTheme.displaySmall)
        ?.copyWith(height: 0.9, color: const Color(0xFF1F2933));
    final subtitleStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: const Color(0xFF1F2933).withOpacity(0.78));
    final radius = BorderRadius.circular(prominent ? 30 : 24);

    return Container(
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.onTap,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Image(
                    image: AssetImage(item.imagePath),
                    fit: prominent ? BoxFit.cover : item.imageFit,
                    alignment: prominent ? Alignment.topCenter : Alignment.center,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: prominent
                            ? <Color>[
                                Colors.transparent,
                                Colors.transparent,
                                item.color.withOpacity(0.55),
                                item.color.withOpacity(0.92),
                              ]
                            : <Color>[
                                item.color.withOpacity(0.04),
                                item.color.withOpacity(0.48),
                                item.color.withOpacity(0.92),
                              ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: prominent ? 20 : 12,
                  right: prominent ? 20 : 12,
                  bottom: prominent ? 20 : 12,
                  child: _CardTextBlock(
                    item: item,
                    countStyle: countStyle,
                    titleStyle: titleStyle,
                    subtitleStyle: subtitleStyle,
                    showSubtitle: prominent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardTextBlock extends StatelessWidget {
  const _CardTextBlock({
    required this.item,
    required this.countStyle,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.showSubtitle,
  });

  final _IncludedItem item;
  final TextStyle? countStyle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(item.count, style: countStyle),
        ),
        const SizedBox(height: 6),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
        if (showSubtitle) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            item.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: subtitleStyle,
          ),
        ],
      ],
    );
  }
}

class _IncludedItem {
  const _IncludedItem({
    required this.count,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.imagePath,
    required this.imageFit,
    this.onTap,
  });

  final String count;
  final String label;
  final String subtitle;
  final Color color;
  final String imagePath;
  final BoxFit imageFit;
  final VoidCallback? onTap;
}

class _AiOverviewCard extends StatelessWidget {
  const _AiOverviewCard({required this.bundle});

  final BriefingBundle? bundle;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    final bullets = bundle?.aiOverviewBullets ??
        const <String>['A calmer summary will appear here once your bundle loads.'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardSoft,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            bundle?.aiOverviewTitle ?? 'Today’s calm take',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...bullets.map(
            (String bullet) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Icon(Icons.circle, size: 7),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(bullet)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.colors});

  final NanaPalette colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.softYellow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.spa_outlined),
                SizedBox(height: 14),
                Text('Take a short reset'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.softGreen,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.soup_kitchen_outlined),
                SizedBox(height: 14),
                Text('Plan one easy dinner'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.cta,
    this.onTap,
  });

  final String title;
  final String? cta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        if (cta != null)
          TextButton(
            onPressed: onTap,
            child: Text(cta!),
          ),
      ],
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Column(
      children: List<Widget>.generate(3, (int index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 110,
          decoration: BoxDecoration(
            color: index.isEven ? colors.cardSoft : colors.cardBlue,
            borderRadius: BorderRadius.circular(24),
          ),
        );
      }),
    );
  }
}
