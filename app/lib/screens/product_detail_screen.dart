import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/photobook.dart';
import '../models/product.dart';
import '../state/cart_state.dart';
import '../theme/app_theme.dart';
import '../widgets/cart_badge_button.dart';
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
  bool get _isPrint => widget.product.category == 'stampa';

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
      appBar: AppBar(
        title: Text(product.name),
        actions: const [CartBadgeButton()],
      ),
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
              onChanged: (urls) => setState(() {
                _photoUrls = urls;
                if (_isPrint && urls.isNotEmpty) {
                  _quantity = urls.length.clamp(1, 9999);
                }
              }),
              subtitle: _isPrint
                  ? 'Carica le foto da stampare. La quantità si imposta '
                      'automaticamente al numero di foto (modificabile).'
                  : 'Carica le foto da stampare/utilizzare per questo prodotto.',
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1) Descrizione (sempre visibile sopra qty/prezzo/aggiungi)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: palette.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        product.description,
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // 2) Row: SINISTRA back+quantity, DESTRA prezzo sopra Aggiungi
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // LEFT: back arrow (al posto del vecchio prezzo) + quantity
                  IconButton(
                    tooltip: 'Indietro',
                    style: IconButton.styleFrom(
                      side: BorderSide(color: palette.border),
                      padding: const EdgeInsets.all(10),
                    ),
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quantità',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: palette.textSecondary,
                            )),
                        const SizedBox(height: 4),
                        _CompactQtyBar(
                          value: _quantity,
                          onChanged: (v) => setState(() => _quantity = v),
                          palette: palette,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // RIGHT: price stacked above Aggiungi
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '€ ${lineTotal.toStringAsFixed(2)}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                                : _photobookPages
                                    .map((p) => p.toFirestore())
                                    .toList(),
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${product.name} aggiunto al carrello'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.add_shopping_cart, size: 18),
                        label: const Text('Aggiungi'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactQtyBar extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final SilvestrePalette palette;

  const _CompactQtyBar({
    required this.value,
    required this.onChanged,
    required this.palette,
  });

  @override
  State<_CompactQtyBar> createState() => _CompactQtyBarState();
}

class _CompactQtyBarState extends State<_CompactQtyBar> {
  late final TextEditingController _ctl =
      TextEditingController(text: widget.value.toString());

  @override
  void didUpdateWidget(_CompactQtyBar old) {
    super.didUpdateWidget(old);
    if (widget.value.toString() != _ctl.text) {
      _ctl.text = widget.value.toString();
      _ctl.selection =
          TextSelection.collapsed(offset: _ctl.text.length);
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _commit(String s) {
    final n = int.tryParse(s.trim());
    if (n == null || n < 1) {
      _ctl.text = '1';
      widget.onChanged(1);
    } else if (n > 9999) {
      _ctl.text = '9999';
      widget.onChanged(9999);
    } else {
      widget.onChanged(n);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: widget.value > 1
                ? () => widget.onChanged(widget.value - 1)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.remove,
                  size: 16,
                  color: widget.value > 1
                      ? palette.textPrimary
                      : palette.textSecondary),
            ),
          ),
          SizedBox(
            width: 44,
            child: TextField(
              controller: _ctl,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
                fontSize: 14,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
              ),
              onSubmitted: _commit,
              onEditingComplete: () => _commit(_ctl.text),
              onTapOutside: (_) => _commit(_ctl.text),
            ),
          ),
          InkWell(
            onTap: widget.value < 9999
                ? () => widget.onChanged(widget.value + 1)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.add, size: 16, color: palette.textPrimary),
            ),
          ),
        ],
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

