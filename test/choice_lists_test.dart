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
}
