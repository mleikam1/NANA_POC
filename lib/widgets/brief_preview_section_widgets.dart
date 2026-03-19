import 'package:flutter/material.dart';

import '../models/brief_content.dart';
import '../models/onboarding_topic.dart';
import '../theme/nana_theme.dart';

class BriefPreviewSectionView extends StatelessWidget {
  const BriefPreviewSectionView({
    super.key,
    required this.section,
    required this.onOpenLink,
    this.isFirst = false,
  });

  final BriefSection section;
  final ValueChanged<BriefContentItem> onOpenLink;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final horizontalPadding = constraints.maxWidth >= 900 ? 32.0 : 20.0;
        final contentWidth = constraints.maxWidth >= 1100 ? 960.0 : 760.0;

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 24),
          children: <Widget>[
            Align(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Container(
                  padding: EdgeInsets.all(constraints.maxWidth >= 600 ? 28 : 22),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.80),
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: colors.skyMist.withValues(alpha: 0.16),
                        blurRadius: 28,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (isFirst) ...<Widget>[
                        _GentleHint(colors: colors),
                        const SizedBox(height: 18),
                      ],
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          _TopicBadge(topic: section.topic.topic),
                          if (section.isFromCache)
                            _MetaPill(
                              label: section.isStale ? 'Cached for now' : 'Saved copy',
                              icon: section.isStale
                                  ? Icons.history_toggle_off_rounded
                                  : Icons.offline_bolt_rounded,
                              backgroundColor: colors.softYellow,
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _fallbackText(section.eyebrow, 'A calm cue'),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _fallbackText(section.title, section.topic.label),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _fallbackText(
                          section.description,
                          'A gentle update for this part of your brief.',
                        ),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (section.summary != null && section.summary!.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 14),
                        _EditorialSummary(summary: section.summary!),
                      ],
                      if (section.errorMessage != null && section.errorMessage!.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 14),
                        _InlineStateNote(
                          icon: Icons.info_outline_rounded,
                          message: 'Some details may be limited: ${section.errorMessage}',
                        ),
                      ],
                      const SizedBox(height: 24),
                      _TopicLayout(section: section, onOpenLink: onOpenLink),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class BriefPreviewCompletionPage extends StatelessWidget {
  const BriefPreviewCompletionPage({
    super.key,
    required this.topics,
  });

  final List<SelectedBriefTopic> topics;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Container(
                padding: EdgeInsets.all(constraints.maxWidth >= 600 ? 32 : 24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.84),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: colors.skyMist.withValues(alpha: 0.18),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: colors.softGreen,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Icon(
                        Icons.spa_outlined,
                        color: colors.forestSage,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'You’re all caught up!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your calm cue is ready. Come back later for a fresh pass through the topics you picked today.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (topics.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 22),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: topics
                            .map((SelectedBriefTopic topic) => _TopicBadge(topic: topic.topic))
                            .toList(growable: false),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopicLayout extends StatelessWidget {
  const _TopicLayout({
    required this.section,
    required this.onOpenLink,
  });

  final BriefSection section;
  final ValueChanged<BriefContentItem> onOpenLink;

  @override
  Widget build(BuildContext context) {
    if (section.state == BriefSectionLoadState.error) {
      return _EmptyTopicState(
        title: 'This section needs a moment.',
        message: section.errorMessage ?? 'Please try refreshing again shortly.',
        icon: Icons.cloud_off_rounded,
      );
    }

    if (section.items.isEmpty) {
      return _EmptyTopicState(
        title: 'Nothing queued just yet.',
        message: 'We’ll keep this spot warm for your next refresh.',
        icon: _topicPresentation(section.topic.topic).icon,
      );
    }

    switch (section.topic.topic) {
      case OnboardingTopic.localNews:
        return _LocalNewsLayout(section: section, onOpenLink: onOpenLink);
      case OnboardingTopic.easyRecipes:
        return _RecipeStackLayout(section: section, onOpenLink: onOpenLink);
      case OnboardingTopic.calmVideos:
        return _FeaturedVideoLayout(section: section, onOpenLink: onOpenLink);
      case OnboardingTopic.weather:
        return _WeatherLayout(section: section);
      case OnboardingTopic.familySavings:
        return _SavingsLayout(section: section, onOpenLink: onOpenLink);
      case OnboardingTopic.goodNews:
        return _ArticleListLayout(section: section, onOpenLink: onOpenLink);
      case OnboardingTopic.cozyGames:
        return _CuratedCardGrid(section: section, onOpenLink: onOpenLink);
      case OnboardingTopic.nostalgia:
        return _ThrowbackCardLayout(section: section, onOpenLink: onOpenLink);
      case OnboardingTopic.homeRoutines:
        return _RoutineLayout(section: section, onOpenLink: onOpenLink);
      case OnboardingTopic.communityEvents:
        return _EventLayout(section: section, onOpenLink: onOpenLink);
    }
  }
}

class _LocalNewsLayout extends StatelessWidget {
  const _LocalNewsLayout({required this.section, required this.onOpenLink});

  final BriefSection section;
  final ValueChanged<BriefContentItem> onOpenLink;

  @override
  Widget build(BuildContext context) {
    final hero = section.items.first;
    final remaining = section.items.skip(1).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HeroEditorialCard(
          item: hero,
          badgeLabel: hero.badge,
          onTap: hero.link?.isNotEmpty == true ? () => onOpenLink(hero) : null,
        ),
        if (remaining.isNotEmpty) ...<Widget>[
          const SizedBox(height: 18),
          Text('Headlines to skim', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...remaining.map(
            (BriefContentItem item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _EditorialListCard(
                item: item,
                onTap: item.link?.isNotEmpty == true ? () => onOpenLink(item) : null,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RecipeStackLayout extends StatelessWidget {
  const _RecipeStackLayout({required this.section, required this.onOpenLink});

  final BriefSection section;
  final ValueChanged<BriefContentItem> onOpenLink;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: section.items.asMap().entries.map((MapEntry<int, BriefContentItem> entry) {
        final item = entry.value;
        return Padding(
          padding: EdgeInsets.only(bottom: entry.key == section.items.length - 1 ? 0 : 14),
          child: _RecipeCard(
            item: item,
            onTap: item.link?.isNotEmpty == true ? () => onOpenLink(item) : null,
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _FeaturedVideoLayout extends StatelessWidget {
  const _FeaturedVideoLayout({required this.section, required this.onOpenLink});

  final BriefSection section;
  final ValueChanged<BriefContentItem> onOpenLink;

  @override
  Widget build(BuildContext context) {
    final featured = section.items.first;
    final remaining = section.items.skip(1).toList(growable: false);
    final colors = NanaColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[colors.softGreen, colors.cardBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: featured.link?.isNotEmpty == true ? () => onOpenLink(featured) : null,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _ImagePanel(imageUrl: featured.imageUrl, height: 220, icon: Icons.play_circle_outline_rounded),
                    const SizedBox(height: 18),
                    _MetaPill(
                      label: featured.badge,
                      icon: Icons.slow_motion_video_rounded,
                      backgroundColor: Colors.white.withValues(alpha: 0.55),
                    ),
                    const SizedBox(height: 14),
                    Text(featured.title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(featured.subtitle, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: featured.link?.isNotEmpty == true ? () => onOpenLink(featured) : null,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Start'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            featured.source,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (remaining.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          ...remaining.map(
            (BriefContentItem item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CompactLinkTile(
                item: item,
                accentColor: colors.softGreen,
                onTap: item.link?.isNotEmpty == true ? () => onOpenLink(item) : null,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _WeatherLayout extends StatelessWidget {
  const _WeatherLayout({required this.section});

  final BriefSection section;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    final summary = section.items.first;
    final forecast = section.items.skip(1).toList(growable: false);
    final humidity = summary.metadata['Humidity'];
    final wind = summary.metadata['Wind'];
    final high = summary.metadata['High'] ?? '--';
    final low = summary.metadata['Low'] ?? '--';
    final weatherTitle = _fallbackText(summary.title, 'Weather');
    final weatherSubtitle = _fallbackText(summary.subtitle, 'Today’s outlook');
    final weatherBadge = _fallbackText(summary.badge, 'Now');
    final weatherSource = _fallbackText(summary.source, 'Weather');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: colors.cardBlue,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(weatherSubtitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 14),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 14,
                runSpacing: 10,
                children: <Widget>[
                  Text(weatherTitle, style: Theme.of(context).textTheme.displaySmall),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _MetaPill(
                      label: weatherBadge,
                      icon: Icons.schedule_rounded,
                      backgroundColor: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('High $high° • Low $low°', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  if (humidity != null && humidity.isNotEmpty)
                    _MetaChip(label: 'Humidity $humidity', backgroundColor: colors.softYellow),
                  if (wind != null && wind.isNotEmpty)
                    _MetaChip(label: 'Wind $wind', backgroundColor: colors.softYellow),
                  _MetaChip(
                    label: weatherSource,
                    backgroundColor: Colors.white.withValues(alpha: 0.55),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (forecast.isNotEmpty) ...<Widget>[
          const SizedBox(height: 18),
          Text('Next up', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: forecast.map((BriefContentItem item) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    width: 156,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.softYellow,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _fallbackText(item.title, 'Later'),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _fallbackText(item.badge, '--'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _fallbackText(item.subtitle, 'Forecast details will appear soon.'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ),
        ],
      ],
    );
  }
}

class _SavingsLayout extends StatelessWidget {
  const _SavingsLayout({required this.section, required this.onOpenLink});

  final BriefSection section;
  final ValueChanged<BriefContentItem> onOpenLink;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Column(
      children: section.items.map((BriefContentItem item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _InfoCard(
            item: item,
            tone: colors.softYellow,
            icon: Icons.sell_outlined,
            onTap: item.link?.isNotEmpty == true ? () => onOpenLink(item) : null,
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _ArticleListLayout extends StatelessWidget {
  const _ArticleListLayout({required this.section, required this.onOpenLink});

  final BriefSection section;
  final ValueChanged<BriefContentItem> onOpenLink;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Column(
      children: section.items.map((BriefContentItem item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _CompactLinkTile(
            item: item,
            accentColor: colors.cardSoft,
            onTap: item.link?.isNotEmpty == true ? () => onOpenLink(item) : null,
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _CuratedCardGrid extends StatelessWidget {
  const _CuratedCardGrid({required this.section, required this.onOpenLink});

  final BriefSection section;
  final ValueChanged<BriefContentItem> onOpenLink;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final columns = constraints.maxWidth >= 700 ? 2 : 1;
        final spacing = 14.0;
        final itemWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: section.items.map((BriefContentItem item) {
            return SizedBox(
              width: itemWidth,
              child: _InfoCard(
                item: item,
                tone: colors.softGreen,
                icon: Icons.sports_esports_rounded,
                onTap: item.link?.isNotEmpty == true ? () => onOpenLink(item) : null,
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }
}

class _ThrowbackCardLayout extends StatelessWidget {
  const _ThrowbackCardLayout({required this.section, required this.onOpenLink});

  final BriefSection section;
  final ValueChanged<BriefContentItem> onOpenLink;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Column(
      children: section.items.map((BriefContentItem item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _InfoCard(
            item: item,
            tone: colors.cardSoft,
            icon: Icons.auto_awesome_rounded,
            onTap: item.link?.isNotEmpty == true ? () => onOpenLink(item) : null,
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _RoutineLayout extends StatelessWidget {
  const _RoutineLayout({required this.section, required this.onOpenLink});

  final BriefSection section;
  final ValueChanged<BriefContentItem> onOpenLink;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Column(
      children: section.items.map((BriefContentItem item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _RoutineCard(
            item: item,
            backgroundColor: colors.softGreen,
            onTap: item.link?.isNotEmpty == true ? () => onOpenLink(item) : null,
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _EventLayout extends StatelessWidget {
  const _EventLayout({required this.section, required this.onOpenLink});

  final BriefSection section;
  final ValueChanged<BriefContentItem> onOpenLink;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Column(
      children: section.items.map((BriefContentItem item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _InfoCard(
            item: item,
            tone: colors.cardBlue,
            icon: Icons.event_available_rounded,
            onTap: item.link?.isNotEmpty == true ? () => onOpenLink(item) : null,
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _HeroEditorialCard extends StatelessWidget {
  const _HeroEditorialCard({
    required this.item,
    required this.badgeLabel,
    this.onTap,
  });

  final BriefContentItem item;
  final String badgeLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Material(
      color: colors.cardBlue,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _ImagePanel(imageUrl: item.imageUrl, height: 220, icon: Icons.article_outlined),
              const SizedBox(height: 16),
              _MetaPill(
                label: _fallbackText(badgeLabel, 'Featured'),
                icon: Icons.newspaper_rounded,
                backgroundColor: Colors.white.withValues(alpha: 0.55),
              ),
              const SizedBox(height: 14),
              Text(
                _fallbackText(item.title, 'A calm read'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _fallbackText(item.subtitle, 'Open for a little more context.'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _MetaChip(label: _fallbackText(item.source, 'Brief')),
                  ...item.metadata.values.take(1).map((String value) => _MetaChip(label: value)),
                ],
              ),
              if (onTap != null) ...<Widget>[
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Text('Read more', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorialListCard extends StatelessWidget {
  const _EditorialListCard({required this.item, this.onTap});

  final BriefContentItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _fallbackText(item.title, 'A calm update'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fallbackText(item.subtitle, 'Tap to open the full story.'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _MetaChip(label: _fallbackText(item.source, 'Brief')),
                        if (item.badge.isNotEmpty) _MetaChip(label: item.badge),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...<Widget>[
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.item, this.onTap});

  final BriefContentItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Material(
      color: colors.cardSoft,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 112,
                child: _ImagePanel(imageUrl: item.imageUrl, height: 112, icon: Icons.restaurant_menu_rounded),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _MetaPill(
                      label: _fallbackText(item.badge, 'Easy'),
                      icon: Icons.timer_outlined,
                      backgroundColor: Colors.white.withValues(alpha: 0.58),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _fallbackText(item.title, 'A simple idea'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fallbackText(item.subtitle, 'Ingredients and details will appear here.'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _fallbackText(item.source, 'Recipes'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.item,
    required this.tone,
    required this.icon,
    this.onTap,
  });

  final BriefContentItem item;
  final Color tone;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tone,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _fallbackText(item.source, 'Brief'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if (item.badge.isNotEmpty) _MetaChip(label: item.badge),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _fallbackText(item.title, 'A helpful pick'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _fallbackText(item.subtitle, 'Open for the latest details.'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (item.metadata.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.metadata.entries
                      .take(2)
                      .map((MapEntry<String, String> entry) => _MetaChip(label: '${entry.key}: ${entry.value}'))
                      .toList(growable: false),
                ),
              ],
              if (onTap != null) ...<Widget>[
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Text('Open', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(width: 6),
                    const Icon(Icons.open_in_new_rounded, size: 18),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.item,
    required this.backgroundColor,
    this.onTap,
  });

  final BriefContentItem item;
  final Color backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _MetaPill(
                label: _fallbackText(item.badge, 'Try this'),
                icon: Icons.self_improvement_rounded,
                backgroundColor: Colors.white.withValues(alpha: 0.52),
              ),
              const SizedBox(height: 14),
              Text(
                _fallbackText(item.title, 'A small routine'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Text(
                _fallbackText(item.subtitle, 'A lighter way to reset your space.'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (item.metadata.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                ...item.metadata.entries.take(2).map(
                  (MapEntry<String, String> entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(Icons.circle, size: 8),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${entry.key}: ${entry.value}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactLinkTile extends StatelessWidget {
  const _CompactLinkTile({
    required this.item,
    required this.accentColor,
    this.onTap,
  });

  final BriefContentItem item;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accentColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            _fallbackText(item.title, 'A calm pick'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (item.badge.isNotEmpty) _MetaChip(label: item.badge),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fallbackText(item.subtitle, 'Open for the full details.'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _fallbackText(item.source, 'Brief'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...<Widget>[
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward_rounded),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePanel extends StatelessWidget {
  const _ImagePanel({
    this.imageUrl,
    required this.height,
    required this.icon,
  });

  final String? imageUrl;
  final double height;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    final resolved = imageUrl?.trim() ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: height,
        width: double.infinity,
        color: colors.ricePaper,
        child: resolved.isEmpty
            ? _ImagePlaceholder(icon: icon)
            : Image.network(
                resolved,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _ImagePlaceholder(icon: icon),
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? progress) {
                  if (progress == null) {
                    return child;
                  }
                  return const _ImagePlaceholder(icon: Icons.image_outlined);
                },
              ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[colors.cardBlue, colors.cardSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(icon, color: colors.forestSage, size: 34),
      ),
    );
  }
}

class _TopicBadge extends StatelessWidget {
  const _TopicBadge({required this.topic});

  final OnboardingTopic topic;

  @override
  Widget build(BuildContext context) {
    final presentation = _topicPresentation(topic);
    return _MetaPill(
      label: presentation.label,
      icon: presentation.icon,
      backgroundColor: presentation.backgroundColor,
    );
  }
}

class _GentleHint extends StatelessWidget {
  const _GentleHint({required this.colors});

  final NanaPalette colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.softGreen,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.swipe_rounded, size: 18, color: colors.forestSage),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Swipe sideways to move through your brief.',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorialSummary extends StatelessWidget {
  const _EditorialSummary({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardSoft,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(summary, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _InlineStateNote extends StatelessWidget {
  const _InlineStateNote({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.softYellow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: colors.earthUmber),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _EmptyTopicState extends StatelessWidget {
  const _EmptyTopicState({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.ricePaper,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.cardBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: colors.forestSage),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    this.backgroundColor,
  });

  final String label;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    final safeLabel = _fallbackText(label, 'Brief');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.skyMist.withValues(alpha: 0.18)),
      ),
      child: Text(safeLabel, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.label,
    required this.icon,
    required this.backgroundColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    final safeLabel = _fallbackText(label, 'Brief');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: colors.forestSage),
          const SizedBox(width: 8),
          Text(safeLabel, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

String _fallbackText(String? value, String fallback) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? fallback : trimmed;
}

_TopicPresentation _topicPresentation(OnboardingTopic topic) {
  switch (topic) {
    case OnboardingTopic.localNews:
      return const _TopicPresentation(
        label: 'Local News',
        icon: Icons.newspaper_rounded,
        backgroundColor: Color(0xFFE2ECF0),
      );
    case OnboardingTopic.easyRecipes:
      return const _TopicPresentation(
        label: 'Easy Recipes',
        icon: Icons.restaurant_rounded,
        backgroundColor: Color(0xFFF4E6DA),
      );
    case OnboardingTopic.calmVideos:
      return const _TopicPresentation(
        label: 'Calm Videos',
        icon: Icons.play_circle_fill_rounded,
        backgroundColor: Color(0xFFDDE9DE),
      );
    case OnboardingTopic.weather:
      return const _TopicPresentation(
        label: 'Weather',
        icon: Icons.wb_cloudy_rounded,
        backgroundColor: Color(0xFFE4EDF4),
      );
    case OnboardingTopic.familySavings:
      return const _TopicPresentation(
        label: 'Family Savings',
        icon: Icons.sell_rounded,
        backgroundColor: Color(0xFFFFF2CF),
      );
    case OnboardingTopic.goodNews:
      return const _TopicPresentation(
        label: 'Good News',
        icon: Icons.sentiment_satisfied_alt_rounded,
        backgroundColor: Color(0xFFF7EBDD),
      );
    case OnboardingTopic.cozyGames:
      return const _TopicPresentation(
        label: 'Cozy Games',
        icon: Icons.sports_esports_rounded,
        backgroundColor: Color(0xFFDCE5D8),
      );
    case OnboardingTopic.nostalgia:
      return const _TopicPresentation(
        label: 'Nostalgia',
        icon: Icons.photo_album_rounded,
        backgroundColor: Color(0xFFF3E5DB),
      );
    case OnboardingTopic.homeRoutines:
      return const _TopicPresentation(
        label: 'Home Routines',
        icon: Icons.nightlight_round,
        backgroundColor: Color(0xFFDCEAD9),
      );
    case OnboardingTopic.communityEvents:
      return const _TopicPresentation(
        label: 'Community Events',
        icon: Icons.event_rounded,
        backgroundColor: Color(0xFFDCE8ED),
      );
  }
}

class _TopicPresentation {
  const _TopicPresentation({
    required this.label,
    required this.icon,
    required this.backgroundColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
}
