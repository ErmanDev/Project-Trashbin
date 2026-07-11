import 'dart:async';

import 'package:flutter/material.dart';

import '../models/game_character.dart';
import '../models/game_progress.dart';
import '../models/sorting_item.dart';
import '../models/town_location.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/pixel_button.dart';
import 'sorting_screen.dart';

/// Bridge after Beach Level 7 puzzle — leads into shore sorting (next).
class BeachSortTransitionScreen extends StatefulWidget {
  const BeachSortTransitionScreen({
    super.key,
    required this.character,
    required this.location,
  });

  final GameCharacter character;
  final TownLocation location;

  @override
  State<BeachSortTransitionScreen> createState() =>
      _BeachSortTransitionScreenState();
}

class _BeachSortTransitionScreenState extends State<BeachSortTransitionScreen>
    with TickerProviderStateMixin {
  static const Color _accent = Color(0xFF00838F);
  static const String _line = "Now let's remove the waste from the beach.";

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
          items: BeachSortingLevel7.items,
          bins: BeachSortingLevel7.bins,
          coinsPerCorrect: BeachSortingLevel7.coinsPerCorrect,
          levelTitle: BeachSortingLevel7.levelTitle,
          locationId: BeachSortingLevel7.locationId,
          levelNumber: BeachSortingLevel7.levelNumber,
          phaseLabel: 'Level 7 · Phase 2',
          backgroundAsset: GameProgress.beachTrashBg,
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
        behavior: HitTestBehavior.opaque,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double w = constraints.maxWidth;
            final double h = constraints.maxHeight;
            final bool compact = h < 420;
            final double spriteHeight = h * (compact ? 0.55 : 0.72);

            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: FadeTransition(
                    opacity: _fade,
                    child: Image.asset(
                      GameProgress.beachTrashBg,
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
                        left: w * 0.04,
                        height: spriteHeight,
                        child: Opacity(opacity: t, child: child),
                      );
                    },
                    child: Transform.flip(
                      flipX: true,
                      child: Image.asset(
                        GameProgress.rangerCutout,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                if (_shownText.isNotEmpty)
                  Positioned(
                    left: compact ? 10 : 16,
                    right: compact ? 10 : 16,
                    bottom: compact ? 10 : 16,
                    child: SafeArea(
                      top: false,
                      child: compact
                          ? _MobileRangerStack(
                              width: w,
                              text: _shownText,
                              castIn: _castIn,
                              showContinueHint: !_typing && !_showReady,
                              aboveDialogue: _showReady
                                  ? Center(
                                      child: PixelButton(
                                        label: 'Start Sorting',
                                        icon: Icons.waves,
                                        color: const Color(0xFF29B6F6),
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
                                      label: 'Start Sorting',
                                      icon: Icons.waves,
                                      color: const Color(0xFF29B6F6),
                                      width: null,
                                      onPressed: _onStart,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                DialogueBox(
                                  text: _shownText,
                                  speakerName: 'Marine Ranger',
                                  accent: _accent,
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

class _MobileRangerStack extends StatelessWidget {
  const _MobileRangerStack({
    required this.width,
    required this.text,
    required this.castIn,
    required this.showContinueHint,
    this.aboveDialogue,
  });

  final double width;
  final String text;
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
                    child: Transform.flip(flipX: true, child: child),
                  ),
                ),
              ),
            );
          },
          child: Image.asset(
            GameProgress.rangerCutout,
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
                accent: const Color(0xFF00838F),
                showContinueHint: showContinueHint,
                showSpeakerName: false,
              ),
            ),
          ],
        ),
        const Positioned(
          left: 0,
          bottom: textPanelMinH,
          child: SpeakerNameTag(
            name: 'Marine Ranger',
            accent: Color(0xFF00838F),
            compact: true,
          ),
        ),
      ],
    );
  }
}
