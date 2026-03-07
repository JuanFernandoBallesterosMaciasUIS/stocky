import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/client_payment.dart';
import '../models/sale.dart';
import '../res/data/colors.dart';
import '../res/data/constants.dart';
import '../res/data/dimens.dart';
import '../store/store_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_filter.dart';
import 'widgets/module_widgets.dart';

/// Pantalla de Ingresos con tres pestaÃ±as:
/// - Ventas: registro y listado de ventas.
/// - Abonos: registro de pagos de clientes crÃ©dito.
/// - Reporte: resumen financiero por perÃ­odo.
class IngresosScreen extends StatefulWidget {
  const IngresosScreen({super.key});

  @override
  State<IngresosScreen> createState() => _IngresosScreenState();
}

class _IngresosScreenState extends State<IngresosScreen>
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
              colors: [ColorApp.moduleIngresosDark, ColorApp.emeraldCustom],
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
            Tab(text: AppConstants.tabVentas),
            Tab(text: AppConstants.tabAbonos),
            Tab(text: AppConstants.tabReporte),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_SaleTab(), _AbonosTab(), _IngresosReportTab()],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Tab Ventas
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SaleTab extends StatefulWidget {
  const _SaleTab();

  @override
  State<_SaleTab> createState() => _SaleTabState();
}

class _SaleTabState extends State<_SaleTab> {
  /// Registra una venta usando el precio fijo del inventario.
  /// Notifica errores con SnackBar en lugar de estado local.
  void _registerSale({
    required BuildContext context,
    required String productId,
    required int qty,
    required PaymentMethod payment,
  }) {
    final store = StoreProvider.of(context);
    final idx = store.products.indexWhere((p) => p.id == productId);
    if (idx == -1) return;
    final product = store.products[idx];
    if (product.stock < qty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppConstants.validationInsufficientStock)),
      );
      return;
    }
    store.addSale(
      Sale(
        id: 'v${DateTime.now().millisecondsSinceEpoch}',
        productId: product.id,
        productName: product.name,
        quantity: qty,
        unitPrice: product.unitCost,
        unitCost: product.unitCost,
        paymentMethod: payment,
        date: DateTime.now(),
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    final store = StoreProvider.of(context);
    if (store.products.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _AddSaleSheet(
        products: store.products,
        onRegister: (id, qty, payment) {
          Navigator.pop(sheetCtx);
          if (!mounted) return;
          _registerSale(
            context: context,
            productId: id,
            qty: qty,
            payment: payment,
          );
        },
      ),
    );
  }

  void _openVoiceSheet(BuildContext context) {
    final store = StoreProvider.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _VoiceSaleSheet(
        products: store.products,
        onRegister: (id, qty, payment) {
          Navigator.pop(sheetCtx);
          if (!mounted) return;
          _registerSale(
            context: context,
            productId: id,
            qty: qty,
            payment: payment,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of(context);
    return Stack(
      children: [
        _SaleList(sales: store.sales),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ModuleActionBar(
            onAdd: () => _openAddSheet(context),
            onVoice: () => _openVoiceSheet(context),
            accentColor: ColorApp.moduleIngresos,
            accentBg: ColorApp.moduleIngresosBg,
            accentDark: ColorApp.moduleIngresosDark,
            accentShadow: ColorApp.moduleIngresosShadow,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barra de acciones inferior (+ manual | 🎤 voz)
// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet: registro manual rápido
// ─────────────────────────────────────────────────────────────────────────────

class _AddSaleSheet extends StatefulWidget {
  const _AddSaleSheet({required this.products, required this.onRegister});

  final List<dynamic> products;
  final void Function(String productId, int qty, PaymentMethod payment)
  onRegister;

  @override
  State<_AddSaleSheet> createState() => _AddSaleSheetState();
}

class _AddSaleSheetState extends State<_AddSaleSheet> {
  String _selectedId = '';
  int _qty = 1;
  PaymentMethod _payment = PaymentMethod.efectivo;

  dynamic get _selectedProduct {
    for (final p in widget.products) {
      if ((p.id as String) == _selectedId) return p;
    }
    return null;
  }

  bool get _canSubmit {
    final prod = _selectedProduct;
    if (prod == null) return false;
    return _qty > 0 && _qty <= (prod.stock as int);
  }

  void _increment() {
    final prod = _selectedProduct;
    if (prod == null) return;
    if (_qty < (prod.stock as int)) setState(() => _qty++);
  }

  void _decrement() {
    if (_qty > 1) setState(() => _qty--);
  }

  @override
  Widget build(BuildContext context) {
    final prod = _selectedProduct;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: ColorApp.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimens.radiusNavTop),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        Dimens.paddingXl,
        Dimens.paddingMd,
        Dimens.paddingXl,
        Dimens.paddingXl + bottomInset,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ModuleSheetHandle(),
            const SizedBox(height: Dimens.paddingMd),
            const Text(
              AppConstants.labelNewSale,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: Dimens.paddingLg),
            Wrap(
              spacing: Dimens.paddingSm,
              runSpacing: Dimens.paddingSm,
              children: [
                for (final p in widget.products)
                  _ProductChip(
                    name: p.name as String,
                    stock: p.stock as int,
                    price: p.unitCost as double,
                    selected: (p.id as String) == _selectedId,
                    onTap: (p.stock as int) > 0
                        ? () => setState(() {
                            _selectedId = p.id as String;
                            _qty = 1;
                          })
                        : null,
                  ),
              ],
            ),
            if (prod != null) ...[
              const SizedBox(height: Dimens.paddingLg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    AppConstants.labelUnitPrice,
                    style: TextStyle(
                      color: ColorApp.slate500,
                      fontSize: Dimens.fontSizeSm,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(prod.unitCost as double),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ColorApp.moduleIngresos,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimens.paddingMd),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ModuleStepperButton(
                    icon: Icons.remove,
                    onTap: _decrement,
                    enabled: _qty > 1,
                    accentColor: ColorApp.moduleIngresos,
                    accentBg: ColorApp.moduleIngresosBg,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimens.paddingXl,
                    ),
                    child: Text(
                      '$_qty',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: ColorApp.slate900,
                      ),
                    ),
                  ),
                  ModuleStepperButton(
                    icon: Icons.add,
                    onTap: _increment,
                    enabled: _qty < (prod.stock as int),
                    accentColor: ColorApp.moduleIngresos,
                    accentBg: ColorApp.moduleIngresosBg,
                  ),
                ],
              ),
              Text(
                '${AppConstants.labelStockDisponible}${prod.stock} ${prod.unit}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: Dimens.fontSizeXs,
                  color: ColorApp.slate500,
                ),
              ),
              const SizedBox(height: Dimens.paddingLg),
              Wrap(
                spacing: Dimens.paddingSm,
                children: [
                  for (final m in PaymentMethod.values)
                    ChoiceChip(
                      label: Text(m.label),
                      selected: _payment == m,
                      selectedColor: ColorApp.moduleIngresosBg,
                      labelStyle: TextStyle(
                        fontSize: Dimens.fontSizeSm,
                        color: _payment == m
                            ? ColorApp.moduleIngresos
                            : ColorApp.slate500,
                        fontWeight: _payment == m
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _payment = m),
                    ),
                ],
              ),
            ],
            const SizedBox(height: Dimens.paddingLg),
            ModulePrimaryButton(
              label: (_canSubmit && prod != null)
                  ? '${AppConstants.btnRegister} · ${CurrencyFormatter.format((prod.unitCost as double) * _qty)}'
                  : AppConstants.btnRegister,
              onPressed: _canSubmit
                  ? () => widget.onRegister(_selectedId, _qty, _payment)
                  : () {},
              color: _canSubmit ? ColorApp.moduleIngresos : ColorApp.slate400,
              shadowColor: _canSubmit
                  ? ColorApp.moduleIngresosShadow
                  : ColorApp.slate400,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductChip extends StatelessWidget {
  const _ProductChip({
    required this.name,
    required this.stock,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final int stock;
  final double price;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasStock = stock > 0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: Dimens.paddingMd,
          vertical: Dimens.paddingSm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? ColorApp.moduleIngresosBg
              : ColorApp.backgroundLight,
          borderRadius: BorderRadius.circular(Dimens.radiusXl),
          border: Border.all(
            color: selected ? ColorApp.moduleIngresos : ColorApp.borderLight,
            width: selected ? Dimens.borderWidthFocus : Dimens.borderWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: Dimens.fontSizeSm,
                color: hasStock ? ColorApp.slate900 : ColorApp.slate400,
              ),
            ),
            Text(
              hasStock
                  ? '$stock disp. · ${CurrencyFormatter.format(price)}'
                  : AppConstants.labelSinStock,
              style: TextStyle(
                fontSize: Dimens.fontSizeXs,
                color: hasStock ? ColorApp.slate500 : ColorApp.stockLowText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip de cliente conocido para el sheet de abonos.
/// Mismo estilo que [_ProductChip] para consistencia visual.
class _ClientChip extends StatelessWidget {
  const _ClientChip({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: Dimens.paddingMd,
          vertical: Dimens.paddingSm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? ColorApp.moduleIngresosBg
              : ColorApp.backgroundLight,
          borderRadius: BorderRadius.circular(Dimens.radiusXl),
          border: Border.all(
            color: selected ? ColorApp.moduleIngresos : ColorApp.borderLight,
            width: selected ? Dimens.borderWidthFocus : Dimens.borderWidth,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline,
              size: 14,
              color: selected ? ColorApp.moduleIngresos : ColorApp.slate400,
            ),
            const SizedBox(width: 4),
            Text(
              name,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: Dimens.fontSizeSm,
                color: selected ? ColorApp.moduleIngresos : ColorApp.slate900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet: dictado por voz
// ─────────────────────────────────────────────────────────────────────────────

/// Resultado del parseo de voz: producto identificado, cantidad y método de pago.
class _ParsedSale {
  const _ParsedSale({
    required this.product,
    required this.qty,
    required this.payment,
  });

  final dynamic product;
  final int qty;
  final PaymentMethod payment;
}

class _VoiceSaleSheet extends StatefulWidget {
  const _VoiceSaleSheet({required this.products, required this.onRegister});

  final List<dynamic> products;
  final void Function(String productId, int qty, PaymentMethod payment)
  onRegister;

  @override
  State<_VoiceSaleSheet> createState() => _VoiceSaleSheetState();
}

class _VoiceSaleSheetState extends State<_VoiceSaleSheet> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;
  String _transcript = '';
  _ParsedSale? _parsed;
  String _voiceError = '';

  @override
  void initState() {
    super.initState();
    _initAndListen();
  }

  /// Inicializa el motor de voz y arranca a escuchar automáticamente.
  Future<void> _initAndListen() async {
    _isAvailable = await _speech.initialize(onStatus: _onStatus);
    if (_isAvailable && mounted) _startListening();
  }

  void _onStatus(String status) {
    if ((status == 'done' || status == 'notListening') && mounted) {
      setState(() => _isListening = false);
    }
  }

  void _startListening() {
    if (!_isAvailable) return;
    setState(() {
      _isListening = true;
      _transcript = '';
      _parsed = null;
      _voiceError = '';
    });
    _speech.listen(
      localeId: 'es_CO',
      onResult: (result) {
        if (!mounted) return;
        setState(() => _transcript = result.recognizedWords);
        if (result.finalResult) {
          final parsed = _parseSpeech(result.recognizedWords);
          setState(() {
            _isListening = false;
            _parsed = parsed;
            _voiceError = parsed == null ? AppConstants.labelVoiceNoMatch : '';
          });
        }
      },
    );
  }

  /// Interpreta el texto de voz: extrae cantidad, producto y método de pago.
  _ParsedSale? _parseSpeech(String rawText) {
    final text = _normalizeForSearch(rawText);

    // 1. Extraer cantidad: primer número entero mencionado
    final numMatch = RegExp(r'\b(\d+)\b').firstMatch(text);
    final qty = numMatch != null ? int.tryParse(numMatch.group(1) ?? '') : null;
    if (qty == null || qty <= 0) return null;

    // 2. Detectar método de pago por palabras clave
    final payment = _detectPayment(text);

    // 3. Encontrar el producto con mayor coincidencia de palabras
    dynamic bestProduct;
    int bestScore = 0;
    for (final p in widget.products) {
      final productWords = _normalizeForSearch(
        p.name as String,
      ).split(' ').where((w) => w.length > 2).toList(growable: false);
      final score = productWords.where(text.contains).length;
      if (score > bestScore) {
        bestScore = score;
        bestProduct = p;
      }
    }
    if (bestProduct == null || bestScore == 0) return null;
    if ((bestProduct.stock as int) < qty) return null;

    return _ParsedSale(product: bestProduct, qty: qty, payment: payment);
  }

  /// Detecta el método de pago a partir de palabras clave normalizadas.
  PaymentMethod _detectPayment(String normalizedText) {
    if (normalizedText.contains('credito') ||
        normalizedText.contains('fiado') ||
        normalizedText.contains('fio')) {
      return PaymentMethod.credito;
    }
    if (normalizedText.contains('nequi') ||
        normalizedText.contains('daviplata')) {
      return PaymentMethod.nequi;
    }
    if (normalizedText.contains('transferencia') ||
        normalizedText.contains('transfer') ||
        normalizedText.contains('tarjeta')) {
      return PaymentMethod.transferencia;
    }
    return PaymentMethod.efectivo;
  }

  /// Convierte el texto a minúsculas y elimina tildes para comparación robusta.
  String _normalizeForSearch(String input) {
    const accents = 'áéíóúüàèìòùâêîôûäëïöüãõñ';
    const normal = 'aeiouuaeioaeiouaeiouaoon';
    var out = input.toLowerCase();
    for (var i = 0; i < accents.length; i++) {
      out = out.replaceAll(accents[i], normal[i]);
    }
    return out;
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ColorApp.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimens.radiusNavTop),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        Dimens.paddingXl,
        Dimens.paddingMd,
        Dimens.paddingXl,
        Dimens.paddingXl + MediaQuery.of(context).padding.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ModuleSheetHandle(),
            const SizedBox(height: Dimens.paddingLg),
            ModuleVoiceIndicator(
              isListening: _isListening,
              accentDark: ColorApp.moduleIngresosDark,
              accentShadow: ColorApp.moduleIngresosShadow,
            ),
            const SizedBox(height: Dimens.paddingMd),
            Text(
              _isListening
                  ? AppConstants.labelListening
                  : _voiceError.isNotEmpty
                  ? _voiceError
                  : _transcript.isEmpty
                  ? AppConstants.labelVoiceHintLong
                  : _transcript,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Dimens.fontSizeSm,
                color: _voiceError.isNotEmpty
                    ? ColorApp.stockLowText
                    : ColorApp.slate500,
              ),
            ),
            if (_parsed != null) ...[
              const SizedBox(height: Dimens.paddingLg),
              _VoiceConfirmCard(parsed: _parsed!),
              const SizedBox(height: Dimens.paddingLg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _startListening,
                      child: const Text(AppConstants.labelVoiceRetry),
                    ),
                  ),
                  const SizedBox(width: Dimens.paddingMd),
                  Expanded(
                    child: ModulePrimaryButton(
                      label: AppConstants.labelVoiceConfirm,
                      onPressed: () => widget.onRegister(
                        _parsed!.product.id as String,
                        _parsed!.qty,
                        _parsed!.payment,
                      ),
                      color: ColorApp.moduleIngresos,
                      shadowColor: ColorApp.moduleIngresosShadow,
                    ),
                  ),
                ],
              ),
            ] else if (!_isListening) ...[
              const SizedBox(height: Dimens.paddingLg),
              ModulePrimaryButton(
                label: AppConstants.labelVoiceRetry,
                onPressed: _startListening,
                color: ColorApp.moduleIngresos,
                shadowColor: ColorApp.moduleIngresosShadow,
              ),
            ],
            const SizedBox(height: Dimens.paddingMd),
          ],
        ),
      ),
    );
  }
}

class _VoiceConfirmCard extends StatelessWidget {
  const _VoiceConfirmCard({required this.parsed});

  final _ParsedSale parsed;

  @override
  Widget build(BuildContext context) {
    final total = (parsed.product.unitCost as double) * parsed.qty;
    return Container(
      padding: const EdgeInsets.all(Dimens.paddingLg),
      decoration: BoxDecoration(
        color: ColorApp.moduleIngresosBg,
        borderRadius: BorderRadius.circular(Dimens.radiusXl),
        border: Border.all(color: ColorApp.moduleIngresos),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            parsed.product.name as String,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: ColorApp.slate900,
            ),
          ),
          const SizedBox(height: Dimens.paddingXs),
          Text(
            '${parsed.qty} u. × ${CurrencyFormatter.format(parsed.product.unitCost as double)} · ${parsed.payment.label}',
            style: const TextStyle(
              fontSize: Dimens.fontSizeSm,
              color: ColorApp.slate500,
            ),
          ),
          const SizedBox(height: Dimens.paddingXs),
          Text(
            CurrencyFormatter.format(total),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: ColorApp.moduleIngresos,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleList extends StatelessWidget {
  const _SaleList({required this.sales});
  final List<Sale> sales;

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) {
      return const ColoredBox(
        color: ColorApp.listSectionBg,
        child: Padding(
          padding: EdgeInsets.only(bottom: Dimens.bottomActionBarPad),
          child: Center(child: Text(AppConstants.emptyList)),
        ),
      );
    }
    return ColoredBox(
      color: ColorApp.listSectionBg,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: Dimens.bottomActionBarPad),
        itemCount: sales.length,
        itemBuilder: (context, index) {
          final s = sales[sales.length - 1 - index];
          return _SaleItem(sale: s);
        },
      ),
    );
  }
}

class _SaleItem extends StatelessWidget {
  const _SaleItem({required this.sale});
  final Sale sale;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ColorApp.surface,
        border: Border(bottom: BorderSide(color: ColorApp.borderLight)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Dimens.paddingLg,
          vertical: Dimens.paddingXs,
        ),
        leading: CircleAvatar(
          backgroundColor: ColorApp.moduleIngresosBg,
          child: const Icon(Icons.arrow_upward, color: ColorApp.moduleIngresos),
        ),
        title: Text(
          sale.productName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${sale.quantity} u. Â· ${sale.paymentMethod.label} Â· '
          '${DateFilter.formatShort(sale.date)}',
          style: const TextStyle(color: ColorApp.slate500),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(sale.total),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: ColorApp.moduleIngresos,
              ),
            ),
            Text(
              'Utilidad: ${CurrencyFormatter.format(sale.grossProfit)}',
              style: const TextStyle(
                fontSize: Dimens.fontSizeXs,
                color: ColorApp.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Tab Abonos
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AbonosTab extends StatefulWidget {
  const _AbonosTab();

  @override
  State<_AbonosTab> createState() => _AbonosTabState();
}

class _AbonosTabState extends State<_AbonosTab> {
  void _registerAbono({
    required BuildContext context,
    required String clientName,
    required double amount,
    required PaymentMethod payment,
  }) {
    final store = StoreProvider.of(context);
    store.addClientPayment(
      ClientPayment(
        id: 'ab${DateTime.now().millisecondsSinceEpoch}',
        clientName: clientName,
        amount: amount,
        paymentMethod: payment,
        date: DateTime.now(),
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    final store = StoreProvider.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _AddAbonoSheet(
        knownClients: store.knownClientNames,
        onRegister: (client, amount, payment) {
          Navigator.pop(sheetCtx);
          if (!mounted) return;
          _registerAbono(
            context: context,
            clientName: client,
            amount: amount,
            payment: payment,
          );
        },
      ),
    );
  }

  void _openVoiceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _VoiceAbonoSheet(
        onRegister: (client, amount, payment) {
          Navigator.pop(sheetCtx);
          if (!mounted) return;
          _registerAbono(
            context: context,
            clientName: client,
            amount: amount,
            payment: payment,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of(context);
    return Stack(
      children: [
        _AbonoList(payments: store.clientPayments),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ModuleActionBar(
            onAdd: () => _openAddSheet(context),
            onVoice: () => _openVoiceSheet(context),
            accentColor: ColorApp.moduleIngresos,
            accentBg: ColorApp.moduleIngresosBg,
            accentDark: ColorApp.moduleIngresosDark,
            accentShadow: ColorApp.moduleIngresosShadow,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet: registro manual de abono
// ─────────────────────────────────────────────────────────────────────────────

class _AddAbonoSheet extends StatefulWidget {
  const _AddAbonoSheet({required this.knownClients, required this.onRegister});

  /// Nombres de clientes ya conocidos (derivados del historial de abonos).
  final List<String> knownClients;
  final void Function(String clientName, double amount, PaymentMethod payment)
  onRegister;

  @override
  State<_AddAbonoSheet> createState() => _AddAbonoSheetState();
}

class _AddAbonoSheetState extends State<_AddAbonoSheet> {
  final _clientController = TextEditingController();
  final _amountController = TextEditingController();
  PaymentMethod _payment = PaymentMethod.efectivo;

  /// Cliente seleccionado desde los chips de clientes conocidos.
  String _selectedClient = '';

  @override
  void initState() {
    super.initState();
    _clientController.addListener(_onClientTextChanged);
    _amountController.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  /// Limpia la selección de chip si el usuario edita manualmente el campo.
  void _onClientTextChanged() {
    final text = _clientController.text.trim();
    if (_selectedClient.isNotEmpty && text != _selectedClient) {
      setState(() => _selectedClient = '');
    } else {
      setState(() {});
    }
  }

  /// Fija el cliente desde un chip y rellena el campo de texto.
  void _selectClient(String name) {
    _selectedClient = name;
    _clientController.text = name;
    _clientController.selection = TextSelection.collapsed(offset: name.length);
    setState(() {});
  }

  @override
  void dispose() {
    _clientController.removeListener(_onClientTextChanged);
    _amountController.removeListener(_rebuild);
    _clientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final amount = double.tryParse(_amountController.text.trim());
    return _clientController.text.trim().isNotEmpty &&
        amount != null &&
        amount > 0;
  }

  void _trySubmit() {
    if (!_canSubmit) return;
    final amount = double.parse(_amountController.text.trim());
    widget.onRegister(_clientController.text.trim(), amount, _payment);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasKnownClients = widget.knownClients.isNotEmpty;
    return Container(
      decoration: const BoxDecoration(
        color: ColorApp.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimens.radiusNavTop),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        Dimens.paddingXl,
        Dimens.paddingMd,
        Dimens.paddingXl,
        Dimens.paddingXl + bottomInset,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ModuleSheetHandle(),
              const SizedBox(height: Dimens.paddingMd),
              const Text(
                AppConstants.labelNewAbono,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Dimens.paddingLg),

              // ── Chips de clientes anteriores ──────────────────────────────
              if (hasKnownClients) ..._buildKnownClientsSection(),

              // ── Campo nombre (sin micrófono) ──────────────────────────────
              TextField(
                controller: _clientController,
                textCapitalization: TextCapitalization.words,
                decoration: moduleRoundedInputDecoration(
                  label: hasKnownClients
                      ? AppConstants.labelNewClientHint
                      : AppConstants.hintClientName,
                  focusColor: ColorApp.moduleIngresos,
                ),
              ),
              const SizedBox(height: Dimens.paddingMd),

              // ── Campo monto (sin micrófono) ───────────────────────────────
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: moduleRoundedInputDecoration(
                  label: AppConstants.hintAmount,
                  focusColor: ColorApp.moduleIngresos,
                ),
              ),
              const SizedBox(height: Dimens.paddingLg),

              // ── Chips de método de pago ───────────────────────────────────
              Wrap(
                spacing: Dimens.paddingSm,
                runSpacing: Dimens.paddingSm,
                children: [
                  for (final m in PaymentMethod.values)
                    ChoiceChip(
                      label: Text(m.label),
                      selected: _payment == m,
                      selectedColor: ColorApp.moduleIngresosBg,
                      labelStyle: TextStyle(
                        fontSize: Dimens.fontSizeSm,
                        color: _payment == m
                            ? ColorApp.moduleIngresos
                            : ColorApp.slate500,
                        fontWeight: _payment == m
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _payment = m),
                    ),
                ],
              ),
              const SizedBox(height: Dimens.paddingLg),
              ModulePrimaryButton(
                label: _canSubmit
                    ? '${AppConstants.btnRegister} · ${CurrencyFormatter.format(double.tryParse(_amountController.text.trim()) ?? 0)}'
                    : AppConstants.btnRegister,
                onPressed: _trySubmit,
                color: _canSubmit ? ColorApp.moduleIngresos : ColorApp.slate400,
                shadowColor: _canSubmit
                    ? ColorApp.moduleIngresosShadow
                    : ColorApp.slate400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la sección de chips de clientes anteriores.
  List<Widget> _buildKnownClientsSection() {
    return [
      const Text(
        AppConstants.labelKnownClients,
        style: TextStyle(
          fontSize: Dimens.fontSizeXs,
          fontWeight: FontWeight.w600,
          color: ColorApp.slate500,
        ),
      ),
      const SizedBox(height: Dimens.paddingSm),
      Wrap(
        spacing: Dimens.paddingSm,
        runSpacing: Dimens.paddingSm,
        children: [
          for (final name in widget.knownClients)
            _ClientChip(
              name: name,
              selected: _selectedClient == name,
              onTap: () => _selectClient(name),
            ),
        ],
      ),
      const SizedBox(height: Dimens.paddingLg),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet: abono por voz
// ─────────────────────────────────────────────────────────────────────────────

class _ParsedAbono {
  const _ParsedAbono({
    required this.clientName,
    required this.amount,
    required this.payment,
  });

  final String clientName;
  final double amount;
  final PaymentMethod payment;
}

class _VoiceAbonoSheet extends StatefulWidget {
  const _VoiceAbonoSheet({required this.onRegister});

  final void Function(String clientName, double amount, PaymentMethod payment)
  onRegister;

  @override
  State<_VoiceAbonoSheet> createState() => _VoiceAbonoSheetState();
}

class _VoiceAbonoSheetState extends State<_VoiceAbonoSheet> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;
  String _transcript = '';
  _ParsedAbono? _parsed;
  String _voiceError = '';

  @override
  void initState() {
    super.initState();
    _initAndListen();
  }

  Future<void> _initAndListen() async {
    _isAvailable = await _speech.initialize(onStatus: _onStatus);
    if (_isAvailable && mounted) _startListening();
  }

  void _onStatus(String status) {
    if ((status == 'done' || status == 'notListening') && mounted) {
      setState(() => _isListening = false);
    }
  }

  void _startListening() {
    if (!_isAvailable) return;
    setState(() {
      _isListening = true;
      _transcript = '';
      _parsed = null;
      _voiceError = '';
    });
    _speech.listen(
      localeId: 'es_CO',
      onResult: (result) {
        if (!mounted) return;
        setState(() => _transcript = result.recognizedWords);
        if (result.finalResult) {
          final parsed = _parseAbono(result.recognizedWords);
          setState(() {
            _isListening = false;
            _parsed = parsed;
            _voiceError = parsed == null
                ? AppConstants.labelVoiceNoMatchAbono
                : '';
          });
        }
      },
    );
  }

  /// Interpreta el texto: extrae nombre de cliente, monto y método de pago.
  /// Ejemplo: "María cincuenta mil nequi" → clientName=María, amount=50000, payment=nequi
  _ParsedAbono? _parseAbono(String rawText) {
    final text = _normalizeForAbono(rawText);

    // 1. Detectar y extraer método de pago
    final payment = _detectPaymentAbono(text);

    // 2. Extraer monto:
    //    Primero busca número literal (ej. "50000" o "50.000")
    //    Luego intenta palabras de cantidad (cien, mil, etc.)
    double? amount;
    String textSinMonto = text;

    // Número literal (dígitos, posiblemente con punto o coma como separador)
    final numMatch = RegExp(r'\b(\d[\d.,]*)\b').firstMatch(text);
    if (numMatch != null) {
      final raw = numMatch.group(1) ?? '';
      final cleaned = raw.replaceAll(',', '').replaceAll('.', '');
      amount = double.tryParse(cleaned);
      textSinMonto = text.replaceFirst(numMatch.group(0) ?? '', '');
    } else {
      // Intentar palabras numéricas básicas (spanish approximate)
      amount = _parseSpanishAmount(text);
    }

    if (amount == null || amount <= 0) return null;

    // 3. Extraer nombre de cliente: palabras restantes sin stop words de pago
    final paymentWords = [
      'nequi',
      'daviplata',
      'transferencia',
      'tarjeta',
      'credito',
      'fiado',
      'efectivo',
      'fio',
      'transfer',
      'mil',
      'pesos',
    ];
    final words = textSinMonto
        .split(' ')
        .where((w) => w.length > 1 && !paymentWords.contains(w))
        .toList(growable: false);

    if (words.isEmpty) return null;
    // Capitalizar primera letra de cada palabra del nombre
    final clientName = words
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ')
        .trim();
    if (clientName.isEmpty) return null;

    return _ParsedAbono(
      clientName: clientName,
      amount: amount,
      payment: payment,
    );
  }

  /// Extrae montos de palabras en español (ej. "cincuenta mil" → 50000).
  double? _parseSpanishAmount(String text) {
    const ones = {
      'uno': 1,
      'dos': 2,
      'tres': 3,
      'cuatro': 4,
      'cinco': 5,
      'seis': 6,
      'siete': 7,
      'ocho': 8,
      'nueve': 9,
      'diez': 10,
      'once': 11,
      'doce': 12,
      'trece': 13,
      'catorce': 14,
      'quince': 15,
      'veinte': 20,
      'treinta': 30,
      'cuarenta': 40,
      'cincuenta': 50,
      'sesenta': 60,
      'setenta': 70,
      'ochenta': 80,
      'noventa': 90,
      'cien': 100,
      'ciento': 100,
      'doscientos': 200,
      'trescientos': 300,
      'cuatrocientos': 400,
      'quinientos': 500,
    };
    int base = 0;
    for (final entry in ones.entries) {
      if (text.contains(entry.key)) base += entry.value;
    }
    if (base == 0) return null;
    return text.contains('mil') ? (base * 1000).toDouble() : base.toDouble();
  }

  PaymentMethod _detectPaymentAbono(String normalizedText) {
    if (normalizedText.contains('credito') ||
        normalizedText.contains('fiado') ||
        normalizedText.contains('fio')) {
      return PaymentMethod.credito;
    }
    if (normalizedText.contains('nequi') ||
        normalizedText.contains('daviplata')) {
      return PaymentMethod.nequi;
    }
    if (normalizedText.contains('transferencia') ||
        normalizedText.contains('transfer') ||
        normalizedText.contains('tarjeta')) {
      return PaymentMethod.transferencia;
    }
    return PaymentMethod.efectivo;
  }

  String _normalizeForAbono(String input) {
    const accents = 'áéíóúüàèìòùâêîôûäëïöüãõñ';
    const normal = 'aeiouuaeioaeiouaeiouaoon';
    var out = input.toLowerCase();
    for (var i = 0; i < accents.length; i++) {
      out = out.replaceAll(accents[i], normal[i]);
    }
    return out;
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ColorApp.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimens.radiusNavTop),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        Dimens.paddingXl,
        Dimens.paddingMd,
        Dimens.paddingXl,
        Dimens.paddingXl + MediaQuery.of(context).padding.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ModuleSheetHandle(),
            const SizedBox(height: Dimens.paddingLg),
            ModuleVoiceIndicator(
              isListening: _isListening,
              accentDark: ColorApp.moduleIngresosDark,
              accentShadow: ColorApp.moduleIngresosShadow,
            ),
            const SizedBox(height: Dimens.paddingMd),
            Text(
              _isListening
                  ? AppConstants.labelListening
                  : _voiceError.isNotEmpty
                  ? _voiceError
                  : _transcript.isEmpty
                  ? AppConstants.labelAbonoVoiceHintLong
                  : _transcript,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Dimens.fontSizeSm,
                color: _voiceError.isNotEmpty
                    ? ColorApp.stockLowText
                    : ColorApp.slate500,
              ),
            ),
            if (_parsed != null) ...[
              const SizedBox(height: Dimens.paddingLg),
              _AbonoConfirmCard(parsed: _parsed!),
              const SizedBox(height: Dimens.paddingLg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _startListening,
                      child: const Text(AppConstants.labelVoiceRetry),
                    ),
                  ),
                  const SizedBox(width: Dimens.paddingMd),
                  Expanded(
                    child: ModulePrimaryButton(
                      label: AppConstants.labelVoiceConfirm,
                      onPressed: () => widget.onRegister(
                        _parsed!.clientName,
                        _parsed!.amount,
                        _parsed!.payment,
                      ),
                      color: ColorApp.moduleIngresos,
                      shadowColor: ColorApp.moduleIngresosShadow,
                    ),
                  ),
                ],
              ),
            ] else if (!_isListening) ...[
              const SizedBox(height: Dimens.paddingLg),
              ModulePrimaryButton(
                label: AppConstants.labelVoiceRetry,
                onPressed: _startListening,
                color: ColorApp.moduleIngresos,
                shadowColor: ColorApp.moduleIngresosShadow,
              ),
            ],
            const SizedBox(height: Dimens.paddingMd),
          ],
        ),
      ),
    );
  }
}

class _AbonoConfirmCard extends StatelessWidget {
  const _AbonoConfirmCard({required this.parsed});

  final _ParsedAbono parsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimens.paddingLg),
      decoration: BoxDecoration(
        color: ColorApp.moduleIngresosBg,
        borderRadius: BorderRadius.circular(Dimens.radiusXl),
        border: Border.all(color: ColorApp.moduleIngresos),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: ColorApp.moduleIngresos,
                child: Icon(Icons.person, color: ColorApp.surface, size: 18),
              ),
              const SizedBox(width: Dimens.paddingSm),
              Expanded(
                child: Text(
                  parsed.clientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: ColorApp.slate900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimens.paddingXs),
          Text(
            parsed.payment.label,
            style: const TextStyle(
              fontSize: Dimens.fontSizeSm,
              color: ColorApp.slate500,
            ),
          ),
          const SizedBox(height: Dimens.paddingXs),
          Text(
            CurrencyFormatter.format(parsed.amount),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: ColorApp.moduleIngresos,
            ),
          ),
        ],
      ),
    );
  }
}

class _AbonoList extends StatelessWidget {
  const _AbonoList({required this.payments});
  final List<ClientPayment> payments;

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return const ColoredBox(
        color: ColorApp.listSectionBg,
        child: Padding(
          padding: EdgeInsets.only(bottom: Dimens.bottomActionBarPad),
          child: Center(child: Text(AppConstants.emptyList)),
        ),
      );
    }
    return ColoredBox(
      color: ColorApp.listSectionBg,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: Dimens.bottomActionBarPad),
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final p = payments[payments.length - 1 - index];
          return Container(
            decoration: const BoxDecoration(
              color: ColorApp.surface,
              border: Border(bottom: BorderSide(color: ColorApp.borderLight)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Dimens.paddingLg,
                vertical: Dimens.paddingXs,
              ),
              leading: const CircleAvatar(
                backgroundColor: ColorApp.moduleIngresosBg,
                child: Icon(Icons.person, color: ColorApp.moduleIngresos),
              ),
              title: Text(
                p.clientName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${p.paymentMethod.label} · ${DateFilter.formatShort(p.date)}',
                style: const TextStyle(color: ColorApp.slate500),
              ),
              trailing: Text(
                CurrencyFormatter.format(p.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorApp.moduleIngresos,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Tab Reporte
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _IngresosReportTab extends StatefulWidget {
  const _IngresosReportTab();

  @override
  State<_IngresosReportTab> createState() => _IngresosReportTabState();
}

class _IngresosReportTabState extends State<_IngresosReportTab> {
  ReportPeriod _period = ReportPeriod.monthly;

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of(context);
    final now = DateTime.now();
    final filteredSales = store.salesForPeriod(_period, now);
    final abonos = store.clientPayments
        .where((p) => DateFilter.isInPeriod(p.date, now, _period))
        .toList(growable: false);

    final totalIngresos = filteredSales.fold(0.0, (s, v) => s + v.total);
    final totalCosto = filteredSales.fold(0.0, (s, v) => s + v.totalCost);
    final utilidad = totalIngresos - totalCosto;
    final totalAbonos = abonos.fold(0.0, (s, p) => s + p.amount);

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
            label: 'Total Ingresos',
            value: CurrencyFormatter.format(totalIngresos),
            color: ColorApp.moduleIngresos,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: 'Costo de Ventas',
            value: CurrencyFormatter.format(totalCosto),
            color: ColorApp.slate500,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: 'Utilidad Bruta',
            value: CurrencyFormatter.format(utilidad),
            color: utilidad >= 0 ? ColorApp.primaryDark : ColorApp.stockLowText,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: 'Abonos Recibidos',
            value: CurrencyFormatter.format(totalAbonos),
            color: ColorApp.moduleIngresos,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: 'NÂ° Ventas',
            value: '${filteredSales.length}',
            color: ColorApp.slate500,
          ),
        ],
      ),
    );
  }
}
