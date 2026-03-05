/// Formateador de moneda colombiana (COP).
///
/// Responsabilidad única: convertir un [double] a representación
/// legible en pesos colombianos sin depender de paquetes externos.
abstract final class CurrencyFormatter {
  /// Devuelve el valor formateado como pesos colombianos.
  ///
  /// Ejemplo: `format(1234567.0)` → `$1.234.567`
  static String format(double amount) {
    final intPart = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;

    for (int i = intPart.length - 1; i >= 0; i--) {
      buffer.write(intPart[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }

    return '\$${buffer.toString().split('').reversed.join()}';
  }

  /// Devuelve el valor abreviado al separador de miles sin símbolo.
  ///
  /// Útil para chips o espacios compactos. Ej: `1.234.567`
  static String compact(double amount) {
    return format(amount).substring(1);
  }
}
