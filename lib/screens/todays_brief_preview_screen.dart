import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_user_profile.dart';
import '../models/todays_brief_preview.dart';
import '../services/todays_brief_service.dart';
import '../theme/nana_theme.dart';
import 'in_app_webview_screen.dart';

class TodaysBriefPreviewScreen extends StatefulWidget {
  const TodaysBriefPreviewScreen({
    super.key,
    required this.profile,
    TodaysBriefService? service,
  }) : _service = service;

  final AppUserProfile profile;
  final TodaysBriefService? _service;

  @override
  State<TodaysBriefPreviewScreen> createState() => _TodaysBriefPreviewScreenState();
}

class _TodaysBriefPreviewScreenState extends State<TodaysBriefPreviewScreen> {
  late final PageController _pageController = PageController();
  late final Future<TodaysBriefPreview> _previewFuture =
      (widget._service ?? TodaysBriefService()).loadPreview(widget.profile);

  int _pageIndex = 0;

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
              colors.cardBlue.withValues(alpha: 0.7),
              colors.ricePaper,
              colors.cardSoft.withValues(alpha: 0.45),
            ],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<TodaysBriefPreview>(
            future: _previewFuture,
            builder: (BuildContext context, AsyncSnapshot<TodaysBriefPreview> snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const _LoadingView();
              }

              if (snapshot.hasError) {
                return _ErrorView(message: snapshot.error.toString());
              }

              final preview = snapshot.requireData;
              final pageCount = preview.sections.length + 1;

              return Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Today’s brief',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('EEEE, MMM d').format(preview.generatedAt),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: (_pageIndex + 1) / pageCount,
                        backgroundColor: colors.skyMist.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (int value) => setState(() => _pageIndex = value),
                      itemCount: pageCount,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == preview.sections.length) {
                          return _CompletionPage(topics: preview.topics);
                        }
                        return _SectionPage(
                          section: preview.sections[index],
                          isFirst: index == 0,
                          onOpenLink: _openLink,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pageIndex == 0
                                ? null
                                : () => _pageController.previousPage(
                                      duration: const Duration(milliseconds: 280),
                                      curve: Curves.easeOutCubic,
                                    ),
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              if (_pageIndex == pageCount - 1) {
                                Navigator.of(context).maybePop();
                                return;
                              }
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOutCubic,
                              );
                            },
                            child: Text(
                              _pageIndex == pageCount - 1 ? 'Done' : 'Next',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openLink(BriefPreviewItem item) async {
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

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(color: colors.forestSage),
            const SizedBox(height: 18),
            Text(
              'Building your calm cue preview…',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'We’re pulling together each selected topic for today’s brief.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Today’s brief', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                'We couldn’t build the preview right now.\n\n$message',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionPage extends StatelessWidget {
  const _SectionPage({
    required this.section,
    required this.isFirst,
    required this.onOpenLink,
  });

  final BriefPreviewSection section;
  final bool isFirst;
  final Future<void> Function(BriefPreviewItem item) onOpenLink;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(32),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.skyMist.withValues(alpha: 0.14),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (isFirst)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.softGreen,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Swipe horizontally to move through your brief',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              if (isFirst) const SizedBox(height: 18),
              Text(section.eyebrow, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 10),
              Text(section.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text(section.description, style: Theme.of(context).textTheme.bodyLarge),
              if (section.errorMessage != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  'Note: ${section.errorMessage}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 22),
              if (section.kind == BriefPreviewSectionKind.weather)
                _WeatherPanel(section: section)
              else if (section.items.isEmpty)
                _EmptyPanel(topic: section.topic)
              else
                ...section.items.map(
                  (BriefPreviewItem item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _PreviewCard(
                      item: item,
                      kind: section.kind,
                      onTap: item.link == null || item.link!.isEmpty
                          ? null
                          : () => onOpenLink(item),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeatherPanel extends StatelessWidget {
  const _WeatherPanel({required this.section});

  final BriefPreviewSection section;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    final weather = section.weather;
    if (weather == null) {
      return _EmptyPanel(topic: section.topic);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.cardBlue,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(weather.location, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    weather.temperature.isEmpty ? '--' : '${weather.temperature}°',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        weather.condition.isEmpty ? 'Quiet skies' : weather.condition,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'High ${weather.high}° • Low ${weather.low}°',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Next few hours', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: weather.hourly.map((BriefPreviewWeatherHour hour) {
            return Container(
              width: 132,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.softYellow,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(hour.label, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Text('${hour.temperature}°', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(hour.condition, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.item,
    required this.kind,
    this.onTap,
  });

  final BriefPreviewItem item;
  final BriefPreviewSectionKind kind;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    final backgroundColor = switch (kind) {
      BriefPreviewSectionKind.recipes => colors.cardSoft,
      BriefPreviewSectionKind.videos => colors.softGreen,
      BriefPreviewSectionKind.curated => colors.softYellow,
      _ => Colors.white,
    };

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(item.badge, style: Theme.of(context).textTheme.labelLarge),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(item.subtitle, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  if (item.source.isNotEmpty)
                    _MetaChip(label: item.source),
                  ...item.metadata.entries.map(
                    (MapEntry<String, String> entry) => _MetaChip(
                      label: '${entry.key}: ${entry.value}',
                    ),
                  ),
                ],
              ),
              if (onTap != null) ...<Widget>[
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Text('Open source', style: Theme.of(context).textTheme.labelLarge),
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.ricePaper.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.topic});

  final String topic;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardSoft,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        'No fresh items landed for $topic just yet. Pull this preview up again in a bit.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _CompletionPage extends StatelessWidget {
  const _CompletionPage({required this.topics});

  final List<String> topics;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.softGreen,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('You’re all caught up!', style: Theme.of(context).textTheme.labelLarge),
            ),
            const Spacer(),
            Text('A calmer finish for now.', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 16),
            Text(
              'Today\'s brief covered ${topics.join(', ')}. Come back anytime from Care to preview the full-screen calm cue again.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: topics
                  .map(
                    (String topic) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.cardBlue,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(topic, style: Theme.of(context).textTheme.bodySmall),
                    ),
                  )
                  .toList(),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
