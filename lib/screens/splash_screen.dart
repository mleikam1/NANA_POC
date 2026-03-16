import 'package:flutter/material.dart';

import '../theme/nana_theme.dart';
import '../widgets/nana_radar_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({
    super.key,
    this.subtitle = 'A calmer companion is getting things ready.',
  });

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const NanaRadarLogo(size: 180),
                const SizedBox(height: 28),
                Text(
                  'nana',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: colors.earthUmber,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
