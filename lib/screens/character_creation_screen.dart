import 'package:flutter/material.dart';

import '../models/game_character.dart';
import '../services/save_manager.dart';
import '../widgets/pixel_button.dart';
import 'cinematic_intro_screen.dart';

/// Lets the player pick one of four eco-heroes. Shown when starting a fresh
/// game (no existing save). The four characters are laid out inline as
/// selectable pixel-art cards.
class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() =>
      _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  int? _selectedIndex;

  Future<void> _confirm() async {
    final int? index = _selectedIndex;
    if (index == null) return;

    final GameCharacter character = GameCharacter.all[index];
    await SaveManager.instance.saveCharacter(character.id);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            CinematicIntroScreen(character: character),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            'assets/images/png/main_menu_bg.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
          ),
          const ColoredBox(color: Color(0x99000000)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: <Widget>[
                  const _Title(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        for (int i = 0; i < GameCharacter.all.length; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: _CharacterCard(
                                character: GameCharacter.all[i],
                                selected: _selectedIndex == i,
                                onTap: () =>
                                    setState(() => _selectedIndex = i),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      PixelButton(
                        label: 'Back',
                        icon: Icons.arrow_back,
                        color: const Color(0xFF90A4AE),
                        width: 200,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 16),
                      Opacity(
                        opacity: _selectedIndex == null ? 0.5 : 1,
                        child: PixelButton(
                          label: 'Play',
                          icon: Icons.check,
                          color: const Color(0xFF4CAF50),
                          width: 240,
                          onPressed: _confirm,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Choose Your Hero',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Jersey10',
        fontSize: 56,
        height: 1,
        letterSpacing: 2,
        color: const Color(0xFF7CE07F),
        shadows: <Shadow>[
          const Shadow(color: Colors.white, offset: Offset(-2, -2)),
          const Shadow(color: Colors.white, offset: Offset(2, -2)),
          const Shadow(color: Colors.white, offset: Offset(-2, 2)),
          const Shadow(color: Colors.white, offset: Offset(2, 2)),
          Shadow(
            color: Colors.black.withValues(alpha: 0.4),
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({
    required this.character,
    required this.selected,
    required this.onTap,
  });

  final GameCharacter character;
  final bool selected;
  final VoidCallback onTap;

  static const Color _border = Color(0xFF2B2B3A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.translationValues(0, selected ? -8 : 0, 0),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3D6),
          border: Border.all(
            color: selected ? character.accent : _border,
            width: selected ? 6 : 4,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: selected ? character.accent : _border,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            // Character portrait.
            Expanded(
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: ColoredBox(
                      color: character.accent.withValues(alpha: 0.18),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          character.asset,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: character.accent,
                          border: Border.all(color: _border, width: 3),
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 22),
                      ),
                    ),
                ],
              ),
            ),
            // Name banner.
            Container(
              width: double.infinity,
              color: character.accent,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                character.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Jersey10',
                  fontSize: 32,
                  height: 1,
                  color: Colors.white,
                  shadows: <Shadow>[
                    Shadow(color: _border, offset: Offset(2, 2)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
