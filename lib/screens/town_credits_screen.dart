import 'dart:async';

import 'package:flutter/material.dart';

import '../models/game_progress.dart';
import 'main_menu_screen.dart';

class _CreditScene {
  const _CreditScene({
    required this.background,
    required this.caption,
  });

  final String background;
  final String caption;
}

/// End credits: restored-town scenes + scrolling names, then Main Menu.
class TownCreditsScreen extends StatefulWidget {
  const TownCreditsScreen({super.key});

  @override
  State<TownCreditsScreen> createState() => _TownCreditsScreenState();
}

class _TownCreditsScreenState extends State<TownCreditsScreen>
    with TickerProviderStateMixin {
  static const List<_CreditScene> _scenes = <_CreditScene>[
    _CreditScene(
      background: GameProgress.parkCleanBg,
      caption: 'Children playing in the park.',
    ),
    _CreditScene(
      background: GameProgress.schoolCleanBg,
      caption: 'Students cleaning the school grounds.',
    ),
    _CreditScene(
      background: GameProgress.neighborhoodCleanBg,
      caption: 'Neighbors working together.',
    ),
    _CreditScene(
      background: GameProgress.beachCleanBg,
      caption: 'Volunteers cleaning the beach.',
    ),
    _CreditScene(
      background: GameProgress.townCenterCleanBg,
      caption: 'Families enjoying the Town Center.',
    ),
  ];

  static const List<String> _creditLines = <String>[
    'Play To Segregate',
    '',
    'A Green Town Story',
    '',
    '',
    'Created for young eco-heroes',
    '',
    '',
    'Locations Restored',
    'The Park',
    'The School',
    'The Neighborhood',
    'The Beach',
    'The Town Center',
    '',
    '',
    'Special Thanks',
    'The Mayor',
    'The Principal',
    'The Barangay Captain',
    'The Marine Ranger',
    'Every citizen of Green Town',
    '',
    '',
    'And you —',
    'Recycling Hero',
    '',
    '',
    'Remember:',
    'Every small action',
    'can make a big difference.',
    '',
    '',
    'Thank you for playing!',
  ];

  int _sceneIndex = 0;
  bool _finished = false;

  late final AnimationController _roll = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 28000),
  );
  late final AnimationController _sceneFade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    value: 1,
  );

  Timer? _sceneTimer;

  @override
  void initState() {
    super.initState();
    _roll.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed && mounted) {
        _goToMainMenu();
      }
    });
    _sceneTimer = Timer.periodic(const Duration(milliseconds: 5200), (_) {
      _advanceScene();
    });
    _roll.forward();
  }

  @override
  void dispose() {
    _sceneTimer?.cancel();
    _roll.dispose();
    _sceneFade.dispose();
    super.dispose();
  }

  Future<void> _advanceScene() async {
    if (!mounted || _finished) return;
    await _sceneFade.reverse();
    if (!mounted) return;
    setState(() {
      _sceneIndex = (_sceneIndex + 1) % _scenes.length;
    });
    await _sceneFade.forward();
  }

  void _goToMainMenu() {
    if (_finished || !mounted) return;
    _finished = true;
    _sceneTimer?.cancel();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const MainMenuScreen(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  void _onTap() {
    // Skip to the end / main menu on tap.
    _goToMainMenu();
  }

  @override
  Widget build(BuildContext context) {
    final _CreditScene scene = _scenes[_sceneIndex];

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

            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                AnimatedBuilder(
                  animation: _sceneFade,
                  builder: (BuildContext context, _) {
                    return Opacity(
                      opacity: Curves.easeInOut.transform(_sceneFade.value),
                      child: Image.asset(
                        scene.background,
                        fit: BoxFit.cover,
                        width: w,
                        height: h,
                        filterQuality: FilterQuality.none,
                      ),
                    );
                  },
                ),
                const ColoredBox(color: Color(0x99000000)),
                Positioned(
                  left: 0,
                  right: 0,
                  top: compact ? 12 : 22,
                  child: SafeArea(
                    bottom: false,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _CaptionChip(
                          key: ValueKey<String>(scene.caption),
                          text: scene.caption,
                          compact: compact,
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _roll,
                  builder: (BuildContext context, _) {
                    final double travel = h + _creditLines.length * 36.0;
                    final double y = h * 0.55 - _roll.value * travel;
                    return Positioned(
                      left: 0,
                      right: 0,
                      top: y,
                      child: Column(
                        children: _creditLines.map((String line) {
                          final bool isTitle = line == 'Play To Segregate' ||
                              line == 'Recycling Hero' ||
                              line == 'Thank you for playing!';
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: compact ? 3 : 5,
                              horizontal: compact ? 16 : 32,
                            ),
                            child: Text(
                              line,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Jersey10',
                                fontSize: isTitle
                                    ? (compact ? 26 : 36)
                                    : (compact ? 16 : 22),
                                height: 1.15,
                                color: isTitle
                                    ? const Color(0xFFFFD54F)
                                    : Colors.white,
                                shadows: const <Shadow>[
                                  Shadow(
                                    color: Colors.black,
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: compact ? 10 : 16,
                  child: SafeArea(
                    top: false,
                    child: Text(
                      'Tap to skip',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Jersey10',
                        fontSize: compact ? 13 : 16,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
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
  const _CaptionChip({super.key, required this.text, required this.compact});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: compact ? 16 : 40),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 18,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xE00E0E1A),
        border: Border.all(color: const Color(0xFFFFD54F), width: 3),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Jersey10',
          fontSize: compact ? 15 : 20,
          height: 1.1,
          color: Colors.white,
        ),
      ),
    );
  }
}
