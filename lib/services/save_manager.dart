import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_progress.dart';

/// Simple persistent save slot for the game.
///
/// Stores the chosen character plus lightweight progress (coins, title and the
/// set of unlocked town locations). This is the single place to grow the save
/// payload over time.
class SaveManager {
  SaveManager._();

  static final SaveManager instance = SaveManager._();

  static const String _characterKey = 'save_character_id';
  static const String _coinsKey = 'save_coins';
  static const String _titleKey = 'save_title';
  static const String _unlockedKey = 'save_unlocked_locations';
  static const String _completedLevelsKey = 'save_completed_levels';
  static const String _parkMaxLevelKey = 'save_park_max_level';
  static const String _parkRestoredKey = 'save_park_restored';
  static const String _cosmeticsKey = 'save_unlocked_cosmetics';
  static const String _equippedHatKey = 'save_equipped_hat';
  static const String _pendingCelebrationKey = 'save_pending_park_celebration';
  static const String _pendingCelebrationCoinsKey =
      'save_pending_celebration_coins';

  /// Locations the player can access from the very start of a new game.
  static const List<String> defaultUnlocked = <String>['park'];
  static const String defaultTitle = 'Rookie Sorter';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Whether a saved game exists (i.e. a character was previously chosen).
  Future<bool> hasSave() async {
    final SharedPreferences prefs = await _preferences;
    final String? id = prefs.getString(_characterKey);
    return id != null && id.isNotEmpty;
  }

  Future<String?> loadCharacterId() async {
    final SharedPreferences prefs = await _preferences;
    return prefs.getString(_characterKey);
  }

  /// Creates a fresh save for [characterId], seeding the default progress.
  Future<void> saveCharacter(String characterId) async {
    final SharedPreferences prefs = await _preferences;
    await prefs.setString(_characterKey, characterId);
    if (!prefs.containsKey(_coinsKey)) {
      await prefs.setInt(_coinsKey, 0);
    }
    if (!prefs.containsKey(_titleKey)) {
      await prefs.setString(_titleKey, defaultTitle);
    }
    if (!prefs.containsKey(_unlockedKey)) {
      await prefs.setStringList(_unlockedKey, defaultUnlocked);
    }
  }

  Future<int> loadCoins() async {
    final SharedPreferences prefs = await _preferences;
    return prefs.getInt(_coinsKey) ?? 0;
  }

  Future<void> saveCoins(int coins) async {
    final SharedPreferences prefs = await _preferences;
    await prefs.setInt(_coinsKey, coins);
  }

  /// Adds [amount] to the saved coin total and persists immediately.
  Future<int> addCoins(int amount) async {
    if (amount <= 0) return loadCoins();
    final SharedPreferences prefs = await _preferences;
    final int updated = (prefs.getInt(_coinsKey) ?? 0) + amount;
    await prefs.setInt(_coinsKey, updated);
    return updated;
  }

  Future<String> loadTitle() async {
    final SharedPreferences prefs = await _preferences;
    return prefs.getString(_titleKey) ?? defaultTitle;
  }

  Future<void> saveTitle(String title) async {
    final SharedPreferences prefs = await _preferences;
    await prefs.setString(_titleKey, title);
  }

  Future<Set<String>> loadUnlockedLocations() async {
    final SharedPreferences prefs = await _preferences;
    return (prefs.getStringList(_unlockedKey) ?? defaultUnlocked).toSet();
  }

  Future<void> unlockLocation(String locationId) async {
    final SharedPreferences prefs = await _preferences;
    final Set<String> unlocked = await loadUnlockedLocations();
    unlocked.add(locationId);
    await prefs.setStringList(_unlockedKey, unlocked.toList());
  }

  Future<Set<String>> loadCompletedLevels() async {
    final SharedPreferences prefs = await _preferences;
    return (prefs.getStringList(_completedLevelsKey) ?? <String>[]).toSet();
  }

  Future<bool> isLevelCompleted(String locationId, int level) async {
    final Set<String> completed = await loadCompletedLevels();
    return completed.contains('$locationId:$level');
  }

  Future<void> markLevelCompleted(String locationId, int level) async {
    final SharedPreferences prefs = await _preferences;
    final Set<String> completed = await loadCompletedLevels();
    completed.add('$locationId:$level');
    await prefs.setStringList(_completedLevelsKey, completed.toList());
  }

  Future<int> loadParkMaxLevel() async {
    final SharedPreferences prefs = await _preferences;
    return prefs.getInt(_parkMaxLevelKey) ?? GameProgress.parkLevel1;
  }

  Future<bool> isParkRestored() async {
    final SharedPreferences prefs = await _preferences;
    return prefs.getBool(_parkRestoredKey) ?? false;
  }

  Future<Set<String>> loadUnlockedCosmetics() async {
    final SharedPreferences prefs = await _preferences;
    return (prefs.getStringList(_cosmeticsKey) ?? <String>[]).toSet();
  }

  Future<String?> loadEquippedHat() async {
    final SharedPreferences prefs = await _preferences;
    return prefs.getString(_equippedHatKey);
  }

  Future<void> unlockCosmetic(String cosmeticId) async {
    final SharedPreferences prefs = await _preferences;
    final Set<String> cosmetics = await loadUnlockedCosmetics();
    cosmetics.add(cosmeticId);
    await prefs.setStringList(_cosmeticsKey, cosmetics.toList());
  }

  Future<void> equipHat(String hatId) async {
    final SharedPreferences prefs = await _preferences;
    await prefs.setString(_equippedHatKey, hatId);
  }

  /// Whether the town map should play the post-Level-1 celebration sequence.
  Future<bool> hasPendingParkCelebration() async {
    final SharedPreferences prefs = await _preferences;
    return prefs.getBool(_pendingCelebrationKey) ?? false;
  }

  /// Coins earned this session, shown during the celebration rewards step.
  Future<int> loadPendingCelebrationCoins() async {
    final SharedPreferences prefs = await _preferences;
    return prefs.getInt(_pendingCelebrationCoinsKey) ?? 0;
  }

  Future<void> clearPendingParkCelebration() async {
    final SharedPreferences prefs = await _preferences;
    await prefs.remove(_pendingCelebrationKey);
    await prefs.remove(_pendingCelebrationCoinsKey);
  }

  /// Persists all rewards and flags after Park Level 1 is finished.
  Future<void> completeParkLevel1({required int coinsEarned}) async {
    if (await isLevelCompleted(
      GameProgress.parkLocationId,
      GameProgress.parkLevel1,
    )) {
      return;
    }

    final SharedPreferences prefs = await _preferences;
    await markLevelCompleted(GameProgress.parkLocationId, GameProgress.parkLevel1);
    await prefs.setInt(_parkMaxLevelKey, GameProgress.parkLevel2);
    await prefs.setBool(_parkRestoredKey, true);
    await unlockCosmetic(GameProgress.ecoHatId);
    await unlockCosmetic(GameProgress.recyclingRookieBadgeId);
    await equipHat(GameProgress.ecoHatId);
    await saveTitle(GameProgress.recyclingRookieTitle);
    await prefs.setBool(_pendingCelebrationKey, true);
    await prefs.setInt(_pendingCelebrationCoinsKey, coinsEarned);
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await _preferences;
    await prefs.remove(_characterKey);
    await prefs.remove(_coinsKey);
    await prefs.remove(_titleKey);
    await prefs.remove(_unlockedKey);
    await prefs.remove(_completedLevelsKey);
    await prefs.remove(_parkMaxLevelKey);
    await prefs.remove(_parkRestoredKey);
    await prefs.remove(_cosmeticsKey);
    await prefs.remove(_equippedHatKey);
    await prefs.remove(_pendingCelebrationKey);
    await prefs.remove(_pendingCelebrationCoinsKey);
  }
}
