import 'package:flutter/material.dart';

import '../models/product.dart';
import '../res/data/colors.dart';
import '../res/data/constants.dart';
import '../res/data/dimens.dart';
import '../utils/date_filter.dart';
import 'widgets/module_widgets.dart';

/// Bottom sheet para editar un [InventoryProduct] existente.
///
/// Pre-carga todos los campos con los valores actuales del producto.
/// Llama a [onSave] con el producto actualizado al confirmar.
class InventoryEditSheet extends StatefulWidget {
  const InventoryEditSheet({
    super.key,
    required this.product,
    required this.onSave,
  });

  final InventoryProduct product;
  final void Function(InventoryProduct updated) onSave;

  @override
  State<InventoryEditSheet> createState() => _InventoryEditSheetState();
}

class _InventoryEditSheetState extends State<InventoryEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  late final TextEditingController _costController;
  late final TextEditingController _thresholdController;
  late int _qty;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p.name);
    _unitController = TextEditingController(text: p.unit);
    _costController = TextEditingController(text: p.unitCost.toString());
    _thresholdController = TextEditingController(
      text: p.lowStockThreshold.toString(),
    );
    _qty = p.stock;
    _expiryDate = p.expiryDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _costController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool get _canSubmit {
    final cost = double.tryParse(_costController.text.trim());
    return _nameController.text.trim().isNotEmpty &&
        _unitController.text.trim().isNotEmpty &&
        (cost ?? 0) > 0 &&
        _qty > 0;
  }

  int get _parsedThreshold {
    final v = int.tryParse(_thresholdController.text.trim());
    return (v != null && v > 0) ? v : AppConstants.lowStockThreshold;
  }

  Future<void> _pickExpiryDate() async {
    final initial = _expiryDate ?? DateTime.now().add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _expiryDate = picked);
    }
  }

  void _submit() {
    if (!_canSubmit) return;
    widget.onSave(
      InventoryProduct(
        id: widget.product.id,
        name: _nameController.text.trim(),
        stock: _qty,
        unit: _unitController.text.trim(),
        icon: widget.product.icon,
        unitCost: double.parse(_costController.text.trim()),
        expiryDate: _expiryDate,
        lowStockThreshold: _parsedThreshold,
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ModuleSheetContainer(
      children: [
        const ModuleSheetHandle(),
        const SizedBox(height: Dimens.paddingMd),
        const Text(
          AppConstants.labelEditProduct,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: Dimens.paddingLg),
        // ── Nombre ────────────────────────────────────────────────────
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: moduleRoundedInputDecoration(
            label: AppConstants.hintProductName,
            focusColor: ColorApp.moduleInventario,
          ),
        ),
        const SizedBox(height: Dimens.paddingMd),
        // ── Cantidad ──────────────────────────────────────────────────
        Row(
          children: [
            const Text(
              AppConstants.hintQuantity,
              style: TextStyle(color: ColorApp.slate500),
            ),
            const Spacer(),
            ModuleQtyStepper(
              value: _qty,
              onChanged: (v) => setState(() => _qty = v),
              accentColor: ColorApp.moduleInventario,
              accentBg: ColorApp.moduleInventarioBg,
              fontSize: 18,
              horizontalNumberPadding: Dimens.paddingMd,
            ),
          ],
        ),
        const SizedBox(height: Dimens.paddingMd),
        // ── Unidad ────────────────────────────────────────────────────
        TextField(
          controller: _unitController,
          onChanged: (_) => setState(() {}),
          decoration: moduleRoundedInputDecoration(
            label: AppConstants.hintUnit,
            focusColor: ColorApp.moduleInventario,
          ),
        ),
        const SizedBox(height: Dimens.paddingMd),
        // ── Costo unitario ────────────────────────────────────────────
        TextField(
          controller: _costController,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: moduleRoundedInputDecoration(
            label: AppConstants.hintUnitCost,
            focusColor: ColorApp.moduleInventario,
          ),
        ),
        const SizedBox(height: Dimens.paddingMd),
        // ── Alerta de bajo stock ──────────────────────────────────────
        TextField(
          controller: _thresholdController,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: moduleRoundedInputDecoration(
            label: AppConstants.hintLowStockThreshold,
            focusColor: ColorApp.moduleInventario,
          ),
        ),
        const SizedBox(height: Dimens.paddingMd),
        // ── Fecha de vencimiento ──────────────────────────────────────
        InkWell(
          onTap: _pickExpiryDate,
          borderRadius: BorderRadius.circular(Dimens.radiusMd),
          child: InputDecorator(
            decoration:
                moduleRoundedInputDecoration(
                  label: AppConstants.labelHintExpiry,
                  focusColor: ColorApp.moduleInventario,
                ).copyWith(
                  suffixIcon: _expiryDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _expiryDate = null),
                        )
                      : const Icon(Icons.calendar_today_outlined, size: 18),
                ),
            child: Text(
              _expiryDate != null
                  ? DateFilter.formatShort(_expiryDate!)
                  : AppConstants.labelNoExpiryDate,
              style: TextStyle(
                color: _expiryDate != null
                    ? ColorApp.slate900
                    : ColorApp.slate400,
              ),
            ),
          ),
        ),
        const SizedBox(height: Dimens.paddingLg),
        ModulePrimaryButton(
          label: AppConstants.btnSave,
          onPressed: _canSubmit ? _submit : () {},
          color: ColorApp.moduleInventario,
          shadowColor: ColorApp.moduleInventarioShadow,
          foreground: ColorApp.slate900,
        ),
      ],
    );
  }
}
