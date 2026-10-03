import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'wheel_math.dart';

const List<Color> wheelPalette = [
  Color(0xFFFF7A59),
  Color(0xFFFFC145),
  Color(0xFF5BC0BE),
  Color(0xFF6C63FF),
  Color(0xFFEF476F),
  Color(0xFF06D6A0),
  Color(0xFF118AB2),
  Color(0xFFF78C6B),
];

/// Color of segment [index] on a wheel of [count] segments.
Color wheelColor(int index, int count) {
  // Avoid two identical neighbours where the wheel wraps around.
  if (count > 1 && index == count - 1 && count % wheelPalette.length == 1) {
    return wheelPalette[(index + 1) % wheelPalette.length];
  }
  return wheelPalette[index % wheelPalette.length];
}

/// A wheel split into one segment per choice, rotated by [rotation] radians,
/// with a fixed pointer at the top.
class SpinningWheel extends StatelessWidget {
  const SpinningWheel({
    super.key,
    required this.choices,
    required this.rotation,
  });

  final List<String> choices;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                  rimColor: scheme.surface,
                  emptyColor: scheme.surfaceContainerHighest,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: CustomPaint(
              size: const Size(32, 36),
              painter: _PointerPainter(scheme.onSurface),
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
    required this.rimColor,
    required this.emptyColor,
  });

  final List<String> choices;
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
          Paint()..color = wheelColor(i, choices.length),
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
  }

  void _paintLabel(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    double seg,
    String text,
  ) {
    final maxWidth = radius * 0.62;
    final fontSize = math.min(18.0, math.max(10.0, radius * seg * 0.35));
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          shadows: const [Shadow(blurRadius: 3, color: Colors.black45)],
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
      Offset(radius * 0.92 - painter.width, -painter.height / 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.choices != choices ||
      old.rimColor != rimColor ||
      old.emptyColor != emptyColor;
}

class _PointerPainter extends CustomPainter {
  _PointerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawShadow(path, Colors.black, 3, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PointerPainter old) => old.color != color;
}
