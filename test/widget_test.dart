import 'package:flutter_test/flutter_test.dart';
import 'package:stocky/main.dart';
import 'package:stocky/res/data/constants.dart';

void main() {
  testWidgets(
    'Smoke test: la app arranca y muestra el tab de Inventario por defecto',
    (WidgetTester tester) async {
      await tester.pumpWidget(const StockyApp());
      await tester.pump();

      // La pantalla de inventario está activa (índice 3)
      expect(find.text(AppConstants.inventoryTitle), findsWidgets);

      // Los tres tabs del inventario son visibles en el AppBar
      expect(find.text(AppConstants.tabManualEntry), findsWidgets);
      expect(find.text(AppConstants.tabStock), findsWidgets);
      expect(find.text(AppConstants.tabExpiring), findsWidgets);
    },
  );

  testWidgets('La barra de navegación inferior contiene los 5 ítems definidos', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StockyApp());
    await tester.pump();

    // Cada etiqueta aparece al menos una vez (en el nav o en el título del módulo)
    expect(find.text(AppConstants.navIngresos), findsWidgets);
    expect(find.text(AppConstants.navCompras), findsWidgets);
    expect(find.text(AppConstants.navGastos), findsWidgets);
    expect(find.text(AppConstants.navInventario), findsWidgets);
    expect(find.text(AppConstants.navReportes), findsWidgets);
  });

  testWidgets(
    'Los datos iniciales del examen se cargan en el store (5 productos)',
    (WidgetTester tester) async {
      await tester.pumpWidget(const StockyApp());
      await tester.pump();

      // El primer producto del inventario debe estar visible en la lista
      expect(find.text('Café Volcán en granos 250gr'), findsWidgets);
    },
  );

  testWidgets(
    'Con stock=50 y umbral=10 todos los productos deben estar en estado Adecuado',
    (WidgetTester tester) async {
      await tester.pumpWidget(const StockyApp());
      await tester.pump();

      // Ningún producto debería mostrar "Bajo Stock" con stock=50
      expect(find.text(AppConstants.labelLowStock), findsNothing);
    },
  );
}
