import 'package:flutter/material.dart';

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
          home: HomePage(themeController: _theme),
        );
      },
    );
  }
}
