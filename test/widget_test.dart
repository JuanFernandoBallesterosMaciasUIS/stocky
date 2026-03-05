import 'package:flutter_test/flutter_test.dart';
import 'package:stocky/main.dart';
import 'package:stocky/res/data/constants.dart';

void main() {
  testWidgets('Smoke test: la app arranca y muestra el tab de Inventario', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StockyApp());
    await tester.pump();

    // Verifica que se renderice el título de la pantalla de inventario
    expect(find.text(AppConstants.inventoryTitle), findsOneWidget);

    // Verifica que los tabs del inventario estén visibles
    expect(find.text(AppConstants.tabManualEntry), findsOneWidget);
    expect(find.text(AppConstants.tabHistory), findsOneWidget);
  });

  testWidgets('La barra de navegación inferior tiene los 5 ítems', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StockyApp());
    await tester.pump();

    expect(find.text(AppConstants.navIngresos), findsOneWidget);
    expect(find.text(AppConstants.navCompras), findsOneWidget);
    expect(find.text(AppConstants.navGastos), findsOneWidget);
    expect(find.text(AppConstants.navInventario), findsOneWidget);
    expect(find.text(AppConstants.navReportes), findsOneWidget);
  });

  testWidgets('La lista muestra productos con sus nombres', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StockyApp());
    await tester.pump();

    expect(find.text('Café Especial x 500g'), findsOneWidget);
    expect(find.text('Café Orgánico x 250g'), findsOneWidget);
    expect(find.text('Filtros de Papel V60'), findsOneWidget);
    expect(find.text('Prensa Francesa 1L'), findsOneWidget);
  });

  testWidgets('Los productos con stock bajo muestran badge "Bajo Stock"', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StockyApp());
    await tester.pump();

    // Dos productos tienen bajo stock (Café Orgánico x 250g y Prensa Francesa 1L)
    expect(find.text(AppConstants.labelLowStock), findsNWidgets(2));
  });
}
