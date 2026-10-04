import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// The languages the app can be shown in.
enum AppLanguage {
  /// Follows the device, in English if it uses another language.
  device(null, null),
  french('fr', 'Français'),
  english('en', 'English'),
  spanish('es', 'Español');

  const AppLanguage(this.code, this.nativeName);

  final String? code;

  /// The language's name in that language, so that anyone can find theirs.
  final String? nativeName;

  /// The locale the app is forced to, or null to follow the device.
  Locale? get locale => code == null ? null : Locale(code!);
}

/// The languages shown with their flag, plus the device's language.
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final AppLanguage selected;
  final ValueChanged<AppLanguage> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Lined up with the cards of the wheel colors above.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          for (final language in AppLanguage.values)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: language == AppLanguage.values.last ? 0 : 8,
                ),
                child: _LanguageTile(
                  key: Key('language-${language.name}'),
                  label: language.nativeName ?? l10n.languageDevice,
                  selected: language == selected,
                  onTap: () => onSelected(language),
                  flag: switch (language) {
                    AppLanguage.device => const Icon(
                      Icons.smartphone,
                      size: 28,
                    ),
                    AppLanguage.french => const Flag(FlagPainter.france),
                    AppLanguage.english => const Flag(
                      FlagPainter.unitedKingdom,
                    ),
                    AppLanguage.spanish => const Flag(FlagPainter.spain),
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.flag,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget flag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: selected ? scheme.secondaryContainer : null,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              children: [
                SizedBox(height: 28, child: Center(child: flag)),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small flag, drawn rather than an emoji so that it looks the same on
/// every device and in the browser.
class Flag extends StatelessWidget {
  const Flag(this.painter, {super.key});

  final FlagPainter painter;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(3),
        ),
        child: CustomPaint(size: const Size(39, 26), painter: painter),
      ),
    );
  }
}

/// Draws a flag over the whole of its canvas, in a 3:2 shape.
class FlagPainter extends CustomPainter {
  const FlagPainter._(this._paint);

  final void Function(Canvas canvas, Size size) _paint;

  static const _blue = Color(0xFF002395);
  static const _red = Color(0xFFED2939);

  static const france = FlagPainter._(_france);
  static const spain = FlagPainter._(_spain);
  static const unitedKingdom = FlagPainter._(_unitedKingdom);

  static void _france(Canvas canvas, Size size) {
    final third = size.width / 3;
    for (final (i, color) in [_blue, Colors.white, _red].indexed) {
      canvas.drawRect(
        Rect.fromLTWH(third * i, 0, third + 0.5, size.height),
        Paint()..color = color,
      );
    }
  }

  static void _spain(Canvas canvas, Size size) {
    final quarter = size.height / 4;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFAA151B),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, quarter, size.width, quarter * 2),
      Paint()..color = const Color(0xFFF1BF00),
    );
  }

  static void _unitedKingdom(Canvas canvas, Size size) {
    const blue = Color(0xFF012169);
    const red = Color(0xFFC8102E);
    final w = size.width, h = size.height;
    // Drawn on the flag's own 60 × 30 grid, stretched to the canvas.
    canvas.save();
    canvas.scale(w / 60, h / 30);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 60, 30), Paint()..color = blue);
    final diagonals = Path()
      ..moveTo(0, 0)
      ..lineTo(60, 30)
      ..moveTo(60, 0)
      ..lineTo(0, 30);
    canvas.drawPath(
      diagonals,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    // The red saltire is offset, each arm on the clockwise side.
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(0, 0, 60, 30));
    final angle = math.atan2(30, 60);
    final dx = math.sin(angle), dy = math.cos(angle);
    final redStroke = Paint()
      ..color = red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final (from, to, side) in [
      (const Offset(0, 0), const Offset(30, 15), -1.0),
      (const Offset(60, 30), const Offset(30, 15), -1.0),
      (const Offset(60, 0), const Offset(30, 15), 1.0),
      (const Offset(0, 30), const Offset(30, 15), 1.0),
    ]) {
      final shift = Offset(dx, -dy * side) * (from.dx < 30 ? 1 : -1);
      canvas.drawLine(from + shift, to + shift, redStroke);
    }
    canvas.restore();
    canvas.drawRect(
      const Rect.fromLTWH(25, 0, 10, 30),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      const Rect.fromLTWH(0, 10, 60, 10),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(const Rect.fromLTWH(27, 0, 6, 30), Paint()..color = red);
    canvas.drawRect(const Rect.fromLTWH(0, 12, 60, 6), Paint()..color = red);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) => _paint(canvas, size);

  @override
  bool shouldRepaint(FlagPainter oldDelegate) => oldDelegate._paint != _paint;
}
