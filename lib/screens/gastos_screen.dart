import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../models/expense_payment.dart';
import '../res/data/colors.dart';
import '../res/data/constants.dart';
import '../res/data/dimens.dart';
import '../store/store_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_filter.dart';
import 'widgets/module_widgets.dart';

/// Pantalla de Gastos con tres pestañas:
/// - Gastos: registro y listado de gastos operativos.
/// - Pagos: registro de pagos contra gastos a crédito.
/// - Reporte: resumen de egresos por período.
class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen>
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
              colors: [ColorApp.moduleGastosDark, ColorApp.moduleGastos],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: const Text(
          AppConstants.moduleGastos,
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
            Tab(text: AppConstants.tabGastos),
            Tab(text: AppConstants.tabPagos),
            Tab(text: AppConstants.tabReporte),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ExpenseTab(),
          _ExpensePaymentTab(),
          _GastosReportTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Gastos
// ─────────────────────────────────────────────────────────────────────────────

class _ExpenseTab extends StatefulWidget {
  const _ExpenseTab();

  @override
  State<_ExpenseTab> createState() => _ExpenseTabState();
}

class _ExpenseTabState extends State<_ExpenseTab> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  PaymentMethod _selectedPayment = PaymentMethod.efectivo;
  String _error = '';

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final store = StoreProvider.of(context);
    final desc = _descController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (desc.isEmpty || amount == null || amount <= 0) {
      setState(() => _error = AppConstants.validationFillAllFields);
      return;
    }
    store.addExpense(
      Expense(
        id: 'g${DateTime.now().millisecondsSinceEpoch}',
        description: desc,
        amount: amount,
        paymentMethod: _selectedPayment,
        date: DateTime.now(),
      ),
    );
    _descController.clear();
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
        _ExpenseForm(
          descController: _descController,
          amountController: _amountController,
          selectedPayment: _selectedPayment,
          error: _error,
          onPaymentChanged: (v) =>
              setState(() => _selectedPayment = v ?? PaymentMethod.efectivo),
          onSubmit: () => _submit(context),
        ),
        Expanded(child: _ExpenseList(expenses: store.expenses)),
      ],
    );
  }
}

class _ExpenseForm extends StatelessWidget {
  const _ExpenseForm({
    required this.descController,
    required this.amountController,
    required this.selectedPayment,
    required this.error,
    required this.onPaymentChanged,
    required this.onSubmit,
  });

  final TextEditingController descController;
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
            controller: descController,
            decoration: moduleRoundedInputDecoration(
              label: AppConstants.hintExpenseDescription,
              focusColor: ColorApp.moduleGastos,
            ),
          ),
          const SizedBox(height: Dimens.paddingSm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: moduleRoundedInputDecoration(
                    label: AppConstants.hintAmount,
                    focusColor: ColorApp.moduleGastos,
                  ),
                ),
              ),
              const SizedBox(width: Dimens.paddingSm),
              Expanded(
                child: DropdownButtonFormField<PaymentMethod>(
                  initialValue: selectedPayment,
                  decoration: moduleRoundedInputDecoration(
                    focusColor: ColorApp.moduleGastos,
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
          ModulePrimaryButton(
            label: AppConstants.btnRegister,
            onPressed: onSubmit,
            color: ColorApp.moduleGastos,
            shadowColor: ColorApp.moduleGastosShadow,
          ),
        ],
      ),
    );
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({required this.expenses});
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const ModuleEmptyList();
    }
    return ColoredBox(
      color: ColorApp.listSectionBg,
      child: ListView.builder(
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final e = expenses[expenses.length - 1 - index];
          return ModuleListItem(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Dimens.paddingLg,
                vertical: Dimens.paddingXs,
              ),
              leading: CircleAvatar(
                backgroundColor: ColorApp.moduleGastosBg,
                child: const Icon(
                  Icons.receipt_long,
                  color: ColorApp.moduleGastos,
                ),
              ),
              title: Text(
                e.description,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${e.paymentMethod.label} · ${DateFilter.formatShort(e.date)}',
                style: const TextStyle(color: ColorApp.slate500),
              ),
              trailing: Text(
                CurrencyFormatter.format(e.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorApp.moduleGastos,
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
// Tab Pagos
// ─────────────────────────────────────────────────────────────────────────────

class _ExpensePaymentTab extends StatefulWidget {
  const _ExpensePaymentTab();

  @override
  State<_ExpensePaymentTab> createState() => _ExpensePaymentTabState();
}

class _ExpensePaymentTabState extends State<_ExpensePaymentTab> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  PaymentMethod _selectedPayment = PaymentMethod.efectivo;
  String _error = '';

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final store = StoreProvider.of(context);
    final desc = _descController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (desc.isEmpty || amount == null || amount <= 0) {
      setState(() => _error = AppConstants.validationFillAllFields);
      return;
    }
    store.addExpensePayment(
      ExpensePayment(
        id: 'pgc${DateTime.now().millisecondsSinceEpoch}',
        description: desc,
        amount: amount,
        paymentMethod: _selectedPayment,
        date: DateTime.now(),
      ),
    );
    _descController.clear();
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
        _ExpensePaymentForm(
          descController: _descController,
          amountController: _amountController,
          selectedPayment: _selectedPayment,
          error: _error,
          onPaymentChanged: (v) =>
              setState(() => _selectedPayment = v ?? PaymentMethod.efectivo),
          onSubmit: () => _submit(context),
        ),
        Expanded(child: _ExpensePaymentList(payments: store.expensePayments)),
      ],
    );
  }
}

class _ExpensePaymentForm extends StatelessWidget {
  const _ExpensePaymentForm({
    required this.descController,
    required this.amountController,
    required this.selectedPayment,
    required this.error,
    required this.onPaymentChanged,
    required this.onSubmit,
  });

  final TextEditingController descController;
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
            controller: descController,
            decoration: moduleRoundedInputDecoration(
              label: AppConstants.hintExpenseDescription,
              focusColor: ColorApp.moduleGastos,
            ),
          ),
          const SizedBox(height: Dimens.paddingSm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: moduleRoundedInputDecoration(
                    label: AppConstants.hintAmount,
                    focusColor: ColorApp.moduleGastos,
                  ),
                ),
              ),
              const SizedBox(width: Dimens.paddingSm),
              Expanded(
                child: DropdownButtonFormField<PaymentMethod>(
                  initialValue: selectedPayment,
                  decoration: moduleRoundedInputDecoration(
                    focusColor: ColorApp.moduleGastos,
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
          ModulePrimaryButton(
            label: AppConstants.btnRegister,
            onPressed: onSubmit,
            color: ColorApp.moduleGastos,
            shadowColor: ColorApp.moduleGastosShadow,
          ),
        ],
      ),
    );
  }
}

class _ExpensePaymentList extends StatelessWidget {
  const _ExpensePaymentList({required this.payments});
  final List<ExpensePayment> payments;

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return const ModuleEmptyList();
    }
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
                backgroundColor: ColorApp.moduleGastosBg,
                child: Icon(Icons.payment, color: ColorApp.moduleGastos),
              ),
              title: Text(
                p.description,
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
                  color: ColorApp.moduleGastos,
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

class _GastosReportTab extends StatefulWidget {
  const _GastosReportTab();

  @override
  State<_GastosReportTab> createState() => _GastosReportTabState();
}

class _GastosReportTabState extends State<_GastosReportTab> {
  ReportPeriod _period = ReportPeriod.monthly;

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of(context);
    final now = DateTime.now();
    final filteredExpenses = store.expensesForPeriod(_period, now);
    final pagos = store.expensePayments
        .where((p) => DateFilter.isInPeriod(p.date, now, _period))
        .toList(growable: false);

    final totalGastos = filteredExpenses.fold(0.0, (s, e) => s + e.amount);
    final totalPagos = pagos.fold(0.0, (s, p) => s + p.amount);
    final credito = filteredExpenses
        .where((e) => e.isCredit)
        .fold(0.0, (s, e) => s + e.amount);

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
            label: 'Total Gastos',
            value: CurrencyFormatter.format(totalGastos),
            color: ColorApp.moduleGastos,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: 'Pagos Realizados',
            value: CurrencyFormatter.format(totalPagos),
            color: ColorApp.slate500,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: 'Gastos a Crédito',
            value: CurrencyFormatter.format(credito),
            color: ColorApp.stockLowText,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: 'N° Gastos',
            value: '${filteredExpenses.length}',
            color: ColorApp.slate500,
          ),
        ],
      ),
    );
  }
}
