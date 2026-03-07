import 'package:flutter/material.dart';

import '../res/data/colors.dart';
import '../res/data/constants.dart';
import '../res/data/dimens.dart';
import '../store/store_provider.dart';
import '../utils/currency_formatter.dart';
import 'widgets/module_widgets.dart';

/// Pantalla de Reportes con cuatro pestañas:
/// - Flujo de Caja: movimientos de efectivo del período.
/// - Por Cobrar: ventas a crédito pendientes de cobro.
/// - Por Pagar: compras y gastos a crédito pendientes de pago.
/// - Resultado: estado de resultado del período.
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
              colors: [
                ColorApp.moduleReportesDark,
                ColorApp.moduleReportesIndigo,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),

        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorApp.surface,
          unselectedLabelColor: ColorApp.slate100,
          indicatorColor: ColorApp.surface,
          indicatorWeight: Dimens.tabIndicatorWidth,
          labelStyle: const TextStyle(
            fontSize: Dimens.fontSizeTab,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(
              height: Dimens.tabHeightTall,
              child: Text(
                AppConstants.tabFlujoCaja,
                textAlign: TextAlign.center,
              ),
            ),
            Tab(
              height: Dimens.tabHeightTall,
              child: Text(
                AppConstants.tabCuentasCobrar,
                textAlign: TextAlign.center,
              ),
            ),
            Tab(
              height: Dimens.tabHeightTall,
              child: Text(
                AppConstants.tabCuentasPagar,
                textAlign: TextAlign.center,
              ),
            ),
            Tab(
              height: Dimens.tabHeightTall,
              child: Text(
                AppConstants.tabEstadoResultado,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FlujoCajaTab(),
          _CuentasCobrarTab(),
          _CuentasPagarTab(),
          _EstadoResultadoTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Flujo de Caja
// ─────────────────────────────────────────────────────────────────────────────

class _FlujoCajaTab extends StatefulWidget {
  const _FlujoCajaTab();

  @override
  State<_FlujoCajaTab> createState() => _FlujoCajaTabState();
}

class _FlujoCajaTabState extends State<_FlujoCajaTab> {
  ReportPeriod _period = ReportPeriod.monthly;

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of(context);
    final now = DateTime.now();

    final ingresosCash = store
        .salesForPeriod(_period, now)
        .where((s) => s.paymentMethod.isCash)
        .fold(0.0, (acc, s) => acc + s.total);

    final comprasCash = store
        .purchasesForPeriod(_period, now)
        .where((p) => p.paymentMethod.isCash)
        .fold(0.0, (acc, p) => acc + p.total);

    final gastosCash = store
        .expensesForPeriod(_period, now)
        .where((e) => e.paymentMethod.isCash)
        .fold(0.0, (acc, e) => acc + e.amount);

    final totalCaja = ingresosCash - comprasCash - gastosCash;

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
            label: AppConstants.labelIngresosCash,
            value: CurrencyFormatter.format(ingresosCash),
            color: ColorApp.primaryDark,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: AppConstants.labelComprasCash,
            value: CurrencyFormatter.format(comprasCash),
            color: ColorApp.moduleCompras,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: AppConstants.labelGastosCash,
            value: CurrencyFormatter.format(gastosCash),
            color: ColorApp.moduleGastos,
          ),
          const SizedBox(height: Dimens.paddingLg),
          _TotalCard(
            label: AppConstants.labelTotalCaja,
            value: CurrencyFormatter.format(totalCaja),
            positive: totalCaja >= 0,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Cuentas por Cobrar (sin filtro de período)
// ─────────────────────────────────────────────────────────────────────────────

class _CuentasCobrarTab extends StatelessWidget {
  const _CuentasCobrarTab();

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of(context);

    final creditSales = store.sales
        .where((s) => s.isCredit)
        .toList(growable: false);
    final totalCreditSales = creditSales.fold(0.0, (acc, s) => acc + s.total);
    final totalAbonos = store.clientPayments.fold(
      0.0,
      (acc, p) => acc + p.amount,
    );
    final saldo = totalCreditSales - totalAbonos;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(Dimens.paddingLg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              MetricCard(
                label: AppConstants.labelCreditSales,
                value: CurrencyFormatter.format(totalCreditSales),
                color: ColorApp.moduleIngresos,
              ),
              const SizedBox(height: Dimens.paddingSm),
              MetricCard(
                label: AppConstants.labelPaymentsReceived,
                value: CurrencyFormatter.format(totalAbonos),
                color: ColorApp.primaryDark,
              ),
              const SizedBox(height: Dimens.paddingLg),
              _TotalCard(
                label: AppConstants.labelSaldoPendiente,
                value: CurrencyFormatter.format(saldo),
                positive: saldo <= 0,
              ),
              const SizedBox(height: Dimens.paddingLg),
            ]),
          ),
        ),
        _SectionHeader(label: AppConstants.sectionCreditSales),
        if (creditSales.isEmpty)
          const SliverFillRemaining(child: _EmptyReport()),
        if (creditSales.isNotEmpty)
          SliverList.builder(
            itemCount: creditSales.length,
            itemBuilder: (context, i) {
              final sale = creditSales[i];
              return ModuleListItem(
                child: ListTile(
                  title: Text(sale.productName),
                  subtitle: Text(
                    '${sale.quantity} × ${CurrencyFormatter.format(sale.unitPrice)}',
                  ),
                  trailing: Text(
                    CurrencyFormatter.format(sale.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ColorApp.moduleIngresos,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3: Cuentas por Pagar (sin filtro de período)
// ─────────────────────────────────────────────────────────────────────────────

class _CuentasPagarTab extends StatelessWidget {
  const _CuentasPagarTab();

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of(context);

    final creditPurchases = store.purchases
        .where((p) => p.isCredit)
        .toList(growable: false);
    final totalCreditPurchases = creditPurchases.fold(
      0.0,
      (acc, p) => acc + p.total,
    );
    final totalSupplierPay = store.supplierPayments.fold(
      0.0,
      (acc, p) => acc + p.amount,
    );
    final saldoCompras = totalCreditPurchases - totalSupplierPay;

    final creditExpenses = store.expenses
        .where((e) => e.isCredit)
        .toList(growable: false);
    final totalCreditExpenses = creditExpenses.fold(
      0.0,
      (acc, e) => acc + e.amount,
    );
    final totalExpensePay = store.expensePayments.fold(
      0.0,
      (acc, p) => acc + p.amount,
    );
    final saldoGastos = totalCreditExpenses - totalExpensePay;

    final totalAPagar = saldoCompras + saldoGastos;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(Dimens.paddingLg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              MetricCard(
                label: AppConstants.labelCreditPurchases,
                value: CurrencyFormatter.format(totalCreditPurchases),
                color: ColorApp.moduleCompras,
              ),
              const SizedBox(height: Dimens.paddingSm),
              MetricCard(
                label: AppConstants.labelSupplierPayments,
                value: CurrencyFormatter.format(totalSupplierPay),
                color: ColorApp.primaryDark,
              ),
              const SizedBox(height: Dimens.paddingSm),
              MetricCard(
                label: AppConstants.labelCreditExpenses,
                value: CurrencyFormatter.format(totalCreditExpenses),
                color: ColorApp.moduleGastos,
              ),
              const SizedBox(height: Dimens.paddingSm),
              MetricCard(
                label: AppConstants.labelExpensePayments,
                value: CurrencyFormatter.format(totalExpensePay),
                color: ColorApp.primaryDark,
              ),
              const SizedBox(height: Dimens.paddingLg),
              _TotalCard(
                label: AppConstants.labelTotalAPagar,
                value: CurrencyFormatter.format(totalAPagar),
                positive: totalAPagar <= 0,
              ),
              const SizedBox(height: Dimens.paddingLg),
            ]),
          ),
        ),
        _SectionHeader(label: AppConstants.sectionCreditPurchases),
        if (creditPurchases.isEmpty)
          const SliverToBoxAdapter(child: _EmptyReport()),
        if (creditPurchases.isNotEmpty)
          SliverList.builder(
            itemCount: creditPurchases.length,
            itemBuilder: (context, i) {
              final purchase = creditPurchases[i];
              return ModuleListItem(
                child: ListTile(
                  title: Text(purchase.productName),
                  subtitle: Text(
                    '${purchase.quantity} × ${CurrencyFormatter.format(purchase.unitPrice)}',
                  ),
                  trailing: Text(
                    CurrencyFormatter.format(purchase.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ColorApp.moduleCompras,
                    ),
                  ),
                ),
              );
            },
          ),
        _SectionHeader(label: AppConstants.sectionCreditExpenses),
        if (creditExpenses.isEmpty)
          const SliverToBoxAdapter(child: _EmptyReport()),
        if (creditExpenses.isNotEmpty)
          SliverList.builder(
            itemCount: creditExpenses.length,
            itemBuilder: (context, i) {
              final expense = creditExpenses[i];
              return ModuleListItem(
                child: ListTile(
                  title: Text(expense.description),
                  trailing: Text(
                    CurrencyFormatter.format(expense.amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ColorApp.moduleGastos,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 4: Estado de Resultado
// ─────────────────────────────────────────────────────────────────────────────

class _EstadoResultadoTab extends StatefulWidget {
  const _EstadoResultadoTab();

  @override
  State<_EstadoResultadoTab> createState() => _EstadoResultadoTabState();
}

class _EstadoResultadoTabState extends State<_EstadoResultadoTab> {
  ReportPeriod _period = ReportPeriod.monthly;

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of(context);
    final now = DateTime.now();

    final sales = store.salesForPeriod(_period, now);
    final totalIngresos = sales.fold(0.0, (acc, s) => acc + s.total);
    final totalCosto = sales.fold(0.0, (acc, s) => acc + s.totalCost);
    final totalGastos = store
        .expensesForPeriod(_period, now)
        .fold(0.0, (acc, e) => acc + e.amount);
    final utilidad = totalIngresos - totalCosto - totalGastos;

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
            label: AppConstants.labelTotalIngresos,
            value: CurrencyFormatter.format(totalIngresos),
            color: ColorApp.moduleIngresos,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: AppConstants.labelTotalCosto,
            value: CurrencyFormatter.format(totalCosto),
            color: ColorApp.moduleCompras,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: AppConstants.labelTotalGastos,
            value: CurrencyFormatter.format(totalGastos),
            color: ColorApp.moduleGastos,
          ),
          const SizedBox(height: Dimens.paddingLg),
          _TotalCard(
            label: AppConstants.labelUtilidadPerdida,
            value: CurrencyFormatter.format(utilidad),
            positive: utilidad >= 0,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets internos reutilizables dentro de este archivo
// ─────────────────────────────────────────────────────────────────────────────

/// Tarjeta de resultado final (totales) con color condicional y fondo oscuro.
class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.value,
    required this.positive,
  });

  final String label;
  final String value;

  /// Cuando es true usa color verde, cuando es false usa rojo.
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? ColorApp.primaryDark : ColorApp.stockLowText;
    return Container(
      padding: const EdgeInsets.all(Dimens.paddingLg),
      decoration: BoxDecoration(
        color: ColorApp.cardBg,
        borderRadius: BorderRadius.circular(Dimens.radiusMd),
        border: Border.all(color: ColorApp.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: ColorApp.slate900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

/// Separador de sección con etiqueta en mayúsculas, estilo fondo gris.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ColoredBox(
        color: ColorApp.listSectionBg,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.paddingLg,
            vertical: Dimens.paddingSm,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: Dimens.fontSizeXs,
              fontWeight: FontWeight.w600,
              color: ColorApp.slate500,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Estado vacío para reportes sin movimientos.
class _EmptyReport extends StatelessWidget {
  const _EmptyReport();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(Dimens.paddingXl),
      child: Center(
        child: Text(
          AppConstants.emptyReporteGlobal,
          style: TextStyle(color: ColorApp.slate500),
        ),
      ),
    );
  }
}
