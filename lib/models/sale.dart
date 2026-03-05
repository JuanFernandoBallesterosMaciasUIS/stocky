import '../res/data/constants.dart';

/// Registro de una venta (ingreso por actividad comercial).
/// Inmutable: usar [copyWith] para modificar.
class Sale {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double unitCost;
  final PaymentMethod paymentMethod;
  final DateTime date;

  const Sale({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
    required this.paymentMethod,
    required this.date,
  });

  /// Ingreso total de esta venta.
  double get total => quantity * unitPrice;

  /// Costo total asociado a esta venta.
  double get totalCost => quantity * unitCost;

  /// Utilidad bruta de esta venta.
  double get grossProfit => total - totalCost;

  /// Devuelve true si genera una cuenta por cobrar.
  bool get isCredit => paymentMethod.isCredit;

  Sale copyWith({
    String? id,
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? unitCost,
    PaymentMethod? paymentMethod,
    DateTime? date,
  }) {
    return Sale(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      unitCost: unitCost ?? this.unitCost,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Sale && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
