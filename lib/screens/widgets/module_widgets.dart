import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

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

/// Campo de texto con botón de dictado por voz integrado.
/// Al pulsar el micrófono (sufijo) inicia el reconocimiento en español;
/// al finalizar coloca el texto en el [controller]. Mantiene el mismo
/// estilo visual que [moduleRoundedInputDecoration].
class VoiceTextField extends StatefulWidget {
  const VoiceTextField({
    super.key,
    required this.controller,
    required this.focusColor,
    this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final Color focusColor;
  final String? label;
  final TextInputType? keyboardType;

  @override
  State<VoiceTextField> createState() => _VoiceTextFieldState();
}

class _VoiceTextFieldState extends State<VoiceTextField> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _speech.initialize(onStatus: _onStatus).then((ok) {
      if (mounted) setState(() => _isAvailable = ok);
    });
  }

  void _onStatus(String status) {
    if ((status == 'done' || status == 'notListening') && mounted) {
      setState(() => _isListening = false);
    }
  }

  Future<void> _toggle() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    if (!_isAvailable) {
      _isAvailable = await _speech.initialize(onStatus: _onStatus);
    }
    if (!_isAvailable || !mounted) return;
    setState(() => _isListening = true);
    await _speech.listen(
      localeId: 'es_CO',
      onResult: (result) {
        widget.controller.text = result.recognizedWords;
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: widget.controller.text.length),
        );
        if (result.finalResult && mounted) {
          setState(() => _isListening = false);
        }
      },
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(Dimens.radiusXl));
    return TextField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(borderRadius: radius),
        enabledBorder: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: ColorApp.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: widget.focusColor,
            width: Dimens.borderWidthFocus,
          ),
        ),
        suffixIcon: _isAvailable
            ? IconButton(
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening ? widget.focusColor : ColorApp.slate400,
                ),
                tooltip: _isListening ? 'Detener' : 'Dictar',
                onPressed: _toggle,
              )
            : null,
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

// ─────────────────────────────────────────────────────────────────────────────
// Widgets de interfaz de voz compartidos (reutilizados en todos los módulos)
// ─────────────────────────────────────────────────────────────────────────────

/// Barra de acción inferior con botón manual (+) y botón de voz (mic).
/// Acepta colores del módulo para cumplir el principio DRY: todos los
/// módulos de entrada reutilizan este widget.
class ModuleActionBar extends StatelessWidget {
  const ModuleActionBar({
    super.key,
    required this.onAdd,
    required this.onVoice,
    required this.accentColor,
    required this.accentBg,
    required this.accentDark,
    required this.accentShadow,
    this.hint = AppConstants.labelVoiceHint,
  });

  final VoidCallback onAdd;
  final VoidCallback onVoice;
  final Color accentColor;
  final Color accentBg;
  final Color accentDark;
  final Color accentShadow;

  /// Texto de ayuda entre los dos botones.
  final String hint;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        Dimens.paddingXl,
        Dimens.paddingMd,
        Dimens.paddingXl,
        Dimens.paddingMd + bottomPad,
      ),
      decoration: const BoxDecoration(
        color: ColorApp.surface,
        boxShadow: [
          BoxShadow(
            color: ColorApp.shadowOverlay,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ModuleAddFab(
            onTap: onAdd,
            accentColor: accentColor,
            accentBg: accentBg,
          ),
          Text(
            hint,
            style: const TextStyle(
              fontSize: Dimens.fontSizeXs,
              color: ColorApp.slate400,
            ),
            textAlign: TextAlign.center,
          ),
          ModuleVoiceFab(
            onTap: onVoice,
            accentDark: accentDark,
            accentShadow: accentShadow,
          ),
        ],
      ),
    );
  }
}

/// Botón circular para abrir el formulario manual de un módulo.
class ModuleAddFab extends StatelessWidget {
  const ModuleAddFab({
    super.key,
    required this.onTap,
    required this.accentColor,
    required this.accentBg,
  });

  final VoidCallback onTap;
  final Color accentColor;
  final Color accentBg;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: Dimens.addFabSize,
        height: Dimens.addFabSize,
        decoration: BoxDecoration(
          color: accentBg,
          shape: BoxShape.circle,
          border: Border.all(
            color: accentColor,
            width: Dimens.borderWidthFocus,
          ),
        ),
        child: Icon(Icons.add, color: accentColor, size: 22),
      ),
    );
  }
}

/// Botón circular de micrófono con gradiente para dictado por voz.
class ModuleVoiceFab extends StatelessWidget {
  const ModuleVoiceFab({
    super.key,
    required this.onTap,
    required this.accentDark,
    required this.accentShadow,
  });

  final VoidCallback onTap;
  final Color accentDark;
  final Color accentShadow;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: Dimens.voiceFabSize,
        height: Dimens.voiceFabSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [accentDark, ColorApp.emeraldCustom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: accentShadow,
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.mic, color: ColorApp.surface, size: 30),
      ),
    );
  }
}

/// Indicador animado de escucha activa de voz.
/// Se expande cuando [isListening] es true.
class ModuleVoiceIndicator extends StatelessWidget {
  const ModuleVoiceIndicator({
    super.key,
    required this.isListening,
    required this.accentDark,
    required this.accentShadow,
  });

  final bool isListening;
  final Color accentDark;
  final Color accentShadow;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isListening ? Dimens.voiceFabSize + 16 : Dimens.voiceFabSize,
      height: isListening ? Dimens.voiceFabSize + 16 : Dimens.voiceFabSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [accentDark, ColorApp.emeraldCustom],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: isListening
            ? [BoxShadow(color: accentShadow, blurRadius: 24, spreadRadius: 6)]
            : null,
      ),
      child: Icon(
        isListening ? Icons.mic : Icons.mic_off,
        color: ColorApp.surface,
        size: 30,
      ),
    );
  }
}

/// Botón circular para incrementar/decrementar cantidad en un stepper.
/// Acepta [accentColor] y [accentBg] para adaptar el estilo a cada módulo.
class ModuleStepperButton extends StatelessWidget {
  const ModuleStepperButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.accentColor,
    required this.accentBg,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final Color accentColor;
  final Color accentBg;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: Dimens.qtyButtonSize,
        height: Dimens.qtyButtonSize,
        decoration: BoxDecoration(
          color: enabled ? accentBg : ColorApp.backgroundLight,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? accentColor : ColorApp.borderLight,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? accentColor : ColorApp.slate400,
        ),
      ),
    );
  }
}

/// Handle de arrastre para bottom sheets — pill centrado.
class ModuleSheetHandle extends StatelessWidget {
  const ModuleSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: Dimens.navPillWidth * 2,
        height: Dimens.navPillHeight + 1,
        decoration: BoxDecoration(
          color: ColorApp.borderLight,
          borderRadius: BorderRadius.circular(Dimens.radiusFull),
        ),
      ),
    );
  }
}
