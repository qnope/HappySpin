import 'dart:math' as math;

import 'wheel_math.dart';

/// Simulation of a wheel with one peg on each segment boundary, slowed down
/// by friction and by a springy pointer that each peg has to push aside.
///
/// Angles are in radians, clockwise, with the pointer at the top. A peg
/// approaching the pointer bends it; once the peg slips past, the pointer
/// snaps back and wobbles like a spring. The energy spent bending the pointer
/// is lost by the wheel, so the wheel slows down a little on every peg, and
/// when it is too slow to get past one it bounces back off it.
class WheelPhysics {
  WheelPhysics({required this.pegCount, required this.angle, this.velocity = 0})
    : assert(pegCount >= 2),
      contactWidth = math.min(0.07, segmentAngle(pegCount) * 0.3) {
    final pegEnergy = pegEnergyPerTurn / pegCount;
    stiffness = 2 * pegEnergy / (contactWidth * contactWidth);
  }

  /// Friction slowing the wheel down regardless of the pegs, in rad/s².
  static const double friction = 0.6;

  /// Damping ratio of a peg pressed against the pointer, so that the wheel
  /// does not bounce off a peg as hard as it hit it.
  static const double contactDamping = 0.6;

  /// Energy taken by all the pegs of one full turn, for a wheel of unit
  /// inertia: the more pegs, the softer each of them.
  static const double pegEnergyPerTurn = 5;

  /// Natural frequency and damping ratio of the pointer spring.
  static const double pointerFrequency = 2 * math.pi * 6;
  static const double pointerDamping = 0.12;

  /// Integration step, small enough for a peg never to be skipped.
  static const double timeStep = 1 / 600;

  final int pegCount;

  /// Half-width of the zone where a peg touches the pointer.
  final double contactWidth;

  /// Spring constant of the pointer, felt by the wheel through the pegs.
  late final double stiffness;

  double angle;
  double velocity;

  /// Pointer deflection, from -1 (bent fully left) to 1 (bent fully right).
  double pointer = 0;
  double pointerVelocity = 0;

  /// Number of pegs that went past the pointer so far.
  int clicks = 0;

  // 1: a peg pushes the pointer from the left (wheel turning clockwise),
  // -1: from the right, 0: no peg touching it.
  int _contact = 0;

  // Set when a peg has just slipped past the pointer, until it leaves the
  // contact zone, so that it does not catch the pointer again.
  bool _released = false;

  /// Position of the closest peg relative to the pointer, in (-seg/2, seg/2].
  double get pegOffset {
    final seg = segmentAngle(pegCount);
    final d = normalizeAngle(angle) % seg;
    return d > seg / 2 ? d - seg : d;
  }

  /// Torque applied by the pointer on the wheel through the touching peg.
  double get _pegTorque {
    final d = pegOffset;
    // Only damp the wheel when it is pushed back off the peg.
    final bouncing = _contact * velocity < 0;
    final damping = bouncing
        ? 2 * contactDamping * math.sqrt(stiffness) * velocity
        : 0;
    if (_contact > 0) return -stiffness * (d + contactWidth) - damping;
    if (_contact < 0) return stiffness * (contactWidth - d) - damping;
    return 0;
  }

  /// Whether the wheel has stopped and the pointer has settled.
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
  }

  void _updateContact() {
    final d = pegOffset;
    if (d.abs() >= contactWidth) {
      _contact = 0;
      _released = false;
    } else if (_contact > 0 && d >= 0 || _contact < 0 && d <= 0) {
      // The peg slipped past the pointer, which snaps back.
      _contact = 0;
      _released = true;
      pointerVelocity = 0;
      clicks++;
    } else if (_contact == 0 && !_released) {
      _contact = d < 0 ? 1 : -1;
    }
  }

  /// Index of the segment under the pointer.
  int get selectedIndex => indexAtRotation(angle, pegCount);
}
