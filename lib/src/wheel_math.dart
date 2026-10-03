import 'dart:math' as math;

const double fullTurn = 2 * math.pi;

/// Angular size of one segment for a wheel with [count] segments.
double segmentAngle(int count) => fullTurn / count;

/// Normalizes [angle] into the range [0, 2π).
double normalizeAngle(double angle) {
  final a = angle % fullTurn;
  return a < 0 ? a + fullTurn : a;
}

/// Index of the segment sitting under the pointer (at the top of the wheel)
/// when the wheel is rotated clockwise by [rotation] radians.
///
/// Segment 0 starts at the top and segments follow clockwise.
int indexAtRotation(double rotation, int count) {
  final local = normalizeAngle(-rotation);
  return (local / segmentAngle(count)).floor() % count;
}
