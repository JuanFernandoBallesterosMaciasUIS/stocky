import 'package:flutter/material.dart';
import 'res/data/colors.dart';
import 'res/data/constants.dart';
import 'screens/main_scaffold.dart';

void main() {
  runApp(const StockyApp());
}

/// Punto de entrada de la aplicacion Stocky.
class StockyApp extends StatelessWidget {
  const StockyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ColorApp.primary),
        scaffoldBackgroundColor: ColorApp.backgroundLight,
        splashFactory: InkRipple.splashFactory,
      ),
      home: const MainScaffold(),
    );
  }
}
