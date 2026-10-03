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
}
