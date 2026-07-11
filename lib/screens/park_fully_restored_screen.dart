import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_progress.dart';
import '../services/save_manager.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/mobile_mayor_dialogue_stack.dart';
import '../widgets/pixel_button.dart';

enum _RestorePhase {
  pan,
  life,
  mayor,
  clap,
  banner,
  done,
}

/// Full park restoration cutscene after Park Level 2.
class ParkFullyRestoredScreen extends StatefulWidget {
  const ParkFullyRestoredScreen({super.key});

  @override
  State<ParkFullyRestoredScreen> createState() =>
      _ParkFullyRestoredScreenState();
}

class _ParkFullyRestoredScreenState extends State<ParkFullyRestoredScreen>
    with TickerProviderStateMixin {
  static const Color _mayorAccent = Color(0xFF3949AB);
  static const Color _border = Color(0xFF2B2B3A);

  static const List<String> _lines = <String>[
    'Look around.',
    'Because of your hard work, our park is alive again.',
    'The people of Green Town are grateful.',
  ];

  static const Duration _charTick = Duration(milliseconds: 28);
  static const Duration _pauseBetweenLines = Duration(milliseconds: 850);

  _RestorePhase _phase = _RestorePhase.pan;
  int _lineIndex = -1;
  String _shownText = '';
  bool _typing = false;
  bool _rewardsSaved = false;

  Timer? _typeTimer;
  Timer? _pauseTimer;

  late final AnimationController _pan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );
  late final AnimationController _life = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3800),
  );
  late final AnimationController _mayorIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _clap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    _pan.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _phase = _RestorePhase.life);
        _life.forward();
      }
    });
    _life.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _phase = _RestorePhase.mayor);
        _mayorIn.forward();
        _advanceLine();
      }
    });
    _pan.forward();
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _pauseTimer?.cancel();
    _pan.dispose();
    _life.dispose();
    _mayorIn.dispose();
    _clap.dispose();
    super.dispose();
  }

  void _advanceLine() {
    if (!mounted) return;
    final int next = _lineIndex + 1;
    if (next >= _lines.length) {
      setState(() => _phase = _RestorePhase.clap);
      _clap.forward().whenComplete(() {
        if (mounted) _showBanner();
      });
      return;
    }
    setState(() => _lineIndex = next);
    _typeLine(_lines[next]);
  }

  void _typeLine(String full) {
    _typeTimer?.cancel();
    setState(() {
      _shownText = '';
      _typing = true;
    });
    int shown = 0;
    _typeTimer = Timer.periodic(_charTick, (Timer timer) {
      if (shown >= full.length) {
        timer.cancel();
        setState(() => _typing = false);
        _pauseTimer = Timer(_pauseBetweenLines, _advanceLine);
        return;
      }
      shown++;
      setState(() => _shownText = full.substring(0, shown));
    });
  }

  Future<void> _showBanner() async {
    if (!_rewardsSaved) {
      _rewardsSaved = true;
      await SaveManager.instance.completeParkLevel2();
    }
    if (!mounted) return;
    setState(() => _phase = _RestorePhase.banner);
  }

  void _onTap() {
    switch (_phase) {
      case _RestorePhase.mayor:
        if (_lineIndex < 0) return;
        if (_typing) {
          _typeTimer?.cancel();
          _pauseTimer?.cancel();
          setState(() {
            _shownText = _lines[_lineIndex];
            _typing = false;
          });
          _pauseTimer = Timer(_pauseBetweenLines, _advanceLine);
        } else {
          _pauseTimer?.cancel();
          _advanceLine();
        }
      case _RestorePhase.clap:
        _clap.stop();
        _showBanner();
      case _RestorePhase.banner:
        _finish();
      default:
        break;
    }
  }

  void _finish() {
    setState(() => _phase = _RestorePhase.done);
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onTap,
        behavior: HitTestBehavior.opaque,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double w = constraints.maxWidth;
            final double h = constraints.maxHeight;
            final bool compact = h < 420;

            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                // Slow pan across the clean park.
                AnimatedBuilder(
                  animation: _pan,
                  builder: (BuildContext context, _) {
                    final double t = Curves.easeInOut.transform(_pan.value);
                    final double scale = 1.12 - t * 0.06;
                    final double dx = (t - 0.5) * w * 0.12;
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: Transform.scale(
                        scale: scale,
                        child: Image.asset(
                          GameProgress.parkCleanBg,
                          fit: BoxFit.cover,
                          width: w,
                          height: h,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                    );
                  },
                ),

                // Life returns overlays (flowers, birds, kids, families).
                if (_phase.index >= _RestorePhase.life.index)
                  AnimatedBuilder(
                    animation: _life,
                    builder: (BuildContext context, _) {
                      return _LifeReturnsOverlay(
                        progress: _phase.index > _RestorePhase.life.index
                            ? 1.0
                            : _life.value,
                        compact: compact,
                        width: w,
                        height: h,
                      );
                    },
                  ),

                // Stage captions during pan / life.
                if (_phase == _RestorePhase.pan || _phase == _RestorePhase.life)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: compact ? 10 : 18,
                    child: SafeArea(
                      bottom: false,
                      child: Center(
                        child: _CaptionChip(
                          text: _phase == _RestorePhase.pan
                              ? 'The park awakens...'
                              : _lifeCaption(_life.value),
                          compact: compact,
                        ),
                      ),
                    ),
                  ),

                // Mayor dialogue.
                if (_phase == _RestorePhase.mayor && _lineIndex >= 0)
                  _buildMayor(compact: compact, width: w, height: h),

                // Townspeople clap.
                if (_phase == _RestorePhase.clap ||
                    _phase == _RestorePhase.banner)
                  AnimatedBuilder(
                    animation: _clap,
                    builder: (BuildContext context, _) {
                      return _ClapOverlay(
                        progress: _phase == _RestorePhase.banner
                            ? 1.0
                            : _clap.value,
                        compact: compact,
                        width: w,
                        height: h,
                      );
                    },
                  ),

                // Banner + rewards.
                if (_phase == _RestorePhase.banner) ...<Widget>[
                  const Positioned.fill(child: ConfettiOverlay()),
                  _buildBanner(compact),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String _lifeCaption(double t) {
    if (t < 0.2) return 'All garbage disappears...';
    if (t < 0.35) return 'Grass is bright green!';
    if (t < 0.5) return 'Flowers bloom throughout the park!';
    if (t < 0.65) return 'Trees look healthy!';
    if (t < 0.78) return 'Birds return!';
    if (t < 0.9) return 'Children laugh and play!';
    return 'Families walk through the park!';
  }

  Widget _buildMayor({
    required bool compact,
    required double width,
    required double height,
  }) {
    if (compact) {
      return Positioned(
        left: 10,
        right: 10,
        bottom: 10,
        child: SafeArea(
          top: false,
          child: MobileMayorDialogueStack(
            width: width,
            text: _shownText,
            mayorIn: _mayorIn,
            mayorAccent: _mayorAccent,
            showContinueHint: !_typing,
          ),
        ),
      );
    }

    final double spriteHeight = height * 0.72;
    return Stack(
      children: <Widget>[
        AnimatedBuilder(
          animation: _mayorIn,
          builder: (BuildContext context, Widget? child) {
            final double t = Curves.easeOut.transform(_mayorIn.value);
            // Walk in from the left toward the player.
            return Positioned(
              bottom: 0,
              left: width * (0.02 + (1 - t) * -0.18),
              height: spriteHeight,
              child: Opacity(opacity: t, child: child),
            );
          },
          child: Image.asset(
            'assets/images/png/char_mayor_cutout.png',
            filterQuality: FilterQuality.none,
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: DialogueBox(
              text: _shownText,
              speakerName: 'Mayor',
              accent: _mayorAccent,
              showContinueHint: !_typing,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBanner(bool compact) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 32,
          vertical: compact ? 8 : 16,
        ),
        child: Container(
          constraints: BoxConstraints(maxWidth: compact ? 480 : 560),
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 24,
            compact ? 12 : 20,
            compact ? 14 : 24,
            compact ? 12 : 20,
          ),
          decoration: BoxDecoration(
            color: const Color(0xF00E0E1A),
            border: Border.all(color: const Color(0xFF4CAF50), width: 5),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                blurRadius: 22,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '🌳 Park Restored!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Jersey10',
                  fontSize: compact ? 34 : 48,
                  height: 1,
                  color: Colors.white,
                  shadows: const <Shadow>[
                    Shadow(color: _border, offset: Offset(2, 2)),
                  ],
                ),
              ),
              SizedBox(height: compact ? 12 : 16),
              _RewardLine(
                icon: Icons.monetization_on,
                color: const Color(0xFFFFC107),
                label: 'Bonus Coins',
                value: '+${GameProgress.parkFullyRestoredBonusCoins}',
                compact: compact,
              ),
              SizedBox(height: compact ? 6 : 8),
              _RewardLine(
                icon: Icons.checkroom,
                color: const Color(0xFF66BB6A),
                label: 'Cosmetic Unlock',
                value: GameProgress.greenCapName,
                compact: compact,
              ),
              SizedBox(height: compact ? 6 : 8),
              _RewardLine(
                icon: Icons.star,
                color: const Color(0xFFFFCA28),
                label: 'Park Completion Star',
                value: '★',
                compact: compact,
              ),
              SizedBox(height: compact ? 6 : 8),
              _RewardLine(
                icon: Icons.school,
                color: const Color(0xFFFFB300),
                label: 'School District',
                value: 'Unlocked!',
                compact: compact,
              ),
              SizedBox(height: compact ? 14 : 18),
              Center(
                child: PixelButton(
                  label: 'Back to Map',
                  icon: Icons.map,
                  color: const Color(0xFF4CAF50),
                  width: null,
                  compact: true,
                  onPressed: _finish,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptionChip extends StatelessWidget {
  const _CaptionChip({required this.text, required this.compact});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xCC0E0E1A),
        border: Border.all(color: const Color(0xFF4CAF50), width: 3),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Jersey10',
          fontSize: compact ? 18 : 24,
          height: 1,
          color: const Color(0xFF9FE6A0),
        ),
      ),
    );
  }
}

class _LifeReturnsOverlay extends StatelessWidget {
  const _LifeReturnsOverlay({
    required this.progress,
    required this.compact,
    required this.width,
    required this.height,
  });

  final double progress;
  final bool compact;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final double trashOut = (1 - progress / 0.18).clamp(0.0, 1.0);
    final double grassIn =
        Curves.easeOut.transform(((progress - 0.12) / 0.25).clamp(0.0, 1.0));
    final double flowersIn =
        Curves.elasticOut.transform(((progress - 0.3) / 0.25).clamp(0.0, 1.0));
    final double birdsIn =
        Curves.easeOut.transform(((progress - 0.5) / 0.2).clamp(0.0, 1.0));
    final double kidsIn =
        Curves.easeOut.transform(((progress - 0.65) / 0.2).clamp(0.0, 1.0));
    final double familiesIn =
        Curves.easeOut.transform(((progress - 0.8) / 0.2).clamp(0.0, 1.0));

    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          if (grassIn > 0)
            Positioned.fill(
              child: Opacity(
                opacity: grassIn * 0.35,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.1,
                      colors: <Color>[
                        Color(0x664CAF50),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (trashOut > 0)
            ...List<Widget>.generate(5, (int i) {
              return Positioned(
                left: width * (0.15 + i * 0.15),
                top: height * (0.55 + (i.isEven ? 0.05 : -0.02)),
                child: Opacity(
                  opacity: trashOut,
                  child: Icon(
                    Icons.delete_outline,
                    color: const Color(0xFF8D6E63),
                    size: compact ? 22 : 28,
                  ),
                ),
              );
            }),
          if (flowersIn > 0)
            ...List<Widget>.generate(8, (int i) {
              return Positioned(
                left: width * (0.08 + (i % 4) * 0.22),
                top: height * (0.42 + (i ~/ 4) * 0.18),
                child: Transform.scale(
                  scale: flowersIn,
                  child: Text(
                    i.isEven ? '🌸' : '🌼',
                    style: TextStyle(fontSize: compact ? 18 : 24),
                  ),
                ),
              );
            }),
          if (birdsIn > 0)
            ...List<Widget>.generate(4, (int i) {
              final double fly = birdsIn;
              return Positioned(
                left: width * (0.2 + i * 0.18) + fly * 20,
                top: height * (0.12 + i * 0.04) - fly * 10,
                child: Opacity(
                  opacity: birdsIn,
                  child: Text(
                    '🐦',
                    style: TextStyle(fontSize: compact ? 18 : 22),
                  ),
                ),
              );
            }),
          if (kidsIn > 0) ...<Widget>[
            Positioned(
              left: width * 0.22,
              bottom: height * 0.28,
              child: Opacity(
                opacity: kidsIn,
                child: Text('🧒', style: TextStyle(fontSize: compact ? 28 : 36)),
              ),
            ),
            Positioned(
              left: width * 0.32,
              bottom: height * 0.26,
              child: Opacity(
                opacity: kidsIn,
                child: Text('👧', style: TextStyle(fontSize: compact ? 28 : 36)),
              ),
            ),
          ],
          if (familiesIn > 0) ...<Widget>[
            Positioned(
              right: width * 0.18,
              bottom: height * 0.24,
              child: Opacity(
                opacity: familiesIn,
                child: Text(
                  '👨‍👩‍👧',
                  style: TextStyle(fontSize: compact ? 26 : 34),
                ),
              ),
            ),
            Positioned(
              right: width * 0.32,
              bottom: height * 0.22,
              child: Opacity(
                opacity: familiesIn,
                child: Text(
                  '🚶',
                  style: TextStyle(fontSize: compact ? 24 : 30),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClapOverlay extends StatelessWidget {
  const _ClapOverlay({
    required this.progress,
    required this.compact,
    required this.width,
    required this.height,
  });

  final double progress;
  final bool compact;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: List<Widget>.generate(7, (int i) {
          final double angle = i * 0.9;
          final double pulse =
              0.85 + 0.15 * math.sin(progress * math.pi * 4 + i);
          return Positioned(
            left: width * 0.5 + math.cos(angle) * width * 0.28 - 12,
            top: height * 0.55 + math.sin(angle) * height * 0.12,
            child: Opacity(
              opacity: progress.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: pulse,
                child: Text(
                  '👏',
                  style: TextStyle(fontSize: compact ? 22 : 28),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RewardLine extends StatelessWidget {
  const _RewardLine({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.compact,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: color, size: compact ? 20 : 24),
        SizedBox(width: compact ? 8 : 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Jersey10',
              fontSize: compact ? 18 : 22,
              color: const Color(0xFFB0BEC5),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Jersey10',
            fontSize: compact ? 18 : 22,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
