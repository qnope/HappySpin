import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import 'language_picker.dart';

/// A set of colors for the wheel, which also tints the rest of the app.
class WheelPalette {
  const WheelPalette({
    required this.id,
    required this.seed,
    required this.colors,
    required this.pointerColor,
    this.labelColor = Colors.white,
  });

  /// Stable identifier, saved on the device.
  final String id;

  /// The palette's name, in the user's language.
  String name(AppLocalizations l10n) => switch (id) {
    'ocean' => l10n.paletteOcean,
    'forest' => l10n.paletteForest,
    'candy' => l10n.paletteCandy,
    _ => l10n.paletteFestive,
  };

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

/// The settings the user picked: light or dark, a wheel palette, whether
/// choices can be weighted, whether the wheel makes sounds, and whether the
/// choices it picks come out of it, and the language of the app.
class AppTheme {
  const AppTheme({
    this.mode = ThemeMode.system,
    this.palette = WheelPalette.festive,
    this.weightedChoices = false,
    this.sounds = true,
    this.elimination = false,
    this.confirmElimination = false,
    this.language = AppLanguage.device,
  });

  final ThemeMode mode;
  final WheelPalette palette;

  /// Whether each choice can be given a weight. When off, every choice
  /// counts the same, but the weights already set are kept.
  final bool weightedChoices;

  /// Whether the wheel ticks on each peg, chimes when it stops, and makes
  /// the device vibrate along.
  final bool sounds;

  /// Whether the choice the wheel picks comes out of it for the next spins,
  /// until it is put back.
  final bool elimination;

  /// Whether, in elimination mode, the user is asked before the picked
  /// choice comes out, instead of it coming out on its own.
  final bool confirmElimination;

  /// The language of the app: the device's, or one the user picked.
  final AppLanguage language;

  AppTheme copyWith({
    ThemeMode? mode,
    WheelPalette? palette,
    bool? weightedChoices,
    bool? sounds,
    bool? elimination,
    bool? confirmElimination,
    AppLanguage? language,
  }) => AppTheme(
    mode: mode ?? this.mode,
    palette: palette ?? this.palette,
    weightedChoices: weightedChoices ?? this.weightedChoices,
    sounds: sounds ?? this.sounds,
    elimination: elimination ?? this.elimination,
    confirmElimination: confirmElimination ?? this.confirmElimination,
    language: language ?? this.language,
  );

  ThemeData data(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.seed,
      brightness: brightness,
    ),
    useMaterial3: true,
    extensions: [WheelTheme(palette)],
  );

  String encode() => jsonEncode({
    'mode': mode.name,
    'palette': palette.id,
    'weightedChoices': weightedChoices,
    'sounds': sounds,
    'elimination': elimination,
    'confirmElimination': confirmElimination,
    'language': language.name,
  });

  factory AppTheme.decode(String source) {
    final json = jsonDecode(source) as Map<String, Object?>;
    return AppTheme(
      mode: ThemeMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => ThemeMode.system,
      ),
      palette: WheelPalette.byId(json['palette'] as String?),
      weightedChoices: json['weightedChoices'] == true,
      // On unless turned off, also for settings saved before sounds existed.
      sounds: json['sounds'] != false,
      elimination: json['elimination'] == true,
      confirmElimination: json['confirmElimination'] == true,
      language: AppLanguage.values.firstWhere(
        (l) => l.name == json['language'],
        orElse: () => AppLanguage.device,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppTheme &&
      other.mode == mode &&
      other.palette == palette &&
      other.weightedChoices == weightedChoices &&
      other.sounds == sounds &&
      other.elimination == elimination &&
      other.confirmElimination == confirmElimination &&
      other.language == language;

  @override
  int get hashCode => Object.hash(
    mode,
    palette,
    weightedChoices,
    sounds,
    elimination,
    confirmElimination,
    language,
  );
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

/// The settings: light or dark, a wheel palette, weighted choices,
/// elimination mode, sounds and language.
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
        final l10n = AppLocalizations.of(context);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.settings, style: text.titleLarge),
                const SizedBox(height: 16),
                Text(l10n.appearance, style: text.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  key: const Key('themeMode'),
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto),
                      label: Text(l10n.themeAuto),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode),
                      label: Text(l10n.themeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode),
                      label: Text(l10n.themeDark),
                    ),
                  ],
                  selected: {theme.mode},
                  onSelectionChanged: (modes) =>
                      controller.update(theme.copyWith(mode: modes.single)),
                ),
                const SizedBox(height: 24),
                Text(l10n.wheelColors, style: text.titleSmall),
                const SizedBox(height: 8),
                for (final palette in WheelPalette.all)
                  _PaletteTile(
                    palette: palette,
                    selected: palette == theme.palette,
                    onTap: () =>
                        controller.update(theme.copyWith(palette: palette)),
                  ),
                const SizedBox(height: 24),
                Text(l10n.choicesSection, style: text.titleSmall),
                SwitchListTile(
                  key: const Key('weightedChoices'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.weightedChoices),
                  subtitle: Text(l10n.weightedChoicesHint),
                  value: theme.weightedChoices,
                  onChanged: (on) =>
                      controller.update(theme.copyWith(weightedChoices: on)),
                ),
                SwitchListTile(
                  key: const Key('elimination'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.elimination),
                  subtitle: Text(l10n.eliminationHint),
                  value: theme.elimination,
                  onChanged: (on) =>
                      controller.update(theme.copyWith(elimination: on)),
                ),
                if (theme.elimination)
                  SwitchListTile(
                    key: const Key('confirmElimination'),
                    contentPadding: const EdgeInsets.only(left: 16),
                    title: Text(l10n.confirmElimination),
                    subtitle: Text(l10n.confirmEliminationHint),
                    value: theme.confirmElimination,
                    onChanged: (on) => controller.update(
                      theme.copyWith(confirmElimination: on),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(l10n.soundsSection, style: text.titleSmall),
                SwitchListTile(
                  key: const Key('sounds'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.sounds),
                  subtitle: Text(l10n.soundsHint),
                  value: theme.sounds,
                  onChanged: (on) =>
                      controller.update(theme.copyWith(sounds: on)),
                ),
                const SizedBox(height: 16),
                Text(l10n.language, style: text.titleSmall),
                const SizedBox(height: 8),
                LanguagePicker(
                  selected: theme.language,
                  onSelected: (language) =>
                      controller.update(theme.copyWith(language: language)),
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
        title: Text(palette.name(AppLocalizations.of(context))),
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
