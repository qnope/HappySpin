import 'package:flutter/material.dart';

import 'home_page.dart';

class HappySpinApp extends StatelessWidget {
  const HappySpinApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFFF7A59);
    return MaterialApp(
      title: 'HappySpin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
