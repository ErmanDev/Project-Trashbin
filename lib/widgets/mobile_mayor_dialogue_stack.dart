import 'package:flutter/material.dart';

import 'dialogue_box.dart';

/// Ren'Py-style mobile mayor stack: bust behind the text panel, speaker tag on top.
class MobileMayorDialogueStack extends StatelessWidget {
  const MobileMayorDialogueStack({
    super.key,
    required this.width,
    required this.text,
    required this.mayorIn,
    this.mayorAccent = const Color(0xFF3949AB),
    this.showContinueHint = false,
    this.aboveDialogue,
  });

  final double width;
  final String text;
  final Animation<double> mayorIn;
  final Color mayorAccent;
  final bool showContinueHint;
  final Widget? aboveDialogue;

  static const double textPanelMinH = 96;
  static const double tagH = 32;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomLeft,
      children: <Widget>[
        AnimatedBuilder(
          animation: mayorIn,
          builder: (BuildContext context, Widget? child) {
            final double t = Curves.easeOut.transform(mayorIn.value);
            return Positioned(
              left: 0,
              bottom: textPanelMinH - 8,
              width: width * 0.40,
              child: Opacity(
                opacity: t,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.50,
                    child: Transform.flip(flipX: true, child: child),
                  ),
                ),
              ),
            );
          },
          child: Image.asset(
            'assets/images/png/char_mayor_cutout.png',
            width: width * 0.40,
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.none,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (aboveDialogue != null) ...<Widget>[
              aboveDialogue!,
              const SizedBox(height: 14),
            ],
            Padding(
              padding: const EdgeInsets.only(top: tagH - 4),
              child: DialogueBox(
                text: text,
                accent: mayorAccent,
                showContinueHint: showContinueHint,
                showSpeakerName: false,
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          bottom: textPanelMinH,
          child: SpeakerNameTag(
            name: 'Mayor',
            accent: mayorAccent,
            compact: true,
          ),
        ),
      ],
    );
  }
}
