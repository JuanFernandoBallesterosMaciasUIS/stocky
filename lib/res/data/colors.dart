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
}
