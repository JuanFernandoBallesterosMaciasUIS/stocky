import '../res/data/constants.dart';

/// Abono de un cliente contra una venta a crédito.
/// Inmutable: usar [copyWith] para modificar.
class ClientPayment {
  final String id;
  final String clientName;

  /// ID de la venta relacionada, si aplica.
  final String? relatedSaleId;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? notes;
  final DateTime date;

  const ClientPayment({
    required this.id,
    required this.clientName,
    this.relatedSaleId,
    required this.amount,
    required this.paymentMethod,
    this.notes,
    required this.date,
  });

  ClientPayment copyWith({
    String? id,
    String? clientName,
    String? relatedSaleId,
    double? amount,
    PaymentMethod? paymentMethod,
    String? notes,
    DateTime? date,
  }) {
    return ClientPayment(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      relatedSaleId: relatedSaleId ?? this.relatedSaleId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      date: date ?? this.date,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ClientPayment && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
