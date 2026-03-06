import 'package:flutter/material.dart';
import 'res/data/colors.dart';
import 'res/data/constants.dart';
import 'screens/main_scaffold.dart';
import 'services/persistence_service.dart';
import 'store/app_store.dart';
import 'store/store_provider.dart';

/// Carga el estado persistido (si existe) y arranca la aplicación.
/// El binding debe inicializarse antes de usar SharedPreferences.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Intentar restaurar estado previo; si no hay datos el store usa los iniciales.
  final store = await PersistenceService.tryLoad() ?? AppStore();

  // Inyectar callback de persistencia: fire-and-forget tras cada mutación.
  store.setPersistCallback(() => PersistenceService.save(store));

  runApp(StockyApp(store: store));
}

/// Punto de entrada de la aplicacion Stocky.
class StockyApp extends StatelessWidget {
  const StockyApp({super.key, required this.store});

  final AppStore store;

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
      home: StoreProvider(store: store, child: const MainScaffold()),
    );
  }
}
