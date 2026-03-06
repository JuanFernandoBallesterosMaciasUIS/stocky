import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/client_payment.dart';
import '../models/expense.dart';
import '../models/expense_payment.dart';
import '../models/product.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import '../models/supplier_payment.dart';
import '../res/data/constants.dart';
import '../store/app_store.dart';

/// Servicio de persistencia local.
///
/// Responsabilidad única: serializar y deserializar el estado de [AppStore]
/// usando [SharedPreferences]. No contiene lógica de negocio ni de UI.
///
/// Separación de responsabilidades (SoC): la lógica de parseo
/// vive aquí y no en los modelos ni en el store.
abstract final class PersistenceService {
  // ── Claves de almacenamiento (sin strings en código) ─────────────────────────
  static const String _kProducts = 'stocky_v1_products';
  static const String _kSales = 'stocky_v1_sales';
  static const String _kClientPayments = 'stocky_v1_client_payments';
  static const String _kPurchases = 'stocky_v1_purchases';
  static const String _kSupplierPayments = 'stocky_v1_supplier_payments';
  static const String _kExpenses = 'stocky_v1_expenses';
  static const String _kExpensePayments = 'stocky_v1_expense_payments';

  // ── API pública ────────────────────────────────────────────────────────────────

  /// Intenta cargar el estado guardado. Devuelve [null] si no hay datos previos
  /// o si la lectura falla, para que el caller use [AppStore()] con datos iniciales.
  static Future<AppStore?> tryLoad() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawProducts = prefs.getString(_kProducts);
      if (rawProducts == null) return null; // primera ejecución

      return AppStore.fromSnapshot(
        products: _decodeProducts(rawProducts),
        sales: _decodeList(prefs.getString(_kSales), _saleFromJson),
        clientPayments: _decodeList(
          prefs.getString(_kClientPayments),
          _clientPaymentFromJson,
        ),
        purchases: _decodeList(prefs.getString(_kPurchases), _purchaseFromJson),
        supplierPayments: _decodeList(
          prefs.getString(_kSupplierPayments),
          _supplierPaymentFromJson,
        ),
        expenses: _decodeList(prefs.getString(_kExpenses), _expenseFromJson),
        expensePayments: _decodeList(
          prefs.getString(_kExpensePayments),
          _expensePaymentFromJson,
        ),
      );
    } catch (_) {
      // Ante cualquier corrupción de datos se arranca con estado inicial.
      return null;
    }
  }

  /// Persiste el estado completo del [store] en [SharedPreferences].
  /// Se ejecuta de forma asíncrona; los errores se descartan silenciosamente
  /// para no interrumpir el flujo de UI (la app sigue funcionando en memoria).
  static Future<void> save(AppStore store) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_kProducts, _encodeProducts(store.products)),
        prefs.setString(_kSales, _encodeList(store.sales, _saleToJson)),
        prefs.setString(
          _kClientPayments,
          _encodeList(store.clientPayments, _clientPaymentToJson),
        ),
        prefs.setString(
          _kPurchases,
          _encodeList(store.purchases, _purchaseToJson),
        ),
        prefs.setString(
          _kSupplierPayments,
          _encodeList(store.supplierPayments, _supplierPaymentToJson),
        ),
        prefs.setString(
          _kExpenses,
          _encodeList(store.expenses, _expenseToJson),
        ),
        prefs.setString(
          _kExpensePayments,
          _encodeList(store.expensePayments, _expensePaymentToJson),
        ),
      ]);
    } catch (_) {
      // Error de escritura: se tolera, los datos siguen en memoria.
    }
  }

  // ── Helpers genéricos ─────────────────────────────────────────────────────────

  static String _encodeList<T>(
    List<T> list,
    Map<String, dynamic> Function(T) toJson,
  ) => jsonEncode(list.map(toJson).toList(growable: false));

  static List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }

  // ── IconData serialización ────────────────────────────────────────────────────
  // Se almacena el código del glifo y la familia de fuente para reconstruir
  // el IconData sin depender de constantes predefinidas.

  static Map<String, dynamic> _iconToJson(IconData icon) => {
    'cp': icon.codePoint,
    'ff': icon.fontFamily ?? 'MaterialIcons',
  };

  static IconData _iconFromJson(Map<String, dynamic> m) => IconData(
    (m['cp'] as num? ?? Icons.inventory_2.codePoint).toInt(),
    fontFamily: (m['ff'] as String?) ?? 'MaterialIcons',
  );

  // ── InventoryProduct ──────────────────────────────────────────────────────────

  static String _encodeProducts(List<InventoryProduct> list) =>
      jsonEncode(list.map(_productToJson).toList(growable: false));

  static List<InventoryProduct> _decodeProducts(String raw) {
    if (raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_productFromJson)
        .toList(growable: false);
  }

  static Map<String, dynamic> _productToJson(InventoryProduct p) => {
    'id': p.id,
    'name': p.name,
    'stock': p.stock,
    'unit': p.unit,
    'icon': _iconToJson(p.icon),
    'unitCost': p.unitCost,
    'expiryDate': p.expiryDate?.toIso8601String(),
    'lowStockThreshold': p.lowStockThreshold,
  };

  /// Migración v1→v2: 'bolsa' se renombró a 'unidad'.
  static String _migrateUnit(String raw) => raw == 'bolsa' ? 'unidad' : raw;

  static InventoryProduct _productFromJson(Map<String, dynamic> m) =>
      InventoryProduct(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? '',
        stock: (m['stock'] as num? ?? 0).toInt(),
        unit: _migrateUnit(m['unit'] as String? ?? ''),
        icon: _iconFromJson((m['icon'] as Map<String, dynamic>?) ?? {}),
        unitCost: (m['unitCost'] as num? ?? 0).toDouble(),
        expiryDate: DateTime.tryParse(m['expiryDate'] as String? ?? ''),
        lowStockThreshold:
            (m['lowStockThreshold'] as num? ?? AppConstants.lowStockThreshold)
                .toInt(),
      );

  // ── Sale ──────────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _saleToJson(Sale s) => {
    'id': s.id,
    'productId': s.productId,
    'productName': s.productName,
    'quantity': s.quantity,
    'unitPrice': s.unitPrice,
    'unitCost': s.unitCost,
    'paymentMethod': s.paymentMethod.name,
    'date': s.date.toIso8601String(),
  };

  static Sale _saleFromJson(Map<String, dynamic> m) => Sale(
    id: m['id'] as String? ?? '',
    productId: m['productId'] as String? ?? '',
    productName: m['productName'] as String? ?? '',
    quantity: (m['quantity'] as num? ?? 0).toInt(),
    unitPrice: (m['unitPrice'] as num? ?? 0).toDouble(),
    unitCost: (m['unitCost'] as num? ?? 0).toDouble(),
    paymentMethod: _paymentMethod(m['paymentMethod'] as String?),
    date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
  );

  // ── ClientPayment ─────────────────────────────────────────────────────────────

  static Map<String, dynamic> _clientPaymentToJson(ClientPayment p) => {
    'id': p.id,
    'clientName': p.clientName,
    'relatedSaleId': p.relatedSaleId,
    'amount': p.amount,
    'paymentMethod': p.paymentMethod.name,
    'notes': p.notes,
    'date': p.date.toIso8601String(),
  };

  static ClientPayment _clientPaymentFromJson(Map<String, dynamic> m) =>
      ClientPayment(
        id: m['id'] as String? ?? '',
        clientName: m['clientName'] as String? ?? '',
        relatedSaleId: m['relatedSaleId'] as String?,
        amount: (m['amount'] as num? ?? 0).toDouble(),
        paymentMethod: _paymentMethod(m['paymentMethod'] as String?),
        notes: m['notes'] as String?,
        date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
      );

  // ── Purchase ──────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _purchaseToJson(Purchase p) => {
    'id': p.id,
    'productId': p.productId,
    'productName': p.productName,
    'quantity': p.quantity,
    'unitPrice': p.unitPrice,
    'paymentMethod': p.paymentMethod.name,
    'date': p.date.toIso8601String(),
  };

  static Purchase _purchaseFromJson(Map<String, dynamic> m) => Purchase(
    id: m['id'] as String? ?? '',
    productId: m['productId'] as String? ?? '',
    productName: m['productName'] as String? ?? '',
    quantity: (m['quantity'] as num? ?? 0).toInt(),
    unitPrice: (m['unitPrice'] as num? ?? 0).toDouble(),
    paymentMethod: _paymentMethod(m['paymentMethod'] as String?),
    date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
  );

  // ── SupplierPayment ───────────────────────────────────────────────────────────

  static Map<String, dynamic> _supplierPaymentToJson(SupplierPayment p) => {
    'id': p.id,
    'supplierName': p.supplierName,
    'relatedPurchaseId': p.relatedPurchaseId,
    'amount': p.amount,
    'paymentMethod': p.paymentMethod.name,
    'notes': p.notes,
    'date': p.date.toIso8601String(),
  };

  static SupplierPayment _supplierPaymentFromJson(Map<String, dynamic> m) =>
      SupplierPayment(
        id: m['id'] as String? ?? '',
        supplierName: m['supplierName'] as String? ?? '',
        relatedPurchaseId: m['relatedPurchaseId'] as String?,
        amount: (m['amount'] as num? ?? 0).toDouble(),
        paymentMethod: _paymentMethod(m['paymentMethod'] as String?),
        notes: m['notes'] as String?,
        date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
      );

  // ── Expense ───────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _expenseToJson(Expense e) => {
    'id': e.id,
    'description': e.description,
    'amount': e.amount,
    'paymentMethod': e.paymentMethod.name,
    'date': e.date.toIso8601String(),
  };

  static Expense _expenseFromJson(Map<String, dynamic> m) => Expense(
    id: m['id'] as String? ?? '',
    description: m['description'] as String? ?? '',
    amount: (m['amount'] as num? ?? 0).toDouble(),
    paymentMethod: _paymentMethod(m['paymentMethod'] as String?),
    date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
  );

  // ── ExpensePayment ────────────────────────────────────────────────────────────

  static Map<String, dynamic> _expensePaymentToJson(ExpensePayment p) => {
    'id': p.id,
    'description': p.description,
    'relatedExpenseId': p.relatedExpenseId,
    'amount': p.amount,
    'paymentMethod': p.paymentMethod.name,
    'date': p.date.toIso8601String(),
  };

  static ExpensePayment _expensePaymentFromJson(Map<String, dynamic> m) =>
      ExpensePayment(
        id: m['id'] as String? ?? '',
        description: m['description'] as String? ?? '',
        relatedExpenseId: m['relatedExpenseId'] as String?,
        amount: (m['amount'] as num? ?? 0).toDouble(),
        paymentMethod: _paymentMethod(m['paymentMethod'] as String?),
        date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
      );

  // ── Enum helper ───────────────────────────────────────────────────────────────

  /// Convierte un string al enum [PaymentMethod] de forma defensiva:
  /// si el valor es nulo o desconocido, devuelve [PaymentMethod.efectivo].
  static PaymentMethod _paymentMethod(String? name) {
    if (name == null || name.isEmpty) return PaymentMethod.efectivo;
    return PaymentMethod.values.firstWhere(
      (e) => e.name == name,
      orElse: () => PaymentMethod.efectivo,
    );
  }
}
