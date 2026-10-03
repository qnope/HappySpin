import 'package:flutter_test/flutter_test.dart';
import 'package:happyspin/src/wheel_math.dart';

void main() {
  test('segment 0 is under the pointer at rest', () {
    expect(indexAtRotation(0.0001, 4), 3);
    expect(indexAtRotation(-0.0001, 4), 0);
  });

  test('segments follow clockwise', () {
    final seg = segmentAngle(4);
    expect(indexAtRotation(-1.5 * seg, 4), 1);
    expect(indexAtRotation(1.5 * seg, 4), 2);
  });
}
