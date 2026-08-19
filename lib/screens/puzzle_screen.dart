import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_character.dart';
import '../models/game_progress.dart';
import '../models/town_location.dart';
import '../services/audio_manager.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/pixel_button.dart';
import 'park_sort_transition_screen.dart';

/// Phase 1 mini-game: a click-to-swap jigsaw puzzle.
///
/// A picture of a waste item / bin (the lesson prop) is sliced into a
/// [gridSize] x [gridSize] grid and scrambled. The player taps two pieces to
/// swap them; whenever a piece lands in its correct spot it locks in with a
/// snap sound. Completing the picture triggers a confetti celebration.
class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({
    super.key,
    required this.character,
    required this.location,
    required this.imageAsset,
    required this.itemName,
    this.gridSize = 2,
    this.backgroundAsset = 'assets/images/png/park_trash_bg.png',
    this.nextBuilder,
    this.instructionText,
    this.completeMessage,
    this.phaseLabel = 'Phase 1',
  });

  final GameCharacter character;
  final TownLocation location;
  final String imageAsset;
  final String itemName;
  final int gridSize;
  final String backgroundAsset;
  final WidgetBuilder? nextBuilder;
  final String? instructionText;
  final String? completeMessage;
  final String phaseLabel;

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  static const Color _panel = Color(0xF00E0E1A);
  static const Color _border = Color(0xFF2B2B3A);

  late int _count;
  late List<int> _slots; // _slots[cell] = piece index currently in that cell
  final Set<int> _locked = <int>{};
  int? _selected;
  bool _complete = false;

  @override
  void initState() {
    super.initState();
    _count = widget.gridSize * widget.gridSize;
    _slots = _scramble(_count);
  }

  /// A derangement (no piece starts in its correct cell) so there is always
  /// something to solve.
  List<int> _scramble(int n) {
    final math.Random rnd = math.Random();
    List<int> order = List<int>.generate(n, (int i) => i);
    do {
      order.shuffle(rnd);
    } while (_fixedPoints(order) > 0);
    return order;
  }

  int _fixedPoints(List<int> order) {
    int count = 0;
    for (int i = 0; i < order.length; i++) {
      if (order[i] == i) count++;
    }
    return count;
  }

  void _onTapCell(int cell) {
    if (_complete || _locked.contains(cell)) return;

    if (_selected == null) {
      setState(() => _selected = cell);
      return;
    }
    if (_selected == cell) {
      setState(() => _selected = null);
      return;
    }

    // Swap the two selected pieces.
    final int a = _selected!;
    setState(() {
      final int tmp = _slots[a];
      _slots[a] = _slots[cell];
      _slots[cell] = tmp;
      _selected = null;
    });
    _lockCorrectPieces();
  }

  void _lockCorrectPieces() {
    bool snapped = false;
    for (int cell = 0; cell < _count; cell++) {
      if (!_locked.contains(cell) && _slots[cell] == cell) {
        _locked.add(cell);
        snapped = true;
      }
    }
    if (snapped) {
      AudioManager.instance.playSnap();
      setState(() {});
    }
    if (_locked.length == _count && !_complete) {
      setState(() => _complete = true);
      AudioManager.instance.playApplause();
    }
  }

  void _onContinue() {
    final WidgetBuilder next = widget.nextBuilder ??
        (BuildContext context) => ParkSortTransitionScreen(
              character: widget.character,
              location: widget.location,
            );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            widget.backgroundAsset,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0xCC0E1A12), Color(0xE6070B08)],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxHeight < 420;
                return Padding(
                  padding: EdgeInsets.all(compact ? 8 : 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                        flex: compact ? 5 : 5,
                        child: _buildInfoColumn(compact: compact),
                      ),
                      SizedBox(width: compact ? 10 : 16),
                      Expanded(
                        flex: compact ? 5 : 6,
                        child: _buildBoardArea(compact: compact),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_complete) ...<Widget>[
            if (widget.location.id == GameProgress.beachLocationId)
              const Positioned.fill(child: _BeachCompleteAmbience()),
            if (widget.location.id == GameProgress.townCenterLocationId)
              const Positioned.fill(child: _TownCenterCompleteAmbience()),
            Positioned.fill(child: _buildCompletePanel()),
            const Positioned.fill(child: ConfettiOverlay()),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoColumn({required bool compact}) {
    if (compact) {
      return _buildCompactInfoColumn();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Align(
          alignment: Alignment.topLeft,
          child: _BackChip(onTap: () => Navigator.of(context).pop()),
        ),
        const SizedBox(height: 8),
        Text(
          widget.phaseLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Jersey10',
            fontSize: 30,
            height: 1,
            color: Color(0xFFFFCA28),
          ),
        ),
        const Text(
          'Fix the Picture!',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Jersey10',
            fontSize: 46,
            height: 1,
            color: Colors.white,
            shadows: <Shadow>[
              Shadow(color: _border, offset: Offset(2, 2)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Text(
              widget.instructionText ??
                  'Tap two pieces to swap them. Rebuild the ${widget.itemName}!',
              style: const TextStyle(
                fontFamily: 'Jersey10',
                fontSize: 24,
                height: 1.15,
                color: Color(0xFFDCE6DC),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            _ReferenceThumb(imageAsset: widget.imageAsset, size: 120),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Goal',
                    style: TextStyle(
                      fontFamily: 'Jersey10',
                      fontSize: 22,
                      height: 1,
                      color: Color(0xFF9FE6A0),
                    ),
                  ),
                  Text(
                    widget.itemName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Jersey10',
                      fontSize: 30,
                      height: 1,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Mobile: prioritize a large Goal preview so players can see the target.
  Widget _buildCompactInfoColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            _BackChip(
              onTap: () => Navigator.of(context).pop(),
              compact: true,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.phaseLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Jersey10',
                  fontSize: 15,
                  height: 1,
                  color: Color(0xFFFFCA28),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Fix the Picture!',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Jersey10',
            fontSize: 22,
            height: 1,
            color: Colors.white,
            shadows: <Shadow>[
              Shadow(color: _border, offset: Offset(2, 2)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.instructionText ??
              'Tap two pieces to swap them. Rebuild the ${widget.itemName}!',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Jersey10',
            fontSize: 13,
            height: 1.15,
            color: Color(0xFFDCE6DC),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final double side = math.min(c.maxWidth, c.maxHeight);
              return Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: side,
                  height: side,
                  child: _ReferenceThumb(
                    imageAsset: widget.imageAsset,
                    size: side,
                    label: 'Goal',
                    subtitle: widget.itemName,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBoardArea({required bool compact}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double side =
            math.min(constraints.maxWidth, constraints.maxHeight);
        final double gap = compact ? 3.0 : 6.0;

        return Center(
          child: Container(
            width: side,
            height: side,
            padding: EdgeInsets.all(gap),
            decoration: BoxDecoration(
              color: _panel,
              border: Border.all(color: _border, width: compact ? 3 : 5),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: Color(0xAA000000), offset: Offset(0, 6)),
              ],
            ),
            child: Column(
              children: <Widget>[
                for (int r = 0; r < widget.gridSize; r++)
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        for (int c = 0; c < widget.gridSize; c++)
                          _buildCell(
                            r * widget.gridSize + c,
                            gap,
                            compact: compact,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCell(int cell, double gap, {required bool compact}) {
    final bool locked = _locked.contains(cell);
    final bool selected = _selected == cell;
    final Color borderColor = locked
        ? const Color(0xFF43D058)
        : selected
            ? const Color(0xFFFFD54F)
            : _border;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(gap / 2),
        child: GestureDetector(
          onTap: () => _onTapCell(cell),
          child: AnimatedScale(
            scale: selected ? 1.06 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: borderColor, width: compact ? 2 : 4),
                boxShadow: selected
                    ? const <BoxShadow>[
                        BoxShadow(color: Color(0x88FFD54F), blurRadius: 10),
                      ]
                    : null,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _PuzzlePieceView(
                    imageAsset: widget.imageAsset,
                    pieceIndex: _slots[cell],
                    gridSize: widget.gridSize,
                  ),
                  if (locked)
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.all(compact ? 1 : 3),
                        child: _CheckBadge(compact: compact),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletePanel() {
    final bool compact = MediaQuery.sizeOf(context).height < 420;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 12 : 24),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: compact ? 12 : 24),
          padding: EdgeInsets.fromLTRB(
            compact ? 16 : 28,
            compact ? 14 : 22,
            compact ? 16 : 28,
            compact ? 16 : 24,
          ),
          decoration: BoxDecoration(
            color: _panel,
            border: Border.all(color: _border, width: compact ? 4 : 5),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0xAA000000), offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.emoji_events,
                color: const Color(0xFFFFCA28),
                size: compact ? 36 : 56,
              ),
              SizedBox(height: compact ? 4 : 6),
              Text(
                'Great Job!',
                style: TextStyle(
                  fontFamily: 'Jersey10',
                  fontSize: compact ? 36 : 56,
                  height: 1,
                  color: Colors.white,
                  shadows: const <Shadow>[
                    Shadow(color: _border, offset: Offset(3, 3)),
                  ],
                ),
              ),
              Text(
                widget.completeMessage ?? 'You fixed the ${widget.itemName}!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Jersey10',
                  fontSize: compact ? 18 : 26,
                  height: 1.1,
                  color: const Color(0xFFDCE6DC),
                ),
              ),
              SizedBox(height: compact ? 12 : 18),
              PixelButton(
                label: 'Continue',
                icon: Icons.arrow_forward,
                color: const Color(0xFF4CAF50),
                width: null,
                compact: compact,
                onPressed: _onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders a single [gridSize] x [gridSize] slice of [imageAsset].
class _PuzzlePieceView extends StatelessWidget {
  const _PuzzlePieceView({
    required this.imageAsset,
    required this.pieceIndex,
    required this.gridSize,
  });

  final String imageAsset;
  final int pieceIndex;
  final int gridSize;

  @override
  Widget build(BuildContext context) {
    final int row = pieceIndex ~/ gridSize;
    final int col = pieceIndex % gridSize;
    return ClipRect(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double w = constraints.maxWidth;
          final double h = constraints.maxHeight;
          return Stack(
            children: <Widget>[
              Positioned(
                left: -col * w,
                top: -row * h,
                width: w * gridSize,
                height: h * gridSize,
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.none,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReferenceThumb extends StatelessWidget {
  const _ReferenceThumb({
    required this.imageAsset,
    this.size = 96,
    this.label,
    this.subtitle,
  });

  final String imageAsset;
  final double size;
  final String? label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final bool large = size >= 100;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF9FE6A0),
          width: large ? 3 : (size < 70 ? 2 : 4),
        ),
        color: Colors.white,
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            imageAsset,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
          ),
          if (label != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0x00000000), Color(0xCC000000)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        label!,
                        style: TextStyle(
                          fontFamily: 'Jersey10',
                          fontSize: large ? 16 : 14,
                          height: 1,
                          color: const Color(0xFF9FE6A0),
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Jersey10',
                            fontSize: large ? 18 : 15,
                            height: 1,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 1 : 2),
      decoration: const BoxDecoration(
        color: Color(0xFF43A047),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check, color: Colors.white, size: compact ? 10 : 16),
    );
  }
}

class _BackChip extends StatelessWidget {
  const _BackChip({
    required this.onTap,
    this.compact = false,
  });

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: const Color(0xF00E0E1A),
          border: Border.all(
            color: const Color(0xFF2B2B3A),
            width: compact ? 2 : 3,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.arrow_back, color: Colors.white, size: compact ? 16 : 20),
            SizedBox(width: compact ? 4 : 6),
            Text(
              'Map',
              style: TextStyle(
                fontFamily: 'Jersey10',
                fontSize: compact ? 18 : 22,
                height: 1,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft waves + seagulls when the Beach Level 7 puzzle is solved.
class _BeachCompleteAmbience extends StatefulWidget {
  const _BeachCompleteAmbience();

  @override
  State<_BeachCompleteAmbience> createState() => _BeachCompleteAmbienceState();
}

class _BeachCompleteAmbienceState extends State<_BeachCompleteAmbience>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _loop,
        builder: (BuildContext context, _) {
          final double t = _loop.value;
          final Size size = MediaQuery.sizeOf(context);
          final double wave = math.sin(t * math.pi * 2) * 6;
          return Stack(
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                bottom: 18 + wave,
                child: Opacity(
                  opacity: 0.55,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(6, (int i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.waves,
                          color: const Color(0xFF29B6F6),
                          size: size.height < 420 ? 22 : 30,
                        ),
                      );
                    }),
                  ),
                ),
              ),
              ...List<Widget>.generate(4, (int i) {
                final double fly = (t + i * 0.22) % 1.0;
                return Positioned(
                  left: size.width * (-0.1 + fly * 1.2),
                  top: size.height * (0.08 + (i % 3) * 0.05) -
                      math.sin(fly * math.pi) * 12,
                  child: Opacity(
                    opacity: 0.85,
                    child: Icon(
                      Icons.flutter_dash,
                      color: const Color(0xFF90CAF9),
                      size: size.height < 420 ? 18 : 24,
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

/// Fireworks when the Town Center Level 9 puzzle is solved.
class _TownCenterCompleteAmbience extends StatefulWidget {
  const _TownCenterCompleteAmbience();

  @override
  State<_TownCenterCompleteAmbience> createState() =>
      _TownCenterCompleteAmbienceState();
}

class _TownCenterCompleteAmbienceState extends State<_TownCenterCompleteAmbience>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _loop,
        builder: (BuildContext context, _) {
          final double t = _loop.value;
          final Size size = MediaQuery.sizeOf(context);
          final bool compact = size.height < 420;
          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: Opacity(
                  opacity: 0.25 + 0.15 * math.sin(t * math.pi * 2),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        radius: 1.2,
                        colors: <Color>[
                          Color(0x66FFECB3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ...List<Widget>.generate(8, (int i) {
                final double burst = (t + i * 0.12) % 1.0;
                final double ang = i * (math.pi * 2 / 8);
                final double radius = burst * (compact ? 70.0 : 110.0);
                final double cx = size.width * (0.2 + (i % 4) * 0.2);
                final double cy = size.height * (0.18 + (i ~/ 4) * 0.12);
                return Positioned(
                  left: cx + math.cos(ang) * radius - 10,
                  top: cy + math.sin(ang) * radius - 10,
                  child: Opacity(
                    opacity: (1 - burst).clamp(0.0, 1.0),
                    child: Icon(
                      i.isEven ? Icons.auto_awesome : Icons.star,
                      color: i.isEven
                          ? const Color(0xFFFFECB3)
                          : const Color(0xFFFFF59D),
                      size: compact ? 16 : 22,
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
