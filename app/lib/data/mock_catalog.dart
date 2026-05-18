import 'package:flutter/material.dart';
import '../models/product.dart';

class MockCatalog {
  static const List<Category> categories = [
    Category(
      id: 'print',
      name: 'Stampe foto',
      tagline: 'I ricordi che si tengono in mano',
      icon: Icons.photo_library_outlined,
    ),
    Category(
      id: 'photobook',
      name: 'Fotolibri',
      tagline: 'Le tue storie in un libro su misura',
      icon: Icons.menu_book_outlined,
    ),
    Category(
      id: 'calendar',
      name: 'Calendari',
      tagline: '12 mesi con i momenti che ami',
      icon: Icons.calendar_month_outlined,
    ),
    Category(
      id: 'canvas',
      name: 'Tele e quadri',
      tagline: 'Arredo che racconta chi sei',
      icon: Icons.image_outlined,
    ),
    Category(
      id: 'magnet',
      name: 'Magneti',
      tagline: 'Sorrisi sempre a portata di vista',
      icon: Icons.bookmark_outline,
    ),
    Category(
      id: 'gift',
      name: 'Regali',
      tagline: 'Un pensiero unico per ogni persona',
      icon: Icons.card_giftcard_outlined,
    ),
  ];

  static final List<Product> products = [
    Product(
      id: 'print_classic',
      category: 'print',
      name: 'Stampa classica',
      description:
          'Carta fotografica professionale, finitura lucida o opaca. Colori brillanti, neri profondi. Pronta in 24h.',
      basePrice: 0.20,
      icon: Icons.photo_outlined,
      editorConfig: const EditorConfig(canvasWidthMm: 100, canvasHeightMm: 150),
      variants: const [
        Variant(id: '10x15', name: '10x15 cm', priceDelta: 0),
        Variant(id: '13x18', name: '13x18 cm', priceDelta: 0.15),
        Variant(id: '15x21', name: '15x21 cm', priceDelta: 0.30),
        Variant(id: '20x30', name: '20x30 cm', priceDelta: 1.50),
        Variant(id: '30x45', name: '30x45 cm', priceDelta: 4.80),
      ],
    ),
    Product(
      id: 'print_poster',
      category: 'print',
      name: 'Poster grande formato',
      description:
          'Carta poster spessa 200 g, fino a 70x100 cm. Perfetto per camerette, studi e regali d\'effetto.',
      basePrice: 9.90,
      icon: Icons.crop_landscape,
      editorConfig: const EditorConfig(canvasWidthMm: 500, canvasHeightMm: 700),
      variants: const [
        Variant(id: '50x70', name: '50x70 cm', priceDelta: 0),
        Variant(id: '70x100', name: '70x100 cm', priceDelta: 8),
      ],
    ),
    Product(
      id: 'photobook_square_20',
      category: 'photobook',
      name: 'Fotolibro Quadrato',
      description:
          'Copertina rigida personalizzata, carta fotografica 200 g/mq. Il regalo perfetto per matrimoni, battesimi, anniversari.',
      basePrice: 24.90,
      icon: Icons.book,
      editorConfig: const EditorConfig(
          canvasWidthMm: 200, canvasHeightMm: 200, pageCount: 20),
      variants: const [
        Variant(id: '20x20_20p', name: '20x20 cm — 20 pagine', priceDelta: 0),
        Variant(id: '20x20_40p', name: '20x20 cm — 40 pagine', priceDelta: 12),
        Variant(id: '30x30_20p', name: '30x30 cm — 20 pagine', priceDelta: 15),
        Variant(id: '30x30_40p', name: '30x30 cm — 40 pagine', priceDelta: 28),
      ],
    ),
    Product(
      id: 'photobook_landscape',
      category: 'photobook',
      name: 'Fotolibro Orizzontale',
      description:
          'Formato panoramico A4 con rilegatura professionale. Pensato per viaggi e paesaggi che meritano spazio.',
      basePrice: 29.90,
      icon: Icons.auto_stories,
      editorConfig: const EditorConfig(
          canvasWidthMm: 280, canvasHeightMm: 210, pageCount: 24),
      variants: const [
        Variant(id: 'A4_24p', name: 'A4 — 24 pagine', priceDelta: 0),
        Variant(id: 'A4_48p', name: 'A4 — 48 pagine', priceDelta: 18),
      ],
    ),
    Product(
      id: 'calendar_wall',
      category: 'calendar',
      name: 'Calendario da parete',
      description:
          '12 fogli mensili + copertina, rilegatura a spirale superiore. Una foto diversa per ogni mese che apri.',
      basePrice: 14.90,
      icon: Icons.calendar_view_month,
      editorConfig: const EditorConfig(
          canvasWidthMm: 297, canvasHeightMm: 210, pageCount: 13),
      variants: const [
        Variant(id: 'A4_landscape', name: 'A4 orizzontale', priceDelta: 0),
        Variant(id: 'A3_landscape', name: 'A3 orizzontale', priceDelta: 6),
      ],
    ),
    Product(
      id: 'calendar_desk',
      category: 'calendar',
      name: 'Calendario da tavolo',
      description:
          'Formato compatto da scrivania con cavalletto. Perfetto per ufficio e regali aziendali.',
      basePrice: 9.90,
      icon: Icons.event_note,
      editorConfig: const EditorConfig(
          canvasWidthMm: 200, canvasHeightMm: 150, pageCount: 13),
      variants: const [
        Variant(id: 'standard', name: '20x15 cm', priceDelta: 0),
      ],
    ),
    Product(
      id: 'canvas_classic',
      category: 'canvas',
      name: 'Tela su telaio',
      description:
          'Stampa su tela canvas 360 g/m² montata su telaio in legno di abete. Pronta da appendere, durata oltre 50 anni.',
      basePrice: 19.90,
      icon: Icons.image,
      editorConfig: const EditorConfig(canvasWidthMm: 400, canvasHeightMm: 300),
      variants: const [
        Variant(id: '40x30', name: '40x30 cm', priceDelta: 0),
        Variant(id: '60x40', name: '60x40 cm', priceDelta: 12),
        Variant(id: '80x60', name: '80x60 cm', priceDelta: 25),
        Variant(id: '100x70', name: '100x70 cm', priceDelta: 45),
      ],
    ),
    Product(
      id: 'magnet_set',
      category: 'magnet',
      name: 'Set magneti foto',
      description:
          'Set di magneti rigidi 6x9 cm personalizzati con le tue foto. Le facce dei tuoi cari, ogni volta che apri il frigo.',
      basePrice: 8.90,
      icon: Icons.bookmark,
      editorConfig: const EditorConfig(canvasWidthMm: 60, canvasHeightMm: 90),
      variants: const [
        Variant(id: '9pcs', name: '9 magneti 6x9 cm', priceDelta: 0),
        Variant(id: '12pcs', name: '12 magneti 6x9 cm', priceDelta: 3),
      ],
    ),
    Product(
      id: 'mug',
      category: 'gift',
      name: 'Tazza personalizzata',
      description:
          'Tazza ceramica bianca 330 ml con la tua foto stampata a colori sublimatici. Lavabile in lavastoviglie.',
      basePrice: 9.90,
      icon: Icons.coffee,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 80),
      variants: const [
        Variant(id: 'standard', name: 'Standard 330 ml', priceDelta: 0),
        Variant(id: 'magic', name: 'Magica termoreattiva', priceDelta: 4),
      ],
    ),
    Product(
      id: 'cushion',
      category: 'gift',
      name: 'Cuscino personalizzato',
      description:
          'Cuscino quadrato in microfibra morbida, imbottito, con foto stampata a tutto colore. Idea regalo originale.',
      basePrice: 19.90,
      icon: Icons.weekend_outlined,
      editorConfig: const EditorConfig(canvasWidthMm: 400, canvasHeightMm: 400),
      variants: const [
        Variant(id: 'standard', name: '40x40 cm', priceDelta: 0),
        Variant(id: 'large', name: '50x50 cm', priceDelta: 5),
      ],
    ),
    Product(
      id: 'tshirt',
      category: 'gift',
      name: 'T-shirt personalizzata',
      description:
          'T-shirt unisex cotone 100% pettinato, stampa fronte ad alta definizione. Resiste a oltre 50 lavaggi.',
      basePrice: 16.90,
      icon: Icons.checkroom,
      editorConfig: const EditorConfig(canvasWidthMm: 250, canvasHeightMm: 300),
      variants: const [
        Variant(id: 'S', name: 'Taglia S', priceDelta: 0),
        Variant(id: 'M', name: 'Taglia M', priceDelta: 0),
        Variant(id: 'L', name: 'Taglia L', priceDelta: 0),
        Variant(id: 'XL', name: 'Taglia XL', priceDelta: 1),
      ],
    ),
  ];

  static List<Product> byCategory(String categoryId) =>
      products.where((p) => p.category == categoryId).toList();

  static Product byId(String id) => products.firstWhere((p) => p.id == id);

  static Category categoryById(String id) =>
      categories.firstWhere((c) => c.id == id);

  static const Map<String, String> categoryImageTags = {
    'print': 'photoprint,family,photography',
    'photobook': 'photoalbum,photobook,memories',
    'calendar': 'calendar,wallcalendar,desk',
    'canvas': 'canvasprint,wallart,interior',
    'magnet': 'fridgemagnet,fridge,kitchen',
    'gift': 'gift,mug,coffee',
  };

  static const Map<String, String> productImageTags = {
    'print_classic': 'photoprint,polaroid',
    'print_poster': 'poster,wallart,large',
    'photobook_square_20': 'photoalbum,square',
    'photobook_landscape': 'photoalbum,travel,landscape',
    'calendar_wall': 'wallcalendar,calendar',
    'calendar_desk': 'deskcalendar,office',
    'canvas_classic': 'canvasprint,wallart',
    'magnet_set': 'fridgemagnet,magnets',
    'mug': 'mug,coffeemug,personalized',
    'cushion': 'cushion,pillow,sofa',
    'tshirt': 'tshirt,apparel,printed',
  };

  static String tagFor(String categoryId, [String? productId]) {
    if (productId != null && productImageTags.containsKey(productId)) {
      return productImageTags[productId]!;
    }
    return categoryImageTags[categoryId] ?? 'photography';
  }
}
