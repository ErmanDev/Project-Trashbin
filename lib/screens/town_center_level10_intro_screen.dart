import 'dart:async';

import 'package:flutter/material.dart';

import '../models/game_character.dart';
import '../models/game_progress.dart';
import '../models/sorting_item.dart';
import '../models/town_location.dart';
import '../widgets/dialogue_box.dart';
import '../widgets/pixel_button.dart';
import 'sorting_screen.dart';

class _DialogueBeat {
  const _DialogueBeat({
    required this.speaker,
    required this.line,
    required this.asset,
    required this.accent,
    this.flipX = false,
  });

  final String speaker;
  final String line;
  final String asset;
  final Color accent;
  final bool flipX;
}

/// Level 10 intro — the full cast gathers before Green Town's final challenge.
class TownCenterLevel10IntroScreen extends StatefulWidget {
  const TownCenterLevel10IntroScreen({
    super.key,
    required this.character,
    required this.location,
  });

  final GameCharacter character;
  final TownLocation location;

  @override
  State<TownCenterLevel10IntroScreen> createState() =>
      _TownCenterLevel10IntroScreenState();
}

class _TownCenterLevel10IntroScreenState
    extends State<TownCenterLevel10IntroScreen> with TickerProviderStateMixin {
  static const Color _mayorAccent = Color(0xFF3949AB);
  static const Color _principalAccent = Color(0xFF8D6E63);
  static const Color _captainAccent = Color(0xFFEC407A);
  static const Color _rangerAccent = Color(0xFF00838F);

  static const List<_DialogueBeat> _beats = <_DialogueBeat>[
    _DialogueBeat(
      speaker: 'Mayor',
      line: 'You taught us that every piece of waste matters.',
      asset: GameProgress.mayorCutout,
      accent: _mayorAccent,
    ),
    _DialogueBeat(
      speaker: 'Principal',
      line: 'Our students now recycle every day.',
      asset: GameProgress.principalCutout,
      accent: _principalAccent,
    ),
    _DialogueBeat(
      speaker: 'Barangay Captain',
      line: 'Families now separate their household waste.',
      asset: GameProgress.barangayCutout,
      accent: _captainAccent,
      flipX: true,
    ),
    _DialogueBeat(
      speaker: 'Marine Ranger',
      line: 'Our beaches are alive again.',
      asset: GameProgress.rangerCutout,
      accent: _rangerAccent,
      flipX: true,
    ),
    _DialogueBeat(
      speaker: 'Mayor',
      line: 'One final task remains.',
      asset: GameProgress.mayorCutout,
      accent: _mayorAccent,
    ),
  ];

  static const List<({String asset, bool flipX})> _gatherCast =
      <({String asset, bool flipX})>[
    (asset: GameProgress.principalCutout, flipX: false),
    (asset: GameProgress.barangayCutout, flipX: true),
    (asset: GameProgress.mayorCutout, flipX: false),
    (asset: GameProgress.rangerCutout, flipX: true),
    (asset: GameProgress.residentCutout, flipX: false),
    (asset: GameProgress.childCutout, flipX: false),
  ];

  static const Duration _charTick = Duration(milliseconds: 28);
  static const Duration _pause = Duration(milliseconds: 900);

  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final AnimationController _gather = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final AnimationController _castIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final AnimationController _dim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  int _beatIndex = -1;
  String _shownText = '';
  bool _typing = false;
  bool _showReady = false;
  bool _gathering = true;
  Timer? _typeTimer;
  Timer? _pauseTimer;

  @override
  void initState() {
    super.initState();
    _fade.addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.completed) {
        _dim.forward();
        _gather.forward();
      }
    });
    _gather.addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.completed && mounted) {
        Future<void>.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          setState(() => _gathering = false);
          _castIn.forward(from: 0);
          _advance();
        });
      }
    });
    _fade.forward();
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _pauseTimer?.cancel();
    _fade.dispose();
    _gather.dispose();
    _castIn.dispose();
    _dim.dispose();
    super.dispose();
  }

  void _advance() {
    final int next = _beatIndex + 1;
    if (next >= _beats.length) {
      setState(() => _showReady = true);
      return;
    }
    setState(() => _beatIndex = next);
    if (next > 0) {
      _castIn.forward(from: 0);
    }
    _type(_beats[next].line);
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
    if (_gathering || _showReady || _beatIndex < 0) return;
    if (_typing) {
      _typeTimer?.cancel();
      _pauseTimer?.cancel();
      setState(() {
        _shownText = _beats[_beatIndex].line;
        _typing = false;
      });
      _pauseTimer = Timer(_pause, _advance);
    } else {
      _pauseTimer?.cancel();
      _advance();
    }
  }

  void _onBegin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SortingScreen(
          character: widget.character,
          location: widget.location,
          items: TownCenterSortingLevel10.items,
          bins: TownCenterSortingLevel10.bins,
          coinsPerCorrect: TownCenterSortingLevel10.coinsPerCorrect,
          levelTitle: TownCenterSortingLevel10.levelTitle,
          locationId: TownCenterSortingLevel10.locationId,
          levelNumber: TownCenterSortingLevel10.levelNumber,
          phaseLabel: 'Level 10',
          backgroundAsset: GameProgress.townCenterCleanBg,
          endWithQuietFade: true,
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
          builder: (BuildContext context, BoxConstraints c) {
            final bool compact = c.maxHeight < 420;
            final double w = c.maxWidth;
            final double h = c.maxHeight;
            final _DialogueBeat? beat =
                _beatIndex >= 0 ? _beats[_beatIndex] : null;
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: FadeTransition(
                    opacity: _fade,
                    child: Image.asset(
                      GameProgress.townCenterCleanBg,
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
                          alpha: 0.28 * _dim.value,
                        ),
                      );
                    },
                  ),
                ),
                // Keep the gathered cast on screen through dialogue.
                AnimatedBuilder(
                  animation: _gather,
                  builder: (BuildContext context, _) {
                    final double gatherT = _gathering ? _gather.value : 1.0;
                    return Opacity(
                      opacity: _gathering
                          ? 1.0
                          : (compact ? 0.35 : 0.55),
                      child: _GatheringCast(
                        progress: gatherT,
                        compact: compact,
                        width: w,
                        height: h,
                        cast: _gatherCast,
                        highlightAsset: beat?.asset,
                      ),
                    );
                  },
                ),
                if (_gathering)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: compact ? 12 : 20,
                    child: SafeArea(
                      bottom: false,
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _gather,
                          builder: (BuildContext context, _) {
                            final double t = Curves.easeOut.transform(
                              ((_gather.value - 0.35) / 0.45).clamp(0.0, 1.0),
                            );
                            return Opacity(
                              opacity: t,
                              child: _CaptionChip(
                                text: 'Everyone stands together.',
                                compact: compact,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                if (!_gathering && beat != null && !compact)
                  Positioned(
                    bottom: 0,
                    left: w * 0.05,
                    height: h * 0.72,
                    child: AnimatedBuilder(
                      animation: _castIn,
                      builder: (BuildContext context, Widget? child) {
                        final double t =
                            Curves.easeOut.transform(_castIn.value);
                        return Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, (1 - t) * 36),
                            child: child,
                          ),
                        );
                      },
                      child: Transform.flip(
                        flipX: beat.flipX,
                        child: Image.asset(
                          beat.asset,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                    ),
                  ),
                if (!_gathering && beat != null)
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
                                label: 'Begin',
                                icon: Icons.flag,
                                color: const Color(0xFF5C6BC0),
                                width: null,
                                compact: compact,
                                onPressed: _onBegin,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (compact)
                            _MobileSpeakerStack(
                              width: w,
                              text: _shownText,
                              castIn: _castIn,
                              beat: beat,
                              showHint: !_typing && !_showReady,
                            )
                          else
                            DialogueBox(
                              text: _shownText,
                              speakerName: beat.speaker,
                              accent: beat.accent,
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

class _CaptionChip extends StatelessWidget {
  const _CaptionChip({required this.text, required this.compact});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 18,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xE00E0E1A),
        border: Border.all(color: const Color(0xFF5C6BC0), width: 3),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Jersey10',
          fontSize: compact ? 16 : 22,
          height: 1,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _GatheringCast extends StatelessWidget {
  const _GatheringCast({
    required this.progress,
    required this.compact,
    required this.width,
    required this.height,
    required this.cast,
    this.highlightAsset,
  });

  final double progress;
  final bool compact;
  final double width;
  final double height;
  final List<({String asset, bool flipX})> cast;
  final String? highlightAsset;

  @override
  Widget build(BuildContext context) {
    final double spriteH = compact ? height * 0.42 : height * 0.55;
    final double slotW = width / (cast.length + 0.4);

    return IgnorePointer(
      child: Stack(
        children: List<Widget>.generate(cast.length, (int i) {
          final double stagger = (i / cast.length) * 0.35;
          final double t = Curves.easeOut.transform(
            ((progress - stagger) / 0.55).clamp(0.0, 1.0),
          );
          final ({String asset, bool flipX}) member = cast[i];
          final bool highlighted =
              highlightAsset != null && member.asset == highlightAsset;
          final double x = slotW * (i + 0.2);
          return Positioned(
            left: x,
            bottom: (1 - t) * 40,
            width: slotW * 0.95,
            height: spriteH,
            child: Opacity(
              opacity: t * (highlighted ? 1.0 : 0.85),
              child: Transform.scale(
                scale: highlighted ? 1.08 : 1.0,
                alignment: Alignment.bottomCenter,
                child: Transform.flip(
                  flipX: member.flipX,
                  child: Image.asset(
                    member.asset,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    filterQuality: FilterQuality.none,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MobileSpeakerStack extends StatelessWidget {
  const _MobileSpeakerStack({
    required this.width,
    required this.text,
    required this.castIn,
    required this.beat,
    required this.showHint,
  });

  final double width;
  final String text;
  final Animation<double> castIn;
  final _DialogueBeat beat;
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
                    child: Transform.flip(flipX: beat.flipX, child: child),
                  ),
                ),
              ),
            );
          },
          child: Image.asset(
            beat.asset,
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
            accent: beat.accent,
            showContinueHint: showHint,
            showSpeakerName: false,
          ),
        ),
        Positioned(
          left: 0,
          bottom: textPanelMinH,
          child: SpeakerNameTag(
            name: beat.speaker,
            accent: beat.accent,
            compact: true,
          ),
        ),
      ],
    );
  }
}
