import 'package:flutter/material.dart';

import '../models/game_character.dart';
import '../models/game_progress.dart';
import '../models/town_location.dart';
import '../services/save_manager.dart';
import '../widgets/park_celebration_overlay.dart';
import '../widgets/school_celebration_overlay.dart';
import '../widgets/neighborhood_celebration_overlay.dart';
import '../widgets/beach_celebration_overlay.dart';
import 'beach_intro_screen.dart';
import 'beach_level8_intro_screen.dart';
import 'location_screen.dart';
import 'park_intro_screen.dart';
import 'park_level2_intro_screen.dart';
import 'school_intro_screen.dart';
import 'school_level4_intro_screen.dart';
import 'neighborhood_intro_screen.dart';
import 'neighborhood_level6_intro_screen.dart';
import 'settings_screen.dart';
import 'town_center_intro_screen.dart';

enum _MapCelebration { none, park, school, neighborhood, beach }

/// The main hub of the game: the town map.
///
/// Shows the coins / title / profile HUD, the action buttons (Customization,
/// Shop, Achievements, Settings) and the five location nodes. Locked locations
/// are disabled until the player unlocks them through progress; only the Park
/// is available at the start.
class TownMapScreen extends StatefulWidget {
  const TownMapScreen({super.key, required this.character});

  static const String routeName = '/town_map';

  final GameCharacter character;

  @override
  State<TownMapScreen> createState() => _TownMapScreenState();
}

class _TownMapScreenState extends State<TownMapScreen> {
  static const double _mapAspect = 1536 / 1024; // town_map_bg.png
  static const Color _mapEdgeColor = Color(0xFF5A8F4A);

  int _coins = 0;
  String _title = SaveManager.defaultTitle;
  Set<String> _unlocked = SaveManager.defaultUnlocked.toSet();
  int _parkMaxLevel = GameProgress.parkLevel1;
  bool _parkRestored = false;
  bool _parkStar = false;
  int _schoolMaxLevel = GameProgress.schoolLevel3;
  bool _schoolRestored = false;
  bool _schoolStar = false;
  int _neighborhoodMaxLevel = GameProgress.neighborhoodLevel5;
  bool _neighborhoodRestored = false;
  bool _neighborhoodStar = false;
  int _beachMaxLevel = GameProgress.beachLevel7;
  bool _beachRestored = false;
  bool _beachStar = false;
  String? _equippedHat;
  bool _loaded = false;
  bool _initialPanSet = false;
  _MapCelebration _celebration = _MapCelebration.none;
  int _celebrationCoins = 0;

  Size _lastViewSize = Size.zero;
  Size _lastMapSize = Size.zero;
  double _lastMaxPanX = 0;
  double _lastMaxPanY = 0;

  final TransformationController _mapTransform = TransformationController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _mapTransform.dispose();
    super.dispose();
  }

  void _applyInitialPan(double viewH, double maxPanY) {
    if (_initialPanSet) return;
    final double startY = (viewH * 0.08).clamp(0.0, maxPanY);
    _mapTransform.value = Matrix4.translationValues(0, startY, 0);
    _initialPanSet = true;
  }

  /// Sizes the pannable map canvas to the image aspect ratio, large enough
  /// to scroll on small screens but never smaller than the viewport.
  ({double w, double h}) _mapSize(
    double viewW,
    double viewH,
    bool compact,
  ) {
    double mapH = viewH;
    double mapW = mapH * _mapAspect;

    final double minH = viewH * (compact ? 1.28 : 1.1);
    final double minW = viewW * (compact ? 1.12 : 1.0);

    if (mapH < minH) {
      mapH = minH;
      mapW = mapH * _mapAspect;
    }
    if (mapW < minW) {
      mapW = minW;
      mapH = mapW / _mapAspect;
    }
    return (w: mapW, h: mapH);
  }

  Future<void> _load() async {
    final int coins = await SaveManager.instance.loadCoins();
    final String title = await SaveManager.instance.loadTitle();
    final bool neighborhoodRestored =
        await SaveManager.instance.isNeighborhoodRestored();
    // Older saves may have restored Neighborhood before Beach unlock existed.
    if (neighborhoodRestored) {
      await SaveManager.instance.unlockLocation(GameProgress.beachLocationId);
    }
    final bool beachRestored = await SaveManager.instance.isBeachRestored();
    final bool beachLevel8Done = await SaveManager.instance.isLevelCompleted(
      GameProgress.beachLocationId,
      GameProgress.beachLevel8,
    );
    // Older saves may have finished Beach before Town Center unlock existed.
    if (beachRestored || beachLevel8Done) {
      await SaveManager.instance.unlockLocation(
        GameProgress.townCenterLocationId,
      );
      if (!beachRestored) {
        await SaveManager.instance.ensureBeachRestoredFlags();
      }
    }
    final Set<String> unlocked =
        await SaveManager.instance.loadUnlockedLocations();
    final int parkMaxLevel = await SaveManager.instance.loadParkMaxLevel();
    final bool parkRestored = await SaveManager.instance.isParkRestored();
    final bool parkStar = await SaveManager.instance.hasParkCompletionStar();
    final int schoolMaxLevel = await SaveManager.instance.loadSchoolMaxLevel();
    final bool schoolRestored = await SaveManager.instance.isSchoolRestored();
    final bool schoolStar = await SaveManager.instance.hasSchoolCompletionStar();
    final int neighborhoodMaxLevel =
        await SaveManager.instance.loadNeighborhoodMaxLevel();
    final bool neighborhoodStar =
        await SaveManager.instance.hasNeighborhoodCompletionStar();
    final int beachMaxLevel = await SaveManager.instance.loadBeachMaxLevel();
    final bool beachRestoredNow =
        await SaveManager.instance.isBeachRestored();
    final bool beachStar = await SaveManager.instance.hasBeachCompletionStar();
    final String? equippedHat = await SaveManager.instance.loadEquippedHat();
    if (!mounted) return;
    setState(() {
      _coins = coins;
      _title = title;
      _unlocked = unlocked;
      _parkMaxLevel = parkMaxLevel;
      _parkRestored = parkRestored;
      _parkStar = parkStar;
      _schoolMaxLevel = schoolMaxLevel;
      _schoolRestored = schoolRestored;
      _schoolStar = schoolStar;
      _neighborhoodMaxLevel = neighborhoodMaxLevel;
      _neighborhoodRestored = neighborhoodRestored;
      _neighborhoodStar = neighborhoodStar;
      _beachMaxLevel = beachMaxLevel;
      _beachRestored = beachRestoredNow;
      _beachStar = beachStar;
      _equippedHat = equippedHat;
      _loaded = true;
    });
  }

  Future<void> _maybeStartParkCelebration() async {
    if (!await SaveManager.instance.hasPendingParkCelebration()) return;
    final int coins = await SaveManager.instance.loadPendingCelebrationCoins();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _celebrationCoins = coins;
        _celebration = _MapCelebration.park;
      });
    });
  }

  Future<void> _maybeStartSchoolCelebration() async {
    if (!await SaveManager.instance.hasPendingSchoolCelebration()) return;
    final int coins =
        await SaveManager.instance.loadPendingSchoolCelebrationCoins();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _celebrationCoins = coins;
        _celebration = _MapCelebration.school;
      });
    });
  }

  Future<void> _maybeStartNeighborhoodCelebration() async {
    if (!await SaveManager.instance.hasPendingNeighborhoodCelebration()) {
      return;
    }
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _celebration = _MapCelebration.neighborhood);
    });
  }

  Future<void> _maybeStartBeachCelebration() async {
    if (!await SaveManager.instance.hasPendingBeachCelebration()) {
      return;
    }
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _celebration = _MapCelebration.beach);
    });
  }

  Future<void> _finishCelebration() async {
    if (_celebration == _MapCelebration.park) {
      await SaveManager.instance.clearPendingParkCelebration();
    } else if (_celebration == _MapCelebration.school) {
      await SaveManager.instance.clearPendingSchoolCelebration();
    } else if (_celebration == _MapCelebration.neighborhood) {
      await SaveManager.instance.clearPendingNeighborhoodCelebration();
    } else if (_celebration == _MapCelebration.beach) {
      await SaveManager.instance.clearPendingBeachCelebration();
    }
    if (!mounted) return;
    setState(() => _celebration = _MapCelebration.none);
    await _load();
  }

  Future<int?> _pickParkLevel() async {
    return showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final double h = MediaQuery.sizeOf(context).height;
        final bool compact = h < 420;
        return Dialog(
          backgroundColor: const Color(0xF00E0E1A),
          insetPadding: EdgeInsets.symmetric(
            horizontal: compact ? 24 : 40,
            vertical: compact ? 12 : 24,
          ),
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: _kBorder, width: 4),
            borderRadius: BorderRadius.zero,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 320 : 360),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 20,
                compact ? 12 : 18,
                compact ? 14 : 20,
                compact ? 12 : 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Choose Park Level',
                    style: TextStyle(
                      fontFamily: 'Jersey10',
                      fontSize: compact ? 26 : 32,
                      height: 1,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 14),
                  _LevelPickTile(
                    label: 'Level 1',
                    subtitle: 'Replay the park cleanup',
                    color: const Color(0xFF4CAF50),
                    compact: compact,
                    onTap: () =>
                        Navigator.of(context).pop(GameProgress.parkLevel1),
                  ),
                  SizedBox(height: compact ? 6 : 10),
                  _LevelPickTile(
                    label: 'Level 2',
                    subtitle: 'New sorting challenge',
                    color: const Color(0xFF1E88E5),
                    compact: compact,
                    onTap: () =>
                        Navigator.of(context).pop(GameProgress.parkLevel2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPark(TownLocation location) async {
    final bool level1Done = await SaveManager.instance.isLevelCompleted(
      GameProgress.parkLocationId,
      GameProgress.parkLevel1,
    );

    if (level1Done && _parkMaxLevel >= GameProgress.parkLevel2) {
      final int? picked = await _pickParkLevel();
      if (!mounted || picked == null) return;

      if (picked == GameProgress.parkLevel2) {
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => ParkLevel2IntroScreen(
              location: location,
              character: widget.character,
            ),
          ),
        );
        if (mounted) await _load();
        return;
      }
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ParkIntroScreen(
          location: location,
          character: widget.character,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
    await _maybeStartParkCelebration();
  }

  String? _nodeLabel(TownLocation location) {
    final bool unlocked = _unlocked.contains(location.id);
    if (location.id == 'park') {
      if (_parkRestored) return 'Restored';
      if (_parkMaxLevel >= GameProgress.parkLevel2) {
        return 'Lv $_parkMaxLevel';
      }
      return null;
    }
    if (location.id == 'school') {
      if (!unlocked) return 'Locked';
      if (_schoolRestored) return 'Restored';
      if (_schoolMaxLevel >= GameProgress.schoolLevel4) {
        return 'Lv $_schoolMaxLevel';
      }
      return 'Unlocked';
    }
    if (location.id == 'neighborhood') {
      if (!unlocked) return 'Locked';
      if (_neighborhoodRestored) return 'Restored';
      if (_neighborhoodMaxLevel >= GameProgress.neighborhoodLevel6) {
        return 'Lv $_neighborhoodMaxLevel';
      }
      return 'Unlocked';
    }
    if (location.id == 'beach') {
      if (!unlocked) return 'Locked';
      if (_beachRestored) return 'Restored';
      if (_beachMaxLevel >= GameProgress.beachLevel8) {
        return 'Lv $_beachMaxLevel';
      }
      return 'Unlocked';
    }
    if (location.id == 'town_center') {
      return unlocked ? 'Unlocked' : 'Locked';
    }
    if (!unlocked) return 'Locked';
    return null;
  }

  Future<void> _openNeighborhood(TownLocation location) async {
    final bool level5Done = await SaveManager.instance.isLevelCompleted(
      GameProgress.neighborhoodLocationId,
      GameProgress.neighborhoodLevel5,
    );

    if (level5Done &&
        _neighborhoodMaxLevel >= GameProgress.neighborhoodLevel6) {
      final int? picked = await _pickNeighborhoodLevel();
      if (!mounted || picked == null) return;
      if (picked == GameProgress.neighborhoodLevel6) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => NeighborhoodLevel6IntroScreen(
              location: location,
              character: widget.character,
            ),
          ),
        );
        if (mounted) await _load();
        return;
      }
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => NeighborhoodIntroScreen(
          location: location,
          character: widget.character,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
    await _maybeStartNeighborhoodCelebration();
  }

  Future<int?> _pickNeighborhoodLevel() async {
    return showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final double h = MediaQuery.sizeOf(context).height;
        final bool compact = h < 420;
        return Dialog(
          backgroundColor: const Color(0xF00E0E1A),
          insetPadding: EdgeInsets.symmetric(
            horizontal: compact ? 24 : 40,
            vertical: compact ? 12 : 24,
          ),
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: _kBorder, width: 4),
            borderRadius: BorderRadius.zero,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 320 : 360),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 20,
                compact ? 12 : 18,
                compact ? 14 : 20,
                compact ? 12 : 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Choose Neighborhood Level',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Jersey10',
                      fontSize: compact ? 24 : 30,
                      height: 1,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 14),
                  _LevelPickTile(
                    label: 'Level 5',
                    subtitle: 'Puzzle + household sorting',
                    color: const Color(0xFFEC407A),
                    compact: compact,
                    onTap: () => Navigator.of(context)
                        .pop(GameProgress.neighborhoodLevel5),
                  ),
                  SizedBox(height: compact ? 6 : 10),
                  _LevelPickTile(
                    label: 'Level 6',
                    subtitle: 'Community cleanup sorting',
                    color: const Color(0xFF7E57C2),
                    compact: compact,
                    onTap: () => Navigator.of(context)
                        .pop(GameProgress.neighborhoodLevel6),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSchool(TownLocation location) async {
    final bool level3Done = await SaveManager.instance.isLevelCompleted(
      GameProgress.schoolLocationId,
      GameProgress.schoolLevel3,
    );

    if (level3Done && _schoolMaxLevel >= GameProgress.schoolLevel4) {
      final int? picked = await _pickSchoolLevel();
      if (!mounted || picked == null) return;
      if (picked == GameProgress.schoolLevel4) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => SchoolLevel4IntroScreen(
              location: location,
              character: widget.character,
            ),
          ),
        );
        if (mounted) await _load();
        return;
      }
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SchoolIntroScreen(
          location: location,
          character: widget.character,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
    await _maybeStartSchoolCelebration();
  }

  Future<int?> _pickSchoolLevel() async {
    return showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final double h = MediaQuery.sizeOf(context).height;
        final bool compact = h < 420;
        return Dialog(
          backgroundColor: const Color(0xF00E0E1A),
          insetPadding: EdgeInsets.symmetric(
            horizontal: compact ? 24 : 40,
            vertical: compact ? 12 : 24,
          ),
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: _kBorder, width: 4),
            borderRadius: BorderRadius.zero,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 320 : 360),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 20,
                compact ? 12 : 18,
                compact ? 14 : 20,
                compact ? 12 : 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Choose School Level',
                    style: TextStyle(
                      fontFamily: 'Jersey10',
                      fontSize: compact ? 26 : 32,
                      height: 1,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 14),
                  _LevelPickTile(
                    label: 'Level 3',
                    subtitle: 'Puzzle + compost',
                    color: const Color(0xFFFFB300),
                    compact: compact,
                    onTap: () =>
                        Navigator.of(context).pop(GameProgress.schoolLevel3),
                  ),
                  SizedBox(height: compact ? 6 : 10),
                  _LevelPickTile(
                    label: 'Level 4',
                    subtitle: 'Finish the campus',
                    color: const Color(0xFF00897B),
                    compact: compact,
                    onTap: () =>
                        Navigator.of(context).pop(GameProgress.schoolLevel4),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onLocationTap(TownLocation location, bool unlocked) async {
    if (!unlocked) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${location.name} is locked. Keep playing to '
                'unlock it!'),
            duration: const Duration(milliseconds: 1400),
          ),
        );
      return;
    }
    if (location.id == 'park') {
      await _openPark(location);
      return;
    }
    if (location.id == 'school') {
      await _openSchool(location);
      return;
    }
    if (location.id == 'neighborhood') {
      await _openNeighborhood(location);
      return;
    }
    if (location.id == 'beach') {
      await _openBeach(location);
      return;
    }
    if (location.id == 'town_center') {
      await _openTownCenter(location);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => LocationScreen(
          location: location,
          character: widget.character,
        ),
      ),
    );
  }

  Future<void> _openTownCenter(TownLocation location) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => TownCenterIntroScreen(
          location: location,
          character: widget.character,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _openBeach(TownLocation location) async {
    final bool level7Done = await SaveManager.instance.isLevelCompleted(
      GameProgress.beachLocationId,
      GameProgress.beachLevel7,
    );

    // After Level 7, always offer Level 7 / Level 8 (like Park & Neighborhood).
    if (level7Done) {
      if (_beachMaxLevel < GameProgress.beachLevel8) {
        await SaveManager.instance.ensureBeachLevel8Unlocked();
        if (mounted) await _load();
      }
      final int? picked = await _pickBeachLevel();
      if (!mounted || picked == null) return;

      if (picked == GameProgress.beachLevel8) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => BeachLevel8IntroScreen(
              location: location,
              character: widget.character,
            ),
          ),
        );
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => BeachIntroScreen(
              location: location,
              character: widget.character,
            ),
          ),
        );
        if (mounted) await _maybeStartBeachCelebration();
      }
      if (mounted) await _load();
      return;
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => BeachIntroScreen(
          location: location,
          character: widget.character,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
    await _maybeStartBeachCelebration();
  }

  Future<int?> _pickBeachLevel() async {
    return showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final double h = MediaQuery.sizeOf(context).height;
        final bool compact = h < 420;
        return Dialog(
          backgroundColor: const Color(0xF00E0E1A),
          insetPadding: EdgeInsets.symmetric(
            horizontal: compact ? 24 : 40,
            vertical: compact ? 12 : 24,
          ),
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: _kBorder, width: 4),
            borderRadius: BorderRadius.zero,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 320 : 360),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 20,
                compact ? 12 : 18,
                compact ? 14 : 20,
                compact ? 12 : 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Choose Beach Level',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Jersey10',
                      fontSize: compact ? 24 : 30,
                      height: 1,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 14),
                  _LevelPickTile(
                    label: 'Level 7',
                    subtitle: 'Saving the Shore',
                    color: const Color(0xFF29B6F6),
                    compact: compact,
                    onTap: () =>
                        Navigator.of(context).pop(GameProgress.beachLevel7),
                  ),
                  SizedBox(height: compact ? 6 : 10),
                  _LevelPickTile(
                    label: 'Level 8',
                    subtitle: 'Protecting Marine Life',
                    color: const Color(0xFF00838F),
                    compact: compact,
                    onTap: () =>
                        Navigator.of(context).pop(GameProgress.beachLevel8),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$feature coming soon!'),
          duration: const Duration(milliseconds: 1200),
        ),
      );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mapEdgeColor,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double viewW = constraints.maxWidth;
          final double viewH = constraints.maxHeight;
          final bool compact = viewH < 420;
          final ({double w, double h}) mapSize =
              _mapSize(viewW, viewH, compact);
          final double maxPanY = (mapSize.h - viewH).clamp(0.0, double.infinity);
          final double maxPanX = (mapSize.w - viewW).clamp(0.0, double.infinity);

          _lastViewSize = Size(viewW, viewH);
          _lastMapSize = Size(mapSize.w, mapSize.h);
          _lastMaxPanX = maxPanX;
          _lastMaxPanY = maxPanY;

          if (_loaded &&
              !_initialPanSet &&
              compact &&
              _celebration == _MapCelebration.none) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _applyInitialPan(viewH, maxPanY);
            });
          }

          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ClipRect(
                child: InteractiveViewer(
                  transformationController: _mapTransform,
                  panEnabled: _celebration == _MapCelebration.none,
                  scaleEnabled: false,
                  constrained: false,
                  // Zero margin — cannot drag past the image edges.
                  boundaryMargin: EdgeInsets.zero,
                  onInteractionUpdate: (_) => _clampPan(maxPanX, maxPanY),
                  onInteractionEnd: (_) => _clampPan(maxPanX, maxPanY),
                  child: SizedBox(
                    width: mapSize.w,
                    height: mapSize.h,
                    child: ColoredBox(
                      color: _mapEdgeColor,
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: <Widget>[
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/png/town_map_bg.png',
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.none,
                            ),
                          ),
                          if (_loaded)
                            for (final TownLocation location
                                in TownLocation.all)
                              Align(
                                alignment: location.position,
                                child: _LocationNode(
                                  location: location,
                                  unlocked: _unlocked.contains(location.id),
                                  compact: compact,
                                  levelLabel: _nodeLabel(location),
                                  restored: (location.id == 'park' &&
                                          _parkRestored) ||
                                      (location.id == 'school' &&
                                          _schoolRestored) ||
                                      (location.id == 'neighborhood' &&
                                          _neighborhoodRestored) ||
                                      (location.id == 'beach' &&
                                          _beachRestored),
                                  showStar: (location.id == 'park' &&
                                          _parkStar) ||
                                      (location.id == 'school' &&
                                          _schoolStar) ||
                                      (location.id == 'neighborhood' &&
                                          _neighborhoodStar) ||
                                      (location.id == 'beach' && _beachStar),
                                  onTap: () => _onLocationTap(
                                    location,
                                    _unlocked.contains(location.id),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Fixed HUD — stays put while the map pans underneath.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.all(compact ? 6 : 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _ProfileBadge(
                          character: widget.character,
                          title: _title,
                          equippedHat: _equippedHat,
                          compact: compact,
                        ),
                        SizedBox(width: compact ? 6 : 10),
                        _CoinsPill(coins: _coins, compact: compact),
                        const Spacer(),
                        _ActionButtons(
                          compact: compact,
                          onCustomization: () => _comingSoon('Customization'),
                          onShop: () => _comingSoon('Shop'),
                          onAchievements: () => _comingSoon('Achievements'),
                          onSettings: _openSettings,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (compact && _celebration == _MapCelebration.none)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: SafeArea(
                    top: false,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC0E0E1A),
                          border: Border.all(color: _kBorder, width: 2),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.swipe,
                              color: Color(0xFFDCE6DC),
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Drag to explore the map',
                              style: TextStyle(
                                fontFamily: 'Jersey10',
                                fontSize: 18,
                                height: 1,
                                color: Color(0xFFDCE6DC),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              if (_celebration == _MapCelebration.park)
                ParkCelebrationOverlay(
                  mapTransform: _mapTransform,
                  mapSize: _lastMapSize,
                  viewSize: _lastViewSize,
                  maxPanX: _lastMaxPanX,
                  maxPanY: _lastMaxPanY,
                  coinsEarned: _celebrationCoins,
                  onFinished: _finishCelebration,
                ),
              if (_celebration == _MapCelebration.school)
                SchoolCelebrationOverlay(
                  mapTransform: _mapTransform,
                  mapSize: _lastMapSize,
                  viewSize: _lastViewSize,
                  maxPanX: _lastMaxPanX,
                  maxPanY: _lastMaxPanY,
                  coinsEarned: _celebrationCoins,
                  onFinished: _finishCelebration,
                ),
              if (_celebration == _MapCelebration.neighborhood)
                NeighborhoodCelebrationOverlay(
                  mapTransform: _mapTransform,
                  mapSize: _lastMapSize,
                  viewSize: _lastViewSize,
                  maxPanX: _lastMaxPanX,
                  maxPanY: _lastMaxPanY,
                  onFinished: _finishCelebration,
                ),
              if (_celebration == _MapCelebration.beach)
                BeachCelebrationOverlay(
                  mapTransform: _mapTransform,
                  mapSize: _lastMapSize,
                  viewSize: _lastViewSize,
                  maxPanX: _lastMaxPanX,
                  maxPanY: _lastMaxPanY,
                  onFinished: _finishCelebration,
                ),
            ],
          );
        },
      ),
    );
  }

  /// Keeps the translation inside the map image — no white gutters.
  void _clampPan(double maxPanX, double maxPanY) {
    final Matrix4 m = _mapTransform.value;
    final double x = m.getTranslation().x.clamp(-maxPanX, 0.0);
    final double y = m.getTranslation().y.clamp(-maxPanY, 0.0);
    if (x != m.getTranslation().x || y != m.getTranslation().y) {
      _mapTransform.value = Matrix4.translationValues(x, y, 0);
    }
  }
}

// ---------------------------------------------------------------------------
// HUD widgets
// ---------------------------------------------------------------------------

const Color _kBorder = Color(0xFF2B2B3A);

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({
    required this.character,
    required this.title,
    this.equippedHat,
    this.compact = false,
  });

  final GameCharacter character;
  final String title;
  final String? equippedHat;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double avatar = compact ? 36 : 46;
    final double nameSize = compact ? 20 : 26;
    final double titleSize = compact ? 16 : 20;

    return Container(
      padding: EdgeInsets.fromLTRB(5, 5, compact ? 8 : 12, 5),
      decoration: BoxDecoration(
        color: const Color(0xF00E0E1A),
        border: Border.all(color: _kBorder, width: 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: avatar,
            height: avatar,
            decoration: BoxDecoration(
              color: character.accent,
              border: Border.all(color: _kBorder, width: 3),
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                OverflowBox(
                  maxHeight: avatar * 2,
                  alignment: Alignment.topCenter,
                  child: Image.asset(
                    character.cutoutAsset,
                    filterQuality: FilterQuality.none,
                    fit: BoxFit.cover,
                  ),
                ),
                if (equippedHat == GameProgress.ecoHatId ||
                    equippedHat == GameProgress.greenCapId ||
                    equippedHat == GameProgress.beachHatId)
                  Positioned(
                    top: compact ? -4 : -6,
                    left: 0,
                    right: 0,
                    child: Icon(
                      Icons.checkroom,
                      color: equippedHat == GameProgress.beachHatId
                          ? const Color(0xFF29B6F6)
                          : equippedHat == GameProgress.greenCapId
                              ? const Color(0xFF43A047)
                              : const Color(0xFF66BB6A),
                      size: compact ? 18 : 22,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                character.name,
                style: TextStyle(
                  fontFamily: 'Jersey10',
                  fontSize: nameSize,
                  height: 1,
                  color: Colors.white,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Jersey10',
                  fontSize: titleSize,
                  height: 1.1,
                  color: character.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoinsPill extends StatelessWidget {
  const _CoinsPill({required this.coins, this.compact = false});

  final int coins;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double coinSize = compact ? 18 : 22;
    final double fontSize = compact ? 20 : 26;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 5 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xF00E0E1A),
        border: Border.all(color: _kBorder, width: 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: coinSize,
            height: coinSize,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB8860B), width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              '\$',
              style: TextStyle(
                fontFamily: 'Jersey10',
                fontSize: compact ? 14 : 18,
                height: 1,
                color: const Color(0xFF7A5B00),
              ),
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Text(
            '$coins',
            style: TextStyle(
              fontFamily: 'Jersey10',
              fontSize: fontSize,
              height: 1,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onCustomization,
    required this.onShop,
    required this.onAchievements,
    required this.onSettings,
    this.compact = false,
  });

  final VoidCallback onCustomization;
  final VoidCallback onShop;
  final VoidCallback onAchievements;
  final VoidCallback onSettings;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _HudIconButton(
          icon: Icons.checkroom,
          label: 'Style',
          color: const Color(0xFF26C6DA),
          compact: compact,
          onTap: onCustomization,
        ),
        SizedBox(width: compact ? 5 : 8),
        _HudIconButton(
          icon: Icons.storefront,
          label: 'Shop',
          color: const Color(0xFF66BB6A),
          compact: compact,
          onTap: onShop,
        ),
        SizedBox(width: compact ? 5 : 8),
        _HudIconButton(
          icon: Icons.emoji_events,
          label: 'Awards',
          color: const Color(0xFFFFB300),
          compact: compact,
          onTap: onAchievements,
        ),
        SizedBox(width: compact ? 5 : 8),
        _HudIconButton(
          icon: Icons.settings,
          label: 'Settings',
          color: const Color(0xFF90A4AE),
          compact: compact,
          onTap: onSettings,
        ),
      ],
    );
  }
}

class _HudIconButton extends StatelessWidget {
  const _HudIconButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double size = compact ? 38 : 48;
    final double iconSize = compact ? 20 : 26;
    final double labelSize = compact ? 14 : 18;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: _kBorder, width: 3),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: _kBorder, offset: Offset(0, 3)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
          SizedBox(height: compact ? 3 : 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Jersey10',
              fontSize: labelSize,
              height: 1,
              color: Colors.white,
              shadows: const <Shadow>[
                Shadow(color: _kBorder, offset: Offset(1, 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Location node
// ---------------------------------------------------------------------------

class _LocationNode extends StatefulWidget {
  const _LocationNode({
    required this.location,
    required this.unlocked,
    required this.onTap,
    this.compact = false,
    this.levelLabel,
    this.restored = false,
    this.showStar = false,
  });

  final TownLocation location;
  final bool unlocked;
  final VoidCallback onTap;
  final bool compact;
  final String? levelLabel;
  final bool restored;
  final bool showStar;

  @override
  State<_LocationNode> createState() => _LocationNodeState();
}

class _LocationNodeState extends State<_LocationNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.unlocked) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool unlocked = widget.unlocked;
    final bool compact = widget.compact;
    final Color medallionColor = unlocked
        ? (widget.restored
            ? const Color(0xFF66BB6A)
            : widget.location.color)
        : const Color(0xFF9E9E9E);
    final double nodeSize = compact ? 48 : 60;
    final double iconSize = compact ? 26 : 32;
    final double nameSize = compact ? 18 : 22;

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ScaleTransition(
            scale: unlocked
                ? Tween<double>(begin: 1.0, end: 1.10).animate(
                    CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                  )
                : const AlwaysStoppedAnimation<double>(1.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  width: nodeSize,
                  height: nodeSize,
                  decoration: BoxDecoration(
                    color: medallionColor,
                    border: Border.all(color: _kBorder, width: compact ? 3 : 4),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(color: _kBorder, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Icon(
                    widget.location.icon,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
                Positioned(
                  right: compact ? -6 : -8,
                  top: compact ? -6 : -8,
                  child: _StateBadge(
                    unlocked: unlocked,
                    restored: widget.restored,
                    showStar: widget.showStar,
                    compact: compact,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 6 : 10),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 8,
              vertical: compact ? 2 : 3,
            ),
            decoration: BoxDecoration(
              color: unlocked ? const Color(0xF00E0E1A) : const Color(0xCC30303A),
              border: Border.all(color: _kBorder, width: 3),
            ),
            child: Text(
              widget.levelLabel != null
                  ? '${widget.location.name}  ${widget.levelLabel}'
                  : widget.location.name,
              style: TextStyle(
                fontFamily: 'Jersey10',
                fontSize: nameSize,
                height: 1,
                color: unlocked ? Colors.white : const Color(0xFFBDBDBD),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({
    required this.unlocked,
    this.restored = false,
    this.showStar = false,
    this.compact = false,
  });

  final bool unlocked;
  final bool restored;
  final bool showStar;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double iconSize = compact ? 13 : 16;
    final Color bg = !unlocked
        ? const Color(0xFF616161)
        : restored
            ? const Color(0xFF2E7D32)
            : const Color(0xFF43A047);
    final IconData icon = !unlocked
        ? Icons.lock
        : showStar
            ? Icons.star
            : Icons.check;

    return Container(
      padding: EdgeInsets.all(compact ? 2 : 3),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: _kBorder, width: 2),
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}

class _LevelPickTile extends StatelessWidget {
  const _LevelPickTile({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF161622),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 7 : 12,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: compact ? 2 : 3),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.play_arrow, color: color, size: compact ? 22 : 28),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Jersey10',
                        fontSize: compact ? 22 : 28,
                        height: 1,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: compact ? 2 : 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Jersey10',
                        fontSize: compact ? 15 : 18,
                        height: 1,
                        color: const Color(0xFFB0BEC5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
