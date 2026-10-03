import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A set of colors for the wheel, which also tints the rest of the app.
class WheelPalette {
  const WheelPalette({
    required this.id,
    required this.name,
    required this.seed,
    required this.colors,
    required this.pointerColor,
    this.labelColor = Colors.white,
  });

  /// Stable identifier, saved on the device.
  final String id;
  final String name;

  /// Color the app's Material color scheme is derived from.
  final Color seed;
  final List<Color> colors;

  /// Color of the pointer at the top of the wheel.
  final Color pointerColor;

  /// Color of the choice names written on the wheel.
  final Color labelColor;

  /// Color of segment [index] on a wheel of [count] segments.
  Color segmentColor(int index, int count) {
    // Avoid two identical neighbours where the wheel wraps around.
    if (count > 1 && index == count - 1 && count % colors.length == 1) {
      return colors[(index + 1) % colors.length];
    }
    return colors[index % colors.length];
  }

  static const festive = WheelPalette(
    id: 'festive',
    pointerColor: Color(0xFFD7263D),
    name: 'Festif',
    seed: Color(0xFFFF7A59),
    colors: [
      Color(0xFFFF7A59),
      Color(0xFFFFC145),
      Color(0xFF5BC0BE),
      Color(0xFF6C63FF),
      Color(0xFFEF476F),
      Color(0xFF06D6A0),
      Color(0xFF118AB2),
      Color(0xFFF78C6B),
    ],
  );

  static const ocean = WheelPalette(
    id: 'ocean',
    pointerColor: Color(0xFFF4A261),
    name: 'Océan',
    seed: Color(0xFF0077B6),
    colors: [
      Color(0xFF03045E),
      Color(0xFF0077B6),
      Color(0xFF00B4D8),
      Color(0xFF2A9D8F),
      Color(0xFF023E8A),
      Color(0xFF0096C7),
      Color(0xFF48CAE4),
      Color(0xFF264653),
    ],
  );

  static const forest = WheelPalette(
    id: 'forest',
    pointerColor: Color(0xFFE9B949),
    name: 'Forêt',
    seed: Color(0xFF2D6A4F),
    colors: [
      Color(0xFF2D6A4F),
      Color(0xFFBC6C25),
      Color(0xFF52B788),
      Color(0xFF606C38),
      Color(0xFF1B4332),
      Color(0xFFDDA15E),
      Color(0xFF40916C),
      Color(0xFF7F5539),
    ],
  );

  static const candy = WheelPalette(
    id: 'candy',
    pointerColor: Color(0xFF8E4FB0),
    name: 'Bonbon',
    seed: Color(0xFFE07A9B),
    labelColor: Color(0xFF3D2C3E),
    colors: [
      Color(0xFFFFADAD),
      Color(0xFFFFD6A5),
      Color(0xFFFDFFB6),
      Color(0xFFCAFFBF),
      Color(0xFF9BF6FF),
      Color(0xFFA0C4FF),
      Color(0xFFBDB2FF),
      Color(0xFFFFC6FF),
    ],
  );

  static const all = [festive, ocean, forest, candy];

  static WheelPalette byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => festive);
}

/// The look the user picked: light or dark, and a wheel palette.
class AppTheme {
  const AppTheme({
    this.mode = ThemeMode.system,
    this.palette = WheelPalette.festive,
  });

  final ThemeMode mode;
  final WheelPalette palette;

  AppTheme copyWith({ThemeMode? mode, WheelPalette? palette}) =>
      AppTheme(mode: mode ?? this.mode, palette: palette ?? this.palette);

  ThemeData data(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.seed,
      brightness: brightness,
    ),
    useMaterial3: true,
    extensions: [WheelTheme(palette)],
  );

  String encode() => jsonEncode({'mode': mode.name, 'palette': palette.id});

  factory AppTheme.decode(String source) {
    final json = jsonDecode(source) as Map<String, Object?>;
    return AppTheme(
      mode: ThemeMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => ThemeMode.system,
      ),
      palette: WheelPalette.byId(json['palette'] as String?),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppTheme && other.mode == mode && other.palette == palette;

  @override
  int get hashCode => Object.hash(mode, palette);
}

/// Makes the wheel palette available from the [Theme].
class WheelTheme extends ThemeExtension<WheelTheme> {
  const WheelTheme(this.palette);

  final WheelPalette palette;

  /// The palette of the enclosing theme, or the default one.
  static WheelPalette of(BuildContext context) =>
      Theme.of(context).extension<WheelTheme>()?.palette ??
      WheelPalette.festive;

  @override
  WheelTheme copyWith({WheelPalette? palette}) =>
      WheelTheme(palette ?? this.palette);

  @override
  WheelTheme lerp(WheelTheme? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

/// Where the chosen theme is kept between launches.
abstract class AppThemeStore {
  Future<AppTheme?> load();
  Future<void> save(AppTheme theme);
}

/// Keeps the theme on the device (local storage on the web).
class PreferencesAppThemeStore implements AppThemeStore {
  static const _key = 'appTheme';

  @override
  Future<AppTheme?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final source = prefs.getString(_key);
    if (source == null) return null;
    try {
      return AppTheme.decode(source);
    } on Object {
      // Unreadable data should not keep the app from starting.
      return null;
    }
  }

  @override
  Future<void> save(AppTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, theme.encode());
  }
}

/// Keeps the theme in memory only; for tests.
class MemoryAppThemeStore implements AppThemeStore {
  MemoryAppThemeStore([this.saved]);

  AppTheme? saved;

  @override
  Future<AppTheme?> load() async => saved;

  @override
  Future<void> save(AppTheme theme) async => saved = theme;
}

/// Holds the current theme, loads it on start and saves every change.
class AppThemeController extends ChangeNotifier {
  AppThemeController({AppThemeStore? store})
    : _store = store ?? PreferencesAppThemeStore();

  final AppThemeStore _store;
  AppTheme _theme = const AppTheme();

  AppTheme get theme => _theme;

  Future<void> load() async {
    AppTheme? saved;
    try {
      saved = await _store.load();
    } on Object {
      // Keep the default theme if storage is unavailable.
    }
    if (saved == null || saved == _theme) return;
    _theme = saved;
    notifyListeners();
  }

  void update(AppTheme theme) {
    if (theme == _theme) return;
    _theme = theme;
    notifyListeners();
    _store.save(theme).catchError((Object _) {});
  }
}

/// Lets the user pick light or dark and a wheel palette.
class ThemeSheet extends StatelessWidget {
  const ThemeSheet({super.key, required this.controller});

  final AppThemeController controller;

  static Future<void> show(
    BuildContext context,
    AppThemeController controller,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => ThemeSheet(controller: controller),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final theme = controller.theme;
        final text = Theme.of(context).textTheme;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Thème', style: text.titleLarge),
                const SizedBox(height: 16),
                Text('Apparence', style: text.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  key: const Key('themeMode'),
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto),
                      label: Text('Auto'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode),
                      label: Text('Clair'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode),
                      label: Text('Sombre'),
                    ),
                  ],
                  selected: {theme.mode},
                  onSelectionChanged: (modes) =>
                      controller.update(theme.copyWith(mode: modes.single)),
                ),
                const SizedBox(height: 24),
                Text('Couleurs de la roue', style: text.titleSmall),
                const SizedBox(height: 8),
                for (final palette in WheelPalette.all)
                  _PaletteTile(
                    palette: palette,
                    selected: palette == theme.palette,
                    onTap: () =>
                        controller.update(theme.copyWith(palette: palette)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final WheelPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: Key('palette-${palette.id}'),
      elevation: 0,
      color: selected ? scheme.secondaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(palette.name),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              for (final color in palette.colors)
                Expanded(
                  child: Container(
                    height: 16,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
        ),
        trailing: Icon(
          selected ? Icons.check_circle : Icons.circle_outlined,
          color: selected ? scheme.primary : scheme.outline,
        ),
      ),
    );
  }
}
