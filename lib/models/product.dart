import 'package:flutter/material.dart';
import '../res/data/constants.dart';

/// Modelo de producto del inventario.
/// Inmutable: usar [copyWith] para crear versiones modificadas.
class Product {
  final String id;
  final String name;
  final int stock;
  final String unit;
  final IconData icon;

  const Product({
    required this.id,
    required this.name,
    required this.stock,
    required this.unit,
    required this.icon,
  });

  /// Calcula el estado de stock usando la lógica centralizada en [StockStatus].
  String get statusKey => StockStatus.fromQuantity(stock);

  /// Devuelve true si el stock está en niveles bajos.
  bool get isLowStock => StockStatus.isLow(statusKey);

  /// Crea una copia con los campos indicados modificados.
  Product copyWith({
    String? id,
    String? name,
    int? stock,
    String? unit,
    IconData? icon,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      icon: icon ?? this.icon,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Product && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
