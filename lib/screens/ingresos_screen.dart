import 'package:flutter/material.dart';

import '../models/client_payment.dart';
import '../models/sale.dart';
import '../res/data/colors.dart';
import '../res/data/constants.dart';
import '../res/data/dimens.dart';
import '../store/store_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_filter.dart';
import 'widgets/module_widgets.dart';

/// Pantalla de Ingresos con tres pestañas:
/// - Ventas: registro y listado de ventas.
/// - Abonos: registro de pagos de clientes crédito.
/// - Reporte: resumen financiero por período.
class IngresosScreen extends StatefulWidget {
  const IngresosScreen({super.key});

  @override
  State<IngresosScreen> createState() => _IngresosScreenState();
}

class _IngresosScreenState extends State<IngresosScreen>
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
              colors: [ColorApp.moduleIngresosDark, ColorApp.emeraldCustom],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: const Text(
          AppConstants.moduleIngresos,
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
            Tab(text: AppConstants.tabVentas),
            Tab(text: AppConstants.tabAbonos),
            Tab(text: AppConstants.tabReporte),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_SaleTab(), _AbonosTab(), _IngresosReportTab()],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Ventas
// ─────────────────────────────────────────────────────────────────────────────

class _SaleTab extends StatefulWidget {
  const _SaleTab();

  @override
  State<_SaleTab> createState() => _SaleTabState();
}

class _SaleTabState extends State<_SaleTab> {
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
    if (product.stock < qty) {
      setState(() => _error = AppConstants.validationInsufficientStock);
      return;
    }

    final sale = Sale(
      id: 'v${DateTime.now().millisecondsSinceEpoch}',
      productId: product.id,
      productName: product.name,
      quantity: qty,
      unitPrice: price,
      unitCost: product.unitCost,
      paymentMethod: _selectedPayment,
      date: DateTime.now(),
    );
    store.addSale(sale);

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
        _SaleForm(
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
        Expanded(child: _SaleList(sales: store.sales)),
      ],
    );
  }
}

class _SaleForm extends StatelessWidget {
  const _SaleForm({
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
              focusColor: ColorApp.moduleIngresos,
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
              moduleColor: ColorApp.moduleIngresos,
            ),
          ],
          const SizedBox(height: Dimens.paddingMd),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: moduleRoundedInputDecoration(
                    label: AppConstants.hintQuantity,
                    focusColor: ColorApp.moduleIngresos,
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
                    focusColor: ColorApp.moduleIngresos,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimens.paddingMd),
          DropdownButtonFormField<PaymentMethod>(
            initialValue: selectedPayment,
            decoration: moduleRoundedInputDecoration(
              focusColor: ColorApp.moduleIngresos,
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
            color: ColorApp.moduleIngresos,
            shadowColor: ColorApp.moduleIngresosShadow,
          ),
        ],
      ),
    );
  }
}

class _SaleList extends StatelessWidget {
  const _SaleList({required this.sales});
  final List<Sale> sales;

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) {
      return const ColoredBox(
        color: ColorApp.listSectionBg,
        child: Center(child: Text(AppConstants.emptyList)),
      );
    }
    return ColoredBox(
      color: ColorApp.listSectionBg,
      child: ListView.builder(
        itemCount: sales.length,
        itemBuilder: (context, index) {
          final s = sales[sales.length - 1 - index];
          return _SaleItem(sale: s);
        },
      ),
    );
  }
}

class _SaleItem extends StatelessWidget {
  const _SaleItem({required this.sale});
  final Sale sale;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ColorApp.surface,
        border: Border(bottom: BorderSide(color: ColorApp.borderLight)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Dimens.paddingLg,
          vertical: Dimens.paddingXs,
        ),
        leading: CircleAvatar(
          backgroundColor: ColorApp.moduleIngresosBg,
          child: const Icon(Icons.arrow_upward, color: ColorApp.moduleIngresos),
        ),
        title: Text(
          sale.productName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${sale.quantity} u. · ${sale.paymentMethod.label} · '
          '${DateFilter.formatShort(sale.date)}',
          style: const TextStyle(color: ColorApp.slate500),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(sale.total),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: ColorApp.moduleIngresos,
              ),
            ),
            Text(
              'Utilidad: ${CurrencyFormatter.format(sale.grossProfit)}',
              style: const TextStyle(
                fontSize: Dimens.fontSizeXs,
                color: ColorApp.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Abonos
// ─────────────────────────────────────────────────────────────────────────────

class _AbonosTab extends StatefulWidget {
  const _AbonosTab();

  @override
  State<_AbonosTab> createState() => _AbonosTabState();
}

class _AbonosTabState extends State<_AbonosTab> {
  final _clientController = TextEditingController();
  final _amountController = TextEditingController();
  PaymentMethod _selectedPayment = PaymentMethod.efectivo;
  String _error = '';

  @override
  void dispose() {
    _clientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final store = StoreProvider.of(context);
    final client = _clientController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (client.isEmpty || amount == null || amount <= 0) {
      setState(() => _error = AppConstants.validationFillAllFields);
      return;
    }
    store.addClientPayment(
      ClientPayment(
        id: 'ab${DateTime.now().millisecondsSinceEpoch}',
        clientName: client,
        amount: amount,
        paymentMethod: _selectedPayment,
        date: DateTime.now(),
      ),
    );
    _clientController.clear();
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
        _AbonoForm(
          clientController: _clientController,
          amountController: _amountController,
          selectedPayment: _selectedPayment,
          error: _error,
          onPaymentChanged: (v) =>
              setState(() => _selectedPayment = v ?? PaymentMethod.efectivo),
          onSubmit: () => _submit(context),
        ),
        Expanded(child: _AbonoList(payments: store.clientPayments)),
      ],
    );
  }
}

class _AbonoForm extends StatelessWidget {
  const _AbonoForm({
    required this.clientController,
    required this.amountController,
    required this.selectedPayment,
    required this.error,
    required this.onPaymentChanged,
    required this.onSubmit,
  });

  final TextEditingController clientController;
  final TextEditingController amountController;
  final PaymentMethod selectedPayment;
  final String error;
  final ValueChanged<PaymentMethod?> onPaymentChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorApp.surface,
      padding: const EdgeInsets.all(Dimens.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: clientController,
            decoration: moduleRoundedInputDecoration(
              label: AppConstants.hintClientName,
              focusColor: ColorApp.moduleIngresos,
            ),
          ),
          const SizedBox(height: Dimens.paddingMd),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: moduleRoundedInputDecoration(
                    label: AppConstants.hintAmount,
                    focusColor: ColorApp.moduleIngresos,
                  ),
                ),
              ),
              const SizedBox(width: Dimens.paddingMd),
              Expanded(
                child: DropdownButtonFormField<PaymentMethod>(
                  initialValue: selectedPayment,
                  decoration: moduleRoundedInputDecoration(
                    focusColor: ColorApp.moduleIngresos,
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
          const SizedBox(height: Dimens.paddingMd),
          ModulePrimaryButton(
            label: AppConstants.btnRegister,
            onPressed: onSubmit,
            color: ColorApp.moduleIngresos,
            shadowColor: ColorApp.moduleIngresosShadow,
          ),
        ],
      ),
    );
  }
}

class _AbonoList extends StatelessWidget {
  const _AbonoList({required this.payments});
  final List<ClientPayment> payments;

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return const ColoredBox(
        color: ColorApp.listSectionBg,
        child: Center(child: Text(AppConstants.emptyList)),
      );
    }
    return ColoredBox(
      color: ColorApp.listSectionBg,
      child: ListView.builder(
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final p = payments[payments.length - 1 - index];
          return Container(
            decoration: const BoxDecoration(
              color: ColorApp.surface,
              border: Border(bottom: BorderSide(color: ColorApp.borderLight)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Dimens.paddingLg,
                vertical: Dimens.paddingXs,
              ),
              leading: const CircleAvatar(
                backgroundColor: ColorApp.moduleIngresosBg,
                child: Icon(Icons.person, color: ColorApp.moduleIngresos),
              ),
              title: Text(
                p.clientName,
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
                  color: ColorApp.moduleIngresos,
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

class _IngresosReportTab extends StatefulWidget {
  const _IngresosReportTab();

  @override
  State<_IngresosReportTab> createState() => _IngresosReportTabState();
}

class _IngresosReportTabState extends State<_IngresosReportTab> {
  ReportPeriod _period = ReportPeriod.monthly;

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of(context);
    final now = DateTime.now();
    final filteredSales = store.salesForPeriod(_period, now);
    final abonos = store.clientPayments
        .where((p) => DateFilter.isInPeriod(p.date, now, _period))
        .toList(growable: false);

    final totalIngresos = filteredSales.fold(0.0, (s, v) => s + v.total);
    final totalCosto = filteredSales.fold(0.0, (s, v) => s + v.totalCost);
    final utilidad = totalIngresos - totalCosto;
    final totalAbonos = abonos.fold(0.0, (s, p) => s + p.amount);

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
            label: 'Total Ingresos',
            value: CurrencyFormatter.format(totalIngresos),
            color: ColorApp.moduleIngresos,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: 'Costo de Ventas',
            value: CurrencyFormatter.format(totalCosto),
            color: ColorApp.slate500,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: 'Utilidad Bruta',
            value: CurrencyFormatter.format(utilidad),
            color: utilidad >= 0 ? ColorApp.primaryDark : ColorApp.stockLowText,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: 'Abonos Recibidos',
            value: CurrencyFormatter.format(totalAbonos),
            color: ColorApp.moduleIngresos,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: 'N° Ventas',
            value: '${filteredSales.length}',
            color: ColorApp.slate500,
          ),
        ],
      ),
    );
  }
}
