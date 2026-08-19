import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_character.dart';
import '../models/game_progress.dart';
import '../services/audio_manager.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/mobile_mayor_dialogue_stack.dart';
import '../widgets/pixel_button.dart';
import 'town_final_rewards_screen.dart';

enum _CeremonyPhase {
  stage,
  dialogue,
  medal,
  banner,
  cheer,
}

/// Final ceremony after the Green Town restoration flyover.
class TownFinalCeremonyScreen extends StatefulWidget {
  const TownFinalCeremonyScreen({
    super.key,
    required this.character,
  });

  final GameCharacter character;

  @override
  State<TownFinalCeremonyScreen> createState() =>
      _TownFinalCeremonyScreenState();
}

class _TownFinalCeremonyScreenState extends State<TownFinalCeremonyScreen>
    with TickerProviderStateMixin {
  static const Color _mayorAccent = Color(0xFF3949AB);
  static const Color _gold = Color(0xFFFFD54F);

  static const List<String> _lines = <String>[
    "Today isn't just about cleaning a town.",
    "It's about protecting our future.",
    'For your dedication, leadership, and commitment to protecting the environment...',
    'We proudly recognize you as...',
  ];

  static const Duration _charTick = Duration(milliseconds: 28);
  static const Duration _pause = Duration(milliseconds: 900);

  static const List<Color> _goldPalette = <Color>[
    Color(0xFFFFD54F),
    Color(0xFFFFC107),
    Color(0xFFFFECB3),
    Color(0xFFFFF176),
    Color(0xFFFFB300),
    Color(0xFFFFE082),
  ];

  _CeremonyPhase _phase = _CeremonyPhase.stage;
  int _lineIndex = -1;
  String _shownText = '';
  bool _typing = false;

  Timer? _typeTimer;
  Timer? _pauseTimer;

  late final AnimationController _stageIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  late final AnimationController _mayorIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final AnimationController _medalIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _bannerIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _fireworks = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );

  @override
  void initState() {
    super.initState();
    _stageIn.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _phase = _CeremonyPhase.dialogue);
        _mayorIn.forward();
        _advanceLine();
      }
    });
    _stageIn.forward();
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _pauseTimer?.cancel();
    _stageIn.dispose();
    _mayorIn.dispose();
    _medalIn.dispose();
    _bannerIn.dispose();
    _fireworks.dispose();
    super.dispose();
  }

  void _advanceLine() {
    if (!mounted) return;
    final int next = _lineIndex + 1;

    // After the second line, present the medal before continuing.
    if (next == 2 && _phase == _CeremonyPhase.dialogue) {
      setState(() => _phase = _CeremonyPhase.medal);
      _medalIn.forward(from: 0);
      _pauseTimer = Timer(const Duration(milliseconds: 1600), () {
        if (!mounted) return;
        setState(() => _phase = _CeremonyPhase.dialogue);
        _mayorIn.forward(from: 0);
        setState(() => _lineIndex = next);
        _typeLine(_lines[next]);
      });
      return;
    }

    if (next >= _lines.length) {
      _showBanner();
      return;
    }

    setState(() => _lineIndex = next);
    if (next > 0 && next != 2) {
      _mayorIn.forward(from: 0);
    }
    _typeLine(_lines[next]);
  }

  void _typeLine(String full) {
    _typeTimer?.cancel();
    setState(() {
      _shownText = '';
      _typing = true;
    });
    int i = 0;
    _typeTimer = Timer.periodic(_charTick, (Timer t) {
      if (i >= full.length) {
        t.cancel();
        setState(() => _typing = false);
        _pauseTimer = Timer(_pause, _advanceLine);
        return;
      }
      i++;
      setState(() => _shownText = full.substring(0, i));
    });
  }

  Future<void> _showBanner() async {
    if (!mounted) return;
    setState(() => _phase = _CeremonyPhase.banner);
    AudioManager.instance.playApplause();
    _bannerIn.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _phase = _CeremonyPhase.cheer);
    _fireworks.repeat();
  }

  void _onTap() {
    switch (_phase) {
      case _CeremonyPhase.dialogue:
        if (_lineIndex < 0) return;
        if (_typing) {
          _typeTimer?.cancel();
          _pauseTimer?.cancel();
          setState(() {
            _shownText = _lines[_lineIndex];
            _typing = false;
          });
          _pauseTimer = Timer(_pause, _advanceLine);
        } else {
          _pauseTimer?.cancel();
          _advanceLine();
        }
      case _CeremonyPhase.medal:
        break;
      case _CeremonyPhase.banner:
        setState(() => _phase = _CeremonyPhase.cheer);
        _fireworks.repeat();
      case _CeremonyPhase.cheer:
        _goToRewards();
      default:
        break;
    }
  }

  void _goToRewards() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const TownFinalRewardsScreen(),
      ),
    );
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
                Image.asset(
                  GameProgress.townCenterCleanBg,
                  fit: BoxFit.cover,
                  width: w,
                  height: h,
                  filterQuality: FilterQuality.none,
                ),
                ColoredBox(color: Colors.black.withValues(alpha: 0.38)),
                AnimatedBuilder(
                  animation: _stageIn,
                  builder: (BuildContext context, _) {
                    return _StageCast(
                      progress: _stageIn.value,
                      compact: compact,
                      width: w,
                      height: h,
                      playerCutout: widget.character.cutoutAsset,
                      showMayor: _phase == _CeremonyPhase.stage ||
                          _phase == _CeremonyPhase.medal ||
                          (_phase == _CeremonyPhase.dialogue && !compact),
                    );
                  },
                ),
                if (_phase == _CeremonyPhase.stage)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: compact ? 12 : 20,
                    child: SafeArea(
                      bottom: false,
                      child: Center(
                        child: _CeremonyCaption(
                          text: 'The Mayor walks onto a small stage.',
                          compact: compact,
                        ),
                      ),
                    ),
                  ),
                if (_phase == _CeremonyPhase.dialogue && _lineIndex >= 0)
                  _buildMayorDialogue(compact: compact, width: w, height: h),
                if (_phase == _CeremonyPhase.medal)
                  _buildMedalPresentation(compact: compact),
                if (_phase == _CeremonyPhase.banner ||
                    _phase == _CeremonyPhase.cheer)
                  _buildHeroBanner(compact: compact),
                if (_phase == _CeremonyPhase.cheer) ...<Widget>[
                  const Positioned.fill(
                    child: ConfettiOverlay(
                      particleCount: 160,
                      duration: Duration(milliseconds: 6000),
                      colors: _goldPalette,
                    ),
                  ),
                  Positioned.fill(
                    child: _CeremonyFireworks(controller: _fireworks),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: compact ? 14 : 24,
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _CeremonyCaption(
                            text: 'The crowd cheers.',
                            compact: compact,
                          ),
                          SizedBox(height: compact ? 10 : 14),
                          PixelButton(
                            label: 'Continue',
                            icon: Icons.card_giftcard,
                            color: _gold,
                            width: null,
                            compact: compact,
                            onPressed: _goToRewards,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMayorDialogue({
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

    return Positioned(
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
    );
  }

  Widget _buildMedalPresentation({required bool compact}) {
    return Center(
      child: AnimatedBuilder(
        animation: _medalIn,
        builder: (BuildContext context, _) {
          final double t = Curves.elasticOut.transform(_medalIn.value);
          return Opacity(
            opacity: _medalIn.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.6 + t * 0.4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.workspace_premium,
                    color: _gold,
                    size: compact ? 72 : 110,
                  ),
                  SizedBox(height: compact ? 8 : 12),
                  _CeremonyCaption(
                    text: 'The Mayor presents a golden medal.',
                    compact: compact,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroBanner({required bool compact}) {
    return Center(
      child: AnimatedBuilder(
        animation: _bannerIn,
        builder: (BuildContext context, _) {
          final double t = Curves.elasticOut.transform(
            _bannerIn.value.clamp(0.0, 1.0),
          );
          return Opacity(
            opacity: _bannerIn.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.7 + t * 0.3,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: compact ? 16 : 40),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 18 : 36,
                  vertical: compact ? 14 : 26,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xF00E0E1A),
                  border: Border.all(color: _gold, width: 5),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: _gold.withValues(alpha: 0.45),
                      blurRadius: 28,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.emoji_events,
                      color: _gold,
                      size: compact ? 36 : 56,
                    ),
                    SizedBox(height: compact ? 6 : 10),
                    Text(
                      'RECYCLING HERO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Jersey10',
                        fontSize: compact ? 28 : 44,
                        height: 1,
                        color: _gold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CeremonyCaption extends StatelessWidget {
  const _CeremonyCaption({required this.text, required this.compact});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: compact ? 16 : 40),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 18,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xE00E0E1A),
        border: Border.all(color: const Color(0xFFFFD54F), width: 3),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Jersey10',
          fontSize: compact ? 15 : 20,
          height: 1.1,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _StageCast extends StatelessWidget {
  const _StageCast({
    required this.progress,
    required this.compact,
    required this.width,
    required this.height,
    required this.playerCutout,
    required this.showMayor,
  });

  final double progress;
  final bool compact;
  final double width;
  final double height;
  final String playerCutout;
  final bool showMayor;

  @override
  Widget build(BuildContext context) {
    final double castH = compact ? height * 0.38 : height * 0.52;
    final double mayorT = Curves.easeOut.transform(
      ((progress - 0.05) / 0.35).clamp(0.0, 1.0),
    );
    final double supportT = Curves.easeOut.transform(
      ((progress - 0.25) / 0.35).clamp(0.0, 1.0),
    );
    final double playerT = Curves.easeOut.transform(
      ((progress - 0.5) / 0.4).clamp(0.0, 1.0),
    );

    final List<({String asset, bool flipX})> support =
        <({String asset, bool flipX})>[
      (asset: GameProgress.principalCutout, flipX: false),
      (asset: GameProgress.barangayCutout, flipX: true),
      (asset: GameProgress.rangerCutout, flipX: true),
      (asset: GameProgress.residentCutout, flipX: false),
      (asset: GameProgress.childCutout, flipX: false),
    ];

    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          // Small stage platform
          if (mayorT > 0)
            Positioned(
              left: width * 0.28,
              right: width * 0.28,
              bottom: compact ? 72 : 96,
              height: compact ? 14 : 20,
              child: Opacity(
                opacity: mayorT,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF5D4037),
                    border: Border(
                      top: BorderSide(color: Color(0xFFFFD54F), width: 3),
                      left: BorderSide(color: Color(0xFF3E2723), width: 2),
                      right: BorderSide(color: Color(0xFF3E2723), width: 2),
                      bottom: BorderSide(color: Color(0xFF3E2723), width: 3),
                    ),
                  ),
                ),
              ),
            ),
          if (showMayor && mayorT > 0)
            Positioned(
              left: width * 0.36,
              bottom: compact ? 82 : 110,
              width: width * 0.28,
              height: castH * 0.85,
              child: Opacity(
                opacity: mayorT,
                child: Transform.translate(
                  offset: Offset(0, (1 - mayorT) * 40),
                  child: Image.asset(
                    GameProgress.mayorCutout,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    filterQuality: FilterQuality.none,
                  ),
                ),
              ),
            ),
          if (supportT > 0)
            ...List<Widget>.generate(support.length, (int i) {
              final ({String asset, bool flipX}) member = support[i];
              final bool leftSide = i < 3;
              final double slot = leftSide ? i.toDouble() : (i - 3).toDouble();
              final double x = leftSide
                  ? width * (0.02 + slot * 0.1)
                  : width * (0.72 + slot * 0.12);
              return Positioned(
                left: x,
                bottom: compact ? 8 : 16,
                width: width * 0.14,
                height: castH * 0.7,
                child: Opacity(
                  opacity: supportT,
                  child: Transform.translate(
                    offset: Offset(0, (1 - supportT) * 30),
                    child: Transform.flip(
                      flipX: member.flipX,
                      child: Image.asset(
                        member.asset,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                ),
              );
            }),
          if (playerT > 0)
            Positioned(
              left: width * 0.42,
              bottom: compact ? 4 : 8,
              width: width * 0.16,
              height: castH * 0.75,
              child: Opacity(
                opacity: playerT,
                child: Transform.translate(
                  offset: Offset(0, (1 - playerT) * 50),
                  child: Image.asset(
                    playerCutout,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    filterQuality: FilterQuality.none,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CeremonyFireworks extends StatelessWidget {
  const _CeremonyFireworks({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, _) {
          final double t = controller.value;
          final Size size = MediaQuery.sizeOf(context);
          final bool compact = size.height < 420;
          return Stack(
            children: List<Widget>.generate(10, (int i) {
              final double burst = (t + i * 0.1) % 1.0;
              final double ang = i * (math.pi * 2 / 10);
              final double radius = burst * (compact ? 80.0 : 120.0);
              final double cx = size.width * (0.15 + (i % 5) * 0.175);
              final double cy = size.height * (0.14 + (i ~/ 5) * 0.1);
              return Positioned(
                left: cx + math.cos(ang) * radius - 12,
                top: cy + math.sin(ang) * radius - 12,
                child: Opacity(
                  opacity: (1 - burst).clamp(0.0, 1.0),
                  child: Icon(
                    i.isEven ? Icons.auto_awesome : Icons.star,
                    color: i.isEven
                        ? const Color(0xFFFFECB3)
                        : const Color(0xFFFFF59D),
                    size: compact ? 18 : 26,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
