import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_user_profile.dart';
import '../models/brief_content.dart';
import '../models/onboarding_topic.dart';
import '../repositories/brief_content_repository.dart';
import '../theme/nana_theme.dart';
import '../widgets/brief_preview_section_widgets.dart';
import 'in_app_webview_screen.dart';

class TodaysBriefPreviewScreen extends StatefulWidget {
  const TodaysBriefPreviewScreen({
    super.key,
    required this.profile,
    this.selectedTopics,
    Future<BriefPage>? initialBriefFuture,
    BriefContentRepository? repository,
  })  : _initialBriefFuture = initialBriefFuture,
        _repository = repository;

  final AppUserProfile profile;
  final List<OnboardingTopic>? selectedTopics;
  final Future<BriefPage>? _initialBriefFuture;
  final BriefContentRepository? _repository;

  @override
  State<TodaysBriefPreviewScreen> createState() => _TodaysBriefPreviewScreenState();
}

class _TodaysBriefPreviewScreenState extends State<TodaysBriefPreviewScreen> {
  late final PageController _pageController = PageController();
  late final BriefContentRepository _repository =
      widget._repository ?? BriefContentRepository();

  // Keeping a stable future lets notification-triggered launches reuse the same
  // prepared brief work instead of briefly flashing a second network load.
  late Future<BriefPage> _briefFuture =
      widget._initialBriefFuture ?? _loadBrief();
  int _currentPageIndex = 0;

  Future<BriefPage> _loadBrief({bool forceRefresh = false}) {
    return _repository.loadBriefPage(
      widget.profile,
      selectedTopics: widget.selectedTopics,
      forceRefresh: forceRefresh,
    );
  }

  void _reloadBrief({bool forceRefresh = false}) {
    setState(() {
      _currentPageIndex = 0;
      _briefFuture = _loadBrief(forceRefresh: forceRefresh);
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Scaffold(
      backgroundColor: colors.ricePaper,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              colors.cardBlue.withValues(alpha: 0.72),
              colors.ricePaper,
              colors.cardSoft.withValues(alpha: 0.48),
            ],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<BriefPage>(
            future: _briefFuture,
            builder: (BuildContext context, AsyncSnapshot<BriefPage> snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const _LoadingView();
              }

              if (snapshot.hasError) {
                return _ErrorView(
                  message: snapshot.error.toString(),
                  onRetry: () => _reloadBrief(forceRefresh: true),
                );
              }

              final brief = snapshot.requireData;
              if (brief.sections.isEmpty) {
                return _EmptyView(onRefresh: () => _reloadBrief(forceRefresh: true));
              }

              final totalPageCount = brief.sections.length + 1;
              final currentSection = _currentPageIndex < brief.sections.length
                  ? brief.sections[_currentPageIndex]
                  : null;
              final currentPageLabel = currentSection?.topic.label ?? 'Caught up';

              return LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final horizontalPadding = constraints.maxWidth >= 900 ? 28.0 : 20.0;

                  return Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.fromLTRB(horizontalPadding, 14, horizontalPadding, 8),
                        child: _Header(
                          generatedAt: brief.generatedAt,
                          currentTopic: currentPageLabel,
                          onClose: () => Navigator.of(context).maybePop(),
                          onRefresh: () => _reloadBrief(forceRefresh: true),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: _PageIndicatorRow(
                          totalPageCount: totalPageCount,
                          currentPageIndex: _currentPageIndex,
                          currentPageLabel: currentPageLabel,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          physics: const BouncingScrollPhysics(),
                          onPageChanged: (int value) => setState(() => _currentPageIndex = value),
                          itemCount: totalPageCount,
                          itemBuilder: (BuildContext context, int index) {
                            if (index == brief.sections.length) {
                              return BriefPreviewCompletionPage(
                                topics: brief.selectedTopics,
                              );
                            }
                            return BriefPreviewSectionView(
                              section: brief.sections[index],
                              isFirst: index == 0,
                              onOpenLink: _openLink,
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 20),
                        child: _BottomControls(
                          isFirstPage: _currentPageIndex == 0,
                          isLastPage: _currentPageIndex == totalPageCount - 1,
                          onBack: () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                          ),
                          onNext: () {
                            if (_currentPageIndex == totalPageCount - 1) {
                              Navigator.of(context).maybePop();
                              return;
                            }
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutCubic,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openLink(BriefContentItem item) async {
    final link = item.link;
    if (link == null || link.isEmpty || !mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InAppWebViewScreen(title: item.title, url: link),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.generatedAt,
    required this.currentTopic,
    required this.onClose,
    required this.onRefresh,
  });

  final DateTime generatedAt;
  final String? currentTopic;
  final VoidCallback onClose;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final actionButtons = Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: <Widget>[
        FilledButton.tonalIcon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Refresh'),
        ),
        FilledButton.tonalIcon(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
          label: const Text('Close'),
        ),
      ],
    );

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Today’s brief',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          DateFormat('EEEE, MMM d').format(generatedAt),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (currentTopic != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            currentTopic!,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              heading,
              const SizedBox(height: 14),
              actionButtons,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: heading),
            const SizedBox(width: 12),
            actionButtons,
          ],
        );
      },
    );
  }
}

class _PageIndicatorRow extends StatelessWidget {
  const _PageIndicatorRow({
    required this.totalPageCount,
    required this.currentPageIndex,
    required this.currentPageLabel,
  });

  final int totalPageCount;
  final int currentPageIndex;
  final String currentPageLabel;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                currentPageLabel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Text(
              'Page ${currentPageIndex + 1} of $totalPageCount',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: (currentPageIndex + 1) / totalPageCount,
            backgroundColor: colors.skyMist.withValues(alpha: 0.18),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List<Widget>.generate(totalPageCount, (int index) {
            final isActive = index == currentPageIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: isActive ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? colors.forestSage : colors.skyMist.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.isFirstPage,
    required this.isLastPage,
    required this.onBack,
    required this.onNext,
  });

  final bool isFirstPage;
  final bool isLastPage;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton(
            onPressed: isFirstPage ? null : onBack,
            child: const Text('Back'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: onNext,
            child: Text(isLastPage ? 'Done' : 'Next'),
          ),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(32),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colors.skyMist.withValues(alpha: 0.16),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: colors.forestSage,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Building your calm cue preview…',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'We’re gathering each selected topic into a soft, swipeable preview.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 22),
                const _LoadingCardPlaceholder(),
                const SizedBox(height: 14),
                const _LoadingCardPlaceholder(isCompact: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingCardPlaceholder extends StatelessWidget {
  const _LoadingCardPlaceholder({this.isCompact = false});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    final lineColor = colors.skyMist.withValues(alpha: 0.22);

    return Container(
      padding: EdgeInsets.all(isCompact ? 18 : 20),
      decoration: BoxDecoration(
        color: isCompact ? colors.ricePaper : colors.cardBlue.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: isCompact ? 110 : 140,
            height: 12,
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: isCompact ? 16 : 18,
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: isCompact ? 180 : 240,
            height: 14,
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.cardSoft,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(Icons.cloud_off_rounded, color: colors.earthUmber),
                ),
                const SizedBox(height: 18),
                Text(
                  'We couldn’t load today’s preview.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.softGreen,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: colors.forestSage),
                ),
                const SizedBox(height: 18),
                Text(
                  'No preview sections yet.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  'Pick a few topics or refresh again to build your calm cue.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh preview'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
