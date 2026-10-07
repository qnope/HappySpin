import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happyspin/l10n/app_localizations.dart';
import 'package:happyspin/src/app_theme.dart';
import 'package:happyspin/src/choice_lists.dart';
import 'package:happyspin/src/home_page.dart';
import 'package:happyspin/src/spinning_wheel.dart';
import 'package:happyspin/src/wheel_feedback.dart';

/// Counts the ticks, stops and chimes the wheel asks for.
class RecordingFeedback implements WheelFeedback {
  final ticks = <double>[];
  var stops = 0;
  var chimes = 0;

  @override
  void preload() {}

  @override
  void tick(double speed) => ticks.add(speed);

  @override
  void stop({bool celebrate = true}) {
    stops++;
    if (celebrate) chimes++;
  }

  @override
  void celebrate() => chimes++;
}

void main() {
  Future<MemoryChoiceListStore> pump(
    WidgetTester tester, {
    MemoryChoiceListStore? store,
    bool weighted = false,
    bool sounds = true,
    bool elimination = false,
    bool confirmElimination = false,
    WheelFeedback? feedback,
  }) async {
    store ??= MemoryChoiceListStore();
    final settings = AppThemeController(store: MemoryAppThemeStore())
      ..update(
        AppTheme(
          weightedChoices: weighted,
          sounds: sounds,
          elimination: elimination,
          confirmElimination: confirmElimination,
        ),
      );
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomePage(
          random: math.Random(1),
          store: store,
          themeController: settings,
          feedback: feedback,
        ),
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

  testWidgets('tapping a choice\'s name lets the user rename it', (
    tester,
  ) async {
    final store = await pump(tester);
    await tester.tap(find.byKey(const Key('choiceName1')));
    await tester.pump();
    final field = find.byKey(const Key('renameInput'));
    expect(field, findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text, 'Sushi');

    await tester.enterText(field, '  Ramen ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(field, findsNothing);
    expect(find.widgetWithText(ListTile, 'Ramen'), findsOneWidget);
    expect(store.saved!.selected.choices, [
      'Pizza',
      'Ramen',
      'Burger',
      'Salade',
    ]);
    final wheel = tester.widget<SpinningWheel>(find.byType(SpinningWheel));
    expect(wheel.choices, contains('Ramen'));
  });

  testWidgets('an empty name keeps the old one', (tester) async {
    final store = await pump(tester);
    await tester.tap(find.byKey(const Key('choiceName0')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('renameInput')), '   ');
    // Tapping elsewhere ends the edit too.
    await tester.tapAt(const Offset(5, 300));
    await tester.pump();
    expect(find.byKey(const Key('renameInput')), findsNothing);
    expect(find.widgetWithText(ListTile, 'Pizza'), findsOneWidget);
    expect(store.saved, isNull);
  });

  testWidgets('tapping a choice\'s color forces another one, until restored', (
    tester,
  ) async {
    final store = await pump(tester);
    const palette = WheelPalette.festive;
    Color wheelColor() =>
        tester.widget<SpinningWheel>(find.byType(SpinningWheel)).colors![2];
    expect(wheelColor(), palette.segmentColor(2, 4));

    await tester.tap(find.byKey(const Key('color2')));
    await tester.pumpAndSettle();
    expect(find.text('Couleur du choix'), findsOneWidget);
    // Picks a color of another palette.
    final picked = WheelPalette.ocean.colors.first;
    final swatch = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          (w.decoration as BoxDecoration?)?.color == picked &&
          w.constraints?.maxWidth == 40,
    );
    await tester.tap(swatch);
    await tester.pumpAndSettle();
    expect(find.text('Couleur du choix'), findsNothing);
    expect(wheelColor(), picked);
    expect(store.saved!.selected.colorOf(2), picked);

    await tester.tap(find.byKey(const Key('color2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restaurer par défaut'));
    await tester.pumpAndSettle();
    expect(wheelColor(), palette.segmentColor(2, 4));
    expect(store.saved!.selected.colorOf(2), isNull);
  });

  testWidgets('cancelling the color popup changes nothing', (tester) async {
    final store = await pump(tester);
    await tester.tap(find.byKey(const Key('color0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(store.saved, isNull);
  });

  testWidgets('the wheel ticks on each peg and chimes once it stops', (
    tester,
  ) async {
    final feedback = RecordingFeedback();
    await pump(tester, feedback: feedback);
    await tester.tap(find.byKey(const Key('spin')));
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(feedback.ticks, isNotEmpty);
    expect(feedback.stops, 0);

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('result')), findsOneWidget);
    expect(feedback.stops, 1);
    // A wheel launched at 0.7 turn per second or more passes several pegs
    // of a four-choice wheel, each one ticking as the wheel goes forward.
    expect(feedback.ticks.length, greaterThan(8));
    expect(feedback.ticks.first, greaterThan(0));
  });

  testWidgets('the wheel stays quiet when sounds are off', (tester) async {
    final feedback = RecordingFeedback();
    await pump(tester, feedback: feedback, sounds: false);
    await tester.tap(find.byKey(const Key('spin')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('result')), findsOneWidget);
    expect(feedback.ticks, isEmpty);
    expect(feedback.stops, 0);
  });

  testWidgets('spinning shows one of the choices', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('spin')));
    await tester.pumpAndSettle();
    final result = tester.widget<Text>(find.byKey(const Key('result')));
    expect(['Pizza', 'Sushi', 'Burger', 'Salade'], contains(result.data));
  });

  testWidgets('pressing on the spinning wheel brings the result sooner', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('spin')));
    await tester.pump();
    final finger = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('wheel'))),
    );
    // A free spin takes at least 3 seconds; held, the wheel stops within 1.5.
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 1000 ~/ 60));
    }
    await finger.up();
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 1000 ~/ 60));
    }
    expect(find.byKey(const Key('result')), findsOneWidget);
    await tester.pumpAndSettle();
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

  testWidgets('weights make a choice more likely and are saved', (
    tester,
  ) async {
    final store = await pump(tester, weighted: true);
    String text(String key) => tester.widget<Text>(find.byKey(Key(key))).data!;
    expect(text('weight0'), '×1');
    expect(text('chance0'), '25\u00a0%');

    await tester.tap(find.byKey(const Key('heavier0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('heavier0')));
    await tester.pump();
    expect(text('weight0'), '×3');
    expect(text('chance0'), '50\u00a0%');
    expect(text('chance1'), '17\u00a0%');
    expect(store.saved!.selected.weights, [3, 1, 1, 1]);

    await tester.tap(find.byKey(const Key('lighter0')));
    await tester.pump();
    expect(store.saved!.selected.weights, [2, 1, 1, 1]);

    // A weight cannot go below 1.
    final lighter = tester.widget<IconButton>(
      find.byKey(const Key('lighter1')),
    );
    expect(lighter.onPressed, isNull);

    // Removing a choice keeps the weights of the others.
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Sushi'),
        matching: find.byIcon(Icons.close),
      ),
    );
    await tester.pump();
    expect(store.saved!.selected.choices, ['Pizza', 'Burger', 'Salade']);
    expect(store.saved!.selected.weights, [2, 1, 1]);
    expect(text('chance0'), '50\u00a0%');
  });

  testWidgets('a heavy choice still spins to a result', (tester) async {
    await pump(
      tester,
      weighted: true,
      store: MemoryChoiceListStore(
        ChoiceLists(
          lists: const [
            ChoiceList(
              name: 'Repas',
              choices: ['Pizza', 'Sushi'],
              weights: [10, 1],
            ),
          ],
          current: 0,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('spin')));
    await tester.pumpAndSettle();
    final result = tester.widget<Text>(find.byKey(const Key('result')));
    expect(['Pizza', 'Sushi'], contains(result.data));
  });

  testWidgets('weights are hidden and ignored until turned on', (tester) async {
    await pump(
      tester,
      store: MemoryChoiceListStore(
        ChoiceLists(
          lists: const [
            ChoiceList(
              name: 'Repas',
              choices: ['Pizza', 'Sushi'],
              weights: [10, 1],
            ),
          ],
          current: 0,
        ),
      ),
    );
    expect(find.byKey(const Key('heavier0')), findsNothing);
    expect(find.byKey(const Key('chance0')), findsNothing);
    final wheel = tester.widget<SpinningWheel>(find.byType(SpinningWheel));
    expect(wheel.weights, [1, 1]);
  });

  testWidgets('turning weights on in the settings shows the saved ones', (
    tester,
  ) async {
    final settings = AppThemeController(store: MemoryAppThemeStore());
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomePage(
            random: math.Random(1),
            store: MemoryChoiceListStore(
              ChoiceLists(
                lists: const [
                  ChoiceList(
                    name: 'Repas',
                    choices: ['Pizza', 'Sushi'],
                    weights: [3, 1],
                  ),
                ],
                current: 0,
              ),
            ),
            themeController: settings,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('themeButton')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('weightedChoices')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('weightedChoices')));
    await tester.pumpAndSettle();
    expect(settings.theme.weightedChoices, isTrue);

    final wheel = tester.widget<SpinningWheel>(find.byType(SpinningWheel));
    expect(wheel.weights, [3, 1]);
    expect(tester.widget<Text>(find.byKey(const Key('weight0'))).data, '×3');
  });

  testWidgets('the settings stay below the notch and close with a button', (
    tester,
  ) async {
    // An iPhone with a Dynamic Island: 59 px of status bar at the top.
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 59 * 3, bottom: 34 * 3);
    addTearDown(tester.view.reset);
    final settings = AppThemeController(store: MemoryAppThemeStore());
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomePage(
          random: math.Random(1),
          store: MemoryChoiceListStore(),
          themeController: settings,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('themeButton')));
    await tester.pumpAndSettle();
    final close = find.byKey(const Key('closeSettings'));
    expect(tester.getTopLeft(find.byType(ThemeSheet)).dy, greaterThan(59));
    expect(tester.getTopLeft(close).dy, greaterThanOrEqualTo(59));

    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(find.byType(ThemeSheet), findsNothing);
  });

  testWidgets('the keyboard covers the page without shrinking the wheel', (
    tester,
  ) async {
    // An iPhone 15: the keyboard takes 336 px and hides the home indicator.
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 59 * 3, bottom: 34 * 3);
    tester.view.viewPadding = tester.view.padding;
    addTearDown(tester.view.reset);
    await pump(tester);
    final wheel = find.byType(SpinningWheel);
    final input = find.byKey(const Key('choiceInput'));
    final size = tester.getSize(wheel);

    await tester.tap(input);
    tester.view.viewInsets = const FakeViewPadding(bottom: 336 * 3);
    tester.view.padding = const FakeViewPadding(top: 59 * 3);
    await tester.pumpAndSettle();

    // The spin button makes way for the field, right under the whole wheel.
    expect(tester.getSize(wheel), size);
    expect(find.byKey(const Key('spin')), findsNothing);
    expect(tester.getTopLeft(wheel).dy, greaterThan(59 + kToolbarHeight));
    expect(tester.getBottomLeft(input).dy, lessThanOrEqualTo(852 - 336));

    tester.view.resetViewInsets();
    tester.view.padding = const FakeViewPadding(top: 59 * 3, bottom: 34 * 3);
    await tester.pumpAndSettle();
    expect(tester.getSize(wheel), size);
    expect(find.byKey(const Key('spin')), findsOneWidget);
  });

  testWidgets('a choice being renamed stays above the keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 59 * 3, bottom: 34 * 3);
    tester.view.viewPadding = tester.view.padding;
    addTearDown(tester.view.reset);
    await pump(tester);
    final wheel = find.byType(SpinningWheel);
    final size = tester.getSize(wheel);

    await tester.tap(find.byKey(const Key('choiceName3')));
    tester.view.viewInsets = const FakeViewPadding(bottom: 336 * 3);
    tester.view.padding = const FakeViewPadding(top: 59 * 3);
    await tester.pumpAndSettle();

    final field = find.byKey(const Key('renameInput'));
    expect(tester.getSize(wheel), size);
    expect(tester.getBottomLeft(field).dy, lessThanOrEqualTo(852 - 336));
  });

  testWidgets('sounds can be turned off in the settings', (tester) async {
    final settings = AppThemeController(store: MemoryAppThemeStore());
    addTearDown(settings.dispose);
    final feedback = RecordingFeedback();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomePage(
          random: math.Random(1),
          store: MemoryChoiceListStore(),
          themeController: settings,
          feedback: feedback,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('themeButton')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('sounds')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sounds')));
    await tester.pumpAndSettle();
    expect(settings.theme.sounds, isFalse);

    Navigator.of(tester.element(find.byKey(const Key('sounds')))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('spin')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('result')), findsOneWidget);
    expect(feedback.ticks, isEmpty);
  });

  group('elimination mode', () {
    MemoryChoiceListStore storeWith(
      List<String> choices, {
      Set<int> eliminated = const {},
    }) => MemoryChoiceListStore(
      ChoiceLists(
        lists: [
          ChoiceList(name: 'Repas', choices: choices, eliminated: eliminated),
        ],
        current: 0,
      ),
    );

    List<String> wheelChoices(WidgetTester tester) =>
        tester.widget<SpinningWheel>(find.byType(SpinningWheel)).choices;

    Future<String> spin(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('spin')));
      await tester.pumpAndSettle();
      return tester.widget<Text>(find.byKey(const Key('result'))).data!;
    }

    testWidgets('picked choices come out until one is left, which wins', (
      tester,
    ) async {
      final feedback = RecordingFeedback();
      final store = await pump(
        tester,
        elimination: true,
        feedback: feedback,
        store: storeWith(['Pizza', 'Sushi', 'Burger']),
      );

      final first = await spin(tester);
      // Coming out of the wheel is no win: no celebration, no chime.
      expect(find.widgetWithText(AlertDialog, 'Éliminé'), findsOneWidget);
      expect(find.text('Le sort a choisi'), findsNothing);
      expect(find.byKey(const Key('eliminationNote')), findsOneWidget);
      expect(feedback.stops, 1);
      expect(feedback.chimes, 0);
      await tester.tap(find.byKey(const Key('next')));
      await tester.pumpAndSettle();
      expect(wheelChoices(tester), isNot(contains(first)));
      expect(wheelChoices(tester), hasLength(2));
      expect(find.text('1 choix éliminé'), findsOneWidget);
      // Still in the list, marked as out.
      expect(find.widgetWithText(ListTile, first), findsOneWidget);
      expect(find.text('Éliminé'), findsOneWidget);
      expect(store.saved!.selected.eliminated, hasLength(1));

      final second = await spin(tester);
      expect(second, isNot(first));
      expect(find.widgetWithText(AlertDialog, 'Éliminé'), findsOneWidget);
      await tester.tap(find.byKey(const Key('next')));
      await tester.pumpAndSettle();
      expect(wheelChoices(tester), hasLength(1));
      expect(find.text('2 choix éliminés'), findsOneWidget);

      // The last choice left wins, just like a normal pick.
      final last = wheelChoices(tester).single;
      expect(find.text('Le sort a choisi'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('result'))).data, last);
      expect(feedback.chimes, 1);
      await tester.tap(find.text('Super !'));
      await tester.pumpAndSettle();

      // No more spinning, the app says which one won.
      expect(find.byKey(const Key('spin')), findsNothing);
      expect(find.text("« $last » l'emporte !"), findsOneWidget);
      await tester.tap(find.byKey(const Key('wheel')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('result')), findsNothing);

      await tester.tap(find.byKey(const Key('restoreAllWheel')));
      await tester.pumpAndSettle();
      expect(wheelChoices(tester), ['Pizza', 'Sushi', 'Burger']);
      expect(find.byKey(const Key('spin')), findsOneWidget);
      expect(find.text('Éliminé'), findsNothing);
      expect(store.saved!.selected.eliminated, isEmpty);
    });

    testWidgets('asks before taking the choice out when set to', (
      tester,
    ) async {
      await pump(
        tester,
        elimination: true,
        confirmElimination: true,
        store: storeWith(['Pizza', 'Sushi', 'Burger']),
      );

      await spin(tester);
      expect(find.text('Super !'), findsNothing);
      await tester.tap(find.byKey(const Key('keepChoice')));
      await tester.pumpAndSettle();
      expect(wheelChoices(tester), hasLength(3));

      final picked = await spin(tester);
      await tester.tap(find.byKey(const Key('eliminateChoice')));
      await tester.pumpAndSettle();
      expect(wheelChoices(tester), hasLength(2));
      expect(wheelChoices(tester), isNot(contains(picked)));
    });

    testWidgets('a choice can be put back on its own', (tester) async {
      await pump(
        tester,
        elimination: true,
        store: storeWith(['Pizza', 'Sushi', 'Burger'], eliminated: {0, 2}),
      );
      expect(wheelChoices(tester), ['Sushi']);
      expect(find.text("« Sushi » l'emporte !"), findsOneWidget);

      await tester.tap(find.byKey(const Key('restore2')));
      await tester.pumpAndSettle();
      expect(wheelChoices(tester), ['Sushi', 'Burger']);
      expect(find.byKey(const Key('spin')), findsOneWidget);

      await tester.tap(find.byKey(const Key('restoreAll')));
      await tester.pumpAndSettle();
      expect(wheelChoices(tester), ['Pizza', 'Sushi', 'Burger']);
      expect(find.byKey(const Key('restoreAll')), findsNothing);
    });

    testWidgets('chances only count the choices left on the wheel', (
      tester,
    ) async {
      await pump(
        tester,
        elimination: true,
        weighted: true,
        store: storeWith(['Pizza', 'Sushi', 'Burger'], eliminated: {0}),
      );
      expect(find.byKey(const Key('chance0')), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('chance1'))).data,
        '50 %',
      );
    });

    testWidgets('choices that came out are back on the wheel when off', (
      tester,
    ) async {
      await pump(
        tester,
        store: storeWith(['Pizza', 'Sushi', 'Burger'], eliminated: {0}),
      );
      expect(wheelChoices(tester), ['Pizza', 'Sushi', 'Burger']);
      expect(find.text('Éliminé'), findsNothing);
      expect(find.byKey(const Key('restoreAll')), findsNothing);
      await spin(tester);
      expect(find.byKey(const Key('eliminationNote')), findsNothing);
    });

    testWidgets('is turned on in the settings, with its confirmation', (
      tester,
    ) async {
      final settings = AppThemeController(store: MemoryAppThemeStore());
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomePage(
            store: MemoryChoiceListStore(),
            themeController: settings,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('themeButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('confirmElimination')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('elimination')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('elimination')));
      await tester.pumpAndSettle();
      expect(settings.theme.elimination, isTrue);

      await tester.ensureVisible(find.byKey(const Key('confirmElimination')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmElimination')));
      await tester.pumpAndSettle();
      expect(settings.theme.confirmElimination, isTrue);
    });
  });
}
