import 'package:flutter/material.dart';

import 'game_progress.dart';

enum CosmeticKind { hat, outfit, pet, badge }

enum CosmeticSource { reward, shop }

/// Catalog entry for Shop / Awards.
class CosmeticItem {
  const CosmeticItem({
    required this.id,
    required this.name,
    required this.kind,
    required this.icon,
    required this.color,
    required this.source,
    this.shopPrice,
    this.unlockHint,
    this.description = '',
    this.imageAsset,
  });

  final String id;
  final String name;
  final CosmeticKind kind;
  final IconData icon;
  final Color color;
  final CosmeticSource source;
  final int? shopPrice;
  final String? unlockHint;
  final String description;
  final String? imageAsset;

  bool get isShopItem => source == CosmeticSource.shop && shopPrice != null;

  static const List<CosmeticItem> all = <CosmeticItem>[
    // —— Hats (rewards) ——
    CosmeticItem(
      id: GameProgress.ecoHatId,
      name: GameProgress.ecoHatName,
      kind: CosmeticKind.hat,
      icon: Icons.eco,
      color: Color(0xFF66BB6A),
      source: CosmeticSource.reward,
      unlockHint: 'Complete Park Level 1',
      description: 'A leafy starter cap for eco-rookies.',
    ),
    CosmeticItem(
      id: GameProgress.greenCapId,
      name: GameProgress.greenCapName,
      kind: CosmeticKind.hat,
      icon: Icons.park,
      color: Color(0xFF43A047),
      source: CosmeticSource.reward,
      unlockHint: 'Restore the Park',
      description: 'Fresh green for a park hero.',
    ),
    CosmeticItem(
      id: GameProgress.beachHatId,
      name: GameProgress.beachHatName,
      kind: CosmeticKind.hat,
      icon: Icons.beach_access,
      color: Color(0xFF29B6F6),
      source: CosmeticSource.reward,
      unlockHint: 'Restore the Beach',
      description: 'Keeps the sun off while you save the shore.',
    ),
    CosmeticItem(
      id: GameProgress.heroCrownId,
      name: GameProgress.heroCrownName,
      kind: CosmeticKind.hat,
      icon: Icons.workspace_premium,
      color: Color(0xFFFFD54F),
      source: CosmeticSource.reward,
      unlockHint: 'Finish Green Town',
      description: 'Crown of the Recycling Hero.',
    ),
    // —— Hats (shop) ——
    CosmeticItem(
      id: 'shop_leaf_bandana',
      name: 'Leaf Bandana',
      kind: CosmeticKind.hat,
      icon: Icons.filter_vintage,
      color: Color(0xFF8BC34A),
      source: CosmeticSource.shop,
      shopPrice: 80,
      description: 'Tied with care for tidy trash days.',
    ),
    CosmeticItem(
      id: 'shop_sunny_visor',
      name: 'Sunny Visor',
      kind: CosmeticKind.hat,
      icon: Icons.wb_sunny,
      color: Color(0xFFFFB300),
      source: CosmeticSource.shop,
      shopPrice: 100,
      description: 'Bright shade for plaza cleanups.',
    ),
    CosmeticItem(
      id: 'shop_rain_hood',
      name: 'Rain Hood',
      kind: CosmeticKind.hat,
      icon: Icons.umbrella,
      color: Color(0xFF5C6BC0),
      source: CosmeticSource.shop,
      shopPrice: 120,
      description: 'Ready for stormy sorting missions.',
    ),
    // —— Outfits ——
    CosmeticItem(
      id: GameProgress.goldenEcoOutfitId,
      name: GameProgress.goldenEcoOutfitName,
      kind: CosmeticKind.outfit,
      icon: Icons.checkroom,
      color: Color(0xFFFFCA28),
      source: CosmeticSource.reward,
      unlockHint: 'Finish Green Town',
      description: 'Shines like a clean fountain.',
    ),
    CosmeticItem(
      id: GameProgress.workGlovesId,
      name: GameProgress.workGlovesName,
      kind: CosmeticKind.outfit,
      icon: Icons.front_hand,
      color: Color(0xFF8D6E63),
      source: CosmeticSource.reward,
      unlockHint: 'Restore the Neighborhood',
      description: 'Tough gloves for community cleanups.',
    ),
    CosmeticItem(
      id: 'shop_sparkle_sneakers',
      name: 'Sparkle Sneakers',
      kind: CosmeticKind.outfit,
      icon: Icons.directions_run,
      color: Color(0xFFEC407A),
      source: CosmeticSource.shop,
      shopPrice: 140,
      description: 'Dash from bin to bin in style.',
    ),
    CosmeticItem(
      id: 'shop_eco_scarf',
      name: 'Eco Scarf',
      kind: CosmeticKind.outfit,
      icon: Icons.texture,
      color: Color(0xFF26A69A),
      source: CosmeticSource.shop,
      shopPrice: 90,
      description: 'Woven from recycled yarn vibes.',
    ),
    // —— Pets ——
    CosmeticItem(
      id: GameProgress.seaTurtlePetId,
      name: GameProgress.seaTurtlePetName,
      kind: CosmeticKind.pet,
      icon: Icons.pets,
      color: Color(0xFF26A69A),
      source: CosmeticSource.reward,
      unlockHint: 'Restore the Beach',
      description: 'A grateful friend from the shore.',
    ),
    CosmeticItem(
      id: GameProgress.petCompanionId,
      name: GameProgress.petCompanionName,
      kind: CosmeticKind.pet,
      icon: Icons.cruelty_free,
      color: Color(0xFFFF7043),
      source: CosmeticSource.reward,
      unlockHint: 'Restore the Neighborhood',
      description: 'A cheerful neighborhood buddy.',
    ),
    CosmeticItem(
      id: 'shop_seedling_pal',
      name: 'Seedling Pal',
      kind: CosmeticKind.pet,
      icon: Icons.spa,
      color: Color(0xFF66BB6A),
      source: CosmeticSource.shop,
      shopPrice: 160,
      description: 'A tiny plant that loves compost.',
    ),
    // —— Badges / awards ——
    CosmeticItem(
      id: GameProgress.recyclingRookieBadgeId,
      name: GameProgress.recyclingRookieTitle,
      kind: CosmeticKind.badge,
      icon: Icons.military_tech,
      color: Color(0xFF66BB6A),
      source: CosmeticSource.reward,
      unlockHint: 'Complete Park Level 1',
      description: 'Your first eco title.',
      imageAsset: 'assets/images/png/badge_recycling_rookie.png',
    ),
    CosmeticItem(
      id: GameProgress.scholarBadgeId,
      name: GameProgress.scholarBadgeTitle,
      kind: CosmeticKind.badge,
      icon: Icons.school,
      color: Color(0xFF42A5F5),
      source: CosmeticSource.reward,
      unlockHint: 'Restore the School',
      description: 'Smart sorting on campus.',
      imageAsset: 'assets/images/png/badge_scholar_sorter.png',
    ),
    CosmeticItem(
      id: GameProgress.ecoSafetyBadgeId,
      name: GameProgress.ecoSafetyBadgeName,
      kind: CosmeticKind.badge,
      icon: Icons.health_and_safety,
      color: Color(0xFFE53935),
      source: CosmeticSource.reward,
      unlockHint: 'Complete Neighborhood Level 5',
      description: 'Hazardous waste handled safely.',
      imageAsset: 'assets/images/png/badge_eco_safety.png',
    ),
    CosmeticItem(
      id: GameProgress.communityGuardianBadgeId,
      name: GameProgress.communityGuardianTitle,
      kind: CosmeticKind.badge,
      icon: Icons.groups,
      color: Color(0xFFEC407A),
      source: CosmeticSource.reward,
      unlockHint: 'Restore the Neighborhood',
      description: 'Trusted by every neighbor.',
      imageAsset: 'assets/images/png/badge_community_guardian.png',
    ),
    CosmeticItem(
      id: GameProgress.oceanGuardianBadgeId,
      name: GameProgress.oceanGuardianBadgeName,
      kind: CosmeticKind.badge,
      icon: Icons.waves,
      color: Color(0xFF29B6F6),
      source: CosmeticSource.reward,
      unlockHint: 'Complete Beach Level 7',
      description: 'Protector of marine life.',
      imageAsset: 'assets/images/png/badge_ocean_guardian.png',
    ),
    CosmeticItem(
      id: GameProgress.ecoExpertBadgeId,
      name: GameProgress.ecoExpertBadgeName,
      kind: CosmeticKind.badge,
      icon: Icons.workspace_premium,
      color: Color(0xFF5C6BC0),
      source: CosmeticSource.reward,
      unlockHint: 'Complete Town Center Level 9',
      description: 'Master of the four bins.',
      imageAsset: 'assets/images/png/badge_eco_expert.png',
    ),
    CosmeticItem(
      id: GameProgress.recyclingHeroBadgeId,
      name: GameProgress.recyclingHeroTitle,
      kind: CosmeticKind.badge,
      icon: Icons.emoji_events,
      color: Color(0xFFFFD54F),
      source: CosmeticSource.reward,
      unlockHint: 'Finish Green Town',
      description: 'Champion of waste segregation.',
      imageAsset: 'assets/images/png/badge_recycling_hero.png',
    ),
    CosmeticItem(
      id: GameProgress.finalCompletionBadgeId,
      name: GameProgress.finalCompletionBadgeName,
      kind: CosmeticKind.badge,
      icon: Icons.star,
      color: Color(0xFFFFCA28),
      source: CosmeticSource.reward,
      unlockHint: 'Finish Green Town',
      description: 'Every district restored.',
      imageAsset: 'assets/images/png/badge_final_completion.png',
    ),
  ];

  static List<CosmeticItem> ofKind(CosmeticKind kind) =>
      all.where((CosmeticItem c) => c.kind == kind).toList();

  static List<CosmeticItem> shopItems() =>
      all.where((CosmeticItem c) => c.isShopItem).toList();

  static List<CosmeticItem> badges() => ofKind(CosmeticKind.badge);

  static CosmeticItem? byId(String id) {
    for (final CosmeticItem c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}
