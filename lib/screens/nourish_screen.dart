import 'package:flutter/material.dart';

import '../models/briefing_bundle.dart';
import '../theme/nana_theme.dart';

class NourishScreen extends StatelessWidget {
  const NourishScreen({
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
    final colors = NanaColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Nourish')),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.softYellow,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    bundle?.aiOverviewTitle ?? 'Today’s kitchen note',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  ...(bundle?.aiOverviewBullets.take(2) ??
                          const <String>['Simple, lower-noise meal ideas appear here.'])
                      .map(
                    (String item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('• $item'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Recipes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            if (loading && (bundle?.recipes.isEmpty ?? true))
              const _RecipeLoading()
            else
              ...((bundle?.recipes ?? const <ContentCard>[])
                  .map(
                    (ContentCard recipe) => Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.cardSoft,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            recipe.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(recipe.subtitle),
                          const SizedBox(height: 6),
                          Text(
                            recipe.metadata['costPerServing']?.toString() ?? recipe.source,
                          ),
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton(
                              onPressed: () {},
                              child: const Text('View full recipe'),
                            ),
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

class _RecipeLoading extends StatelessWidget {
  const _RecipeLoading();

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Column(
      children: List<Widget>.generate(3, (int index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 134,
          decoration: BoxDecoration(
            color: index.isEven ? colors.cardSoft : colors.softYellow,
            borderRadius: BorderRadius.circular(24),
          ),
        );
      }),
    );
  }
}
