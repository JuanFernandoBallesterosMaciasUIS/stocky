/// Constantes de dominio de la aplicación.
/// Los strings de estado y umbrales NUNCA deben escribirse
/// como literales dispersos en providers, widgets o modelos.
abstract final class StockStatus {
  static const String adequate = 'adequate';
  static const String low = 'low';

  /// Devuelve true si el estado corresponde a stock bajo.
  static bool isLow(String status) => status == low;

  /// Devuelve true si el estado corresponde a stock adecuado.
  static bool isAdequate(String status) => status == adequate;

  /// Calcula el estado en función de la cantidad y el umbral.
  static String fromQuantity(int quantity) =>
      quantity <= AppConstants.lowStockThreshold ? low : adequate;
}

/// Constantes globales de la aplicación.
abstract final class AppConstants {
  /// Umbral de unidades por debajo del cual el stock se considera bajo.
  static const int lowStockThreshold = 10;

  /// Nombre de la aplicación.
  static const String appName = 'Stocky';

  /// Título de la pantalla de inventario.
  static const String inventoryTitle = 'CONTROL DE INVENTARIOS';

  // Etiquetas de tabs de inventario
  static const String tabManualEntry = 'Registro Manual';
  static const String tabHistory = 'Historial';

  // Etiquetas de navegación inferior
  static const String navIngresos = 'Ingresos';
  static const String navCompras = 'Compras';
  static const String navGastos = 'Gastos';
  static const String navInventario = 'Inventario';
  static const String navReportes = 'Reportes';

  // Etiquetas de estado de stock
  static const String labelAdequate = 'Adecuado';
  static const String labelLowStock = 'Bajo Stock';

  // Texto del banner informativo
  static const String infoBannerText =
      'El stock se actualiza automáticamente desde tus registros de '
      'Compras (ingresos) y Ventas (salidas).';
}
