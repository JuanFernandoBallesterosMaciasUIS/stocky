import '../res/data/constants.dart';

/// Registro de una compra (adquisición de mercancía).
/// Al guardarse en el store, incrementa automáticamente el stock del producto.
/// Inmutable: usar [copyWith] para modificar.
class Purchase {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final PaymentMethod paymentMethod;
  final DateTime date;

  const Purchase({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.paymentMethod,
    required this.date,
  });

  /// Costo total de esta compra.
  double get total => quantity * unitPrice;

  /// Devuelve true si genera una cuenta por pagar al proveedor.
  bool get isCredit => paymentMethod.isCredit;

  Purchase copyWith({
    String? id,
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    PaymentMethod? paymentMethod,
    DateTime? date,
  }) {
    return Purchase(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Purchase && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
