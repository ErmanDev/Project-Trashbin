import 'package:flutter/material.dart';

import '../models/game_progress.dart';
import '../models/town_location.dart';
import '../services/audio_manager.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/mobile_mayor_dialogue_stack.dart';
import '../widgets/pixel_button.dart';

enum TownCenterCelebrationPhase {
  panning,
  progress,
  mayor,
  unlock,
  done,
}

/// Post–Level-9 celebration: pan to Town Center → plaza progress → Mayor → Level 10.
class TownCenterCelebrationOverlay extends StatefulWidget {
  const TownCenterCelebrationOverlay({
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
  State<TownCenterCelebrationOverlay> createState() =>
      _TownCenterCelebrationOverlayState();
}

class _TownCenterCelebrationOverlayState
    extends State<TownCenterCelebrationOverlay>
    with TickerProviderStateMixin {
  static const Color _accent = Color(0xFF3949AB);
  static const String _mayorLine = 'The town is almost restored.';

  TownCenterCelebrationPhase _phase = TownCenterCelebrationPhase.panning;
  String _mayorText = '';
  bool _mayorTyping = false;

  late final AnimationController _pan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5600),
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

  Offset get _townCenterMapOffset {
    final TownLocation town = TownLocation.all.firstWhere(
      (TownLocation l) => l.id == 'town_center',
    );
    final double x = (town.position.x + 1) / 2 * widget.mapSize.width;
    final double y = (town.position.y + 1) / 2 * widget.mapSize.height;
    return Offset(x, y);
  }

  bool get _showMapProgress =>
      _phase == TownCenterCelebrationPhase.progress ||
      (_phase == TownCenterCelebrationPhase.mayor && _cinematicIn.value < 1);

  bool get _showCinematic =>
      _phase.index >= TownCenterCelebrationPhase.mayor.index;

  double get _cinematicOpacity {
    if (_phase.index > TownCenterCelebrationPhase.mayor.index) return 1;
    if (_phase == TownCenterCelebrationPhase.mayor) {
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
        setState(() => _phase = TownCenterCelebrationPhase.progress);
        _progress.forward();
      }
    });
    _progress.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed && mounted) {
        _beginMayor();
      }
    });

    _pan.forward();
  }

  void _beginMayor() {
    setState(() => _phase = TownCenterCelebrationPhase.mayor);
    _cinematicIn.forward();
    _castIn.forward();
    _typeMayorLine();
  }

  Matrix4 _computeCenterTransform() {
    final Offset node = _townCenterMapOffset;
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

  void _typeMayorLine() {
    setState(() {
      _mayorText = '';
      _mayorTyping = true;
    });
    int i = 0;
    Future<void>.delayed(const Duration(milliseconds: 40), () async {
      while (i <= _mayorLine.length && mounted) {
        setState(() => _mayorText = _mayorLine.substring(0, i));
        i++;
        await Future<void>.delayed(const Duration(milliseconds: 28));
      }
      if (mounted) setState(() => _mayorTyping = false);
    });
  }

  void _onTap() {
    switch (_phase) {
      case TownCenterCelebrationPhase.mayor:
        if (_mayorTyping) {
          setState(() {
            _mayorText = _mayorLine;
            _mayorTyping = false;
          });
        } else {
          setState(() => _phase = TownCenterCelebrationPhase.unlock);
          AudioManager.instance.playApplause();
        }
      case TownCenterCelebrationPhase.unlock:
        setState(() => _phase = TownCenterCelebrationPhase.done);
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

  Offset _townCenterScreenPosition() {
    final Offset node = _townCenterMapOffset;
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
    final Offset center = _townCenterScreenPosition();

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (_phase == TownCenterCelebrationPhase.panning)
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
                final double p = _phase == TownCenterCelebrationPhase.progress
                    ? _progress.value
                    : 1.0;
                return _TownCenterMapProgress(
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
          GameProgress.townCenterCleanBg,
          fit: BoxFit.cover,
          width: width,
          height: height,
          filterQuality: FilterQuality.none,
        ),
        ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
        if (_phase == TownCenterCelebrationPhase.mayor)
          _buildMayor(compact: compact, width: width, height: height),
        if (_phase == TownCenterCelebrationPhase.unlock) ...<Widget>[
          const Positioned.fill(child: ConfettiOverlay()),
          _buildUnlockBanner(compact),
        ],
      ],
    );
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
            text: _mayorText,
            mayorIn: _castIn,
            mayorAccent: _accent,
            showContinueHint: !_mayorTyping,
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
          child: Image.asset(
            GameProgress.mayorCutout,
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
              text: _mayorText,
              speakerName: 'Mayor',
              accent: _accent,
              showContinueHint: !_mayorTyping,
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
            border: Border.all(color: const Color(0xFF5C6BC0), width: 5),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF5C6BC0).withValues(alpha: 0.35),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.location_city,
                color: const Color(0xFF5C6BC0),
                size: compact ? 36 : 56,
              ),
              SizedBox(height: compact ? 6 : 12),
              Text(
                'Level 10 Unlocked!',
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
                "Green Town's Final Challenge awaits",
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
                  label: 'Begin Level 10',
                  icon: Icons.flag,
                  color: const Color(0xFF5C6BC0),
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

class _TownCenterMapProgress extends StatelessWidget {
  const _TownCenterMapProgress({
    required this.progress,
    required this.center,
    required this.compact,
  });

  final double progress;
  final Offset center;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double greenIn = Curves.easeOut.transform(
      ((progress - 0.12) / 0.2).clamp(0.0, 1.0),
    );
    final double captionIn = Curves.easeOut.transform(
      ((progress - 0.88) / 0.12).clamp(0.0, 1.0),
    );
    final double glowR = compact ? 90.0 : 120.0;

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          if (greenIn > 0)
            Positioned(
              left: center.dx - glowR,
              top: center.dy - glowR,
              width: glowR * 2,
              height: glowR * 2,
              child: Opacity(
                opacity: greenIn * 0.85,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        Color(0xCC66BB6A),
                        Color(0x0066BB6A),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (captionIn > 0)
            Positioned(
              left: 0,
              right: 0,
              top: center.dy - (compact ? 78 : 98),
              child: Opacity(
                opacity: captionIn,
                child: Text(
                  'Town Center Progress',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Jersey10',
                    fontSize: compact ? 16 : 22,
                    color: const Color(0xFFC5CAE9),
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
