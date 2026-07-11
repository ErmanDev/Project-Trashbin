import 'dart:async';

import 'package:flutter/material.dart';

import '../models/game_character.dart';
import '../models/game_progress.dart';
import '../models/town_location.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/mobile_mayor_dialogue_stack.dart';
import '../widgets/pixel_button.dart';
import 'neighborhood_sort_transition_screen.dart';
import 'puzzle_screen.dart';

class _Line {
  const _Line(this.speaker, this.accent, this.text, {this.isMayor = false});
  final String speaker;
  final Color accent;
  final String text;
  final bool isMayor;
}

/// Neighborhood intro: zoom into messy street, Barangay Captain then Mayor.
class NeighborhoodIntroScreen extends StatefulWidget {
  const NeighborhoodIntroScreen({
    super.key,
    required this.character,
    required this.location,
  });

  final GameCharacter character;
  final TownLocation location;

  @override
  State<NeighborhoodIntroScreen> createState() =>
      _NeighborhoodIntroScreenState();
}

class _NeighborhoodIntroScreenState extends State<NeighborhoodIntroScreen>
    with TickerProviderStateMixin {
  static const Color _captainAccent = Color(0xFFEC407A);
  static const Color _mayorAccent = Color(0xFF3949AB);

  static const List<_Line> _lines = <_Line>[
    _Line(
      'Barangay Captain',
      _captainAccent,
      'Welcome to our neighborhood.',
    ),
    _Line(
      'Barangay Captain',
      _captainAccent,
      "Everyone throws their garbage into one bin, and now it's becoming a serious problem.",
    ),
    _Line(
      'Barangay Captain',
      _captainAccent,
      "Some items are even dangerous if they're handled incorrectly.",
    ),
    _Line(
      'Mayor',
      _mayorAccent,
      "Today you'll learn how to identify hazardous waste and keep your community safe.",
      isMayor: true,
    ),
  ];

  static const Duration _pauseBetweenLines = Duration(milliseconds: 900);
  static const Duration _charTick = Duration(milliseconds: 28);

  late final AnimationController _zoom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  late final AnimationController _captainIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  late final AnimationController _mayorIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  late final AnimationController _dim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  int _lineIndex = -1;
  String _shownText = '';
  bool _typing = false;
  bool _showReady = false;
  bool _mayorArrived = false;

  Timer? _typeTimer;
  Timer? _pauseTimer;

  @override
  void initState() {
    super.initState();
    _zoom.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _dim.forward();
        _captainIn.forward();
      }
    });
    _captainIn.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _advanceLine();
      }
    });
    _zoom.forward();
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _pauseTimer?.cancel();
    _zoom.dispose();
    _captainIn.dispose();
    _mayorIn.dispose();
    _dim.dispose();
    super.dispose();
  }

  Future<void> _advanceLine() async {
    if (!mounted) return;
    final int next = _lineIndex + 1;
    if (next >= _lines.length) {
      setState(() => _showReady = true);
      return;
    }

    final _Line line = _lines[next];
    if (line.isMayor && !_mayorArrived) {
      setState(() {
        _mayorArrived = true;
        _lineIndex = next;
        _shownText = '';
        _typing = false;
      });
      await _mayorIn.forward();
      if (!mounted) return;
      _typeLine(line.text);
      return;
    }

    setState(() => _lineIndex = next);
    _typeLine(line.text);
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

  void _onStartMission() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => PuzzleScreen(
          character: widget.character,
          location: widget.location,
          imageAsset: 'assets/images/png/puzzle_neighborhood_clean.png',
          itemName: 'Clean Neighborhood',
          gridSize: 4,
          backgroundAsset: GameProgress.neighborhoodTrashBg,
          phaseLabel: 'Level 5 · Phase 1',
          instructionText:
              'Complete the picture to discover how communities can work '
              'together to keep their neighborhood clean.',
          completeMessage:
              "Great! Now let's organize the neighborhood's waste.",
          nextBuilder: (BuildContext context) =>
              NeighborhoodSortTransitionScreen(
            character: widget.character,
            location: widget.location,
          ),
        ),
      ),
    );
  }

  bool get _showingMayor =>
      _lineIndex >= 0 && _lines[_lineIndex].isMayor;

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
            final double spriteHeight = h * (compact ? 0.55 : 0.72);
            final double bgOpacityCap = compact ? 0.42 : 1.0;

            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned.fill(
                  child: ClipRect(
                    child: AnimatedBuilder(
                      animation: _zoom,
                      builder: (BuildContext context, Widget? child) {
                        final double scale = 1.0 + 0.22 * _zoom.value;
                        final double opacity = compact
                            ? (0.08 + _zoom.value * bgOpacityCap)
                                .clamp(0.0, bgOpacityCap)
                            : (0.15 + _zoom.value).clamp(0.0, 1.0);
                        return Transform.scale(
                          scale: scale,
                          child: Opacity(opacity: opacity, child: child),
                        );
                      },
                      child: Image.asset(
                        GameProgress.neighborhoodTrashBg,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                ),

                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _dim,
                    builder: (BuildContext context, _) {
                      return ColoredBox(
                        color: Colors.black.withValues(
                          alpha: 0.45 * _dim.value,
                        ),
                      );
                    },
                  ),
                ),

                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _zoom,
                      builder: (BuildContext context, _) => ColoredBox(
                        color: Colors.black.withValues(
                          alpha: (1 - _zoom.value).clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                  ),
                ),

                if (!compact) ...<Widget>[
                  AnimatedBuilder(
                    animation: _captainIn,
                    builder: (BuildContext context, Widget? child) {
                      final double t =
                          Curves.easeOut.transform(_captainIn.value);
                      return Positioned(
                        bottom: 0 - (1 - t) * 36,
                        left: w * 0.04,
                        height: spriteHeight,
                        child: Opacity(
                          opacity: t * (_showingMayor ? 0.55 : 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: Image.asset(
                      GameProgress.barangayCutout,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                  if (_mayorArrived)
                    AnimatedBuilder(
                      animation: _mayorIn,
                      builder: (BuildContext context, Widget? child) {
                        final double t =
                            Curves.easeOut.transform(_mayorIn.value);
                        return Positioned(
                          bottom: 0 - (1 - t) * 36,
                          right: w * 0.04,
                          height: spriteHeight,
                          child: Opacity(opacity: t, child: child),
                        );
                      },
                      child: Image.asset(
                        GameProgress.mayorCutout,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                ],

                if (_lineIndex >= 0)
                  Positioned(
                    left: compact ? 10 : 16,
                    right: compact ? 10 : 16,
                    bottom: compact ? 10 : 16,
                    child: SafeArea(
                      top: false,
                      child: compact
                          ? _buildMobileDialogue(w: w)
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                if (_showReady) ...<Widget>[
                                  Center(
                                    child: PixelButton(
                                      label: 'Start Mission',
                                      icon: Icons.flag,
                                      color: const Color(0xFFFFB300),
                                      width: null,
                                      onPressed: _onStartMission,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                DialogueBox(
                                  text: _shownText,
                                  speakerName: _lines[_lineIndex].speaker,
                                  accent: _lines[_lineIndex].accent,
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

  Widget _buildMobileDialogue({required double w}) {
    final _Line line = _lines[_lineIndex];
    final Widget? startBtn = _showReady
        ? Center(
            child: PixelButton(
              label: 'Start Mission',
              icon: Icons.flag,
              color: const Color(0xFFFFB300),
              width: null,
              compact: true,
              onPressed: _onStartMission,
            ),
          )
        : null;

    if (line.isMayor) {
      return MobileMayorDialogueStack(
        width: w,
        text: _shownText,
        mayorIn: _mayorIn,
        mayorAccent: _mayorAccent,
        showContinueHint: !_typing && !_showReady,
        aboveDialogue: startBtn,
      );
    }

    return _MobileCaptainStack(
      width: w,
      text: _shownText,
      speaker: line.speaker,
      accent: line.accent,
      castIn: _captainIn,
      showContinueHint: !_typing && !_showReady,
      aboveDialogue: startBtn,
    );
  }
}

class _MobileCaptainStack extends StatelessWidget {
  const _MobileCaptainStack({
    required this.width,
    required this.text,
    required this.speaker,
    required this.accent,
    required this.castIn,
    required this.showContinueHint,
    this.aboveDialogue,
  });

  final double width;
  final String text;
  final String speaker;
  final Color accent;
  final Animation<double> castIn;
  final bool showContinueHint;
  final Widget? aboveDialogue;

  @override
  Widget build(BuildContext context) {
    const double textPanelMinH = 96;
    const double tagH = 32;
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
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (aboveDialogue != null) ...<Widget>[
              aboveDialogue!,
              const SizedBox(height: 14),
            ],
            Padding(
              padding: const EdgeInsets.only(top: tagH - 4),
              child: DialogueBox(
                text: text,
                accent: accent,
                showContinueHint: showContinueHint,
                showSpeakerName: false,
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          bottom: textPanelMinH,
          child: SpeakerNameTag(
            name: speaker,
            accent: accent,
            compact: true,
          ),
        ),
      ],
    );
  }
}
