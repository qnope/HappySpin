import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A named list of choices, one per wheel, each with a weight.
class ChoiceList {
  /// [weights] go with [choices] one for one; missing ones count as 1.
  const ChoiceList({required this.name, required this.choices, this._weights});

  /// Smallest and largest weight a choice can have.
  static const int minWeight = 1;
  static const int maxWeight = 10;

  final String name;
  final List<String> choices;
  final List<int>? _weights;

  /// How likely each choice is, relative to the others.
  List<int> get weights => [
    for (var i = 0; i < choices.length; i++) weightOf(i),
  ];

  int weightOf(int index) {
    final weights = _weights;
    if (weights == null || index >= weights.length) return 1;
    return weights[index].clamp(minWeight, maxWeight);
  }

  /// Chance of picking the choice at [index], between 0 and 1.
  double chanceOf(int index) {
    final total = weights.fold(0, (sum, w) => sum + w);
    return weightOf(index) / total;
  }

  ChoiceList copyWith({
    String? name,
    List<String>? choices,
    List<int>? weights,
  }) => ChoiceList(
    name: name ?? this.name,
    choices: choices ?? this.choices,
    weights: weights ?? (choices == null ? _weights : null),
  );

  ChoiceList withChoice(String choice, {int weight = 1}) =>
      copyWith(choices: [...choices, choice], weights: [...weights, weight]);

  ChoiceList withoutChoice(int index) => copyWith(
    choices: [...choices]..removeAt(index),
    weights: weights..removeAt(index),
  );

  ChoiceList withWeight(int index, int weight) =>
      copyWith(weights: weights..[index] = weight.clamp(minWeight, maxWeight));

  Map<String, Object?> toJson() => {
    'name': name,
    'choices': choices,
    'weights': weights,
  };

  factory ChoiceList.fromJson(Map<String, Object?> json) => ChoiceList(
    name: json['name'] as String,
    choices: (json['choices'] as List).cast<String>(),
    // Lists saved before weights existed have none: every choice weighs 1.
    weights: (json['weights'] as List?)?.cast<int>(),
  );
}

/// All the lists the user has, and which one is on the wheel.
class ChoiceLists {
  ChoiceLists({required this.lists, required int current})
    : assert(lists.isNotEmpty),
      current = current.clamp(0, lists.length - 1);

  /// What a first launch shows.
  factory ChoiceLists.initial() => ChoiceLists(
    lists: const [
      ChoiceList(
        name: 'Repas',
        choices: ['Pizza', 'Sushi', 'Burger', 'Salade'],
      ),
    ],
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
