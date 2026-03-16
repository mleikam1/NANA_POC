import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/nana_theme.dart';

class NanaRadarLogo extends StatefulWidget {
  const NanaRadarLogo({super.key, this.size = 180});

  final double size;

  @override
  State<NanaRadarLogo> createState() => _NanaRadarLogoState();
}

class _NanaRadarLogoState extends State<NanaRadarLogo>
    with SingleTickerProviderStateMixin {
  static const Duration _loopDuration = Duration(milliseconds: 6000);

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _loopDuration)..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = NanaColors.of(context);

    return SizedBox(
      height: widget.size,
      width: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final loopProgress = _controller.value;
          return CustomPaint(
            painter: _NanaRadarPainter(
              colors: colors,
              t: loopProgress,
              loopDurationSeconds: _loopDuration.inMilliseconds / 1000,
            ),
          );
        },
      ),
    );
  }
}

class _NanaRadarPainter extends CustomPainter {
  const _NanaRadarPainter({
    required this.colors,
    required this.t,
    required this.loopDurationSeconds,
  });

  final NanaPalette colors;
  final double t;
  final double loopDurationSeconds;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final minDimension = math.min(size.width, size.height);
    final scale = minDimension / 180;

    final elapsed = t * loopDurationSeconds;
    final orbPulse = _wave(elapsed, periodSeconds: 2.1);
    final orbScale = _lerp(0.96, 1.04, orbPulse);

    final ringConfigs = <_RingConfig>[
      _RingConfig(
        radius: 42 * scale,
        pulse: _wave(elapsed + 0.08, periodSeconds: 2.3),
        color: colors.sunGlow,
      ),
      _RingConfig(
        radius: 60 * scale,
        pulse: _wave(elapsed + 0.32, periodSeconds: 2.4),
        color: colors.forestSage,
      ),
      _RingConfig(
        radius: 80 * scale,
        pulse: _wave(elapsed + 0.56, periodSeconds: 2.5),
        color: colors.skyMist,
      ),
    ];

    for (final ring in ringConfigs) {
      final ringScale = _lerp(0.99, 1.015, ring.pulse);
      final ringAlpha = _lerp(0.28, 0.54, ring.pulse);
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 * scale
        ..color = ring.color.withOpacity(ringAlpha);
      canvas.drawCircle(center, ring.radius * ringScale, ringPaint);
    }

    final sweepRotation = t * math.pi * 2;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sweepRotation - math.pi / 2);
    final sweepRect = Rect.fromCircle(
      center: Offset.zero,
      radius: 84 * scale,
    );
    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13 * scale
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: <Color>[
          colors.skyMist.withOpacity(0),
          colors.skyMist.withOpacity(0.03),
          colors.forestSage.withOpacity(0.16),
          colors.forestSage.withOpacity(0.24),
          colors.forestSage.withOpacity(0),
        ],
        stops: const <double>[0, 0.56, 0.68, 0.73, 1],
      ).createShader(sweepRect);
    canvas.drawArc(
      sweepRect,
      0,
      math.pi * 0.75,
      false,
      sweepPaint,
    );
    canvas.restore();

    final rippleProgress = (elapsed % 2.2) / 2.2;
    final rippleEase = Curves.easeOutCubic.transform(rippleProgress);
    final rippleAlpha = (1 - rippleProgress) * 0.18;
    if (rippleAlpha > 0.01) {
      final ripplePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.3 + (0.5 * (1 - rippleProgress))) * scale
        ..color = colors.skyMist.withOpacity(rippleAlpha);
      canvas.drawCircle(center, _lerp(26, 86, rippleEase) * scale, ripplePaint);
    }

    final orbShadowPaint = Paint()
      ..color = colors.forestSage.withOpacity(0.26)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20 * scale);
    canvas.drawCircle(center.translate(0, 7 * scale), 20 * scale, orbShadowPaint);

    final orbPaint = Paint()..color = colors.forestSage;
    canvas.drawCircle(center, 26 * scale * orbScale, orbPaint);
  }

  @override
  bool shouldRepaint(covariant _NanaRadarPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.colors != colors;
  }

  static double _wave(double seconds, {required double periodSeconds}) {
    final radians = (seconds / periodSeconds) * math.pi * 2;
    return (math.sin(radians) + 1) / 2;
  }

  static double _lerp(double a, double b, double t) => a + ((b - a) * t);
}

class _RingConfig {
  const _RingConfig({
    required this.radius,
    required this.pulse,
    required this.color,
  });

  final double radius;
  final double pulse;
  final Color color;
}
