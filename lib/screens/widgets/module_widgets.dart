import 'package:flutter/material.dart';

import '../../res/data/colors.dart';
import '../../res/data/constants.dart';
import '../../res/data/dimens.dart';

/// Construye un [InputDecoration] con bordes redondeados (radiusXl = 12 px)
/// y color de foco configurable. Centraliza el estilo de los campos de texto
/// de todos los módulos para cumplir con el principio DRY.
InputDecoration moduleRoundedInputDecoration({
  String? label,
  String? hint,
  required Color focusColor,
}) {
  const radius = BorderRadius.all(Radius.circular(Dimens.radiusXl));
  return InputDecoration(
    labelText: label,
    hintText: hint,
    border: const OutlineInputBorder(borderRadius: radius),
    enabledBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: ColorApp.borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: focusColor, width: Dimens.borderWidthFocus),
    ),
  );
}

/// Botón principal de registro con altura fija [Dimens.primaryBtnHeight],
/// bordes redondeados y sombra de color del módulo.
class ModulePrimaryButton extends StatelessWidget {
  const ModulePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.color,
    required this.shadowColor,
    this.foreground = ColorApp.surface,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Color shadowColor;

  /// Color del texto/ícono del botón. Por defecto blanco.
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Dimens.primaryBtnHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foreground,
          elevation: Dimens.btnElevation,
          shadowColor: shadowColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(Dimens.radiusXl)),
          ),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Selector de período reutilizado por los reportes de Ingresos, Compras
/// y Gastos. Elimina la duplicación de `_PeriodSelector` en cada módulo.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ReportPeriod>(
      segments: [
        for (final p in ReportPeriod.values)
          ButtonSegment<ReportPeriod>(value: p, label: Text(p.label)),
      ],
      selected: {selected},
      onSelectionChanged: (s) {
        if (s.isNotEmpty) onChanged(s.first);
      },
    );
  }
}

/// Tarjeta de métrica para los reportes de módulo.
/// Elimina la duplicación de `_MetricCard` en cada módulo.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimens.paddingLg),
      decoration: BoxDecoration(
        color: ColorApp.surface,
        borderRadius: BorderRadius.circular(Dimens.radiusMd),
        border: Border.all(color: ColorApp.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: ColorApp.slate500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Envuelve un widget hijo en un contenedor blanco con separador inferior,
/// siguiendo el diseño moderno de las listas de módulos.
class ModuleListItem extends StatelessWidget {
  const ModuleListItem({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ColorApp.surface,
        border: Border(bottom: BorderSide(color: ColorApp.borderLight)),
      ),
      child: child,
    );
  }
}

/// Badge informativo que muestra el stock disponible de un producto seleccionado.
/// El color cambia según el nivel:
///   - [moduleColor] (tinte suave) → stock > [lowStockThreshold] (adecuado)
///   - Ámbar  → 0 < stock ≤ [lowStockThreshold] (bajo)
///   - Rojo   → stock == 0 (agotado)
class StockBadge extends StatelessWidget {
  const StockBadge({
    super.key,
    required this.stock,
    required this.unit,
    this.moduleColor,
    this.lowStockThreshold = AppConstants.lowStockThreshold,
  });

  final int stock;
  final String unit;

  /// Color del módulo que se aplica cuando el stock es adecuado.
  /// Si es null se usa el verde por defecto.
  final Color? moduleColor;

  /// Umbral por debajo del cual el stock se clasifica como bajo.
  final int lowStockThreshold;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final IconData icon;
    if (stock == 0) {
      bg = ColorApp.stockLowBg;
      fg = ColorApp.stockLowText;
      icon = Icons.remove_shopping_cart_outlined;
    } else if (stock <= lowStockThreshold) {
      bg = ColorApp.stockWarningBg;
      fg = ColorApp.stockWarningText;
      icon = Icons.warning_amber_rounded;
    } else {
      final Color base = moduleColor ?? ColorApp.stockAdequateText;
      bg = base.withAlpha(30); // ~12 % opacidad
      fg = base;
      icon = Icons.inventory_2_outlined;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.paddingMd,
        vertical: Dimens.paddingXs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Dimens.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: Dimens.iconSizeSm, color: fg),
          const SizedBox(width: Dimens.paddingXs),
          Text(
            '${AppConstants.labelStockDisponible}$stock $unit',
            style: TextStyle(
              fontSize: Dimens.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fondo gris para el estado vacío de listas, reutilizado en todos los
/// módulos para evitar duplicar el mismo [ColoredBox] + [Center].
class ModuleEmptyList extends StatelessWidget {
  const ModuleEmptyList({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: ColorApp.listSectionBg,
      child: Center(child: Text(AppConstants.emptyList)),
    );
  }
}
