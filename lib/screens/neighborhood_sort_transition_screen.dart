import 'dart:async';

import 'package:flutter/material.dart';

import '../models/game_character.dart';
import '../models/game_progress.dart';
import '../models/town_location.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/pixel_button.dart';
import '../models/sorting_item.dart';
import 'sorting_screen.dart';

/// Bridge after Neighborhood Level 5 puzzle — leads into sorting (next).
class NeighborhoodSortTransitionScreen extends StatefulWidget {
  const NeighborhoodSortTransitionScreen({
    super.key,
    required this.character,
    required this.location,
  });

  final GameCharacter character;
  final TownLocation location;

  @override
  State<NeighborhoodSortTransitionScreen> createState() =>
      _NeighborhoodSortTransitionScreenState();
}

class _NeighborhoodSortTransitionScreenState
    extends State<NeighborhoodSortTransitionScreen>
    with TickerProviderStateMixin {
  static const Color _accent = Color(0xFFEC407A);
  static const String _line =
      "Great! Now let's organize the neighborhood's waste.";

  static const Duration _charTick = Duration(milliseconds: 30);
  static const Duration _pauseAfterLine = Duration(milliseconds: 900);

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

  String _shownText = '';
  bool _typing = false;
  bool _showReady = false;
  Timer? _typeTimer;
  Timer? _pauseTimer;

  @override
  void initState() {
    super.initState();
    _fade.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _dim.forward();
        _castIn.forward();
      }
    });
    _castIn.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) _typeLine(_line);
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
          items: NeighborhoodSortingLevel5.items,
          bins: NeighborhoodSortingLevel5.bins,
          coinsPerCorrect: NeighborhoodSortingLevel5.coinsPerCorrect,
          levelTitle: NeighborhoodSortingLevel5.levelTitle,
          locationId: NeighborhoodSortingLevel5.locationId,
          levelNumber: NeighborhoodSortingLevel5.levelNumber,
          phaseLabel: 'Level 5',
          backgroundAsset: GameProgress.neighborhoodTrashBg,
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
              children: <Widget>[
                Positioned.fill(
                  child: FadeTransition(
                    opacity: _fade,
                    child: Image.asset(
                      GameProgress.neighborhoodTrashBg,
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
                        bottom: 0 - (1 - t) * 40,
                        left: w * 0.05,
                        height: spriteHeight,
                        child: Opacity(opacity: t, child: child),
                      );
                    },
                    child: Image.asset(
                      GameProgress.barangayCutout,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                if (_shownText.isNotEmpty || _showReady)
                  Positioned(
                    left: compact ? 10 : 16,
                    right: compact ? 10 : 16,
                    bottom: compact ? 10 : 16,
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
                            const SizedBox(height: 14),
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
