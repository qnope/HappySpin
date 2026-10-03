import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happyspin/src/home_page.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomePage(random: math.Random(1))),
    );
  }

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
}
