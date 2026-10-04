import 'wheel_haptics.dart';
import 'wheel_sounds.dart';

/// What the wheel makes the user hear and feel: a tick each time a peg goes
/// past the pointer, and a chime with a stronger buzz when it stops.
abstract class WheelFeedback {
  /// Gets the sounds ready, so that the first tick is not late. Called from
  /// the tap that spins the wheel, when browsers allow sound to start.
  void preload();

  /// A peg went past the pointer while the wheel turned at [speed] rad/s.
  void tick(double speed);

  /// The wheel stopped on a choice.
  void stop();
}

/// Plays the wheel's sounds and vibrates the device.
class DeviceWheelFeedback implements WheelFeedback {
  /// [enabled] tells whether the user wants sounds and vibrations.
  DeviceWheelFeedback({required bool Function() enabled})
    : _sounds = WheelSounds(enabled: enabled);

  final WheelSounds _sounds;
  final WheelHaptics _haptics = WheelHaptics();
  Future<void>? _loading;

  @override
  void preload() {
    _sounds.unlock();
    _load();
  }

  void _load() => _loading ??= _sounds.load().catchError((Object _) {
    // Without sound, the wheel still vibrates.
  });

  @override
  void tick(double speed) {
    _haptics.tick();
    _load();
    // Louder when the wheel turns fast, softer as it slows down.
    _sounds.tick((0.5 + speed.abs() / 8).clamp(0.5, 1.0));
  }

  @override
  void stop() {
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
  void stop() {}
}
