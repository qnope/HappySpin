import 'wheel_haptics_native.dart'
    if (dart.library.js_interop) 'wheel_haptics_web.dart';

/// The vibrations of the wheel.
abstract class WheelHaptics {
  factory WheelHaptics() = PlatformWheelHaptics;

  /// A light tap for a peg going past the pointer.
  void tick();

  /// A stronger buzz when the wheel stops.
  void stop();
}
