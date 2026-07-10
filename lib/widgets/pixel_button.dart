import 'package:flutter/material.dart';

/// A chunky, pixel-art style push button with a hard drop shadow.
///
/// The button "presses down" when tapped by shrinking its offset shadow,
/// giving a tactile, retro-game feel that is friendly for young players.
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.color,
    this.icon,
    this.width = 320,
    this.compact = false,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;
  final IconData? icon;

  /// Fixed button width. Pass `null` to size the button to its label so long
  /// labels are never clipped.
  final double? width;

  /// Smaller padding and font for tight mobile layouts.
  final bool compact;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _pressed = false;

  double get _depth => widget.compact ? 3 : 6;

  double get _outlineOffset => widget.compact ? 2 : 4;

  Color get _shadowColor => HSLColor.fromColor(widget.color)
      .withLightness(
        (HSLColor.fromColor(widget.color).lightness - 0.22).clamp(0.0, 1.0),
      )
      .toColor();

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  Widget _buildLabel() {
    final double fontSize = widget.compact ? 26 : 40;
    final Text text = Text(
      widget.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Jersey10',
        fontSize: fontSize,
        height: 1,
        color: Colors.white,
        letterSpacing: 1.5,
        shadows: const <Shadow>[
          Shadow(color: Color(0xFF2B2B3A), offset: Offset(2, 2)),
        ],
      ),
    );
    // With a fixed width the text must be flexible so it can ellipsize;
    // with auto width the button hugs the (unclipped) text instead.
    return widget.width == null ? text : Flexible(child: text);
  }

  @override
  Widget build(BuildContext context) {
    final double depth = _depth;
    final double offset = _pressed ? 0 : depth;
    final double vPad = widget.compact ? 7 : 14;
    final double hPad = widget.compact ? 14 : 20;
    final double iconSize = widget.compact ? 20 : 28;
    final double borderW = widget.compact ? 3 : 4;

    return Padding(
      // Reserve room for the drop shadow so the last button never clips.
      padding: EdgeInsets.only(bottom: depth + _outlineOffset),
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          width: widget.width,
          transform: Matrix4.translationValues(0, depth - offset, 0),
          decoration: BoxDecoration(
            color: widget.color,
            border: Border.all(color: const Color(0xFF2B2B3A), width: borderW),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: _shadowColor,
                offset: Offset(0, offset),
              ),
              BoxShadow(
                color: const Color(0xFF2B2B3A),
                offset: Offset(0, offset + _outlineOffset),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
          child: Row(
            // When there is no fixed width, hug the label so it is never
            // clipped; otherwise fill the width and centre the content.
            mainAxisSize:
                widget.width == null ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (widget.icon != null) ...<Widget>[
                Icon(widget.icon, color: Colors.white, size: iconSize),
                SizedBox(width: widget.compact ? 6 : 12),
              ],
              _buildLabel(),
            ],
          ),
        ),
      ),
    );
  }
}
