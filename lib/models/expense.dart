import '../res/data/constants.dart';

/// Registro de un gasto operativo del negocio.
/// Inmutable: usar [copyWith] para modificar.
class Expense {
  final String id;
  final String description;
  final double amount;
  final PaymentMethod paymentMethod;
  final DateTime date;

  const Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.paymentMethod,
    required this.date,
  });

  /// Devuelve true si genera una cuenta por pagar.
  bool get isCredit => paymentMethod.isCredit;

  /// Devuelve true si fue pagado en efectivo.
  bool get isCash => paymentMethod.isCash;

  Expense copyWith({
    String? id,
    String? description,
    double? amount,
    PaymentMethod? paymentMethod,
    DateTime? date,
  }) {
    return Expense(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Expense && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
