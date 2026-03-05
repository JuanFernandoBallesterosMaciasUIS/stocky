import 'package:flutter/widgets.dart';

import 'app_store.dart';

/// Proveedor del estado global mediante [InheritedNotifier].
///
/// Responsabilidad única: exponer [AppStore] al árbol de widgets sin
/// acoplar los hijos al sistema de gestión de estado.
///
/// Uso:
/// ```dart
/// // En main.dart
/// StoreProvider(store: AppStore(), child: const MainScaffold())
///
/// // En cualquier widget hijo
/// final store = StoreProvider.of(context);
/// ```
class StoreProvider extends InheritedNotifier<AppStore> {
  const StoreProvider({
    super.key,
    required AppStore store,
    required super.child,
  }) : super(notifier: store);

  /// Retorna el [AppStore] más cercano en el árbol.
  ///
  /// Lanza [AssertionError] si no hay [StoreProvider] en el árbol.
  static AppStore of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<StoreProvider>();
    assert(
      provider != null,
      'No se encontró StoreProvider en el árbol de widgets.',
    );
    return provider!.notifier!;
  }
}
