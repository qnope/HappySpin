import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happyspin/src/app.dart';
import 'package:happyspin/src/app_theme.dart';
import 'package:happyspin/src/spinning_wheel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('a theme survives encoding', () {
    const theme = AppTheme(mode: ThemeMode.dark, palette: WheelPalette.ocean);
    expect(AppTheme.decode(theme.encode()), theme);
  });

  test('unknown saved values fall back to the defaults', () {
    final theme = AppTheme.decode('{"mode":"violet","palette":"inconnue"}');
    expect(theme, const AppTheme());
  });

  test('neighbouring segments never share a color', () {
    for (final palette in WheelPalette.all) {
      for (var count = 2; count <= 20; count++) {
        for (var i = 0; i < count; i++) {
          expect(
            palette.segmentColor(i, count),
            isNot(palette.segmentColor((i + 1) % count, count)),
            reason: '${palette.name}, $count segments, segment $i',
          );
        }
      }
    }
  });

  test('the theme is saved on the device', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PreferencesAppThemeStore();
    expect(await store.load(), isNull);
    const theme = AppTheme(mode: ThemeMode.light, palette: WheelPalette.candy);
    await store.save(theme);
    expect(await store.load(), theme);
  });

  test('unreadable saved theme is ignored', () async {
    SharedPreferences.setMockInitialValues({'appTheme': 'pas du json'});
    expect(await PreferencesAppThemeStore().load(), isNull);
  });

  testWidgets('picking a theme restyles the app and is remembered', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = MemoryAppThemeStore();
    await tester.pumpWidget(HappySpinApp(themeStore: store));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('themeButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sombre'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('palette-forest')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('palette-forest')));
    await tester.pumpAndSettle();

    expect(
      store.saved,
      const AppTheme(mode: ThemeMode.dark, palette: WheelPalette.forest),
    );
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    final context = tester.element(find.byType(SpinningWheel));
    expect(WheelTheme.of(context), WheelPalette.forest);
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('the saved theme is applied on start', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = MemoryAppThemeStore(
      const AppTheme(mode: ThemeMode.dark, palette: WheelPalette.ocean),
    );
    await tester.pumpWidget(HappySpinApp(themeStore: store));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(SpinningWheel));
    expect(WheelTheme.of(context), WheelPalette.ocean);
    expect(Theme.of(context).brightness, Brightness.dark);
    final dot = tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
    expect(dot.backgroundColor, WheelPalette.ocean.colors.first);
  });
}
