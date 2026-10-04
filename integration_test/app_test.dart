import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happyspin/src/app.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create a list, add choices, spin and get a result', (
    tester,
  ) async {
    // Whatever the browser's language, follow the French texts below.
    tester.platformDispatcher.localesTestValue = const [Locale('fr', 'FR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const HappySpinApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('listMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('newList')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('listNameInput')), 'Sorties');
    await tester.tap(find.byKey(const Key('confirmListName')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('listName')), findsOneWidget);
    expect(find.text('Sorties'), findsOneWidget);
    expect(find.text('Ajoute au moins 2 choix'), findsOneWidget);

    for (final choice in ['Cinéma', 'Resto', 'Balade']) {
      await tester.enterText(find.byKey(const Key('choiceInput')), choice);
      await tester.tap(find.byKey(const Key('addChoice')));
      await tester.pump();
    }
    expect(find.byType(ListTile), findsNWidgets(3));

    // A focused text field blinks its cursor forever, which would keep
    // pumpAndSettle from ever settling.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('spin')));
    await tester.pumpAndSettle();

    final result = tester.widget<Text>(find.byKey(const Key('result')));
    expect(['Cinéma', 'Resto', 'Balade'], contains(result.data));

    await tester.tap(find.text('Super !'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('result')), findsNothing);
  });
}
