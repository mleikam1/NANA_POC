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
                'Morning Briefing\n$dateLabel',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              if (loading && bundle == null)
                const _LoadingBlock()
              else ...<Widget>[
                _HeroSummaryCard(
                  profile: profile,
                  bundle: bundle,
                ),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'What’s included',
                  cta: 'Refresh',
                  onTap: () {
                    onRefresh();
                  },
                ),
                const SizedBox(height: 12),
                _WhatIncludedGrid(bundle: bundle),
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

class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({
    required this.profile,
    required this.bundle,
  });

  final AppUserProfile profile;
  final BriefingBundle? bundle;

  @override
  Widget build(BuildContext context) {
    final weather = bundle?.weather;
    final colors = NanaColors.of(context);
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
            'Your daily companion is ready',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.earthUmber,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            weather == null
                ? 'We’re building your calm-tech feed.'
                : '${weather.weather} in ${weather.location}. ${weather.temperature}° and a gentle place to start your day.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _MiniPill(
                label: '${bundle?.localNews.length ?? 0} local stories',
              ),
              _MiniPill(
                label: '${bundle?.recipes.length ?? 0} recipe ideas',
              ),
              _MiniPill(
                label: '${bundle?.shortVideos.length ?? 0} short resets',
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () {},
            child: const Text('Open today’s calm brief'),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: NanaColors.of(context).ricePaper.withOpacity(0.75),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}

class _WhatIncludedGrid extends StatelessWidget {
  const _WhatIncludedGrid({required this.bundle});

  final BriefingBundle? bundle;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    final weather = bundle?.weather;
    final items = <_IncludedItem>[
      _IncludedItem(
        count: '${bundle?.localNews.length ?? 0}',
        label: 'Places to visit',
        color: colors.softGreen,
      ),
      _IncludedItem(
        count: '${bundle?.recipes.length ?? 0}',
        label: 'Recipes to try',
        color: colors.softYellow,
      ),
      _IncludedItem(
        count: weather == null ? '--' : weather.temperature,
        label: weather == null ? 'Weather' : 'Current temp',
        color: colors.cardBlue,
      ),
      _IncludedItem(
        count: '${bundle?.shortVideos.length ?? 0}',
        label: 'Short resets',
        color: colors.cardSoft,
      ),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 140,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemBuilder: (_, int index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.count,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const Spacer(),
              Text(
                item.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IncludedItem {
  const _IncludedItem({
    required this.count,
    required this.label,
    required this.color,
  });

  final String count;
  final String label;
  final Color color;
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
