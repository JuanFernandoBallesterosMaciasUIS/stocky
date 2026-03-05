import '../res/data/constants.dart';

/// Pago realizado a un proveedor contra una compra a crédito.
/// Inmutable: usar [copyWith] para modificar.
class SupplierPayment {
  final String id;
  final String supplierName;

  /// ID de la compra relacionada, si aplica.
  final String? relatedPurchaseId;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? notes;
  final DateTime date;

  const SupplierPayment({
    required this.id,
    required this.supplierName,
    this.relatedPurchaseId,
    required this.amount,
    required this.paymentMethod,
    this.notes,
    required this.date,
  });

  SupplierPayment copyWith({
    String? id,
    String? supplierName,
    String? relatedPurchaseId,
    double? amount,
    PaymentMethod? paymentMethod,
    String? notes,
    DateTime? date,
  }) {
    return SupplierPayment(
      id: id ?? this.id,
      supplierName: supplierName ?? this.supplierName,
      relatedPurchaseId: relatedPurchaseId ?? this.relatedPurchaseId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      date: date ?? this.date,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SupplierPayment && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
