import 'package:flutter/material.dart';

/// Paleta de colores centralizada de la aplicación.
/// PROHIBIDO usar Color(0xFF...) directamente en los Widgets.
/// Usar siempre ColorApp.nombreDelColor.
abstract final class ColorApp {
  // Colores primarios
  static const Color primary = Color(0xFF30E86E);
  static const Color primaryDark = Color(0xFF22C55E);

  // Fondos
  static const Color backgroundLight = Color(0xFFF6F8F6);
  static const Color backgroundDark = Color(0xFF112116);

  // Superficies
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B);

  // Texto / Neutros
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);

  // Bordes
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  // Semáforo de stock
  static const Color stockAdequateBg = Color(0xFFDCFCE7);
  static const Color stockAdequateText = Color(0xFF15803D);
  static const Color stockWarningBg = Color(0xFFFFFBEB); // amber-50
  static const Color stockWarningText = Color(0xFF92400E); // amber-800
  static const Color stockLowBg = Color(0xFFFEE2E2);
  static const Color stockLowText = Color(0xFFB91C1C);
  static const Color stockLowFg = Color(0xFFEF4444);

  // Overlay del banner informativo
  static const Color infoBannerBg = Color(
    0x1A30E86E,
  ); // primary con 10% opacidad
  static const Color infoBannerBorder = Color(
    0x3330E86E,
  ); // primary con 20% opacidad

  // Colores por módulo (íconos del nav y encabezados)
  static const Color moduleIngresos = Color(0xFF3B82F6); // Azul
  static const Color moduleCompras = Color(0xFFF97316); // Naranja
  static const Color moduleGastos = Color(0xFFA855F7); // Púrpura
  static const Color moduleInventario = Color(0xFF30E86E); // Verde primario
  static const Color moduleReportes = Color(0xFF64748B); // Gris pizarra

  // Fondos suaves por módulo
  static const Color moduleIngresosBg = Color(0xFFEFF6FF);
  static const Color moduleComprasBg = Color(0xFFFFF7ED);
  static const Color moduleGastosBg = Color(0xFFFAF5FF);
  static const Color moduleInventarioBg = Color(0xFFF0FDF4); // green-50

  // Gradiente del módulo Ingresos (azul oscuro → esmeralda)
  static const Color moduleIngresosDark = Color(0xFF1E3A8A); // blue-900
  static const Color emeraldCustom = Color(0xFF10B981); // emerald-500

  // Gradiente del módulo Compras (naranja oscuro → naranja)
  static const Color moduleComprasDark = Color(0xFF7C2D12); // orange-900

  // Gradiente del módulo Gastos (púrpura oscuro → púrpura)
  static const Color moduleGastosDark = Color(0xFF3B0764); // purple-900

  // Gradiente del módulo Inventario (verde oscuro → verde primario)
  static const Color moduleInventarioDark = Color(0xFF14532D); // green-900

  // Gradiente del módulo Reportes (índigo oscuro → índigo)
  static const Color moduleReportesDark = Color(0xFF1E1B4B); // indigo-950
  static const Color moduleReportesIndigo = Color(0xFF6366F1); // indigo-500

  // Sombras de botones por módulo (30 % opacidad)
  static const Color moduleIngresosShadow = Color(0x4D3B82F6);
  static const Color moduleComprasShadow = Color(0x4DF97316);
  static const Color moduleGastosShadow = Color(0x4DA855F7);
  static const Color moduleInventarioShadow = Color(0x4D30E86E);
  static const Color moduleReportesShadow = Color(0x4D6366F1);

  // Fondo de la sección de listas
  static const Color listSectionBg = Color(0xFFF3F4F6); // gray-100

  // Alertas de vencimiento
  static const Color expiringBg = Color(0xFFFEF3C7);
  static const Color expiringText = Color(0xFFD97706);
  static const Color expiredBg = Color(0xFFFEE2E2);
  static const Color expiredText = Color(0xFFB91C1C);

  // Fondo de tarjetas de formulario
  static const Color cardBg = Color(0xFFF8FAFC);

  // Sombra suave para barras flotantes (negro al 9%)
  static const Color shadowOverlay = Color(0x18000000);
}
