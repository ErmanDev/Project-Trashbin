import 'package:flutter/material.dart';

import '../models/game_progress.dart';
import '../models/town_location.dart';
import '../services/audio_manager.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/pixel_button.dart';

enum NeighborhoodCelebrationPhase {
  panning,
  progress,
  captain,
  unlock,
  done,
}

/// Post–Level-6 celebration: pan to Neighborhood → street progress → Captain → Beach.
class NeighborhoodCelebrationOverlay extends StatefulWidget {
  const NeighborhoodCelebrationOverlay({
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
  State<NeighborhoodCelebrationOverlay> createState() =>
      _NeighborhoodCelebrationOverlayState();
}

class _NeighborhoodCelebrationOverlayState
    extends State<NeighborhoodCelebrationOverlay>
    with TickerProviderStateMixin {
  static const Color _accent = Color(0xFFEC407A);
  static const String _captainLine =
      'People are beginning to understand that proper waste segregation protects everyone.';

  NeighborhoodCelebrationPhase _phase = NeighborhoodCelebrationPhase.panning;
  String _captainText = '';
  bool _captainTyping = false;

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

  Offset get _neighborhoodMapOffset {
    final TownLocation neighborhood = TownLocation.all.firstWhere(
      (TownLocation l) => l.id == 'neighborhood',
    );
    final double x =
        (neighborhood.position.x + 1) / 2 * widget.mapSize.width;
    final double y =
        (neighborhood.position.y + 1) / 2 * widget.mapSize.height;
    return Offset(x, y);
  }

  bool get _showMapProgress =>
      _phase == NeighborhoodCelebrationPhase.progress ||
      (_phase == NeighborhoodCelebrationPhase.captain &&
          _cinematicIn.value < 1);

  bool get _showCinematic =>
      _phase.index >= NeighborhoodCelebrationPhase.captain.index;

  double get _cinematicOpacity {
    if (_phase.index > NeighborhoodCelebrationPhase.captain.index) return 1;
    if (_phase == NeighborhoodCelebrationPhase.captain) {
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
        setState(() => _phase = NeighborhoodCelebrationPhase.progress);
        _progress.forward();
      }
    });
    _progress.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed && mounted) {
        _beginCaptain();
      }
    });

    _pan.forward();
  }

  void _beginCaptain() {
    setState(() => _phase = NeighborhoodCelebrationPhase.captain);
    _cinematicIn.forward();
    _castIn.forward();
    _typeCaptainLine();
  }

  Matrix4 _computeCenterTransform() {
    final Offset node = _neighborhoodMapOffset;
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

  void _typeCaptainLine() {
    setState(() {
      _captainText = '';
      _captainTyping = true;
    });
    int i = 0;
    Future<void>.delayed(const Duration(milliseconds: 40), () async {
      while (i <= _captainLine.length && mounted) {
        setState(() => _captainText = _captainLine.substring(0, i));
        i++;
        await Future<void>.delayed(const Duration(milliseconds: 28));
      }
      if (mounted) setState(() => _captainTyping = false);
    });
  }

  void _onTap() {
    switch (_phase) {
      case NeighborhoodCelebrationPhase.captain:
        if (_captainTyping) {
          setState(() {
            _captainText = _captainLine;
            _captainTyping = false;
          });
        } else {
          setState(() => _phase = NeighborhoodCelebrationPhase.unlock);
          AudioManager.instance.playApplause();
        }
      case NeighborhoodCelebrationPhase.unlock:
        setState(() => _phase = NeighborhoodCelebrationPhase.done);
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

  Offset _neighborhoodScreenPosition() {
    final Offset node = _neighborhoodMapOffset;
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
    final Offset center = _neighborhoodScreenPosition();

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (_phase == NeighborhoodCelebrationPhase.panning)
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
                final double p = _phase == NeighborhoodCelebrationPhase.progress
                    ? _progress.value
                    : 1.0;
                return _NeighborhoodMapProgress(
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
          GameProgress.neighborhoodCleanBg,
          fit: BoxFit.cover,
          width: width,
          height: height,
          filterQuality: FilterQuality.none,
        ),
        ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
        if (_phase == NeighborhoodCelebrationPhase.captain)
          _buildCaptain(compact: compact, width: width, height: height),
        if (_phase == NeighborhoodCelebrationPhase.unlock) ...<Widget>[
          const Positioned.fill(child: ConfettiOverlay()),
          _buildUnlockBanner(compact),
        ],
      ],
    );
  }

  Widget _buildCaptain({
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
          child: _MobileCaptainStack(
            width: width,
            text: _captainText,
            castIn: _castIn,
            showContinueHint: !_captainTyping,
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
            GameProgress.barangayCutout,
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
              text: _captainText,
              speakerName: 'Barangay Captain',
              accent: _accent,
              showContinueHint: !_captainTyping,
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
              Text(
                'Neighborhood Level 6 Unlocked!',
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
                'Finish the community cleanup next',
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

class _MobileCaptainStack extends StatelessWidget {
  const _MobileCaptainStack({
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
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: Image.asset(
            GameProgress.barangayCutout,
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
            accent: const Color(0xFFEC407A),
            showContinueHint: showContinueHint,
            showSpeakerName: false,
          ),
        ),
        const Positioned(
          left: 0,
          bottom: textPanelMinH,
          child: SpeakerNameTag(
            name: 'Barangay Captain',
            accent: Color(0xFFEC407A),
            compact: true,
          ),
        ),
      ],
    );
  }
}

class _NeighborhoodMapProgress extends StatelessWidget {
  const _NeighborhoodMapProgress({
    required this.progress,
    required this.center,
    required this.compact,
  });

  final double progress;
  final Offset center;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double lightsIn = Curves.easeOut.transform(
      ((progress - 0.55) / 0.2).clamp(0.0, 1.0),
    );
    final double glowR = compact ? 90.0 : 120.0;

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          if (lightsIn > 0)
            Positioned(
              left: center.dx - glowR,
              top: center.dy - glowR,
              width: glowR * 2,
              height: glowR * 2,
              child: Opacity(
                opacity: lightsIn * 0.85,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        Color(0xCCFFECB3),
                        Color(0x00FFECB3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (progress > 0.05 && progress < 0.98)
            Positioned(
              left: 0,
              right: 0,
              top: compact ? 8 : 16,
              child: Center(
                child: _StageLabel(progress: progress, compact: compact),
              ),
            ),
        ],
      ),
    );
  }
}

class _StageLabel extends StatelessWidget {
  const _StageLabel({required this.progress, required this.compact});

  final double progress;
  final bool compact;

  String get _label {
    if (progress < 0.18) return 'Some garbage disappears...';
    if (progress < 0.38) return 'Residents sweep their sidewalks!';
    if (progress < 0.58) return 'Community gardens look healthier!';
    if (progress < 0.78) return 'Streetlights grow brighter!';
    return 'The Barangay Captain smiles!';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xCC0E0E1A),
        border: Border.all(color: const Color(0xFFEC407A), width: 3),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontFamily: 'Jersey10',
          fontSize: compact ? 18 : 24,
          height: 1,
          color: const Color(0xFFF8BBD0),
        ),
      ),
    );
  }
}
