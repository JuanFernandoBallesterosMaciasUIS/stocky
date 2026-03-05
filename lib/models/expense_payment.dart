import '../res/data/constants.dart';

/// Pago realizado contra un gasto registrado a crédito.
/// Inmutable: usar [copyWith] para modificar.
class ExpensePayment {
  final String id;
  final String description;

  /// ID del gasto relacionado, si aplica.
  final String? relatedExpenseId;
  final double amount;
  final PaymentMethod paymentMethod;
  final DateTime date;

  const ExpensePayment({
    required this.id,
    required this.description,
    this.relatedExpenseId,
    required this.amount,
    required this.paymentMethod,
    required this.date,
  });

  ExpensePayment copyWith({
    String? id,
    String? description,
    String? relatedExpenseId,
    double? amount,
    PaymentMethod? paymentMethod,
    DateTime? date,
  }) {
    return ExpensePayment(
      id: id ?? this.id,
      description: description ?? this.description,
      relatedExpenseId: relatedExpenseId ?? this.relatedExpenseId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ExpensePayment && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
