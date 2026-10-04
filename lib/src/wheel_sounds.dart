import 'wheel_sounds_native.dart'
    if (dart.library.js_interop) 'wheel_sounds_web.dart';

/// The two sounds of the wheel, played as quickly as the platform allows so
/// that each tick lands on its peg.
abstract class WheelSounds {
  factory WheelSounds() = PlatformWheelSounds;

  /// Loads the sounds; until then, playing them does nothing.
  Future<void> load();

  /// The click of a peg going past the pointer, at [volume] from 0 to 1.
  void tick(double volume);

  /// The chime of the wheel stopping.
  void chime();
}
