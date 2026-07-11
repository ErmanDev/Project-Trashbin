import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_progress.dart';
import '../services/save_manager.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/pixel_button.dart';

enum _Phase { pan, life, dialogue, clap, banner }

class _DialogueBeat {
  const _DialogueBeat({
    required this.speaker,
    required this.line,
    required this.asset,
    required this.accent,
  });

  final String speaker;
  final String line;
  final String asset;
  final Color accent;
}

/// Full beach restoration cutscene after Beach Level 8.
class BeachFullyRestoredScreen extends StatefulWidget {
  const BeachFullyRestoredScreen({super.key});

  @override
  State<BeachFullyRestoredScreen> createState() =>
      _BeachFullyRestoredScreenState();
}

class _BeachFullyRestoredScreenState extends State<BeachFullyRestoredScreen>
    with TickerProviderStateMixin {
  static const Color _rangerAccent = Color(0xFF00838F);
  static const Color _mayorAccent = Color(0xFF3949AB);
  static const Color _border = Color(0xFF2B2B3A);

  static const List<_DialogueBeat> _beats = <_DialogueBeat>[
    _DialogueBeat(
      speaker: 'Marine Ranger',
      line: 'Because of your efforts, marine life has a safer home.',
      asset: GameProgress.rangerCutout,
      accent: _rangerAccent,
    ),
    _DialogueBeat(
      speaker: 'Mayor',
      line: "You've restored another important part of Green Town.",
      asset: GameProgress.mayorCutout,
      accent: _mayorAccent,
    ),
  ];

  static const Duration _charTick = Duration(milliseconds: 28);
  static const Duration _pauseBetweenLines = Duration(milliseconds: 900);

  _Phase _phase = _Phase.pan;
  int _beatIndex = -1;
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
    duration: const Duration(milliseconds: 5200),
  );
  late final AnimationController _castIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
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
        setState(() => _phase = _Phase.life);
        _life.forward();
      }
    });
    _life.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _phase = _Phase.dialogue);
        _castIn.forward(from: 0);
        _advanceBeat();
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
    _castIn.dispose();
    _clap.dispose();
    super.dispose();
  }

  void _advanceBeat() {
    if (!mounted) return;
    final int next = _beatIndex + 1;
    if (next >= _beats.length) {
      setState(() => _phase = _Phase.clap);
      _clap.forward().whenComplete(() {
        if (mounted) _showBanner();
      });
      return;
    }
    setState(() => _beatIndex = next);
    if (next > 0) {
      _castIn.forward(from: 0);
    }
    _typeLine(_beats[next].line);
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
        _pauseTimer = Timer(_pauseBetweenLines, _advanceBeat);
        return;
      }
      shown++;
      setState(() => _shownText = full.substring(0, shown));
    });
  }

  Future<void> _showBanner() async {
    if (!_rewardsSaved) {
      _rewardsSaved = true;
      await SaveManager.instance.completeBeachLevel8(coinsEarned: 0);
    }
    if (!mounted) return;
    setState(() => _phase = _Phase.banner);
  }

  void _onTap() {
    switch (_phase) {
      case _Phase.dialogue:
        if (_beatIndex < 0) return;
        if (_typing) {
          _typeTimer?.cancel();
          _pauseTimer?.cancel();
          setState(() {
            _shownText = _beats[_beatIndex].line;
            _typing = false;
          });
          _pauseTimer = Timer(_pauseBetweenLines, _advanceBeat);
        } else {
          _pauseTimer?.cancel();
          _advanceBeat();
        }
      case _Phase.clap:
        _clap.stop();
        _showBanner();
      case _Phase.banner:
        _finish();
      default:
        break;
    }
  }

  void _finish() {
    Navigator.of(context).pop();
  }

  String _lifeCaption(double t) {
    if (t < 0.12) return 'The water is crystal clear...';
    if (t < 0.24) return 'The sand is spotless!';
    if (t < 0.36) return 'Palm trees sway in the breeze!';
    if (t < 0.50) return 'Sea turtles safely crawl across the beach!';
    if (t < 0.62) return 'Fish swim in the shallow water!';
    if (t < 0.76) return 'Families enjoy the shoreline!';
    if (t < 0.88) return 'Volunteers keep the beach clean!';
    return 'Green Beach is alive again!';
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
                          GameProgress.beachCleanBg,
                          fit: BoxFit.cover,
                          width: w,
                          height: h,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                    );
                  },
                ),
                if (_phase.index >= _Phase.life.index)
                  AnimatedBuilder(
                    animation: _life,
                    builder: (BuildContext context, _) {
                      return _ShoreLifeOverlay(
                        progress: _phase.index > _Phase.life.index
                            ? 1.0
                            : _life.value,
                        compact: compact,
                        width: w,
                        height: h,
                      );
                    },
                  ),
                if (_phase == _Phase.pan || _phase == _Phase.life)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: compact ? 10 : 18,
                    child: SafeArea(
                      bottom: false,
                      child: Center(
                        child: _CaptionChip(
                          text: _phase == _Phase.pan
                              ? 'A celebration begins...'
                              : _lifeCaption(_life.value),
                          compact: compact,
                        ),
                      ),
                    ),
                  ),
                if (_phase == _Phase.dialogue && _beatIndex >= 0)
                  _buildSpeaker(compact: compact, width: w, height: h),
                if (_phase == _Phase.clap || _phase == _Phase.banner)
                  AnimatedBuilder(
                    animation: _clap,
                    builder: (BuildContext context, _) {
                      return _ClapOverlay(
                        progress:
                            _phase == _Phase.banner ? 1.0 : _clap.value,
                        compact: compact,
                        width: w,
                        height: h,
                      );
                    },
                  ),
                if (_phase == _Phase.banner) ...<Widget>[
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

  Widget _buildSpeaker({
    required bool compact,
    required double width,
    required double height,
  }) {
    final _DialogueBeat beat = _beats[_beatIndex];
    final bool flipRanger = beat.asset == GameProgress.rangerCutout;

    if (compact) {
      return Positioned(
        left: 10,
        right: 10,
        bottom: 10,
        child: SafeArea(
          top: false,
          child: _MobileSpeakerStack(
            width: width,
            text: _shownText,
            castIn: _castIn,
            speakerName: beat.speaker,
            asset: beat.asset,
            accent: beat.accent,
            flipX: flipRanger,
            showContinueHint: !_typing,
          ),
        ),
      );
    }

    final double spriteHeight = height * 0.72;
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
        ),
        AnimatedBuilder(
          animation: _castIn,
          builder: (BuildContext context, Widget? child) {
            final double t = Curves.easeOut.transform(_castIn.value);
            return Positioned(
              bottom: 0 - (1 - t) * 36,
              left: width * 0.05,
              height: spriteHeight,
              child: Opacity(opacity: t, child: child),
            );
          },
          child: Transform.flip(
            flipX: flipRanger,
            child: Image.asset(
              beat.asset,
              filterQuality: FilterQuality.none,
            ),
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
              speakerName: beat.speaker,
              accent: beat.accent,
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
            border: Border.all(color: const Color(0xFF29B6F6), width: 5),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF29B6F6).withValues(alpha: 0.4),
                blurRadius: 22,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '🏖️ Beach Restored!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Jersey10',
                  fontSize: compact ? 30 : 44,
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
                value: '+${GameProgress.beachFullyRestoredBonusCoins}',
                compact: compact,
              ),
              SizedBox(height: compact ? 6 : 8),
              _RewardLine(
                icon: Icons.pets,
                color: const Color(0xFF26A69A),
                label: 'Cosmetic Unlock',
                value: GameProgress.seaTurtlePetName,
                compact: compact,
              ),
              SizedBox(height: compact ? 6 : 8),
              _RewardLine(
                icon: Icons.star,
                color: const Color(0xFFFFCA28),
                label: 'Beach Completion Star',
                value: '★',
                compact: compact,
              ),
              SizedBox(height: compact ? 6 : 8),
              _RewardLine(
                icon: Icons.location_city,
                color: const Color(0xFF7E57C2),
                label: 'Town Center',
                value: 'Unlocked!',
                compact: compact,
              ),
              SizedBox(height: compact ? 14 : 18),
              Center(
                child: PixelButton(
                  label: 'Back to Map',
                  icon: Icons.map,
                  color: const Color(0xFF29B6F6),
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
        border: Border.all(color: const Color(0xFF29B6F6), width: 3),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Jersey10',
          fontSize: compact ? 18 : 24,
          height: 1,
          color: const Color(0xFFB3E5FC),
        ),
      ),
    );
  }
}

class _ShoreLifeOverlay extends StatelessWidget {
  const _ShoreLifeOverlay({
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
    final double waterIn =
        Curves.easeOut.transform((progress / 0.18).clamp(0.0, 1.0));
    final double sandIn =
        Curves.easeOut.transform(((progress - 0.12) / 0.18).clamp(0.0, 1.0));
    final double palmsIn = Curves.elasticOut
        .transform(((progress - 0.28) / 0.18).clamp(0.0, 1.0));
    final double turtleIn =
        Curves.easeOut.transform(((progress - 0.42) / 0.18).clamp(0.0, 1.0));
    final double fishIn =
        Curves.easeOut.transform(((progress - 0.55) / 0.15).clamp(0.0, 1.0));
    final double familiesIn =
        Curves.easeOut.transform(((progress - 0.68) / 0.18).clamp(0.0, 1.0));
    final double volunteersIn =
        Curves.easeOut.transform(((progress - 0.82) / 0.18).clamp(0.0, 1.0));

    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          if (waterIn > 0)
            Positioned.fill(
              child: Opacity(
                opacity: waterIn * 0.3,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.1,
                      colors: <Color>[
                        Color(0x664FC3F7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (sandIn > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: height * 0.18,
              child: Opacity(
                opacity: sandIn,
                child: Text(
                  '✨  ✨  ✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: compact ? 18 : 24),
                ),
              ),
            ),
          if (palmsIn > 0)
            ...List<Widget>.generate(3, (int i) {
              return Positioned(
                left: width * (0.15 + i * 0.3),
                top: height * 0.22,
                child: Transform.scale(
                  scale: palmsIn,
                  child: Text(
                    '🌴',
                    style: TextStyle(fontSize: compact ? 28 : 36),
                  ),
                ),
              );
            }),
          if (turtleIn > 0)
            Positioned(
              left: width * (0.2 + turtleIn * 0.25),
              bottom: height * 0.26,
              child: Opacity(
                opacity: turtleIn,
                child: Text(
                  '🐢🐢',
                  style: TextStyle(fontSize: compact ? 26 : 34),
                ),
              ),
            ),
          if (fishIn > 0)
            ...List<Widget>.generate(4, (int i) {
              return Positioned(
                left: width * (0.35 + i * 0.12),
                bottom: height * (0.32 + (i % 2) * 0.04),
                child: Opacity(
                  opacity: fishIn,
                  child: Text(
                    '🐟',
                    style: TextStyle(fontSize: compact ? 16 : 22),
                  ),
                ),
              );
            }),
          if (familiesIn > 0)
            Positioned(
              right: width * 0.12,
              bottom: height * 0.24,
              child: Opacity(
                opacity: familiesIn,
                child: Text(
                  '👨‍👩‍👧🏖️',
                  style: TextStyle(fontSize: compact ? 24 : 32),
                ),
              ),
            ),
          if (volunteersIn > 0)
            Positioned(
              left: width * 0.1,
              bottom: height * 0.22,
              child: Opacity(
                opacity: volunteersIn,
                child: Text(
                  '🧹🙋‍♂️',
                  style: TextStyle(fontSize: compact ? 22 : 28),
                ),
              ),
            ),
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
        children: List<Widget>.generate(10, (int i) {
          final double wave =
              (math.sin(progress * math.pi * 4 + i) + 1) / 2;
          return Positioned(
            left: width * (0.08 + (i % 5) * 0.18),
            bottom: height * (0.18 + (i ~/ 5) * 0.12) + wave * 8,
            child: Opacity(
              opacity: progress.clamp(0.0, 1.0),
              child: Text(
                '👏',
                style: TextStyle(fontSize: compact ? 20 : 28),
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
              fontSize: compact ? 16 : 20,
              height: 1,
              color: const Color(0xFFB0BEC5),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Jersey10',
            fontSize: compact ? 16 : 20,
            height: 1,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _MobileSpeakerStack extends StatelessWidget {
  const _MobileSpeakerStack({
    required this.width,
    required this.text,
    required this.castIn,
    required this.speakerName,
    required this.asset,
    required this.accent,
    required this.flipX,
    required this.showContinueHint,
  });

  final double width;
  final String text;
  final Animation<double> castIn;
  final String speakerName;
  final String asset;
  final Color accent;
  final bool flipX;
  final bool showContinueHint;

  static const double textPanelMinH = 96;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomLeft,
      children: <Widget>[
        AnimatedBuilder(
          animation: castIn,
          builder: (BuildContext context, Widget? child) {
            final double t = Curves.easeOut.transform(castIn.value);
            return Positioned(
              left: 0,
              bottom: textPanelMinH - 8,
              width: width * 0.40,
              child: Opacity(
                opacity: t,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.50,
                    child: Transform.flip(flipX: flipX, child: child),
                  ),
                ),
              ),
            );
          },
          child: Image.asset(
            asset,
            width: width * 0.40,
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.none,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 28),
          child: DialogueBox(
            text: text,
            accent: accent,
            showContinueHint: showContinueHint,
            showSpeakerName: false,
          ),
        ),
        Positioned(
          left: 0,
          bottom: textPanelMinH,
          child: SpeakerNameTag(
            name: speakerName,
            accent: accent,
            compact: true,
          ),
        ),
      ],
    );
  }
}
