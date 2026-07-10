import 'package:flutter/material.dart';

/// A selectable player character shown on the character creation screen.
class GameCharacter {
  const GameCharacter({
    required this.id,
    required this.name,
    required this.asset,
    required this.accent,
  });

  final String id;
  final String name;
  final String asset;

  /// Card accent colour used for the selection frame and name banner.
  final Color accent;

  /// Background-removed variant, used where the character stands on a scene
  /// (e.g. the cinematic intro) rather than inside a card.
  String get cutoutAsset => asset.replaceAll('.png', '_cutout.png');

  /// The four playable eco-heroes (2 boys, 2 girls).
  static const List<GameCharacter> all = <GameCharacter>[
    GameCharacter(
      id: 'boy1',
      name: 'Milo',
      asset: 'assets/images/png/char_boy1.png',
      accent: Color(0xFF4CAF50),
    ),
    GameCharacter(
      id: 'boy2',
      name: 'Theo',
      asset: 'assets/images/png/char_boy2.png',
      accent: Color(0xFF42A5F5),
    ),
    GameCharacter(
      id: 'girl1',
      name: 'Rosa',
      asset: 'assets/images/png/char_girl1.png',
      accent: Color(0xFFEC407A),
    ),
    GameCharacter(
      id: 'girl2',
      name: 'Ivy',
      asset: 'assets/images/png/char_girl2.png',
      accent: Color(0xFFFFB300),
    ),
  ];

  static GameCharacter? byId(String? id) {
    if (id == null) return null;
    for (final GameCharacter character in all) {
      if (character.id == id) return character;
    }
    return null;
  }
}
