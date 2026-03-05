import '../res/data/constants.dart';

/// Utilidad para filtrar fechas según un [ReportPeriod].
///
/// Responsabilidad única: encapsular la lógica de comparación temporal
/// sin efectos secundarios ni estado mutable.
abstract final class DateFilter {
  /// Devuelve `true` si [date] pertenece al periodo indicado respecto
  /// a la fecha de referencia [reference].
  ///
  /// - [ReportPeriod.daily]: mismo año + mes + día.
  /// - [ReportPeriod.weekly]: misma semana ISO (lunes–domingo).
  /// - [ReportPeriod.monthly]: mismo año + mes.
  static bool isInPeriod(
    DateTime date,
    DateTime reference,
    ReportPeriod period,
  ) {
    switch (period) {
      case ReportPeriod.daily:
        return date.year == reference.year &&
            date.month == reference.month &&
            date.day == reference.day;

      case ReportPeriod.weekly:
        final startOfWeek = reference.subtract(
          Duration(days: reference.weekday - 1),
        );
        final normalizedStart = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        final endOfWeek = normalizedStart.add(const Duration(days: 6));
        final d = DateTime(date.year, date.month, date.day);
        return !d.isBefore(normalizedStart) && !d.isAfter(endOfWeek);

      case ReportPeriod.monthly:
        return date.year == reference.year && date.month == reference.month;
    }
  }

  /// Formatea una fecha a `dd/mm/yyyy` para mostrar en la UI.
  static String formatShort(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }
}
