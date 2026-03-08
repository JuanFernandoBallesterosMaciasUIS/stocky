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

  /// Devuelve true si el pago fue en efectivo (solo billete/moneda).
  bool get isCash => this == PaymentMethod.efectivo;

  /// Devuelve true si el pago se hizo al contado (no genera deuda pendiente).
  /// Incluye efectivo, Nequi, transferencia y tarjeta.
  bool get isNonCredit => !isCredit;
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
  static const String inventoryTitle = 'Inventario';

  // Etiquetas de tabs de inventario
  static const String tabManualEntry = 'Registro';
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
  static const String labelStockDisponible = 'Stock disponible: ';

  // Voz — configuración del reconocimiento
  static const Duration voicePauseFor = Duration(seconds: 3);

  // Voz — etiquetas de la interfaz de dictado
  static const String labelVoiceHint = 'Toca el micrófono para dictar';
  static const String labelVoiceHintLong = 'Di: "2 arroces en efectivo"';
  static const String labelListening = 'Escuchando...';
  static const String labelVoiceNoMatch =
      'No encontré el producto. Intenta de nuevo.';
  static const String labelVoiceRetry = 'Reintentar';
  static const String labelVoiceConfirm = 'Confirmar';
  static const String labelStopListening = 'Detener';
  static const String labelVoiceEditTitle = 'Revisá y corregí';
  static const String labelVoiceRetryListening = 'Volver a escuchar';

  // Hoja de registro rápido — Ventas
  static const String labelNewSale = 'Nueva venta';
  static const String labelUnitPrice = 'Precio unitario';
  static const String labelSinStock = 'Sin stock';

  // Hoja de registro rápido — Abonos
  static const String labelNewAbono = 'Nuevo abono';
  static const String labelAbonoVoiceHintLong =
      'Di: "María cincuenta mil nequi"';
  static const String labelVoiceNoMatchAbono =
      'No pude entender el abono. Intenta de nuevo.';
  static const String labelKnownClients = 'Clientes anteriores';
  static const String labelNewClientHint = 'O escribe un nombre nuevo';

  // Hoja de registro rápido — Compras
  static const String labelNewCompra = 'Nueva compra';
  static const String labelVoiceHintCompraLong = 'Di: "5 arroces a tres mil"';
  static const String labelVoiceNoMatchCompra =
      'No entendí la compra. Intenta de nuevo.';

  // Hoja de registro rápido — Proveedores
  static const String labelNewProveedor = 'Nuevo pago a proveedor';
  static const String labelVoiceHintProveedorLong =
      'Di: "Juan cien mil efectivo"';
  static const String labelVoiceNoMatchProveedor =
      'No entendí el pago. Intenta de nuevo.';
  static const String labelKnownSuppliers = 'Proveedores anteriores';

  // Hoja de registro rápido — Gastos
  static const String labelNewGasto = 'Nuevo gasto';
  static const String labelVoiceHintGastoLong = 'Di: "arriendo ochenta mil"';
  static const String labelVoiceNoMatchGasto =
      'No entendí el gasto. Intenta de nuevo.';

  // Hoja de registro rápido — Pagos de gasto
  static const String labelNewPagoGasto = 'Nuevo pago de gasto';
  static const String labelVoiceHintPagoLong =
      'Di: "servicios treinta mil nequi"';
  static const String labelVoiceNoMatchPago =
      'No entendí el pago. Intenta de nuevo.';

  // Hoja de registro rápido — Inventario
  static const String labelNewProducto = 'Nuevo producto';
  static const String labelVoiceHintProductoLong = 'Di: "arroz 100 kilos 5000"';
  static const String labelVoiceNoMatchProducto =
      'No entendí el producto. Intenta de nuevo.';
  static const String labelHintExpiry = 'Fecha de vencimiento (opcional)';
  static const String labelNoExpiryDate = 'Sin fecha de vencimiento';
  static const String hintLowStockThreshold = 'Alerta de bajo stock (und.)';

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
  static const String labelEditProduct = 'Editar producto';
  static const String btnCancel = 'Cancelar';
  static const String btnAccept = 'Aceptar';
  static const String labelQtyDialogTitle = 'Ingresá la cantidad';

  // Estado vacío
  static const String emptyList = 'No hay registros aún.';

  // ─── Módulo Reportes ─────────────────────────────
  // Tabs
  static const String tabFlujoCaja = 'Flujo de Caja';
  static const String tabCuentasCobrar = 'Por Cobrar';
  static const String tabCuentasPagar = 'Por Pagar';
  static const String tabEstadoResultado = 'Resultado';
  static const String tabKardex = 'Kardex';

  // Métricas de Flujo de Caja
  /// "Al contado" = efectivo + nequi + transferencia + tarjeta (sin crédito)
  static const String labelIngresosCash = 'Ingresos al Contado';
  static const String labelComprasCash = 'Compras al Contado';
  static const String labelGastosCash = 'Gastos al Contado';
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

  // ─── Kardex ──────────────────────────────────────
  static const String labelKardexProducto = 'PRODUCTO';
  static const String labelKardexEntrada = 'Entrada';
  static const String labelKardexSalida = 'Salida';
  static const String labelKardexExistencia = 'Existencia';
  static const String labelKardexValor = 'Valor';
  static const String labelKardexTotal = 'TOTAL';
  static const String emptyKardex = 'Sin productos en inventario.';
}
