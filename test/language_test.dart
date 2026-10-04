import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happyspin/src/app.dart';
import 'package:happyspin/src/app_theme.dart';
import 'package:happyspin/src/language_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> start(
    WidgetTester tester, {
    required List<Locale> device,
    AppThemeStore? store,
  }) async {
    tester.platformDispatcher.localesTestValue = device;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      HappySpinApp(themeStore: store ?? MemoryAppThemeStore()),
    );
    await tester.pumpAndSettle();
  }

  test('the language survives encoding', () {
    const theme = AppTheme(language: AppLanguage.spanish);
    expect(AppTheme.decode(theme.encode()), theme);
  });

  test('settings saved before languages existed follow the device', () {
    final theme = AppTheme.decode('{"mode": "dark", "palette": "ocean"}');
    expect(theme.language, AppLanguage.device);
  });

  for (final (device, spin, list) in [
    (const Locale('fr', 'FR'), 'Faire tourner', 'Repas'),
    (const Locale('en', 'US'), 'Spin', 'Meals'),
    (const Locale('es', 'ES'), 'Girar', 'Comidas'),
    // Any other language gets English.
    (const Locale('de', 'DE'), 'Spin', 'Meals'),
  ]) {
    testWidgets('a device in $device shows the app in its language', (
      tester,
    ) async {
      await start(tester, device: [device]);
      expect(find.text(spin), findsOneWidget);
      expect(find.text(list), findsOneWidget);
    });
  }

  testWidgets('picking a flag changes the language and is remembered', (
    tester,
  ) async {
    final store = MemoryAppThemeStore();
    await start(tester, device: const [Locale('fr', 'FR')], store: store);

    await tester.tap(find.byKey(const Key('themeButton')));
    await tester.pumpAndSettle();
    expect(find.text('Langue'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('language-spanish')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-spanish')));
    await tester.pumpAndSettle();

    expect(find.text('Idioma'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);
    expect(store.saved, const AppTheme(language: AppLanguage.spanish));

    await tester.tap(find.byKey(const Key('language-device')));
    await tester.pumpAndSettle();
    expect(find.text('Langue'), findsOneWidget);
    expect(store.saved, const AppTheme());
  });

  testWidgets('the saved language wins over the device one', (tester) async {
    await start(
      tester,
      device: const [Locale('fr', 'FR')],
      store: MemoryAppThemeStore(const AppTheme(language: AppLanguage.english)),
    );
    expect(find.text('Spin'), findsOneWidget);
  });

  testWidgets('choices the user typed are not translated', (tester) async {
    await start(tester, device: const [Locale('en', 'US')]);
    await tester.enterText(find.byKey(const Key('choiceInput')), 'Crêpes');
    await tester.tap(find.byKey(const Key('addChoice')));
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('themeButton')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('language-french')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-french')));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Langue'))).pop();
    await tester.pumpAndSettle();

    expect(find.text('Crêpes'), findsWidgets);
    // The example list, made on the first launch, stays as it was.
    expect(find.text('Meals'), findsOneWidget);
    expect(find.text('Faire tourner'), findsOneWidget);
  });
}
