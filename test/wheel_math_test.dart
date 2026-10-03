import 'package:flutter_test/flutter_test.dart';
import 'package:happyspin/src/wheel_math.dart';

void main() {
  test('segment 0 is under the pointer at rest', () {
    final layout = WheelLayout.even(4);
    expect(layout.indexAtRotation(0.0001), 3);
    expect(layout.indexAtRotation(-0.0001), 0);
  });

  test('segments follow clockwise', () {
    final layout = WheelLayout.even(4);
    final seg = segmentAngle(4);
    expect(layout.indexAtRotation(-1.5 * seg), 1);
    expect(layout.indexAtRotation(1.5 * seg), 2);
  });

  test('segments are as wide as their weight', () {
    final layout = WheelLayout([1, 2, 1]);
    expect(layout.sweep(0), closeTo(fullTurn / 4, 1e-9));
    expect(layout.sweep(1), closeTo(fullTurn / 2, 1e-9));
    expect(layout.start(2), closeTo(fullTurn * 3 / 4, 1e-9));
    expect(layout.middle(1), closeTo(fullTurn / 2, 1e-9));
    expect(layout.minMiddleGap, closeTo(fullTurn / 4, 1e-9));
  });

  test('finds the segment under the pointer on a weighted wheel', () {
    final layout = WheelLayout([1, 2, 1]);
    expect(layout.indexAt(0.1), 0);
    expect(layout.indexAt(fullTurn / 4 + 0.01), 1);
    expect(layout.indexAt(fullTurn * 0.74), 1);
    expect(layout.indexAt(fullTurn * 0.76), 2);
    expect(layout.indexAtRotation(-fullTurn * 0.6), 1);
    expect(layout.indexAtRotation(0.1), 2);
  });
}
