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

  /// Calcula el estado en función de la cantidad y el umbral mínimo del producto.
  static String fromQuantity(int quantity, int threshold) =>
      quantity <= threshold ? low : adequate;
}

// ─────────────────────────────────────────────
// Métodos de pago
// ─────────────────────────────────────────────

/// Métodos de pago disponibles en la aplicación.
/// Centralizado aquí para evitar literales dispersos en formularios y modelos.
enum PaymentMethod {
  efectivo,
  credito,
  transferencia,
  tarjeta,
  nequi;

  String get label => switch (this) {
    PaymentMethod.efectivo => 'Efectivo',
    PaymentMethod.credito => 'Crédito',
    PaymentMethod.transferencia => 'Transferencia',
    PaymentMethod.tarjeta => 'Tarjeta',
    PaymentMethod.nequi => 'Nequi',
  };

  /// Devuelve true si este método genera una cuenta por cobrar/pagar.
  bool get isCredit => this == PaymentMethod.credito;

  /// Devuelve true si el pago fue en efectivo.
  bool get isCash => this == PaymentMethod.efectivo;
}

// ─────────────────────────────────────────────
// Períodos de reporte
// ─────────────────────────────────────────────

/// Períodos de filtro para reportes.
enum ReportPeriod {
  daily,
  weekly,
  monthly;

  String get label => switch (this) {
    ReportPeriod.daily => 'Diario',
    ReportPeriod.weekly => 'Semanal',
    ReportPeriod.monthly => 'Mensual',
  };
}

/// Constantes globales de la aplicación.
abstract final class AppConstants {
  /// Umbral de unidades por debajo del cual el stock se considera bajo (defecto global).
  static const int lowStockThreshold = 10;

  /// Días de antelación para alertar sobre productos próximos a vencer.
  static const int expiryWarningDays = 30;

  /// Nombre de la aplicación.
  static const String appName = 'Stocky';

  /// Título de la pantalla de inventario.
  static const String inventoryTitle = 'CONTROL DE INVENTARIOS';

  // Etiquetas de tabs de inventario
  static const String tabManualEntry = 'Registro Manual';
  static const String tabStock = 'Stock';
  static const String tabExpiring = 'Por Vencer';

  // Etiquetas de navegación inferior
  static const String navIngresos = 'Ingresos';
  static const String navCompras = 'Compras';
  static const String navGastos = 'Gastos';
  static const String navInventario = 'Inventario';
  static const String navReportes = 'Reportes';

  // Etiquetas de estado de stock
  static const String labelAdequate = 'Adecuado';
  static const String labelLowStock = 'Bajo Stock';
  static const String labelExpired = 'Vencido';
  static const String labelExpiringSoon = 'Por Vencer';

  // Texto del banner informativo de inventario
  static const String infoBannerText =
      'El stock se actualiza automáticamente desde tus registros de '
      'Compras (ingresos) y Ventas (salidas).';

  // Etiquetas de módulos
  static const String moduleIngresos = 'Ingresos';
  static const String moduleCompras = 'Compras';
  static const String moduleGastos = 'Gastos';

  // Tabs de módulos
  static const String tabVentas = 'Ventas';
  static const String tabAbonos = 'Abonos';
  static const String tabReporte = 'Reporte';
  static const String tabCompras = 'Compras';
  static const String tabProveedores = 'Proveedores';
  static const String tabGastos = 'Gastos';
  static const String tabPagos = 'Pagos';

  // Mensajes de validación
  static const String validationFillAllFields =
      'Por favor completa todos los campos.';
  static const String validationPositiveNumber =
      'Ingresa un número mayor a cero.';
  static const String validationSelectProduct = 'Selecciona un producto.';
  static const String validationInsufficientStock =
      'Stock insuficiente para esta venta.';

  // Placeholders de formularios
  static const String hintClientName = 'Nombre del cliente';
  static const String hintSupplierName = 'Nombre del proveedor';
  static const String hintExpenseDescription = 'Descripción del gasto';
  static const String hintProductName = 'Nombre del producto';
  static const String hintQuantity = 'Cantidad';
  static const String hintUnitPrice = 'Precio unitario';
  static const String hintUnitCost = 'Costo unitario';
  static const String hintAmount = 'Monto';
  static const String hintUnit = 'Unidad (ej. und., kg, paq.)';
  static const String hintNotes = 'Notas (opcional)';

  // Botones
  static const String btnRegister = 'Registrar';
  static const String btnSave = 'Guardar';

  // Estado vacío
  static const String emptyList = 'No hay registros aún.';

  // ─── Módulo Reportes ─────────────────────────────
  // Tabs
  static const String tabFlujoCaja = 'Flujo de Caja';
  static const String tabCuentasCobrar = 'Por Cobrar';
  static const String tabCuentasPagar = 'Por Pagar';
  static const String tabEstadoResultado = 'Resultado';

  // Métricas de Flujo de Caja
  static const String labelIngresosCash = 'Ingresos Efectivo';
  static const String labelComprasCash = 'Compras Efectivo';
  static const String labelGastosCash = 'Gastos Efectivo';
  static const String labelTotalCaja = 'Total en Caja';

  // Métricas de Estado de Resultado
  static const String labelTotalIngresos = 'Total Ingresos';
  static const String labelTotalCosto = 'Total Costo';
  static const String labelTotalGastos = 'Total Gastos';
  static const String labelUtilidadPerdida = 'Utilidad / Pérdida';

  // Métricas de Cuentas por Cobrar
  static const String labelCreditSales = 'Ventas a Crédito';
  static const String labelPaymentsReceived = 'Abonos Recibidos';
  static const String labelSaldoPendiente = 'Saldo Pendiente';

  // Métricas de Cuentas por Pagar
  static const String labelCreditPurchases = 'Compras a Crédito';
  static const String labelSupplierPayments = 'Pagos a Proveedores';
  static const String labelCreditExpenses = 'Gastos a Crédito';
  static const String labelExpensePayments = 'Pagos de Gastos';
  static const String labelTotalAPagar = 'Total a Pagar';

  // Cabeceras de sección
  static const String sectionCreditSales = 'DETALLE VENTAS A CRÉDITO';
  static const String sectionCreditPurchases = 'DETALLE COMPRAS A CRÉDITO';
  static const String sectionCreditExpenses = 'DETALLE GASTOS A CRÉDITO';

  // Estado vacío
  static const String emptyReportePeriod = 'Sin movimientos en este período.';
  static const String emptyReporteGlobal = 'Sin registros a la fecha.';
}
