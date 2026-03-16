import 'package:flutter/material.dart';

import '../models/briefing_bundle.dart';
import '../theme/nana_theme.dart';

class UnwindScreen extends StatelessWidget {
  const UnwindScreen({
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
      appBar: AppBar(title: const Text('Unwind')),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.softGreen,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Take 5 quiet minutes',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Short-form calm content belongs here: quick resets, soft routines, gentle how-tos, and cozy decompression.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () {},
                    child: const Text('Start a mini reset'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Short Videos',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            if (loading && (bundle?.shortVideos.isEmpty ?? true))
              const _VideoLoading()
            else
              ...((bundle?.shortVideos ?? const <ContentCard>[])
                  .map(
                    (ContentCard video) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.cardBlue,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: colors.ricePaper.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.play_circle_outline_rounded, size: 34),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  video.title,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(video.subtitle),
                                const SizedBox(height: 6),
                                Text(
                                  video.metadata['duration']?.toString() ?? video.source,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ],
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

class _VideoLoading extends StatelessWidget {
  const _VideoLoading();

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Column(
      children: List<Widget>.generate(2, (int index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 102,
          decoration: BoxDecoration(
            color: index.isEven ? colors.cardBlue : colors.softGreen,
            borderRadius: BorderRadius.circular(24),
          ),
        );
      }),
    );
  }
}
