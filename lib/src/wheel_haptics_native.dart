import 'package:flutter/services.dart';

import 'wheel_haptics.dart';

/// Uses the haptic engine of iOS and Android.
class PlatformWheelHaptics implements WheelHaptics {
  @override
  void tick() => HapticFeedback.selectionClick();

  @override
  void stop() => HapticFeedback.mediumImpact();
}
