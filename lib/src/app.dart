import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

import 'app_theme.dart';
import 'home_page.dart';

class HappySpinApp extends StatefulWidget {
  const HappySpinApp({super.key, this.themeStore});

  /// Injectable for tests; defaults to storage on the device.
  final AppThemeStore? themeStore;

  @override
  State<HappySpinApp> createState() => _HappySpinAppState();
}

class _HappySpinAppState extends State<HappySpinApp> {
  late final AppThemeController _theme = AppThemeController(
    store: widget.themeStore,
  )..load();

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _theme,
      builder: (context, _) {
        final theme = _theme.theme;
        return MaterialApp(
          title: 'HappySpin',
          debugShowCheckedModeBanner: false,
          theme: theme.data(Brightness.light),
          darkTheme: theme.data(Brightness.dark),
          themeMode: theme.mode,
          locale: theme.language.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          // English first: it is what a device in another language gets.
          supportedLocales: const [Locale('en'), Locale('fr'), Locale('es')],
          home: HomePage(themeController: _theme),
        );
      },
    );
  }
}
