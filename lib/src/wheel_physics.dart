import 'dart:math' as math;

import 'wheel_math.dart';

/// Simulation of a wheel with one peg in the middle of each segment, slowed down
/// by friction and by a springy pointer that each peg has to push aside.
///
/// Angles are in radians, clockwise, with the pointer at the top. A peg
/// approaching the pointer bends it; once the peg slips past, the pointer
/// snaps back and wobbles like a spring. The energy spent bending the pointer
/// is lost by the wheel, so the wheel slows down a little on every peg, and
/// when it is too slow to get past one it bounces back off it.
class WheelPhysics {
  WheelPhysics({required this.layout, required this.angle, this.velocity = 0})
    : assert(layout.count >= 2),
      contactWidth = math.min(0.07, layout.minMiddleGap * 0.3) {
    // Each peg takes as much energy as its segment is wide, so that the
    // chance of stopping on a segment matches its size on the wheel.
    stiffnesses = [
      for (var i = 0; i < layout.count; i++)
        2 *
            pegEnergyPerTurn *
            layout.sweep(i) /
            fullTurn /
            (contactWidth * contactWidth),
    ];
  }

  /// Friction slowing the wheel down regardless of the pegs, in rad/s².
  static const double friction = 0.4;

  /// Extra friction while a finger presses on the wheel, in rad/s².
  static const double brakeFriction = 6;

  /// Damping ratio of a peg pressed against the pointer, so that the wheel
  /// does not bounce off a peg as hard as it hit it.
  static const double contactDamping = 0.6;

  /// Share of the pointer spring that pushes a peg away once past it.
  static const double releasePush = 0.3;

  /// Energy taken by all the pegs of one full turn, for a wheel of unit
  /// inertia: the more pegs, the softer each of them.
  static const double pegEnergyPerTurn = 3.5;

  /// Natural frequency and damping ratio of the pointer spring.
  static const double pointerFrequency = 2 * math.pi * 9;
  static const double pointerDamping = 0.15;

  /// Integration step, small enough for a peg never to be skipped.
  static const double timeStep = 1 / 600;

  /// The segments of the wheel, with one peg in the middle of each.
  final WheelLayout layout;

  int get pegCount => layout.count;

  /// Half-width of the zone where a peg touches the pointer.
  final double contactWidth;

  /// Spring constant of the pointer felt by the wheel through each peg.
  late final List<double> stiffnesses;

  double angle;
  double velocity;

  /// Whether a finger presses on the wheel, slowing it down much faster.
  bool braking = false;

  double get _friction => braking ? friction + brakeFriction : friction;

  /// Pointer deflection, from -1 (bent fully left) to 1 (bent fully right).
  double pointer = 0;
  double pointerVelocity = 0;

  /// Number of pegs that went past the pointer so far.
  int clicks = 0;

  /// Number of times a peg hit the pointer hard enough to bend it, but was
  /// too slow to get past it and started falling back.
  int knocks = 0;

  /// How far a peg must bend the pointer for its knock to be heard.
  static const double knockBend = 0.3;

  // Furthest the touching peg has bent the pointer so far, and whether it
  // has knocked already.
  double _bend = 0;
  bool _knocked = false;

  // 1: a peg pushes the pointer from the left (wheel turning clockwise),
  // -1: from the right, 0: no peg touching it.
  int _contact = 0;

  // Direction in which a peg has just slipped past the pointer (1 or -1),
  // until it leaves the contact zone, so that it does not catch the pointer
  // again; 0 otherwise.
  int _released = 0;

  // Closest peg to the pointer, and its position relative to the pointer,
  // as of the last time the wheel moved.
  int _peg = 0;
  double _pegOffset = 0;
  double? _pegAngle;

  void _findClosestPeg() {
    if (_pegAngle == angle) return;
    _pegAngle = angle;
    // The closest peg is the one of the segment under the pointer, or of a
    // segment next to it: no need to go through all the pegs, which this
    // does twice per step, hundreds of times a second.
    final under = layout.indexAtRotation(angle);
    final count = layout.count;
    var best = double.infinity;
    for (var k = -1; k <= 1; k++) {
      final i = (under + k + count) % count;
      var d = normalizeAngle(angle + layout.middle(i));
      if (d > math.pi) d -= fullTurn;
      if (d.abs() < best.abs()) {
        best = d;
        _peg = i;
      }
    }
    _pegOffset = best;
  }

  /// Position of the closest peg relative to the pointer, in (-π, π].
  double get pegOffset {
    _findClosestPeg();
    return _pegOffset;
  }

  /// Torque applied by the pointer on the wheel through the touching peg.
  double get _pegTorque {
    final d = pegOffset;
    final stiffness = stiffnesses[_peg];
    // Only damp the wheel when it is pushed back off the peg.
    final bouncing = _contact * velocity < 0;
    final damping = bouncing
        ? 2 * contactDamping * math.sqrt(stiffness) * velocity
        : 0;
    if (_contact > 0) return -stiffness * (d + contactWidth) - damping;
    if (_contact < 0) return stiffness * (contactWidth - d) - damping;
    // The pointer snapping back nudges the peg it just let go of out of the
    // way, so that the wheel never stops with a peg under the pointer.
    if (_released != 0) {
      return _released * releasePush * stiffness * (contactWidth - d.abs());
    }
    return 0;
  }

  /// Whether the wheel has stopped and the pointer has settled. A finger
  /// holding the wheel on a peg does not count: the peg has to settle once
  /// the finger lets go.
  bool get isAtRest =>
      velocity == 0 &&
      _pegTorque.abs() <= friction &&
      pointerVelocity.abs() < 0.3 &&
      (pointer - _pointerContact).abs() < 0.03;

  /// Deflection forced on the pointer by the touching peg, if any.
  double get _pointerContact {
    final d = pegOffset;
    if (_contact > 0) return (d + contactWidth) / contactWidth;
    if (_contact < 0) return (d - contactWidth) / contactWidth;
    return 0;
  }

  /// Advances the simulation by [seconds].
  void advance(double seconds) {
    final steps = (seconds / timeStep).round();
    for (var i = 0; i < steps; i++) {
      _step(timeStep);
    }
  }

  void _step(double dt) {
    _updateContact();

    final torque = _pegTorque;
    final friction = _friction;
    if (velocity == 0 && torque.abs() <= friction) {
      // Static friction holds the wheel.
    } else {
      final direction = velocity != 0 ? velocity.sign : torque.sign;
      final next = velocity + (torque - direction * friction) * dt;
      // Friction stops the wheel but never makes it turn backwards.
      velocity = torque.abs() <= friction && next.sign != direction ? 0 : next;
      angle += velocity * dt;
    }

    pointerVelocity +=
        (-pointerFrequency * pointerFrequency * pointer -
            2 * pointerDamping * pointerFrequency * pointerVelocity) *
        dt;
    pointer += pointerVelocity * dt;
    final forced = _pointerContact;
    if ((_contact > 0 && pointer < forced) ||
        (_contact < 0 && pointer > forced)) {
      pointer = forced;
      pointerVelocity = velocity / contactWidth;
    }
    if (_contact != 0) {
      _bend = math.max(_bend, pointer.abs());
      // The wheel stopped going forward against the peg: it knocked
      // against the pointer and falls back.
      if (!_knocked && _bend >= knockBend && velocity * _contact <= 0) {
        _knocked = true;
        knocks++;
      }
    }
  }

  void _updateContact() {
    final d = pegOffset;
    if (d.abs() >= contactWidth) {
      _contact = 0;
      _released = 0;
      _bend = 0;
      _knocked = false;
    } else if (_contact > 0 && d >= 0 || _contact < 0 && d <= 0) {
      // The peg slipped past the pointer, which snaps back.
      _released = _contact;
      _contact = 0;
      pointerVelocity = 0;
      clicks++;
      _bend = 0;
      _knocked = false;
    } else if (_contact == 0 && _released == 0) {
      _contact = d < 0 ? 1 : -1;
    }
  }

  /// Index of the segment under the pointer.
  int get selectedIndex => layout.indexAtRotation(angle);
}
