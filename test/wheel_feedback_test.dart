import 'package:flutter_test/flutter_test.dart';
import 'package:happyspin/src/wheel_feedback.dart';
import 'package:happyspin/src/wheel_haptics.dart';
import 'package:happyspin/src/wheel_sounds.dart';

class _CountingSounds implements WheelSounds {
  int ticks = 0;

  @override
  Future<void> load() async {}

  @override
  void unlock() {}

  @override
  void tick(double volume) => ticks++;

  @override
  void chime() {}
}

class _CountingHaptics implements WheelHaptics {
  int ticks = 0;

  @override
  void tick() => ticks++;

  @override
  void stop() {}
}

void main() {
  test('ticks coming faster than the phone can play are skipped', () async {
    final sounds = _CountingSounds();
    final haptics = _CountingHaptics();
    final feedback = DeviceWheelFeedback(
      enabled: () => true,
      sounds: sounds,
      haptics: haptics,
    );

    // A wheel with many choices ticks on every frame.
    for (var i = 0; i < 100; i++) {
      feedback.tick(6);
    }
    expect(sounds.ticks, 1);
    expect(haptics.ticks, 1);

    await Future<void>.delayed(
      DeviceWheelFeedback.minTickInterval + const Duration(milliseconds: 10),
    );
    feedback.tick(6);
    expect(sounds.ticks, 2);
    expect(haptics.ticks, 2);
  });
}
