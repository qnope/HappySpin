import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What the wheel makes the user hear and feel: a tick each time a peg goes
/// past the pointer, and a chime with a stronger buzz when it stops.
abstract class WheelFeedback {
  /// Gets the sounds ready, so that the first tick is not late.
  void preload();

  /// A peg went past the pointer while the wheel turned at [speed] rad/s.
  void tick(double speed);

  /// The wheel stopped on a choice.
  void stop();
}

/// Plays the wheel's sounds and vibrates the device.
class DeviceWheelFeedback implements WheelFeedback {
  /// Ticks can overlap when the wheel spins fast, so several players take
  /// turns playing them.
  static const _tickPlayers = 6;

  Future<AudioPool?>? _ticks;
  AudioPlayer? _chime;

  Future<AudioPool?> _loadTicks() async {
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
    try {
      return await AudioPool.create(
        source: AssetSource('sounds/tick.wav'),
        maxPlayers: _tickPlayers,
        minPlayers: 2,
      );
    } on Object {
      // Without sound, the wheel still vibrates.
      return null;
    }
  }

  @override
  void preload() => _ticks ??= _loadTicks();

  @override
  void tick(double speed) {
    HapticFeedback.selectionClick();
    // Louder when the wheel turns fast, softer as it slows down.
    _playTick((0.35 + speed.abs() / 8).clamp(0.35, 1.0));
  }

  Future<void> _playTick(double volume) async {
    try {
      await (await (_ticks ??= _loadTicks()))?.start(volume: volume);
    } on Object {
      // A missed tick is not worth interrupting the spin for.
    }
  }

  @override
  void stop() {
    HapticFeedback.mediumImpact();
    _playChime();
  }

  Future<void> _playChime() async {
    try {
      await (_chime ??= AudioPlayer()).play(AssetSource('sounds/stop.wav'));
    } on Object {
      // The result still shows without the chime.
    }
  }
}

/// Neither sound nor vibration; for tests and when the user turns them off.
class SilentWheelFeedback implements WheelFeedback {
  const SilentWheelFeedback();

  @override
  void preload() {}

  @override
  void tick(double speed) {}

  @override
  void stop() {}
}
