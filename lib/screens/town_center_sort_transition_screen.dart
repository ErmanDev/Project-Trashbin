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

/// Bridge after Town Center Level 9 puzzle — leads into Phase 2 sorting.
class TownCenterSortTransitionScreen extends StatefulWidget {
  const TownCenterSortTransitionScreen({
    super.key,
    required this.character,
    required this.location,
  });

  final GameCharacter character;
  final TownLocation location;

  @override
  State<TownCenterSortTransitionScreen> createState() =>
      _TownCenterSortTransitionScreenState();
}

class _TownCenterSortTransitionScreenState
    extends State<TownCenterSortTransitionScreen>
    with TickerProviderStateMixin {
  static const Color _accent = Color(0xFF3949AB);
  static const String _line = "Now let's make this vision a reality.";

  static const Duration _charTick = Duration(milliseconds: 30);
  static const Duration _pauseAfterLine = Duration(milliseconds: 900);

  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final AnimationController _mayorIn = AnimationController(
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
        _mayorIn.forward();
      }
    });
    _mayorIn.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) _typeLine(_line);
    });
    _fade.forward();
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _pauseTimer?.cancel();
    _fade.dispose();
    _mayorIn.dispose();
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
          items: TownCenterSortingLevel9.items,
          bins: TownCenterSortingLevel9.bins,
          coinsPerCorrect: TownCenterSortingLevel9.coinsPerCorrect,
          levelTitle: TownCenterSortingLevel9.levelTitle,
          locationId: TownCenterSortingLevel9.locationId,
          levelNumber: TownCenterSortingLevel9.levelNumber,
          phaseLabel: 'Level 9 · Phase 2',
          backgroundAsset: GameProgress.townCenterTrashBg,
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
                      GameProgress.townCenterTrashBg,
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
                    animation: _mayorIn,
                    builder: (BuildContext context, Widget? child) {
                      final double t =
                          Curves.easeOut.transform(_mayorIn.value);
                      return Positioned(
                        bottom: 0 - (1 - t) * 36,
                        left: w * 0.04,
                        height: spriteHeight,
                        child: Opacity(opacity: t, child: child),
                      );
                    },
                    child: Image.asset(
                      GameProgress.mayorCutout,
                      filterQuality: FilterQuality.none,
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
                          ? MobileMayorDialogueStack(
                              width: w,
                              text: _shownText,
                              mayorIn: _mayorIn,
                              mayorAccent: _accent,
                              showContinueHint: !_typing && !_showReady,
                              aboveDialogue: _showReady
                                  ? Center(
                                      child: PixelButton(
                                        label: 'Start Sorting',
                                        icon: Icons.swap_vert,
                                        color: const Color(0xFF7E57C2),
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
                                      icon: Icons.swap_vert,
                                      color: const Color(0xFF7E57C2),
                                      width: null,
                                      onPressed: _onStart,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                DialogueBox(
                                  text: _shownText,
                                  speakerName: 'Mayor',
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
