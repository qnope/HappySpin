import 'package:flutter/foundation.dart';

import 'wheel_haptics.dart';
import 'wheel_sounds.dart';

/// What the wheel makes the user hear and feel: a tick each time a peg goes
/// past the pointer, a stronger buzz when it stops, and a chime when a
/// choice wins.
abstract class WheelFeedback {
  /// Gets the sounds ready, so that the first tick is not late. Called from
  /// the tap that spins the wheel, when browsers allow sound to start.
  void preload();

  /// A peg went past the pointer while the wheel turned at [speed] rad/s.
  void tick(double speed);

  /// The wheel stopped on a choice; [celebrate] is false when the choice
  /// is only eliminated, which deserves no chime.
  void stop({bool celebrate = true});

  /// A choice won without the wheel stopping on it: the last one left in
  /// elimination mode.
  void celebrate();
}

/// Plays the wheel's sounds and vibrates the device.
class DeviceWheelFeedback implements WheelFeedback {
  /// [enabled] tells whether the user wants sounds and vibrations.
  DeviceWheelFeedback({
    required bool Function() enabled,
    @visibleForTesting WheelSounds? sounds,
    @visibleForTesting WheelHaptics? haptics,
  }) : _sounds = sounds ?? WheelSounds(enabled: enabled),
       _haptics = haptics ?? WheelHaptics();

  /// Shortest time between two ticks. With many choices, a peg goes past
  /// the pointer on every frame: playing a sound and vibrating that often
  /// floods the phone with more requests than it can handle, until it
  /// stops responding. Past this rate the ticks blur into a buzz anyway.
  static const Duration minTickInterval = Duration(milliseconds: 45);

  final WheelSounds _sounds;
  final WheelHaptics _haptics;
  final Stopwatch _sinceTick = Stopwatch();
  Future<void>? _loading;

  @override
  void preload() {
    _sounds.unlock();
    _load();
  }

  void _load() => _loading ??= _sounds.load().catchError((Object error) {
    // Without sound, the wheel still vibrates; the next spin tries again.
    debugPrint('HappySpin: sounds not loaded: $error');
    _loading = null;
  });

  @override
  void tick(double speed) {
    if (_sinceTick.isRunning && _sinceTick.elapsed < minTickInterval) return;
    _sinceTick
      ..reset()
      ..start();
    _haptics.tick();
    _load();
    // Louder when the wheel turns fast, softer as it slows down.
    _sounds.tick((0.5 + speed.abs() / 8).clamp(0.5, 1.0));
  }

  @override
  void stop({bool celebrate = true}) {
    _haptics.stop();
    if (celebrate) _sounds.chime();
  }

  @override
  void celebrate() {
    _haptics.stop();
    _sounds.chime();
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
  void stop({bool celebrate = true}) {}

  @override
  void celebrate() {}
}
