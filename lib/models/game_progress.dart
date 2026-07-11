/// Persistent progress keys and reward identifiers.
class GameProgress {
  GameProgress._();

  static const String parkLocationId = 'park';
  static const String schoolLocationId = 'school';
  static const int parkLevel1 = 1;
  static const int parkLevel2 = 2;
  static const int schoolLevel3 = 3;
  static const int schoolLevel4 = 4;

  static const String ecoHatId = 'eco_hat';
  static const String greenCapId = 'green_cap';
  static const String recyclingRookieBadgeId = 'recycling_rookie';
  static const String recyclingRookieTitle = 'Recycling Rookie';
  static const String ecoHatName = 'Eco Cap';
  static const String greenCapName = 'Green Cap';
  static const int parkFullyRestoredBonusCoins = 200;

  static const String parkTrashBg = 'assets/images/png/park_trash_bg.png';
  static const String parkCleanBg = 'assets/images/png/park_clean_bg.png';
  static const String schoolTrashBg = 'assets/images/png/school_trash_bg.png';
  static const String schoolCleanBg = 'assets/images/png/school_clean_bg.png';
  static const String neighborhoodTrashBg =
      'assets/images/png/neighborhood_trash_bg.png';
  static const String neighborhoodCleanBg =
      'assets/images/png/neighborhood_clean_bg.png';
  static const String principalCutout =
      'assets/images/png/char_principal_cutout.png';
  static const String mayorCutout = 'assets/images/png/char_mayor_cutout.png';
  static const String barangayCutout =
      'assets/images/png/char_barangay_cutout.png';
  static const String neighborhoodLocationId = 'neighborhood';
  static const int neighborhoodLevel5 = 5;
  static const int neighborhoodLevel6 = 6;
  static const int schoolFullyRestoredBonusCoins = 200;
  static const int neighborhoodFullyRestoredBonusCoins = 200;
  static const String communityGuardianTitle = 'Community Guardian';
  static const String communityGuardianBadgeId = 'community_guardian';
  static const String ecoSafetyBadgeId = 'eco_safety_badge';
  static const String ecoSafetyBadgeName = 'Eco Safety Badge';
  /// Bonus so a perfect Level 5 clear shows +225 total (100 play + 125).
  static const int neighborhoodLevel5BonusCoins = 125;
  static const String scholarBadgeId = 'scholar_sorter';
  static const String scholarBadgeTitle = 'Scholar Sorter';
}
