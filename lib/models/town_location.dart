import 'package:flutter/material.dart';

/// A location node on the town map.
///
/// [position] is a fractional offset (0..1) over the map background image,
/// roughly aligned with the matching zone painted in `town_map_bg.png`.
class TownLocation {
  const TownLocation({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.position,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final Alignment position;

  /// The five town locations, in progression order.
  static const List<TownLocation> all = <TownLocation>[
    TownLocation(
      id: 'park',
      name: 'Park',
      icon: Icons.park,
      color: Color(0xFF4CAF50),
      position: Alignment(-0.66, 0.28),
    ),
    TownLocation(
      id: 'school',
      name: 'School',
      icon: Icons.school,
      color: Color(0xFFFFB300),
      position: Alignment(-0.42, -0.6),
    ),
    TownLocation(
      id: 'neighborhood',
      name: 'Neighborhood',
      icon: Icons.holiday_village,
      color: Color(0xFFEC407A),
      position: Alignment(0.02, 0.42),
    ),
    TownLocation(
      id: 'beach',
      name: 'Beach',
      icon: Icons.beach_access,
      color: Color(0xFF29B6F6),
      position: Alignment(0.78, 0.12),
    ),
    TownLocation(
      id: 'town_center',
      name: 'Town Center',
      icon: Icons.location_city,
      color: Color(0xFF7E57C2),
      position: Alignment(0.18, -0.62),
    ),
  ];
}
