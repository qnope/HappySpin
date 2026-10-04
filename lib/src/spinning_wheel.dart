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
    this.weights,
    this.colors,
    this.pointerDeflection = 0,
  });

  final List<String> choices;

  /// How wide each choice's segment is, relative to the others; all the
  /// same size when null.
  final List<int>? weights;

  /// Color of each choice's segment; taken from the palette when null.
  final List<Color>? colors;
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
                  colors: colors,
                  layout: choices.isEmpty
                      ? null
                      : WheelLayout(weights ?? List.filled(choices.length, 1)),
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
                painter: _PointerPainter(
                  color: palette.pointerColor,
                  outline: Colors.white,
                ),
              ),
            ),
          ),
          // Same top padding as the wheel, so the hub sits on its center.
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Center(
              child: Container(
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
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({
    required this.choices,
    required this.colors,
    required this.layout,
    required this.palette,
    required this.rimColor,
    required this.emptyColor,
  });

  final List<String> choices;
  final List<Color>? colors;
  final WheelLayout? layout;
  final WheelPalette palette;
  final Color rimColor;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final layout = this.layout;
    if (layout == null) {
      canvas.drawCircle(center, radius, Paint()..color = emptyColor);
    } else {
      for (var i = 0; i < choices.length; i++) {
        final start = -math.pi / 2 + layout.start(i);
        final seg = layout.sweep(i);
        canvas.drawArc(
          rect,
          start,
          seg,
          true,
          Paint()
            ..color = colors?[i] ?? palette.segmentColor(i, choices.length),
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

    if (layout != null && choices.length > 1) {
      _paintPegs(canvas, center, radius, layout);
    }
  }

  /// One peg in the middle of each segment, near the rim.
  void _paintPegs(
    Canvas canvas,
    Offset center,
    double radius,
    WheelLayout layout,
  ) {
    final pegRadius = math.max(4.0, radius * 0.032);
    final distance = radius - 5 - pegRadius * 1.5;
    final fill = Paint()..color = const Color(0xFFF5F5F5);
    final edge = Paint()
      ..color = Colors.black38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < choices.length; i++) {
      final angle = -math.pi / 2 + layout.middle(i);
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
    final fontSize = math.min(18.0, math.max(9.0, radius * seg * 0.35));
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
      old.colors != colors ||
      old.layout != layout ||
      old.palette != palette ||
      old.rimColor != rimColor ||
      old.emptyColor != emptyColor;
}

class _PointerPainter extends CustomPainter {
  _PointerPainter({required this.color, required this.outline});

  final Color color;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    // An arrowhead with a rounded top, its sides curving in to a sharp tip.
    final w = size.width;
    final pivot = Offset(w / 2, w / 2);
    final tip = Offset(w / 2, size.height - 1);
    const top = 3.0;
    const corner = 7.0;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..quadraticBezierTo(2, size.height * 0.55, 2, top + corner)
      ..quadraticBezierTo(2, top, 2 + corner, top)
      ..lineTo(w - 2 - corner, top)
      ..quadraticBezierTo(w - 2, top, w - 2, top + corner)
      ..quadraticBezierTo(w - 2, size.height * 0.55, tip.dx, tip.dy)
      ..close();

    canvas.drawShadow(path, Colors.black, 4, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.35)!,
            color,
            Color.lerp(color, Colors.black, 0.3)!,
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    // A small polished screw holding the pointer.
    final screw = w * 0.15;
    canvas.drawCircle(
      pivot,
      screw,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [Colors.white, outline, Color.lerp(outline, color, 0.5)!],
          stops: const [0, 0.6, 1],
        ).createShader(Rect.fromCircle(center: pivot, radius: screw)),
    );
    canvas.drawCircle(
      pivot,
      screw,
      Paint()
        ..color = Color.lerp(color, Colors.black, 0.4)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_PointerPainter old) =>
      old.color != color || old.outline != outline;
}
