import 'package:flutter/material.dart';

import '../../models/kardex_entry.dart';
import '../../res/data/colors.dart';
import '../../res/data/constants.dart';
import '../../res/data/dimens.dart';
import '../../store/store_provider.dart';
import '../../utils/currency_formatter.dart';

/// Pestaña de Kardex en el módulo de Reportes.
///
/// Muestra una tabla con:
/// - Entrada (compras acumuladas), Salida (ventas acumuladas),
///   Existencia (stock actual) y Valor (existencia × costo unitario)
/// por cada producto del inventario.
///
/// Los datos los obtiene del getter [AppStore.kardexEntries], que
/// pre-agrega compras y ventas en O(n) antes de construir cada fila,
/// garantizando que no haya consultas dentro de bucles.
class KardexTab extends StatelessWidget {
  const KardexTab({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = StoreProvider.of(context).kardexEntries;

    if (entries.isEmpty) {
      return const Center(
        child: Text(
          AppConstants.emptyKardex,
          style: TextStyle(color: ColorApp.slate500),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _KardexHeader(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            itemBuilder: (context, index) =>
                _KardexRow(entry: entries[index], isEven: index.isEven),
          ),
          _KardexTotalsRow(entries: entries),
        ],
      ),
    );
  }
}

// ── Cabecera de columnas ────────────────────────────────────────────────────

class _KardexHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorApp.listSectionBg,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.paddingMd,
        vertical: Dimens.paddingSm,
      ),
      child: const Row(
        children: [
          Expanded(
            flex: Dimens.kardexFlexNombre,
            child: Text(AppConstants.labelKardexProducto, style: _headerStyle),
          ),
          _HeaderCell(AppConstants.labelKardexEntrada),
          _HeaderCell(AppConstants.labelKardexSalida),
          _HeaderCell(AppConstants.labelKardexExistencia),
          _HeaderCell(
            AppConstants.labelKardexValor,
            flex: Dimens.kardexFlexValor,
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {this.flex = Dimens.kardexFlexColumna});
  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(label, textAlign: TextAlign.right, style: _headerStyle),
    );
  }
}

// ── Fila de producto ────────────────────────────────────────────────────────

class _KardexRow extends StatelessWidget {
  const _KardexRow({required this.entry, required this.isEven});

  final KardexEntry entry;
  final bool isEven;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isEven ? ColorApp.surface : ColorApp.listSectionBg,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.paddingMd,
        vertical: Dimens.paddingSm,
      ),
      child: Row(
        children: [
          Expanded(
            flex: Dimens.kardexFlexNombre,
            child: Tooltip(
              message: entry.productName,
              child: Text(
                entry.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: Dimens.fontSizeSm),
              ),
            ),
          ),
          _DataCell(entry.entradas.toString()),
          _DataCell(entry.salidas.toString()),
          _DataCell(
            entry.existencia.toString(),
            bold: true,
            color: entry.existencia > 0
                ? ColorApp.primaryDark
                : ColorApp.stockLowText,
          ),
          _DataCell(
            CurrencyFormatter.format(entry.valorTotal),
            flex: Dimens.kardexFlexValor,
          ),
        ],
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  const _DataCell(
    this.text, {
    this.bold = false,
    this.color,
    this.flex = Dimens.kardexFlexColumna,
  });
  final String text;
  final bool bold;
  final Color? color;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: Dimens.fontSizeSm,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
    );
  }
}

// ── Fila de totales ─────────────────────────────────────────────────────────

class _KardexTotalsRow extends StatelessWidget {
  const _KardexTotalsRow({required this.entries});
  final List<KardexEntry> entries;

  @override
  Widget build(BuildContext context) {
    int totalEntradas = 0;
    int totalSalidas = 0;
    int totalExistencia = 0;
    double totalValor = 0;

    for (final e in entries) {
      totalEntradas += e.entradas;
      totalSalidas += e.salidas;
      totalExistencia += e.existencia;
      totalValor += e.valorTotal;
    }

    return Container(
      color: ColorApp.cardBg,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.paddingMd,
        vertical: Dimens.paddingMd,
      ),
      child: Row(
        children: [
          const Expanded(
            flex: Dimens.kardexFlexNombre,
            child: Text(
              AppConstants.labelKardexTotal,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: Dimens.fontSizeSm,
              ),
            ),
          ),
          _TotalCell(totalEntradas.toString()),
          _TotalCell(totalSalidas.toString()),
          _TotalCell(totalExistencia.toString()),
          _TotalCell(
            CurrencyFormatter.format(totalValor),
            flex: Dimens.kardexFlexValor,
          ),
        ],
      ),
    );
  }
}

class _TotalCell extends StatelessWidget {
  const _TotalCell(this.text, {this.flex = Dimens.kardexFlexColumna});
  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: Dimens.fontSizeSm,
          color: ColorApp.primaryDark,
        ),
      ),
    );
  }
}

// ── Estilo compartido ───────────────────────────────────────────────────────

const _headerStyle = TextStyle(
  fontSize: Dimens.fontSizeXs,
  fontWeight: FontWeight.w700,
  color: ColorApp.slate500,
  letterSpacing: 0.4,
);
