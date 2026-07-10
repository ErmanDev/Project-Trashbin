import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_character.dart';
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
  });

  final GameCharacter character;
  final TownLocation location;
  final String imageAsset;
  final String itemName;
  final int gridSize;

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
    }
  }

  void _onContinue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ParkSortTransitionScreen(
          character: widget.character,
          location: widget.location,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Soft park backdrop, dimmed so the puzzle pops.
          Image.asset(
            'assets/images/png/park_trash_bg.png',
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
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(flex: 5, child: _buildInfoPanel()),
                  const SizedBox(width: 16),
                  Expanded(flex: 6, child: _buildBoardArea()),
                ],
              ),
            ),
          ),

          if (_complete) ...<Widget>[
            Positioned.fill(child: _buildCompletePanel()),
            const Positioned.fill(child: ConfettiOverlay()),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Align(
          alignment: Alignment.topLeft,
          child: _BackChip(onTap: () => Navigator.of(context).pop()),
        ),
        const Spacer(),
        const Text(
          'Phase 1',
          style: TextStyle(
            fontFamily: 'Jersey10',
            fontSize: 30,
            height: 1,
            color: Color(0xFFFFCA28),
          ),
        ),
        const Text(
          'Fix the Picture!',
          style: TextStyle(
            fontFamily: 'Jersey10',
            fontSize: 46,
            height: 1,
            color: Colors.white,
            shadows: <Shadow>[Shadow(color: _border, offset: Offset(2, 2))],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap two pieces to swap them. Rebuild the ${widget.itemName}!',
          style: const TextStyle(
            fontFamily: 'Jersey10',
            fontSize: 24,
            height: 1.1,
            color: Color(0xFFDCE6DC),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            _ReferenceThumb(imageAsset: widget.imageAsset),
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
        const Spacer(flex: 2),
      ],
    );
  }

  Widget _buildBoardArea() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double side =
            math.min(constraints.maxWidth, constraints.maxHeight);
        const double gap = 6;
        final double cell = (side - gap * (widget.gridSize + 1)) /
            widget.gridSize;

        return Center(
          child: Container(
            width: side,
            height: side,
            padding: const EdgeInsets.all(gap),
            decoration: BoxDecoration(
              color: _panel,
              border: Border.all(color: _border, width: 5),
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
                          _buildCell(r * widget.gridSize + c, cell, gap),
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

  Widget _buildCell(int cell, double cellSize, double gap) {
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
                border: Border.all(color: borderColor, width: 4),
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
                    const Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.all(3),
                        child: _CheckBadge(),
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
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 24),
        decoration: BoxDecoration(
          color: _panel,
          border: Border.all(color: _border, width: 5),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0xAA000000), offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.emoji_events, color: Color(0xFFFFCA28), size: 56),
            const SizedBox(height: 6),
            const Text(
              'Great Job!',
              style: TextStyle(
                fontFamily: 'Jersey10',
                fontSize: 56,
                height: 1,
                color: Colors.white,
                shadows: <Shadow>[Shadow(color: _border, offset: Offset(3, 3))],
              ),
            ),
            Text(
              'You fixed the ${widget.itemName}!',
              style: const TextStyle(
                fontFamily: 'Jersey10',
                fontSize: 26,
                height: 1.1,
                color: Color(0xFFDCE6DC),
              ),
            ),
            const SizedBox(height: 18),
            PixelButton(
              label: 'Continue',
              icon: Icons.arrow_forward,
              color: const Color(0xFF4CAF50),
              width: null,
              onPressed: _onContinue,
            ),
          ],
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
  const _ReferenceThumb({required this.imageAsset});

  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF2B2B3A), width: 4),
        color: Colors.white,
      ),
      clipBehavior: Clip.hardEdge,
      child: Image.asset(
        imageAsset,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.none,
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: Color(0xFF43A047),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, color: Colors.white, size: 16),
    );
  }
}

class _BackChip extends StatelessWidget {
  const _BackChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xF00E0E1A),
          border: Border.all(color: const Color(0xFF2B2B3A), width: 3),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.arrow_back, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text(
              'Map',
              style: TextStyle(
                fontFamily: 'Jersey10',
                fontSize: 22,
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
