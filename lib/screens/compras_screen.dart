import 'package:flutter/material.dart';

import '../models/purchase.dart';
import '../models/supplier_payment.dart';
import '../res/data/colors.dart';
import '../res/data/constants.dart';
import '../res/data/dimens.dart';
import '../store/store_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_filter.dart';
import 'widgets/module_widgets.dart';

/// Pantalla de Compras con tres pestañas:
/// - Compras: registro y listado de compras.
/// - Proveedores: pagos a proveedores.
/// - Reporte: resumen de compras por período.
class ComprasScreen extends StatefulWidget {
  const ComprasScreen({super.key});

  @override
  State<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.backgroundLight,
      appBar: AppBar(
        toolbarHeight: Dimens.appBarHeightGradient,
        backgroundColor: Colors.transparent,
        foregroundColor: ColorApp.surface,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [ColorApp.moduleComprasDark, ColorApp.moduleCompras],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: const Text(
          AppConstants.moduleCompras,
          style: TextStyle(
            fontSize: Dimens.fontSizeTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorApp.surface,
          unselectedLabelColor: ColorApp.slate100,
          indicatorColor: ColorApp.surface,
          indicatorWeight: Dimens.tabIndicatorWidth,
          tabs: const [
            Tab(text: AppConstants.tabCompras),
            Tab(text: AppConstants.tabProveedores),
            Tab(text: AppConstants.tabReporte),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_PurchaseTab(), _SupplierTab(), _ComprasReportTab()],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Compras
// ─────────────────────────────────────────────────────────────────────────────

class _PurchaseTab extends StatefulWidget {
  const _PurchaseTab();

  @override
  State<_PurchaseTab> createState() => _PurchaseTabState();
}

class _PurchaseTabState extends State<_PurchaseTab> {
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedProductId = '';
  PaymentMethod _selectedPayment = PaymentMethod.efectivo;
  String _error = '';

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final store = StoreProvider.of(context);
    final qty = int.tryParse(_qtyController.text.trim());
    final price = double.tryParse(_priceController.text.trim());

    if (_selectedProductId.isEmpty) {
      setState(() => _error = AppConstants.validationSelectProduct);
      return;
    }
    if (qty == null || qty <= 0 || price == null || price <= 0) {
      setState(() => _error = AppConstants.validationPositiveNumber);
      return;
    }

    final productIndex = store.products.indexWhere(
      (p) => p.id == _selectedProductId,
    );
    if (productIndex == -1) {
      setState(() => _error = AppConstants.validationSelectProduct);
      return;
    }
    final product = store.products[productIndex];

    store.addPurchase(
      Purchase(
        id: 'c${DateTime.now().millisecondsSinceEpoch}',
        productId: product.id,
        productName: product.name,
        quantity: qty,
        unitPrice: price,
        paymentMethod: _selectedPayment,
        date: DateTime.now(),
      ),
    );

    _qtyController.clear();
    _priceController.clear();
    setState(() {
      _selectedProductId = '';
      _selectedPayment = PaymentMethod.efectivo;
      _error = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of(context);
    return Column(
      children: [
        _PurchaseForm(
          qtyController: _qtyController,
          priceController: _priceController,
          selectedProductId: _selectedProductId,
          selectedPayment: _selectedPayment,
          products: store.products,
          error: _error,
          onProductChanged: (v) => setState(() => _selectedProductId = v ?? ''),
          onPaymentChanged: (v) =>
              setState(() => _selectedPayment = v ?? PaymentMethod.efectivo),
          onSubmit: () => _submit(context),
        ),
        Expanded(child: _PurchaseList(purchases: store.purchases)),
      ],
    );
  }
}

class _PurchaseForm extends StatelessWidget {
  const _PurchaseForm({
    required this.qtyController,
    required this.priceController,
    required this.selectedProductId,
    required this.selectedPayment,
    required this.products,
    required this.error,
    required this.onProductChanged,
    required this.onPaymentChanged,
    required this.onSubmit,
  });

  final TextEditingController qtyController;
  final TextEditingController priceController;
  final String selectedProductId;
  final PaymentMethod selectedPayment;
  final List<dynamic> products;
  final String error;
  final ValueChanged<String?> onProductChanged;
  final ValueChanged<PaymentMethod?> onPaymentChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    // Busca el producto seleccionado para mostrar su stock en tiempo real.
    dynamic selectedProduct;
    for (final p in products) {
      if ((p.id as String) == selectedProductId) {
        selectedProduct = p;
        break;
      }
    }
    return Container(
      color: ColorApp.surface,
      padding: const EdgeInsets.all(Dimens.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: selectedProductId.isEmpty ? null : selectedProductId,
            hint: const Text(AppConstants.validationSelectProduct),
            decoration: moduleRoundedInputDecoration(
              label: AppConstants.hintProductName,
              focusColor: ColorApp.moduleCompras,
            ),
            items: [
              for (final p in products)
                DropdownMenuItem<String>(
                  value: p.id as String,
                  child: Text(p.name as String),
                ),
            ],
            onChanged: onProductChanged,
          ),
          if (selectedProduct != null) ...[
            const SizedBox(height: Dimens.paddingXs),
            StockBadge(
              stock: selectedProduct!.stock as int,
              unit: selectedProduct!.unit as String,
              moduleColor: ColorApp.moduleCompras,
            ),
          ],
          const SizedBox(height: Dimens.paddingSm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: moduleRoundedInputDecoration(
                    label: AppConstants.hintQuantity,
                    focusColor: ColorApp.moduleCompras,
                  ),
                ),
              ),
              const SizedBox(width: Dimens.paddingMd),
              Expanded(
                child: TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: moduleRoundedInputDecoration(
                    label: AppConstants.hintUnitPrice,
                    focusColor: ColorApp.moduleCompras,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimens.paddingMd),
          DropdownButtonFormField<PaymentMethod>(
            initialValue: selectedPayment,
            decoration: moduleRoundedInputDecoration(
              focusColor: ColorApp.moduleCompras,
            ),
            items: [
              for (final m in PaymentMethod.values)
                DropdownMenuItem<PaymentMethod>(value: m, child: Text(m.label)),
            ],
            onChanged: onPaymentChanged,
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: Dimens.paddingXs),
            Text(error, style: const TextStyle(color: ColorApp.stockLowText)),
          ],
          const SizedBox(height: Dimens.paddingMd),
          ModulePrimaryButton(
            label: AppConstants.btnRegister,
            onPressed: onSubmit,
            color: ColorApp.moduleCompras,
            shadowColor: ColorApp.moduleComprasShadow,
          ),
        ],
      ),
    );
  }
}

class _PurchaseList extends StatelessWidget {
  const _PurchaseList({required this.purchases});

  final List<Purchase> purchases;

  @override
  Widget build(BuildContext context) {
    if (purchases.isEmpty) return const ModuleEmptyList();
    return ColoredBox(
      color: ColorApp.listSectionBg,
      child: ListView.builder(
        itemCount: purchases.length,
        itemBuilder: (context, index) {
          final p = purchases[purchases.length - 1 - index];
          return ModuleListItem(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Dimens.paddingLg,
                vertical: Dimens.paddingXs,
              ),
              leading: CircleAvatar(
                backgroundColor: ColorApp.moduleComprasBg,
                child: const Icon(
                  Icons.arrow_downward,
                  color: ColorApp.moduleCompras,
                ),
              ),
              title: Text(
                p.productName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${p.quantity} u. · ${p.paymentMethod.label} · '
                '${DateFilter.formatShort(p.date)}',
                style: const TextStyle(color: ColorApp.slate500),
              ),
              trailing: Text(
                CurrencyFormatter.format(p.total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorApp.moduleCompras,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Proveedores
// ─────────────────────────────────────────────────────────────────────────────

class _SupplierTab extends StatefulWidget {
  const _SupplierTab();

  @override
  State<_SupplierTab> createState() => _SupplierTabState();
}

class _SupplierTabState extends State<_SupplierTab> {
  final _supplierController = TextEditingController();
  final _amountController = TextEditingController();
  PaymentMethod _selectedPayment = PaymentMethod.efectivo;
  String _error = '';

  @override
  void dispose() {
    _supplierController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final store = StoreProvider.of(context);
    final supplier = _supplierController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (supplier.isEmpty || amount == null || amount <= 0) {
      setState(() => _error = AppConstants.validationFillAllFields);
      return;
    }
    store.addSupplierPayment(
      SupplierPayment(
        id: 'sp${DateTime.now().millisecondsSinceEpoch}',
        supplierName: supplier,
        amount: amount,
        paymentMethod: _selectedPayment,
        date: DateTime.now(),
      ),
    );
    _supplierController.clear();
    _amountController.clear();
    setState(() {
      _selectedPayment = PaymentMethod.efectivo;
      _error = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of(context);
    return Column(
      children: [
        _SupplierForm(
          supplierController: _supplierController,
          amountController: _amountController,
          selectedPayment: _selectedPayment,
          error: _error,
          onPaymentChanged: (v) =>
              setState(() => _selectedPayment = v ?? PaymentMethod.efectivo),
          onSubmit: () => _submit(context),
        ),
        Expanded(child: _SupplierList(payments: store.supplierPayments)),
      ],
    );
  }
}

class _SupplierForm extends StatelessWidget {
  const _SupplierForm({
    required this.supplierController,
    required this.amountController,
    required this.selectedPayment,
    required this.error,
    required this.onPaymentChanged,
    required this.onSubmit,
  });

  final TextEditingController supplierController;
  final TextEditingController amountController;
  final PaymentMethod selectedPayment;
  final String error;
  final ValueChanged<PaymentMethod?> onPaymentChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorApp.cardBg,
      padding: const EdgeInsets.all(Dimens.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: supplierController,
            decoration: const InputDecoration(
              labelText: AppConstants.hintSupplierName,
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: Dimens.paddingSm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: AppConstants.hintAmount,
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: Dimens.paddingSm),
              Expanded(
                child: DropdownButtonFormField<PaymentMethod>(
                  initialValue: selectedPayment,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final m in PaymentMethod.values)
                      DropdownMenuItem<PaymentMethod>(
                        value: m,
                        child: Text(m.label),
                      ),
                  ],
                  onChanged: onPaymentChanged,
                ),
              ),
            ],
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: Dimens.paddingXs),
            Text(error, style: const TextStyle(color: ColorApp.stockLowText)),
          ],
          const SizedBox(height: Dimens.paddingSm),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorApp.moduleCompras,
              foregroundColor: ColorApp.surface,
            ),
            onPressed: onSubmit,
            child: const Text(AppConstants.btnRegister),
          ),
        ],
      ),
    );
  }
}

class _SupplierList extends StatelessWidget {
  const _SupplierList({required this.payments});

  final List<SupplierPayment> payments;

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) return const ModuleEmptyList();
    return ColoredBox(
      color: ColorApp.listSectionBg,
      child: ListView.builder(
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final p = payments[payments.length - 1 - index];
          return ModuleListItem(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Dimens.paddingLg,
                vertical: Dimens.paddingXs,
              ),
              leading: const CircleAvatar(
                backgroundColor: ColorApp.moduleComprasBg,
                child: Icon(Icons.store, color: ColorApp.moduleCompras),
              ),
              title: Text(
                p.supplierName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${p.paymentMethod.label} · ${DateFilter.formatShort(p.date)}',
                style: const TextStyle(color: ColorApp.slate500),
              ),
              trailing: Text(
                CurrencyFormatter.format(p.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorApp.moduleCompras,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Reporte
// ─────────────────────────────────────────────────────────────────────────────

class _ComprasReportTab extends StatefulWidget {
  const _ComprasReportTab();

  @override
  State<_ComprasReportTab> createState() => _ComprasReportTabState();
}

class _ComprasReportTabState extends State<_ComprasReportTab> {
  ReportPeriod _period = ReportPeriod.monthly;

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of(context);
    final now = DateTime.now();
    final filteredPurchases = store.purchasesForPeriod(_period, now);
    final pagosProveedor = store.supplierPayments
        .where((p) => DateFilter.isInPeriod(p.date, now, _period))
        .toList(growable: false);

    final totalCompras = filteredPurchases.fold(0.0, (s, c) => s + c.total);
    final totalPagos = pagosProveedor.fold(0.0, (s, p) => s + p.amount);
    final credito = filteredPurchases
        .where((c) => c.isCredit)
        .fold(0.0, (s, c) => s + c.total);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimens.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PeriodSelector(
            selected: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
          const SizedBox(height: Dimens.paddingLg),
          MetricCard(
            label: 'Total Compras',
            value: CurrencyFormatter.format(totalCompras),
            color: ColorApp.moduleCompras,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: 'Pagos a Proveedores',
            value: CurrencyFormatter.format(totalPagos),
            color: ColorApp.slate500,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: 'Saldo a Crédito',
            value: CurrencyFormatter.format(credito - totalPagos),
            color: ColorApp.stockLowText,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: 'N° Compras',
            value: '${filteredPurchases.length}',
            color: ColorApp.slate500,
          ),
        ],
      ),
    );
  }
}
