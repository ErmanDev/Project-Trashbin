import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_progress.dart';
import '../models/town_location.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/pixel_button.dart';

/// Phases of the post–Level-3 school celebration.
enum SchoolCelebrationPhase {
  panning,
  restoring,
  principal,
  rewards,
  levelUnlock,
  done,
}

/// Post–Level-3 celebration: map pan → campus restore → clean school + Principal.
class SchoolCelebrationOverlay extends StatefulWidget {
  const SchoolCelebrationOverlay({
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
  State<SchoolCelebrationOverlay> createState() =>
      _SchoolCelebrationOverlayState();
}

class _SchoolCelebrationOverlayState extends State<SchoolCelebrationOverlay>
    with TickerProviderStateMixin {
  static const Color _border = Color(0xFF2B2B3A);
  static const Color _principalAccent = Color(0xFF00897B);

  SchoolCelebrationPhase _phase = SchoolCelebrationPhase.panning;
  String _principalText = '';
  bool _principalTyping = false;

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
  late final AnimationController _castIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  late final Matrix4 _startTransform;
  late final Matrix4 _targetTransform;

  Offset get _schoolMapOffset {
    final TownLocation school = TownLocation.all.firstWhere(
      (TownLocation l) => l.id == 'school',
    );
    final double x = (school.position.x + 1) / 2 * widget.mapSize.width;
    final double y = (school.position.y + 1) / 2 * widget.mapSize.height;
    return Offset(x, y);
  }

  bool get _showMapRestoration =>
      _phase == SchoolCelebrationPhase.restoring ||
      (_phase == SchoolCelebrationPhase.principal && _cinematicIn.value < 1);

  bool get _showCinematic =>
      _phase.index >= SchoolCelebrationPhase.principal.index;

  double get _cinematicOpacity {
    if (_phase.index > SchoolCelebrationPhase.principal.index) return 1;
    if (_phase == SchoolCelebrationPhase.principal) {
      return Curves.easeInOut.transform(_cinematicIn.value);
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _startTransform = widget.mapTransform.value.clone();
    _targetTransform = _computeSchoolCenterTransform();

    _pan.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _phase = SchoolCelebrationPhase.restoring);
        _restore.forward();
      }
    });
    _restore.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed && mounted) {
        _beginPrincipalCinematic();
      }
    });

    _pan.forward();
  }

  void _beginPrincipalCinematic() {
    setState(() => _phase = SchoolCelebrationPhase.principal);
    _cinematicIn.forward();
    _castIn.forward();
    _showPrincipalLine();
  }

  Matrix4 _computeSchoolCenterTransform() {
    final Offset school = _schoolMapOffset;
    double tx = widget.viewSize.width / 2 - school.dx;
    double ty = widget.viewSize.height / 2 - school.dy;
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

  void _showPrincipalLine() {
    setState(() {
      _principalText = '';
      _principalTyping = true;
    });
    const String line = 'Wonderful!';
    int i = 0;
    Future<void>.delayed(const Duration(milliseconds: 40), () async {
      while (i <= line.length && mounted) {
        setState(() => _principalText = line.substring(0, i));
        i++;
        await Future<void>.delayed(const Duration(milliseconds: 45));
      }
      if (mounted) setState(() => _principalTyping = false);
    });
  }

  void _onTap() {
    switch (_phase) {
      case SchoolCelebrationPhase.principal:
        if (_principalTyping) {
          setState(() {
            _principalText = 'Wonderful!';
            _principalTyping = false;
          });
        } else {
          setState(() => _phase = SchoolCelebrationPhase.rewards);
        }
      case SchoolCelebrationPhase.rewards:
        setState(() => _phase = SchoolCelebrationPhase.levelUnlock);
      case SchoolCelebrationPhase.levelUnlock:
        setState(() => _phase = SchoolCelebrationPhase.done);
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
    _castIn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = widget.viewSize.height < 420;
    final double w = widget.viewSize.width;
    final double h = widget.viewSize.height;
    final Offset schoolScreen = _schoolScreenPosition();

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (_phase == SchoolCelebrationPhase.panning)
            AnimatedBuilder(
              animation: _pan,
              builder: (BuildContext context, _) {
                _updatePanTransform();
                return const SizedBox.shrink();
              },
            ),
          if (_showMapRestoration)
            AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[_restore, _cinematicIn]),
              builder: (BuildContext context, _) {
                final double progress =
                    _phase == SchoolCelebrationPhase.restoring
                        ? _restore.value
                        : 1.0;
                return _SchoolMapRestoration(
                  progress: progress,
                  center: schoolScreen,
                  compact: compact,
                );
              },
            ),
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
          GameProgress.schoolCleanBg,
          fit: BoxFit.cover,
          width: width,
          height: height,
          filterQuality: FilterQuality.none,
        ),
        if (_phase == SchoolCelebrationPhase.principal)
          _buildPrincipalCinematic(
            compact: compact,
            width: width,
            height: height,
          ),
        if (_phase == SchoolCelebrationPhase.rewards)
          _buildRewardsDialog(compact),
        if (_phase == SchoolCelebrationPhase.levelUnlock) ...<Widget>[
          const Positioned.fill(child: ConfettiOverlay()),
          _buildLevelUnlockBanner(compact),
        ],
      ],
    );
  }

  Widget _buildPrincipalCinematic({
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
          child: _MobilePrincipalStack(
            width: width,
            text: _principalText,
            castIn: _castIn,
            showContinueHint: !_principalTyping,
          ),
        ),
      );
    }

    final double spriteHeight = height * 0.72;
    return Stack(
      children: <Widget>[
        AnimatedBuilder(
          animation: _castIn,
          builder: (BuildContext context, Widget? child) {
            final double t = Curves.easeOut.transform(_castIn.value);
            return Positioned(
              bottom: 0 - (1 - t) * 40,
              left: width * 0.05,
              height: spriteHeight,
              child: Opacity(opacity: t, child: child),
            );
          },
          child: Image.asset(
            GameProgress.principalCutout,
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
              text: _principalText,
              speakerName: 'Principal',
              accent: _principalAccent,
              showContinueHint: !_principalTyping,
            ),
          ),
        ),
      ],
    );
  }

  Offset _schoolScreenPosition() {
    final Offset school = _schoolMapOffset;
    final Matrix4 m = widget.mapTransform.value;
    return Offset(
      school.dx + m.getTranslation().x,
      school.dy + m.getTranslation().y,
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
              icon: Icons.eco,
              color: const Color(0xFF66BB6A),
              label: 'Campus',
              value: 'Looking cleaner!',
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
            border: Border.all(color: const Color(0xFF00897B), width: 5),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF00897B).withValues(alpha: 0.35),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.lock_open,
                color: const Color(0xFF00897B),
                size: compact ? 36 : 56,
              ),
              SizedBox(height: compact ? 6 : 12),
              Text(
                'School Level 4 Unlocked!',
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
                  color: const Color(0xFF00897B),
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

class _MobilePrincipalStack extends StatelessWidget {
  const _MobilePrincipalStack({
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
            GameProgress.principalCutout,
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
            accent: const Color(0xFF00897B),
            showContinueHint: showContinueHint,
            showSpeakerName: false,
          ),
        ),
        const Positioned(
          left: 0,
          bottom: textPanelMinH,
          child: SpeakerNameTag(
            name: 'Principal',
            accent: Color(0xFF00897B),
            compact: true,
          ),
        ),
      ],
    );
  }
}

class _SchoolMapRestoration extends StatelessWidget {
  const _SchoolMapRestoration({
    required this.progress,
    required this.center,
    required this.compact,
  });

  final double progress;
  final Offset center;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double trashOut = (1 - (progress / 0.22)).clamp(0.0, 1.0);
    final double cleanIn = Curves.easeOut.transform(
      ((progress - 0.15) / 0.30).clamp(0.0, 1.0),
    );
    final double booksIn = Curves.elasticOut.transform(
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
          if (cleanIn > 0)
            Positioned(
              left: center.dx - glowR,
              top: center.dy - glowR,
              width: glowR * 2,
              height: glowR * 2,
              child: Opacity(
                opacity: cleanIn,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        const Color(0xCC00897B),
                        const Color(0x0000897B),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
          if (booksIn > 0)
            ..._scatter(8, (int i) {
              final double angle = i * 0.78 + 0.3;
              final double dist = (compact ? 70.0 : 95.0) * (0.6 + i * 0.05);
              return Positioned(
                left: center.dx + math.cos(angle) * dist - 10,
                top: center.dy + math.sin(angle) * dist * 0.65 - 10,
                child: Transform.scale(
                  scale: booksIn,
                  child: Text(
                    i % 3 == 0 ? '📚' : (i % 3 == 1 ? '✏️' : '🎒'),
                    style: TextStyle(fontSize: compact ? 18 : 22, height: 1),
                  ),
                ),
              );
            }),
          if (kidsIn > 0) ...<Widget>[
            Positioned(
              left: center.dx - (compact ? 55 : 72),
              top: center.dy + (compact ? 20 : 28),
              child: Opacity(
                opacity: kidsIn,
                child: Transform.translate(
                  offset: Offset(0, (1 - kidsIn) * 24),
                  child: Text(
                    '🧒',
                    style: TextStyle(fontSize: compact ? 26 : 32),
                  ),
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
                  child: Text(
                    '👧',
                    style: TextStyle(fontSize: compact ? 26 : 32),
                  ),
                ),
              ),
            ),
          ],
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
    if (progress < 0.45) return 'Campus brightens!';
    if (progress < 0.62) return 'School supplies return!';
    if (progress < 0.78) return 'Students come back!';
    return 'Everyone cheers!';
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
        border: Border.all(color: const Color(0xFF00897B), width: 3),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontFamily: 'Jersey10',
          fontSize: compact ? 20 : 26,
          height: 1,
          color: const Color(0xFF80CBC4),
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
