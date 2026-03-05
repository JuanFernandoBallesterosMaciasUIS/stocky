import 'package:flutter/material.dart';
import '../res/data/constants.dart';

/// Producto del inventario con control de stock, costo y vencimiento.
/// Inmutable: usar [copyWith] para crear versiones modificadas.
class InventoryProduct {
  final String id;
  final String name;
  final int stock;
  final String unit;
  final IconData icon;
  final double unitCost;
  final DateTime? expiryDate;

  /// Umbral individual de bajo stock. Por defecto usa [AppConstants.lowStockThreshold].
  final int lowStockThreshold;

  const InventoryProduct({
    required this.id,
    required this.name,
    required this.stock,
    required this.unit,
    required this.icon,
    required this.unitCost,
    this.expiryDate,
    this.lowStockThreshold = AppConstants.lowStockThreshold,
  });

  /// Calcula el estado de stock usando el umbral individual.
  String get statusKey => StockStatus.fromQuantity(stock, lowStockThreshold);

  /// Devuelve true si el stock está en niveles bajos.
  bool get isLowStock => StockStatus.isLow(statusKey);

  /// Devuelve true si el producto vence en los próximos [AppConstants.expiryWarningDays] días.
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysLeft = expiryDate!.difference(DateTime.now()).inDays;
    return daysLeft >= 0 && daysLeft <= AppConstants.expiryWarningDays;
  }

  /// Devuelve true si el producto ya está vencido.
  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  /// Valor total del stock disponible.
  double get stockValue => stock * unitCost;

  /// Crea una copia con los campos indicados modificados.
  InventoryProduct copyWith({
    String? id,
    String? name,
    int? stock,
    String? unit,
    IconData? icon,
    double? unitCost,
    DateTime? expiryDate,
    int? lowStockThreshold,
  }) {
    return InventoryProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      icon: icon ?? this.icon,
      unitCost: unitCost ?? this.unitCost,
      expiryDate: expiryDate ?? this.expiryDate,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is InventoryProduct && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
