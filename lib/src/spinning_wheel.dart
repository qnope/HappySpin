import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'wheel_math.dart';

/// A wheel split into one segment per choice, rotated by [rotation] radians,
/// with a peg in the middle of each segment and a springy pointer at the top.
class SpinningWheel extends StatelessWidget {
  const SpinningWheel({
    super.key,
    required this.choices,
    required this.rotation,
    this.pointerDeflection = 0,
  });

  final List<String> choices;
  final double rotation;

  /// How much the pegs bend the pointer, from -1 (left) to 1 (right).
  final double pointerDeflection;

  /// Angle of the pointer when fully bent by a peg.
  static const double maxPointerAngle = 0.5;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = WheelTheme.of(context);
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Transform.rotate(
              angle: rotation,
              child: CustomPaint(
                size: Size.infinite,
                painter: _WheelPainter(
                  choices: choices,
                  palette: palette,
                  rimColor: scheme.surface,
                  emptyColor: scheme.surfaceContainerHighest,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Transform.rotate(
              // The pointer pivots around its base: a positive deflection
              // swings its tip to the right.
              angle: -pointerDeflection.clamp(-1.5, 1.5) * maxPointerAngle,
              alignment: const Alignment(0, -0.27),
              child: CustomPaint(
                size: const Size(32, 44),
                painter: _PointerPainter(scheme.onSurface),
              ),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.surface,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(blurRadius: 6, color: Colors.black26),
              ],
            ),
            child: Icon(Icons.auto_awesome, color: scheme.primary),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({
    required this.choices,
    required this.palette,
    required this.rimColor,
    required this.emptyColor,
  });

  final List<String> choices;
  final WheelPalette palette;
  final Color rimColor;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (choices.isEmpty) {
      canvas.drawCircle(center, radius, Paint()..color = emptyColor);
    } else {
      final seg = segmentAngle(choices.length);
      for (var i = 0; i < choices.length; i++) {
        final start = -math.pi / 2 + i * seg;
        canvas.drawArc(
          rect,
          start,
          seg,
          true,
          Paint()..color = palette.segmentColor(i, choices.length),
        );
        if (choices.length > 1) {
          canvas.drawArc(
            rect,
            start,
            seg,
            true,
            Paint()
              ..color = rimColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
        _paintLabel(canvas, center, radius, start + seg / 2, seg, choices[i]);
      }
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = rimColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    if (choices.length > 1) _paintPegs(canvas, center, radius);
  }

  /// One peg in the middle of each segment, near the rim.
  void _paintPegs(Canvas canvas, Offset center, double radius) {
    final seg = segmentAngle(choices.length);
    final pegRadius = math.max(4.0, radius * 0.032);
    final distance = radius - 5 - pegRadius * 1.5;
    final fill = Paint()..color = const Color(0xFFF5F5F5);
    final edge = Paint()
      ..color = Colors.black38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < choices.length; i++) {
      final angle = -math.pi / 2 + (i + 0.5) * seg;
      final peg = center + Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.drawCircle(
        peg + const Offset(0, 1),
        pegRadius,
        Paint()..color = Colors.black26,
      );
      canvas.drawCircle(peg, pegRadius, fill);
      canvas.drawCircle(peg, pegRadius, edge);
    }
  }

  void _paintLabel(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    double seg,
    String text,
  ) {
    final maxWidth = radius * 0.56;
    final fontSize = math.min(18.0, math.max(10.0, radius * seg * 0.35));
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: palette.labelColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          shadows: palette.labelColor == Colors.white
              ? const [Shadow(blurRadius: 3, color: Colors.black45)]
              : null,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    painter.paint(
      canvas,
      // Stop short of the peg at the rim.
      Offset(radius * 0.84 - painter.width, -painter.height / 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.choices != choices ||
      old.palette != palette ||
      old.rimColor != rimColor ||
      old.emptyColor != emptyColor;
}

class _PointerPainter extends CustomPainter {
  _PointerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // A rounded flap hanging from a pivot, ending in a sharp tip.
    final w = size.width;
    final pivot = Offset(w / 2, w / 2);
    final path = Path()
      ..moveTo(w / 2, size.height)
      ..lineTo(0, pivot.dy)
      ..arcToPoint(Offset(w, pivot.dy), radius: Radius.circular(w / 2))
      ..lineTo(w / 2, size.height)
      ..close();
    canvas.drawShadow(path, Colors.black, 3, false);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(pivot, w * 0.16, Paint()..color = Colors.white70);
  }

  @override
  bool shouldRepaint(_PointerPainter old) => old.color != color;
}
