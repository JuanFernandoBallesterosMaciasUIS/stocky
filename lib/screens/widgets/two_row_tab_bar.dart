import 'package:flutter/material.dart';

import '../../res/data/colors.dart';
import '../../res/data/constants.dart';
import '../../res/data/dimens.dart';

/// TabBar de dos filas para la pantalla de Reportes.
///
/// Distribuye las 5 pestañas en dos filas sin scroll, aprovechando todo
/// el ancho disponible:
///   Fila 1 (flex igual, 3 tabs): Flujo de Caja · Por Cobrar · Por Pagar
///   Fila 2 (flex igual, 2 tabs): Resultado · Kardex
///
/// Implementa [PreferredSizeWidget] para poder usarse como [AppBar.bottom].
/// El fondo es transparente — el gradiente del [AppBar.flexibleSpace] se
/// muestra a través de él.
class TwoRowTabBar extends StatelessWidget implements PreferredSizeWidget {
  const TwoRowTabBar({super.key, required this.controller});

  final TabController controller;

  static const _row1 = [
    AppConstants.tabFlujoCaja,
    AppConstants.tabCuentasCobrar,
    AppConstants.tabCuentasPagar,
  ];

  static const _row2 = [
    AppConstants.tabEstadoResultado,
    AppConstants.tabKardex,
  ];

  @override
  Size get preferredSize => const Size.fromHeight(Dimens.twoRowTabBarHeight);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TabRow(labels: _row1, startIndex: 0, controller: controller),
          _TabRow(labels: _row2, startIndex: 3, controller: controller),
        ],
      ),
    );
  }
}

// ── Fila de tabs ─────────────────────────────────────────────────────────────

class _TabRow extends StatelessWidget {
  const _TabRow({
    required this.labels,
    required this.startIndex,
    required this.controller,
  });

  final List<String> labels;
  final int startIndex;
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < labels.length; i++)
          Expanded(
            child: _TabChip(
              label: labels[i],
              selected: controller.index == startIndex + i,
              onTap: () => controller.animateTo(startIndex + i),
            ),
          ),
      ],
    );
  }
}

// ── Chip individual ───────────────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: ColorApp.surface.withValues(alpha: 0.15),
      highlightColor: Colors.transparent,
      child: Container(
        height: Dimens.twoRowTabRowHeight,
        alignment: Alignment.center,
        decoration: selected
            ? const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: ColorApp.surface,
                    width: Dimens.tabIndicatorWidth,
                  ),
                ),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingSm),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: Dimens.fontSizeTab,
            fontWeight: FontWeight.w600,
            color: selected ? ColorApp.surface : ColorApp.slate100,
          ),
        ),
      ),
    );
  }
}
