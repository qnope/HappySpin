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
          pegCount: count,
          angle: random.nextDouble() * fullTurn,
          velocity: 6 + random.nextDouble() * 3,
        );
        final start = wheel.angle;
        final time = spin(wheel);
        final turns = (wheel.angle - start) / fullTurn;
        expect(time, inInclusiveRange(3, 10), reason: 'count=$count');
        expect(turns, inInclusiveRange(1, 5), reason: 'count=$count');
      }
    }
  });

  test('every peg going past the pointer is a click', () {
    final wheel = WheelPhysics(pegCount: 8, angle: 0.3, velocity: 8);
    final start = wheel.angle;
    spin(wheel);
    final seg = segmentAngle(8);
    final crossed = (wheel.angle / seg).floor() - (start / seg).floor();
    expect(wheel.clicks, crossed);
  });

  test('the wheel slows down on each peg', () {
    final wheel = WheelPhysics(pegCount: 4, angle: 0.4, velocity: 7);
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
    final wheel = WheelPhysics(pegCount: 4, angle: 0.4, velocity: 7);
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
        pegCount: count,
        angle: random.nextDouble() * fullTurn,
        velocity: 6 + random.nextDouble() * 3,
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
        pegCount: 6,
        angle: 0,
        velocity: 6 + random.nextDouble() * 3,
      );
      spin(wheel);
      wins[wheel.selectedIndex]++;
    }
    for (final w in wins) {
      expect(w, greaterThan(25));
    }
  });
}
