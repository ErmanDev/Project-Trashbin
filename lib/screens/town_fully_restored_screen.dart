import 'package:flutter/material.dart';

import '../models/game_character.dart';
import '../models/game_progress.dart';
import '../services/audio_manager.dart';
import '../widgets/confetti_overlay.dart';
import 'town_final_ceremony_screen.dart';

class _FlyStop {
  const _FlyStop({
    required this.title,
    required this.caption,
    required this.background,
    required this.accent,
    required this.icons,
  });

  final String title;
  final String caption;
  final String background;
  final Color accent;
  final List<IconData> icons;
}

/// Final restoration flyover after Level 10 — Park → School → Neighborhood →
/// Beach → Town Center celebration.
class TownFullyRestoredScreen extends StatefulWidget {
  const TownFullyRestoredScreen({
    super.key,
    required this.character,
  });

  final GameCharacter character;

  @override
  State<TownFullyRestoredScreen> createState() =>
      _TownFullyRestoredScreenState();
}

class _TownFullyRestoredScreenState extends State<TownFullyRestoredScreen>
    with TickerProviderStateMixin {
  static const List<_FlyStop> _stops = <_FlyStop>[
    _FlyStop(
      title: 'The Park',
      caption: 'Children are laughing.',
      background: GameProgress.parkCleanBg,
      accent: Color(0xFF66BB6A),
      icons: <IconData>[
        Icons.child_care,
        Icons.face,
        Icons.sentiment_satisfied_alt,
        Icons.park,
        Icons.sports_soccer,
      ],
    ),
    _FlyStop(
      title: 'The School',
      caption: 'Students are using recycling bins.',
      background: GameProgress.schoolCleanBg,
      accent: Color(0xFF42A5F5),
      icons: <IconData>[
        Icons.backpack,
        Icons.recycling,
        Icons.child_care,
        Icons.menu_book,
        Icons.delete,
      ],
    ),
    _FlyStop(
      title: 'The Neighborhood',
      caption: 'Families are sorting waste outside their homes.',
      background: GameProgress.neighborhoodCleanBg,
      accent: Color(0xFFEC407A),
      icons: <IconData>[
        Icons.home,
        Icons.family_restroom,
        Icons.recycling,
        Icons.yard,
        Icons.cleaning_services,
      ],
    ),
    _FlyStop(
      title: 'The Beach',
      caption: 'Sea turtles return to the ocean.',
      background: GameProgress.beachCleanBg,
      accent: Color(0xFF29B6F6),
      icons: <IconData>[
        Icons.pets,
        Icons.waves,
        Icons.set_meal,
        Icons.park,
        Icons.water,
      ],
    ),
    _FlyStop(
      title: 'The Town Center',
      caption: 'The plaza is clean.',
      background: GameProgress.townCenterCleanBg,
      accent: Color(0xFF5C6BC0),
      icons: <IconData>[
        Icons.water_drop,
        Icons.park,
        Icons.local_florist,
        Icons.flutter_dash,
        Icons.people,
      ],
    ),
  ];

  static const List<String> _townCaptions = <String>[
    'The plaza is clean.',
    'The fountain sparkles.',
    'Trees are green.',
    'Flowers bloom.',
    'Birds fly overhead.',
    'Citizens gather in the square.',
  ];

  int _stopIndex = 0;
  bool _fromWhite = true;
  bool _showConfetti = false;
  int _townCaptionIndex = 0;

  late final AnimationController _whiteOut = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
    value: 1,
  );
  late final AnimationController _kenBurns = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );
  late final AnimationController _life = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  late final AnimationController _crossfade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  _FlyStop get _current => _stops[_stopIndex];
  bool get _isFinalStop => _stopIndex >= _stops.length - 1;

  @override
  void initState() {
    super.initState();
    AudioManager.instance.startBackgroundMusic();
    _beginStop();
  }

  @override
  void dispose() {
    _whiteOut.dispose();
    _kenBurns.dispose();
    _life.dispose();
    _crossfade.dispose();
    super.dispose();
  }

  Future<void> _beginStop() async {
    _kenBurns
      ..reset()
      ..forward();
    _life
      ..reset()
      ..forward();
    if (_fromWhite) {
      await _whiteOut.reverse();
      if (!mounted) return;
      setState(() => _fromWhite = false);
    } else {
      _crossfade
        ..value = 1
        ..reverse();
    }

    if (_isFinalStop) {
      await _runTownCenterBeats();
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 3800));
    if (!mounted) return;
    await _advanceStop();
  }

  Future<void> _runTownCenterBeats() async {
    for (int i = 0; i < _townCaptions.length; i++) {
      if (!mounted) return;
      setState(() => _townCaptionIndex = i);
      _life
        ..reset()
        ..forward();
      await Future<void>.delayed(const Duration(milliseconds: 1600));
    }
    if (!mounted) return;
    setState(() => _showConfetti = true);
    AudioManager.instance.playApplause();
    await Future<void>.delayed(const Duration(milliseconds: 3200));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => TownFinalCeremonyScreen(
          character: widget.character,
        ),
      ),
    );
  }

  Future<void> _advanceStop() async {
    await _crossfade.forward();
    if (!mounted) return;
    setState(() {
      _stopIndex++;
      _townCaptionIndex = 0;
    });
    await _beginStop();
  }

  String get _caption {
    if (_isFinalStop) {
      return _townCaptions[_townCaptionIndex.clamp(0, _townCaptions.length - 1)];
    }
    return _current.caption;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double w = constraints.maxWidth;
          final double h = constraints.maxHeight;
          final bool compact = h < 420;

          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              AnimatedBuilder(
                animation: Listenable.merge(<Listenable>[_kenBurns, _crossfade]),
                builder: (BuildContext context, _) {
                  final double t = Curves.easeInOut.transform(_kenBurns.value);
                  final double scale = 1.08 + t * 0.06;
                  final double dx = (t - 0.5) * w * 0.08;
                  final double fade = 1 - _crossfade.value * 0.35;
                  return Opacity(
                    opacity: fade.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(dx, 0),
                      child: Transform.scale(
                        scale: scale,
                        child: Image.asset(
                          _current.background,
                          fit: BoxFit.cover,
                          width: w,
                          height: h,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _life,
                builder: (BuildContext context, _) {
                  return _LocationLifeOverlay(
                    progress: _life.value,
                    compact: compact,
                    width: w,
                    height: h,
                    accent: _current.accent,
                  );
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                top: compact ? 12 : 22,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: <Widget>[
                      _TitleChip(
                        text: _current.title,
                        accent: _current.accent,
                        compact: compact,
                      ),
                      SizedBox(height: compact ? 8 : 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: _CaptionChip(
                          key: ValueKey<String>(_caption),
                          text: _caption,
                          compact: compact,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showConfetti) ...<Widget>[
                const Positioned.fill(child: ConfettiOverlay()),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: compact ? 16 : 28,
                  child: SafeArea(
                    top: false,
                    child: Center(
                      child: _CaptionChip(
                        text: 'Confetti fills the sky.',
                        compact: compact,
                      ),
                    ),
                  ),
                ),
              ],
              AnimatedBuilder(
                animation: _whiteOut,
                builder: (BuildContext context, _) {
                  if (_whiteOut.value <= 0.01) {
                    return const SizedBox.shrink();
                  }
                  return Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(
                        color: Colors.white.withValues(alpha: _whiteOut.value),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TitleChip extends StatelessWidget {
  const _TitleChip({
    required this.text,
    required this.accent,
    required this.compact,
  });

  final String text;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 22,
        vertical: compact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xE00E0E1A),
        border: Border.all(color: accent, width: 4),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 16,
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Jersey10',
          fontSize: compact ? 22 : 34,
          height: 1,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CaptionChip extends StatelessWidget {
  const _CaptionChip({
    super.key,
    required this.text,
    required this.compact,
  });

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: compact ? 20 : 48),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 18,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xD00E0E1A),
        border: Border.all(color: const Color(0xFF2B2B3A), width: 3),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Jersey10',
          fontSize: compact ? 15 : 20,
          height: 1.1,
          color: const Color(0xFFECEFF1),
        ),
      ),
    );
  }
}

class _LocationLifeOverlay extends StatelessWidget {
  const _LocationLifeOverlay({
    required this.progress,
    required this.compact,
    required this.width,
    required this.height,
    required this.accent,
  });

  final double progress;
  final bool compact;
  final double width;
  final double height;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final double glow = Curves.easeOut.transform(
      ((progress - 0.05) / 0.25).clamp(0.0, 1.0),
    );

    final double cx = width * 0.5;
    final double cy = height * (compact ? 0.55 : 0.58);
    final double glowR = compact ? 100.0 : 140.0;

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          if (glow > 0)
            Positioned(
              left: cx - glowR,
              top: cy - glowR,
              width: glowR * 2,
              height: glowR * 2,
              child: Opacity(
                opacity: glow * 0.7,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        accent.withValues(alpha: 0.55),
                        accent.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
