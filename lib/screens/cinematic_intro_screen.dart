import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_character.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/pixel_button.dart';
import 'town_map_screen.dart';

/// A single spoken line in the intro. Keeping a speaker + accent per line
/// means the dialogue system already supports switching between speakers,
/// even though for now only the Mayor talks.
class _Line {
  const _Line(this.speaker, this.accent, this.text);
  final String speaker;
  final Color accent;
  final String text;
}

/// Ren'Py-style story introduction played after character creation.
///
/// Fades into a polluted Green Town, the Mayor walks toward the player, then
/// he delivers his lines one at a time (auto-advancing after a 1s pause). When
/// he finishes, an "I'm Ready" button appears to enter the game.
class CinematicIntroScreen extends StatefulWidget {
  const CinematicIntroScreen({super.key, required this.character});

  final GameCharacter character;

  @override
  State<CinematicIntroScreen> createState() => _CinematicIntroScreenState();
}

class _CinematicIntroScreenState extends State<CinematicIntroScreen>
    with TickerProviderStateMixin {
  static const Color _mayorAccent = Color(0xFF3949AB);

  static const List<_Line> _lines = <_Line>[
    _Line('Mayor', _mayorAccent, 'Welcome to Green Town.'),
    _Line('Mayor', _mayorAccent, 'Our town used to be beautiful.'),
    _Line('Mayor', _mayorAccent, 'People stopped sorting their waste.'),
    _Line('Mayor', _mayorAccent, 'Now every district is covered in garbage.'),
    _Line('Mayor', _mayorAccent, 'Can you help restore our town?'),
  ];

  static const Duration _pauseBetweenLines = Duration(seconds: 1);
  static const Duration _charTick = Duration(milliseconds: 24);

  late final AnimationController _sceneFade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final AnimationController _walk = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  int _lineIndex = -1; // -1 = dialogue not started yet (still walking)
  String _shownText = '';
  bool _typing = false;
  bool _showReady = false;

  Timer? _typeTimer;
  Timer? _pauseTimer;

  @override
  void initState() {
    super.initState();

    _sceneFade.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _walk.forward();
      }
    });
    _walk.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _startDialogue();
      }
    });

    _sceneFade.forward();
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _pauseTimer?.cancel();
    _sceneFade.dispose();
    _walk.dispose();
    super.dispose();
  }

  void _startDialogue() => _advanceLine();

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

  /// Tap to speed things up, Ren'Py style: finish the current line instantly,
  /// or skip the pause to the next line.
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

  void _onReady() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: TownMapScreen.routeName),
        builder: (BuildContext context) =>
            TownMapScreen(character: widget.character),
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
            final double spriteHeight = h * 0.74;

            return Stack(
              children: <Widget>[
                // Polluted town background, fading in.
                Positioned.fill(
                  child: FadeTransition(
                    opacity: _sceneFade,
                    child: Image.asset(
                      'assets/images/png/polluted_town_bg.png',
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                ),
                // Gloomy vignette overlay.
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        radius: 1.1,
                        colors: <Color>[Colors.transparent, Color(0x66000000)],
                        stops: <double>[0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // The player's chosen character, standing to the right.
                Positioned(
                  bottom: 0,
                  right: w * 0.06,
                  height: spriteHeight,
                  child: FadeTransition(
                    opacity: _sceneFade,
                    child: Image.asset(
                      widget.character.cutoutAsset,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                ),

                // The Mayor walks in from the left.
                AnimatedBuilder(
                  animation: _walk,
                  builder: (BuildContext context, Widget? child) {
                    final double startLeft = -w * 0.45;
                    final double endLeft = w * 0.24;
                    final double left =
                        startLeft + (endLeft - startLeft) * _walk.value;
                    // Subtle walking bob while moving.
                    final double bob = _walk.isAnimating
                        ? math.sin(_walk.value * math.pi * 8) * 5
                        : 0;
                    return Positioned(
                      bottom: 0 - bob,
                      left: left,
                      height: spriteHeight,
                      child: Opacity(
                        opacity: _sceneFade.value,
                        child: child,
                      ),
                    );
                  },
                  child: Image.asset(
                    'assets/images/png/char_mayor_cutout.png',
                    filterQuality: FilterQuality.none,
                  ),
                ),

                // Initial fade-from-black.
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _sceneFade,
                      builder: (BuildContext context, _) => ColoredBox(
                        color: Colors.black
                            .withValues(alpha: 1 - _sceneFade.value),
                      ),
                    ),
                  ),
                ),

                // Dialogue + ready button anchored to the bottom.
                if (_lineIndex >= 0)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (_showReady) ...<Widget>[
                            PixelButton(
                              label: "I'm Ready",
                              icon: Icons.check,
                              color: const Color(0xFF4CAF50),
                              width: 280,
                              onPressed: _onReady,
                            ),
                            const SizedBox(height: 14),
                          ],
                          DialogueBox(
                            text: _shownText,
                            speakerName: _lines[_lineIndex].speaker,
                            accent: _lines[_lineIndex].accent,
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
}
