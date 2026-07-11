import 'dart:async';

import 'package:flutter/material.dart';

import '../models/game_character.dart';
import '../models/game_progress.dart';
import '../models/town_location.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/pixel_button.dart';
import 'puzzle_screen.dart';
import 'school_sort_transition_screen.dart';

class _Line {
  const _Line(this.speaker, this.accent, this.text);
  final String speaker;
  final Color accent;
  final String text;
}

/// School District intro cinematic (Levels 3–4 entry).
///
/// Zooms into the untidy campus, then the Principal speaks.
/// Ends with Start Mission.
class SchoolIntroScreen extends StatefulWidget {
  const SchoolIntroScreen({
    super.key,
    required this.character,
    required this.location,
  });

  final GameCharacter character;
  final TownLocation location;

  @override
  State<SchoolIntroScreen> createState() => _SchoolIntroScreenState();
}

class _SchoolIntroScreenState extends State<SchoolIntroScreen>
    with TickerProviderStateMixin {
  static const Color _principalAccent = Color(0xFF00897B);

  static const List<_Line> _lines = <_Line>[
    _Line(
      'Principal',
      _principalAccent,
      'Thank you for helping restore the park.',
    ),
    _Line(
      'Principal',
      _principalAccent,
      "Our students want a clean place to learn, but many people don't know how to separate their waste.",
    ),
    _Line(
      'Principal',
      _principalAccent,
      "Today you'll learn something new—some waste can become compost instead of ending up in landfills.",
    ),
  ];

  static const Duration _pauseBetweenLines = Duration(milliseconds: 900);
  static const Duration _charTick = Duration(milliseconds: 28);

  late final AnimationController _zoom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final AnimationController _castIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
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
    _zoom.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _castIn.forward();
      }
    });
    _castIn.addStatusListener((AnimationStatus status) {
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
    _castIn.dispose();
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

  void _onStartMission() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => PuzzleScreen(
          character: widget.character,
          location: widget.location,
          imageAsset: 'assets/images/png/bin_compost.png',
          itemName: 'Compost Bin',
          gridSize: 3,
          backgroundAsset: GameProgress.schoolTrashBg,
          nextBuilder: (BuildContext context) => SchoolSortTransitionScreen(
            character: widget.character,
            location: widget.location,
          ),
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
                        GameProgress.schoolTrashBg,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                ),

                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        radius: 1.1,
                        colors: <Color>[
                          Colors.transparent,
                          Color(compact ? 0x77000000 : 0x55000000),
                        ],
                        stops: const <double>[0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                if (compact)
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Colors.transparent,
                            Color(0x66000000),
                            Color(0xAA000000),
                          ],
                          stops: <double>[0.35, 0.72, 1.0],
                        ),
                      ),
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

                // Desktop: Principal walks in from the left.
                if (!compact)
                  AnimatedBuilder(
                    animation: _castIn,
                    builder: (BuildContext context, Widget? child) {
                      final double t =
                          Curves.easeOut.transform(_castIn.value);
                      return Positioned(
                        bottom: 0 - (1 - t) * 36,
                        left: w * 0.05,
                        height: spriteHeight,
                        child: Opacity(opacity: t, child: child),
                      );
                    },
                    child: Image.asset(
                      GameProgress.principalCutout,
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
                          ? _buildMobileDialogueStack(w: w)
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

  /// Mobile: Principal bust behind dialogue, Ren'Py layering.
  Widget _buildMobileDialogueStack({required double w}) {
    const double textPanelMinH = 96;
    const double tagH = 32;
    final _Line line = _lines[_lineIndex];

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomLeft,
      children: <Widget>[
        AnimatedBuilder(
          animation: _castIn,
          builder: (BuildContext context, Widget? child) {
            final double t = Curves.easeOut.transform(_castIn.value);
            return Positioned(
              left: 0,
              bottom: textPanelMinH - 8,
              width: w * 0.40,
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
            width: w * 0.40,
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.none,
          ),
        ),

        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_showReady) ...<Widget>[
              Center(
                child: PixelButton(
                  label: 'Start Mission',
                  icon: Icons.flag,
                  color: const Color(0xFFFFB300),
                  width: null,
                  compact: true,
                  onPressed: _onStartMission,
                ),
              ),
              const SizedBox(height: 14),
            ],
            Padding(
              padding: const EdgeInsets.only(top: tagH - 4),
              child: DialogueBox(
                text: _shownText,
                accent: line.accent,
                showContinueHint: !_typing && !_showReady,
                showSpeakerName: false,
              ),
            ),
          ],
        ),

        Positioned(
          left: 0,
          bottom: textPanelMinH,
          child: SpeakerNameTag(
            name: line.speaker,
            accent: line.accent,
            compact: true,
          ),
        ),
      ],
    );
  }
}
