import 'dart:async';

import 'package:flutter/material.dart';

import '../models/game_character.dart';
import '../models/game_progress.dart';
import '../models/sorting_item.dart';
import '../models/town_location.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/mobile_mayor_dialogue_stack.dart';
import '../widgets/pixel_button.dart';
import 'sorting_screen.dart';

class _Line {
  const _Line(this.text);
  final String text;
}

/// Park Level 2 intro: Mayor dialogue, then straight into waste sorting (no puzzle).
class ParkLevel2IntroScreen extends StatefulWidget {
  const ParkLevel2IntroScreen({
    super.key,
    required this.character,
    required this.location,
  });

  final GameCharacter character;
  final TownLocation location;

  @override
  State<ParkLevel2IntroScreen> createState() => _ParkLevel2IntroScreenState();
}

class _ParkLevel2IntroScreenState extends State<ParkLevel2IntroScreen>
    with TickerProviderStateMixin {
  static const Color _mayorAccent = Color(0xFF3949AB);

  static const List<_Line> _lines = <_Line>[
    _Line("You're getting the hang of it."),
    _Line("Let's finish cleaning the park."),
  ];

  static const Duration _pauseBetweenLines = Duration(milliseconds: 900);
  static const Duration _charTick = Duration(milliseconds: 30);

  late final AnimationController _fadeIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _mayorIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  int _lineIndex = -1;
  String _shownText = '';
  bool _typing = false;
  bool _showReady = false;

  Timer? _typeTimer;
  Timer? _pauseTimer;

  @override
  void initState() {
    super.initState();
    _fadeIn.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _mayorIn.forward();
      }
    });
    _mayorIn.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _advanceLine();
      }
    });
    _fadeIn.forward();
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _pauseTimer?.cancel();
    _fadeIn.dispose();
    _mayorIn.dispose();
    super.dispose();
  }

  void _advanceLine() {
    if (!mounted) return;
    final int next = _lineIndex + 1;
    if (next >= _lines.length) {
      setState(() => _showReady = true);
      return;
    }
    setState(() => _lineIndex = next);
    _typeLine(_lines[next].text);
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

  void _onTap() {
    if (_showReady || _lineIndex < 0) return;
    if (_typing) {
      _typeTimer?.cancel();
      _pauseTimer?.cancel();
      setState(() {
        _shownText = _lines[_lineIndex].text;
        _typing = false;
      });
      _pauseTimer = Timer(_pauseBetweenLines, _advanceLine);
    } else {
      _pauseTimer?.cancel();
      _advanceLine();
    }
  }

  void _onStart() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SortingScreen(
          character: widget.character,
          location: widget.location,
          items: ParkSortingLevel2.items,
          bins: ParkSortingLevel2.bins,
          coinsPerCorrect: ParkSortingLevel2.coinsPerCorrect,
          levelTitle: ParkSortingLevel2.levelTitle,
          locationId: GameProgress.parkLocationId,
          levelNumber: ParkSortingLevel2.parkLevel,
          phaseLabel: 'Level 2',
          backgroundAsset: GameProgress.parkCleanBg,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onTap,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double w = constraints.maxWidth;
            final double h = constraints.maxHeight;
            final bool compact = h < 420;
            final double spriteHeight = h * 0.72;

            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _fadeIn,
                    builder: (BuildContext context, Widget? child) {
                      return Opacity(
                        opacity: _fadeIn.value,
                        child: child,
                      );
                    },
                    child: Image.asset(
                      GameProgress.parkCleanBg,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                ),

                if (!compact)
                  AnimatedBuilder(
                    animation: _mayorIn,
                    builder: (BuildContext context, Widget? child) {
                      final double t =
                          Curves.easeOut.transform(_mayorIn.value);
                      return Positioned(
                        bottom: 0 - (1 - t) * 40.0,
                        left: w * 0.05,
                        height: spriteHeight,
                        child: Opacity(opacity: t, child: child),
                      );
                    },
                    child: Image.asset(
                      'assets/images/png/char_mayor_cutout.png',
                      filterQuality: FilterQuality.none,
                    ),
                  ),

                if (_lineIndex >= 0)
                  Positioned(
                    left: compact ? 10 : 16,
                    right: compact ? 10 : 16,
                    bottom: compact ? 10 : 16,
                    child: SafeArea(
                      top: false,
                      child: compact
                          ? MobileMayorDialogueStack(
                              width: w,
                              text: _shownText,
                              mayorIn: _mayorIn,
                              mayorAccent: _mayorAccent,
                              showContinueHint: !_typing && !_showReady,
                              aboveDialogue: _showReady
                                  ? Center(
                                      child: PixelButton(
                                        label: "Let's Sort!",
                                        icon: Icons.swap_vert,
                                        color: const Color(0xFF4CAF50),
                                        width: null,
                                        compact: true,
                                        onPressed: _onStart,
                                      ),
                                    )
                                  : null,
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                if (_showReady) ...<Widget>[
                                  Center(
                                    child: PixelButton(
                                      label: "Let's Sort!",
                                      icon: Icons.swap_vert,
                                      color: const Color(0xFF4CAF50),
                                      width: null,
                                      onPressed: _onStart,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                DialogueBox(
                                  text: _shownText,
                                  speakerName: 'Mayor',
                                  accent: _mayorAccent,
                                  showContinueHint:
                                      !_typing && !_showReady,
                                ),
                              ],
                            ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
