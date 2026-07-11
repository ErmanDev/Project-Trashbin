import 'dart:async';

import 'package:flutter/material.dart';

import '../models/game_character.dart';
import '../models/game_progress.dart';
import '../models/sorting_item.dart';
import '../models/town_location.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/pixel_button.dart';
import 'sorting_screen.dart';

/// Short Captain intro before Neighborhood Level 6 sorting (no puzzle).
class NeighborhoodLevel6IntroScreen extends StatefulWidget {
  const NeighborhoodLevel6IntroScreen({
    super.key,
    required this.character,
    required this.location,
  });

  final GameCharacter character;
  final TownLocation location;

  @override
  State<NeighborhoodLevel6IntroScreen> createState() =>
      _NeighborhoodLevel6IntroScreenState();
}

class _NeighborhoodLevel6IntroScreenState
    extends State<NeighborhoodLevel6IntroScreen> with TickerProviderStateMixin {
  static const Color _accent = Color(0xFFEC407A);
  static const List<String> _lines = <String>[
    "You're getting better at sorting hazardous waste!",
    "Let's finish cleaning our neighborhood streets.",
  ];

  static const Duration _charTick = Duration(milliseconds: 28);
  static const Duration _pause = Duration(milliseconds: 850);

  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final AnimationController _castIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final AnimationController _dim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
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
    _fade.addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.completed) {
        _dim.forward();
        _castIn.forward();
      }
    });
    _castIn.addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.completed) _advance();
    });
    _fade.forward();
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _pauseTimer?.cancel();
    _fade.dispose();
    _castIn.dispose();
    _dim.dispose();
    super.dispose();
  }

  void _advance() {
    final int next = _lineIndex + 1;
    if (next >= _lines.length) {
      setState(() => _showReady = true);
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
    _typeTimer = Timer.periodic(_charTick, (Timer t) {
      if (i >= full.length) {
        t.cancel();
        setState(() => _typing = false);
        _pauseTimer = Timer(_pause, _advance);
        return;
      }
      i++;
      setState(() => _shownText = full.substring(0, i));
    });
  }

  void _onTap() {
    if (_showReady || _lineIndex < 0) return;
    if (_typing) {
      _typeTimer?.cancel();
      _pauseTimer?.cancel();
      setState(() {
        _shownText = _lines[_lineIndex];
        _typing = false;
      });
      _pauseTimer = Timer(_pause, _advance);
    } else {
      _pauseTimer?.cancel();
      _advance();
    }
  }

  void _onStart() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SortingScreen(
          character: widget.character,
          location: widget.location,
          items: NeighborhoodSortingLevel6.items,
          bins: NeighborhoodSortingLevel6.bins,
          coinsPerCorrect: NeighborhoodSortingLevel6.coinsPerCorrect,
          levelTitle: NeighborhoodSortingLevel6.levelTitle,
          locationId: NeighborhoodSortingLevel6.locationId,
          levelNumber: NeighborhoodSortingLevel6.levelNumber,
          phaseLabel: 'Level 6',
          backgroundAsset: GameProgress.neighborhoodCleanBg,
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
          builder: (BuildContext context, BoxConstraints c) {
            final bool compact = c.maxHeight < 420;
            final double w = c.maxWidth;
            final double h = c.maxHeight;
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: FadeTransition(
                    opacity: _fade,
                    child: Image.asset(
                      GameProgress.neighborhoodCleanBg,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.none,
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
                if (!compact)
                  AnimatedBuilder(
                    animation: _castIn,
                    builder: (BuildContext context, Widget? child) {
                      final double t =
                          Curves.easeOut.transform(_castIn.value);
                      return Positioned(
                        bottom: 0 - (1 - t) * 36,
                        left: w * 0.05,
                        height: h * 0.72,
                        child: Opacity(opacity: t, child: child),
                      );
                    },
                    child: Image.asset(
                      GameProgress.barangayCutout,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                if (_lineIndex >= 0)
                  Positioned(
                    left: compact ? 10 : 12,
                    right: compact ? 10 : 12,
                    bottom: compact ? 10 : 12,
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (_showReady) ...<Widget>[
                            Center(
                              child: PixelButton(
                                label: "Let's Sort!",
                                icon: Icons.swap_vert,
                                color: const Color(0xFF4CAF50),
                                width: null,
                                compact: compact,
                                onPressed: _onStart,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (compact)
                            _MobileCaptainStack(
                              width: w,
                              text: _shownText,
                              castIn: _castIn,
                              showHint: !_typing && !_showReady,
                            )
                          else
                            DialogueBox(
                              text: _shownText,
                              speakerName: 'Barangay Captain',
                              accent: _accent,
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

class _MobileCaptainStack extends StatelessWidget {
  const _MobileCaptainStack({
    required this.width,
    required this.text,
    required this.castIn,
    required this.showHint,
  });

  final double width;
  final String text;
  final Animation<double> castIn;
  final bool showHint;

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
            showContinueHint: showHint,
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
