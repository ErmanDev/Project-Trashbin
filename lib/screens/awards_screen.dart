import 'package:flutter/material.dart';

import '../models/cosmetic_item.dart';
import '../models/game_progress.dart';
import '../services/save_manager.dart';
import '../widgets/pixel_button.dart';

/// Badges, title, and district stars — simple layout that fits mobile.
class AwardsScreen extends StatefulWidget {
  const AwardsScreen({super.key});

  @override
  State<AwardsScreen> createState() => _AwardsScreenState();
}

class _AwardsScreenState extends State<AwardsScreen> {
  static const Color _panel = Color(0xE00E0E1A);
  static const Color _accent = Color(0xFFFFCA28);

  String _title = SaveManager.defaultTitle;
  Set<String> _owned = <String>{};
  bool _parkStar = false;
  bool _schoolStar = false;
  bool _neighborhoodStar = false;
  bool _beachStar = false;
  bool _finale = false;
  bool _loaded = false;
  CosmeticItem? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await SaveManager.instance.syncUnlockedBadgesFromProgress();
    final String title = await SaveManager.instance.loadTitle();
    final Set<String> owned =
        await SaveManager.instance.loadUnlockedCosmetics();
    final bool park = await SaveManager.instance.hasParkCompletionStar();
    final bool school = await SaveManager.instance.hasSchoolCompletionStar();
    final bool neighborhood =
        await SaveManager.instance.hasNeighborhoodCompletionStar();
    final bool beach = await SaveManager.instance.hasBeachCompletionStar();
    final bool finale = await SaveManager.instance.isLevelCompleted(
      GameProgress.townCenterLocationId,
      GameProgress.townCenterLevel10,
    );
    if (!mounted) return;
    setState(() {
      _title = title;
      _owned = owned;
      _parkStar = park;
      _schoolStar = school;
      _neighborhoodStar = neighborhood;
      _beachStar = beach;
      _finale = finale;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<CosmeticItem> badges = CosmeticItem.badges();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            GameProgress.awardsShelfBg,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
          ),
          const ColoredBox(color: Color(0x66000000)),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final bool compact = c.maxHeight < 420;
                final double pad = compact ? 6.0 : 10.0;
                final CosmeticItem? selected = _selected;
                final bool ownedSelected =
                    selected != null && _owned.contains(selected.id);

                return Padding(
                  padding: EdgeInsets.all(pad),
                  child: Column(
                    children: <Widget>[
                      // Header: Back + title + current title
                      Row(
                        children: <Widget>[
                          PixelButton(
                            label: 'Back',
                            icon: Icons.arrow_back,
                            color: const Color(0xFF42A5F5),
                            width: null,
                            compact: true,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          SizedBox(width: compact ? 8 : 12),
                          Text(
                            'Awards',
                            style: TextStyle(
                              fontFamily: 'Jersey10',
                              fontSize: compact ? 24 : 30,
                              height: 1,
                              color: Colors.white,
                              shadows: const <Shadow>[
                                Shadow(color: _accent, offset: Offset(2, 2)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              _title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: 'Jersey10',
                                fontSize: compact ? 16 : 20,
                                height: 1,
                                color: _accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 4 : 6),
                      // Stars — icons only
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          _Star(done: _parkStar, color: const Color(0xFF66BB6A)),
                          _Star(
                            done: _schoolStar,
                            color: const Color(0xFF42A5F5),
                          ),
                          _Star(
                            done: _neighborhoodStar,
                            color: const Color(0xFFEC407A),
                          ),
                          _Star(
                            done: _beachStar,
                            color: const Color(0xFF29B6F6),
                          ),
                          _Star(done: _finale, color: const Color(0xFFFFD54F)),
                        ],
                      ),
                      SizedBox(height: compact ? 4 : 6),
                      // Badge grid — 4 across, 2 rows (no scroll)
                      Expanded(
                        child: !_loaded
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                children: <Widget>[
                                  Expanded(
                                    child: Row(
                                      children: <Widget>[
                                        for (int i = 0; i < 4; i++)
                                          Expanded(
                                            child: Padding(
                                              padding: EdgeInsets.all(
                                                compact ? 2 : 4,
                                              ),
                                              child: _BadgeTile(
                                                item: badges[i],
                                                owned: _owned
                                                    .contains(badges[i].id),
                                                selected:
                                                    selected?.id == badges[i].id,
                                                onTap: () => setState(
                                                  () => _selected = badges[i],
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: <Widget>[
                                        for (int i = 4; i < 8; i++)
                                          Expanded(
                                            child: Padding(
                                              padding: EdgeInsets.all(
                                                compact ? 2 : 4,
                                              ),
                                              child: _BadgeTile(
                                                item: badges[i],
                                                owned: _owned
                                                    .contains(badges[i].id),
                                                selected:
                                                    selected?.id == badges[i].id,
                                                onTap: () => setState(
                                                  () => _selected = badges[i],
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      // One-line detail
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 8 : 12,
                          vertical: compact ? 5 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: _panel,
                          border: Border.all(
                            color: selected?.color ?? _accent,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          selected == null
                              ? 'Tap a badge'
                              : ownedSelected
                                  ? '${selected.name} — ${selected.description}'
                                  : '${selected.name} — ${selected.unlockHint ?? 'Locked'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Jersey10',
                            fontSize: compact ? 13 : 16,
                            height: 1.1,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
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

class _Star extends StatelessWidget {
  const _Star({required this.done, required this.color});

  final bool done;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        done ? Icons.star : Icons.star_border,
        color: done ? color : const Color(0xFF78909C),
        size: 22,
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.item,
    required this.owned,
    required this.selected,
    required this.onTap,
  });

  final CosmeticItem item;
  final bool owned;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xCC1A1408)
                : const Color(0x880E0E1A),
            border: Border.all(
              color: selected
                  ? _AwardsScreenState._accent
                  : owned
                      ? item.color
                      : const Color(0xFF5D4037),
              width: selected ? 3 : 2,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (item.imageAsset != null)
                Opacity(
                  opacity: owned ? 1 : 0.35,
                  child: Image.asset(
                    item.imageAsset!,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                    color: owned ? null : Colors.grey,
                    colorBlendMode: owned ? null : BlendMode.saturation,
                  ),
                )
              else
                Icon(
                  owned ? item.icon : Icons.lock,
                  color: owned ? item.color : const Color(0xFF78909C),
                  size: 28,
                ),
              if (!owned)
                const Align(
                  child: Icon(Icons.lock, color: Color(0xE0FFFFFF), size: 22),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
