import 'dart:async';

import 'package:flutter/material.dart';

import '../models/game_character.dart';
import '../models/town_location.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/pixel_button.dart';
import 'sorting_screen.dart';

/// Short bridge cinematic between Phase 1 (puzzle) and Phase 2 (sorting).
///
/// The camera pans across the littered park while the Mayor praises the player
/// and introduces the sorting challenge.
class ParkSortTransitionScreen extends StatefulWidget {
  const ParkSortTransitionScreen({
    super.key,
    required this.character,
    required this.location,
  });

  final GameCharacter character;
  final TownLocation location;

  @override
  State<ParkSortTransitionScreen> createState() =>
      _ParkSortTransitionScreenState();
}

class _ParkSortTransitionScreenState extends State<ParkSortTransitionScreen>
    with TickerProviderStateMixin {
  static const Color _mayorAccent = Color(0xFF3949AB);
  static const String _line =
      "Great! Now let's sort the waste.";

  static const Duration _charTick = Duration(milliseconds: 30);
  static const Duration _pauseAfterLine = Duration(milliseconds: 900);

  late final AnimationController _pan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  late final AnimationController _mayorIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  String _shownText = '';
  bool _typing = false;
  bool _showReady = false;

  Timer? _typeTimer;
  Timer? _pauseTimer;

  @override
  void initState() {
    super.initState();
    _pan.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _mayorIn.forward();
      }
    });
    _mayorIn.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _typeLine(_line);
      }
    });
    _pan.forward();
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _pauseTimer?.cancel();
    _pan.dispose();
    _mayorIn.dispose();
    super.dispose();
  }

  void _typeLine(String full) {
    _typeTimer?.cancel();
    setState(() {
      _shownText = '';
      _typing = true;
      _showReady = false;
    });
    int shown = 0;
    _typeTimer = Timer.periodic(_charTick, (Timer timer) {
      if (shown >= full.length) {
        timer.cancel();
        setState(() => _typing = false);
        _pauseTimer = Timer(_pauseAfterLine, () {
          if (mounted) setState(() => _showReady = true);
        });
        return;
      }
      shown++;
      setState(() => _shownText = full.substring(0, shown));
    });
  }

  void _onTap() {
    if (_showReady) return;
    if (_typing) {
      _typeTimer?.cancel();
      _pauseTimer?.cancel();
      setState(() {
        _shownText = _line;
        _typing = false;
      });
      _pauseTimer = Timer(_pauseAfterLine, () {
        if (mounted) setState(() => _showReady = true);
      });
    } else if (_shownText.isNotEmpty) {
      _pauseTimer?.cancel();
      setState(() => _showReady = true);
    }
  }

  void _onStart() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SortingScreen(
          character: widget.character,
          location: widget.location,
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
            final double bgOpacityCap = compact ? 0.42 : 1.0;

            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                // Park background — slow horizontal pan.
                Positioned.fill(
                  child: ClipRect(
                    child: AnimatedBuilder(
                      animation: _pan,
                      builder: (BuildContext context, Widget? child) {
                        final double t = Curves.easeInOut.transform(_pan.value);
                        final double offsetX = -w * 0.12 * t;
                        final double opacity = compact
                            ? (0.08 + t * bgOpacityCap).clamp(0.0, bgOpacityCap)
                            : (0.2 + t * 0.8).clamp(0.0, 1.0);
                        return Transform.translate(
                          offset: Offset(offsetX, 0),
                          child: Transform.scale(
                            scale: 1.08,
                            child: Opacity(opacity: opacity, child: child),
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/images/png/park_trash_bg.png',
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

                // Mayor on desktop (mobile bust lives in the dialogue stack).
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

                // Phase label.
                Positioned(
                  top: 16,
                  left: 16,
                  child: SafeArea(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 10 : 14,
                        vertical: compact ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xF00E0E1A),
                        border: Border.all(
                          color: const Color(0xFF2B2B3A),
                          width: 3,
                        ),
                      ),
                      child: Text(
                        'Phase 2',
                        style: TextStyle(
                          fontFamily: 'Jersey10',
                          fontSize: compact ? 22 : 28,
                          height: 1,
                          color: const Color(0xFFFFCA28),
                        ),
                      ),
                    ),
                  ),
                ),

                // Dialogue + start button.
                if (_shownText.isNotEmpty)
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
                                  PixelButton(
                                    label: "Let's Sort!",
                                    icon: Icons.swap_vert,
                                    color: const Color(0xFF4CAF50),
                                    width: null,
                                    onPressed: _onStart,
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                DialogueBox(
                                  text: _shownText,
                                  speakerName: 'Mayor',
                                  accent: _mayorAccent,
                                  showContinueHint: !_typing && !_showReady,
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

  /// Ren'Py layering on mobile: mayor → text panel → speaker tag on top.
  Widget _buildMobileDialogueStack({required double w}) {
    const double textPanelMinH = 96;
    const double tagH = 32;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomLeft,
      children: <Widget>[
        // 1) Mayor bust (back layer).
        AnimatedBuilder(
          animation: _mayorIn,
          builder: (BuildContext context, Widget? child) {
            final double t = Curves.easeOut.transform(_mayorIn.value);
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
            'assets/images/png/char_mayor_cutout.png',
            width: w * 0.40,
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.none,
          ),
        ),

        // 2) Button + text panel (middle layer).
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_showReady) ...<Widget>[
              Center(
                child: PixelButton(
                  label: "Let's Sort!",
                  icon: Icons.swap_vert,
                  color: const Color(0xFF4CAF50),
                  width: null,
                  compact: true,
                  onPressed: _onStart,
                ),
              ),
              const SizedBox(height: 14),
            ],
            Padding(
              padding: const EdgeInsets.only(top: tagH - 4),
              child: DialogueBox(
                text: _shownText,
                accent: _mayorAccent,
                showContinueHint: !_typing && !_showReady,
                showSpeakerName: false,
              ),
            ),
          ],
        ),

        // 3) Speaker name tag (front layer, on top of mayor).
        const Positioned(
          left: 0,
          bottom: textPanelMinH,
          child: SpeakerNameTag(
            name: 'Mayor',
            accent: _mayorAccent,
            compact: true,
          ),
        ),
      ],
    );
  }
}
