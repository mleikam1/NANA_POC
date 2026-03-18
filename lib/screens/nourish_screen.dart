import 'dart:async';

import 'package:flutter/material.dart';

import '../models/briefing_bundle.dart';
import '../models/recipe_result.dart';
import '../services/recipes_service.dart';
import '../theme/nana_theme.dart';
import 'in_app_webview_screen.dart';

class NourishScreen extends StatefulWidget {
  const NourishScreen({
    super.key,
    required this.bundle,
    required this.loading,
    required this.onRefresh,
    required this.focusSignal,
    this.recipesService,
  });

  final BriefingBundle? bundle;
  final bool loading;
  final Future<void> Function() onRefresh;
  final int focusSignal;
  final RecipesService? recipesService;

  @override
  State<NourishScreen> createState() => _NourishScreenState();
}

class _NourishScreenState extends State<NourishScreen> {
  final GlobalKey _recipesAnchorKey = GlobalKey();

  late final RecipesService _recipesService =
      widget.recipesService ?? RecipesService();

  RecipeResult? _recipesResult;
  bool _recipesLoading = true;
  bool _recipesRefreshing = false;
  String? _recipesError;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRecipes());
    if (widget.focusSignal > 0) {
      focusRecipes();
    }
  }

  @override
  void didUpdateWidget(covariant NourishScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusSignal != widget.focusSignal) {
      focusRecipes();
    }
  }

  Future<void> focusRecipes() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _recipesAnchorKey.currentContext;
      if (context == null) {
        return;
      }
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.02,
      );
    });
  }

  Future<void> _loadRecipes({bool forceRefresh = false}) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _recipesLoading = _recipesResult == null;
      _recipesRefreshing = _recipesResult != null;
      _recipesError = null;
    });

    try {
      final result = await _recipesService.fetchRecipes(forceRefresh: forceRefresh);
      if (!mounted) {
        return;
      }
      setState(() {
        _recipesResult = result;
        _recipesLoading = false;
        _recipesRefreshing = false;
        _recipesError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _recipesLoading = false;
        _recipesRefreshing = false;
        _recipesError = error.toString();
      });
    }
  }

  Future<void> _handleRefresh() async {
    await Future.wait<void>(<Future<void>>[
      widget.onRefresh(),
      _loadRecipes(forceRefresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    final result = _recipesResult;
    final recipes = result?.recipes ?? const <RecipeCard>[];
    final hasRecipes = recipes.isNotEmpty;
    final hasQueryUsed = result != null && result.queryUsed.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Nourish')),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
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
                    widget.bundle?.aiOverviewTitle ?? 'Today’s kitchen note',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  ...((widget.bundle?.aiOverviewBullets ??
                              const <String>[
                                'Simple, lower-noise meal ideas appear here.',
                              ])
                          .take(2))
                      .map(
                    (String item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('• $item'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              key: _recipesAnchorKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Recipes',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasQueryUsed
                            ? 'Three calm recipe ideas pulled from “${result!.queryUsed}”.'
                            : 'Three calm recipe ideas to try this week.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  tooltip: 'Refresh recipes',
                  onPressed:
                      _recipesRefreshing ? null : () => _loadRecipes(forceRefresh: true),
                  icon: _recipesRefreshing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_recipesLoading)
              const _RecipeLoadingState()
            else if (!hasRecipes && _recipesError != null)
              _RecipeMessageCard(
                toneColor: colors.cardSoft,
                title: 'We couldn’t load recipes just now',
                body: _recipesError!,
                actionLabel: 'Try again',
                onAction: () => _loadRecipes(forceRefresh: true),
              )
            else if (!hasRecipes)
              _RecipeMessageCard(
                toneColor: colors.cardSoft,
                title: 'No recipe ideas yet',
                body:
                    'We did not find recipe cards for this moment. Please refresh in a little while.',
                actionLabel: 'Refresh',
                onAction: () => _loadRecipes(forceRefresh: true),
              )
            else ...<Widget>[
              if (result!.isStale || result.usedCache || result.isPartial)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StatusPill(
                    label: result.isStale
                        ? 'Showing saved recipes while we retry.'
                        : result.isPartial
                            ? 'We found fewer than three strong matches, so this block is partial for now.'
                            : 'Showing saved recipe ideas.',
                  ),
                ),
              ...recipes.map(
                (RecipeCard recipe) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _RecipeEditorialCard(
                    recipe: recipe,
                    onTap: () => _openRecipe(context, recipe),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openRecipe(BuildContext context, RecipeCard recipe) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InAppWebViewScreen(
          title: recipe.source.isNotEmpty ? recipe.source : recipe.title,
          url: recipe.link,
        ),
      ),
    );
  }
}

class _RecipeEditorialCard extends StatelessWidget {
  const _RecipeEditorialCard({
    required this.recipe,
    required this.onTap,
  });

  final RecipeCard recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    final headlineStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          height: 1.2,
        );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white.withOpacity(0.84),
        );
    final secondaryLine = _buildSecondaryLine(recipe);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF6E8E8A),
            borderRadius: BorderRadius.circular(30),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.skyMist.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                child: AspectRatio(
                  aspectRatio: 1.55,
                  child: recipe.thumbnailUrl.isNotEmpty
                      ? Image.network(
                          recipe.thumbnailUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (
                            BuildContext context,
                            Widget child,
                            ImageChunkEvent? loadingProgress,
                          ) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return _RecipeImagePlaceholder(recipe: recipe);
                          },
                          errorBuilder: (_, __, ___) {
                            return _RecipeImagePlaceholder(recipe: recipe);
                          },
                        )
                      : _RecipeImagePlaceholder(recipe: recipe),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(recipe.title, style: headlineStyle),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _buildMetadataChips(context, recipe),
                    ),
                    if (secondaryLine != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(secondaryLine, style: bodyStyle),
                    ],
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Open the original recipe in-app',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: onTap,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: colors.earthUmber,
                            ),
                            child: const Text('View recipe'),
                          ),
                        ],
                      ),
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

  List<Widget> _buildMetadataChips(BuildContext context, RecipeCard recipe) {
    final entries = <String>[
      if (recipe.source.isNotEmpty) recipe.source,
      if (recipe.totalTime.isNotEmpty) recipe.totalTime,
      if (recipe.rating != null)
        recipe.reviews != null && recipe.reviews! > 0
            ? '${recipe.rating!.toStringAsFixed(1)} ★ (${recipe.reviews})'
            : '${recipe.rating!.toStringAsFixed(1)} ★',
      if (recipe.totalIngredients != null && recipe.totalIngredients! > 0)
        '${recipe.totalIngredients} ingredients'
      else if (recipe.ingredients.isNotEmpty)
        '${recipe.ingredients.length} ingredients',
      if (recipe.badge.isNotEmpty) recipe.badge,
      if (recipe.video.isNotEmpty) 'Video',
    ];

    return entries
        .map(
          (String label) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        )
        .toList();
  }

  String? _buildSecondaryLine(RecipeCard recipe) {
    if (recipe.ingredients.isNotEmpty) {
      return recipe.ingredients.take(3).join(' • ');
    }
    if (recipe.badge.isNotEmpty && recipe.video.isNotEmpty) {
      return '${recipe.badge} • Video included';
    }
    if (recipe.badge.isNotEmpty) {
      return recipe.badge;
    }
    if (recipe.video.isNotEmpty) {
      return 'Video included';
    }
    return null;
  }
}

class _RecipeImagePlaceholder extends StatelessWidget {
  const _RecipeImagePlaceholder({required this.recipe});

  final RecipeCard recipe;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFB7CBC7),
            Color(0xFF90ABA7),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            recipe.source.isNotEmpty ? recipe.source : 'Recipe',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white.withOpacity(0.94),
                ),
          ),
        ),
      ),
    );
  }
}

class _RecipeLoadingState extends StatelessWidget {
  const _RecipeLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(3, (int index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF6E8E8A).withOpacity(index.isEven ? 0.92 : 0.82),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            children: <Widget>[
              Container(
                height: 176,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(30)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: <Widget>[
                    Container(
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List<Widget>.generate(3, (int chipIndex) {
                        return Expanded(
                          child: Container(
                            height: 28,
                            margin: EdgeInsets.only(
                              right: chipIndex == 2 ? 0 : 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _RecipeMessageCard extends StatelessWidget {
  const _RecipeMessageCard({
    required this.toneColor,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final Color toneColor;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: toneColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.cardBlue.withOpacity(0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline, size: 16, color: colors.earthUmber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
