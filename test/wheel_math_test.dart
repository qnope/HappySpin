import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:happyspin/src/wheel_math.dart';

void main() {
  test('segment 0 is under the pointer at rest', () {
    expect(indexAtRotation(0.0001, 4), 3);
    expect(indexAtRotation(-0.0001, 4), 0);
  });

  test('targetRotation lands on every target', () {
    final random = math.Random(42);
    for (var count = 2; count <= 12; count++) {
      for (var target = 0; target < count; target++) {
        final current = (random.nextDouble() - 0.5) * 40;
        final end = targetRotation(
          current: current,
          target: target,
          count: count,
          offset: (random.nextDouble() - 0.5) * 0.8,
        );
        expect(
          indexAtRotation(end, count),
          target,
          reason: 'count=$count target=$target',
        );
        expect(end - current, greaterThanOrEqualTo(5 * fullTurn));
        expect(end - current, lessThan(6 * fullTurn));
      }
    }
  });
}
