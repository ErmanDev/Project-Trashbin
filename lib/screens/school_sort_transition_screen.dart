import 'dart:async';

import 'package:flutter/material.dart';

import '../models/game_character.dart';
import '../models/game_progress.dart';
import '../models/sorting_item.dart';
import '../models/town_location.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/pixel_button.dart';
import 'sorting_screen.dart';

/// Bridge between School Level 3 puzzle and sorting.
class SchoolSortTransitionScreen extends StatefulWidget {
  const SchoolSortTransitionScreen({
    super.key,
    required this.character,
    required this.location,
  });

  final GameCharacter character;
  final TownLocation location;

  @override
  State<SchoolSortTransitionScreen> createState() =>
      _SchoolSortTransitionScreenState();
}

class _SchoolSortTransitionScreenState extends State<SchoolSortTransitionScreen>
    with TickerProviderStateMixin {
  static const Color _accent = Color(0xFF00897B);
  static const String _line =
      "Great! Now let's sort the campus waste—watch for compost!";

  static const Duration _charTick = Duration(milliseconds: 30);
  static const Duration _pauseAfterLine = Duration(milliseconds: 900);

  late final AnimationController _pan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  late final AnimationController _castIn = AnimationController(
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
      if (status == AnimationStatus.completed) _castIn.forward();
    });
    _castIn.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) _typeLine(_line);
    });
    _pan.forward();
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _pauseTimer?.cancel();
    _pan.dispose();
    _castIn.dispose();
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
          items: SchoolSortingLevel3.items,
          bins: SchoolSortingLevel3.bins,
          coinsPerCorrect: SchoolSortingLevel3.coinsPerCorrect,
          levelTitle: SchoolSortingLevel3.levelTitle,
          locationId: SchoolSortingLevel3.locationId,
          levelNumber: SchoolSortingLevel3.levelNumber,
          phaseLabel: 'Level 3',
          backgroundAsset: GameProgress.schoolTrashBg,
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
                  child: ClipRect(
                    child: AnimatedBuilder(
                      animation: _pan,
                      builder: (BuildContext context, Widget? child) {
                        final double t = _pan.value;
                        return Transform.translate(
                          offset: Offset((0.5 - t) * w * 0.15, 0),
                          child: Transform.scale(
                            scale: 1.08,
                            child: Opacity(
                              opacity: compact
                                  ? (0.35 + t * 0.4).clamp(0.0, 0.75)
                                  : 1,
                              child: child,
                            ),
                          ),
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
                      GameProgress.principalCutout,
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
                            _MobilePrincipalStack(
                              width: w,
                              text: _shownText,
                              castIn: _castIn,
                              showHint: !_typing && !_showReady,
                            )
                          else
                            DialogueBox(
                              text: _shownText,
                              speakerName: 'Principal',
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

class _MobilePrincipalStack extends StatelessWidget {
  const _MobilePrincipalStack({
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
            showContinueHint: showHint,
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
