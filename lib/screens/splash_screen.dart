import 'package:flutter/material.dart';

import 'main_menu_screen.dart';

/// Unity-style splash: black field, centered logo fade-in, brief hold, fade out.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String routeName = '/splash';
  static const String logoAsset = 'assets/images/logo/logo_pts.png';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bg = Color(0xFF000000);
  static const Duration _fadeIn = Duration(milliseconds: 900);
  static const Duration _hold = Duration(milliseconds: 1400);
  static const Duration _fadeOut = Duration(milliseconds: 700);

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _fadeIn + _hold + _fadeOut,
    );

    // Unity-like logo reveal: fade + slight scale up, hold, then fade out.
    _opacity = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: _fadeIn.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(1),
        weight: _hold.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: _fadeOut.inMilliseconds.toDouble(),
      ),
    ]).animate(_controller);

    _scale = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.92, end: 1)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: _fadeIn.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(1),
        weight: (_hold + _fadeOut).inMilliseconds.toDouble(),
      ),
    ]).animate(_controller);

    _controller.forward().whenComplete(_goToMenu);
  }

  void _goToMenu() {
    if (!mounted || _navigating) return;
    _navigating = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation) =>
            const MainMenuScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final double logoWidth = (size.shortestSide * 0.55).clamp(180.0, 320.0);

    return Scaffold(
      backgroundColor: _bg,
      body: ColoredBox(
        color: _bg,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) {
              return Opacity(
                opacity: _opacity.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: _scale.value,
                  child: child,
                ),
              );
            },
            child: Image.asset(
              SplashScreen.logoAsset,
              width: logoWidth,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              gaplessPlayback: true,
            ),
          ),
        ),
      ),
    );
  }
}
