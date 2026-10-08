import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'wheel_sounds.dart';

/// Plays the sounds with the platform's audio players, on iOS and Android.
class PlatformWheelSounds implements WheelSounds {
  PlatformWheelSounds({required bool Function() enabled});

  /// Ticks can overlap when the wheel spins fast, so several players take
  /// turns playing them.
  static const _voices = 6;

  final List<AudioPlayer> _ticks = [];
  var _next = 0;
  AudioPlayer? _chime;

  // Players still busy starting their sound. A tick waiting for its player
  // is skipped rather than queued: queued requests would pile up faster
  // than the phone plays them, and keep it busy long after the spin.
  final Set<AudioPlayer> _starting = {};

  /// Mixes with the user's music rather than pausing it. On iPhone this
  /// takes the playback category, which plays even in silent mode: iOS
  /// refuses to mix the ambient one, and would then play the sounds with
  /// its default category, which follows the silent switch and pauses the
  /// music. Sounds can be turned off in the settings instead.
  @visibleForTesting
  static AudioContext audioContext() => AudioContext(
    android: AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)
        .buildAndroid(),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  @override
  Future<void> load() async {
    try {
      await AudioPlayer.global.setAudioContext(audioContext());
    } on Object catch (error) {
      // Not every platform lets the audio context be changed.
      debugPrint('HappySpin: audio context not set: $error');
    }
    final ticks = [
      for (var i = 0; i < _voices; i++)
        await _player('sounds/tick.wav', PlayerMode.lowLatency),
    ];
    _chime = await _player('sounds/stop.wav', PlayerMode.mediaPlayer);
    _ticks.addAll(ticks);
  }

  Future<AudioPlayer> _player(String asset, PlayerMode mode) async {
    final player = AudioPlayer();
    // Keep the sound loaded once played, ready for the next time.
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setPlayerMode(mode);
    await player.setSource(AssetSource(asset));
    return player;
  }

  @override
  void unlock() {}

  @override
  void tick(double volume) {
    if (_ticks.isEmpty) return;
    _play(_ticks[_next++ % _ticks.length], volume);
  }

  @override
  void chime() {
    if (_chime case final chime?) _play(chime, 1);
  }

  Future<void> _play(AudioPlayer player, double volume) async {
    if (!_starting.add(player)) return;
    try {
      await player.setVolume(volume);
      await player.resume();
    } on Object catch (error) {
      // A missed sound is not worth interrupting the spin for.
      debugPrint('HappySpin: sound not played: $error');
    } finally {
      _starting.remove(player);
    }
  }
}
