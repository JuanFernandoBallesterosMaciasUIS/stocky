/// Resumen de movimientos de un producto en el kardex.
///
/// Agrega las entradas (compras), salidas (ventas) y refleja la
/// existencia actual más su valorización al costo unitario vigente.
///
/// Inmutable: todos los campos son finales.
class KardexEntry {
  const KardexEntry({
    required this.productId,
    required this.productName,
    required this.entradas,
    required this.salidas,
    required this.existencia,
    required this.unitCost,
  });

  final String productId;
  final String productName;

  /// Total de unidades ingresadas por compras.
  final int entradas;

  /// Total de unidades egresadas por ventas.
  final int salidas;

  /// Stock actual del producto (fuente de verdad del inventario).
  final int existencia;

  /// Costo unitario vigente del producto.
  final double unitCost;

  /// Valorización total: existencia × costo unitario.
  double get valorTotal => existencia * unitCost;
}
