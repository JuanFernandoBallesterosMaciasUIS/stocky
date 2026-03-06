/// Dimensiones y breakpoints centralizados de la aplicación.
/// PROHIBIDO usar literales numéricos para layouts directamente en los Widgets.
/// Usar siempre Dimens.nombreDeLaDimension.
abstract final class Dimens {
  // Breakpoints responsivos
  static const double bpMobileMax = 600.0;
  static const double bpTablet = 768.0;
  static const double bpDesktop = 1024.0;

  // Máximo ancho del contenido principal (como en el HTML: max-w-md ≈ 448px)
  static const double maxContentWidth = 448.0;

  // Espaciado general
  static const double paddingXs = 4.0;
  static const double paddingSm = 8.0;
  static const double paddingMd = 12.0;
  static const double paddingLg = 16.0;
  static const double paddingXl = 24.0;

  // Alturas fijas
  static const double productItemMinHeight = 72.0;
  static const double bottomNavHeight = 72.0;
  static const double headerHeight = 52.0;
  static const double tabBarHeight = 48.0;

  // Íconos y avatares
  static const double productIconSize = 48.0;
  static const double productIconInnerSize = 24.0;
  static const double navIconSize = 24.0;
  static const double fabSize = 56.0;

  // Border radius
  static const double radiusMd = 8.0;
  static const double radiusFull = 9999.0;

  // Bordes
  static const double borderWidth = 1.0;
  static const double borderWidthFocus = 2.0;
  static const double tabIndicatorWidth = 3.0;

  // Border radius extra grande (rounded-xl ≈ 12 px)
  static const double radiusXl = 12.0;

  // Tipografía
  static const double fontSizeTitle = 28.0;
  static const double fontSizeXs = 11.0;

  // Botón principal
  static const double primaryBtnHeight = 52.0;
  static const double btnElevation = 6.0;

  // Toolbar con gradiente
  static const double appBarHeightGradient = 72.0;

  // Barra de navegación inferior moderna
  static const double radiusNavTop = 20.0;
  static const double navPillHeight = 3.0;
  static const double navPillWidth = 24.0;
}
