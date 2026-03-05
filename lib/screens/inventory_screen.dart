import 'package:flutter/material.dart';
import '../models/product.dart';
import '../res/data/colors.dart';
import '../res/data/constants.dart';
import '../res/data/dimens.dart';

/// Pantalla de inventario con dos sub-tabs: Registro Manual e Historial.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Datos de muestra. En producción, provienen de un repositorio/provider.
  final List<Product> _products = const [
    Product(
      id: '1',
      name: 'Café Especial x 500g',
      stock: 45,
      unit: 'und.',
      icon: Icons.local_cafe,
    ),
    Product(
      id: '2',
      name: 'Café Orgánico x 250g',
      stock: 3,
      unit: 'und.',
      icon: Icons.eco,
    ),
    Product(
      id: '3',
      name: 'Filtros de Papel V60',
      stock: 120,
      unit: 'paq.',
      icon: Icons.inventory_2,
    ),
    Product(
      id: '4',
      name: 'Prensa Francesa 1L',
      stock: 1,
      unit: 'und.',
      icon: Icons.blender,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InventoryHeader(tabController: _tabController),
        _InfoBanner(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ManualEntryTab(products: _products),
              _HistoryTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Widgets privados de la pantalla de inventario
// ─────────────────────────────────────────────

/// Encabezado fijo con título y TabBar de la pantalla de inventario.
class _InventoryHeader extends StatelessWidget {
  final TabController tabController;

  const _InventoryHeader({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorApp.backgroundLight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimens.paddingLg,
              vertical: Dimens.paddingMd,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: ColorApp.borderLight,
                  width: Dimens.borderWidth,
                ),
              ),
            ),
            child: const Center(
              child: Text(
                AppConstants.inventoryTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorApp.slate900,
                ),
              ),
            ),
          ),
          // TabBar
          TabBar(
            controller: tabController,
            labelColor: ColorApp.slate900,
            unselectedLabelColor: ColorApp.slate500,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            indicatorColor: ColorApp.primary,
            indicatorWeight: Dimens.tabIndicatorWidth,
            tabs: const [
              Tab(text: AppConstants.tabManualEntry),
              Tab(text: AppConstants.tabHistory),
            ],
          ),
        ],
      ),
    );
  }
}

/// Banner informativo sobre el flujo de actualización del stock.
class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.paddingLg,
        vertical: Dimens.paddingMd,
      ),
      decoration: const BoxDecoration(
        color: ColorApp.infoBannerBg,
        border: Border(
          bottom: BorderSide(
            color: ColorApp.infoBannerBorder,
            width: Dimens.borderWidth,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: ColorApp.primary, size: 20),
          const SizedBox(width: Dimens.paddingMd),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: ColorApp.slate500,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text:
                        'El stock se actualiza automáticamente desde tus registros de ',
                  ),
                  TextSpan(
                    text: 'Compras',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' (ingresos) y '),
                  TextSpan(
                    text: 'Ventas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' (salidas).'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab de registro manual: muestra el listado de productos.
class _ManualEntryTab extends StatelessWidget {
  final List<Product> products;

  const _ManualEntryTab({required this.products});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Encabezado de la sección
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimens.paddingLg,
            Dimens.paddingLg,
            Dimens.paddingLg,
            Dimens.paddingSm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Productos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorApp.slate900,
                ),
              ),
              Text(
                'Total: ${products.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ColorApp.slate500,
                ),
              ),
            ],
          ),
        ),
        // Lista de productos con renderizado perezoso
        Expanded(
          child: ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _ProductItem(product: products[index]);
            },
          ),
        ),
      ],
    );
  }
}

/// Ítem individual de producto en el listado.
class _ProductItem extends StatelessWidget {
  final Product product;

  const _ProductItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: Dimens.productItemMinHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.paddingLg,
        vertical: Dimens.paddingMd,
      ),
      decoration: const BoxDecoration(
        color: ColorApp.surface,
        border: Border(
          bottom: BorderSide(
            color: ColorApp.borderLight,
            width: Dimens.borderWidth,
          ),
        ),
      ),
      child: Row(
        children: [
          _ProductIcon(icon: product.icon),
          const SizedBox(width: Dimens.paddingLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ColorApp.slate900,
                  ),
                ),
                const SizedBox(height: Dimens.paddingXs),
                _StockRow(product: product),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ícono del producto con fondo de color primario.
class _ProductIcon extends StatelessWidget {
  final IconData icon;

  const _ProductIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Dimens.productIconSize,
      height: Dimens.productIconSize,
      decoration: BoxDecoration(
        color: ColorApp.primary.withAlpha(51), // ~20% de opacidad
        borderRadius: BorderRadius.circular(Dimens.radiusMd),
      ),
      child: Icon(
        icon,
        size: Dimens.productIconInnerSize,
        color: ColorApp.primaryDark,
      ),
    );
  }
}

/// Fila de stock con cantidad y badge de estado.
class _StockRow extends StatelessWidget {
  final Product product;

  const _StockRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Stock: ${product.stock} ${product.unit}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: product.isLowStock
                ? FontWeight.w500
                : FontWeight.normal,
            color: product.isLowStock ? ColorApp.stockLowFg : ColorApp.slate500,
          ),
        ),
        const SizedBox(width: Dimens.paddingSm),
        _StockBadge(isLow: product.isLowStock),
      ],
    );
  }
}

/// Badge visual de estado de stock (Adecuado / Bajo Stock).
class _StockBadge extends StatelessWidget {
  final bool isLow;

  const _StockBadge({required this.isLow});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.paddingSm,
        vertical: 2.0,
      ),
      decoration: BoxDecoration(
        color: isLow ? ColorApp.stockLowBg : ColorApp.stockAdequateBg,
        borderRadius: BorderRadius.circular(Dimens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLow) ...[
            const Icon(
              Icons.warning_rounded,
              size: 12,
              color: ColorApp.stockLowText,
            ),
            const SizedBox(width: 2),
          ],
          Text(
            isLow ? AppConstants.labelLowStock : AppConstants.labelAdequate,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isLow ? ColorApp.stockLowText : ColorApp.stockAdequateText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab de historial (pendiente de implementación futura).
class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Historial próximamente',
        style: TextStyle(fontSize: 14, color: ColorApp.slate500),
      ),
    );
  }
}
