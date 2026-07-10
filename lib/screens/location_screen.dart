import 'package:flutter/material.dart';

import '../models/game_character.dart';
import '../models/town_location.dart';
import '../widgets/pixel_button.dart';

/// Placeholder screen shown when entering an unlocked town location
/// (e.g. the Park). The actual mini-game / level will be built here.
class LocationScreen extends StatelessWidget {
  const LocationScreen({
    super.key,
    required this.location,
    required this.character,
  });

  final TownLocation location;
  final GameCharacter character;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            'assets/images/png/town_map_bg.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
          ),
          ColoredBox(color: location.color.withValues(alpha: 0.55)),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(location.icon, size: 72, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    location.name,
                    style: const TextStyle(
                      fontFamily: 'Jersey10',
                      fontSize: 64,
                      height: 1,
                      color: Colors.white,
                      shadows: <Shadow>[
                        Shadow(color: Color(0xFF2B2B3A), offset: Offset(3, 3)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Level coming soon...',
                    style: TextStyle(
                      fontFamily: 'Jersey10',
                      fontSize: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PixelButton(
                    label: 'Back to Map',
                    icon: Icons.arrow_back,
                    color: const Color(0xFF42A5F5),
                    width: 300,
                    onPressed: () => Navigator.of(context).pop(),
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
