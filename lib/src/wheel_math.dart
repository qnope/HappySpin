import 'dart:math' as math;

const double fullTurn = 2 * math.pi;

/// Angular size of one segment for a wheel with [count] equal segments.
double segmentAngle(int count) => fullTurn / count;

/// Normalizes [angle] into the range [0, 2π).
double normalizeAngle(double angle) {
  final a = angle % fullTurn;
  return a < 0 ? a + fullTurn : a;
}

/// How a wheel is split into segments, each one as wide as its weight.
///
/// Angles are in radians, clockwise, in the wheel's own frame: segment 0
/// starts at the top and segments follow clockwise.
class WheelLayout {
  WheelLayout(List<num> weights)
    : assert(weights.isNotEmpty),
      assert(weights.every((w) => w > 0)),
      _bounds = _boundsOf(weights);

  /// A wheel with [count] segments of the same size.
  WheelLayout.even(int count) : this(List.filled(count, 1));

  static List<double> _boundsOf(List<num> weights) {
    final total = weights.fold<num>(0, (sum, w) => sum + w);
    final bounds = <double>[0];
    var sum = 0.0;
    for (final w in weights) {
      sum += w;
      bounds.add(fullTurn * sum / total);
    }
    bounds[weights.length] = fullTurn;
    return bounds;
  }

  // Where each segment starts, plus a full turn at the end.
  final List<double> _bounds;

  int get count => _bounds.length - 1;

  double start(int index) => _bounds[index];

  double sweep(int index) => _bounds[index + 1] - _bounds[index];

  double middle(int index) => (_bounds[index] + _bounds[index + 1]) / 2;

  /// Smallest angle between the middles of two neighbouring segments.
  double get minMiddleGap {
    var gap = fullTurn;
    for (var i = 0; i < count; i++) {
      gap = math.min(gap, (sweep(i) + sweep((i + 1) % count)) / 2);
    }
    return gap;
  }

  @override
  bool operator ==(Object other) =>
      other is WheelLayout &&
      other._bounds.length == _bounds.length &&
      Iterable.generate(_bounds.length)
          .every((i) => other._bounds[i] == _bounds[i]);

  @override
  int get hashCode => Object.hashAll(_bounds);

  /// Index of the segment containing [angle], in the wheel's frame.
  int indexAt(double angle) {
    final a = normalizeAngle(angle);
    var low = 0;
    var high = count - 1;
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (_bounds[mid] <= a) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  /// Index of the segment sitting under the pointer (at the top of the wheel)
  /// when the wheel is rotated clockwise by [rotation] radians.
  int indexAtRotation(double rotation) => indexAt(-rotation);
}
