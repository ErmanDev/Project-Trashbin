import 'package:flutter/material.dart';

import '../models/cosmetic_item.dart';
import '../models/game_progress.dart';
import '../models/level_reward.dart';
import '../services/audio_manager.dart';
import '../services/save_manager.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/pixel_button.dart';
import 'beach_fully_restored_screen.dart';
import 'neighborhood_fully_restored_screen.dart';
import 'park_fully_restored_screen.dart';
import 'school_fully_restored_screen.dart';

/// Post-level results screen with stars, stats, and environmental impact.
class RewardScreen extends StatefulWidget {
  const RewardScreen({
    super.key,
    required this.result,
  });

  final LevelRewardResult result;

  static const Color _panel = Color(0xF00E0E1A);
  static const Color _border = Color(0xFF2B2B3A);

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  @override
  void initState() {
    super.initState();
    AudioManager.instance.playApplause();
  }

  @override
  Widget build(BuildContext context) {
    final LevelRewardResult result = widget.result;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            result.locationId == GameProgress.townCenterLocationId
                ? (result.levelNumber >= GameProgress.townCenterLevel10
                    ? GameProgress.townCenterCleanBg
                    : GameProgress.townCenterTrashBg)
                : result.locationId == GameProgress.beachLocationId
                    ? (result.levelNumber >= 8
                        ? GameProgress.beachCleanBg
                        : GameProgress.beachTrashBg)
                    : result.locationId == GameProgress.neighborhoodLocationId
                        ? (result.levelNumber >= 6
                            ? GameProgress.neighborhoodCleanBg
                            : GameProgress.neighborhoodTrashBg)
                        : result.locationId == GameProgress.schoolLocationId
                            ? (result.levelNumber >= 4
                                ? GameProgress.schoolCleanBg
                                : GameProgress.schoolTrashBg)
                            : result.levelNumber >= 2
                                ? GameProgress.parkCleanBg
                                : GameProgress.parkTrashBg,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0xCC0E1A12), Color(0xE6070B08)],
              ),
            ),
          ),
          const Positioned.fill(child: ConfettiOverlay()),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxHeight < 420;
                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 24,
                      vertical: compact ? 8 : 16,
                    ),
                    child: _RewardCard(result: result, compact: compact),
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

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.result,
    required this.compact,
  });

  final LevelRewardResult result;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double titleSize = compact ? 40 : 52;
    final double sectionSize = compact ? 20 : 24;
    final double statLabelSize = compact ? 16 : 18;
    final double statValueSize = compact ? 24 : 30;

    return Container(
      constraints: BoxConstraints(
        maxWidth: compact ? 520 : 640,
      ),
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 28,
        compact ? 14 : 22,
        compact ? 16 : 28,
        compact ? 16 : 24,
      ),
      decoration: BoxDecoration(
        color: RewardScreen._panel,
        border: Border.all(color: RewardScreen._border, width: compact ? 4 : 5),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0xAA000000), offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            result.levelTitle,
            style: TextStyle(
              fontFamily: 'Jersey10',
              fontSize: titleSize,
              height: 1,
              color: Colors.white,
              shadows: const <Shadow>[
                Shadow(color: RewardScreen._border, offset: Offset(3, 3)),
              ],
            ),
          ),
          if (result.isReplay) ...<Widget>[
            SizedBox(height: compact ? 6 : 8),
            Text(
              'Replay — rewards already claimed',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Jersey10',
                fontSize: compact ? 16 : 20,
                height: 1.1,
                color: const Color(0xFF9FE6A0),
              ),
            ),
          ],
          SizedBox(height: compact ? 8 : 12),
          _StarRow(stars: result.stars, compact: compact),
          SizedBox(height: compact ? 12 : 18),
          if (result.usesMissionStats)
            _NeighborhoodStats(
              result: result,
              compact: compact,
              labelSize: statLabelSize,
              valueSize: statValueSize,
            )
          else if (compact)
            _CompactStats(
              result: result,
              labelSize: statLabelSize,
              valueSize: statValueSize,
            )
          else
            _WideStats(
              result: result,
              labelSize: statLabelSize,
              valueSize: statValueSize,
            ),
          SizedBox(height: compact ? 12 : 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              result.impactSectionTitle,
              style: TextStyle(
                fontFamily: 'Jersey10',
                fontSize: sectionSize,
                height: 1,
                color: const Color(0xFF9FE6A0),
              ),
            ),
          ),
          SizedBox(height: compact ? 6 : 10),
          ...result.environmentalImpact.map(
            (EnvironmentalImpact impact) => _ImpactRow(
              impact: impact,
              compact: compact,
            ),
          ),
          if (result.rewardBadge != null) ...<Widget>[
            SizedBox(height: compact ? 12 : 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Reward',
                style: TextStyle(
                  fontFamily: 'Jersey10',
                  fontSize: sectionSize,
                  height: 1,
                  color: const Color(0xFFFFCA28),
                ),
              ),
            ),
            SizedBox(height: compact ? 6 : 10),
            _RewardLine(
              icon: result.rewardIcon,
              color: result.levelNumber == GameProgress.neighborhoodLevel6
                  ? const Color(0xFF8D6E63)
                  : result.levelNumber == GameProgress.beachLevel7
                      ? const Color(0xFF29B6F6)
                      : result.levelNumber == GameProgress.beachLevel8
                          ? const Color(0xFF26A69A)
                          : result.levelNumber == GameProgress.townCenterLevel9
                              ? const Color(0xFF5C6BC0)
                              : const Color(0xFFE53935),
              label: result.rewardBadge!,
              compact: compact,
              imageAsset: result.rewardBadgeId == null
                  ? null
                  : CosmeticItem.byId(result.rewardBadgeId!)?.imageAsset,
            ),
            _RewardLine(
              icon: Icons.monetization_on,
              color: const Color(0xFFFFC107),
              label: '+${result.coinsEarned} Coins',
              compact: compact,
            ),
          ],
          SizedBox(height: compact ? 14 : 20),
          Center(
            child: PixelButton(
              label: 'Continue',
              icon: Icons.arrow_forward,
              color: const Color(0xFF4CAF50),
              width: null,
              compact: compact,
              onPressed: () async {
                if (result.locationId == GameProgress.parkLocationId) {
                  if (result.levelNumber == 1) {
                    await SaveManager.instance.completeParkLevel1(
                      coinsEarned: result.coinsEarned,
                    );
                    if (context.mounted) Navigator.of(context).pop(true);
                  } else if (result.levelNumber == 2) {
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const ParkFullyRestoredScreen(),
                      ),
                    );
                  }
                } else if (result.locationId == GameProgress.schoolLocationId) {
                  if (result.levelNumber == 3) {
                    await SaveManager.instance.completeSchoolLevel3(
                      coinsEarned: result.coinsEarned,
                    );
                    if (context.mounted) Navigator.of(context).pop(true);
                  } else if (result.levelNumber == 4) {
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const SchoolFullyRestoredScreen(),
                      ),
                    );
                  }
                } else if (result.locationId ==
                    GameProgress.neighborhoodLocationId) {
                  if (result.levelNumber == 5) {
                    await SaveManager.instance.completeNeighborhoodLevel5(
                      coinsEarned: result.coinsEarned,
                    );
                    if (context.mounted) Navigator.of(context).pop(true);
                  } else if (result.levelNumber == 6) {
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const NeighborhoodFullyRestoredScreen(),
                      ),
                    );
                  }
                } else if (result.locationId == GameProgress.beachLocationId) {
                  if (result.levelNumber == GameProgress.beachLevel7) {
                    await SaveManager.instance.completeBeachLevel7(
                      coinsEarned: result.coinsEarned,
                    );
                    if (context.mounted) Navigator.of(context).pop();
                  } else if (result.levelNumber == GameProgress.beachLevel8) {
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const BeachFullyRestoredScreen(),
                      ),
                    );
                  }
                } else if (result.locationId ==
                    GameProgress.townCenterLocationId) {
                  if (result.levelNumber == GameProgress.townCenterLevel9) {
                    await SaveManager.instance.completeTownCenterLevel9(
                      coinsEarned: result.coinsEarned,
                    );
                    if (context.mounted) Navigator.of(context).pop();
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NeighborhoodStats extends StatelessWidget {
  const _NeighborhoodStats({
    required this.result,
    required this.compact,
    required this.labelSize,
    required this.valueSize,
  });

  final LevelRewardResult result;
  final bool compact;
  final double labelSize;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _StatTile(
                label: 'Coins Earned',
                value: '+${result.coinsEarned}',
                icon: Icons.monetization_on,
                accent: const Color(0xFFFFC107),
                labelSize: labelSize,
                valueSize: valueSize,
                compact: compact,
              ),
            ),
            SizedBox(width: compact ? 8 : 10),
            Expanded(
              child: _StatTile(
                label: 'Correct Answers',
                value: result.correctAnswersLabel,
                icon: Icons.check_circle,
                accent: const Color(0xFF66BB6A),
                labelSize: labelSize,
                valueSize: valueSize,
                compact: compact,
              ),
            ),
          ],
        ),
        if (result.perfectBonus) ...<Widget>[
          SizedBox(height: compact ? 6 : 8),
          Row(
            children: <Widget>[
              Icon(
                Icons.auto_awesome,
                color: const Color(0xFFFFCA28),
                size: compact ? 18 : 22,
              ),
              SizedBox(width: compact ? 6 : 8),
              Text(
                'Perfect Bonus',
                style: TextStyle(
                  fontFamily: 'Jersey10',
                  fontSize: compact ? 16 : 20,
                  height: 1,
                  color: const Color(0xFFFFCA28),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _RewardLine extends StatelessWidget {
  const _RewardLine({
    required this.icon,
    required this.color,
    required this.label,
    required this.compact,
    this.imageAsset,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool compact;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    final double iconSize = compact ? 28 : 40;
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 4 : 6),
      child: Row(
        children: <Widget>[
          if (imageAsset != null)
            Image.asset(
              imageAsset!,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            )
          else
            Icon(icon, color: color, size: compact ? 20 : 24),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Jersey10',
                fontSize: compact ? 18 : 22,
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

class _StarRow extends StatelessWidget {
  const _StarRow({
    required this.stars,
    required this.compact,
  });

  final int stars;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double size = compact ? 36 : 48;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(3, (int index) {
        final bool filled = index < stars;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6),
          child: Text(
            filled ? '⭐' : '☆',
            style: TextStyle(fontSize: size, height: 1),
          ),
        );
      }),
    );
  }
}

class _WideStats extends StatelessWidget {
  const _WideStats({
    required this.result,
    required this.labelSize,
    required this.valueSize,
  });

  final LevelRewardResult result;
  final double labelSize;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatTile(
            label: 'Coins Earned',
            value: '${result.coinsEarned}',
            icon: Icons.monetization_on,
            accent: const Color(0xFFFFC107),
            labelSize: labelSize,
            valueSize: valueSize,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Score',
            value: '${result.score}',
            icon: Icons.grade,
            accent: const Color(0xFFFFCA28),
            labelSize: labelSize,
            valueSize: valueSize,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Correct Answers',
            value: '${result.correctAnswers}',
            icon: Icons.check_circle,
            accent: const Color(0xFF66BB6A),
            labelSize: labelSize,
            valueSize: valueSize,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Mistakes',
            value: '${result.mistakes}',
            icon: Icons.close,
            accent: const Color(0xFFEF5350),
            labelSize: labelSize,
            valueSize: valueSize,
          ),
        ),
      ],
    );
  }
}

class _CompactStats extends StatelessWidget {
  const _CompactStats({
    required this.result,
    required this.labelSize,
    required this.valueSize,
  });

  final LevelRewardResult result;
  final double labelSize;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _StatTile(
                label: 'Coins Earned',
                value: '${result.coinsEarned}',
                icon: Icons.monetization_on,
                accent: const Color(0xFFFFC107),
                labelSize: labelSize,
                valueSize: valueSize,
                compact: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatTile(
                label: 'Score',
                value: '${result.score}',
                icon: Icons.grade,
                accent: const Color(0xFFFFCA28),
                labelSize: labelSize,
                valueSize: valueSize,
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: _StatTile(
                label: 'Correct Answers',
                value: '${result.correctAnswers}',
                icon: Icons.check_circle,
                accent: const Color(0xFF66BB6A),
                labelSize: labelSize,
                valueSize: valueSize,
                compact: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatTile(
                label: 'Mistakes',
                value: '${result.mistakes}',
                icon: Icons.close,
                accent: const Color(0xFFEF5350),
                labelSize: labelSize,
                valueSize: valueSize,
                compact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.labelSize,
    required this.valueSize,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final double labelSize;
  final double valueSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF161622),
        border: Border.all(color: RewardScreen._border, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: accent, size: compact ? 18 : 22),
          SizedBox(height: compact ? 2 : 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Jersey10',
              fontSize: labelSize,
              height: 1,
              color: const Color(0xFFB0BEC5),
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Jersey10',
              fontSize: valueSize,
              height: 1,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow({
    required this.impact,
    required this.compact,
  });

  final EnvironmentalImpact impact;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final String kgText = impact.kg == impact.kg.roundToDouble()
        ? '+${impact.kg.toInt()} kg'
        : '+${impact.kg.toStringAsFixed(1)} kg';

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 4 : 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              impact.label,
              style: TextStyle(
                fontFamily: 'Jersey10',
                fontSize: compact ? 20 : 24,
                height: 1,
                color: const Color(0xFFDCE6DC),
              ),
            ),
          ),
          Text(
            kgText,
            style: TextStyle(
              fontFamily: 'Jersey10',
              fontSize: compact ? 20 : 24,
              height: 1,
              color: const Color(0xFF9FE6A0),
            ),
          ),
        ],
      ),
    );
  }
}
