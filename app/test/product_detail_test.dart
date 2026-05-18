import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silvestre_app/data/mock_catalog.dart';
import 'package:silvestre_app/screens/product_detail_screen.dart';
import 'package:silvestre_app/theme/app_theme.dart';

void main() {
  testWidgets('ProductDetailScreen renders all variants for "Stampa classica"',
      (WidgetTester tester) async {
    final product = MockCatalog.byId('print_classic');

    await tester.pumpWidget(
      MaterialApp(
        theme: SilvestreThemes.classic.build(),
        home: ProductDetailScreen(product: product),
      ),
    );
    await tester.pump();

    // Section heading
    expect(find.text('Scegli il formato'), findsOneWidget);

    // All 5 variant names should be in the tree
    expect(find.text('10x15 cm'), findsOneWidget);
    expect(find.text('13x18 cm'), findsOneWidget);
    expect(find.text('15x21 cm'), findsOneWidget);
    expect(find.text('20x30 cm'), findsOneWidget);
    expect(find.text('30x45 cm'), findsOneWidget);

    // Default selected variant price visible
    expect(find.text('€ 0.20'), findsWidgets);

    // Quantità section
    expect(find.text('Quantità'), findsOneWidget);

    // Bottom bar
    expect(find.text('Totale'), findsOneWidget);
    expect(find.text('Aggiungi'), findsOneWidget);
  });

  testWidgets('Selecting a variant updates the total',
      (WidgetTester tester) async {
    final product = MockCatalog.byId('print_classic');

    await tester.pumpWidget(
      MaterialApp(
        theme: SilvestreThemes.classic.build(),
        home: ProductDetailScreen(product: product),
      ),
    );
    await tester.pump();

    // Scroll into view first since variants may be below the fold
    final formatHeader = find.text('Scegli il formato');
    await tester.ensureVisible(formatHeader);
    await tester.pump();

    final variant30x45 = find.text('30x45 cm');
    await tester.ensureVisible(variant30x45);
    await tester.pump();
    await tester.tap(variant30x45);
    await tester.pump();

    // 30x45 = base 0.20 + delta 4.80 = 5.00 * 1 quantity
    expect(find.text('€ 5.00'), findsWidgets);
  });
}
