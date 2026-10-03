import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:happyspin/src/wheel_math.dart';
import 'package:happyspin/src/wheel_physics.dart';

/// Spins until the wheel rests and returns how long it took, in seconds.
double spin(WheelPhysics wheel) {
  var time = 0.0;
  while (!wheel.isAtRest && time < 60) {
    wheel.advance(1 / 60);
    time += 1 / 60;
  }
  return time;
}

void main() {
  test('a spin stops after a few gentle turns', () {
    final random = math.Random(7);
    for (var count = 2; count <= 16; count++) {
      for (var k = 0; k < 20; k++) {
        final wheel = WheelPhysics(
          layout: WheelLayout.even(count),
          angle: random.nextDouble() * fullTurn,
          velocity: 4.5 + random.nextDouble() * 2,
        );
        final start = wheel.angle;
        final time = spin(wheel);
        final turns = (wheel.angle - start) / fullTurn;
        expect(time, inInclusiveRange(3, 10), reason: 'count=$count');
        expect(turns, inInclusiveRange(0.8, 5), reason: 'count=$count');
      }
    }
  });

  test('every peg going past the pointer is a click', () {
    final wheel = WheelPhysics(
      layout: WheelLayout.even(8),
      angle: 0.3,
      velocity: 8,
    );
    final start = wheel.angle;
    spin(wheel);
    final seg = segmentAngle(8);
    // Pegs sit in the middle of the segments.
    int pegsBefore(double angle) => ((angle + seg / 2) / seg).floor();
    final crossed = pegsBefore(wheel.angle) - pegsBefore(start);
    expect(wheel.clicks, crossed);
  });

  test('the wheel slows down on each peg', () {
    final wheel = WheelPhysics(
      layout: WheelLayout.even(4),
      angle: 0.4,
      velocity: 7,
    );
    // Let the closest peg reach the pointer.
    while (wheel.pegOffset > -wheel.contactWidth + 0.01 ||
        wheel.pegOffset > 0) {
      wheel.advance(WheelPhysics.timeStep);
    }
    final before = wheel.velocity;
    final clicks = wheel.clicks;
    while (wheel.clicks == clicks) {
      wheel.advance(WheelPhysics.timeStep);
    }
    final frictionOnly =
        before - WheelPhysics.friction * (2 * wheel.contactWidth / before);
    expect(wheel.velocity, lessThan(frictionOnly - 0.1));
  });

  test('the pointer bends then springs back past its rest position', () {
    final wheel = WheelPhysics(
      layout: WheelLayout.even(4),
      angle: 0.4,
      velocity: 7,
    );
    var maxBend = 0.0;
    var minBend = 0.0;
    final clicks = wheel.clicks;
    while (wheel.clicks == clicks) {
      wheel.advance(WheelPhysics.timeStep);
      maxBend = math.max(maxBend, wheel.pointer);
    }
    for (var i = 0; i < 60; i++) {
      wheel.advance(WheelPhysics.timeStep);
      minBend = math.min(minBend, wheel.pointer);
    }
    expect(maxBend, greaterThanOrEqualTo(1));
    expect(minBend, lessThan(-0.2));
  });

  test('the wheel never stops with a peg under the pointer', () {
    final random = math.Random(3);
    for (var k = 0; k < 200; k++) {
      final count = 2 + random.nextInt(10);
      final wheel = WheelPhysics(
        layout: WheelLayout.even(count),
        angle: random.nextDouble() * fullTurn,
        velocity: 4.5 + random.nextDouble() * 2,
      );
      spin(wheel);
      expect(wheel.pegOffset.abs(), greaterThan(0.001));
    }
  });

  test('every segment can win', () {
    final random = math.Random(11);
    final wins = List.filled(6, 0);
    for (var k = 0; k < 300; k++) {
      final wheel = WheelPhysics(
        layout: WheelLayout.even(6),
        angle: 0,
        velocity: 4.5 + random.nextDouble() * 2,
      );
      spin(wheel);
      wins[wheel.selectedIndex]++;
    }
    for (final w in wins) {
      expect(w, greaterThan(25));
    }
  });

  test('a weighted wheel still spins well and clicks on every peg', () {
    final random = math.Random(5);
    for (var k = 0; k < 100; k++) {
      final weights = [
        for (var i = 0; i < 2 + random.nextInt(8); i++) 1 + random.nextInt(10),
      ];
      final layout = WheelLayout(weights);
      final wheel = WheelPhysics(
        layout: layout,
        angle: random.nextDouble() * fullTurn,
        velocity: 4.5 + random.nextDouble() * 2,
      );
      final start = wheel.angle;
      final time = spin(wheel);
      final turns = (wheel.angle - start) / fullTurn;
      expect(time, inInclusiveRange(3, 10), reason: '$weights');
      expect(turns, inInclusiveRange(0.8, 5), reason: '$weights');
      expect(wheel.pegOffset.abs(), greaterThan(0.001), reason: '$weights');
    }
  });

  test('a choice wins as often as its segment is wide', () {
    final random = math.Random(13);
    final layout = WheelLayout([1, 3, 1, 5]);
    final wins = List.filled(4, 0);
    const spins = 1000;
    var angle = 0.0;
    for (var k = 0; k < spins; k++) {
      // Like in the app, each spin starts where the last one stopped.
      final wheel = WheelPhysics(
        layout: layout,
        angle: angle,
        velocity: 4.5 + random.nextDouble() * 2,
      );
      spin(wheel);
      angle = wheel.angle;
      wins[wheel.selectedIndex]++;
    }
    for (var i = 0; i < 4; i++) {
      final expected = layout.sweep(i) / fullTurn;
      expect(wins[i] / spins, closeTo(expected, 0.05), reason: '$wins');
    }
  });

  test('pressing on the wheel stops it much sooner', () {
    final random = math.Random(17);
    for (var k = 0; k < 100; k++) {
      final count = 2 + random.nextInt(10);
      final angle = random.nextDouble() * fullTurn;
      final velocity = 4.5 + random.nextDouble() * 2;
      final free = WheelPhysics(
        layout: WheelLayout.even(count),
        angle: angle,
        velocity: velocity,
      );
      final braked = WheelPhysics(
        layout: WheelLayout.even(count),
        angle: angle,
        velocity: velocity,
      )..braking = true;
      expect(spin(free), greaterThan(3), reason: 'count=$count');
      braked.advance(1.5);
      expect(braked.velocity, 0, reason: 'count=$count');
      // Once the finger lets go, the wheel quickly settles, never on a peg.
      braked.braking = false;
      expect(spin(braked), lessThan(1), reason: 'count=$count');
      expect(braked.pegOffset.abs(), greaterThan(0.001));
    }
  });

  test('braking keeps the draw proportional to the weights', () {
    final random = math.Random(19);
    final layout = WheelLayout([1, 3, 1, 5]);
    final wins = List.filled(4, 0);
    const spins = 1000;
    var angle = 0.0;
    for (var k = 0; k < spins; k++) {
      final wheel = WheelPhysics(
        layout: layout,
        angle: angle,
        velocity: 4.5 + random.nextDouble() * 2,
      );
      // Press on the wheel at some point during the spin, and hold.
      wheel.advance(random.nextDouble() * 2);
      wheel.braking = true;
      wheel.advance(1.5);
      wheel.braking = false;
      spin(wheel);
      angle = wheel.angle;
      wins[wheel.selectedIndex]++;
    }
    for (var i = 0; i < 4; i++) {
      final expected = layout.sweep(i) / fullTurn;
      expect(wins[i] / spins, closeTo(expected, 0.05), reason: '$wins');
    }
  });
}
