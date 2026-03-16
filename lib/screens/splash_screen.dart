import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/nana_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.subtitle = 'A calmer companion is getting things ready.',
  });

  final String subtitle;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))
        ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _ring(double size, double angle, Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Transform.rotate(
          angle: angle + (_controller.value * math.pi * 2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.8),
            ),
          ),
        );
      },
    );
  }

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
                SizedBox(
                  height: 180,
                  width: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      _ring(160, 0.0, colors.skyMist.withOpacity(0.6)),
                      _ring(120, 0.5, colors.forestSage.withOpacity(0.7)),
                      _ring(84, 1.0, colors.sunGlow.withOpacity(0.8)),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: colors.forestSage,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                              color: colors.forestSage.withOpacity(0.25),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'nana',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: colors.earthUmber,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.subtitle,
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
