import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_user_profile.dart';
import '../models/briefing_bundle.dart';
import '../theme/nana_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.profile,
    required this.bundle,
    required this.loading,
    required this.onRefresh,
  });

  final AppUserProfile profile;
  final BriefingBundle? bundle;
  final bool loading;
  final Future<void> Function() onRefresh;

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
  });

  final AppUserProfile profile;
  final BriefingBundle? bundle;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    final weather = bundle?.weather;
    final items = <_IncludedItem>[
      _IncludedItem(
        count: '${bundle?.localNews.length ?? 0}',
        label: 'Local stories',
        subtitle: 'Near ${profile.locationLabel.trim().isEmpty ? 'you' : profile.locationLabel.trim()}',
        color: colors.softGreen,
        icon: Icons.location_city_outlined,
        accentIcons: const <IconData>[Icons.fmd_good_outlined, Icons.article_outlined],
      ),
      _IncludedItem(
        count: '${bundle?.recipes.length ?? 0}',
        label: 'Easy recipes',
        subtitle: 'Low-lift dinner ideas',
        color: colors.softYellow,
        icon: Icons.local_dining_outlined,
        accentIcons: const <IconData>[Icons.rice_bowl_outlined, Icons.local_cafe_outlined],
      ),
      _IncludedItem(
        count: weather == null ? '--' : weather.temperature,
        label: weather == null ? 'Weather' : 'Current temp',
        subtitle: weather == null ? 'Pending forecast' : weather.weather,
        color: colors.cardBlue,
        icon: Icons.wb_twilight_outlined,
        accentIcons: const <IconData>[Icons.wb_sunny_outlined, Icons.air_outlined],
      ),
      _IncludedItem(
        count: '${bundle?.shortVideos.length ?? 0}',
        label: 'Short resets',
        subtitle: 'Mindful moments',
        color: colors.cardSoft,
        icon: Icons.spa_outlined,
        accentIcons: const <IconData>[Icons.self_improvement_outlined, Icons.play_circle_outline],
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const gap = 12.0;
        final width = constraints.maxWidth;
        final cardWidth = (width - gap) / 2;
        final tallHeight = (cardWidth * 1.42).clamp(228.0, 320.0);
        final stackedHeight = ((tallHeight - gap) / 2).clamp(108.0, 154.0);

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
            const SizedBox(height: gap),
            SizedBox(
              height: stackedHeight,
              width: double.infinity,
              child: _IncludedEditorialCard(
                item: items[3],
                prominent: false,
                horizontal: true,
              ),
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
    this.horizontal = false,
  });

  final _IncludedItem item;
  final bool prominent;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final titleStyle = prominent
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.titleMedium;
    final countStyle = (prominent
            ? Theme.of(context).textTheme.displayLarge
            : Theme.of(context).textTheme.displaySmall)
        ?.copyWith(height: 0.9);

    return Container(
      padding: EdgeInsets.all(prominent ? 20 : 14),
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(prominent ? 30 : 24),
      ),
      child: prominent
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _CardDecorativeCluster(item: item),
                const Spacer(),
                _CardTextBlock(item: item, countStyle: countStyle, titleStyle: titleStyle),
              ],
            )
          : horizontal
          ? Row(
              children: <Widget>[
                _CompactBadgeIcon(item: item),
                const SizedBox(width: 10),
                Expanded(
                  child: _CardTextBlock(
                    item: item,
                    countStyle: countStyle,
                    titleStyle: titleStyle,
                    subtitleMaxLines: 1,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _CompactBadgeIcon(item: item),
                const Spacer(),
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
              ],
            ),
    );
  }
}

class _CompactBadgeIcon extends StatelessWidget {
  const _CompactBadgeIcon({required this.item});

  final _IncludedItem item;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: colors.ricePaper.withOpacity(0.62),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Icon(item.icon, size: 16),
    );
  }
}

class _CardDecorativeCluster extends StatelessWidget {
  const _CardDecorativeCluster({required this.item});

  final _IncludedItem item;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);

    Widget chip(IconData icon, {double size = 16}) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: colors.ricePaper.withOpacity(0.62),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, size: size),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        chip(item.icon, size: 17),
        ...item.accentIcons.map(chip),
      ],
    );
  }
}

class _CardTextBlock extends StatelessWidget {
  const _CardTextBlock({
    required this.item,
    required this.countStyle,
    required this.titleStyle,
    this.subtitleMaxLines = 2,
  });

  final _IncludedItem item;
  final TextStyle? countStyle;
  final TextStyle? titleStyle;
  final int subtitleMaxLines;

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
        const SizedBox(height: 2),
        Text(
          item.subtitle,
          maxLines: subtitleMaxLines,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
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
    required this.icon,
    required this.accentIcons,
  });

  final String count;
  final String label;
  final String subtitle;
  final Color color;
  final IconData icon;
  final List<IconData> accentIcons;
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
