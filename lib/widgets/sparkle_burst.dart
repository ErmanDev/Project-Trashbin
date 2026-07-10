import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A quick burst of star sparkles at a screen position.
///
/// Mount with a [GlobalKey] or inside a [Stack]; fades out automatically.
class SparkleBurst extends StatefulWidget {
  const SparkleBurst({
    super.key,
    this.particleCount = 14,
    this.duration = const Duration(milliseconds: 700),
  });

  final int particleCount;
  final Duration duration;

  @override
  State<SparkleBurst> createState() => _SparkleBurstState();
}

class _SparkleBurstState extends State<SparkleBurst>
    with SingleTickerProviderStateMixin {
  static const List<Color> _colors = <Color>[
    Color(0xFFFFEB3B),
    Color(0xFFFFFFFF),
    Color(0xFFFFCA28),
    Color(0xFF80DEEA),
  ];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final List<_Spark> _sparks;

  @override
  void initState() {
    super.initState();
    final math.Random rnd = math.Random();
    _sparks = List<_Spark>.generate(widget.particleCount, (int i) {
      final double angle = rnd.nextDouble() * math.pi * 2;
      final double dist = 0.25 + rnd.nextDouble() * 0.75;
      return _Spark(
        dx: math.cos(angle) * dist,
        dy: math.sin(angle) * dist,
        size: 6 + rnd.nextDouble() * 10,
        color: _colors[rnd.nextInt(_colors.length)],
        spin: (rnd.nextDouble() - 0.5) * 6,
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
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, _) {
          final double t = _controller.value;
          final double alpha =
              t < 0.55 ? 1.0 : (1.0 - (t - 0.55) / 0.45).clamp(0.0, 1.0);
          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              for (final _Spark s in _sparks) _buildSpark(s, t, alpha),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSpark(_Spark s, double t, double alpha) {
    final double spread = 52 * t;
    return Positioned(
      left: s.dx * spread,
      top: s.dy * spread,
      child: Opacity(
        opacity: alpha,
        child: Transform.rotate(
          angle: s.spin * t,
          child: Icon(
            Icons.star,
            color: s.color,
            size: s.size,
          ),
        ),
      ),
    );
  }
}

class _Spark {
  const _Spark({
    required this.dx,
    required this.dy,
    required this.size,
    required this.color,
    required this.spin,
  });

  final double dx;
  final double dy;
  final double size;
  final Color color;
  final double spin;
}
