import 'wheel_sounds_native.dart'
    if (dart.library.js_interop) 'wheel_sounds_web.dart';

/// The two sounds of the wheel, played as quickly as the platform allows so
/// that each tick lands on its peg.
abstract class WheelSounds {
  /// [enabled] tells whether the user wants sounds, so that touches do not
  /// wake the device's audio up when sounds are off.
  factory WheelSounds({required bool Function() enabled}) = PlatformWheelSounds;

  /// Loads the sounds; until then, playing them does nothing.
  Future<void> load();

  /// Lets sound play from now on, where the platform only allows it right
  /// after the user touched the screen. Call it from a tap.
  void unlock();

  /// The click of a peg going past the pointer, at [volume] from 0 to 1.
  void tick(double volume);

  /// The chime of the wheel stopping.
  void chime();
}
