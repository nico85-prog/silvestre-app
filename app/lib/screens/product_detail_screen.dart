import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/photobook.dart';
import '../models/product.dart';
import '../state/cart_state.dart';
import '../theme/app_theme.dart';
import '../widgets/catalog_image.dart';
import '../widgets/photo_picker_section.dart';
import 'photobook/photobook_editor_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late String _selectedVariantId = widget.product.variants.first.id;
  int _quantity = 1;
  List<String> _photoUrls = [];
  List<PhotobookPage> _photobookPages = [];

  bool get _isPhotobook => widget.product.category == 'photobook';

  Future<void> _openPhotobookEditor() async {
    final variant = widget.product.variants
        .firstWhere((v) => v.id == _selectedVariantId);
    final result = await Navigator.push<PhotobookResult>(
      context,
      MaterialPageRoute(
        builder: (_) => PhotobookEditorScreen(
          product: widget.product,
          variant: variant,
          initialPhotoUrls: _photoUrls,
          initialPages: _photobookPages.isEmpty ? null : _photobookPages,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _photoUrls = result.photos;
        _photobookPages = result.pages;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final textTheme = Theme.of(context).textTheme;
    final product = widget.product;
    final unitPrice = product.priceForVariant(_selectedVariantId);
    final lineTotal = unitPrice * _quantity;

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          SizedBox(
            height: 240,
            child: CatalogImage(
              imageKey: product.id,
              borderRadius: BorderRadius.circular(20),
              fallbackIcon: product.icon,
              showAttribution: true,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            product.name,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.description,
            style: TextStyle(color: palette.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 22),
          Text(
            'Scegli il formato',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: product.variants.map((v) {
              final isSelected = v.id == _selectedVariantId;
              final price = product.basePrice + v.priceDelta;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selectedVariantId = v.id),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? palette.primary.withValues(alpha: 0.08)
                          : palette.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? palette.primary : palette.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? palette.primary
                              : palette.textSecondary,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            v.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '€ ${price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: palette.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Text(
            'Quantità',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          _QuantitySelector(
            value: _quantity,
            onChanged: (v) => setState(() => _quantity = v),
            palette: palette,
          ),
          const SizedBox(height: 22),
          Text(
            _isPhotobook ? 'Componi il tuo fotolibro' : 'Le tue foto',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          if (_isPhotobook)
            _PhotobookSummaryCard(
              pagesCount: _photobookPages.length,
              photosCount: _photoUrls.length,
              onTap: _openPhotobookEditor,
              palette: palette,
            )
          else
            PhotoPickerSection(
              initialUrls: _photoUrls,
              onChanged: (urls) => setState(() => _photoUrls = urls),
              subtitle:
                  'Carica le foto da stampare/utilizzare per questo prodotto.',
            ),
          const SizedBox(height: 80),
        ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: palette.background,
            border: Border(top: BorderSide(color: palette.border)),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Totale',
                      style: TextStyle(
                          fontSize: 12, color: palette.textSecondary)),
                  Text(
                    '€ ${lineTotal.toStringAsFixed(2)}',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  final variant = product.variants
                      .firstWhere((v) => v.id == _selectedVariantId);
                  cartState.add(CartItem(
                    id: '${product.id}_${variant.id}_${DateTime.now().millisecondsSinceEpoch}',
                    productId: product.id,
                    variantId: variant.id,
                    productName: product.name,
                    variantName: variant.name,
                    quantity: _quantity,
                    unitPrice: unitPrice,
                    photoUrls: List.from(_photoUrls),
                    photobookPages: _photobookPages.isEmpty
                        ? null
                        : _photobookPages.map((p) => p.toFirestore()).toList(),
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} aggiunto al carrello'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Aggiungi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotobookSummaryCard extends StatelessWidget {
  final int pagesCount;
  final int photosCount;
  final VoidCallback onTap;
  final SilvestrePalette palette;

  const _PhotobookSummaryCard({
    required this.pagesCount,
    required this.photosCount,
    required this.onTap,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final hasDesign = pagesCount > 0;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.primary, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasDesign ? Icons.auto_stories : Icons.auto_awesome,
                color: palette.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasDesign
                        ? 'Fotolibro pronto'
                        : 'Apri editor fotolibro',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasDesign
                        ? '$pagesCount pagine · $photosCount foto · auto-impaginato'
                        : 'Auto-impagina con AI: carica foto e ti propongo il layout',
                    style: TextStyle(
                      fontSize: 13,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: palette.primary),
          ],
        ),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final SilvestrePalette palette;

  const _QuantitySelector({
    required this.value,
    required this.onChanged,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: value < 99 ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
