import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Handles looping background music for the game.
///
/// A single shared instance keeps one [AudioPlayer] alive so the music
/// persists across screens instead of restarting on every navigation.
class AudioManager {
  AudioManager._();

  static final AudioManager instance = AudioManager._();

  // Path is relative to the `assets/` folder for AssetSource.
  static const String _bgMusicAsset = 'audio/bg_music.mp3';
  static const String _snapAsset = 'audio/snap.wav';

  final AudioPlayer _bgPlayer = AudioPlayer(playerId: 'bg_music');
  final AudioPlayer _sfxPlayer = AudioPlayer(playerId: 'sfx');

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  double _volume = 0.6;
  double get volume => _volume;

  // Background music is unmuted by default.
  bool _isMuted = false;
  bool get isMuted => _isMuted;

  /// Starts (or resumes) the looping background track.
  Future<void> startBackgroundMusic() async {
    if (_isPlaying) return;
    try {
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.setVolume(_isMuted ? 0 : _volume);
      await _bgPlayer.play(AssetSource(_bgMusicAsset));
      _isPlaying = true;
    } catch (error, stackTrace) {
      debugPrint('Failed to start background music: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> stopBackgroundMusic() async {
    await _bgPlayer.stop();
    _isPlaying = false;
  }

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0);
    if (!_isMuted) {
      await _bgPlayer.setVolume(_volume);
    }
  }

  /// Enables or disables background music without stopping playback,
  /// so unmuting resumes the track at its current position.
  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    await _bgPlayer.setVolume(_isMuted ? 0 : _volume);
  }

  Future<bool> toggleMute() async {
    await setMuted(!_isMuted);
    return _isMuted;
  }

  /// Plays the short "snap" sound used when a puzzle piece locks in place.
  /// Honors the current mute setting and can be re-triggered rapidly.
  Future<void> playSnap() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _sfxPlayer.setVolume(1.0);
      await _sfxPlayer.play(AssetSource(_snapAsset));
    } catch (error, stackTrace) {
      debugPrint('Failed to play snap sfx: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> dispose() async {
    await _bgPlayer.dispose();
    await _sfxPlayer.dispose();
    _isPlaying = false;
  }
}
