import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A lightweight, self-contained confetti celebration.
///
/// A festive shower of colored pieces drifts down across the screen while
/// spinning, then fades out. Runs once for [duration] when mounted, so simply
/// dropping it into a [Stack] triggers the celebration.
///
/// Implemented with plain positioned widgets (rather than a CustomPainter) so
/// it renders reliably across Flutter's web renderers.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    super.key,
    this.particleCount = 130,
    this.duration = const Duration(milliseconds: 4200),
  });

  final int particleCount;
  final Duration duration;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  static const List<Color> _palette = <Color>[
    Color(0xFFEF5350),
    Color(0xFFFFCA28),
    Color(0xFF66BB6A),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
    Color(0xFFFF7043),
    Color(0xFF26C6DA),
  ];

  static const double _gravity = 0.22;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final math.Random rnd = math.Random();
    _particles = List<_Particle>.generate(widget.particleCount, (int i) {
      return _Particle(
        originX: rnd.nextDouble(),
        // Spread from just above the top down into the upper third so the
        // shower fills the screen almost immediately and lingers.
        originY: -0.6 + rnd.nextDouble() * 0.8,
        vx: (rnd.nextDouble() - 0.5) * 0.4,
        vy: 0.15 + rnd.nextDouble() * 0.2,
        color: _palette[rnd.nextInt(_palette.length)],
        size: 8 + rnd.nextDouble() * 9,
        rotation: rnd.nextDouble() * math.pi * 2,
        spin: (rnd.nextDouble() - 0.5) * 12,
        wobble: rnd.nextDouble() * math.pi * 2,
      );
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double w = constraints.maxWidth;
          final double h = constraints.maxHeight;
          return AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, _) {
              final double t = _controller.value;
              final double alpha = t < 0.85
                  ? 1.0
                  : (1.0 - (t - 0.85) / 0.15).clamp(0.0, 1.0);
              return Stack(
                children: <Widget>[
                  for (final _Particle p in _particles)
                    _buildParticle(p, t, w, h, alpha),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildParticle(_Particle p, double t, double w, double h, double a) {
    final double fx =
        p.originX + p.vx * t + math.sin(p.wobble + t * 8) * 0.02;
    final double fy = p.originY + p.vy * t + 0.5 * _gravity * t * t;
    final double squash = 0.45 + 0.55 * math.sin(p.wobble + t * 10).abs();
    return Positioned(
      left: fx * w,
      top: fy * h,
      child: Opacity(
        opacity: a,
        child: Transform.rotate(
          angle: p.rotation + p.spin * t,
          child: Container(
            width: p.size,
            height: p.size * squash,
            decoration: BoxDecoration(
              color: p.color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.originX,
    required this.originY,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.spin,
    required this.wobble,
  });

  final double originX;
  final double originY;
  final double vx;
  final double vy;
  final Color color;
  final double size;
  final double rotation;
  final double spin;
  final double wobble;
}
