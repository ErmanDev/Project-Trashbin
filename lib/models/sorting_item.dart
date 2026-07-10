import 'package:flutter/material.dart';

/// The three waste-bin categories used in the sorting mini-game.
enum BinType {
  recycling,
  compost,
  hazardous,
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
}
