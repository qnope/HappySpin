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

/// Final rotation that lands segment [target] under the pointer, starting
/// from [current] and spinning clockwise at least [minTurns] full turns.
///
/// [offset] in (-0.5, 0.5) shifts the landing point inside the segment so
/// the wheel does not always stop dead center.
double targetRotation({
  required double current,
  required int target,
  required int count,
  int minTurns = 5,
  double offset = 0,
}) {
  final seg = segmentAngle(count);
  final wanted = normalizeAngle(-(target + 0.5 + offset) * seg);
  final delta = normalizeAngle(wanted - normalizeAngle(current));
  return current + minTurns * fullTurn + delta;
}
