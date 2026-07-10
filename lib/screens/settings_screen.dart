import 'package:flutter/material.dart';

import '../services/audio_manager.dart';
import '../widgets/pixel_button.dart';
import '../widgets/pixel_checkbox.dart';

/// Settings screen. Currently lets the player mute/unmute the background
/// music with a pixel-art checkbox (unmuted by default).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // The checkbox represents "sound on", so it is the inverse of muted.
  bool _soundOn = !AudioManager.instance.isMuted;

  Future<void> _onToggle(bool soundOn) async {
    await AudioManager.instance.setMuted(!soundOn);
    setState(() => _soundOn = soundOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            'assets/images/png/main_menu_bg.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
          ),
          // Darken the background so the settings panel stands out.
          const ColoredBox(color: Color(0x66000000)),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxHeight < 420;
                final double panelWidth = compact
                    ? (constraints.maxWidth - 32).clamp(260.0, 360.0)
                    : 460.0;
                final double buttonWidth = compact
                    ? (constraints.maxWidth * 0.45).clamp(160.0, 220.0)
                    : 260.0;
                final double titleGap = compact ? 16.0 : 24.0;
                final double panelGap = compact ? 18.0 : 28.0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        _ScreenTitle(compact: compact),
                        SizedBox(height: titleGap),
                        _SettingsPanel(
                          soundOn: _soundOn,
                          onToggle: _onToggle,
                          compact: compact,
                          width: panelWidth,
                        ),
                        SizedBox(height: panelGap),
                        PixelButton(
                          label: 'Back',
                          icon: Icons.arrow_back,
                          color: const Color(0xFF42A5F5),
                          width: buttonWidth,
                          compact: compact,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenTitle extends StatelessWidget {
  const _ScreenTitle({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double fontSize = compact ? 48 : 72;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        'Settings',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Jersey10',
          fontSize: fontSize,
          height: 1,
          letterSpacing: 2,
          color: const Color(0xFFFFB300),
          shadows: <Shadow>[
            const Shadow(color: Colors.white, offset: Offset(-3, -3)),
            const Shadow(color: Colors.white, offset: Offset(3, -3)),
            const Shadow(color: Colors.white, offset: Offset(-3, 3)),
            const Shadow(color: Colors.white, offset: Offset(3, 3)),
            Shadow(
              color: Colors.black.withValues(alpha: 0.35),
              offset: const Offset(0, 6),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.soundOn,
    required this.onToggle,
    required this.compact,
    required this.width,
  });

  final bool soundOn;
  final ValueChanged<bool> onToggle;
  final bool compact;
  final double width;

  @override
  Widget build(BuildContext context) {
    final double iconSize = compact ? 30 : 40;
    final double borderW = compact ? 3 : 4;
    final double shadowY = compact ? 4 : 8;

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 24,
        vertical: compact ? 14 : 22,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D6),
        border: Border.all(color: const Color(0xFF2B2B3A), width: borderW),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF2B2B3A),
            offset: Offset(0, shadowY),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Icon(
            soundOn ? Icons.volume_up : Icons.volume_off,
            size: iconSize,
            color: const Color(0xFF2B2B3A),
          ),
          SizedBox(width: compact ? 10 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _PixelLabel('Music', compact ? 26 : 34),
                _PixelLabel(
                  soundOn ? 'Unmuted' : 'Muted',
                  compact ? 20 : 24,
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 10 : 16),
          PixelCheckbox(
            value: soundOn,
            onChanged: onToggle,
            size: compact ? 44 : 56,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _PixelLabel extends StatelessWidget {
  const _PixelLabel(this.text, this.size);

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Jersey10',
        fontSize: size,
        height: 1.1,
        color: const Color(0xFF2B2B3A),
      ),
    );
  }
}
