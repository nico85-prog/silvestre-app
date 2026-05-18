import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silvestre_app/data/mock_catalog.dart';
import 'package:silvestre_app/screens/product_detail_screen.dart';
import 'package:silvestre_app/theme/app_theme.dart';

void main() {
  testWidgets('ProductDetailScreen renders all variants for "Stampa classica"',
      (WidgetTester tester) async {
    final product = MockCatalog.byId('stampa_classica');

    await tester.pumpWidget(
      MaterialApp(
        theme: SilvestreThemes.classic.build(),
        home: ProductDetailScreen(product: product),
      ),
    );
    await tester.pump();

    expect(find.text('Scegli il formato'), findsOneWidget);

    // Every variant name from the catalog should be in the tree
    for (final v in product.variants) {
      expect(find.text(v.name), findsOneWidget,
          reason: 'variant ${v.name} should render');
    }

    expect(find.text('Quantità'), findsOneWidget);
    expect(find.text('Aggiungi'), findsOneWidget);
  });

  testWidgets('Selecting last variant updates the total to its price',
      (WidgetTester tester) async {
    final product = MockCatalog.byId('stampa_classica');
    final lastVariant = product.variants.last;
    final expectedPrice = product.basePrice + lastVariant.priceDelta;

    await tester.pumpWidget(
      MaterialApp(
        theme: SilvestreThemes.classic.build(),
        home: ProductDetailScreen(product: product),
      ),
    );
    await tester.pump();

    final variantFinder = find.text(lastVariant.name);
    await tester.ensureVisible(variantFinder);
    await tester.pump();
    await tester.tap(variantFinder);
    await tester.pump();

    expect(find.text('€ ${expectedPrice.toStringAsFixed(2)}'), findsWidgets);
  });
}
