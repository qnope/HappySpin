import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'wheel_sounds.dart';

/// Plays the sounds with the platform's audio players, on iOS and Android.
class PlatformWheelSounds implements WheelSounds {
  /// Ticks can overlap when the wheel spins fast, so several players take
  /// turns playing them.
  static const _voices = 6;

  final List<AudioPlayer> _ticks = [];
  var _next = 0;
  AudioPlayer? _chime;

  @override
  Future<void> load() async {
    try {
      // Mix with the user's music rather than pausing it, and stay quiet
      // when an iPhone is switched to silent.
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
          respectSilence: defaultTargetPlatform == TargetPlatform.iOS,
        ).build(),
      );
    } on Object {
      // Not every platform lets the audio context be changed.
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
  void tick(double volume) {
    if (_ticks.isEmpty) return;
    _play(_ticks[_next++ % _ticks.length], volume);
  }

  @override
  void chime() {
    if (_chime case final chime?) _play(chime, 1);
  }

  Future<void> _play(AudioPlayer player, double volume) async {
    try {
      await player.setVolume(volume);
      await player.resume();
    } on Object {
      // A missed sound is not worth interrupting the spin for.
    }
  }
}
