import 'package:flutter/material.dart';

import '../models/game_character.dart';
import '../models/game_progress.dart';
import '../models/town_location.dart';
import '../widgets/pixel_button.dart';

/// Placeholder entry for Park Level 2 (unlocked after Level 1).
class ParkLevel2Screen extends StatelessWidget {
  const ParkLevel2Screen({
    super.key,
    required this.character,
    required this.location,
  });

  final GameCharacter character;
  final TownLocation location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            GameProgress.parkCleanBg,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xCC0E1A12),
                  Color(0xE6070B08),
                ],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxHeight < 420;
                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(compact ? 12 : 24),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: compact ? 480 : 560,
                      ),
                      padding: EdgeInsets.fromLTRB(
                        compact ? 16 : 24,
                        compact ? 12 : 20,
                        compact ? 16 : 24,
                        compact ? 12 : 22,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xF00E0E1A),
                        border: Border.all(
                          color: const Color(0xFF2B2B3A),
                          width: compact ? 4 : 5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.park,
                            color: const Color(0xFF4CAF50),
                            size: compact ? 40 : 56,
                          ),
                          SizedBox(height: compact ? 6 : 10),
                          Text(
                            'Park Level 2',
                            style: TextStyle(
                              fontFamily: 'Jersey10',
                              fontSize: compact ? 36 : 48,
                              height: 1,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: compact ? 6 : 8),
                          Text(
                            'A new sorting challenge awaits!\nComing soon.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Jersey10',
                              fontSize: compact ? 20 : 26,
                              height: 1.15,
                              color: const Color(0xFFDCE6DC),
                            ),
                          ),
                          SizedBox(height: compact ? 12 : 18),
                          Center(
                            child: PixelButton(
                              label: 'Back to Map',
                              icon: Icons.map,
                              color: const Color(0xFF4CAF50),
                              width: null,
                              compact: true,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ],
                      ),
                    ),
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
