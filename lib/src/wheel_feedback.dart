import 'package:flutter/services.dart';

import 'wheel_sounds.dart';

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
  final WheelSounds _sounds = WheelSounds();
  Future<void>? _loading;

  @override
  void preload() => _loading ??= _sounds.load().catchError((Object _) {
    // Without sound, the wheel still vibrates.
  });

  @override
  void tick(double speed) {
    HapticFeedback.selectionClick();
    preload();
    // Louder when the wheel turns fast, softer as it slows down.
    _sounds.tick((0.35 + speed.abs() / 8).clamp(0.35, 1.0));
  }

  @override
  void stop() {
    HapticFeedback.mediumImpact();
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
  void stop() {}
}
