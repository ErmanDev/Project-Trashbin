import 'package:flutter/material.dart';

/// Summary data shown on the post-level reward screen.
class LevelRewardResult {
  const LevelRewardResult({
    required this.stars,
    required this.coinsEarned,
    required this.score,
    required this.correctAnswers,
    required this.mistakes,
    required this.environmentalImpact,
    this.levelTitle = 'Level Complete',
    this.locationId = 'park',
    this.levelNumber = 1,
    this.totalItems,
    this.rewardBadge,
    this.rewardBadgeId,
    this.perfectBonus = false,
    this.impactSectionTitle = 'Environmental Impact',
    this.rewardIcon = Icons.military_tech,
    this.isReplay = false,
  });

  final int stars;
  final int coinsEarned;
  final int score;
  final int correctAnswers;
  final int mistakes;
  final List<EnvironmentalImpact> environmentalImpact;
  final String levelTitle;
  final String locationId;
  final int levelNumber;

  /// True when the level was already cleared; no coins/unlocks are granted.
  final bool isReplay;

  /// When set, Correct Answers shows as `correct/total` (e.g. 10/10).
  final int? totalItems;

  /// Optional badge unlocked for this level (shown in a Reward section).
  final String? rewardBadge;

  /// Cosmetic / badge id used to load the badge PNG on the reward screen.
  final String? rewardBadgeId;

  /// Show a Perfect Bonus row when the player made zero mistakes.
  final bool perfectBonus;

  final String impactSectionTitle;
  final IconData rewardIcon;

  /// Back-compat alias used by older park call sites.
  int get parkLevel => levelNumber;

  bool get isNeighborhood => locationId == 'neighborhood';

  bool get isBeach => locationId == 'beach';

  bool get isTownCenter => locationId == 'town_center';

  /// Mission results show coins + correct/total.
  bool get usesMissionStats => isNeighborhood || isBeach || isTownCenter;

  String get correctAnswersLabel {
    if (totalItems != null) {
      return '$correctAnswers/$totalItems';
    }
    return '$correctAnswers';
  }

  static int starsForMistakes(int mistakes) {
    if (mistakes == 0) return 3;
    if (mistakes <= 2) return 2;
    return 1;
  }

  static int scoreFor({
    required int correctAnswers,
    required int mistakes,
  }) {
    final int raw = correctAnswers * 100 - mistakes * 25;
    return raw < 0 ? 0 : raw;
  }

  /// Merge impact rows that share the same label.
  static List<EnvironmentalImpact> aggregateImpacts(
    List<EnvironmentalImpact> raw,
  ) {
    final Map<String, double> byLabel = <String, double>{};
    for (final EnvironmentalImpact impact in raw) {
      byLabel[impact.label] = (byLabel[impact.label] ?? 0) + impact.kg;
    }
    return byLabel.entries
        .map(
          (MapEntry<String, double> e) => EnvironmentalImpact(
            label: e.key,
            kg: e.value,
          ),
        )
        .toList();
  }
}

/// One line on the environmental-impact section of the reward screen.
class EnvironmentalImpact {
  const EnvironmentalImpact({
    required this.label,
    required this.kg,
  });

  final String label;
  final double kg;
}
