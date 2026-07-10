import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_character.dart';
import '../models/level_reward.dart';
import '../models/sorting_item.dart';
import '../models/town_location.dart';
import '../services/audio_manager.dart';
import '../services/save_manager.dart';
import '../widgets/pixel_button.dart';
import '../widgets/sparkle_burst.dart';
import 'reward_screen.dart';

/// Phase 2 mini-game: drag waste items into the correct bins.
///
/// Correct sorts earn coins and score with a sparkle burst. Wrong drops (e.g.
/// a battery in recycling) shake the screen and show a lesson popup.
class SortingScreen extends StatefulWidget {
  const SortingScreen({
    super.key,
    required this.character,
    required this.location,
    this.items = ParkSortingLevel.items,
    this.bins = ParkSortingLevel.bins,
    this.coinsPerCorrect = ParkSortingLevel.coinsPerCorrect,
  });

  final GameCharacter character;
  final TownLocation location;
  final List<WasteItem> items;
  final List<WasteBin> bins;
  final int coinsPerCorrect;

  @override
  State<SortingScreen> createState() => _SortingScreenState();
}

class _SortingScreenState extends State<SortingScreen>
    with TickerProviderStateMixin {
  static const Color _panel = Color(0xF00E0E1A);
  static const Color _border = Color(0xFF2B2B3A);

  int _itemIndex = 0;
  int _score = 0;
  int _sessionCoins = 0;
  int _savedCoins = 0;
  int _mistakes = 0;
  final List<EnvironmentalImpact> _environmentalImpact = <EnvironmentalImpact>[];
  bool _showOops = false;
  String _oopsTitle = 'Oops!';
  String _oopsMessage = '';
  bool _dragging = false;

  Offset? _sparkleAt;
  int _sparkleKey = 0;
  String? _floatingCoinText;
  int _floatingCoinKey = 0;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    _loadCoins();
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _loadCoins() async {
    final int coins = await SaveManager.instance.loadCoins();
    if (!mounted) return;
    setState(() => _savedCoins = coins);
  }

  WasteItem? get _currentItem =>
      _itemIndex < widget.items.length ? widget.items[_itemIndex] : null;

  void _onShakeTick() {
    _shake.forward(from: 0);
  }

  Future<void> _onCorrectDrop(WasteItem item, WasteBin bin) async {
    AudioManager.instance.playSnap();
    final int earned = widget.coinsPerCorrect;
    final int newTotal = await SaveManager.instance.addCoins(earned);
    if (!mounted) return;

    setState(() {
      _score++;
      _sessionCoins += earned;
      _savedCoins = newTotal;
      _environmentalImpact.add(
        EnvironmentalImpact(label: item.impactLabel, kg: item.impactKg),
      );
      _sparkleKey++;
      _floatingCoinKey++;
      _floatingCoinText = '+$earned';
      _itemIndex++;
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    if (_itemIndex >= widget.items.length) {
      _goToRewardScreen();
    } else {
      setState(() {
        _floatingCoinText = null;
        _sparkleAt = null;
      });
    }
  }

  void _goToRewardScreen() {
    final int correctAnswers = _score;
    final LevelRewardResult result = LevelRewardResult(
      stars: LevelRewardResult.starsForMistakes(_mistakes),
      coinsEarned: _sessionCoins,
      score: LevelRewardResult.scoreFor(
        correctAnswers: correctAnswers,
        mistakes: _mistakes,
      ),
      correctAnswers: correctAnswers,
      mistakes: _mistakes,
      environmentalImpact: List<EnvironmentalImpact>.from(_environmentalImpact),
      levelTitle: 'Park Level 1',
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => RewardScreen(result: result),
      ),
    );
  }

  void _onWrongDrop(WasteItem item, WasteBin bin) {
    _onShakeTick();
    setState(() => _mistakes++);
    final String? lesson = item.messageForWrongBin(bin.type);
    if (lesson == null) return;

    setState(() {
      _oopsTitle = 'Oops!';
      _oopsMessage = lesson;
      _showOops = true;
    });
  }

  void _closeOops() => setState(() => _showOops = false);

  double _shakeOffset(double t) {
    if (t <= 0 || t >= 1) return 0;
    return math.sin(t * math.pi * 8) * 10 * (1 - t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _shake,
        builder: (BuildContext context, Widget? child) {
          return Transform.translate(
            offset: Offset(_shakeOffset(_shake.value), 0),
            child: child,
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
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
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool compact = constraints.maxHeight < 420;
                  final double dockHeight = compact
                      ? (constraints.maxHeight * 0.24).clamp(88.0, 120.0)
                      : (constraints.maxHeight * 0.28).clamp(96.0, 148.0);
                  return Padding(
                    padding: EdgeInsets.all(compact ? 8 : 14),
                    child: Column(
                      children: <Widget>[
                        _buildHud(compact: compact),
                        SizedBox(height: compact ? 6 : 10),
                        Expanded(child: _buildBinsCenter(compact: compact)),
                        SizedBox(height: compact ? 6 : 10),
                        if (compact)
                          _buildWasteDock(compact: true)
                        else
                          SizedBox(
                            height: dockHeight,
                            child: _buildWasteDock(compact: false),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            if (_sparkleAt != null)
              Positioned(
                left: _sparkleAt!.dx - 40,
                top: _sparkleAt!.dy - 40,
                width: 80,
                height: 80,
                child: SparkleBurst(key: ValueKey<int>(_sparkleKey)),
              ),

            if (_floatingCoinText != null)
              Positioned(
                top: 72,
                right: 24,
                child: _FloatingCoin(
                  key: ValueKey<int>(_floatingCoinKey),
                  text: _floatingCoinText!,
                ),
              ),

            if (_showOops) _buildOopsOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHud({required bool compact}) {
    final double labelSize = compact ? 16 : 18;
    final double valueSize = compact ? 22 : 26;
    final double phaseSize = compact ? 18 : 22;

    return Row(
      children: <Widget>[
        _HudChip(
          icon: Icons.grade,
          label: 'Score',
          value: '$_score',
          accent: const Color(0xFFFFCA28),
          labelSize: labelSize,
          valueSize: valueSize,
          compact: compact,
        ),
        SizedBox(width: compact ? 6 : 10),
        _HudChip(
          icon: Icons.monetization_on,
          label: 'Coins',
          value: '$_savedCoins',
          accent: const Color(0xFFFFC107),
          labelSize: labelSize,
          valueSize: valueSize,
          compact: compact,
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: compact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: _panel,
            border: Border.all(color: _border, width: 3),
          ),
          child: Text(
            'Phase 2  •  ${_itemIndex + 1}/${widget.items.length}',
            style: TextStyle(
              fontFamily: 'Jersey10',
              fontSize: phaseSize,
              height: 1,
              color: const Color(0xFFDCE6DC),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBinsCenter({required bool compact}) {
    final double titleSize = compact ? 22 : 28;

    return Column(
      children: <Widget>[
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Drag waste to the right bin!',
            style: TextStyle(
              fontFamily: 'Jersey10',
              fontSize: titleSize,
              height: 1,
              color: const Color(0xFFDCE6DC),
            ),
          ),
        ),
        SizedBox(height: compact ? 6 : 10),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < widget.bins.length; i++) ...<Widget>[
                if (i > 0) SizedBox(width: compact ? 8 : 14),
                Expanded(
                  child: _BinDropTarget(
                    bin: widget.bins[i],
                    compact: compact,
                    enabled: !_showOops && _currentItem != null,
                    onCorrect: (WasteItem item, Offset globalPos) {
                      setState(() {
                        _sparkleAt = globalPos;
                        _sparkleKey++;
                      });
                      _onCorrectDrop(item, widget.bins[i]);
                    },
                    onWrong: _onWrongDrop,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWasteDock({required bool compact}) {
    final WasteItem? item = _currentItem;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 16,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _border, width: compact ? 3 : 4),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0xAA000000), offset: Offset(0, -4)),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: item == null
          ? SizedBox(height: compact ? 52 : double.infinity)
          : compact
              ? Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'Sort this item',
                        style: TextStyle(
                          fontFamily: 'Jersey10',
                          fontSize: 18,
                          height: 1,
                          color: Color(0xFF9FE6A0),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildDraggableItem(item, compact: true),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'Sort this item',
                      style: TextStyle(
                        fontFamily: 'Jersey10',
                        fontSize: 24,
                        height: 1,
                        color: Color(0xFF9FE6A0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Center(
                        child: _buildDraggableItem(item, compact: false),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDraggableItem(WasteItem item, {required bool compact}) {
    return Draggable<WasteItem>(
      data: item,
      maxSimultaneousDrags: _showOops ? 0 : 1,
      onDragStarted: () => setState(() => _dragging = true),
      onDragEnd: (_) => setState(() => _dragging = false),
      onDraggableCanceled: (_, _) => setState(() => _dragging = false),
      feedback: Material(
        color: Colors.transparent,
        child: _WasteCard(item: item, elevated: true, compact: compact),
      ),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: _WasteCard(item: item, compact: compact),
      ),
      child: AnimatedScale(
        scale: _dragging ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: _WasteCard(item: item, compact: compact),
      ),
    );
  }

  Widget _buildOopsOverlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xAA000000),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
            decoration: BoxDecoration(
              color: _panel,
              border: Border.all(color: const Color(0xFFE53935), width: 5),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: Color(0xAA000000), offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFE53935),
                  size: 52,
                ),
                const SizedBox(height: 8),
                Text(
                  _oopsTitle,
                  style: const TextStyle(
                    fontFamily: 'Jersey10',
                    fontSize: 52,
                    height: 1,
                    color: Colors.white,
                    shadows: <Shadow>[
                      Shadow(color: _border, offset: Offset(2, 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _oopsMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Jersey10',
                    fontSize: 28,
                    height: 1.15,
                    color: Color(0xFFDCE6DC),
                  ),
                ),
                const SizedBox(height: 18),
                PixelButton(
                  label: 'Try Again',
                  icon: Icons.refresh,
                  color: const Color(0xFF4CAF50),
                  width: null,
                  onPressed: _closeOops,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _HudChip extends StatelessWidget {
  const _HudChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.labelSize,
    required this.valueSize,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final double labelSize;
  final double valueSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 5 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xF00E0E1A),
        border: Border.all(color: const Color(0xFF2B2B3A), width: 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: accent, size: compact ? 18 : 22),
          SizedBox(width: compact ? 6 : 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Jersey10',
                  fontSize: labelSize,
                  height: 1,
                  color: const Color(0xFFB0BEC5),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Jersey10',
                  fontSize: valueSize,
                  height: 1,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WasteCard extends StatelessWidget {
  const _WasteCard({
    required this.item,
    this.elevated = false,
    this.compact = false,
  });

  final WasteItem item;
  final bool elevated;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double imageSize = compact ? 40 : 64;
    final double fontSize = compact ? 18 : 20;
    final double width = compact ? 0 : 110;

    final BoxDecoration decoration = BoxDecoration(
      color: const Color(0xF00E0E1A),
      border: Border.all(
        color: elevated ? item.color : const Color(0xFF2B2B3A),
        width: compact ? 3 : 4,
      ),
      boxShadow: elevated
          ? <BoxShadow>[
              BoxShadow(
                color: item.color.withValues(alpha: 0.5),
                blurRadius: compact ? 8 : 14,
              ),
            ]
          : <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF2B2B3A),
                offset: Offset(0, compact ? 3 : 5),
              ),
            ],
    );

    final Widget image = SizedBox(
      width: imageSize,
      height: imageSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF2B2B3A), width: 3),
        ),
        child: Image.asset(
          item.imageAsset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
        ),
      ),
    );

    final Widget label = Text(
      item.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Jersey10',
        fontSize: fontSize,
        height: 1,
        color: Colors.white,
      ),
    );

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: decoration,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            image,
            const SizedBox(width: 8),
            Flexible(child: label),
          ],
        ),
      );
    }

    return Container(
      width: elevated ? width + 8 : width,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: decoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          image,
          const SizedBox(height: 6),
          FittedBox(fit: BoxFit.scaleDown, child: label),
        ],
      ),
    );
  }
}

class _BinDropTarget extends StatefulWidget {
  const _BinDropTarget({
    required this.bin,
    required this.compact,
    required this.onCorrect,
    required this.onWrong,
    required this.enabled,
  });

  final WasteBin bin;
  final bool compact;
  final void Function(WasteItem item, Offset globalPos) onCorrect;
  final void Function(WasteItem item, WasteBin bin) onWrong;
  final bool enabled;

  @override
  State<_BinDropTarget> createState() => _BinDropTargetState();
}

class _BinDropTargetState extends State<_BinDropTarget>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  bool _rejecting = false;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _playRejectShake() {
    setState(() => _rejecting = true);
    _shake.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _rejecting = false);
    });
  }

  double _shakeOffset(double t) {
    if (t <= 0 || t >= 1) return 0;
    return math.sin(t * math.pi * 8) * 12 * (1 - t);
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<WasteItem>(
      onWillAcceptWithDetails: (_) => widget.enabled,
      onMove: (_) {
        if (!_hovering) setState(() => _hovering = true);
      },
      onLeave: (_) => setState(() => _hovering = false),
      onAcceptWithDetails: (DragTargetDetails<WasteItem> details) {
        setState(() => _hovering = false);
        final WasteItem item = details.data;
        if (item.correctBin != widget.bin.type) {
          _playRejectShake();
          widget.onWrong(item, widget.bin);
          return;
        }
        final RenderBox box = context.findRenderObject()! as RenderBox;
        final Offset center = box.localToGlobal(
          box.size.center(Offset.zero),
        );
        widget.onCorrect(item, center);
      },
      builder: (
        BuildContext context,
        List<WasteItem?> candidate,
        List<dynamic> rejected,
      ) {
        final bool active = _hovering || candidate.isNotEmpty;
        return AnimatedBuilder(
          animation: _shake,
          builder: (BuildContext context, Widget? child) {
            return Transform.translate(
              offset: Offset(_shakeOffset(_shake.value), 0),
              child: child,
            );
          },
          child: SizedBox.expand(
            child: AnimatedScale(
              scale: active ? 1.04 : 1.0,
              duration: const Duration(milliseconds: 120),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: EdgeInsets.symmetric(
                  vertical: widget.compact ? 6 : 8,
                  horizontal: widget.compact ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xF00E0E1A),
                  border: Border.all(
                    color: _rejecting
                        ? const Color(0xFFE53935)
                        : active
                            ? widget.bin.color
                            : const Color(0xFF2B2B3A),
                    width: _rejecting ? 5 : active ? 5 : 4,
                  ),
                  boxShadow: _rejecting
                      ? <BoxShadow>[
                          BoxShadow(
                            color: const Color(0xFFE53935).withValues(alpha: 0.5),
                            blurRadius: 14,
                          ),
                        ]
                      : active
                          ? <BoxShadow>[
                              BoxShadow(
                                color: widget.bin.color.withValues(alpha: 0.45),
                                blurRadius: 12,
                              ),
                            ]
                          : const <BoxShadow>[
                              BoxShadow(
                                color: Color(0xFF2B2B3A),
                                offset: Offset(0, 5),
                              ),
                            ],
                ),
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: Image.asset(
                        widget.bin.imageAsset,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                    SizedBox(height: widget.compact ? 2 : 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.bin.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Jersey10',
                          fontSize: widget.compact ? 18 : 22,
                          height: 1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FloatingCoin extends StatefulWidget {
  const _FloatingCoin({super.key, required this.text});

  final String text;

  @override
  State<_FloatingCoin> createState() => _FloatingCoinState();
}

class _FloatingCoinState extends State<_FloatingCoin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        final double t = _controller.value;
        return Opacity(
          opacity: (1 - t).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -36 * t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xF00E0E1A),
                border: Border.all(color: const Color(0xFFFFC107), width: 3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.monetization_on,
                    color: Color(0xFFFFC107),
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.text,
                    style: const TextStyle(
                      fontFamily: 'Jersey10',
                      fontSize: 28,
                      height: 1,
                      color: Color(0xFFFFC107),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
