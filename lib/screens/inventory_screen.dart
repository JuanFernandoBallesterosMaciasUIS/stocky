import 'package:flutter/material.dart';

import '../models/product.dart';
import '../res/data/colors.dart';
import '../res/data/constants.dart';
import '../res/data/dimens.dart';
import '../store/store_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_filter.dart';
import 'widgets/module_widgets.dart';

/// Pantalla de Control de Inventarios con tres pestañas:
/// - Registro Manual: formulario para agregar productos y lista completa.
/// - Stock: estado actual del stock con alertas de bajo inventario.
/// - Por Vencer: productos próximos a vencer o ya vencidos.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
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
              colors: [
                ColorApp.moduleInventarioDark,
                ColorApp.moduleInventario,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: const Text(
          AppConstants.inventoryTitle,
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
            Tab(text: AppConstants.tabManualEntry),
            Tab(text: AppConstants.tabStock),
            Tab(text: AppConstants.tabExpiring),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_ManualEntryTab(), _StockTab(), _ExpiryTab()],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Registro Manual
// ─────────────────────────────────────────────────────────────────────────────

class _ManualEntryTab extends StatefulWidget {
  const _ManualEntryTab();

  @override
  State<_ManualEntryTab> createState() => _ManualEntryTabState();
}

class _ManualEntryTabState extends State<_ManualEntryTab> {
  final _nameController = TextEditingController();
  final _stockController = TextEditingController();
  final _unitController = TextEditingController();
  final _costController = TextEditingController();
  String _error = '';

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    _costController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final name = _nameController.text.trim();
    final stock = int.tryParse(_stockController.text.trim());
    final unit = _unitController.text.trim();
    final cost = double.tryParse(_costController.text.trim());

    if (name.isEmpty || unit.isEmpty) {
      setState(() => _error = AppConstants.validationFillAllFields);
      return;
    }
    if (stock == null || stock < 0 || cost == null || cost <= 0) {
      setState(() => _error = AppConstants.validationPositiveNumber);
      return;
    }

    StoreProvider.of(context).addInventoryProduct(
      InventoryProduct(
        id: 'ip${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        stock: stock,
        unit: unit,
        icon: Icons.inventory_2,
        unitCost: cost,
      ),
    );
    _nameController.clear();
    _stockController.clear();
    _unitController.clear();
    _costController.clear();
    setState(() => _error = '');
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of(context);
    return Column(
      children: [
        _ProductForm(
          nameController: _nameController,
          stockController: _stockController,
          unitController: _unitController,
          costController: _costController,
          error: _error,
          onSubmit: () => _submit(context),
        ),
        const _InfoBanner(),
        Expanded(child: _ProductList(products: store.products, showCost: true)),
      ],
    );
  }
}

class _ProductForm extends StatelessWidget {
  const _ProductForm({
    required this.nameController,
    required this.stockController,
    required this.unitController,
    required this.costController,
    required this.error,
    required this.onSubmit,
  });

  final TextEditingController nameController;
  final TextEditingController stockController;
  final TextEditingController unitController;
  final TextEditingController costController;
  final String error;
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
            controller: nameController,
            decoration: moduleRoundedInputDecoration(
              label: AppConstants.hintProductName,
              focusColor: ColorApp.moduleInventario,
            ),
          ),
          const SizedBox(height: Dimens.paddingSm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: moduleRoundedInputDecoration(
                    label: AppConstants.hintQuantity,
                    focusColor: ColorApp.moduleInventario,
                  ),
                ),
              ),
              const SizedBox(width: Dimens.paddingSm),
              Expanded(
                child: TextField(
                  controller: unitController,
                  decoration: moduleRoundedInputDecoration(
                    label: AppConstants.hintUnit,
                    focusColor: ColorApp.moduleInventario,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimens.paddingSm),
          TextField(
            controller: costController,
            keyboardType: TextInputType.number,
            decoration: moduleRoundedInputDecoration(
              label: AppConstants.hintUnitCost,
              focusColor: ColorApp.moduleInventario,
            ),
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: Dimens.paddingXs),
            Text(error, style: const TextStyle(color: ColorApp.stockLowText)),
          ],
          const SizedBox(height: Dimens.paddingSm),
          ModulePrimaryButton(
            label: AppConstants.btnRegister,
            onPressed: onSubmit,
            color: ColorApp.moduleInventario,
            shadowColor: ColorApp.moduleInventarioShadow,
            foreground: ColorApp.slate900,
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Dimens.paddingLg,
        vertical: Dimens.paddingSm,
      ),
      padding: const EdgeInsets.all(Dimens.paddingMd),
      decoration: BoxDecoration(
        color: ColorApp.infoBannerBg,
        borderRadius: BorderRadius.circular(Dimens.radiusMd),
        border: Border.all(color: ColorApp.infoBannerBorder),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: ColorApp.primaryDark),
          SizedBox(width: Dimens.paddingSm),
          Expanded(
            child: Text(
              AppConstants.infoBannerText,
              style: TextStyle(fontSize: 12, color: ColorApp.primaryDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({required this.products, this.showCost = false});
  final List<InventoryProduct> products;
  final bool showCost;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const ModuleEmptyList();
    }
    return ColoredBox(
      color: ColorApp.listSectionBg,
      child: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) =>
            _ProductItem(product: products[index], showCost: showCost),
      ),
    );
  }
}

class _ProductItem extends StatelessWidget {
  const _ProductItem({required this.product, this.showCost = false});
  final InventoryProduct product;
  final bool showCost;

  @override
  Widget build(BuildContext context) {
    final isLow = product.isLowStock;
    return Container(
      decoration: const BoxDecoration(
        color: ColorApp.surface,
        border: Border(bottom: BorderSide(color: ColorApp.borderLight)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimens.paddingLg,
          vertical: Dimens.paddingSm,
        ),
        child: Row(
          children: [
            Container(
              width: Dimens.productIconSize,
              height: Dimens.productIconSize,
              decoration: BoxDecoration(
                color: isLow ? ColorApp.stockLowBg : ColorApp.stockAdequateBg,
                borderRadius: BorderRadius.circular(Dimens.radiusMd),
              ),
              child: Icon(
                product.icon,
                size: Dimens.productIconInnerSize,
                color: isLow ? ColorApp.stockLowFg : ColorApp.primaryDark,
              ),
            ),
            const SizedBox(width: Dimens.paddingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: Dimens.paddingXs),
                  Row(
                    children: [
                      _StockChip(
                        label: '${product.stock} ${product.unit}',
                        isLow: isLow,
                      ),
                      if (showCost) ...[
                        const SizedBox(width: Dimens.paddingXs),
                        Text(
                          CurrencyFormatter.format(product.stockValue),
                          style: const TextStyle(
                            fontSize: 12,
                            color: ColorApp.slate500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockChip extends StatelessWidget {
  const _StockChip({required this.label, required this.isLow});
  final String label;
  final bool isLow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.paddingSm,
        vertical: Dimens.paddingXs,
      ),
      decoration: BoxDecoration(
        color: isLow ? ColorApp.stockLowBg : ColorApp.stockAdequateBg,
        borderRadius: BorderRadius.circular(Dimens.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isLow ? ColorApp.stockLowText : ColorApp.stockAdequateText,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Stock
// ─────────────────────────────────────────────────────────────────────────────

class _StockTab extends StatelessWidget {
  const _StockTab();

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of(context);
    final products = store.products;
    final lowCount = store.lowStockProducts.length;

    if (products.isEmpty) {
      return const Center(child: Text(AppConstants.emptyList));
    }
    return Column(
      children: [
        if (lowCount > 0) _LowStockBanner(count: lowCount),
        Expanded(child: _ProductList(products: products)),
      ],
    );
  }
}

class _LowStockBanner extends StatelessWidget {
  const _LowStockBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: ColorApp.stockLowBg,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.paddingLg,
        vertical: Dimens.paddingSm,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: ColorApp.stockLowText,
            size: 18,
          ),
          const SizedBox(width: Dimens.paddingSm),
          Text(
            '$count ${AppConstants.labelLowStock.toLowerCase()}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: ColorApp.stockLowText,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Por Vencer
// ─────────────────────────────────────────────────────────────────────────────

class _ExpiryTab extends StatelessWidget {
  const _ExpiryTab();

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of(context);
    final expiring = store.expiringSoonProducts;
    final expired = store.expiredProducts;

    if (expiring.isEmpty && expired.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: ColorApp.primaryDark,
              size: 48,
            ),
            SizedBox(height: Dimens.paddingSm),
            Text(
              'Sin productos por vencer',
              style: TextStyle(color: ColorApp.slate500),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        if (expired.isNotEmpty)
          _ExpirySection(
            title: AppConstants.labelExpired,
            products: expired,
            bgColor: ColorApp.expiredBg,
            textColor: ColorApp.expiredText,
          ),
        if (expiring.isNotEmpty)
          _ExpirySection(
            title: AppConstants.labelExpiringSoon,
            products: expiring,
            bgColor: ColorApp.expiringBg,
            textColor: ColorApp.expiringText,
          ),
      ],
    );
  }
}

class _ExpirySection extends StatelessWidget {
  const _ExpirySection({
    required this.title,
    required this.products,
    required this.bgColor,
    required this.textColor,
  });

  final String title;
  final List<InventoryProduct> products;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: bgColor,
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.paddingLg,
            vertical: Dimens.paddingMd,
          ),
          child: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
          ),
        ),
        for (final product in products)
          _ExpiryProductItem(product: product, textColor: textColor),
      ],
    );
  }
}

class _ExpiryProductItem extends StatelessWidget {
  const _ExpiryProductItem({required this.product, required this.textColor});

  final InventoryProduct product;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final expiry = product.expiryDate;
    return ListTile(
      leading: Icon(product.icon, color: textColor),
      title: Text(
        product.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: expiry != null
          ? Text(
              'Vence: ${DateFilter.formatShort(expiry)}',
              style: TextStyle(color: textColor),
            )
          : null,
      trailing: Text(
        '${product.stock} ${product.unit}',
        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }
}
