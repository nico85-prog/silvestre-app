import 'package:flutter_test/flutter_test.dart';
import 'package:silvestre_app/data/mock_catalog.dart';

void main() {
  test('Catalog has categories and products', () {
    expect(MockCatalog.categories, isNotEmpty);
    expect(MockCatalog.products, isNotEmpty);
  });

  test('Every product belongs to an existing category', () {
    final catIds = MockCatalog.categories.map((c) => c.id).toSet();
    for (final p in MockCatalog.products) {
      expect(catIds.contains(p.category), isTrue,
          reason: 'Product ${p.id} references unknown category ${p.category}');
    }
  });

  test('Every product has at least one variant', () {
    for (final p in MockCatalog.products) {
      expect(p.variants, isNotEmpty,
          reason: 'Product ${p.id} has no variants');
    }
  });
}
