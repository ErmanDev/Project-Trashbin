import 'package:flutter/material.dart';

import '../models/cosmetic_item.dart';
import '../models/game_progress.dart';
import '../services/save_manager.dart';
import '../widgets/pixel_button.dart';

/// Spend coins on optional hats, outfits, and pets.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const Color _border = Color(0xFF2B2B3A);
  static const Color _panel = Color(0xF00E0E1A);
  static const Color accent = Color(0xFFFFB300);

  int _coins = 0;
  Set<String> _owned = <String>{};
  String? _equippedHat;
  String? _equippedOutfit;
  String? _equippedPet;
  bool _loaded = false;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final int coins = await SaveManager.instance.loadCoins();
    final Set<String> owned =
        await SaveManager.instance.loadUnlockedCosmetics();
    final String? hat = await SaveManager.instance.loadEquippedHat();
    final String? outfit = await SaveManager.instance.loadEquippedOutfit();
    final String? pet = await SaveManager.instance.loadEquippedPet();
    if (!mounted) return;
    setState(() {
      _coins = coins;
      _owned = owned;
      _equippedHat = hat;
      _equippedOutfit = outfit;
      _equippedPet = pet;
      _loaded = true;
    });
  }

  bool _isEquipped(CosmeticItem item) {
    switch (item.kind) {
      case CosmeticKind.hat:
        return _equippedHat == item.id;
      case CosmeticKind.outfit:
        return _equippedOutfit == item.id;
      case CosmeticKind.pet:
        return _equippedPet == item.id;
      case CosmeticKind.badge:
        return false;
    }
  }

  Future<void> _equipItem(CosmeticItem item) async {
    switch (item.kind) {
      case CosmeticKind.hat:
        await SaveManager.instance.equipHat(item.id);
        break;
      case CosmeticKind.outfit:
        await SaveManager.instance.equipOutfit(item.id);
        break;
      case CosmeticKind.pet:
        await SaveManager.instance.equipPet(item.id);
        break;
      case CosmeticKind.badge:
        return;
    }
  }

  Future<void> _buy(CosmeticItem item) async {
    if (_busyId != null || item.shopPrice == null) return;
    if (_owned.contains(item.id)) return;
    setState(() => _busyId = item.id);
    final bool ok = await SaveManager.instance.purchaseCosmetic(
      item.id,
      item.shopPrice!,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Not enough coins!'),
            duration: Duration(milliseconds: 1400),
          ),
        );
      setState(() => _busyId = null);
      return;
    }
    await _equipItem(item);
    await _load();
    if (!mounted) return;
    setState(() => _busyId = null);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Bought & equipped ${item.name}!'),
          duration: const Duration(milliseconds: 1400),
        ),
      );
  }

  Future<void> _equip(CosmeticItem item) async {
    if (_busyId != null || !_owned.contains(item.id)) return;
    setState(() => _busyId = item.id);
    await _equipItem(item);
    await _load();
    if (!mounted) return;
    setState(() => _busyId = null);
  }

  @override
  Widget build(BuildContext context) {
    final List<CosmeticItem> items = CosmeticItem.shopItems();
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            GameProgress.parkCleanBg,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
          ),
          const ColoredBox(color: Color(0x99000000)),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final bool compact = c.maxHeight < 420;
                return Padding(
                  padding: EdgeInsets.all(compact ? 10 : 16),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            'Shop',
                            style: TextStyle(
                              fontFamily: 'Jersey10',
                              fontSize: compact ? 28 : 36,
                              height: 1,
                              color: Colors.white,
                              shadows: const <Shadow>[
                                Shadow(
                                  color: _ShopScreenState.accent,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.monetization_on,
                                  color: _ShopScreenState.accent,
                                  size: compact ? 18 : 22,
                                ),
                                SizedBox(width: compact ? 4 : 6),
                                Text(
                                  '$_coins',
                                  style: TextStyle(
                                    fontFamily: 'Jersey10',
                                    fontSize: compact ? 18 : 22,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 8 : 12),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(compact ? 8 : 12),
                          decoration: BoxDecoration(
                            color: _panel,
                            border: Border.all(color: _border, width: 4),
                          ),
                          child: !_loaded
                              ? const Center(child: CircularProgressIndicator())
                              : ListView.separated(
                                  itemCount: items.length,
                                  separatorBuilder:
                                      (BuildContext context, int index) =>
                                          SizedBox(height: compact ? 6 : 8),
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final CosmeticItem item = items[index];
                                    final bool owned =
                                        _owned.contains(item.id);
                                    final bool canAfford =
                                        _coins >= (item.shopPrice ?? 0);
                                    final bool equipped = _isEquipped(item);
                                    return _ShopRow(
                                      item: item,
                                      owned: owned,
                                      equipped: equipped,
                                      canAfford: canAfford,
                                      busy: _busyId == item.id,
                                      compact: compact,
                                      onBuy: () => _buy(item),
                                      onEquip: () => _equip(item),
                                    );
                                  },
                                ),
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 12),
                      PixelButton(
                        label: 'Back',
                        icon: Icons.arrow_back,
                        color: const Color(0xFF42A5F5),
                        width: null,
                        compact: compact,
                        onPressed: () => Navigator.of(context).pop(true),
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

class _ShopRow extends StatelessWidget {
  const _ShopRow({
    required this.item,
    required this.owned,
    required this.equipped,
    required this.canAfford,
    required this.busy,
    required this.compact,
    required this.onBuy,
    required this.onEquip,
  });

  final CosmeticItem item;
  final bool owned;
  final bool equipped;
  final bool canAfford;
  final bool busy;
  final bool compact;
  final VoidCallback onBuy;
  final VoidCallback onEquip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161622),
        border: Border.all(color: item.color, width: 3),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: compact ? 44 : 56,
            height: compact ? 44 : 56,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.2),
              border: Border.all(color: const Color(0xFF2B2B3A), width: 2),
            ),
            child: Icon(item.icon, color: item.color, size: compact ? 24 : 30),
          ),
          SizedBox(width: compact ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  style: TextStyle(
                    fontFamily: 'Jersey10',
                    fontSize: compact ? 16 : 20,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: compact ? 2 : 4),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Jersey10',
                    fontSize: compact ? 12 : 14,
                    height: 1.1,
                    color: const Color(0xFFB0BEC5),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 6 : 10),
          if (owned)
            _ShopActionChip(
              label: equipped ? 'Equipped' : 'Equip',
              color: equipped
                  ? const Color(0xFF9FE6A0)
                  : const Color(0xFF26C6DA),
              compact: compact,
              busy: busy,
              enabled: !equipped,
              onTap: onEquip,
            )
          else
            _ShopActionChip(
              label: '${item.shopPrice}',
              showCoin: true,
              color: canAfford
                  ? _ShopScreenState.accent
                  : const Color(0xFF546E7A),
              compact: compact,
              busy: busy,
              enabled: canAfford,
              onTap: onBuy,
            ),
        ],
      ),
    );
  }
}

class _ShopActionChip extends StatelessWidget {
  const _ShopActionChip({
    required this.label,
    required this.color,
    required this.compact,
    required this.busy,
    required this.enabled,
    required this.onTap,
    this.showCoin = false,
  });

  final String label;
  final Color color;
  final bool compact;
  final bool busy;
  final bool enabled;
  final bool showCoin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (!enabled || busy) ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: const Color(0xFF2B2B3A), width: 2),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0xFF2B2B3A), offset: Offset(0, 2)),
          ],
        ),
        child: busy
            ? SizedBox(
                width: compact ? 14 : 18,
                height: compact ? 14 : 18,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (showCoin) ...<Widget>[
                    Icon(
                      Icons.monetization_on,
                      size: compact ? 14 : 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Jersey10',
                      fontSize: compact ? 14 : 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
