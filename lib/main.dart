import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const GymFitApp());
}

class GymFitApp extends StatelessWidget {
  const GymFitApp({super.key});

  static const _seed = Color(0xFF00C853); // verde energético

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymFit',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18))),
      ),
    );
  }
}
