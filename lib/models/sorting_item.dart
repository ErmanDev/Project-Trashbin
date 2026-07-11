import 'package:flutter/material.dart';

/// Waste-bin categories used in the sorting mini-game.
enum BinType {
  recycling,
  compost,
  residual,
  hazardous,
}

extension BinTypeLabel on BinType {
  String get label => switch (this) {
        BinType.recycling => 'Recycling',
        BinType.compost => 'Compost',
        BinType.residual => 'Residual',
        BinType.hazardous => 'Hazardous',
      };
}

/// A draggable piece of litter the player must sort into the right bin.
class WasteItem {
  const WasteItem({
    required this.id,
    required this.name,
    required this.correctBin,
    required this.imageAsset,
    required this.color,
    required this.impactLabel,
    required this.impactKg,
    this.wrongBinMessages = const <BinType, String>{},
  });

  final String id;
  final String name;
  final BinType correctBin;
  final String imageAsset;
  final Color color;

  /// Label shown on the reward screen (e.g. "Plastic Recycled").
  final String impactLabel;

  /// Kilograms diverted when this item is sorted correctly.
  final double impactKg;

  /// Optional lesson text when the player drops this item in the wrong bin.
  final Map<BinType, String> wrongBinMessages;

  String? messageForWrongBin(BinType bin) => wrongBinMessages[bin];

  /// Lesson shown on any wrong drop (specific message or a short default).
  String lessonForWrongBin(BinType bin) {
    return messageForWrongBin(bin) ??
        '$name belongs in ${correctBin.label}.';
  }
}

/// Visual + label metadata for a drop target bin.
class WasteBin {
  const WasteBin({
    required this.type,
    required this.label,
    required this.imageAsset,
    required this.color,
  });

  final BinType type;
  final String label;
  final String imageAsset;
  final Color color;
}

/// Park Level 1 — Phase 2 sorting sequence.
class ParkSortingLevel {
  ParkSortingLevel._();

  static const List<WasteBin> bins = <WasteBin>[
    WasteBin(
      type: BinType.recycling,
      label: 'Recycling',
      imageAsset: 'assets/images/png/bin_recycling.png',
      color: Color(0xFF1E88E5),
    ),
    WasteBin(
      type: BinType.compost,
      label: 'Compost',
      imageAsset: 'assets/images/png/bin_compost.png',
      color: Color(0xFF6D4C41),
    ),
    WasteBin(
      type: BinType.hazardous,
      label: 'Hazardous',
      imageAsset: 'assets/images/png/bin_hazardous.png',
      color: Color(0xFFE53935),
    ),
  ];

  static const List<WasteItem> items = <WasteItem>[
    WasteItem(
      id: 'plastic_bottle',
      name: 'Plastic Bottle',
      correctBin: BinType.recycling,
      imageAsset: 'assets/images/png/waste_plastic_bottle.png',
      color: Color(0xFF42A5F5),
      impactLabel: 'Plastic Recycled',
      impactKg: 5,
    ),
    WasteItem(
      id: 'banana_peel',
      name: 'Banana Peel',
      correctBin: BinType.compost,
      imageAsset: 'assets/images/png/waste_banana_peel.png',
      color: Color(0xFFFFCA28),
      impactLabel: 'Compost',
      impactKg: 2,
    ),
    WasteItem(
      id: 'newspaper',
      name: 'Newspaper',
      correctBin: BinType.recycling,
      imageAsset: 'assets/images/png/waste_newspaper.png',
      color: Color(0xFF90A4AE),
      impactLabel: 'Paper',
      impactKg: 3,
    ),
    WasteItem(
      id: 'apple_core',
      name: 'Apple Core',
      correctBin: BinType.compost,
      imageAsset: 'assets/images/png/waste_apple_core.png',
      color: Color(0xFFEF5350),
      impactLabel: 'Compost',
      impactKg: 2,
    ),
    WasteItem(
      id: 'battery',
      name: 'Battery',
      correctBin: BinType.hazardous,
      imageAsset: 'assets/images/png/waste_battery.png',
      color: Color(0xFFFF7043),
      impactLabel: 'Hazardous Waste',
      impactKg: 1,
      wrongBinMessages: <BinType, String>{
        BinType.recycling:
            'Batteries contain harmful chemicals.\nThey belong in Hazardous Waste.',
      },
    ),
  ];

  static const int coinsPerCorrect = 10;
  static const String levelTitle = 'Park Level 1';
  static const int parkLevel = 1;
}

/// Park Level 2 — direct sorting (no puzzle), trickier items.
class ParkSortingLevel2 {
  ParkSortingLevel2._();

  static const List<WasteBin> bins = <WasteBin>[
    WasteBin(
      type: BinType.recycling,
      label: 'Recycling',
      imageAsset: 'assets/images/png/bin_recycling.png',
      color: Color(0xFF1E88E5),
    ),
    WasteBin(
      type: BinType.compost,
      label: 'Compost',
      imageAsset: 'assets/images/png/bin_compost.png',
      color: Color(0xFF6D4C41),
    ),
    WasteBin(
      type: BinType.hazardous,
      label: 'Hazardous',
      imageAsset: 'assets/images/png/bin_hazardous.png',
      color: Color(0xFFE53935),
    ),
  ];

  static const List<WasteItem> items = <WasteItem>[
    WasteItem(
      id: 'aluminum_can',
      name: 'Aluminum Can',
      correctBin: BinType.recycling,
      imageAsset: 'assets/images/png/waste_aluminum_can.png',
      color: Color(0xFFB0BEC5),
      impactLabel: 'Metal Recycled',
      impactKg: 4,
      wrongBinMessages: <BinType, String>{
        BinType.hazardous:
            'Aluminum cans are safe to recycle.\nPut them in Recycling!',
        BinType.compost:
            'Metal is not food waste.\nAluminum cans go in Recycling.',
      },
    ),
    WasteItem(
      id: 'glass_bottle',
      name: 'Glass Bottle',
      correctBin: BinType.recycling,
      imageAsset: 'assets/images/png/waste_glass_bottle.png',
      color: Color(0xFF66BB6A),
      impactLabel: 'Glass Recycled',
      impactKg: 5,
      wrongBinMessages: <BinType, String>{
        BinType.hazardous:
            'Clean glass bottles can be recycled.\nThey belong in Recycling.',
        BinType.compost:
            'Glass is not compost.\nPut glass bottles in Recycling.',
      },
    ),
    WasteItem(
      id: 'plastic_bag',
      name: 'Plastic Bag',
      correctBin: BinType.recycling,
      imageAsset: 'assets/images/png/waste_plastic_bag.png',
      color: Color(0xFF42A5F5),
      impactLabel: 'Plastic Recycled',
      impactKg: 2,
      wrongBinMessages: <BinType, String>{
        BinType.compost:
            'Plastic does not break down in compost.\nPlastic bags belong in Recycling.',
        BinType.hazardous:
            'Plastic bags are not hazardous waste.\nThey belong in Recycling.',
      },
    ),
    WasteItem(
      id: 'apple_core_l2',
      name: 'Apple Core',
      correctBin: BinType.compost,
      imageAsset: 'assets/images/png/waste_apple_core.png',
      color: Color(0xFFEF5350),
      impactLabel: 'Compost',
      impactKg: 2,
      wrongBinMessages: <BinType, String>{
        BinType.recycling:
            'Food scraps are not recyclable.\nApple cores belong in Compost.',
        BinType.hazardous:
            'Food scraps can become soil!\nApple cores belong in Compost.',
      },
    ),
    WasteItem(
      id: 'banana_peel_l2',
      name: 'Banana Peel',
      correctBin: BinType.compost,
      imageAsset: 'assets/images/png/waste_banana_peel.png',
      color: Color(0xFFFFCA28),
      impactLabel: 'Compost',
      impactKg: 2,
      wrongBinMessages: <BinType, String>{
        BinType.recycling:
            'Banana peels are food scraps.\nThey belong in Compost.',
        BinType.hazardous:
            'Food scraps can become soil!\nBanana peels belong in Compost.',
      },
    ),
    WasteItem(
      id: 'battery_l2',
      name: 'Battery',
      correctBin: BinType.hazardous,
      imageAsset: 'assets/images/png/waste_battery.png',
      color: Color(0xFFFF7043),
      impactLabel: 'Hazardous Waste',
      impactKg: 1,
      wrongBinMessages: <BinType, String>{
        BinType.recycling:
            'Batteries contain harmful chemicals.\nThey belong in Hazardous Waste.',
        BinType.compost:
            'Never compost batteries!\nThey belong in Hazardous Waste.',
      },
    ),
    WasteItem(
      id: 'broken_toy',
      name: 'Broken Toy',
      correctBin: BinType.hazardous,
      imageAsset: 'assets/images/png/waste_broken_toy.png',
      color: Color(0xFFFFCA28),
      impactLabel: 'Hazardous Waste',
      impactKg: 2,
      wrongBinMessages: <BinType, String>{
        BinType.recycling:
            'Broken toys may have batteries or mixed parts.\nThey belong in Hazardous Waste.',
        BinType.compost:
            'Toys are not food waste.\nBroken toys belong in Hazardous Waste.',
      },
    ),
  ];

  static const int coinsPerCorrect = 10;
  static const String levelTitle = 'Park Level 2';
  static const int parkLevel = 2;
}

/// School Level 3 — puzzle then sorting, compost focus.
class SchoolSortingLevel3 {
  SchoolSortingLevel3._();

  static const List<WasteBin> bins = ParkSortingLevel.bins;

  static const List<WasteItem> items = <WasteItem>[
    WasteItem(
      id: 's3_banana',
      name: 'Banana Peel',
      correctBin: BinType.compost,
      imageAsset: 'assets/images/png/waste_banana_peel.png',
      color: Color(0xFFFFCA28),
      impactLabel: 'Compost',
      impactKg: 2,
      wrongBinMessages: <BinType, String>{
        BinType.recycling:
            'Food scraps become compost, not recycling.\nBanana peels belong in Compost.',
      },
    ),
    WasteItem(
      id: 's3_apple',
      name: 'Apple Core',
      correctBin: BinType.compost,
      imageAsset: 'assets/images/png/waste_apple_core.png',
      color: Color(0xFFEF5350),
      impactLabel: 'Compost',
      impactKg: 2,
      wrongBinMessages: <BinType, String>{
        BinType.recycling:
            'Apple cores are food scraps.\nThey belong in Compost.',
      },
    ),
    WasteItem(
      id: 's3_sandwich',
      name: 'Leftover Sandwich',
      correctBin: BinType.compost,
      imageAsset: 'assets/images/png/waste_sandwich.png',
      color: Color(0xFF8D6E63),
      impactLabel: 'Compost',
      impactKg: 3,
      wrongBinMessages: <BinType, String>{
        BinType.recycling:
            'Leftover food can become soil!\nSandwiches belong in Compost.',
        BinType.hazardous:
            'Food is not hazardous waste.\nLeftover sandwiches belong in Compost.',
      },
    ),
    WasteItem(
      id: 's3_bottle',
      name: 'Plastic Bottle',
      correctBin: BinType.recycling,
      imageAsset: 'assets/images/png/waste_plastic_bottle.png',
      color: Color(0xFF42A5F5),
      impactLabel: 'Plastic Recycled',
      impactKg: 5,
    ),
    WasteItem(
      id: 's3_paper',
      name: 'Newspaper',
      correctBin: BinType.recycling,
      imageAsset: 'assets/images/png/waste_newspaper.png',
      color: Color(0xFF90A4AE),
      impactLabel: 'Paper',
      impactKg: 3,
    ),
  ];

  static const int coinsPerCorrect = 10;
  static const String levelTitle = 'School Level 3';
  static const int levelNumber = 3;
  static const String locationId = 'school';
}

/// School Level 4 — direct sorting, trickier campus waste.
class SchoolSortingLevel4 {
  SchoolSortingLevel4._();

  static const List<WasteBin> bins = ParkSortingLevel.bins;

  static const List<WasteItem> items = <WasteItem>[
    WasteItem(
      id: 's4_can',
      name: 'Aluminum Can',
      correctBin: BinType.recycling,
      imageAsset: 'assets/images/png/waste_aluminum_can.png',
      color: Color(0xFFB0BEC5),
      impactLabel: 'Metal Recycled',
      impactKg: 4,
      wrongBinMessages: <BinType, String>{
        BinType.compost: 'Metal is not food waste.\nCans go in Recycling.',
      },
    ),
    WasteItem(
      id: 's4_glass',
      name: 'Glass Bottle',
      correctBin: BinType.recycling,
      imageAsset: 'assets/images/png/waste_glass_bottle.png',
      color: Color(0xFF66BB6A),
      impactLabel: 'Glass Recycled',
      impactKg: 5,
    ),
    WasteItem(
      id: 's4_bag',
      name: 'Plastic Bag',
      correctBin: BinType.recycling,
      imageAsset: 'assets/images/png/waste_plastic_bag.png',
      color: Color(0xFF42A5F5),
      impactLabel: 'Plastic Recycled',
      impactKg: 2,
      wrongBinMessages: <BinType, String>{
        BinType.compost:
            'Plastic does not compost.\nPlastic bags belong in Recycling.',
      },
    ),
    WasteItem(
      id: 's4_sandwich',
      name: 'Leftover Sandwich',
      correctBin: BinType.compost,
      imageAsset: 'assets/images/png/waste_sandwich.png',
      color: Color(0xFF8D6E63),
      impactLabel: 'Compost',
      impactKg: 3,
      wrongBinMessages: <BinType, String>{
        BinType.recycling:
            'Food leftovers become compost.\nThey do not go in Recycling.',
      },
    ),
    WasteItem(
      id: 's4_banana',
      name: 'Banana Peel',
      correctBin: BinType.compost,
      imageAsset: 'assets/images/png/waste_banana_peel.png',
      color: Color(0xFFFFCA28),
      impactLabel: 'Compost',
      impactKg: 2,
    ),
    WasteItem(
      id: 's4_battery',
      name: 'Battery',
      correctBin: BinType.hazardous,
      imageAsset: 'assets/images/png/waste_battery.png',
      color: Color(0xFFFF7043),
      impactLabel: 'Hazardous Waste',
      impactKg: 1,
      wrongBinMessages: <BinType, String>{
        BinType.recycling:
            'Batteries contain harmful chemicals.\nThey belong in Hazardous Waste.',
        BinType.compost:
            'Never compost batteries!\nThey belong in Hazardous Waste.',
      },
    ),
    WasteItem(
      id: 's4_toy',
      name: 'Broken Toy',
      correctBin: BinType.hazardous,
      imageAsset: 'assets/images/png/waste_broken_toy.png',
      color: Color(0xFFFFCA28),
      impactLabel: 'Hazardous Waste',
      impactKg: 2,
      wrongBinMessages: <BinType, String>{
        BinType.recycling:
            'Broken toys may have batteries or mixed parts.\nThey belong in Hazardous Waste.',
      },
    ),
  ];

  static const int coinsPerCorrect = 10;
  static const String levelTitle = 'School Level 4';
  static const int levelNumber = 4;
  static const String locationId = 'school';
}

/// Neighborhood Level 5 — Phase 2 sorting with Residual + Hazardous focus.
class NeighborhoodSortingLevel5 {
  NeighborhoodSortingLevel5._();

  static const List<WasteBin> bins = <WasteBin>[
    WasteBin(
      type: BinType.recycling,
      label: 'Recycling',
      imageAsset: 'assets/images/png/bin_recycling.png',
      color: Color(0xFF1E88E5),
    ),
    WasteBin(
      type: BinType.compost,
      label: 'Compost',
      imageAsset: 'assets/images/png/bin_compost.png',
      color: Color(0xFF6D4C41),
    ),
    WasteBin(
      type: BinType.residual,
      label: 'Residual',
      imageAsset: 'assets/images/png/bin_residual.png',
      color: Color(0xFF78909C),
    ),
    WasteBin(
      type: BinType.hazardous,
      label: 'Hazardous',
      imageAsset: 'assets/images/png/bin_hazardous.png',
      color: Color(0xFFE53935),
    ),
  ];

  static const List<WasteItem> items = <WasteItem>[
    WasteItem(
      id: 'n5_bottle',
      name: 'Plastic Bottle',
      correctBin: BinType.recycling,
      imageAsset: 'assets/images/png/waste_plastic_bottle.png',
      color: Color(0xFF42A5F5),
      impactLabel: 'Plastic Recycled',
      impactKg: 3,
      wrongBinMessages: <BinType, String>{
        BinType.residual:
            'Clean plastic bottles can be recycled.\nThey belong in Recycling.',
        BinType.compost:
            'Plastic does not compost.\nPlastic bottles belong in Recycling.',
      },
    ),
    WasteItem(
      id: 'n5_veggies',
      name: 'Vegetable Scraps',
      correctBin: BinType.compost,
      imageAsset: 'assets/images/png/waste_vegetable_scraps.png',
      color: Color(0xFF66BB6A),
      impactLabel: 'Compost Produced',
      impactKg: 3,
      wrongBinMessages: <BinType, String>{
        BinType.recycling:
            'Food scraps are not recyclable.\nVegetable scraps belong in Compost.',
        BinType.residual:
            'Kitchen scraps can become soil!\nVegetable scraps belong in Compost.',
      },
    ),
    WasteItem(
      id: 'n5_tissue',
      name: 'Used Tissue',
      correctBin: BinType.residual,
      imageAsset: 'assets/images/png/waste_used_tissue.png',
      color: Color(0xFFECEFF1),
      impactLabel: 'Residual Waste',
      impactKg: 1,
      wrongBinMessages: <BinType, String>{
        BinType.recycling:
            'Used tissues are dirty and not recyclable.\nThey belong in Residual.',
        BinType.compost:
            'Used tissues may carry germs.\nThey belong in Residual.',
      },
    ),
    WasteItem(
      id: 'n5_battery',
      name: 'AA Battery',
      correctBin: BinType.hazardous,
      imageAsset: 'assets/images/png/waste_battery.png',
      color: Color(0xFFFF7043),
      impactLabel: 'Hazardous Waste Safely Collected',
      impactKg: 1,
      wrongBinMessages: <BinType, String>{
        BinType.recycling:
            'Batteries contain chemicals that can leak into the environment.\nThey should be collected as hazardous waste and disposed of safely.',
        BinType.compost:
            'Never compost batteries!\nThey belong in Hazardous Waste.',
        BinType.residual:
            'Batteries are special waste.\nThey belong in Hazardous Waste.',
      },
    ),
    WasteItem(
      id: 'n5_bulb',
      name: 'Broken Light Bulb',
      correctBin: BinType.hazardous,
      imageAsset: 'assets/images/png/waste_light_bulb.png',
      color: Color(0xFFFFF176),
      impactLabel: 'Hazardous Waste Safely Collected',
      impactKg: 1,
      wrongBinMessages: <BinType, String>{
        BinType.recycling:
            'Broken bulbs can cut and may contain harmful materials.\nThey belong in Hazardous Waste.',
        BinType.residual:
            'Broken light bulbs need special handling.\nThey belong in Hazardous Waste.',
      },
    ),
    WasteItem(
      id: 'n5_glass',
      name: 'Glass Bottle',
      correctBin: BinType.recycling,
      imageAsset: 'assets/images/png/waste_glass_bottle.png',
      color: Color(0xFF66BB6A),
      impactLabel: 'Plastic Recycled',
      impactKg: 5,
    ),
    WasteItem(
      id: 'n5_wrapper',
      name: 'Food Wrapper',
      correctBin: BinType.residual,
      imageAsset: 'assets/images/png/waste_food_wrapper.png',
      color: Color(0xFFFFA726),
      impactLabel: 'Residual Waste',
      impactKg: 1,
      wrongBinMessages: <BinType, String>{
        BinType.recycling:
            'Dirty snack wrappers usually cannot be recycled.\nThey belong in Residual.',
        BinType.compost:
            'Plastic wrappers do not compost.\nThey belong in Residual.',
      },
    ),
    WasteItem(
      id: 'n5_eggshells',
      name: 'Eggshells',
      correctBin: BinType.compost,
      imageAsset: 'assets/images/png/waste_eggshells.png',
      color: Color(0xFFFFF8E1),
      impactLabel: 'Compost Produced',
      impactKg: 2,
      wrongBinMessages: <BinType, String>{
        BinType.recycling:
            'Eggshells are food waste, not recyclable packaging.\nThey belong in Compost.',
      },
    ),
    WasteItem(
      id: 'n5_magazine',
      name: 'Old Magazine',
      correctBin: BinType.recycling,
      imageAsset: 'assets/images/png/waste_newspaper.png',
      color: Color(0xFF90A4AE),
      impactLabel: 'Plastic Recycled',
      impactKg: 2,
    ),
    WasteItem(
      id: 'n5_paint',
      name: 'Empty Paint Can',
      correctBin: BinType.hazardous,
      imageAsset: 'assets/images/png/waste_paint_can.png',
      color: Color(0xFF8D6E63),
      impactLabel: 'Hazardous Waste Safely Collected',
      impactKg: 2,
      wrongBinMessages: <BinType, String>{
        BinType.recycling:
            'Paint cans with leftover paint are hazardous.\nThey belong in Hazardous Waste.',
        BinType.residual:
            'Leftover paint can harm the environment.\nPaint cans belong in Hazardous Waste.',
      },
    ),
  ];

  static const int coinsPerCorrect = 10;
  static const String levelTitle = 'Neighborhood Level 5';
  static const int levelNumber = 5;
  static const String locationId = 'neighborhood';
}

/// Neighborhood Level 6 — trickier sorting on the cleaner street (no puzzle).
class NeighborhoodSortingLevel6 {
  NeighborhoodSortingLevel6._();

  static const List<WasteBin> bins = NeighborhoodSortingLevel5.bins;

  static const List<WasteItem> items = <WasteItem>[
    WasteItem(
      id: 'n6_battery',
      name: 'AA Battery',
      correctBin: BinType.hazardous,
      imageAsset: 'assets/images/png/waste_battery.png',
      color: Color(0xFFFF7043),
      impactLabel: 'Hazardous Waste',
      impactKg: 1,
      wrongBinMessages: <BinType, String>{
        BinType.recycling:
            'Batteries contain chemicals that can leak into the environment.\nThey should be collected as hazardous waste and disposed of safely.',
        BinType.residual:
            'Batteries are special waste.\nThey belong in Hazardous Waste.',
      },
    ),
    WasteItem(
      id: 'n6_wrapper',
      name: 'Food Wrapper',
      correctBin: BinType.residual,
      imageAsset: 'assets/images/png/waste_food_wrapper.png',
      color: Color(0xFFFFA726),
      impactLabel: 'Residual Waste',
      impactKg: 1,
      wrongBinMessages: <BinType, String>{
        BinType.recycling:
            'Dirty snack wrappers usually cannot be recycled.\nThey belong in Residual.',
      },
    ),
    WasteItem(
      id: 'n6_can',
      name: 'Aluminum Can',
      correctBin: BinType.recycling,
      imageAsset: 'assets/images/png/waste_aluminum_can.png',
      color: Color(0xFFB0BEC5),
      impactLabel: 'Metal Recycled',
      impactKg: 4,
    ),
    WasteItem(
      id: 'n6_paint',
      name: 'Empty Paint Can',
      correctBin: BinType.hazardous,
      imageAsset: 'assets/images/png/waste_paint_can.png',
      color: Color(0xFF8D6E63),
      impactLabel: 'Hazardous Waste',
      impactKg: 2,
      wrongBinMessages: <BinType, String>{
        BinType.recycling:
            'Paint cans with leftover paint are hazardous.\nThey belong in Hazardous Waste.',
      },
    ),
    WasteItem(
      id: 'n6_eggshells',
      name: 'Eggshells',
      correctBin: BinType.compost,
      imageAsset: 'assets/images/png/waste_eggshells.png',
      color: Color(0xFFFFF8E1),
      impactLabel: 'Compost',
      impactKg: 2,
    ),
    WasteItem(
      id: 'n6_bulb',
      name: 'Broken Light Bulb',
      correctBin: BinType.hazardous,
      imageAsset: 'assets/images/png/waste_light_bulb.png',
      color: Color(0xFFFFF176),
      impactLabel: 'Hazardous Waste',
      impactKg: 1,
    ),
    WasteItem(
      id: 'n6_tissue',
      name: 'Used Tissue',
      correctBin: BinType.residual,
      imageAsset: 'assets/images/png/waste_used_tissue.png',
      color: Color(0xFFECEFF1),
      impactLabel: 'Residual Waste',
      impactKg: 1,
    ),
    WasteItem(
      id: 'n6_glass',
      name: 'Glass Bottle',
      correctBin: BinType.recycling,
      imageAsset: 'assets/images/png/waste_glass_bottle.png',
      color: Color(0xFF66BB6A),
      impactLabel: 'Glass Recycled',
      impactKg: 5,
    ),
    WasteItem(
      id: 'n6_veggies',
      name: 'Vegetable Scraps',
      correctBin: BinType.compost,
      imageAsset: 'assets/images/png/waste_vegetable_scraps.png',
      color: Color(0xFF66BB6A),
      impactLabel: 'Compost',
      impactKg: 3,
    ),
    WasteItem(
      id: 'n6_toy',
      name: 'Broken Toy',
      correctBin: BinType.hazardous,
      imageAsset: 'assets/images/png/waste_broken_toy.png',
      color: Color(0xFFFFCA28),
      impactLabel: 'Hazardous Waste',
      impactKg: 2,
      wrongBinMessages: <BinType, String>{
        BinType.recycling:
            'Broken toys may have batteries or mixed parts.\nThey belong in Hazardous Waste.',
        BinType.residual:
            'Broken toys need special handling.\nThey belong in Hazardous Waste.',
      },
    ),
  ];

  static const int coinsPerCorrect = 10;
  static const String levelTitle = 'Neighborhood Level 6';
  static const int levelNumber = 6;
  static const String locationId = 'neighborhood';
}
