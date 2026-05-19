import 'package:flutter/material.dart';
import '../data/mock_catalog.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../widgets/cart_badge_button.dart';
import '../widgets/catalog_image.dart';
import 'product_detail_screen.dart';

class CategoryProductsScreen extends StatelessWidget {
  final Category category;
  const CategoryProductsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final products = MockCatalog.byCategory(category.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        actions: const [CartBadgeButton()],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final p = products[i];
          final cheapest = p.variants
              .map((v) => p.basePrice + v.priceDelta)
              .reduce((a, b) => a < b ? a : b);
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
            ),
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CatalogImage(
                      imageKey: p.id,
                      fallbackIcon: p.icon,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'da € ${cheapest.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: palette.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: palette.textSecondary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
