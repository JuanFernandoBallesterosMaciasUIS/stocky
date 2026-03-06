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
/// Cada sección se mantiene viva en un [Stack] con [AnimatedOpacity]
/// para preservar el estado y animar la transición entre tabs.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  /// Índice de la pestaña actualmente seleccionada.
  int _currentIndex = _NavItem.inventarioIndex;

  /// Pantallas instanciadas una sola vez para preservar su estado.
  final List<Widget> _screens = const [
    IngresosScreen(),
    ComprasScreen(),
    GastosScreen(),
    InventoryScreen(),
    ReportesScreen(),
  ];

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
            child: Stack(
              children: List.generate(_screens.length, (i) {
                return AnimatedOpacity(
                  opacity: i == _currentIndex ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: IgnorePointer(
                    ignoring: i != _currentIndex,
                    child: _screens[i],
                  ),
                );
              }),
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
}

// ─────────────────────────────────────────────
// Widgets privados del MainScaffold
// ─────────────────────────────────────────────

/// Barra de navegación inferior flotante con esquinas redondeadas,
/// sombra y pill indicator animado por módulo.
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorApp.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Dimens.radiusNavTop),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 24,
            spreadRadius: 0,
            offset: Offset(0, -6),
          ),
        ],
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
/// Muestra un pill animado sobre el ícono cuando está activo.
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
    final color = isSelected ? item.activeColor : ColorApp.slate400;

    return InkWell(
      onTap: onTap,
      splashColor: item.activeColor.withAlpha(40),
      highlightColor: Colors.transparent,
      customBorder: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimens.radiusNavTop),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pill indicator superior animado
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: Dimens.navPillHeight,
            width: isSelected ? Dimens.navPillWidth : 0,
            margin: const EdgeInsets.only(bottom: Dimens.paddingXs),
            decoration: BoxDecoration(
              color: item.activeColor,
              borderRadius: BorderRadius.circular(Dimens.radiusFull),
            ),
          ),
          // Ícono con escala animada
          AnimatedScale(
            scale: isSelected ? 1.18 : 1.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: Icon(item.icon, size: Dimens.navIconSize, color: color),
          ),
          const SizedBox(height: Dimens.paddingXs),
          // Etiqueta
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: Dimens.fontSizeXs,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              color: color,
            ),
            child: Text(item.label),
          ),
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
  final Color activeColor;

  const _NavItem({
    required this.index,
    required this.label,
    required this.icon,
    required this.activeColor,
  });

  /// Índice de la pestaña de Inventario.
  static const int inventarioIndex = 3;

  /// Lista completa de ítems en el orden del diseño.
  static const List<_NavItem> all = [
    _NavItem(
      index: 0,
      label: AppConstants.navIngresos,
      icon: Icons.payments,
      activeColor: ColorApp.moduleIngresos,
    ),
    _NavItem(
      index: 1,
      label: AppConstants.navCompras,
      icon: Icons.shopping_cart,
      activeColor: ColorApp.moduleCompras,
    ),
    _NavItem(
      index: 2,
      label: AppConstants.navGastos,
      icon: Icons.receipt_long,
      activeColor: ColorApp.moduleGastos,
    ),
    _NavItem(
      index: inventarioIndex,
      label: AppConstants.navInventario,
      icon: Icons.inventory_2,
      activeColor: ColorApp.moduleInventario,
    ),
    _NavItem(
      index: 4,
      label: AppConstants.navReportes,
      icon: Icons.bar_chart,
      activeColor: ColorApp.moduleReportesIndigo,
    ),
  ];
}
