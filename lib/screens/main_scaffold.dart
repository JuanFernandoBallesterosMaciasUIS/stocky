import 'package:flutter/material.dart';
import '../res/data/colors.dart';
import '../res/data/constants.dart';
import '../res/data/dimens.dart';
import 'compras_screen.dart';
import 'gastos_screen.dart';
import 'ingresos_screen.dart';
import 'inventory_screen.dart';
import 'reportes_screen.dart';

/// Scaffold principal de la aplicación con navegación inferior.
/// Cada ítem del nav renderiza su pantalla correspondiente en un [IndexedStack]
/// para preservar el estado entre cambios de tab.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  /// Índice de la pestaña actualmente seleccionada.
  int _currentIndex = _NavItem.inventarioIndex;

  /// Cambia la pestaña activa. Extraído como método para SRP.
  void _onNavItemTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.backgroundLight,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Dimens.maxContentWidth),
            child: IndexedStack(
              index: _currentIndex,
              children: _buildScreens(),
            ),
          ),
        ),
      ),
      floatingActionButton: null,
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }

  /// Construye la lista de pantallas para el [IndexedStack].
  /// Cada pantalla se mantiene viva durante el ciclo de vida del scaffold.
  List<Widget> _buildScreens() {
    return const [
      IngresosScreen(),
      ComprasScreen(),
      GastosScreen(),
      InventoryScreen(),
      ReportesScreen(),
    ];
  }
}

// ─────────────────────────────────────────────
// Widgets privados del MainScaffold
// ─────────────────────────────────────────────

/// Barra de navegación inferior con los cinco ítems del diseño.
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ColorApp.surface,
        border: Border(
          top: BorderSide(
            color: ColorApp.borderLight,
            width: Dimens.borderWidth,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: Dimens.bottomNavHeight,
          child: Row(
            children: _NavItem.all
                .map(
                  (item) => Expanded(
                    child: _NavButton(
                      item: item,
                      isSelected: currentIndex == item.index,
                      onTap: () => onTap(item.index),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

/// Botón individual de la barra de navegación inferior.
class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? ColorApp.primary : ColorApp.slate500;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isSelected)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.paddingLg,
                vertical: Dimens.paddingXs,
              ),
              decoration: BoxDecoration(
                color: ColorApp.primary.withAlpha(51), // ~20% opacidad
                borderRadius: BorderRadius.circular(Dimens.radiusFull),
              ),
              child: Icon(item.icon, size: Dimens.navIconSize, color: color),
            )
          else
            Icon(item.icon, size: Dimens.navIconSize, color: color),
          const SizedBox(height: Dimens.paddingXs),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: Dimens.paddingSm),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Descriptor de ítems del BottomNav
// ─────────────────────────────────────────────

/// Datos de configuración de cada ítem de la barra inferior.
class _NavItem {
  final int index;
  final String label;
  final IconData icon;

  const _NavItem({
    required this.index,
    required this.label,
    required this.icon,
  });

  /// Índice de la pestaña de Inventario.
  static const int inventarioIndex = 3;

  /// Lista completa de ítems en el orden del diseño.
  static const List<_NavItem> all = [
    _NavItem(index: 0, label: AppConstants.navIngresos, icon: Icons.payments),
    _NavItem(
      index: 1,
      label: AppConstants.navCompras,
      icon: Icons.shopping_cart,
    ),
    _NavItem(index: 2, label: AppConstants.navGastos, icon: Icons.receipt_long),
    _NavItem(
      index: inventarioIndex,
      label: AppConstants.navInventario,
      icon: Icons.inventory_2,
    ),
    _NavItem(index: 4, label: AppConstants.navReportes, icon: Icons.bar_chart),
  ];
}
