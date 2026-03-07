import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/purchase.dart';
import '../models/supplier_payment.dart';
import '../res/data/colors.dart';
import '../res/data/constants.dart';
import '../res/data/dimens.dart';
import '../store/store_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_filter.dart';
import 'widgets/module_widgets.dart';

/// Pantalla de Compras con tres pestañas:
/// - Compras: registro y listado de compras.
/// - Proveedores: pagos a proveedores.
/// - Reporte: resumen de compras por período.
class ComprasScreen extends StatefulWidget {
  const ComprasScreen({super.key});

  @override
  State<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen>
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
              colors: [ColorApp.moduleComprasDark, ColorApp.moduleCompras],
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
            Tab(text: AppConstants.tabCompras),
            Tab(text: AppConstants.tabProveedores),
            Tab(text: AppConstants.tabReporte),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_PurchaseTab(), _SupplierTab(), _ComprasReportTab()],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Compras
// ─────────────────────────────────────────────────────────────────────────────

class _PurchaseTab extends StatefulWidget {
  const _PurchaseTab();

  @override
  State<_PurchaseTab> createState() => _PurchaseTabState();
}

class _PurchaseTabState extends State<_PurchaseTab> {
  void _registerPurchase({
    required BuildContext context,
    required String productId,
    required int qty,
    required double price,
    required PaymentMethod payment,
  }) {
    final store = StoreProvider.of(context);
    final idx = store.products.indexWhere((p) => p.id == productId);
    if (idx == -1) return;
    final product = store.products[idx];
    store.addPurchase(
      Purchase(
        id: 'c${DateTime.now().millisecondsSinceEpoch}',
        productId: product.id,
        productName: product.name,
        quantity: qty,
        unitPrice: price,
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
      builder: (sheetCtx) => _AddPurchaseSheet(
        products: store.products,
        onRegister: (productId, qty, price, payment) {
          Navigator.pop(sheetCtx);
          if (!mounted) return;
          _registerPurchase(
            context: context,
            productId: productId,
            qty: qty,
            price: price,
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
      builder: (sheetCtx) => _VoicePurchaseSheet(
        products: store.products,
        onRegister: (productId, qty, price, payment) {
          Navigator.pop(sheetCtx);
          if (!mounted) return;
          _registerPurchase(
            context: context,
            productId: productId,
            qty: qty,
            price: price,
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
        _PurchaseList(purchases: store.purchases),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ModuleActionBar(
            onAdd: () => _openAddSheet(context),
            onVoice: () => _openVoiceSheet(context),
            accentColor: ColorApp.moduleCompras,
            accentBg: ColorApp.moduleComprasBg,
            accentDark: ColorApp.moduleComprasDark,
            accentShadow: ColorApp.moduleComprasShadow,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet: registro manual de compra
// ─────────────────────────────────────────────────────────────────────────────

class _AddPurchaseSheet extends StatefulWidget {
  const _AddPurchaseSheet({required this.products, required this.onRegister});

  final List<dynamic> products;
  final void Function(
    String productId,
    int qty,
    double price,
    PaymentMethod payment,
  )
  onRegister;

  @override
  State<_AddPurchaseSheet> createState() => _AddPurchaseSheetState();
}

class _AddPurchaseSheetState extends State<_AddPurchaseSheet> {
  String _selectedId = '';
  int _qty = 1;
  final _priceController = TextEditingController();
  PaymentMethod _payment = PaymentMethod.efectivo;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  dynamic get _selectedProduct {
    for (final p in widget.products) {
      if ((p.id as String) == _selectedId) return p;
    }
    return null;
  }

  bool get _canSubmit {
    final price = double.tryParse(_priceController.text.trim());
    return _selectedProduct != null && (price ?? 0) > 0;
  }

  @override
  Widget build(BuildContext context) {
    final prod = _selectedProduct;
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
        Dimens.paddingXl + MediaQuery.of(context).viewInsets.bottom,
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
                AppConstants.labelNewCompra,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Dimens.paddingLg),
              // ── Chips de productos ────────────────────────────────────────
              Wrap(
                spacing: Dimens.paddingSm,
                runSpacing: Dimens.paddingSm,
                children: [
                  for (final p in widget.products)
                    _PurchaseProductChip(
                      name: p.name as String,
                      stock: p.stock as int,
                      selected: (p.id as String) == _selectedId,
                      onTap: () => setState(() {
                        _selectedId = p.id as String;
                        _qty = 1;
                      }),
                    ),
                ],
              ),
              if (prod != null) ...[
                const SizedBox(height: Dimens.paddingLg),
                // ── Stepper cantidad ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ModuleQtyStepper(
                      value: _qty,
                      onChanged: (v) => setState(() => _qty = v),
                      accentColor: ColorApp.moduleCompras,
                      accentBg: ColorApp.moduleComprasBg,
                    ),
                  ],
                ),
                const SizedBox(height: Dimens.paddingMd),
                // ── Precio unitario ───────────────────────────────────────
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: moduleRoundedInputDecoration(
                    label: AppConstants.hintUnitPrice,
                    focusColor: ColorApp.moduleCompras,
                  ),
                ),
                const SizedBox(height: Dimens.paddingLg),
                // ── Chips de método de pago ───────────────────────────────
                Wrap(
                  spacing: Dimens.paddingSm,
                  children: [
                    for (final m in PaymentMethod.values)
                      ChoiceChip(
                        label: Text(m.label),
                        selected: _payment == m,
                        selectedColor: ColorApp.moduleComprasBg,
                        labelStyle: TextStyle(
                          color: _payment == m
                              ? ColorApp.moduleCompras
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
                  label: AppConstants.btnRegister,
                  onPressed: _canSubmit
                      ? () => widget.onRegister(
                          _selectedId,
                          _qty,
                          double.parse(_priceController.text.trim()),
                          _payment,
                        )
                      : () {},
                  color: ColorApp.moduleCompras,
                  shadowColor: ColorApp.moduleComprasShadow,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet: dictado por voz — Compra
// ─────────────────────────────────────────────────────────────────────────────

/// Resultado del parseo de voz para una compra.
class _ParsedPurchase {
  const _ParsedPurchase({
    required this.product,
    required this.qty,
    required this.price,
    required this.payment,
  });

  final dynamic product;
  final int qty;
  final double price;
  final PaymentMethod payment;
}

class _VoicePurchaseSheet extends StatefulWidget {
  const _VoicePurchaseSheet({required this.products, required this.onRegister});

  final List<dynamic> products;
  final void Function(
    String productId,
    int qty,
    double price,
    PaymentMethod payment,
  )
  onRegister;

  @override
  State<_VoicePurchaseSheet> createState() => _VoicePurchaseSheetState();
}

class _VoicePurchaseSheetState extends State<_VoicePurchaseSheet> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;
  String _transcript = '';
  String _sessionBase = ''; // acumula texto entre sesiones de escucha
  VoiceSheetMode _mode = VoiceSheetMode.listening;
  String _voiceError = '';

  // ── Editing form state ────────────────────────────────────────────────────
  String _selectedId = '';
  int _qty = 1;
  final _priceController = TextEditingController();
  PaymentMethod _payment = PaymentMethod.efectivo;

  dynamic get _selectedProduct {
    for (final p in widget.products) {
      if ((p.id as String) == _selectedId) return p;
    }
    return null;
  }

  bool get _canSubmit {
    final price = double.tryParse(_priceController.text.trim());
    return _selectedId.isNotEmpty && _qty > 0 && (price ?? 0) > 0;
  }

  @override
  void initState() {
    super.initState();
    _initAndListen();
  }

  @override
  void dispose() {
    _speech.cancel();
    _priceController.dispose();
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
      _priceController.text = parsed.price.toStringAsFixed(0);
      _selectedId = parsed.product.id as String;
      _qty = parsed.qty;
      _payment = parsed.payment;
    } else if (_transcript.isNotEmpty) {
      // Extrae cantidad, precio y pago aunque el producto no fuera identificado
      final text = _normalize(_transcript);
      _payment = _detectPayment(text);
      final numMatches = RegExp(r'\b(\d[\d.,]*)\b').allMatches(text).toList();
      if (numMatches.isNotEmpty) {
        _qty = int.tryParse(numMatches.first.group(1) ?? '') ?? _qty;
        if (numMatches.length >= 2) {
          final raw = (numMatches[1].group(1) ?? '')
              .replaceAll(',', '')
              .replaceAll('.', '');
          final price = double.tryParse(raw);
          if (price != null && price > 0) {
            _priceController.text = price.toStringAsFixed(0);
          }
        }
      }
      if (_priceController.text.isEmpty) {
        final spanishPrice = _parseSpanishAmount(text);
        if (spanishPrice != null) {
          _priceController.text = spanishPrice.toStringAsFixed(0);
        }
      }
    }
    setState(() {
      _isListening = false;
      _mode = VoiceSheetMode.editing;
      _voiceError = '';
    });
  }

  /// Interpreta: "5 arroces a tres mil efectivo"
  /// → qty=5, product=arroz, price=3000, payment=efectivo
  _ParsedPurchase? _parseSpeech(String rawText) {
    final text = _normalize(rawText);
    final payment = _detectPayment(text);

    // 1. Extraer todos los números literales del texto
    final numMatches = RegExp(r'\b(\d[\d.,]*)\b').allMatches(text).toList();
    int qty = 1;
    double? price;

    if (numMatches.isNotEmpty) {
      qty = int.tryParse(numMatches.first.group(1) ?? '') ?? 1;
      if (numMatches.length >= 2) {
        final raw = (numMatches[1].group(1) ?? '')
            .replaceAll(',', '')
            .replaceAll('.', '');
        price = double.tryParse(raw);
      }
    }

    // 2. Si no hay precio literal, buscar en palabras españolas
    price ??= _parseSpanishAmount(text);
    if (price == null || price <= 0) return null;

    // 3. Encontrar el producto con mayor coincidencia de palabras
    dynamic bestProduct;
    int bestScore = 0;
    for (final p in widget.products) {
      final productWords = _normalize(
        p.name as String,
      ).split(' ').where((w) => w.length > 2).toList(growable: false);
      final score = productWords.where(text.contains).length;
      if (score > bestScore) {
        bestScore = score;
        bestProduct = p;
      }
    }
    if (bestProduct == null || bestScore == 0) return null;

    return _ParsedPurchase(
      product: bestProduct,
      qty: qty,
      price: price,
      payment: payment,
    );
  }

  PaymentMethod _detectPayment(String text) {
    if (text.contains('credito') ||
        text.contains('fiado') ||
        text.contains('fio')) {
      return PaymentMethod.credito;
    }
    if (text.contains('nequi') || text.contains('daviplata')) {
      return PaymentMethod.nequi;
    }
    if (text.contains('transferencia') ||
        text.contains('transfer') ||
        text.contains('tarjeta')) {
      return PaymentMethod.transferencia;
    }
    return PaymentMethod.efectivo;
  }

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ModuleSheetHandle(),
              const SizedBox(height: Dimens.paddingLg),
              if (_mode == VoiceSheetMode.listening)
                ..._buildListeningBody()
              else
                ..._buildEditingBody(),
              const SizedBox(height: Dimens.paddingMd),
            ],
          ),
        ),
      ),
    );
  }

  /// Vista de escucha activa: indicador + transcripción en vivo + Detener.
  List<Widget> _buildListeningBody() {
    dynamic sampleProduct;
    for (final p in widget.products) {
      if ((p.stock as int) > 0) {
        sampleProduct = p;
        break;
      }
    }
    if (sampleProduct == null && widget.products.isNotEmpty) {
      sampleProduct = widget.products.first;
    }
    final exHint = sampleProduct != null
        ? 'Di: "3 ${(sampleProduct.name as String).toLowerCase()} precio dos mil"'
        : AppConstants.labelVoiceHintCompraLong;
    return [
      ModuleVoiceExampleHint(exampleText: exHint),
      const SizedBox(height: Dimens.paddingMd),
      ModuleVoiceIndicator(
        isListening: _isListening,
        accentColor: ColorApp.moduleCompras,
        accentDark: ColorApp.moduleComprasDark,
        accentShadow: ColorApp.moduleComprasShadow,
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
          color: ColorApp.moduleCompras,
          shadowColor: ColorApp.moduleComprasShadow,
        ),
    ];
  }

  /// Vista de edición: formulario prellenado para revisar antes de registrar.
  List<Widget> _buildEditingBody() {
    final prod = _selectedProduct;
    return [
      const Text(
        AppConstants.labelVoiceEditTitle,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: Dimens.paddingLg),
      Wrap(
        spacing: Dimens.paddingSm,
        runSpacing: Dimens.paddingSm,
        children: [
          for (final p in widget.products)
            _PurchaseProductChip(
              name: p.name as String,
              stock: p.stock as int,
              selected: (p.id as String) == _selectedId,
              onTap: () => setState(() {
                _selectedId = p.id as String;
                _qty = 1;
              }),
            ),
        ],
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
            accentColor: ColorApp.moduleCompras,
            accentBg: ColorApp.moduleComprasBg,
            fontSize: 18,
            horizontalNumberPadding: Dimens.paddingMd,
          ),
        ],
      ),
      const SizedBox(height: Dimens.paddingMd),
      TextField(
        controller: _priceController,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        decoration: moduleRoundedInputDecoration(
          label: AppConstants.hintUnitPrice,
          focusColor: ColorApp.moduleCompras,
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
              selectedColor: ColorApp.moduleComprasBg,
              labelStyle: TextStyle(
                color: _payment == m
                    ? ColorApp.moduleCompras
                    : ColorApp.slate500,
                fontWeight: _payment == m ? FontWeight.w600 : FontWeight.normal,
              ),
              onSelected: (_) => setState(() => _payment = m),
            ),
        ],
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
              label: _canSubmit && prod != null
                  ? '${AppConstants.btnRegister} · ${CurrencyFormatter.format((double.tryParse(_priceController.text.trim()) ?? 0) * _qty)}'
                  : AppConstants.btnRegister,
              onPressed: _canSubmit
                  ? () => widget.onRegister(
                      _selectedId,
                      _qty,
                      double.parse(_priceController.text.trim()),
                      _payment,
                    )
                  : () {},
              color: _canSubmit ? ColorApp.moduleCompras : ColorApp.slate400,
              shadowColor: _canSubmit
                  ? ColorApp.moduleComprasShadow
                  : ColorApp.slate400,
            ),
          ),
        ],
      ),
    ];
  }
}

/// Chip de producto para el sheet de nueva compra.
class _PurchaseProductChip extends StatelessWidget {
  const _PurchaseProductChip({
    required this.name,
    required this.stock,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final int stock;
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
          color: selected ? ColorApp.moduleComprasBg : ColorApp.backgroundLight,
          borderRadius: BorderRadius.circular(Dimens.radiusXl),
          border: Border.all(
            color: selected ? ColorApp.moduleCompras : ColorApp.borderLight,
            width: selected ? Dimens.borderWidthFocus : Dimens.borderWidth,
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: Dimens.fontSizeSm,
            color: selected ? ColorApp.moduleCompras : ColorApp.slate900,
          ),
        ),
      ),
    );
  }
}

class _PurchaseList extends StatelessWidget {
  const _PurchaseList({required this.purchases});

  final List<Purchase> purchases;

  @override
  Widget build(BuildContext context) {
    if (purchases.isEmpty) {
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
        itemCount: purchases.length,
        itemBuilder: (context, index) {
          final p = purchases[purchases.length - 1 - index];
          return ModuleListItem(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Dimens.paddingLg,
                vertical: Dimens.paddingXs,
              ),
              leading: CircleAvatar(
                backgroundColor: ColorApp.moduleComprasBg,
                child: const Icon(
                  Icons.arrow_downward,
                  color: ColorApp.moduleCompras,
                ),
              ),
              title: Text(
                p.productName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${p.quantity} u. \u00b7 ${p.paymentMethod.label} \u00b7 '
                '${DateFilter.formatShort(p.date)}',
                style: const TextStyle(color: ColorApp.slate500),
              ),
              trailing: Text(
                CurrencyFormatter.format(p.total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorApp.moduleCompras,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Proveedores
// ─────────────────────────────────────────────────────────────────────────────

class _SupplierTab extends StatefulWidget {
  const _SupplierTab();

  @override
  State<_SupplierTab> createState() => _SupplierTabState();
}

class _SupplierTabState extends State<_SupplierTab> {
  void _registerPayment({
    required BuildContext context,
    required String supplierName,
    required double amount,
    required PaymentMethod payment,
  }) {
    StoreProvider.of(context).addSupplierPayment(
      SupplierPayment(
        id: 'sp${DateTime.now().millisecondsSinceEpoch}',
        supplierName: supplierName,
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
      builder: (sheetCtx) => _AddSupplierSheet(
        knownSuppliers: store.knownSupplierNames,
        onRegister: (name, amount, payment) {
          Navigator.pop(sheetCtx);
          if (!mounted) return;
          _registerPayment(
            context: context,
            supplierName: name,
            amount: amount,
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
      builder: (sheetCtx) => _VoiceSupplierSheet(
        knownSuppliers: store.knownSupplierNames,
        onRegister: (name, amount, payment) {
          Navigator.pop(sheetCtx);
          if (!mounted) return;
          _registerPayment(
            context: context,
            supplierName: name,
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
        _SupplierList(payments: store.supplierPayments),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ModuleActionBar(
            onAdd: () => _openAddSheet(context),
            onVoice: () => _openVoiceSheet(context),
            accentColor: ColorApp.moduleCompras,
            accentBg: ColorApp.moduleComprasBg,
            accentDark: ColorApp.moduleComprasDark,
            accentShadow: ColorApp.moduleComprasShadow,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet: registro manual de pago a proveedor
// ─────────────────────────────────────────────────────────────────────────────

class _AddSupplierSheet extends StatefulWidget {
  const _AddSupplierSheet({
    required this.knownSuppliers,
    required this.onRegister,
  });

  final List<String> knownSuppliers;
  final void Function(String supplierName, double amount, PaymentMethod payment)
  onRegister;

  @override
  State<_AddSupplierSheet> createState() => _AddSupplierSheetState();
}

class _AddSupplierSheetState extends State<_AddSupplierSheet> {
  final _supplierController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedSupplier = '';
  PaymentMethod _payment = PaymentMethod.efectivo;

  @override
  void dispose() {
    _supplierController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool get _hasKnownSuppliers => widget.knownSuppliers.isNotEmpty;

  String get _effectiveName {
    final typed = _supplierController.text.trim();
    return typed.isNotEmpty ? typed : _selectedSupplier;
  }

  bool get _canSubmit {
    final amount = double.tryParse(_amountController.text.trim());
    return _effectiveName.isNotEmpty && (amount ?? 0) > 0;
  }

  void _selectSupplier(String name) {
    setState(() {
      _selectedSupplier = name;
      _supplierController.text = name;
      _supplierController.selection = TextSelection.fromPosition(
        TextPosition(offset: name.length),
      );
    });
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
        Dimens.paddingXl + MediaQuery.of(context).viewInsets.bottom,
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
                AppConstants.labelNewProveedor,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Dimens.paddingLg),
              // ── Chips de proveedores anteriores ──────────────────────────
              if (_hasKnownSuppliers) ...[
                const Text(
                  AppConstants.labelKnownSuppliers,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: ColorApp.slate500,
                    fontSize: Dimens.fontSizeSm,
                  ),
                ),
                const SizedBox(height: Dimens.paddingSm),
                Wrap(
                  spacing: Dimens.paddingXs,
                  runSpacing: Dimens.paddingXs,
                  children: [
                    for (final s in widget.knownSuppliers)
                      _SupplierChip(
                        name: s,
                        selected: _selectedSupplier == s,
                        onTap: () => _selectSupplier(s),
                      ),
                  ],
                ),
                const SizedBox(height: Dimens.paddingMd),
              ],
              // ── Campo nombre del proveedor ────────────────────────────────
              TextField(
                controller: _supplierController,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() => _selectedSupplier = ''),
                decoration: moduleRoundedInputDecoration(
                  label: _hasKnownSuppliers
                      ? AppConstants.labelNewClientHint
                      : AppConstants.hintSupplierName,
                  focusColor: ColorApp.moduleCompras,
                ),
              ),
              const SizedBox(height: Dimens.paddingMd),
              // ── Monto ─────────────────────────────────────────────────────
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: moduleRoundedInputDecoration(
                  label: AppConstants.hintAmount,
                  focusColor: ColorApp.moduleCompras,
                ),
              ),
              const SizedBox(height: Dimens.paddingLg),
              // ── Chips de método de pago ───────────────────────────────────
              Wrap(
                spacing: Dimens.paddingSm,
                children: [
                  for (final m in PaymentMethod.values)
                    ChoiceChip(
                      label: Text(m.label),
                      selected: _payment == m,
                      selectedColor: ColorApp.moduleComprasBg,
                      labelStyle: TextStyle(
                        color: _payment == m
                            ? ColorApp.moduleCompras
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
                label: AppConstants.btnRegister,
                onPressed: _canSubmit
                    ? () => widget.onRegister(
                        _effectiveName,
                        double.parse(_amountController.text.trim()),
                        _payment,
                      )
                    : () {},
                color: ColorApp.moduleCompras,
                shadowColor: ColorApp.moduleComprasShadow,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet: dictado por voz — Pago a proveedor
// ─────────────────────────────────────────────────────────────────────────────

/// Resultado del parseo de voz para un pago a proveedor.
class _ParsedSupplier {
  const _ParsedSupplier({
    required this.supplierName,
    required this.amount,
    required this.payment,
  });

  final String supplierName;
  final double amount;
  final PaymentMethod payment;
}

class _VoiceSupplierSheet extends StatefulWidget {
  const _VoiceSupplierSheet({
    required this.onRegister,
    this.knownSuppliers = const [],
  });

  final void Function(String supplierName, double amount, PaymentMethod payment)
  onRegister;
  final List<String> knownSuppliers;

  @override
  State<_VoiceSupplierSheet> createState() => _VoiceSupplierSheetState();
}

class _VoiceSupplierSheetState extends State<_VoiceSupplierSheet> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;
  String _transcript = '';
  String _sessionBase = ''; // acumula texto entre sesiones de escucha
  VoiceSheetMode _mode = VoiceSheetMode.listening;
  String _voiceError = '';

  // ── Editing form state ────────────────────────────────────────────────────
  final _supplierController = TextEditingController();
  final _amountController = TextEditingController();
  PaymentMethod _payment = PaymentMethod.efectivo;

  bool get _canSubmit {
    final amount = double.tryParse(_amountController.text.trim());
    return _supplierController.text.trim().isNotEmpty && (amount ?? 0) > 0;
  }

  @override
  void initState() {
    super.initState();
    _initAndListen();
  }

  @override
  void dispose() {
    _speech.cancel();
    _supplierController.dispose();
    _amountController.dispose();
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
    final parsed = _parseSupplier(_transcript);
    if (parsed != null) {
      _supplierController.text = parsed.supplierName;
      _amountController.text = parsed.amount.toStringAsFixed(0);
      _payment = parsed.payment;
    } else if (_transcript.isNotEmpty) {
      // Extrae pago y monto parcial aunque el nombre no fuera identificado
      final text = _normalize(_transcript);
      _payment = _detectPayment(text);
      final numMatch = RegExp(r'\b(\d[\d.,]*)\b').firstMatch(text);
      if (numMatch != null) {
        final raw = (numMatch.group(1) ?? '')
            .replaceAll(',', '')
            .replaceAll('.', '');
        final amount = double.tryParse(raw);
        if (amount != null && amount > 0) {
          _amountController.text = amount.toStringAsFixed(0);
        }
      } else {
        final spanishAmount = _parseSpanishAmount(text);
        if (spanishAmount != null) {
          _amountController.text = spanishAmount.toStringAsFixed(0);
        }
      }
    }
    setState(() {
      _isListening = false;
      _mode = VoiceSheetMode.editing;
      _voiceError = '';
    });
  }

  /// Interpreta: "Juan cien mil efectivo"
  /// → supplierName=Juan, amount=100000, payment=efectivo
  _ParsedSupplier? _parseSupplier(String rawText) {
    final text = _normalize(rawText);
    final payment = _detectPayment(text);

    double? amount;
    String textSinMonto = text;

    final numMatch = RegExp(r'\b(\d[\d.,]*)\b').firstMatch(text);
    if (numMatch != null) {
      final raw = (numMatch.group(1) ?? '')
          .replaceAll(',', '')
          .replaceAll('.', '');
      amount = double.tryParse(raw);
      textSinMonto = text.replaceFirst(numMatch.group(0) ?? '', '');
    } else {
      amount = _parseSpanishAmount(text);
    }

    if (amount == null || amount <= 0) return null;

    const stopWords = [
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
      'proveedor',
      'pago',
      'a',
    ];
    final words = textSinMonto
        .split(' ')
        .where((w) => w.length > 1 && !stopWords.contains(w))
        .toList(growable: false);

    if (words.isEmpty) return null;
    final name = words
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ')
        .trim();
    if (name.isEmpty) return null;

    return _ParsedSupplier(
      supplierName: name,
      amount: amount,
      payment: payment,
    );
  }

  PaymentMethod _detectPayment(String text) {
    if (text.contains('credito') ||
        text.contains('fiado') ||
        text.contains('fio')) {
      return PaymentMethod.credito;
    }
    if (text.contains('nequi') || text.contains('daviplata')) {
      return PaymentMethod.nequi;
    }
    if (text.contains('transferencia') ||
        text.contains('transfer') ||
        text.contains('tarjeta')) {
      return PaymentMethod.transferencia;
    }
    return PaymentMethod.efectivo;
  }

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ModuleSheetHandle(),
              const SizedBox(height: Dimens.paddingLg),
              if (_mode == VoiceSheetMode.listening)
                ..._buildListeningBody()
              else
                ..._buildEditingBody(),
              const SizedBox(height: Dimens.paddingMd),
            ],
          ),
        ),
      ),
    );
  }

  /// Vista de escucha activa: indicador + transcripción en vivo + Detener.
  List<Widget> _buildListeningBody() {
    final exHint = widget.knownSuppliers.isNotEmpty
        ? 'Di: "${widget.knownSuppliers.first} treinta mil nequi"'
        : AppConstants.labelVoiceHintProveedorLong;
    return [
      ModuleVoiceExampleHint(exampleText: exHint),
      const SizedBox(height: Dimens.paddingMd),
      ModuleVoiceIndicator(
        isListening: _isListening,
        accentColor: ColorApp.moduleCompras,
        accentDark: ColorApp.moduleComprasDark,
        accentShadow: ColorApp.moduleComprasShadow,
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
          color: ColorApp.moduleCompras,
          shadowColor: ColorApp.moduleComprasShadow,
        ),
    ];
  }

  /// Vista de edición: formulario prellenado para revisar antes de registrar.
  List<Widget> _buildEditingBody() {
    return [
      const Text(
        AppConstants.labelVoiceEditTitle,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: Dimens.paddingLg),
      TextField(
        controller: _supplierController,
        textCapitalization: TextCapitalization.words,
        onChanged: (_) => setState(() {}),
        decoration: moduleRoundedInputDecoration(
          label: AppConstants.hintSupplierName,
          focusColor: ColorApp.moduleCompras,
        ),
      ),
      const SizedBox(height: Dimens.paddingMd),
      TextField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        decoration: moduleRoundedInputDecoration(
          label: AppConstants.hintAmount,
          focusColor: ColorApp.moduleCompras,
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
              selectedColor: ColorApp.moduleComprasBg,
              labelStyle: TextStyle(
                color: _payment == m
                    ? ColorApp.moduleCompras
                    : ColorApp.slate500,
                fontWeight: _payment == m ? FontWeight.w600 : FontWeight.normal,
              ),
              onSelected: (_) => setState(() => _payment = m),
            ),
        ],
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
                      _supplierController.text.trim(),
                      double.parse(_amountController.text.trim()),
                      _payment,
                    )
                  : () {},
              color: _canSubmit ? ColorApp.moduleCompras : ColorApp.slate400,
              shadowColor: _canSubmit
                  ? ColorApp.moduleComprasShadow
                  : ColorApp.slate400,
            ),
          ),
        ],
      ),
    ];
  }
}

/// Chip de proveedor conocido para el sheet de pago a proveedor.
class _SupplierChip extends StatelessWidget {
  const _SupplierChip({
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
          color: selected ? ColorApp.moduleComprasBg : ColorApp.backgroundLight,
          borderRadius: BorderRadius.circular(Dimens.radiusXl),
          border: Border.all(
            color: selected ? ColorApp.moduleCompras : ColorApp.borderLight,
            width: selected ? Dimens.borderWidthFocus : Dimens.borderWidth,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.store,
              size: 14,
              color: selected ? ColorApp.moduleCompras : ColorApp.slate400,
            ),
            const SizedBox(width: 4),
            Text(
              name,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: Dimens.fontSizeSm,
                color: selected ? ColorApp.moduleCompras : ColorApp.slate900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierList extends StatelessWidget {
  const _SupplierList({required this.payments});

  final List<SupplierPayment> payments;

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
          return ModuleListItem(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Dimens.paddingLg,
                vertical: Dimens.paddingXs,
              ),
              leading: const CircleAvatar(
                backgroundColor: ColorApp.moduleComprasBg,
                child: Icon(Icons.store, color: ColorApp.moduleCompras),
              ),
              title: Text(
                p.supplierName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${p.paymentMethod.label} \u00b7 ${DateFilter.formatShort(p.date)}',
                style: const TextStyle(color: ColorApp.slate500),
              ),
              trailing: Text(
                CurrencyFormatter.format(p.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorApp.moduleCompras,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Reporte
// ─────────────────────────────────────────────────────────────────────────────

class _ComprasReportTab extends StatefulWidget {
  const _ComprasReportTab();

  @override
  State<_ComprasReportTab> createState() => _ComprasReportTabState();
}

class _ComprasReportTabState extends State<_ComprasReportTab> {
  ReportPeriod _period = ReportPeriod.monthly;

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of(context);
    final now = DateTime.now();
    final filteredPurchases = store.purchasesForPeriod(_period, now);
    final pagosProveedor = store.supplierPayments
        .where((p) => DateFilter.isInPeriod(p.date, now, _period))
        .toList(growable: false);

    final totalCompras = filteredPurchases.fold(0.0, (s, c) => s + c.total);
    final totalPagos = pagosProveedor.fold(0.0, (s, p) => s + p.amount);
    final credito = filteredPurchases
        .where((c) => c.isCredit)
        .fold(0.0, (s, c) => s + c.total);

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
            label: 'Total Compras',
            value: CurrencyFormatter.format(totalCompras),
            color: ColorApp.moduleCompras,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: 'Pagos a Proveedores',
            value: CurrencyFormatter.format(totalPagos),
            color: ColorApp.slate500,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: 'Saldo a Crédito',
            value: CurrencyFormatter.format(credito - totalPagos),
            color: ColorApp.stockLowText,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: 'N° Compras',
            value: '${filteredPurchases.length}',
            color: ColorApp.slate500,
          ),
        ],
      ),
    );
  }
}
