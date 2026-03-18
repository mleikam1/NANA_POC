import 'package:flutter/material.dart';

import '../models/app_user_profile.dart';
import '../models/local_news_story.dart';
import '../screens/in_app_webview_screen.dart';
import '../services/local_news_service.dart';
import '../theme/nana_theme.dart';

class LocalNewsBlock extends StatefulWidget {
  const LocalNewsBlock({
    super.key,
    required this.profile,
    required this.focusSignal,
    this.service,
    this.onOpenStory,
  });

  final AppUserProfile profile;
  final int focusSignal;
  final LocalNewsService? service;
  final ValueChanged<LocalNewsStory>? onOpenStory;

  @override
  State<LocalNewsBlock> createState() => LocalNewsBlockState();
}

class LocalNewsBlockState extends State<LocalNewsBlock> {
  final GlobalKey _anchorKey = GlobalKey();

  late final LocalNewsService _service = widget.service ?? LocalNewsService();

  bool _loading = true;
  bool _refreshing = false;
  LocalNewsResult? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  @override
  void didUpdateWidget(covariant LocalNewsBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.uid != widget.profile.uid ||
        oldWidget.profile.locationLabel != widget.profile.locationLabel ||
        oldWidget.profile.locationLatitude != widget.profile.locationLatitude ||
        oldWidget.profile.locationLongitude != widget.profile.locationLongitude) {
      _loadNews(forceRefresh: true);
    }

    if (oldWidget.focusSignal != widget.focusSignal) {
      focusLocalNews();
    }
  }

  Future<void> focusLocalNews() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _anchorKey.currentContext;
      if (context == null) {
        return;
      }
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        alignment: 0.02,
      );
    });
  }

  Future<void> _loadNews({bool forceRefresh = false}) async {
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = _result == null;
      _refreshing = _result != null;
      _errorMessage = null;
    });

    try {
      final result = await _service.fetchLocalNews(
        widget.profile,
        forceRefresh: forceRefresh,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
        _loading = false;
        _refreshing = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _refreshing = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    final result = _result;
    final stories = result?.stories ?? const <LocalNewsStory>[];
    final hasStories = stories.isNotEmpty;

    return Column(
      key: _anchorKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Local News',
                    key: const Key('local-news-title'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    result == null
                        ? 'Five steady local stories, shaped around your saved area.'
                        : 'Five steady local stories for ${result.location.label.isEmpty ? 'your area' : result.location.label}.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              tooltip: 'Refresh local news',
              onPressed: _refreshing ? null : () => _loadNews(forceRefresh: true),
              icon: _refreshing
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
        if (_loading)
          const _LocalNewsLoadingState()
        else if (!hasStories && _errorMessage != null)
          _LocalNewsMessageCard(
            toneColor: colors.cardSoft,
            title: 'We couldn’t load local stories just now',
            body: _errorMessage!,
            actionLabel: 'Try again',
            onAction: () => _loadNews(forceRefresh: true),
          )
        else if (!hasStories)
          _LocalNewsMessageCard(
            toneColor: colors.cardSoft,
            title: 'No local stories yet',
            body:
                'We did not find five good local stories for this saved area. Try refreshing in a little while.',
            actionLabel: 'Refresh',
            onAction: () => _loadNews(forceRefresh: true),
          )
        else ...<Widget>[
          if (result!.isStale || result.usedCache || result.isPartial)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StatusPill(
                label: result.isStale
                    ? 'Showing saved stories while we retry in the background.'
                    : result.isPartial
                        ? 'Some articles used fallback summaries, but the local briefing is ready.'
                        : 'Showing saved local stories.',
              ),
            ),
          ...stories
              .map(
                (LocalNewsStory story) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _LocalNewsStoryCard(story: story),
                ),
              )
              .toList(),
          _OpenOriginalStoriesFooter(
            stories: stories,
            onTapStory: (LocalNewsStory story) => _openStory(context, story),
          ),
        ],
      ],
    );
  }

  void _openStory(BuildContext context, LocalNewsStory story) {
    if (widget.onOpenStory != null) {
      widget.onOpenStory!(story);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InAppWebViewScreen(
          title: story.source.isNotEmpty ? story.source : story.title,
          url: story.url,
        ),
      ),
    );
  }
}

class _LocalNewsStoryCard extends StatelessWidget {
  const _LocalNewsStoryCard({required this.story});

  final LocalNewsStory story;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF5B8787),
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.skyMist.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${story.rank}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            story.calmHeadline,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  height: 1.25,
                ),
          ),
          const SizedBox(height: 12),
          ...story.bullets.map(
            (String bullet) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bullet,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.94),
                            height: 1.45,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            story.title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.78),
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: <Widget>[
              _MetaChip(label: story.source.isEmpty ? 'Local source' : story.source),
              _MetaChip(label: story.relativeTimeLabel),
              _MetaChip(label: story.readTimeLabel),
              if (story.extractionFailed) const _MetaChip(label: 'Fallback summary'),
            ],
          ),
        ],
      ),
    );
  }
}

class _OpenOriginalStoriesFooter extends StatelessWidget {
  const _OpenOriginalStoriesFooter({
    required this.stories,
    required this.onTapStory,
  });

  final List<LocalNewsStory> stories;
  final ValueChanged<LocalNewsStory> onTapStory;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Open original stories',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Read the full reporting in NANA’s in-app reader.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          ...stories.map(
            (LocalNewsStory story) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                key: Key('open-original-story-${story.rank}'),
                onPressed: () => onTapStory(story),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  alignment: Alignment.centerLeft,
                  side: BorderSide(color: colors.forestSage.withOpacity(0.18)),
                ),
                child: Text(
                  '${story.rank}. ${story.title}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
            ),
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.softYellow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _LocalNewsMessageCard extends StatelessWidget {
  const _LocalNewsMessageCard({
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
      width: double.infinity,
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

class _LocalNewsLoadingState extends StatefulWidget {
  const _LocalNewsLoadingState();

  @override
  State<_LocalNewsLoadingState> createState() => _LocalNewsLoadingStateState();
}

class _LocalNewsLoadingStateState extends State<_LocalNewsLoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final opacity = 0.55 + (_controller.value * 0.25);
        return Column(
          children: List<Widget>.generate(
            3,
            (int index) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              height: 184,
              decoration: BoxDecoration(
                color: const Color(0xFF5B8787).withOpacity(opacity - (index * 0.04)),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        );
      },
    );
  }
}
