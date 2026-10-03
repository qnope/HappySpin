import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happyspin/src/choice_lists.dart';
import 'package:happyspin/src/home_page.dart';

void main() {
  Future<MemoryChoiceListStore> pump(
    WidgetTester tester, {
    MemoryChoiceListStore? store,
  }) async {
    store ??= MemoryChoiceListStore();
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(random: math.Random(1), store: store),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> openListMenu(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('listMenu')));
    await tester.pumpAndSettle();
  }

  Future<void> createList(WidgetTester tester, String name) async {
    await openListMenu(tester);
    await tester.tap(find.byKey(const Key('newList')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('listNameInput')), name);
    await tester.tap(find.byKey(const Key('confirmListName')));
    await tester.pump();
  }

  Future<void> addChoice(WidgetTester tester, String choice) async {
    await tester.enterText(find.byKey(const Key('choiceInput')), choice);
    await tester.tap(find.byKey(const Key('addChoice')));
    await tester.pump();
  }

  String listName(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('listName'))).data!;

  testWidgets('adds and removes choices', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('choiceInput')), 'Tacos');
    await tester.tap(find.byKey(const Key('addChoice')));
    await tester.pump();
    expect(find.widgetWithText(ListTile, 'Tacos'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Tacos'),
        matching: find.byIcon(Icons.close),
      ),
    );
    await tester.pump();
    expect(find.widgetWithText(ListTile, 'Tacos'), findsNothing);
  });

  testWidgets('spinning shows one of the choices', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('spin')));
    await tester.pumpAndSettle();
    final result = tester.widget<Text>(find.byKey(const Key('result')));
    expect(['Pizza', 'Sushi', 'Burger', 'Salade'], contains(result.data));
  });

  testWidgets('spin is disabled with fewer than 2 choices', (tester) async {
    await pump(tester);
    await tester.tap(find.byTooltip('Tout effacer'));
    await tester.pump();
    final button = tester.widget<ButtonStyleButton>(
      find.byKey(const Key('spin')),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Ajoute au moins 2 choix'), findsOneWidget);
  });

  testWidgets('creates a new empty list and switches to it', (tester) async {
    final store = await pump(tester);
    expect(listName(tester), 'Repas');

    await createList(tester, 'Week-end');
    expect(listName(tester), 'Week-end');
    expect(find.text('Aucun choix pour le moment.'), findsOneWidget);

    await addChoice(tester, 'Plage');
    await addChoice(tester, 'Musée');
    expect(store.saved!.lists.map((l) => l.name), ['Repas', 'Week-end']);
    expect(store.saved!.selected.choices, ['Plage', 'Musée']);

    // Back to the first list, its choices are untouched.
    await openListMenu(tester);
    await tester.tap(find.text('Repas').last);
    await tester.pumpAndSettle();
    expect(listName(tester), 'Repas');
    expect(find.widgetWithText(ListTile, 'Pizza'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Plage'), findsNothing);
    expect(store.saved!.current, 0);
  });

  testWidgets('restores saved lists', (tester) async {
    await pump(
      tester,
      store: MemoryChoiceListStore(
        ChoiceLists(
          lists: const [
            ChoiceList(name: 'Repas', choices: ['Pizza', 'Sushi']),
            ChoiceList(name: 'Films', choices: ['Alien', 'Amélie']),
          ],
          current: 1,
        ),
      ),
    );
    expect(listName(tester), 'Films');
    expect(find.widgetWithText(ListTile, 'Amélie'), findsOneWidget);
  });

  testWidgets('renames and deletes a list', (tester) async {
    final store = await pump(tester);
    await createList(tester, 'Films');

    await openListMenu(tester);
    await tester.tap(find.byKey(const Key('renameList')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('listNameInput')), 'Séries');
    await tester.tap(find.byKey(const Key('confirmListName')));
    await tester.pumpAndSettle();
    expect(listName(tester), 'Séries');

    await openListMenu(tester);
    await tester.tap(find.byKey(const Key('deleteList')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDeleteList')));
    await tester.pumpAndSettle();
    expect(listName(tester), 'Repas');
    expect(store.saved!.lists.map((l) => l.name), ['Repas']);
  });

  testWidgets('the last list cannot be deleted', (tester) async {
    await pump(tester);
    await openListMenu(tester);
    final item = tester.widget<PopupMenuItem<VoidCallback>>(
      find.byKey(const Key('deleteList')),
    );
    expect(item.enabled, isFalse);
  });

  testWidgets('empty names do not create a list', (tester) async {
    final store = await pump(tester);
    await createList(tester, '   ');
    await tester.pumpAndSettle();
    expect(listName(tester), 'Repas');
    expect(store.saved, isNull);
  });
}
