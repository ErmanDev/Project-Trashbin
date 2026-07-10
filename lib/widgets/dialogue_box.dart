import 'package:flutter/material.dart';

/// A Ren'Py-style dialogue box shown at the bottom of a cinematic.
///
/// Renders an optional speaker name tag (so conversations can switch between
/// speakers) above a bordered text panel. The [text] is supplied by the
/// caller, which lets the parent drive a typewriter/reveal effect.
class DialogueBox extends StatelessWidget {
  const DialogueBox({
    super.key,
    required this.text,
    this.speakerName,
    this.accent = const Color(0xFF4CAF50),
    this.showContinueHint = false,
    this.showSpeakerName = true,
  });

  final String text;
  final String? speakerName;
  final Color accent;
  final bool showContinueHint;

  /// When false, only the text panel is drawn (speaker tag rendered separately).
  final bool showSpeakerName;

  static const Color _panel = Color(0xF00E0E1A);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (showSpeakerName &&
            speakerName != null &&
            speakerName!.isNotEmpty)
          SpeakerNameTag(name: speakerName!, accent: accent),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          constraints: const BoxConstraints(minHeight: 96),
          decoration: BoxDecoration(
            color: _panel,
            border: Border.all(color: accent, width: 4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'Jersey10',
                    fontSize: 34,
                    height: 1.15,
                    color: Colors.white,
                  ),
                ),
              ),
              if (showContinueHint)
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 2),
                  child: _BlinkingArrow(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The floating name label above a [DialogueBox] text panel.
class SpeakerNameTag extends StatelessWidget {
  const SpeakerNameTag({
    super.key,
    required this.name,
    required this.accent,
    this.compact = false,
  });

  final String name;
  final Color accent;
  final bool compact;

  static const Color _border = Color(0xFF2B2B3A);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: compact ? 8 : 12),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: accent,
        border: Border.all(color: _border, width: compact ? 3 : 4),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontFamily: 'Jersey10',
          fontSize: compact ? 24 : 30,
          height: 1,
          color: Colors.white,
          shadows: const <Shadow>[
            Shadow(color: _border, offset: Offset(2, 2)),
          ],
        ),
      ),
    );
  }
}

class _BlinkingArrow extends StatefulWidget {
  const _BlinkingArrow();

  @override
  State<_BlinkingArrow> createState() => _BlinkingArrowState();
}

class _BlinkingArrowState extends State<_BlinkingArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const Icon(
        Icons.play_arrow,
        color: Colors.white,
        size: 26,
      ),
    );
  }
}
