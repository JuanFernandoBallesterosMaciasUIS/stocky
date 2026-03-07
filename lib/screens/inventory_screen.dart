import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/product.dart';
import '../res/data/colors.dart';
import '../res/data/constants.dart';
import '../res/data/dimens.dart';
import '../store/store_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_filter.dart';
import 'inventory_edit_sheet.dart';
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
  void _registerProduct({
    required BuildContext context,
    required String name,
    required int qty,
    required String unit,
    required double cost,
    DateTime? expiryDate,
    int lowStockThreshold = AppConstants.lowStockThreshold,
  }) {
    StoreProvider.of(context).addInventoryProduct(
      InventoryProduct(
        id: 'ip${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        stock: qty,
        unit: unit,
        icon: Icons.inventory_2,
        unitCost: cost,
        expiryDate: expiryDate,
        lowStockThreshold: lowStockThreshold,
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _AddProductSheet(
        onRegister: (name, qty, unit, cost, expiryDate, lowStockThreshold) {
          Navigator.pop(sheetCtx);
          if (!mounted) return;
          _registerProduct(
            context: context,
            name: name,
            qty: qty,
            unit: unit,
            cost: cost,
            expiryDate: expiryDate,
            lowStockThreshold: lowStockThreshold,
          );
        },
      ),
    );
  }

  void _openVoiceSheet(BuildContext context) {
    final store = StoreProvider.of(context);
    final exHint = store.products.isNotEmpty
        ? 'Di: "${store.products.first.name.toLowerCase()} cincuenta unidades costo dos mil"'
        : null;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _VoiceProductSheet(
        exampleHint: exHint,
        onRegister: (name, qty, unit, cost) {
          Navigator.pop(sheetCtx);
          if (!mounted) return;
          _registerProduct(
            context: context,
            name: name,
            qty: qty,
            unit: unit,
            cost: cost,
          );
        },
      ),
    );
  }

  void _openEditSheet(BuildContext context, InventoryProduct product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => InventoryEditSheet(
        product: product,
        onSave: (updated) {
          Navigator.pop(sheetCtx);
          if (!mounted) return;
          StoreProvider.of(context).updateInventoryProduct(updated);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of(context);
    return Stack(
      children: [
        Column(
          children: [
            const _InfoBanner(),
            Expanded(
              child: _ProductList(
                products: store.products,
                showCost: true,
                bottomPadding: Dimens.bottomActionBarPad,
                onEdit: (p) => _openEditSheet(context, p),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ModuleActionBar(
            onAdd: () => _openAddSheet(context),
            onVoice: () => _openVoiceSheet(context),
            accentColor: ColorApp.moduleInventario,
            accentBg: ColorApp.moduleInventarioBg,
            accentDark: ColorApp.moduleInventarioDark,
            accentShadow: ColorApp.moduleInventarioShadow,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet: registro manual de producto
// ─────────────────────────────────────────────────────────────────────────────

class _AddProductSheet extends StatefulWidget {
  const _AddProductSheet({required this.onRegister});

  final void Function(
    String name,
    int qty,
    String unit,
    double cost,
    DateTime? expiryDate,
    int lowStockThreshold,
  )
  onRegister;

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _costController = TextEditingController();
  final _thresholdController = TextEditingController(
    text: AppConstants.lowStockThreshold.toString(),
  );
  int _qty = 1;
  DateTime? _expiryDate;

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _costController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _expiryDate = picked);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return ModuleSheetContainer(
      children: [
        const ModuleSheetHandle(),
        const SizedBox(height: Dimens.paddingMd),
        const Text(
          AppConstants.labelNewProducto,
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
        // ── Alerta de bajo stock ───────────────────────────────────────
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
          label: AppConstants.btnRegister,
          onPressed: _canSubmit
              ? () => widget.onRegister(
                  _nameController.text.trim(),
                  _qty,
                  _unitController.text.trim(),
                  double.parse(_costController.text.trim()),
                  _expiryDate,
                  _parsedThreshold,
                )
              : () {},
          color: ColorApp.moduleInventario,
          shadowColor: ColorApp.moduleInventarioShadow,
          foreground: ColorApp.slate900,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet: dictado por voz — Producto
// ─────────────────────────────────────────────────────────────────────────────

/// Resultado del parseo de voz para un producto.
class _ParsedProduct {
  const _ParsedProduct({
    required this.name,
    required this.qty,
    required this.unit,
    required this.cost,
  });

  final String name;
  final int qty;
  final String unit;
  final double cost;
}

class _VoiceProductSheet extends StatefulWidget {
  const _VoiceProductSheet({required this.onRegister, this.exampleHint});

  final void Function(String name, int qty, String unit, double cost)
  onRegister;
  final String? exampleHint;

  @override
  State<_VoiceProductSheet> createState() => _VoiceProductSheetState();
}

class _VoiceProductSheetState extends State<_VoiceProductSheet> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;
  String _transcript = '';
  String _sessionBase = ''; // acumula texto entre sesiones de escucha
  VoiceSheetMode _mode = VoiceSheetMode.listening;
  String _voiceError = '';

  // ── Form state (editing mode) ─────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _costController = TextEditingController();
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    _initAndListen();
  }

  @override
  void dispose() {
    _speech.cancel();
    _nameController.dispose();
    _unitController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _initAndListen() async {
    _isAvailable = await _speech.initialize(onStatus: _onStatus);
    if (_isAvailable && mounted) _startListening();
  }

  void _onStatus(String status) {
    if ((status == 'done' || status == 'notListening') &&
        _isListening &&
        mounted) {
      // El motor pausó — guardar acumulado y reanudar
      _sessionBase = _transcript;
      _restartListen();
    }
  }

  void _startListening() {
    if (!_isAvailable) return;
    _sessionBase = '';
    setState(() {
      _isListening = true;
      _transcript = '';
      _voiceError = '';
      _mode = VoiceSheetMode.listening;
    });
    _restartListen();
  }

  /// Inicia (o reanuda) el reconocimiento acumulando texto entre sesiones.
  void _restartListen() {
    _speech.listen(
      localeId: 'es_CO',
      pauseFor: AppConstants.voicePauseFor,
      onResult: (result) {
        if (!mounted) return;
        final combined = _sessionBase.isEmpty
            ? result.recognizedWords
            : '$_sessionBase ${result.recognizedWords}';
        setState(() => _transcript = combined.trim());
      },
    );
  }

  /// Detiene la escucha y transiciona siempre al formulario editable.
  /// Rellena lo que se pudo parsear; el resto queda disponible para edición manual.
  void _finishListening() {
    if (!_isListening) return;
    _speech.stop();
    if (!mounted) return;
    final parsed = _parseSpeech(_transcript);
    if (parsed != null) {
      _populateFormFromParsed(parsed);
    } else if (_transcript.isNotEmpty) {
      // Extrae nombre y cantidad aunque falten otros campos
      final text = _normalize(_transcript);
      final words = text.split(' ').where((w) => w.isNotEmpty).toList();
      final numRegex = RegExp(r'^\d+([.,]\d+)?$');
      final nameWords = words
          .where((w) => !numRegex.hasMatch(w.replaceAll(',', '.')))
          .toList(growable: false);
      if (nameWords.isNotEmpty) {
        _nameController.text = nameWords
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
            .join(' ')
            .trim();
      }
      final numbers = words
          .map((w) => double.tryParse(w.replaceAll(',', '.')))
          .whereType<double>()
          .toList(growable: false);
      if (numbers.isNotEmpty) _qty = numbers.first.toInt().clamp(1, 999999);
    }
    setState(() {
      _isListening = false;
      _mode = VoiceSheetMode.editing;
      _voiceError = '';
    });
  }

  /// Rellena los campos del formulario con los datos del parseo.
  void _populateFormFromParsed(_ParsedProduct parsed) {
    _nameController.text = parsed.name;
    _unitController.text = parsed.unit;
    _costController.text = parsed.cost.toStringAsFixed(0);
    _qty = parsed.qty;
  }

  bool get _canSubmit {
    final cost = double.tryParse(_costController.text.trim());
    return _nameController.text.trim().isNotEmpty &&
        _unitController.text.trim().isNotEmpty &&
        (cost ?? 0) > 0 &&
        _qty > 0;
  }

  /// Interpreta: "arroz 100 kilos 5000"
  /// → name="Arroz", qty=100, unit="kilos", cost=5000
  _ParsedProduct? _parseSpeech(String rawText) {
    final text = _normalize(rawText);
    final words = text.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return null;

    const unitWords = [
      'kg',
      'und',
      'paq',
      'kilo',
      'kilos',
      'unidad',
      'unidades',
      'paquete',
      'paquetes',
      'litro',
      'litros',
      'caja',
      'cajas',
    ];

    final numRegex = RegExp(r'^\d+([.,]\d+)?$');
    final numbers = <double>[];
    for (final w in words) {
      final normalized = w.replaceAll(',', '.');
      if (numRegex.hasMatch(normalized)) {
        final v = double.tryParse(normalized);
        if (v != null) numbers.add(v);
      }
    }

    if (numbers.length < 2) return null;
    final qty = numbers.first.toInt();
    final cost = numbers.last;
    if (qty <= 0 || cost <= 0) return null;

    String unit = 'und';
    for (final w in words) {
      if (unitWords.contains(w)) {
        unit = w;
        break;
      }
    }

    final nameWords = words
        .where(
          (w) =>
              !numRegex.hasMatch(w.replaceAll(',', '.')) &&
              !unitWords.contains(w),
        )
        .toList(growable: false);

    if (nameWords.isEmpty) return null;
    final name = nameWords
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ')
        .trim();
    if (name.isEmpty) return null;

    return _ParsedProduct(name: name, qty: qty, unit: unit, cost: cost);
  }

  String _normalize(String input) {
    const accents = 'áéíóúüàèìòùâêîôûäëïöüãõñ';
    const normal = 'aeiouuaeioaeiouaeiouaoon';
    var out = input.toLowerCase();
    for (var i = 0; i < accents.length; i++) {
      out = out.replaceAll(accents[i], normal[i]);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return ModuleSheetContainer(
      children: [
        const ModuleSheetHandle(),
        const SizedBox(height: Dimens.paddingLg),
        if (_mode == VoiceSheetMode.listening)
          ..._buildListeningBody()
        else
          ..._buildEditingBody(),
        const SizedBox(height: Dimens.paddingMd),
      ],
    );
  }

  /// Vista de escucha activa: indicador animado + transcripción en vivo + botón Detener.
  List<Widget> _buildListeningBody() {
    return [
      ModuleVoiceExampleHint(
        exampleText:
            widget.exampleHint ?? AppConstants.labelVoiceHintProductoLong,
      ),
      const SizedBox(height: Dimens.paddingMd),
      ModuleVoiceIndicator(
        isListening: _isListening,
        accentColor: ColorApp.moduleInventario,
        accentDark: ColorApp.moduleInventarioDark,
        accentShadow: ColorApp.moduleInventarioShadow,
      ),
      const SizedBox(height: Dimens.paddingMd),
      Text(
        _isListening
            ? (_transcript.isNotEmpty
                  ? _transcript
                  : AppConstants.labelListening)
            : (_voiceError.isNotEmpty
                  ? _voiceError
                  : AppConstants.labelVoiceHint),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: Dimens.fontSizeSm,
          color: _voiceError.isNotEmpty
              ? ColorApp.stockLowText
              : ColorApp.slate500,
        ),
      ),
      const SizedBox(height: Dimens.paddingLg),
      if (_isListening)
        ModulePrimaryButton(
          label: AppConstants.labelStopListening,
          onPressed: _finishListening,
          color: ColorApp.stockLowText,
          shadowColor: ColorApp.stockLowText,
          foreground: ColorApp.surface,
        )
      else
        ModulePrimaryButton(
          label: AppConstants.labelVoiceRetry,
          onPressed: _startListening,
          color: ColorApp.moduleInventario,
          shadowColor: ColorApp.moduleInventarioShadow,
          foreground: ColorApp.slate900,
        ),
    ];
  }

  /// Vista de edición: formulario prellenado para revisar y ajustar antes de registrar.
  List<Widget> _buildEditingBody() {
    return [
      const Text(
        AppConstants.labelVoiceEditTitle,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: Dimens.paddingLg),
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
      TextField(
        controller: _unitController,
        onChanged: (_) => setState(() {}),
        decoration: moduleRoundedInputDecoration(
          label: AppConstants.hintUnit,
          focusColor: ColorApp.moduleInventario,
        ),
      ),
      const SizedBox(height: Dimens.paddingMd),
      TextField(
        controller: _costController,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        decoration: moduleRoundedInputDecoration(
          label: AppConstants.hintUnitCost,
          focusColor: ColorApp.moduleInventario,
        ),
      ),
      const SizedBox(height: Dimens.paddingLg),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _startListening,
              child: const Text(AppConstants.labelVoiceRetryListening),
            ),
          ),
          const SizedBox(width: Dimens.paddingMd),
          Expanded(
            child: ModulePrimaryButton(
              label: AppConstants.btnRegister,
              onPressed: _canSubmit
                  ? () => widget.onRegister(
                      _nameController.text.trim(),
                      _qty,
                      _unitController.text.trim(),
                      double.parse(_costController.text.trim()),
                    )
                  : () {},
              color: _canSubmit ? ColorApp.moduleInventario : ColorApp.slate400,
              shadowColor: _canSubmit
                  ? ColorApp.moduleInventarioShadow
                  : ColorApp.slate400,
              foreground: ColorApp.slate900,
            ),
          ),
        ],
      ),
    ];
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
  const _ProductList({
    required this.products,
    this.showCost = false,
    this.bottomPadding = 0,
    this.onEdit,
  });
  final List<InventoryProduct> products;
  final bool showCost;
  final double bottomPadding;

  /// Callback opcional que habilita el botón de edición en cada ítem.
  final void Function(InventoryProduct)? onEdit;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return ColoredBox(
        color: ColorApp.listSectionBg,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: const Center(child: Text(AppConstants.emptyList)),
        ),
      );
    }
    return ColoredBox(
      color: ColorApp.listSectionBg,
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: bottomPadding),
        itemCount: products.length,
        itemBuilder: (context, index) => _ProductItem(
          product: products[index],
          showCost: showCost,
          onEdit: onEdit,
        ),
      ),
    );
  }
}

class _ProductItem extends StatelessWidget {
  const _ProductItem({
    required this.product,
    this.showCost = false,
    this.onEdit,
  });
  final InventoryProduct product;
  final bool showCost;

  /// Si se proporciona, muestra un botón de lápiz para editar el producto.
  final void Function(InventoryProduct)? onEdit;

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
            if (onEdit != null)
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: ColorApp.slate400,
                ),
                tooltip: AppConstants.labelEditProduct,
                onPressed: () {
                  final callback = onEdit;
                  if (callback != null) callback(product);
                },
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
