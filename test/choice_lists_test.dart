import 'package:flutter_test/flutter_test.dart';
import 'package:happyspin/src/choice_lists.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('encodes and decodes lists', () {
    final lists = ChoiceLists(
      lists: const [
        ChoiceList(name: 'Repas', choices: ['Pizza', 'Sushi']),
        ChoiceList(name: 'Vide', choices: []),
      ],
      current: 1,
    );
    final decoded = ChoiceLists.decode(lists.encode());
    expect(decoded.current, 1);
    expect(decoded.lists.map((l) => l.name), ['Repas', 'Vide']);
    expect(decoded.lists.first.choices, ['Pizza', 'Sushi']);
  });

  test('clamps the selected list into range', () {
    final lists = ChoiceLists(lists: ChoiceLists.initial().lists, current: 5);
    expect(lists.current, 0);
  });

  test('saves to and loads from device preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PreferencesChoiceListStore();
    expect(await store.load(), isNull);

    await store.save(
      ChoiceLists(
        lists: const [
          ChoiceList(name: 'Films', choices: ['Alien']),
        ],
        current: 0,
      ),
    );
    final loaded = await store.load();
    expect(loaded!.selected.name, 'Films');
    expect(loaded.selected.choices, ['Alien']);
  });

  test('ignores unreadable saved data', () async {
    SharedPreferences.setMockInitialValues({'choiceLists': 'pas du json'});
    expect(await PreferencesChoiceListStore().load(), isNull);
  });

  test('saves the weight of each choice', () {
    final lists = ChoiceLists(
      lists: [
        const ChoiceList(
          name: 'Repas',
          choices: ['Pizza', 'Sushi'],
        ).withWeight(1, 3),
      ],
      current: 0,
    );
    final decoded = ChoiceLists.decode(lists.encode());
    expect(decoded.selected.weights, [1, 3]);
    expect(decoded.selected.chanceOf(1), 0.75);
  });

  test('lists saved before weights give every choice a weight of 1', () {
    final decoded = ChoiceLists.decode(
      '{"current":0,"lists":[{"name":"Repas","choices":["Pizza","Sushi"]}]}',
    );
    expect(decoded.selected.choices, ['Pizza', 'Sushi']);
    expect(decoded.selected.weights, [1, 1]);
  });

  test('weights follow their choice and stay in range', () {
    var list = const ChoiceList(
      name: 'Repas',
      choices: ['A', 'B'],
    ).withChoice('C').withWeight(2, 4).withWeight(0, 99);
    expect(list.weights, [ChoiceList.maxWeight, 1, 4]);
    list = list.withoutChoice(1);
    expect(list.choices, ['A', 'C']);
    expect(list.weights, [ChoiceList.maxWeight, 4]);
    expect(list.withWeight(1, 0).weights.last, ChoiceList.minWeight);
  });

  group('eliminated choices', () {
    const list = ChoiceList(
      name: 'Repas',
      choices: ['Pizza', 'Sushi', 'Burger', 'Salade'],
      eliminated: {1, 3},
    );

    test('are left out of the remaining ones', () {
      expect(list.remaining, [0, 2]);
      expect(list.withEliminated(0).remaining, [2]);
      expect(list.withRestored(3).remaining, [0, 2, 3]);
      expect(list.withAllRestored().remaining, [0, 1, 2, 3]);
    });

    test('follow their choice when another one is removed', () {
      final removed = list.withoutChoice(0);
      expect(removed.choices, ['Sushi', 'Burger', 'Salade']);
      expect(removed.eliminated, {0, 2});
      expect(list.withoutChoice(1).eliminated, {2});
    });

    test('stay out when a choice is added, and go with a new list', () {
      expect(list.withChoice('Tacos').eliminated, {1, 3});
      expect(list.copyWith(choices: ['Tacos']).eliminated, isEmpty);
      expect(list.copyWith(name: 'Midi').eliminated, {1, 3});
    });

    test('are saved, and missing from older lists', () {
      final decoded = ChoiceList.fromJson(list.toJson());
      expect(decoded.eliminated, {1, 3});
      final old = ChoiceList.fromJson({
        'name': 'Repas',
        'choices': ['Pizza', 'Sushi'],
      });
      expect(old.eliminated, isEmpty);
    });

    test('chances can count only some choices', () {
      const weighted = ChoiceList(
        name: 'Repas',
        choices: ['Pizza', 'Sushi', 'Burger'],
        weights: [2, 1, 1],
      );
      expect(weighted.chanceOf(0), 0.5);
      expect(weighted.chanceOf(0, among: [0, 1]), closeTo(2 / 3, 1e-9));
    });
  });
}
