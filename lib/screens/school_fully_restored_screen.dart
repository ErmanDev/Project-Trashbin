import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_progress.dart';
import '../services/save_manager.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/pixel_button.dart';

enum _SchoolRestorePhase { pan, life, dialogue, banner }

/// Full school restoration cutscene after School Level 4.
class SchoolFullyRestoredScreen extends StatefulWidget {
  const SchoolFullyRestoredScreen({super.key});

  @override
  State<SchoolFullyRestoredScreen> createState() =>
      _SchoolFullyRestoredScreenState();
}

class _SchoolFullyRestoredScreenState extends State<SchoolFullyRestoredScreen>
    with TickerProviderStateMixin {
  static const Color _accent = Color(0xFF00897B);
  static const List<String> _lines = <String>[
    'Look at our campus now!',
    'Because of you, students have a clean place to learn.',
    'The School District is grateful.',
  ];

  _SchoolRestorePhase _phase = _SchoolRestorePhase.pan;
  int _lineIndex = -1;
  String _shownText = '';
  bool _typing = false;
  bool _saved = false;

  Timer? _typeTimer;
  Timer? _pauseTimer;

  late final AnimationController _pan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3800),
  );
  late final AnimationController _life = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  late final AnimationController _castIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    _pan.addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _phase = _SchoolRestorePhase.life);
        _life.forward();
      }
    });
    _life.addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _phase = _SchoolRestorePhase.dialogue);
        _castIn.forward();
        _advance();
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
    super.dispose();
  }

  void _advance() {
    final int next = _lineIndex + 1;
    if (next >= _lines.length) {
      _showBanner();
      return;
    }
    setState(() => _lineIndex = next);
    _type(_lines[next]);
  }

  void _type(String full) {
    _typeTimer?.cancel();
    setState(() {
      _shownText = '';
      _typing = true;
    });
    int i = 0;
    _typeTimer = Timer.periodic(const Duration(milliseconds: 28), (Timer t) {
      if (i >= full.length) {
        t.cancel();
        setState(() => _typing = false);
        _pauseTimer = Timer(const Duration(milliseconds: 850), _advance);
        return;
      }
      i++;
      setState(() => _shownText = full.substring(0, i));
    });
  }

  Future<void> _showBanner() async {
    if (!_saved) {
      _saved = true;
      await SaveManager.instance.completeSchoolLevel4();
    }
    if (mounted) setState(() => _phase = _SchoolRestorePhase.banner);
  }

  void _onTap() {
    if (_phase == _SchoolRestorePhase.dialogue) {
      if (_lineIndex < 0) return;
      if (_typing) {
        _typeTimer?.cancel();
        _pauseTimer?.cancel();
        setState(() {
          _shownText = _lines[_lineIndex];
          _typing = false;
        });
        _pauseTimer = Timer(const Duration(milliseconds: 850), _advance);
      } else {
        _pauseTimer?.cancel();
        _advance();
      }
    } else if (_phase == _SchoolRestorePhase.banner) {
      _finish();
    }
  }

  void _finish() {
    Navigator.of(context).pop();
  }

  Widget _buildPrincipal({
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
          child: _MobilePrincipalDialogue(
            width: width,
            text: _shownText,
            castIn: _castIn,
            showContinueHint: !_typing,
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
              bottom: 0 - (1 - t) * 36,
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
              text: _shownText,
              speakerName: 'Principal',
              accent: _accent,
              showContinueHint: !_typing,
            ),
          ),
        ),
      ],
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
          builder: (BuildContext context, BoxConstraints c) {
            final double w = c.maxWidth;
            final double h = c.maxHeight;
            final bool compact = h < 420;
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                AnimatedBuilder(
                  animation: _pan,
                  builder: (BuildContext context, _) {
                    final double t = Curves.easeInOut.transform(_pan.value);
                    return Transform.translate(
                      offset: Offset((t - 0.5) * w * 0.1, 0),
                      child: Transform.scale(
                        scale: 1.1 - t * 0.05,
                        child: Image.asset(
                          GameProgress.schoolCleanBg,
                          fit: BoxFit.cover,
                          width: w,
                          height: h,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                    );
                  },
                ),
                if (_phase.index >= _SchoolRestorePhase.life.index &&
                    _phase.index < _SchoolRestorePhase.dialogue.index)
                  AnimatedBuilder(
                    animation: _life,
                    builder: (BuildContext context, _) {
                      final double p =
                          _phase.index > _SchoolRestorePhase.life.index ? 1 : _life.value;
                      return IgnorePointer(
                        child: Stack(
                          children: <Widget>[
                            if (p > 0.2)
                              ...List<Widget>.generate(6, (int i) {
                                return Positioned(
                                  left: w * (0.1 + (i % 3) * 0.28),
                                  top: h * (0.4 + (i ~/ 3) * 0.15),
                                  child: Opacity(
                                    opacity: ((p - 0.2) / 0.4).clamp(0.0, 1.0),
                                    child: Text(
                                      i.isEven ? '🌸' : '🌼',
                                      style: TextStyle(
                                        fontSize: compact ? 18 : 24,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            if (p > 0.55)
                              Positioned(
                                left: w * 0.2,
                                bottom: h * 0.28,
                                child: Opacity(
                                  opacity: ((p - 0.55) / 0.3).clamp(0.0, 1.0),
                                  child: Text(
                                    '🧒👧',
                                    style: TextStyle(
                                      fontSize: compact ? 28 : 36,
                                    ),
                                  ),
                                ),
                              ),
                            if (p > 0.75)
                              ...List<Widget>.generate(5, (int i) {
                                return Positioned(
                                  left: w * 0.5 +
                                      math.cos(i) * w * 0.25 -
                                      10,
                                  top: h * 0.5 + math.sin(i) * h * 0.1,
                                  child: Opacity(
                                    opacity: ((p - 0.75) / 0.25).clamp(0.0, 1.0),
                                    child: const Text('👏', style: TextStyle(fontSize: 22)),
                                  ),
                                );
                              }),
                          ],
                        ),
                      );
                    },
                  ),
                if (_phase == _SchoolRestorePhase.pan || _phase == _SchoolRestorePhase.life)
                  Positioned(
                    top: compact ? 12 : 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC0E0E1A),
                          border: Border.all(
                            color: const Color(0xFFFFB300),
                            width: 3,
                          ),
                        ),
                        child: Text(
                          _phase == _SchoolRestorePhase.pan
                              ? 'The campus awakens...'
                              : 'Students return to a clean school!',
                          style: TextStyle(
                            fontFamily: 'Jersey10',
                            fontSize: compact ? 18 : 22,
                            color: const Color(0xFFFFE082),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_phase == _SchoolRestorePhase.dialogue &&
                    _lineIndex >= 0) ...<Widget>[
                  // Dim the clean campus so the Principal reads clearly.
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _castIn,
                      builder: (BuildContext context, _) {
                        final double t =
                            Curves.easeOut.transform(_castIn.value);
                        return ColoredBox(
                          color: Colors.black.withValues(alpha: 0.45 * t),
                        );
                      },
                    ),
                  ),
                  _buildPrincipal(
                    compact: compact,
                    width: w,
                    height: h,
                  ),
                ],
                if (_phase == _SchoolRestorePhase.banner) ...<Widget>[
                  const Positioned.fill(child: ConfettiOverlay()),
                  Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(compact ? 12 : 24),
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: compact ? 480 : 560,
                        ),
                        padding: EdgeInsets.all(compact ? 14 : 22),
                        decoration: BoxDecoration(
                          color: const Color(0xF00E0E1A),
                          border: Border.all(
                            color: const Color(0xFFFFB300),
                            width: 5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              '🏫 School Restored!',
                              style: TextStyle(
                                fontFamily: 'Jersey10',
                                fontSize: compact ? 32 : 44,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: compact ? 12 : 16),
                            _line(
                              Icons.monetization_on,
                              const Color(0xFFFFC107),
                              'Bonus Coins',
                              '+${GameProgress.schoolFullyRestoredBonusCoins}',
                              compact,
                            ),
                            _line(
                              Icons.military_tech,
                              const Color(0xFFFFB300),
                              'Badge',
                              GameProgress.scholarBadgeTitle,
                              compact,
                            ),
                            _line(
                              Icons.holiday_village,
                              const Color(0xFFEC407A),
                              'Neighborhood',
                              'Unlocked!',
                              compact,
                            ),
                            SizedBox(height: compact ? 14 : 18),
                            PixelButton(
                              label: 'Back to Map',
                              icon: Icons.map,
                              color: const Color(0xFF42A5F5),
                              width: null,
                              compact: true,
                              onPressed: _finish,
                            ),
                          ],
                        ),
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

  Widget _line(
    IconData icon,
    Color color,
    String label,
    String value,
    bool compact,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 8),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color, size: compact ? 20 : 24),
          const SizedBox(width: 8),
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
      ),
    );
  }
}

class _MobilePrincipalDialogue extends StatelessWidget {
  const _MobilePrincipalDialogue({
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
