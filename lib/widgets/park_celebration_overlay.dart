import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_progress.dart';
import '../models/town_location.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/mobile_mayor_dialogue_stack.dart';
import '../widgets/pixel_button.dart';

/// Phases of the post-Level-1 park celebration.
enum ParkCelebrationPhase {
  /// Camera pans back to the park on the town map.
  panning,
  /// On-map restoration: trash → grass → flowers → children → clap.
  restoring,
  /// Full-screen clean park + mayor dialogue.
  mayor,
  rewards,
  levelUnlock,
  done,
}

/// Post-Level-1 celebration: town map animation → mayor cinematic → rewards.
class ParkCelebrationOverlay extends StatefulWidget {
  const ParkCelebrationOverlay({
    super.key,
    required this.mapTransform,
    required this.mapSize,
    required this.viewSize,
    required this.maxPanX,
    required this.maxPanY,
    required this.coinsEarned,
    required this.onFinished,
  });

  final TransformationController mapTransform;
  final Size mapSize;
  final Size viewSize;
  final double maxPanX;
  final double maxPanY;
  final int coinsEarned;
  final VoidCallback onFinished;

  @override
  State<ParkCelebrationOverlay> createState() => _ParkCelebrationOverlayState();
}

class _ParkCelebrationOverlayState extends State<ParkCelebrationOverlay>
    with TickerProviderStateMixin {
  static const Color _border = Color(0xFF2B2B3A);
  static const Color _mayorAccent = Color(0xFF3949AB);

  ParkCelebrationPhase _phase = ParkCelebrationPhase.panning;
  String _mayorText = '';
  bool _mayorTyping = false;

  late final AnimationController _pan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final AnimationController _restore = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4500),
  );
  late final AnimationController _cinematicIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final AnimationController _mayorIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  late final Matrix4 _startTransform;
  late final Matrix4 _targetTransform;

  Offset get _parkMapOffset {
    final TownLocation park = TownLocation.all.first;
    final double x = (park.position.x + 1) / 2 * widget.mapSize.width;
    final double y = (park.position.y + 1) / 2 * widget.mapSize.height;
    return Offset(x, y);
  }

  bool get _showMapRestoration =>
      _phase == ParkCelebrationPhase.restoring ||
      (_phase == ParkCelebrationPhase.mayor && _cinematicIn.value < 1);

  bool get _showCinematic => _phase.index >= ParkCelebrationPhase.mayor.index;

  double get _cinematicOpacity {
    if (_phase.index > ParkCelebrationPhase.mayor.index) return 1;
    if (_phase == ParkCelebrationPhase.mayor) {
      return Curves.easeInOut.transform(_cinematicIn.value);
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _startTransform = widget.mapTransform.value.clone();
    _targetTransform = _computeParkCenterTransform();

    _pan.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _phase = ParkCelebrationPhase.restoring);
        _restore.forward();
      }
    });
    _restore.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed && mounted) {
        _beginMayorCinematic();
      }
    });

    _pan.forward();
  }

  void _beginMayorCinematic() {
    setState(() => _phase = ParkCelebrationPhase.mayor);
    _cinematicIn.forward();
    _mayorIn.forward();
    _showMayorLine();
  }

  Matrix4 _computeParkCenterTransform() {
    final Offset park = _parkMapOffset;
    double tx = widget.viewSize.width / 2 - park.dx;
    double ty = widget.viewSize.height / 2 - park.dy;
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

  void _showMayorLine() {
    setState(() {
      _mayorText = '';
      _mayorTyping = true;
    });
    const String line = 'Wonderful!';
    int i = 0;
    Future<void>.delayed(const Duration(milliseconds: 40), () async {
      while (i <= line.length && mounted) {
        setState(() => _mayorText = line.substring(0, i));
        i++;
        await Future<void>.delayed(const Duration(milliseconds: 45));
      }
      if (mounted) setState(() => _mayorTyping = false);
    });
  }

  void _onTap() {
    switch (_phase) {
      case ParkCelebrationPhase.mayor:
        if (_mayorTyping) {
          setState(() {
            _mayorText = 'Wonderful!';
            _mayorTyping = false;
          });
        } else {
          setState(() => _phase = ParkCelebrationPhase.rewards);
        }
      case ParkCelebrationPhase.rewards:
        setState(() => _phase = ParkCelebrationPhase.levelUnlock);
      case ParkCelebrationPhase.levelUnlock:
        setState(() => _phase = ParkCelebrationPhase.done);
        widget.onFinished();
      default:
        break;
    }
  }

  @override
  void dispose() {
    _pan.dispose();
    _restore.dispose();
    _cinematicIn.dispose();
    _mayorIn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = widget.viewSize.height < 420;
    final double w = widget.viewSize.width;
    final double h = widget.viewSize.height;
    final Offset parkScreen = _parkScreenPosition();

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // 1) Camera returns to town map — pan to park.
          if (_phase == ParkCelebrationPhase.panning)
            AnimatedBuilder(
              animation: _pan,
              builder: (BuildContext context, _) {
                _updatePanTransform();
                return const SizedBox.shrink();
              },
            ),

          // 2) On-map restoration animation (town map stays visible).
          if (_showMapRestoration)
            AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[_restore, _cinematicIn]),
              builder: (BuildContext context, _) {
                final double progress = _phase == ParkCelebrationPhase.restoring
                    ? _restore.value
                    : 1.0;
                return _ParkMapRestoration(
                  progress: progress,
                  center: parkScreen,
                  compact: compact,
                );
              },
            ),

          // 3–5) Mayor → rewards → level unlock on full-screen clean park.
          if (_showCinematic && _cinematicOpacity > 0)
            Positioned.fill(
              child: Opacity(
                opacity: _cinematicOpacity,
                child: _buildCinematicScene(
                  compact: compact,
                  width: w,
                  height: h,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCinematicScene({
    required bool compact,
    required double width,
    required double height,
  }) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: <Widget>[
        Image.asset(
          GameProgress.parkCleanBg,
          fit: BoxFit.cover,
          width: width,
          height: height,
          filterQuality: FilterQuality.none,
        ),
        if (_phase == ParkCelebrationPhase.mayor)
          _buildMayorCinematic(compact: compact, width: width, height: height),
        if (_phase == ParkCelebrationPhase.rewards)
          _buildRewardsDialog(compact),
        if (_phase == ParkCelebrationPhase.levelUnlock) ...<Widget>[
          const Positioned.fill(child: ConfettiOverlay()),
          _buildLevelUnlockBanner(compact),
        ],
      ],
    );
  }

  Widget _buildMayorCinematic({
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
            mayorIn: _mayorIn,
            mayorAccent: _mayorAccent,
            showContinueHint: !_mayorTyping,
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
            return Positioned(
              bottom: 0 - (1 - t) * 40,
              left: width * 0.05,
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
              text: _mayorText,
              speakerName: 'Mayor',
              accent: _mayorAccent,
              showContinueHint: !_mayorTyping,
            ),
          ),
        ),
      ],
    );
  }

  Offset _parkScreenPosition() {
    final Offset park = _parkMapOffset;
    final Matrix4 m = widget.mapTransform.value;
    return Offset(
      park.dx + m.getTranslation().x,
      park.dy + m.getTranslation().y,
    );
  }

  Widget _buildRewardsDialog(bool compact) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: compact ? 16 : 32),
        padding: EdgeInsets.fromLTRB(
          compact ? 16 : 24,
          compact ? 14 : 20,
          compact ? 16 : 24,
          compact ? 16 : 22,
        ),
        decoration: BoxDecoration(
          color: const Color(0xF00E0E1A),
          border: Border.all(color: _border, width: compact ? 4 : 5),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0xAA000000), offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'You Received!',
              style: TextStyle(
                fontFamily: 'Jersey10',
                fontSize: compact ? 36 : 48,
                height: 1,
                color: Colors.white,
                shadows: const <Shadow>[
                  Shadow(color: _border, offset: Offset(2, 2)),
                ],
              ),
            ),
            SizedBox(height: compact ? 12 : 16),
            _RewardRow(
              icon: Icons.monetization_on,
              color: const Color(0xFFFFC107),
              label: 'Coins',
              value: '+${widget.coinsEarned}',
              compact: compact,
            ),
            SizedBox(height: compact ? 8 : 10),
            _RewardRow(
              icon: Icons.checkroom,
              color: const Color(0xFF66BB6A),
              label: 'New Hat',
              value: GameProgress.ecoHatName,
              compact: compact,
            ),
            SizedBox(height: compact ? 8 : 10),
            _RewardRow(
              icon: Icons.military_tech,
              color: const Color(0xFF42A5F5),
              label: 'Badge',
              value: GameProgress.recyclingRookieTitle,
              compact: compact,
            ),
            SizedBox(height: compact ? 14 : 18),
            Text(
              'Tap to continue',
              style: TextStyle(
                fontFamily: 'Jersey10',
                fontSize: compact ? 18 : 22,
                color: const Color(0xFFB0BEC5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelUnlockBanner(bool compact) {
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
            border: Border.all(color: const Color(0xFF4CAF50), width: 5),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.35),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.lock_open,
                color: const Color(0xFF4CAF50),
                size: compact ? 36 : 56,
              ),
              SizedBox(height: compact ? 6 : 12),
              Text(
                'Park Level 2 Unlocked!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Jersey10',
                  fontSize: compact ? 28 : 44,
                  height: 1,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: compact ? 8 : 14),
              Center(
                child: PixelButton(
                  label: 'Continue',
                  icon: Icons.map,
                  color: const Color(0xFF4CAF50),
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

/// Staged restoration played on the town map at the park node.
class _ParkMapRestoration extends StatelessWidget {
  const _ParkMapRestoration({
    required this.progress,
    required this.center,
    required this.compact,
  });

  final double progress;
  final Offset center;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Timeline: trash → grass + clean park → flowers → children → clap
    final double trashOut = (1 - (progress / 0.22)).clamp(0.0, 1.0);
    final double grassIn = Curves.easeOut.transform(
      ((progress - 0.15) / 0.30).clamp(0.0, 1.0),
    );
    final double flowersIn = Curves.elasticOut.transform(
      ((progress - 0.40) / 0.22).clamp(0.0, 1.0),
    );
    final double kidsIn = Curves.easeOut.transform(
      ((progress - 0.58) / 0.20).clamp(0.0, 1.0),
    );
    final double clapIn = Curves.easeOut.transform(
      ((progress - 0.75) / 0.25).clamp(0.0, 1.0),
    );

    final double glowR = compact ? 90.0 : 120.0;

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          // Grass becomes green.
          if (grassIn > 0)
            Positioned(
              left: center.dx - glowR,
              top: center.dy - glowR,
              width: glowR * 2,
              height: glowR * 2,
              child: Opacity(
                opacity: grassIn,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        const Color(0xCC43A047),
                        const Color(0x0043A047),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Trash disappears.
          if (trashOut > 0)
            ..._scatter(6, (int i) {
              final double angle = i * 1.15;
              final double dist = compact ? 48.0 : 64.0;
              return Positioned(
                left: center.dx + math.cos(angle) * dist - 14,
                top: center.dy + math.sin(angle) * dist * 0.7 - 14,
                child: Opacity(
                  opacity: trashOut,
                  child: Icon(
                    i.isEven ? Icons.delete_outline : Icons.lunch_dining,
                    color: const Color(0xFF8D6E63),
                    size: compact ? 24 : 28,
                  ),
                ),
              );
            }),

          // Flowers bloom.
          if (flowersIn > 0)
            ..._scatter(8, (int i) {
              final double angle = i * 0.78 + 0.3;
              final double dist = (compact ? 70.0 : 95.0) * (0.6 + i * 0.05);
              return Positioned(
                left: center.dx + math.cos(angle) * dist - 10,
                top: center.dy + math.sin(angle) * dist * 0.65 - 10,
                child: Transform.scale(
                  scale: flowersIn,
                  child: Text(
                    i % 3 == 0 ? '🌸' : (i % 3 == 1 ? '🌼' : '🌷'),
                    style: TextStyle(fontSize: compact ? 18 : 22, height: 1),
                  ),
                ),
              );
            }),

          // Children return.
          if (kidsIn > 0) ...<Widget>[
            Positioned(
              left: center.dx - (compact ? 55 : 72),
              top: center.dy + (compact ? 20 : 28),
              child: Opacity(
                opacity: kidsIn,
                child: Transform.translate(
                  offset: Offset(0, (1 - kidsIn) * 24),
                  child: Text('🧒', style: TextStyle(fontSize: compact ? 26 : 32)),
                ),
              ),
            ),
            Positioned(
              left: center.dx + (compact ? 30 : 42),
              top: center.dy + (compact ? 24 : 32),
              child: Opacity(
                opacity: kidsIn,
                child: Transform.translate(
                  offset: Offset(0, (1 - kidsIn) * 28),
                  child: Text('👧', style: TextStyle(fontSize: compact ? 26 : 32)),
                ),
              ),
            ),
            Positioned(
              left: center.dx - (compact ? 10 : 14),
              top: center.dy + (compact ? 38 : 50),
              child: Opacity(
                opacity: kidsIn,
                child: Transform.translate(
                  offset: Offset(0, (1 - kidsIn) * 20),
                  child: Text('🏃', style: TextStyle(fontSize: compact ? 22 : 28)),
                ),
              ),
            ),
          ],

          // People clap.
          if (clapIn > 0)
            ..._scatter(5, (int i) {
              final double angle = i * 1.25 - 1.2;
              final double dist = compact ? 85.0 : 110.0;
              return Positioned(
                left: center.dx + math.cos(angle) * dist - 11,
                top: center.dy + math.sin(angle) * dist * 0.5 - 30,
                child: Opacity(
                  opacity: clapIn,
                  child: Transform.scale(
                    scale: 0.85 + 0.15 * math.sin(clapIn * math.pi * 3 + i),
                    child: const Text('👏', style: TextStyle(fontSize: 22)),
                  ),
                ),
              );
            }),

          // Stage label during restoration.
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

  List<Widget> _scatter(int count, Widget Function(int index) builder) {
    return List<Widget>.generate(count, builder);
  }
}

class _StageLabel extends StatelessWidget {
  const _StageLabel({required this.progress, required this.compact});

  final double progress;
  final bool compact;

  String get _label {
    if (progress < 0.22) return 'Trash disappears...';
    if (progress < 0.45) return 'Grass becomes green!';
    if (progress < 0.62) return 'Flowers bloom!';
    if (progress < 0.78) return 'Children return!';
    return 'People clap!';
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
        border: Border.all(color: const Color(0xFF4CAF50), width: 3),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontFamily: 'Jersey10',
          fontSize: compact ? 20 : 26,
          height: 1,
          color: const Color(0xFF9FE6A0),
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
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
        Container(
          width: compact ? 40 : 48,
          height: compact ? 40 : 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color, width: 3),
          ),
          child: Icon(icon, color: color, size: compact ? 22 : 26),
        ),
        SizedBox(width: compact ? 10 : 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Jersey10',
              fontSize: compact ? 22 : 26,
              color: const Color(0xFFB0BEC5),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Jersey10',
            fontSize: compact ? 22 : 28,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
