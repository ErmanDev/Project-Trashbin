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
  });

  final int stars;
  final int coinsEarned;
  final int score;
  final int correctAnswers;
  final int mistakes;
  final List<EnvironmentalImpact> environmentalImpact;
  final String levelTitle;

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
