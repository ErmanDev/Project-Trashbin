import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_progress.dart';
import '../models/town_location.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/pixel_button.dart';

enum BeachCelebrationPhase {
  panning,
  progress,
  ranger,
  unlock,
  done,
}

/// Post–Level-7 celebration: pan to Beach → shoreline cleanup → Ranger → Level 8.
class BeachCelebrationOverlay extends StatefulWidget {
  const BeachCelebrationOverlay({
    super.key,
    required this.mapTransform,
    required this.mapSize,
    required this.viewSize,
    required this.maxPanX,
    required this.maxPanY,
    required this.onFinished,
  });

  final TransformationController mapTransform;
  final Size mapSize;
  final Size viewSize;
  final double maxPanX;
  final double maxPanY;
  final VoidCallback onFinished;

  @override
  State<BeachCelebrationOverlay> createState() =>
      _BeachCelebrationOverlayState();
}

class _BeachCelebrationOverlayState extends State<BeachCelebrationOverlay>
    with TickerProviderStateMixin {
  static const Color _accent = Color(0xFF00838F);
  static const String _rangerLine =
      'Every piece of trash removed gives nature another chance.';

  BeachCelebrationPhase _phase = BeachCelebrationPhase.panning;
  String _rangerText = '';
  bool _rangerTyping = false;

  late final AnimationController _pan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  );
  late final AnimationController _cinematicIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final AnimationController _castIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  late final Matrix4 _startTransform;
  late final Matrix4 _targetTransform;

  Offset get _beachMapOffset {
    final TownLocation beach = TownLocation.all.firstWhere(
      (TownLocation l) => l.id == 'beach',
    );
    final double x = (beach.position.x + 1) / 2 * widget.mapSize.width;
    final double y = (beach.position.y + 1) / 2 * widget.mapSize.height;
    return Offset(x, y);
  }

  bool get _showMapProgress =>
      _phase == BeachCelebrationPhase.progress ||
      (_phase == BeachCelebrationPhase.ranger && _cinematicIn.value < 1);

  bool get _showCinematic =>
      _phase.index >= BeachCelebrationPhase.ranger.index;

  double get _cinematicOpacity {
    if (_phase.index > BeachCelebrationPhase.ranger.index) return 1;
    if (_phase == BeachCelebrationPhase.ranger) {
      return Curves.easeInOut.transform(_cinematicIn.value);
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _startTransform = widget.mapTransform.value.clone();
    _targetTransform = _computeCenterTransform();

    _pan.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _phase = BeachCelebrationPhase.progress);
        _progress.forward();
      }
    });
    _progress.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed && mounted) {
        _beginRanger();
      }
    });

    _pan.forward();
  }

  void _beginRanger() {
    setState(() => _phase = BeachCelebrationPhase.ranger);
    _cinematicIn.forward();
    _castIn.forward();
    _typeRangerLine();
  }

  Matrix4 _computeCenterTransform() {
    final Offset node = _beachMapOffset;
    double tx = widget.viewSize.width / 2 - node.dx;
    double ty = widget.viewSize.height / 2 - node.dy;
    tx = tx.clamp(-widget.maxPanX, 0.0);
    ty = ty.clamp(-widget.maxPanY, 0.0);
    return Matrix4.translationValues(tx, ty, 0);
  }

  void _updatePanTransform() {
    final double t = Curves.easeInOut.transform(_pan.value);
    final double sx = _startTransform.getTranslation().x;
    final double sy = _startTransform.getTranslation().y;
    final double ex = _targetTransform.getTranslation().x;
    final double ey = _targetTransform.getTranslation().y;
    widget.mapTransform.value = Matrix4.translationValues(
      sx + (ex - sx) * t,
      sy + (ey - sy) * t,
      0,
    );
  }

  void _typeRangerLine() {
    setState(() {
      _rangerText = '';
      _rangerTyping = true;
    });
    int i = 0;
    Future<void>.delayed(const Duration(milliseconds: 40), () async {
      while (i <= _rangerLine.length && mounted) {
        setState(() => _rangerText = _rangerLine.substring(0, i));
        i++;
        await Future<void>.delayed(const Duration(milliseconds: 28));
      }
      if (mounted) setState(() => _rangerTyping = false);
    });
  }

  void _onTap() {
    switch (_phase) {
      case BeachCelebrationPhase.ranger:
        if (_rangerTyping) {
          setState(() {
            _rangerText = _rangerLine;
            _rangerTyping = false;
          });
        } else {
          setState(() => _phase = BeachCelebrationPhase.unlock);
        }
      case BeachCelebrationPhase.unlock:
        setState(() => _phase = BeachCelebrationPhase.done);
        widget.onFinished();
      default:
        break;
    }
  }

  @override
  void dispose() {
    _pan.dispose();
    _progress.dispose();
    _cinematicIn.dispose();
    _castIn.dispose();
    super.dispose();
  }

  Offset _beachScreenPosition() {
    final Offset node = _beachMapOffset;
    final Matrix4 m = widget.mapTransform.value;
    return Offset(
      node.dx + m.getTranslation().x,
      node.dy + m.getTranslation().y,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = widget.viewSize.height < 420;
    final double w = widget.viewSize.width;
    final double h = widget.viewSize.height;
    final Offset center = _beachScreenPosition();

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (_phase == BeachCelebrationPhase.panning)
            AnimatedBuilder(
              animation: _pan,
              builder: (BuildContext context, _) {
                _updatePanTransform();
                return const SizedBox.shrink();
              },
            ),
          if (_showMapProgress)
            AnimatedBuilder(
              animation:
                  Listenable.merge(<Listenable>[_progress, _cinematicIn]),
              builder: (BuildContext context, _) {
                final double p = _phase == BeachCelebrationPhase.progress
                    ? _progress.value
                    : 1.0;
                return _BeachMapProgress(
                  progress: p,
                  center: center,
                  compact: compact,
                );
              },
            ),
          if (_showCinematic && _cinematicOpacity > 0)
            Positioned.fill(
              child: Opacity(
                opacity: _cinematicOpacity,
                child: _buildCinematic(compact: compact, width: w, height: h),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCinematic({
    required bool compact,
    required double width,
    required double height,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.asset(
          GameProgress.beachCleanBg,
          fit: BoxFit.cover,
          width: width,
          height: height,
          filterQuality: FilterQuality.none,
        ),
        ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
        if (_phase == BeachCelebrationPhase.ranger)
          _buildRanger(compact: compact, width: width, height: height),
        if (_phase == BeachCelebrationPhase.unlock) ...<Widget>[
          const Positioned.fill(child: ConfettiOverlay()),
          _buildUnlockBanner(compact),
        ],
      ],
    );
  }

  Widget _buildRanger({
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
          child: _MobileRangerStack(
            width: width,
            text: _rangerText,
            castIn: _castIn,
            showContinueHint: !_rangerTyping,
          ),
        ),
      );
    }

    return Stack(
      children: <Widget>[
        AnimatedBuilder(
          animation: _castIn,
          builder: (BuildContext context, Widget? child) {
            final double t = Curves.easeOut.transform(_castIn.value);
            return Positioned(
              bottom: 0 - (1 - t) * 40,
              left: width * 0.05,
              height: height * 0.72,
              child: Opacity(opacity: t, child: child),
            );
          },
          child: Transform.flip(
            flipX: true,
            child: Image.asset(
              GameProgress.rangerCutout,
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
              text: _rangerText,
              speakerName: 'Marine Ranger',
              accent: _accent,
              showContinueHint: !_rangerTyping,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnlockBanner(bool compact) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 40),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 32,
            vertical: compact ? 12 : 26,
          ),
          decoration: BoxDecoration(
            color: const Color(0xF00E0E1A),
            border: Border.all(color: const Color(0xFF29B6F6), width: 5),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF29B6F6).withValues(alpha: 0.35),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.waves,
                color: const Color(0xFF29B6F6),
                size: compact ? 36 : 56,
              ),
              SizedBox(height: compact ? 6 : 12),
              Text(
                'Level 8 Unlocked!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Jersey10',
                  fontSize: compact ? 28 : 44,
                  height: 1,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: compact ? 6 : 10),
              Text(
                'Beach Level 8 is ready',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Jersey10',
                  fontSize: compact ? 16 : 22,
                  height: 1,
                  color: const Color(0xFFB0BEC5),
                ),
              ),
              SizedBox(height: compact ? 8 : 14),
              Center(
                child: PixelButton(
                  label: 'Continue',
                  icon: Icons.map,
                  color: const Color(0xFF29B6F6),
                  width: null,
                  compact: true,
                  onPressed: _onTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileRangerStack extends StatelessWidget {
  const _MobileRangerStack({
    required this.width,
    required this.text,
    required this.castIn,
    required this.showContinueHint,
  });

  final double width;
  final String text;
  final Animation<double> castIn;
  final bool showContinueHint;

  @override
  Widget build(BuildContext context) {
    const double textPanelMinH = 96;
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
                    child: Transform.flip(flipX: true, child: child),
                  ),
                ),
              ),
            );
          },
          child: Image.asset(
            GameProgress.rangerCutout,
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
            accent: const Color(0xFF00838F),
            showContinueHint: showContinueHint,
            showSpeakerName: false,
          ),
        ),
        const Positioned(
          left: 0,
          bottom: textPanelMinH,
          child: SpeakerNameTag(
            name: 'Marine Ranger',
            accent: Color(0xFF00838F),
            compact: true,
          ),
        ),
      ],
    );
  }
}

class _BeachMapProgress extends StatelessWidget {
  const _BeachMapProgress({
    required this.progress,
    required this.center,
    required this.compact,
  });

  final double progress;
  final Offset center;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double trashOut = (1 - (progress / 0.2)).clamp(0.0, 1.0);
    final double sandIn = Curves.easeOut.transform(
      ((progress - 0.15) / 0.2).clamp(0.0, 1.0),
    );
    final double turtleIn = Curves.elasticOut.transform(
      ((progress - 0.4) / 0.25).clamp(0.0, 1.0),
    );
    final double birdsIn = Curves.easeOut.transform(
      ((progress - 0.65) / 0.25).clamp(0.0, 1.0),
    );
    final double smileIn = Curves.easeOut.transform(
      ((progress - 0.85) / 0.15).clamp(0.0, 1.0),
    );

    final double glowR = compact ? 90.0 : 120.0;

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          if (sandIn > 0)
            Positioned(
              left: center.dx - glowR,
              top: center.dy - glowR,
              width: glowR * 2,
              height: glowR * 2,
              child: Opacity(
                opacity: sandIn * 0.8,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        Color(0xCC81D4FA),
                        Color(0x0081D4FA),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (trashOut > 0)
            ...List<Widget>.generate(6, (int i) {
              final double ang = i * (math.pi * 2 / 6);
              return Positioned(
                left: center.dx + math.cos(ang) * 40 - 10,
                top: center.dy + math.sin(ang) * 28 - 10,
                child: Opacity(
                  opacity: trashOut,
                  child: Icon(
                    Icons.delete_outline,
                    color: const Color(0xFF8D6E63),
                    size: compact ? 18 : 24,
                  ),
                ),
              );
            }),
          if (turtleIn > 0)
            Positioned(
              left: center.dx - (compact ? 18 : 24),
              top: center.dy + 8,
              child: Transform.scale(
                scale: turtleIn,
                child: Text(
                  '🐢',
                  style: TextStyle(fontSize: compact ? 28 : 36),
                ),
              ),
            ),
          if (birdsIn > 0)
            ...List<Widget>.generate(4, (int i) {
              return Positioned(
                left: center.dx - 50 + i * 28.0 + birdsIn * 10,
                top: center.dy - 55 - (i % 2) * 12.0,
                child: Opacity(
                  opacity: birdsIn,
                  child: Text(
                    '🐦',
                    style: TextStyle(fontSize: compact ? 16 : 20),
                  ),
                ),
              );
            }),
          if (smileIn > 0)
            Positioned(
              left: 0,
              right: 0,
              top: center.dy - (compact ? 70 : 90),
              child: Opacity(
                opacity: smileIn,
                child: Text(
                  'The cleanup begins...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Jersey10',
                    fontSize: compact ? 16 : 22,
                    color: const Color(0xFFB3E5FC),
                    shadows: const <Shadow>[
                      Shadow(color: Colors.black, offset: Offset(1, 1)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
