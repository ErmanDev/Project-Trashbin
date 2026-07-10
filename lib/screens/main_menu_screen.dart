import 'package:flutter/material.dart';

import '../models/game_character.dart';
import '../services/app_quit.dart';
import '../services/audio_manager.dart';
import '../services/save_manager.dart';
import '../widgets/pixel_button.dart';
import 'character_creation_screen.dart';
import 'settings_screen.dart';
import 'town_map_screen.dart';

/// The main menu shown when the game launches.
///
/// Displays the pixel-art city background, the game title, and three
/// vertically stacked pixel buttons: Start, Settings and Exit.
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  // Child-friendly, high-contrast palette.
  static const Color _startColor = Color(0xFF4CAF50); // grass green
  static const Color _settingsColor = Color(0xFFFFB300); // sunny yellow
  static const Color _exitColor = Color(0xFFEF5350); // soft red

  @override
  void initState() {
    super.initState();
    AudioManager.instance.startBackgroundMusic();
  }

  Future<void> _onStart(BuildContext context) async {
    // If a save exists, load straight into the map; otherwise start a new
    // game by letting the player create/pick a character.
    if (await SaveManager.instance.hasSave()) {
      final String? id = await SaveManager.instance.loadCharacterId();
      final GameCharacter? character = GameCharacter.byId(id);
      if (character != null) {
        if (!context.mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) =>
                TownMapScreen(character: character),
          ),
        );
        return;
      }
    }

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const CharacterCreationScreen(),
      ),
    );
  }

  Future<void> _onSettings(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const SettingsScreen(),
      ),
    );
    // Refresh any UI that depends on audio state when returning.
    if (mounted) setState(() {});
  }

  Future<void> _onExit() async {
    await AudioManager.instance.stopBackgroundMusic();
    await quitApp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Background.
          Image.asset(
            'assets/images/png/main_menu_bg.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none, // keep crisp pixel edges
          ),
          // Slight dark gradient at the bottom for button readability.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.transparent,
                  Colors.transparent,
                  Color(0x33000000),
                ],
                stops: <double>[0.0, 0.55, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double maxW = constraints.maxWidth;
                final double maxH = constraints.maxHeight;
                final bool compact = maxH < 420;
                final double buttonWidth = compact
                    ? (maxW * 0.50).clamp(170.0, 240.0)
                    : (maxW * 0.62).clamp(220.0, 320.0);
                final double gap = compact ? 12.0 : 18.0;
                final double titleGap = compact ? 18.0 : 28.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _GameTitle(compact: compact),
                      SizedBox(height: titleGap),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          PixelButton(
                            label: 'Start',
                            icon: Icons.play_arrow,
                            color: _startColor,
                            width: buttonWidth,
                            compact: compact,
                            onPressed: () => _onStart(context),
                          ),
                          SizedBox(height: gap),
                          PixelButton(
                            label: 'Settings',
                            icon: Icons.settings,
                            color: _settingsColor,
                            width: buttonWidth,
                            compact: compact,
                            onPressed: () => _onSettings(context),
                          ),
                          SizedBox(height: gap),
                          PixelButton(
                            label: 'Exit',
                            icon: Icons.close,
                            color: _exitColor,
                            width: buttonWidth,
                            compact: compact,
                            onPressed: _onExit,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GameTitle extends StatelessWidget {
  const _GameTitle({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double fontSize = compact ? 48 : 72;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        'Play To Segregate',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Jersey10',
          fontSize: fontSize,
          height: 1,
          letterSpacing: 2,
          color: const Color(0xFF2E7D32),
          shadows: <Shadow>[
            const Shadow(color: Colors.white, offset: Offset(-3, -3)),
            const Shadow(color: Colors.white, offset: Offset(3, -3)),
            const Shadow(color: Colors.white, offset: Offset(-3, 3)),
            const Shadow(color: Colors.white, offset: Offset(3, 3)),
            Shadow(
              color: Colors.black.withValues(alpha: 0.35),
              offset: const Offset(0, 6),
              blurRadius: 0,
            ),
          ],
        ),
      ),
    );
  }
}
