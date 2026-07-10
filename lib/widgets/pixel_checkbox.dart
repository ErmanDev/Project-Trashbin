import 'package:flutter/material.dart';

/// A chunky pixel-art style toggle box.
///
/// When [value] is true it shows a green box with a white check mark
/// (used here for "unmuted"); when false it shows a muted red box with a
/// cross. Tapping anywhere on the widget flips the value.
class PixelCheckbox extends StatelessWidget {
  const PixelCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 56,
    this.compact = false,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;
  final bool compact;

  static const Color _onColor = Color(0xFF4CAF50); // green = unmuted
  static const Color _offColor = Color(0xFFEF5350); // red = muted
  static const Color _border = Color(0xFF2B2B3A);

  @override
  Widget build(BuildContext context) {
    final Color fill = value ? _onColor : _offColor;
    final Color shadow = HSLColor.fromColor(fill)
        .withLightness(
          (HSLColor.fromColor(fill).lightness - 0.22).clamp(0.0, 1.0),
        )
        .toColor();
    final double depth = compact ? 2 : 4;
    final double outline = compact ? 4 : 8;
    final double borderW = compact ? 3 : 4;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: _border, width: borderW),
          boxShadow: <BoxShadow>[
            BoxShadow(color: shadow, offset: Offset(0, depth)),
            BoxShadow(color: _border, offset: Offset(0, outline)),
          ],
        ),
        child: Icon(
          value ? Icons.check : Icons.close,
          color: Colors.white,
          size: size * 0.6,
          shadows: const <Shadow>[
            Shadow(color: _border, offset: Offset(2, 2)),
          ],
        ),
      ),
    );
  }
}
