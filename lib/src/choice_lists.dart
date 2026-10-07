import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A named list of choices, one per wheel, each with a weight and maybe a
/// color of its own.
class ChoiceList {
  /// [weights] and [colors] go with [choices] one for one; missing weights
  /// count as 1, and missing colors are the theme's.
  const ChoiceList({
    required this.name,
    required this.choices,
    this._weights,
    this._colors,
    this.eliminated = const {},
  });

  /// Smallest and largest weight a choice can have.
  static const int minWeight = 1;
  static const int maxWeight = 10;

  final String name;
  final List<String> choices;
  final List<int>? _weights;
  final List<Color?>? _colors;

  /// Indexes of the choices that came out in elimination mode, and are left
  /// off the wheel until they are put back.
  final Set<int> eliminated;

  bool isEliminated(int index) => eliminated.contains(index);

  /// Indexes of the choices still on the wheel in elimination mode.
  List<int> get remaining => [
    for (var i = 0; i < choices.length; i++)
      if (!isEliminated(i)) i,
  ];

  /// How likely each choice is, relative to the others.
  List<int> get weights => [
    for (var i = 0; i < choices.length; i++) weightOf(i),
  ];

  int weightOf(int index) {
    final weights = _weights;
    if (weights == null || index >= weights.length) return 1;
    return weights[index].clamp(minWeight, maxWeight);
  }

  /// Color the user gave each choice, null where the theme picks it.
  List<Color?> get colors => [
    for (var i = 0; i < choices.length; i++) colorOf(i),
  ];

  /// Color the user gave the choice at [index], or null if the theme picks
  /// it.
  Color? colorOf(int index) {
    final colors = _colors;
    if (colors == null || index >= colors.length) return null;
    return colors[index];
  }

  /// Chance of picking the choice at [index], between 0 and 1, when the
  /// wheel holds the choices at [among] (all of them by default).
  double chanceOf(int index, {Iterable<int>? among}) {
    among ??= Iterable.generate(choices.length);
    final total = among.fold(0, (sum, i) => sum + weightOf(i));
    return weightOf(index) / total;
  }

  /// A new list of [choices] drops the weights, colors and eliminations of
  /// the old one, unless new ones are given.
  ChoiceList copyWith({
    String? name,
    List<String>? choices,
    List<int>? weights,
    List<Color?>? colors,
    Set<int>? eliminated,
  }) => ChoiceList(
    name: name ?? this.name,
    choices: choices ?? this.choices,
    weights: weights ?? (choices == null ? _weights : null),
    colors: colors ?? (choices == null ? _colors : null),
    eliminated: eliminated ?? (choices == null ? this.eliminated : const {}),
  );

  ChoiceList withChoice(String choice, {int weight = 1}) => copyWith(
    choices: [...choices, choice],
    weights: [...weights, weight],
    colors: [...colors, null],
    eliminated: eliminated,
  );

  ChoiceList withoutChoice(int index) => copyWith(
    choices: [...choices]..removeAt(index),
    weights: weights..removeAt(index),
    colors: colors..removeAt(index),
    // The choices after the removed one move up by one.
    eliminated: {
      for (final i in eliminated)
        if (i < index) i else if (i > index) i - 1,
    },
  );

  /// Takes the choice at [index] off the wheel.
  ChoiceList withEliminated(int index) =>
      copyWith(eliminated: {...eliminated, index});

  /// Puts the choice at [index] back on the wheel.
  ChoiceList withRestored(int index) =>
      copyWith(eliminated: {...eliminated}..remove(index));

  /// Puts every choice back on the wheel.
  ChoiceList withAllRestored() => copyWith(eliminated: const {});

  ChoiceList withWeight(int index, int weight) =>
      copyWith(weights: weights..[index] = weight.clamp(minWeight, maxWeight));

  /// Gives the choice at [index] its own [color], or the theme's when null.
  ChoiceList withColor(int index, Color? color) =>
      copyWith(colors: colors..[index] = color);

  /// Calls the choice at [index] [name], keeping its weight, color and
  /// whether it came out.
  ChoiceList withRenamed(int index, String name) => copyWith(
    choices: [...choices]..[index] = name,
    weights: weights,
    colors: colors,
    eliminated: eliminated,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'choices': choices,
    'weights': weights,
    'colors': [for (final color in colors) color?.toARGB32()],
    'eliminated': [...eliminated]..sort(),
  };

  factory ChoiceList.fromJson(Map<String, Object?> json) => ChoiceList(
    name: json['name'] as String,
    choices: (json['choices'] as List).cast<String>(),
    // Lists saved before weights existed have none: every choice weighs 1.
    weights: (json['weights'] as List?)?.cast<int>(),
    // Lists saved before colors existed take all of theirs from the theme.
    colors: [
      for (final color in (json['colors'] as List?)?.cast<int?>() ?? <int?>[])
        color == null ? null : Color(color),
    ],
    eliminated: {
      for (final i in (json['eliminated'] as List?)?.cast<int>() ?? <int>[])
        if (i >= 0 && i < (json['choices'] as List).length) i,
    },
  );
}

/// All the lists the user has, and which one is on the wheel.
class ChoiceLists {
  ChoiceLists({required this.lists, required int current})
    : assert(lists.isNotEmpty),
      current = current.clamp(0, lists.length - 1);

  /// What a first launch shows: one example list, given in the user's
  /// language.
  factory ChoiceLists.initial({
    String name = 'Repas',
    List<String> choices = const ['Pizza', 'Sushi', 'Burger', 'Salade'],
  }) => ChoiceLists(
    lists: [ChoiceList(name: name, choices: choices)],
    current: 0,
  );

  final List<ChoiceList> lists;
  final int current;

  ChoiceList get selected => lists[current];

  String encode() => jsonEncode({
    'current': current,
    'lists': [for (final list in lists) list.toJson()],
  });

  factory ChoiceLists.decode(String source) {
    final json = jsonDecode(source) as Map<String, Object?>;
    return ChoiceLists(
      lists: [
        for (final list in json['lists'] as List)
          ChoiceList.fromJson(list as Map<String, Object?>),
      ],
      current: json['current'] as int,
    );
  }
}

/// Where the lists are kept between launches.
abstract class ChoiceListStore {
  Future<ChoiceLists?> load();
  Future<void> save(ChoiceLists lists);
}

/// Keeps the lists on the device (local storage on the web).
class PreferencesChoiceListStore implements ChoiceListStore {
  static const _key = 'choiceLists';

  @override
  Future<ChoiceLists?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final source = prefs.getString(_key);
    if (source == null) return null;
    try {
      return ChoiceLists.decode(source);
    } on Object {
      // Unreadable data should not keep the app from starting.
      return null;
    }
  }

  @override
  Future<void> save(ChoiceLists lists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, lists.encode());
  }
}

/// Keeps the lists in memory only; for tests.
class MemoryChoiceListStore implements ChoiceListStore {
  MemoryChoiceListStore([this.saved]);

  ChoiceLists? saved;

  @override
  Future<ChoiceLists?> load() async => saved;

  @override
  Future<void> save(ChoiceLists lists) async => saved = lists;
}
