import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A named list of choices, one per wheel.
class ChoiceList {
  const ChoiceList({required this.name, required this.choices});

  final String name;
  final List<String> choices;

  ChoiceList copyWith({String? name, List<String>? choices}) =>
      ChoiceList(name: name ?? this.name, choices: choices ?? this.choices);

  Map<String, Object?> toJson() => {'name': name, 'choices': choices};

  factory ChoiceList.fromJson(Map<String, Object?> json) => ChoiceList(
    name: json['name'] as String,
    choices: (json['choices'] as List).cast<String>(),
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
