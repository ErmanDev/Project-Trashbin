import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/survey_url.dart';
import '../models/game_progress.dart';
import '../services/audio_manager.dart';
import '../services/save_manager.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/pixel_button.dart';
import 'town_credits_screen.dart';

/// Final rewards panel after the Recycling Hero ceremony.
class TownFinalRewardsScreen extends StatefulWidget {
  const TownFinalRewardsScreen({super.key});

  @override
  State<TownFinalRewardsScreen> createState() => _TownFinalRewardsScreenState();
}

class _TownFinalRewardsScreenState extends State<TownFinalRewardsScreen> {
  static const Color _gold = Color(0xFFFFD54F);
  static const Color _border = Color(0xFF2B2B3A);
  static const Color _panel = Color(0xF00E0E1A);

  static const List<({String label, String value})> _impact = <({
    String label,
    String value
  })>[
    (label: 'Plastic Recycled', value: '85 kg'),
    (label: 'Paper Recycled', value: '42 kg'),
    (label: 'Compost Produced', value: '37 kg'),
    (label: 'Hazardous Waste Safely Collected', value: '21 kg'),
  ];

  bool _saved = false;

  @override
  void initState() {
    super.initState();
    AudioManager.instance.playApplause();
    _grantRewards();
  }

  Future<void> _grantRewards() async {
    if (_saved) return;
    _saved = true;
    await SaveManager.instance.completeTownCenterFinale();
  }

  Future<void> _finish() async {
    final bool? openForm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final double h = MediaQuery.sizeOf(context).height;
        final bool compact = h < 420;
        return Dialog(
          backgroundColor: _panel,
          insetPadding: EdgeInsets.symmetric(
            horizontal: compact ? 24 : 40,
            vertical: compact ? 12 : 24,
          ),
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: _border, width: 4),
            borderRadius: BorderRadius.zero,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 340 : 400),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 20,
                compact ? 12 : 18,
                compact ? 14 : 20,
                compact ? 12 : 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Almost done!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Jersey10',
                      fontSize: compact ? 26 : 32,
                      height: 1,
                      color: _gold,
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 14),
                  Text(
                    'Please fill out a short survey about what you learned '
                    'in the park, school, neighborhood, beach, and town center.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Jersey10',
                      fontSize: compact ? 15 : 18,
                      height: 1.25,
                      color: const Color(0xFFECEFF1),
                    ),
                  ),
                  SizedBox(height: compact ? 14 : 18),
                  PixelButton(
                    label: 'Open survey',
                    icon: Icons.open_in_browser,
                    color: const Color(0xFF4CAF50),
                    width: null,
                    compact: compact,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  PixelButton(
                    label: 'Skip for now',
                    icon: Icons.skip_next,
                    color: const Color(0xFF78909C),
                    width: null,
                    compact: compact,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (openForm == true) {
      final Uri uri = Uri.parse(kSurveyFormUrl);
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open the survey link. Ask your teacher for the URL.',
              style: TextStyle(fontFamily: 'Jersey10'),
            ),
          ),
        );
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const TownCreditsScreen(),
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
            GameProgress.townCenterCleanBg,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
          ),
          const ColoredBox(color: Color(0x99000000)),
          const Positioned.fill(
            child: ConfettiOverlay(
              particleCount: 100,
              colors: <Color>[
                Color(0xFFFFD54F),
                Color(0xFFFFC107),
                Color(0xFFFFECB3),
                Color(0xFFFFF176),
              ],
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxHeight < 420;
                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 28,
                      vertical: compact ? 8 : 16,
                    ),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: compact ? 520 : 600,
                      ),
                      padding: EdgeInsets.fromLTRB(
                        compact ? 14 : 24,
                        compact ? 12 : 20,
                        compact ? 14 : 24,
                        compact ? 12 : 20,
                      ),
                      decoration: BoxDecoration(
                        color: _panel,
                        border: Border.all(color: _gold, width: 5),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: _gold.withValues(alpha: 0.35),
                            blurRadius: 22,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            'Final Rewards',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Jersey10',
                              fontSize: compact ? 32 : 44,
                              height: 1,
                              color: Colors.white,
                              shadows: const <Shadow>[
                                Shadow(
                                  color: _border,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: compact ? 10 : 14),
                          _RewardRow(
                            icon: Icons.military_tech,
                            color: _gold,
                            label: 'Title',
                            value: GameProgress.recyclingHeroTitle,
                            compact: compact,
                            imageAsset:
                                'assets/images/png/badge_recycling_hero.png',
                          ),
                          _RewardRow(
                            icon: Icons.checkroom,
                            color: const Color(0xFFFFCA28),
                            label: 'Outfit',
                            value: GameProgress.goldenEcoOutfitName,
                            compact: compact,
                          ),
                          _RewardRow(
                            icon: Icons.workspace_premium,
                            color: _gold,
                            label: 'Crown',
                            value: GameProgress.heroCrownName,
                            compact: compact,
                          ),
                          _RewardRow(
                            icon: Icons.star,
                            color: const Color(0xFFFFCA28),
                            label: 'Badge',
                            value: GameProgress.finalCompletionBadgeName,
                            compact: compact,
                            imageAsset:
                                'assets/images/png/badge_final_completion.png',
                          ),
                          _RewardRow(
                            icon: Icons.monetization_on,
                            color: const Color(0xFFFFC107),
                            label: 'Bonus Coins',
                            value:
                                '+${GameProgress.townFullyRestoredBonusCoins}',
                            compact: compact,
                          ),
                          SizedBox(height: compact ? 10 : 14),
                          Text(
                            'Environmental Impact Summary',
                            style: TextStyle(
                              fontFamily: 'Jersey10',
                              fontSize: compact ? 18 : 22,
                              height: 1,
                              color: const Color(0xFF9FE6A0),
                            ),
                          ),
                          SizedBox(height: compact ? 6 : 8),
                          ..._impact.map(
                            (({String label, String value}) row) => _ImpactRow(
                              label: row.label,
                              value: row.value,
                              compact: compact,
                            ),
                          ),
                          SizedBox(height: compact ? 10 : 14),
                          Container(
                            padding: EdgeInsets.all(compact ? 10 : 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161622),
                              border: Border.all(
                                color: const Color(0xFF5C6BC0),
                                width: 3,
                              ),
                            ),
                            child: Text(
                              'Thank you for helping make Green Town a cleaner '
                              'and healthier place. Remember, every small action '
                              'can make a big difference. Keep practicing proper '
                              'waste segregation in your daily life!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Jersey10',
                                fontSize: compact ? 14 : 17,
                                height: 1.25,
                                color: const Color(0xFFECEFF1),
                              ),
                            ),
                          ),
                          SizedBox(height: compact ? 12 : 16),
                          Center(
                            child: PixelButton(
                              label: 'Continue',
                              icon: Icons.movie,
                              color: _gold,
                              width: null,
                              compact: compact,
                              onPressed: _finish,
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

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.compact,
    this.imageAsset,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool compact;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 4 : 6),
      child: Row(
        children: <Widget>[
          if (imageAsset != null)
            Image.asset(
              imageAsset!,
              width: compact ? 28 : 36,
              height: compact ? 28 : 36,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            )
          else
            Icon(icon, color: color, size: compact ? 20 : 26),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Jersey10',
                fontSize: compact ? 15 : 18,
                height: 1,
                color: const Color(0xFFB0BEC5),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Jersey10',
                fontSize: compact ? 16 : 20,
                height: 1,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow({
    required this.label,
    required this.value,
    required this.compact,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 3 : 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Jersey10',
                fontSize: compact ? 14 : 16,
                height: 1,
                color: const Color(0xFFCFD8DC),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Jersey10',
              fontSize: compact ? 15 : 18,
              height: 1,
              color: const Color(0xFF9FE6A0),
            ),
          ),
        ],
      ),
    );
  }
}
