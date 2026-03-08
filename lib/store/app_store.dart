import 'package:flutter/material.dart';

import '../models/client_payment.dart';
import '../models/expense.dart';
import '../models/expense_payment.dart';
import '../models/kardex_entry.dart';
import '../models/product.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import '../models/supplier_payment.dart';
import '../res/data/constants.dart';

/// Estado central de la aplicación.
///
/// Responsabilidades:
/// - Mantener las listas inmutables de cada entidad de negocio.
/// - Notificar a los widgets suscritos cuando el estado cambia.
/// - Aplicar las reglas de negocio al registrar operaciones (ajuste de stock).
///
/// No contiene lógica de UI.
class AppStore extends ChangeNotifier {
  // ── Inventario ──────────────────────────────────────────────────────────────
  List<InventoryProduct> _products;

  // ── Ingresos ─────────────────────────────────────────────────────────────────
  List<Sale> _sales;
  List<ClientPayment> _clientPayments;

  // ── Compras ───────────────────────────────────────────────────────────────────
  List<Purchase> _purchases;
  List<SupplierPayment> _supplierPayments;

  // ── Gastos ────────────────────────────────────────────────────────────────────
  List<Expense> _expenses;
  List<ExpensePayment> _expensePayments;

  AppStore({
    List<InventoryProduct>? products,
    List<Sale>? sales,
    List<ClientPayment>? clientPayments,
    List<Purchase>? purchases,
    List<SupplierPayment>? supplierPayments,
    List<Expense>? expenses,
    List<ExpensePayment>? expensePayments,
  }) : _products = products ?? _initialProducts(),
       _sales = sales ?? _initialSales(),
       _clientPayments = clientPayments ?? const [],
       _purchases = purchases ?? _initialPurchases(),
       _supplierPayments = supplierPayments ?? const [],
       _expenses = expenses ?? _initialExpenses(),
       _expensePayments = expensePayments ?? const [];

  /// Constructor para restaurar el estado desde datos persistidos.
  /// No aplica datos iniciales de ejemplo; usa exactamente lo recibido.
  AppStore.fromSnapshot({
    required List<InventoryProduct> products,
    required List<Sale> sales,
    required List<ClientPayment> clientPayments,
    required List<Purchase> purchases,
    required List<SupplierPayment> supplierPayments,
    required List<Expense> expenses,
    required List<ExpensePayment> expensePayments,
  }) : _products = products,
       _sales = sales,
       _clientPayments = clientPayments,
       _purchases = purchases,
       _supplierPayments = supplierPayments,
       _expenses = expenses,
       _expensePayments = expensePayments;

  // ── Persistencia ──────────────────────────────────────────────────────────────

  /// Callback invocado después de cada mutación para persistir el estado.
  /// Se inyecta desde main.dart (inversión de dependencia) para mantener
  /// el store desacoplado del mecanismo de almacenamiento.
  VoidCallback? _persistCallback;

  /// Registra el callback que se llamará tras cada mutación del estado.
  void setPersistCallback(VoidCallback callback) {
    _persistCallback = callback;
  }

  /// Notifica a los listeners y dispara la persistencia.
  void _onMutated() {
    notifyListeners();
    _persistCallback?.call();
  }

  // ── Getters ──────────────────────────────────────────────────────────────────
  List<InventoryProduct> get products => List.unmodifiable(_products);
  List<Sale> get sales => List.unmodifiable(_sales);
  List<ClientPayment> get clientPayments => List.unmodifiable(_clientPayments);

  /// Lista ordenada de nombres de clientes únicos, derivada de los abonos.
  /// Usada para sugerir clientes en el formulario de nuevo abono.
  List<String> get knownClientNames {
    final seen = <String>{};
    final names = <String>[];
    for (final p in _clientPayments) {
      final name = p.clientName.trim();
      if (name.isNotEmpty && seen.add(name)) names.add(name);
    }
    names.sort();
    return List.unmodifiable(names);
  }

  /// Lista ordenada de nombres de proveedores únicos, derivada de los pagos
  /// a proveedores. Usada para sugerir proveedores en el formulario de pago.
  List<String> get knownSupplierNames {
    final seen = <String>{};
    final names = <String>[];
    for (final p in _supplierPayments) {
      final name = p.supplierName.trim();
      if (name.isNotEmpty && seen.add(name)) names.add(name);
    }
    names.sort();
    return List.unmodifiable(names);
  }

  List<Purchase> get purchases => List.unmodifiable(_purchases);
  List<SupplierPayment> get supplierPayments =>
      List.unmodifiable(_supplierPayments);
  List<Expense> get expenses => List.unmodifiable(_expenses);
  List<ExpensePayment> get expensePayments =>
      List.unmodifiable(_expensePayments);

  // ── Computed ──────────────────────────────────────────────────────────────────
  List<InventoryProduct> get lowStockProducts =>
      _products.where((p) => p.isLowStock).toList(growable: false);

  List<InventoryProduct> get expiringSoonProducts => _products
      .where((p) => p.isExpiringSoon && !p.isExpired)
      .toList(growable: false);

  List<InventoryProduct> get expiredProducts =>
      _products.where((p) => p.isExpired).toList(growable: false);

  /// Kardex: una entrada por cada producto del inventario con sus totales
  /// de entradas (compras) y salidas (ventas) acumuladas.
  ///
  /// Complejidad O(compras + ventas + productos): se pre-agregan en mapas
  /// antes de iterar los productos, sin bucles anidados.
  List<KardexEntry> get kardexEntries {
    // Pre-agregar entradas por producto id en O(compras)
    final entradasMap = <String, int>{};
    for (final p in _purchases) {
      entradasMap[p.productId] = (entradasMap[p.productId] ?? 0) + p.quantity;
    }
    // Pre-agregar salidas por producto id en O(ventas)
    final salidasMap = <String, int>{};
    for (final s in _sales) {
      salidasMap[s.productId] = (salidasMap[s.productId] ?? 0) + s.quantity;
    }
    return [
      for (final product in _products)
        KardexEntry(
          productId: product.id,
          productName: product.name,
          entradas: entradasMap[product.id] ?? 0,
          salidas: salidasMap[product.id] ?? 0,
          existencia: product.stock,
          unitCost: product.unitCost,
        ),
    ];
  }

  List<Sale> salesForPeriod(ReportPeriod period, DateTime reference) => _sales
      .where((s) => _isInPeriod(s.date, reference, period))
      .toList(growable: false);

  List<Purchase> purchasesForPeriod(ReportPeriod period, DateTime reference) =>
      _purchases
          .where((p) => _isInPeriod(p.date, reference, period))
          .toList(growable: false);

  List<Expense> expensesForPeriod(ReportPeriod period, DateTime reference) =>
      _expenses
          .where((e) => _isInPeriod(e.date, reference, period))
          .toList(growable: false);

  // ── Mutations: Inventario ─────────────────────────────────────────────────────
  void addInventoryProduct(InventoryProduct product) {
    _products = [..._products, product];
    _onMutated();
  }

  void updateInventoryProduct(InventoryProduct updated) {
    _products = [
      for (final p in _products)
        if (p.id == updated.id) updated else p,
    ];
    _onMutated();
  }

  // ── Mutations: Ingresos ───────────────────────────────────────────────────────
  void addSale(Sale sale) {
    _sales = [..._sales, sale];
    _decrementStock(sale.productId, sale.quantity);
    _onMutated();
  }

  void addClientPayment(ClientPayment payment) {
    _clientPayments = [..._clientPayments, payment];
    _onMutated();
  }

  // ── Mutations: Compras ────────────────────────────────────────────────────────
  void addPurchase(Purchase purchase) {
    _purchases = [..._purchases, purchase];
    _incrementStock(purchase.productId, purchase.quantity);
    _onMutated();
  }

  void addSupplierPayment(SupplierPayment payment) {
    _supplierPayments = [..._supplierPayments, payment];
    _onMutated();
  }

  // ── Mutations: Gastos ─────────────────────────────────────────────────────────
  void addExpense(Expense expense) {
    _expenses = [..._expenses, expense];
    _onMutated();
  }

  void addExpensePayment(ExpensePayment payment) {
    _expensePayments = [..._expensePayments, payment];
    _onMutated();
  }

  // ── Private helpers ───────────────────────────────────────────────────────────
  void _decrementStock(String productId, int qty) {
    _products = [
      for (final p in _products)
        if (p.id == productId)
          p.copyWith(stock: (p.stock - qty).clamp(0, double.infinity).toInt())
        else
          p,
    ];
  }

  void _incrementStock(String productId, int qty) {
    _products = [
      for (final p in _products)
        if (p.id == productId) p.copyWith(stock: p.stock + qty) else p,
    ];
  }

  static bool _isInPeriod(
    DateTime date,
    DateTime reference,
    ReportPeriod period,
  ) {
    switch (period) {
      case ReportPeriod.daily:
        return date.year == reference.year &&
            date.month == reference.month &&
            date.day == reference.day;
      case ReportPeriod.weekly:
        final start = reference.subtract(Duration(days: reference.weekday - 1));
        final s = DateTime(start.year, start.month, start.day);
        final e = s.add(const Duration(days: 6));
        final d = DateTime(date.year, date.month, date.day);
        return !d.isBefore(s) && !d.isAfter(e);
      case ReportPeriod.monthly:
        return date.year == reference.year && date.month == reference.month;
    }
  }

  // ── Datos iniciales del examen ────────────────────────────────────────────────
  static const _ref = '2025-06-01';

  static DateTime _d(String iso) => DateTime.parse(iso);

  static List<InventoryProduct> _initialProducts() {
    return const [
      InventoryProduct(
        id: 'p1',
        name: 'Café Volcán en granos 250gr',
        stock: 50,
        unit: 'unidad',
        icon: Icons.coffee,
        unitCost: 11460,
      ),
      InventoryProduct(
        id: 'p2',
        name: 'Café Finca en grano 454gr',
        stock: 50,
        unit: 'unidad',
        icon: Icons.coffee,
        unitCost: 45780,
      ),
      InventoryProduct(
        id: 'p3',
        name: 'Café Mujeres Cafeteras en granos 454gr',
        stock: 50,
        unit: 'unidad',
        icon: Icons.coffee,
        unitCost: 45780,
      ),
      InventoryProduct(
        id: 'p4',
        name: 'Café Origen Nariño en granos 454gr',
        stock: 50,
        unit: 'unidad',
        icon: Icons.coffee,
        unitCost: 45780,
      ),
      InventoryProduct(
        id: 'p5',
        name: 'Café Colina en grano 454gr',
        stock: 50,
        unit: 'unidad',
        icon: Icons.coffee,
        unitCost: 36650,
      ),
    ];
  }

  static List<Purchase> _initialPurchases() {
    return [
      Purchase(
        id: 'c1',
        productId: 'p1',
        productName: 'Café Volcán en granos 250gr',
        quantity: 100,
        unitPrice: 11460,
        paymentMethod: PaymentMethod.efectivo,
        date: _d(_ref),
      ),
      Purchase(
        id: 'c2',
        productId: 'p2',
        productName: 'Café Finca en grano 454gr',
        quantity: 150,
        unitPrice: 45780,
        paymentMethod: PaymentMethod.nequi,
        date: _d(_ref),
      ),
      Purchase(
        id: 'c3',
        productId: 'p3',
        productName: 'Café Mujeres Cafeteras en granos 454gr',
        quantity: 200,
        unitPrice: 45780,
        paymentMethod: PaymentMethod.nequi,
        date: _d(_ref),
      ),
      Purchase(
        id: 'c4',
        productId: 'p4',
        productName: 'Café Origen Nariño en granos 454gr',
        quantity: 250,
        unitPrice: 45780,
        paymentMethod: PaymentMethod.credito,
        date: _d(_ref),
      ),
      Purchase(
        id: 'c5',
        productId: 'p5',
        productName: 'Café Colina en grano 454gr',
        quantity: 300,
        unitPrice: 36650,
        paymentMethod: PaymentMethod.credito,
        date: _d(_ref),
      ),
    ];
  }

  static List<Sale> _initialSales() {
    return [
      Sale(
        id: 'v1',
        productId: 'p1',
        productName: 'Café Volcán en granos 250gr',
        quantity: 50,
        unitPrice: 31460,
        unitCost: 11460,
        paymentMethod: PaymentMethod.efectivo,
        date: _d(_ref),
      ),
      Sale(
        id: 'v2',
        productId: 'p2',
        productName: 'Café Finca en grano 454gr',
        quantity: 100,
        unitPrice: 65780,
        unitCost: 45780,
        paymentMethod: PaymentMethod.nequi,
        date: _d(_ref),
      ),
      Sale(
        id: 'v3',
        productId: 'p3',
        productName: 'Café Mujeres Cafeteras en granos 454gr',
        quantity: 150,
        unitPrice: 65780,
        unitCost: 45780,
        paymentMethod: PaymentMethod.nequi,
        date: _d(_ref),
      ),
      Sale(
        id: 'v4',
        productId: 'p4',
        productName: 'Café Origen Nariño en granos 454gr',
        quantity: 200,
        unitPrice: 65780,
        unitCost: 45780,
        paymentMethod: PaymentMethod.nequi,
        date: _d(_ref),
      ),
      Sale(
        id: 'v5',
        productId: 'p5',
        productName: 'Café Colina en grano 454gr',
        quantity: 250,
        unitPrice: 56650,
        unitCost: 36650,
        paymentMethod: PaymentMethod.credito,
        date: _d(_ref),
      ),
    ];
  }

  static List<Expense> _initialExpenses() {
    return [
      Expense(
        id: 'g1',
        description: 'Agua',
        amount: 100000,
        paymentMethod: PaymentMethod.nequi,
        date: _d(_ref),
      ),
      Expense(
        id: 'g2',
        description: 'Luz',
        amount: 70000,
        paymentMethod: PaymentMethod.nequi,
        date: _d(_ref),
      ),
      Expense(
        id: 'g3',
        description: 'Internet',
        amount: 150000,
        paymentMethod: PaymentMethod.nequi,
        date: _d(_ref),
      ),
      Expense(
        id: 'g4',
        description: 'Nómina',
        amount: 2000000,
        paymentMethod: PaymentMethod.nequi,
        date: _d(_ref),
      ),
      Expense(
        id: 'g5',
        description: 'Seguridad Social',
        amount: 500000,
        paymentMethod: PaymentMethod.nequi,
        date: _d(_ref),
      ),
      Expense(
        id: 'g6',
        description: 'Arriendo',
        amount: 2000000,
        paymentMethod: PaymentMethod.nequi,
        date: _d(_ref),
      ),
      Expense(
        id: 'g7',
        description: 'Útiles de Aseo',
        amount: 50000,
        paymentMethod: PaymentMethod.nequi,
        date: _d(_ref),
      ),
      Expense(
        id: 'g8',
        description: 'Vigilancia',
        amount: 70000,
        paymentMethod: PaymentMethod.nequi,
        date: _d(_ref),
      ),
    ];
  }
}
