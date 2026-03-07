import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/expense.dart';
import '../models/expense_payment.dart';
import '../res/data/colors.dart';
import '../res/data/constants.dart';
import '../res/data/dimens.dart';
import '../store/store_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_filter.dart';
import 'widgets/module_widgets.dart';

/// Pantalla de Gastos con tres pestañas:
/// - Gastos: registro y listado de gastos operativos.
/// - Pagos: registro de pagos contra gastos a crédito.
/// - Reporte: resumen de egresos por período.
class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen>
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
              colors: [ColorApp.moduleGastosDark, ColorApp.moduleGastos],
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
            Tab(text: AppConstants.tabGastos),
            Tab(text: AppConstants.tabPagos),
            Tab(text: AppConstants.tabReporte),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ExpenseTab(),
          _ExpensePaymentTab(),
          _GastosReportTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Gastos
// ─────────────────────────────────────────────────────────────────────────────

class _ExpenseTab extends StatefulWidget {
  const _ExpenseTab();

  @override
  State<_ExpenseTab> createState() => _ExpenseTabState();
}

class _ExpenseTabState extends State<_ExpenseTab> {
  void _registerExpense({
    required BuildContext context,
    required String description,
    required double amount,
    required PaymentMethod payment,
  }) {
    StoreProvider.of(context).addExpense(
      Expense(
        id: 'g${DateTime.now().millisecondsSinceEpoch}',
        description: description,
        amount: amount,
        paymentMethod: payment,
        date: DateTime.now(),
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _AddExpenseSheet(
        onRegister: (desc, amount, payment) {
          Navigator.pop(sheetCtx);
          if (!mounted) return;
          _registerExpense(
            context: context,
            description: desc,
            amount: amount,
            payment: payment,
          );
        },
      ),
    );
  }

  void _openVoiceSheet(BuildContext context) {
    final store = StoreProvider.of(context);
    final exHint = store.expenses.isNotEmpty
        ? 'Di: "${store.expenses.last.description} ochenta mil efectivo"'
        : null;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _VoiceExpenseSheet(
        exampleHint: exHint,
        onRegister: (desc, amount, payment) {
          Navigator.pop(sheetCtx);
          if (!mounted) return;
          _registerExpense(
            context: context,
            description: desc,
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
        _ExpenseList(expenses: store.expenses),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ModuleActionBar(
            onAdd: () => _openAddSheet(context),
            onVoice: () => _openVoiceSheet(context),
            accentColor: ColorApp.moduleGastos,
            accentBg: ColorApp.moduleGastosBg,
            accentDark: ColorApp.moduleGastosDark,
            accentShadow: ColorApp.moduleGastosShadow,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet: registro manual de gasto
// ─────────────────────────────────────────────────────────────────────────────

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet({required this.onRegister});

  final void Function(String description, double amount, PaymentMethod payment)
  onRegister;

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  PaymentMethod _payment = PaymentMethod.efectivo;

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final amount = double.tryParse(_amountController.text.trim());
    return _descController.text.trim().isNotEmpty && (amount ?? 0) > 0;
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
                AppConstants.labelNewGasto,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Dimens.paddingLg),
              // ── Descripción ──────────────────────────────────────────────
              TextField(
                controller: _descController,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: moduleRoundedInputDecoration(
                  label: AppConstants.hintExpenseDescription,
                  focusColor: ColorApp.moduleGastos,
                ),
              ),
              const SizedBox(height: Dimens.paddingMd),
              // ── Monto ────────────────────────────────────────────────────
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: moduleRoundedInputDecoration(
                  label: AppConstants.hintAmount,
                  focusColor: ColorApp.moduleGastos,
                ),
              ),
              const SizedBox(height: Dimens.paddingLg),
              // ── Chips de método de pago ──────────────────────────────────
              Wrap(
                spacing: Dimens.paddingSm,
                children: [
                  for (final m in PaymentMethod.values)
                    ChoiceChip(
                      label: Text(m.label),
                      selected: _payment == m,
                      selectedColor: ColorApp.moduleGastosBg,
                      labelStyle: TextStyle(
                        color: _payment == m
                            ? ColorApp.moduleGastos
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
                        _descController.text.trim(),
                        double.parse(_amountController.text.trim()),
                        _payment,
                      )
                    : () {},
                color: ColorApp.moduleGastos,
                shadowColor: ColorApp.moduleGastosShadow,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet: dictado por voz — Gasto
// ─────────────────────────────────────────────────────────────────────────────

/// Resultado del parseo de voz para un gasto.
class _ParsedExpense {
  const _ParsedExpense({
    required this.description,
    required this.amount,
    required this.payment,
  });

  final String description;
  final double amount;
  final PaymentMethod payment;
}

class _VoiceExpenseSheet extends StatefulWidget {
  const _VoiceExpenseSheet({required this.onRegister, this.exampleHint});

  final void Function(String description, double amount, PaymentMethod payment)
  onRegister;
  final String? exampleHint;

  @override
  State<_VoiceExpenseSheet> createState() => _VoiceExpenseSheetState();
}

class _VoiceExpenseSheetState extends State<_VoiceExpenseSheet> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;
  String _transcript = '';
  String _sessionBase = ''; // acumula texto entre sesiones de escucha
  VoiceSheetMode _mode = VoiceSheetMode.listening;
  String _voiceError = '';

  // ── Editing form state ────────────────────────────────────────────────────
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  PaymentMethod _payment = PaymentMethod.efectivo;

  bool get _canSubmit {
    final amount = double.tryParse(_amountController.text.trim());
    return _descController.text.trim().isNotEmpty && (amount ?? 0) > 0;
  }

  @override
  void initState() {
    super.initState();
    _initAndListen();
  }

  @override
  void dispose() {
    _speech.cancel();
    _descController.dispose();
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
    final parsed = _parseSpeech(_transcript);
    if (parsed != null) {
      _descController.text = parsed.description;
      _amountController.text = parsed.amount.toStringAsFixed(0);
      _payment = parsed.payment;
    } else if (_transcript.isNotEmpty) {
      // Extrae pago y monto parcial aunque la descripción no fuera identificada
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

  /// Interpreta: "arriendo ochenta mil efectivo"
  /// → description="arriendo", amount=80000, payment=efectivo
  _ParsedExpense? _parseSpeech(String rawText) {
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
      'gasto',
      'pague',
      'pago',
    ];
    final words = textSinMonto
        .split(' ')
        .where((w) => w.length > 1 && !stopWords.contains(w))
        .toList(growable: false);

    if (words.isEmpty) return null;
    final desc = words
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ')
        .trim();
    if (desc.isEmpty) return null;

    return _ParsedExpense(description: desc, amount: amount, payment: payment);
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
    return [
      ModuleVoiceExampleHint(
        exampleText: widget.exampleHint ?? AppConstants.labelVoiceHintGastoLong,
      ),
      const SizedBox(height: Dimens.paddingMd),
      ModuleVoiceIndicator(
        isListening: _isListening,
        accentColor: ColorApp.moduleGastos,
        accentDark: ColorApp.moduleGastosDark,
        accentShadow: ColorApp.moduleGastosShadow,
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
          color: ColorApp.moduleGastos,
          shadowColor: ColorApp.moduleGastosShadow,
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
        controller: _descController,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) => setState(() {}),
        decoration: moduleRoundedInputDecoration(
          label: AppConstants.hintExpenseDescription,
          focusColor: ColorApp.moduleGastos,
        ),
      ),
      const SizedBox(height: Dimens.paddingMd),
      TextField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        decoration: moduleRoundedInputDecoration(
          label: AppConstants.hintAmount,
          focusColor: ColorApp.moduleGastos,
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
              selectedColor: ColorApp.moduleGastosBg,
              labelStyle: TextStyle(
                color: _payment == m
                    ? ColorApp.moduleGastos
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
                      _descController.text.trim(),
                      double.parse(_amountController.text.trim()),
                      _payment,
                    )
                  : () {},
              color: _canSubmit ? ColorApp.moduleGastos : ColorApp.slate400,
              shadowColor: _canSubmit
                  ? ColorApp.moduleGastosShadow
                  : ColorApp.slate400,
            ),
          ),
        ],
      ),
    ];
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({required this.expenses});
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
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
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final e = expenses[expenses.length - 1 - index];
          return ModuleListItem(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Dimens.paddingLg,
                vertical: Dimens.paddingXs,
              ),
              leading: CircleAvatar(
                backgroundColor: ColorApp.moduleGastosBg,
                child: const Icon(
                  Icons.receipt_long,
                  color: ColorApp.moduleGastos,
                ),
              ),
              title: Text(
                e.description,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${e.paymentMethod.label} \u00b7 ${DateFilter.formatShort(e.date)}',
                style: const TextStyle(color: ColorApp.slate500),
              ),
              trailing: Text(
                CurrencyFormatter.format(e.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorApp.moduleGastos,
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
// Tab Pagos
// ─────────────────────────────────────────────────────────────────────────────

class _ExpensePaymentTab extends StatefulWidget {
  const _ExpensePaymentTab();

  @override
  State<_ExpensePaymentTab> createState() => _ExpensePaymentTabState();
}

class _ExpensePaymentTabState extends State<_ExpensePaymentTab> {
  void _registerPayment({
    required BuildContext context,
    required String description,
    required double amount,
    required PaymentMethod payment,
  }) {
    StoreProvider.of(context).addExpensePayment(
      ExpensePayment(
        id: 'pgc${DateTime.now().millisecondsSinceEpoch}',
        description: description,
        amount: amount,
        paymentMethod: payment,
        date: DateTime.now(),
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _AddExpensePaymentSheet(
        onRegister: (desc, amount, payment) {
          Navigator.pop(sheetCtx);
          if (!mounted) return;
          _registerPayment(
            context: context,
            description: desc,
            amount: amount,
            payment: payment,
          );
        },
      ),
    );
  }

  void _openVoiceSheet(BuildContext context) {
    final store = StoreProvider.of(context);
    final exHint = store.expensePayments.isNotEmpty
        ? 'Di: "${store.expensePayments.last.description} veinte mil nequi"'
        : null;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _VoiceExpensePaymentSheet(
        exampleHint: exHint,
        onRegister: (desc, amount, payment) {
          Navigator.pop(sheetCtx);
          if (!mounted) return;
          _registerPayment(
            context: context,
            description: desc,
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
        _ExpensePaymentList(payments: store.expensePayments),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ModuleActionBar(
            onAdd: () => _openAddSheet(context),
            onVoice: () => _openVoiceSheet(context),
            accentColor: ColorApp.moduleGastos,
            accentBg: ColorApp.moduleGastosBg,
            accentDark: ColorApp.moduleGastosDark,
            accentShadow: ColorApp.moduleGastosShadow,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet: registro manual de pago de gasto
// ─────────────────────────────────────────────────────────────────────────────

class _AddExpensePaymentSheet extends StatefulWidget {
  const _AddExpensePaymentSheet({required this.onRegister});

  final void Function(String description, double amount, PaymentMethod payment)
  onRegister;

  @override
  State<_AddExpensePaymentSheet> createState() =>
      _AddExpensePaymentSheetState();
}

class _AddExpensePaymentSheetState extends State<_AddExpensePaymentSheet> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  PaymentMethod _payment = PaymentMethod.efectivo;

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final amount = double.tryParse(_amountController.text.trim());
    return _descController.text.trim().isNotEmpty && (amount ?? 0) > 0;
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
                AppConstants.labelNewPagoGasto,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Dimens.paddingLg),
              // ── Descripción / beneficiario ────────────────────────────
              TextField(
                controller: _descController,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: moduleRoundedInputDecoration(
                  label: AppConstants.hintExpenseDescription,
                  focusColor: ColorApp.moduleGastos,
                ),
              ),
              const SizedBox(height: Dimens.paddingMd),
              // ── Monto ─────────────────────────────────────────────────
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: moduleRoundedInputDecoration(
                  label: AppConstants.hintAmount,
                  focusColor: ColorApp.moduleGastos,
                ),
              ),
              const SizedBox(height: Dimens.paddingLg),
              // ── Chips de método de pago ────────────────────────────────
              Wrap(
                spacing: Dimens.paddingSm,
                children: [
                  for (final m in PaymentMethod.values)
                    ChoiceChip(
                      label: Text(m.label),
                      selected: _payment == m,
                      selectedColor: ColorApp.moduleGastosBg,
                      labelStyle: TextStyle(
                        color: _payment == m
                            ? ColorApp.moduleGastos
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
                        _descController.text.trim(),
                        double.parse(_amountController.text.trim()),
                        _payment,
                      )
                    : () {},
                color: ColorApp.moduleGastos,
                shadowColor: ColorApp.moduleGastosShadow,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet: dictado por voz — Pago de gasto
// ─────────────────────────────────────────────────────────────────────────────

class _VoiceExpensePaymentSheet extends StatefulWidget {
  const _VoiceExpensePaymentSheet({required this.onRegister, this.exampleHint});

  final void Function(String description, double amount, PaymentMethod payment)
  onRegister;
  final String? exampleHint;

  @override
  State<_VoiceExpensePaymentSheet> createState() =>
      _VoiceExpensePaymentSheetState();
}

class _VoiceExpensePaymentSheetState extends State<_VoiceExpensePaymentSheet> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;
  String _transcript = '';
  String _sessionBase = ''; // acumula texto entre sesiones de escucha
  VoiceSheetMode _mode = VoiceSheetMode.listening;
  String _voiceError = '';

  // ── Editing form state ────────────────────────────────────────────────────
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  PaymentMethod _payment = PaymentMethod.efectivo;

  bool get _canSubmit {
    final amount = double.tryParse(_amountController.text.trim());
    return _descController.text.trim().isNotEmpty && (amount ?? 0) > 0;
  }

  @override
  void initState() {
    super.initState();
    _initAndListen();
  }

  @override
  void dispose() {
    _speech.cancel();
    _descController.dispose();
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
    final parsed = _parseSpeech(_transcript);
    if (parsed != null) {
      _descController.text = parsed.description;
      _amountController.text = parsed.amount.toStringAsFixed(0);
      _payment = parsed.payment;
    } else if (_transcript.isNotEmpty) {
      // Extrae pago y monto parcial aunque la descripción no fuera identificada
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

  /// Interpreta: "servicios treinta mil nequi"
  /// → description="servicios", amount=30000, payment=nequi
  _ParsedExpense? _parseSpeech(String rawText) {
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
      'pago',
    ];
    final words = textSinMonto
        .split(' ')
        .where((w) => w.length > 1 && !stopWords.contains(w))
        .toList(growable: false);

    if (words.isEmpty) return null;
    final desc = words
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ')
        .trim();
    if (desc.isEmpty) return null;

    return _ParsedExpense(description: desc, amount: amount, payment: payment);
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
    return [
      ModuleVoiceExampleHint(
        exampleText: widget.exampleHint ?? AppConstants.labelVoiceHintPagoLong,
      ),
      const SizedBox(height: Dimens.paddingMd),
      ModuleVoiceIndicator(
        isListening: _isListening,
        accentColor: ColorApp.moduleGastos,
        accentDark: ColorApp.moduleGastosDark,
        accentShadow: ColorApp.moduleGastosShadow,
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
          color: ColorApp.moduleGastos,
          shadowColor: ColorApp.moduleGastosShadow,
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
        controller: _descController,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) => setState(() {}),
        decoration: moduleRoundedInputDecoration(
          label: AppConstants.hintExpenseDescription,
          focusColor: ColorApp.moduleGastos,
        ),
      ),
      const SizedBox(height: Dimens.paddingMd),
      TextField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        decoration: moduleRoundedInputDecoration(
          label: AppConstants.hintAmount,
          focusColor: ColorApp.moduleGastos,
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
              selectedColor: ColorApp.moduleGastosBg,
              labelStyle: TextStyle(
                color: _payment == m
                    ? ColorApp.moduleGastos
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
                      _descController.text.trim(),
                      double.parse(_amountController.text.trim()),
                      _payment,
                    )
                  : () {},
              color: _canSubmit ? ColorApp.moduleGastos : ColorApp.slate400,
              shadowColor: _canSubmit
                  ? ColorApp.moduleGastosShadow
                  : ColorApp.slate400,
            ),
          ),
        ],
      ),
    ];
  }
}

class _ExpensePaymentList extends StatelessWidget {
  const _ExpensePaymentList({required this.payments});
  final List<ExpensePayment> payments;

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
                backgroundColor: ColorApp.moduleGastosBg,
                child: Icon(Icons.payment, color: ColorApp.moduleGastos),
              ),
              title: Text(
                p.description,
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
                  color: ColorApp.moduleGastos,
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

class _GastosReportTab extends StatefulWidget {
  const _GastosReportTab();

  @override
  State<_GastosReportTab> createState() => _GastosReportTabState();
}

class _GastosReportTabState extends State<_GastosReportTab> {
  ReportPeriod _period = ReportPeriod.monthly;

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of(context);
    final now = DateTime.now();
    final filteredExpenses = store.expensesForPeriod(_period, now);
    final pagos = store.expensePayments
        .where((p) => DateFilter.isInPeriod(p.date, now, _period))
        .toList(growable: false);

    final totalGastos = filteredExpenses.fold(0.0, (s, e) => s + e.amount);
    final totalPagos = pagos.fold(0.0, (s, p) => s + p.amount);
    final credito = filteredExpenses
        .where((e) => e.isCredit)
        .fold(0.0, (s, e) => s + e.amount);

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
            label: 'Total Gastos',
            value: CurrencyFormatter.format(totalGastos),
            color: ColorApp.moduleGastos,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: 'Pagos Realizados',
            value: CurrencyFormatter.format(totalPagos),
            color: ColorApp.slate500,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: 'Gastos a Crédito',
            value: CurrencyFormatter.format(credito),
            color: ColorApp.stockLowText,
          ),
          const SizedBox(height: Dimens.paddingSm),
          MetricCard(
            label: 'N° Gastos',
            value: '${filteredExpenses.length}',
            color: ColorApp.slate500,
          ),
        ],
      ),
    );
  }
}
