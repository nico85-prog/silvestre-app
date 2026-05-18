// AUTO-GENERATED FILE — non modificare a mano.
// Genera da: Listini/catalogo.csv via docs/sync_listini.py
// Per modificare prezzi/prodotti, edita il CSV e fai deploy.

import 'package:flutter/material.dart';
import '../models/product.dart';

class MockCatalog {
  static const List<Category> categories = [
    Category(
      id: 'stampa',
      name: 'Stampe foto',
      tagline: 'I ricordi che si tengono in mano',
      icon: Icons.photo_library_outlined,
    ),
    Category(
      id: 'fotolibro',
      name: 'Fotolibri',
      tagline: 'Le tue storie in un libro su misura',
      icon: Icons.menu_book_outlined,
    ),
    Category(
      id: 'calendario',
      name: 'Calendari',
      tagline: '12 mesi con i momenti che ami',
      icon: Icons.calendar_month_outlined,
    ),
    Category(
      id: 'fotoquadro',
      name: 'Tele e quadri',
      tagline: 'Arredo che racconta chi sei',
      icon: Icons.image_outlined,
    ),
    Category(
      id: 'fotoregalo',
      name: 'Regali e gadget',
      tagline: 'Un pensiero unico per ogni persona',
      icon: Icons.card_giftcard_outlined,
    ),
    Category(
      id: 'crystal',
      name: 'Crystal 3D',
      tagline: 'Cristalli con incisione laser dei tuoi ricordi',
      icon: Icons.auto_awesome_outlined,
    ),
  ];

  static final List<Product> products = [
    Product(
      id: 'stampa_classica',
      category: 'stampa',
      name: 'Stampa classica',
      description: 'Carta fotografica professionale, finitura lucida o opaca. Pi\u00f9 stampi meno paghi (fascia per quantit\u00e0).',
      basePrice: 0.1,
      icon: Icons.photo_outlined,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: '9x13_1_29',
          name: '9x13 cm (1-29 pz)',
          priceDelta: 0.35,
        ),
        Variant(
          id: '9x13_30_49',
          name: '9x13 cm (30-49 pz)',
          priceDelta: 0.13,
        ),
        Variant(
          id: '9x13_50_149',
          name: '9x13 cm (50-149 pz)',
          priceDelta: 0.1,
        ),
        Variant(
          id: '9x13_150_299',
          name: '9x13 cm (150-299 pz)',
          priceDelta: 0.08,
        ),
        Variant(
          id: '9x13_300_479',
          name: '9x13 cm (300-479 pz)',
          priceDelta: 0.04,
        ),
        Variant(
          id: '9x13_480_599',
          name: '9x13 cm (480-599 pz)',
          priceDelta: 0.02,
        ),
        Variant(
          id: '9x13_600_plus',
          name: '9x13 cm (600+ pz)',
          priceDelta: 0.0,
        ),
        Variant(
          id: '10x15_1_29',
          name: '10x15 cm (1-29 pz)',
          priceDelta: 0.35,
        ),
        Variant(
          id: '10x15_30_49',
          name: '10x15 cm (30-49 pz)',
          priceDelta: 0.16,
        ),
        Variant(
          id: '10x15_50_149',
          name: '10x15 cm (50-149 pz)',
          priceDelta: 0.12,
        ),
        Variant(
          id: '10x15_150_299',
          name: '10x15 cm (150-299 pz)',
          priceDelta: 0.1,
        ),
        Variant(
          id: '10x15_300_479',
          name: '10x15 cm (300-479 pz)',
          priceDelta: 0.06,
        ),
        Variant(
          id: '10x15_480_599',
          name: '10x15 cm (480-599 pz)',
          priceDelta: 0.04,
        ),
        Variant(
          id: '10x15_600_plus',
          name: '10x15 cm (600+ pz)',
          priceDelta: 0.02,
        ),
        Variant(
          id: '13x18_1_29',
          name: '13x18 cm (1-29 pz)',
          priceDelta: 0.42,
        ),
        Variant(
          id: '13x18_30_49',
          name: '13x18 cm (30-49 pz)',
          priceDelta: 0.22,
        ),
        Variant(
          id: '13x18_50_149',
          name: '13x18 cm (50-149 pz)',
          priceDelta: 0.15,
        ),
        Variant(
          id: '13x18_150_299',
          name: '13x18 cm (150-299 pz)',
          priceDelta: 0.12,
        ),
        Variant(
          id: '13x18_300_479',
          name: '13x18 cm (300-479 pz)',
          priceDelta: 0.08,
        ),
        Variant(
          id: '13x18_480_599',
          name: '13x18 cm (480-599 pz)',
          priceDelta: 0.06,
        ),
        Variant(
          id: '13x18_600_plus',
          name: '13x18 cm (600+ pz)',
          priceDelta: 0.03,
        ),
        Variant(
          id: '15x20_1_29',
          name: '15x20 cm (1-29 pz)',
          priceDelta: 0.9,
        ),
        Variant(
          id: '15x20_30_49',
          name: '15x20 cm (30-49 pz)',
          priceDelta: 0.5,
        ),
        Variant(
          id: '15x20_50_149',
          name: '15x20 cm (50-149 pz)',
          priceDelta: 0.4,
        ),
        Variant(
          id: '15x20_150_299',
          name: '15x20 cm (150-299 pz)',
          priceDelta: 0.32,
        ),
        Variant(
          id: '15x20_300_479',
          name: '15x20 cm (300-479 pz)',
          priceDelta: 0.17,
        ),
        Variant(
          id: '15x20_480_599',
          name: '15x20 cm (480-599 pz)',
          priceDelta: 0.15,
        ),
        Variant(
          id: '15x20_600_plus',
          name: '15x20 cm (600+ pz)',
          priceDelta: 0.11,
        ),
      ],
    ),
    Product(
      id: 'stampa_media',
      category: 'stampa',
      name: 'Stampa formato medio',
      description: 'Stampe da 20x25 a 30x45 cm. Sconto progressivo con quantit\u00e0.',
      basePrice: 0.9,
      icon: Icons.photo_outlined,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: '20x25_1_5',
          name: '20x25 cm (1-5 pz)',
          priceDelta: 1.0,
        ),
        Variant(
          id: '20x25_6_10',
          name: '20x25 cm (6-10 pz)',
          priceDelta: 0.75,
        ),
        Variant(
          id: '20x25_11_20',
          name: '20x25 cm (11-20 pz)',
          priceDelta: 0.6,
        ),
        Variant(
          id: '20x25_21_49',
          name: '20x25 cm (21-49 pz)',
          priceDelta: 0.4,
        ),
        Variant(
          id: '20x25_50_plus',
          name: '20x25 cm (50+ pz)',
          priceDelta: 0.0,
        ),
        Variant(
          id: '20x30_1_5',
          name: '20x30 cm (1-5 pz)',
          priceDelta: 1.2,
        ),
        Variant(
          id: '20x30_6_10',
          name: '20x30 cm (6-10 pz)',
          priceDelta: 1.0,
        ),
        Variant(
          id: '20x30_11_20',
          name: '20x30 cm (11-20 pz)',
          priceDelta: 0.8,
        ),
        Variant(
          id: '20x30_21_49',
          name: '20x30 cm (21-49 pz)',
          priceDelta: 0.6,
        ),
        Variant(
          id: '20x30_50_plus',
          name: '20x30 cm (50+ pz)',
          priceDelta: 0.1,
        ),
        Variant(
          id: '24x30_1_5',
          name: '24x30 cm (1-5 pz)',
          priceDelta: 1.6,
        ),
        Variant(
          id: '24x30_6_10',
          name: '24x30 cm (6-10 pz)',
          priceDelta: 1.2,
        ),
        Variant(
          id: '24x30_11_20',
          name: '24x30 cm (11-20 pz)',
          priceDelta: 1.0,
        ),
        Variant(
          id: '24x30_21_49',
          name: '24x30 cm (21-49 pz)',
          priceDelta: 0.7,
        ),
        Variant(
          id: '24x30_50_plus',
          name: '24x30 cm (50+ pz)',
          priceDelta: 0.3,
        ),
        Variant(
          id: '30x40_1_5',
          name: '30x40 cm (1-5 pz)',
          priceDelta: 3.6,
        ),
        Variant(
          id: '30x40_6_10',
          name: '30x40 cm (6-10 pz)',
          priceDelta: 3.0,
        ),
        Variant(
          id: '30x40_11_20',
          name: '30x40 cm (11-20 pz)',
          priceDelta: 2.6,
        ),
        Variant(
          id: '30x40_21_49',
          name: '30x40 cm (21-49 pz)',
          priceDelta: 2.1,
        ),
        Variant(
          id: '30x40_50_plus',
          name: '30x40 cm (50+ pz)',
          priceDelta: 1.2,
        ),
        Variant(
          id: '30x45_1_5',
          name: '30x45 cm (1-5 pz)',
          priceDelta: 4.1,
        ),
        Variant(
          id: '30x45_6_10',
          name: '30x45 cm (6-10 pz)',
          priceDelta: 3.4,
        ),
        Variant(
          id: '30x45_11_20',
          name: '30x45 cm (11-20 pz)',
          priceDelta: 3.0,
        ),
        Variant(
          id: '30x45_21_49',
          name: '30x45 cm (21-49 pz)',
          priceDelta: 2.5,
        ),
        Variant(
          id: '30x45_50_plus',
          name: '30x45 cm (50+ pz)',
          priceDelta: 1.6,
        ),
      ],
    ),
    Product(
      id: 'stampa_panoramica',
      category: 'stampa',
      name: 'Foto panoramica',
      description: 'Formati allungati per panorami e foto di gruppo. Sconto progressivo.',
      basePrice: 0.6,
      icon: Icons.crop_landscape,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: '15x30_1_5',
          name: '15x30 cm (1-5 pz)',
          priceDelta: 1.4,
        ),
        Variant(
          id: '15x30_6_10',
          name: '15x30 cm (6-10 pz)',
          priceDelta: 0.6,
        ),
        Variant(
          id: '15x30_11_20',
          name: '15x30 cm (11-20 pz)',
          priceDelta: 0.4,
        ),
        Variant(
          id: '15x30_21_49',
          name: '15x30 cm (21-49 pz)',
          priceDelta: 0.2,
        ),
        Variant(
          id: '15x30_50_plus',
          name: '15x30 cm (50+ pz)',
          priceDelta: 0.0,
        ),
        Variant(
          id: '30x60_1_5',
          name: '30x60 cm (1-5 pz)',
          priceDelta: 7.4,
        ),
        Variant(
          id: '30x60_6_10',
          name: '30x60 cm (6-10 pz)',
          priceDelta: 5.4,
        ),
        Variant(
          id: '30x60_11_20',
          name: '30x60 cm (11-20 pz)',
          priceDelta: 4.2,
        ),
        Variant(
          id: '30x60_21_49',
          name: '30x60 cm (21-49 pz)',
          priceDelta: 3.4,
        ),
        Variant(
          id: '30x60_50_plus',
          name: '30x60 cm (50+ pz)',
          priceDelta: 2.9,
        ),
        Variant(
          id: '30x70_1_5',
          name: '30x70 cm (1-5 pz)',
          priceDelta: 8.4,
        ),
        Variant(
          id: '30x70_6_10',
          name: '30x70 cm (6-10 pz)',
          priceDelta: 6.4,
        ),
        Variant(
          id: '30x70_11_20',
          name: '30x70 cm (11-20 pz)',
          priceDelta: 5.0,
        ),
        Variant(
          id: '30x70_21_49',
          name: '30x70 cm (21-49 pz)',
          priceDelta: 4.4,
        ),
        Variant(
          id: '30x70_50_plus',
          name: '30x70 cm (50+ pz)',
          priceDelta: 3.4,
        ),
        Variant(
          id: '30x80_1_5',
          name: '30x80 cm (1-5 pz)',
          priceDelta: 9.4,
        ),
        Variant(
          id: '30x80_6_10',
          name: '30x80 cm (6-10 pz)',
          priceDelta: 7.4,
        ),
        Variant(
          id: '30x80_11_20',
          name: '30x80 cm (11-20 pz)',
          priceDelta: 5.8,
        ),
        Variant(
          id: '30x80_21_49',
          name: '30x80 cm (21-49 pz)',
          priceDelta: 5.1,
        ),
        Variant(
          id: '30x80_50_plus',
          name: '30x80 cm (50+ pz)',
          priceDelta: 4.4,
        ),
        Variant(
          id: '30x90_1_5',
          name: '30x90 cm (1-5 pz)',
          priceDelta: 11.4,
        ),
        Variant(
          id: '30x90_6_10',
          name: '30x90 cm (6-10 pz)',
          priceDelta: 8.4,
        ),
        Variant(
          id: '30x90_11_20',
          name: '30x90 cm (11-20 pz)',
          priceDelta: 6.6,
        ),
        Variant(
          id: '30x90_21_49',
          name: '30x90 cm (21-49 pz)',
          priceDelta: 5.85,
        ),
        Variant(
          id: '30x90_50_plus',
          name: '30x90 cm (50+ pz)',
          priceDelta: 4.6,
        ),
      ],
    ),
    Product(
      id: 'plotter_grande',
      category: 'stampa',
      name: 'Stampa plotter grande formato',
      description: 'Stampa su carta poster per camerette, locali, regali d\'effetto.',
      basePrice: 10.0,
      icon: Icons.crop_landscape,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: '35x35',
          name: '35x35 cm',
          priceDelta: 0.0,
        ),
        Variant(
          id: '40x40',
          name: '40x40 cm',
          priceDelta: 5.0,
        ),
        Variant(
          id: '50x70',
          name: '50x70 cm',
          priceDelta: 20.0,
        ),
        Variant(
          id: '70x100',
          name: '70x100 cm',
          priceDelta: 40.0,
        ),
      ],
    ),
    Product(
      id: 'fotolibro_15x20',
      category: 'fotolibro',
      name: 'Fotolibro 15x20',
      description: 'Include 12 pagine fino a 66 foto. Copertina rigida nera, avorio, rossa, rosa, azzurra o blu.',
      basePrice: 0.75,
      icon: Icons.book,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: 'base',
          name: '12 pagine (max 66 foto)',
          priceDelta: 19.15,
        ),
        Variant(
          id: 'extra',
          name: 'Pagina extra (+\u20ac0,75)',
          priceDelta: 0.0,
        ),
      ],
    ),
    Product(
      id: 'fotolibro_20x20',
      category: 'fotolibro',
      name: 'Fotolibro 20x20',
      description: 'Include 12 pagine fino a 88 foto. Copertina rigida nera, avorio, rossa o blu.',
      basePrice: 1.2,
      icon: Icons.auto_stories,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: 'base',
          name: '12 pagine (max 88 foto)',
          priceDelta: 20.8,
        ),
        Variant(
          id: 'extra',
          name: 'Pagina extra (+\u20ac1,20)',
          priceDelta: 0.0,
        ),
      ],
    ),
    Product(
      id: 'fotolibro_20x30',
      category: 'fotolibro',
      name: 'Fotolibro 20x30',
      description: 'Include 12 pagine fino a 88 foto. Copertina rigida nera, avorio, rossa o blu.',
      basePrice: 1.5,
      icon: Icons.auto_stories,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: 'base',
          name: '12 pagine (max 88 foto)',
          priceDelta: 23.4,
        ),
        Variant(
          id: 'extra',
          name: 'Pagina extra (+\u20ac1,50)',
          priceDelta: 0.0,
        ),
      ],
    ),
    Product(
      id: 'calendario_annuale',
      category: 'calendario',
      name: 'Calendario annuale (1 pagina)',
      description: 'Tutto l\'anno su una singola pagina personalizzata.',
      basePrice: 5.0,
      icon: Icons.event_note,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: '30x40_plast',
          name: '30x40 cm plastificato',
          priceDelta: 5.0,
        ),
        Variant(
          id: '30x40_nonplast',
          name: '30x40 cm non plastificato',
          priceDelta: 2.0,
        ),
        Variant(
          id: '20x30_plast',
          name: '20x30 cm plastificato',
          priceDelta: 1.9,
        ),
        Variant(
          id: '20x30_nonplast',
          name: '20x30 cm non plastificato',
          priceDelta: 0.0,
        ),
      ],
    ),
    Product(
      id: 'calendario_mensile',
      category: 'calendario',
      name: 'Calendario mensile (12 pagine)',
      description: '12 pagine + copertina, una foto diversa per ogni mese.',
      basePrice: 19.9,
      icon: Icons.calendar_view_month,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: '30x40',
          name: '30x40 cm da parete',
          priceDelta: 15.0,
        ),
        Variant(
          id: '20x30',
          name: '20x30 cm da parete',
          priceDelta: 5.0,
        ),
        Variant(
          id: '15x20',
          name: '15x20 cm da tavolo',
          priceDelta: 0.0,
        ),
      ],
    ),
    Product(
      id: 'calendario_bimestrale',
      category: 'calendario',
      name: 'Calendario bimestrale (6 pagine)',
      description: '6 pagine + copertina, una foto ogni 2 mesi.',
      basePrice: 19.0,
      icon: Icons.event_note,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: '30x40',
          name: '30x40 cm',
          priceDelta: 0.0,
        ),
      ],
    ),
    Product(
      id: 'fotoquadro_canvas',
      category: 'fotoquadro',
      name: 'Fotoquadro su tela',
      description: 'Stampa su tela premium (lucida o satinata) con telaio in legno (sottile o doppio). Pronto da appendere.',
      basePrice: 19.9,
      icon: Icons.image,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: '20x20',
          name: '20x20 cm',
          priceDelta: 0.0,
        ),
        Variant(
          id: '20x30',
          name: '20x30 cm',
          priceDelta: 5.0,
        ),
        Variant(
          id: '30x40',
          name: '30x40 cm',
          priceDelta: 29.1,
        ),
        Variant(
          id: '40x60',
          name: '40x60 cm',
          priceDelta: 47.7,
        ),
        Variant(
          id: '50x70',
          name: '50x70 cm',
          priceDelta: 58.1,
        ),
        Variant(
          id: '60x80',
          name: '60x80 cm',
          priceDelta: 73.7,
        ),
        Variant(
          id: '70x100',
          name: '70x100 cm',
          priceDelta: 89.3,
        ),
        Variant(
          id: '80x100',
          name: '80x100 cm',
          priceDelta: 95.8,
        ),
        Variant(
          id: '100x150',
          name: '100x150 cm',
          priceDelta: 188.1,
        ),
      ],
    ),
    Product(
      id: 'plotter_tela',
      category: 'fotoquadro',
      name: 'Stampa plotter su tela',
      description: 'Tela stampata e rifinita ai bordi.',
      basePrice: 11.0,
      icon: Icons.crop_landscape,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: '20x30',
          name: '20x30 cm',
          priceDelta: 0.0,
        ),
        Variant(
          id: '30x40',
          name: '30x40 cm',
          priceDelta: 11.0,
        ),
        Variant(
          id: '40x60',
          name: '40x60 cm',
          priceDelta: 31.0,
        ),
        Variant(
          id: '50x70',
          name: '50x70 cm',
          priceDelta: 51.0,
        ),
        Variant(
          id: '70x100',
          name: '70x100 cm',
          priceDelta: 109.0,
        ),
      ],
    ),
    Product(
      id: 'magnete_grande',
      category: 'fotoregalo',
      name: 'Magnete grande',
      description: 'Magnete personalizzato con la tua foto. Quadrato, rotondo, cuore o rettangolare.',
      basePrice: 9.0,
      icon: Icons.bookmark,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: 'singolo',
          name: 'Magnete 10x15',
          priceDelta: 0.0,
        ),
      ],
    ),
    Product(
      id: 'magnete_piccolo',
      category: 'fotoregalo',
      name: 'Magnete piccolo',
      description: 'Magnete personalizzato in formato compatto.',
      basePrice: 6.0,
      icon: Icons.bookmark_outline,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: 'singolo',
          name: 'Magnete piccolo',
          priceDelta: 0.0,
        ),
      ],
    ),
    Product(
      id: 'tazza',
      category: 'fotoregalo',
      name: 'Tazza personalizzata',
      description: 'Tazza ceramica con stampa sublimatica della tua foto.',
      basePrice: 8.0,
      icon: Icons.coffee,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: 'standard',
          name: 'Tazza standard',
          priceDelta: 7.0,
        ),
        Variant(
          id: 'interno',
          name: 'Tazza interno colorato',
          priceDelta: 7.0,
        ),
        Variant(
          id: 'manico_cuore',
          name: 'Tazza manico a cuore',
          priceDelta: 7.0,
        ),
        Variant(
          id: 'tazzina',
          name: 'Tazzina caff\u00e8 singola',
          priceDelta: 0.0,
        ),
        Variant(
          id: 'tazzine_2',
          name: 'Due tazzine caff\u00e8',
          priceDelta: 7.0,
        ),
      ],
    ),
    Product(
      id: 'tshirt',
      category: 'fotoregalo',
      name: 'T-shirt personalizzata',
      description: 'T-shirt cotone 100% con stampa fotografica ad alta definizione.',
      basePrice: 12.0,
      icon: Icons.checkroom,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: 'fronte',
          name: 'Stampa solo fronte',
          priceDelta: 0.0,
        ),
        Variant(
          id: 'fronte_retro',
          name: 'Stampa fronte e retro',
          priceDelta: 6.0,
        ),
      ],
    ),
    Product(
      id: 'tshirt_tua',
      category: 'fotoregalo',
      name: 'Stampa su tua T-shirt',
      description: 'Porti tu la maglietta noi la stampiamo.',
      basePrice: 7.0,
      icon: Icons.checkroom,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: 'fronte',
          name: 'Stampa solo fronte',
          priceDelta: 0.0,
        ),
        Variant(
          id: 'fronte_retro',
          name: 'Stampa fronte e retro',
          priceDelta: 6.0,
        ),
      ],
    ),
    Product(
      id: 'cuscino',
      category: 'fotoregalo',
      name: 'Cuscino personalizzato',
      description: 'Cuscino con foto stampata su tessuto morbido.',
      basePrice: 18.0,
      icon: Icons.weekend_outlined,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: 'quadrato',
          name: 'Cuscino quadrato (max 4 foto/lato)',
          priceDelta: 0.0,
        ),
        Variant(
          id: 'design',
          name: 'Cuscino Design (pi\u00f9 4 foto/lato)',
          priceDelta: 1.9,
        ),
        Variant(
          id: 'cuore',
          name: 'Cuscino cuore',
          priceDelta: 1.9,
        ),
      ],
    ),
    Product(
      id: 'puzzle',
      category: 'fotoregalo',
      name: 'Puzzle personalizzato',
      description: 'Puzzle con la tua foto. Vari formati.',
      basePrice: 5.0,
      icon: Icons.extension,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: 'a4',
          name: 'A4 (21x29,7)',
          priceDelta: 10.0,
        ),
        Variant(
          id: 'a3',
          name: 'A3 (29,7x42)',
          priceDelta: 10.0,
        ),
        Variant(
          id: 'cuore',
          name: 'Cuore (29x35)',
          priceDelta: 13.0,
        ),
        Variant(
          id: 'piccolo',
          name: 'Puzzle cuore piccolo',
          priceDelta: 10.0,
        ),
        Variant(
          id: 'supporto',
          name: 'Supporto per appoggio',
          priceDelta: 0.0,
        ),
      ],
    ),
    Product(
      id: 'cucina',
      category: 'fotoregalo',
      name: 'Prodotti cucina',
      description: 'Accessori cucina con la tua foto.',
      basePrice: 8.0,
      icon: Icons.restaurant,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: 'tovaglietta_sughero',
          name: 'Tovaglietta sughero',
          priceDelta: 4.0,
        ),
        Variant(
          id: 'tovaglietta_stoffa',
          name: 'Tovaglietta stoffa',
          priceDelta: 10.0,
        ),
        Variant(
          id: 'vassoio_legno',
          name: 'Vassoio in legno',
          priceDelta: 50.0,
        ),
        Variant(
          id: 'sottobicchieri',
          name: 'Sottobicchieri',
          priceDelta: 0.0,
        ),
        Variant(
          id: 'grembiule',
          name: 'Grembiule',
          priceDelta: 10.0,
        ),
        Variant(
          id: 'presina',
          name: 'Presina',
          priceDelta: 3.0,
        ),
        Variant(
          id: 'bavetta',
          name: 'Bavetta',
          priceDelta: 3.0,
        ),
      ],
    ),
    Product(
      id: 'casa',
      category: 'fotoregalo',
      name: 'Casa e ufficio',
      description: 'Oggetti per casa e scrivania personalizzabili.',
      basePrice: 11.0,
      icon: Icons.home,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: 'orologio_muro',
          name: 'Orologio da muro',
          priceDelta: 31.0,
        ),
        Variant(
          id: 'portapenne',
          name: 'Portapenne ceramica',
          priceDelta: 1.0,
        ),
        Variant(
          id: 'salvadanaio',
          name: 'Salvadanaio',
          priceDelta: 4.0,
        ),
        Variant(
          id: 'tappetino_mouse',
          name: 'Tappetino mouse',
          priceDelta: 0.0,
        ),
      ],
    ),
    Product(
      id: 'tessili',
      category: 'fotoregalo',
      name: 'Tessili casa',
      description: 'Plaid, teli mare, trapunte e copripiumini con le tue foto.',
      basePrice: 18.0,
      icon: Icons.weekend_outlined,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: 'plaid_70x100',
          name: 'Plaid 70x100',
          priceDelta: 1.9,
        ),
        Variant(
          id: 'plaid_100x150',
          name: 'Plaid 100x150',
          priceDelta: 11.9,
        ),
        Variant(
          id: 'plaid_130x180',
          name: 'Plaid 130x180',
          priceDelta: 31.9,
        ),
        Variant(
          id: 'telo_70x100',
          name: 'Telo mare 70x100',
          priceDelta: 1.9,
        ),
        Variant(
          id: 'telo_90x180',
          name: 'Telo mare 90x180',
          priceDelta: 21.9,
        ),
        Variant(
          id: 'trapunta_100x150',
          name: 'Trapunta 100x150',
          priceDelta: 21.9,
        ),
        Variant(
          id: 'trapunta_180x200',
          name: 'Trapunta 180x200',
          priceDelta: 64.9,
        ),
        Variant(
          id: 'copripiumino_100x150',
          name: 'Copripiumino 100x150',
          priceDelta: 41.0,
        ),
        Variant(
          id: 'copripiumino_240x240',
          name: 'Copripiumino 240x240',
          priceDelta: 130.0,
        ),
        Variant(
          id: 'federa',
          name: 'Federa guanciale',
          priceDelta: 0.0,
        ),
        Variant(
          id: 'coppia_federe',
          name: 'Coppia federe',
          priceDelta: 17.0,
        ),
      ],
    ),
    Product(
      id: 'borse',
      category: 'fotoregalo',
      name: 'Borse e astucci',
      description: 'Borse personalizzate e accessori da scuola.',
      basePrice: 11.0,
      icon: Icons.shopping_bag_outlined,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: 'borsa',
          name: 'Borsa',
          priceDelta: 7.0,
        ),
        Variant(
          id: 'sacca_sport',
          name: 'Sacca sport',
          priceDelta: 0.0,
        ),
        Variant(
          id: 'zaino_bimbo',
          name: 'Zaino bimbo',
          priceDelta: 13.9,
        ),
        Variant(
          id: 'astuccio',
          name: 'Astuccio portapastelli',
          priceDelta: 4.0,
        ),
      ],
    ),
    Product(
      id: 'pannello_muro',
      category: 'fotoregalo',
      name: 'Pannelli da muro',
      description: 'Pannelli stampati in legno o alluminio, gi\u00e0 pronti per essere appesi.',
      basePrice: 17.9,
      icon: Icons.image,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: '20x30_legno',
          name: '20x30 legno',
          priceDelta: 12.0,
        ),
        Variant(
          id: '30x20_legno',
          name: '30x20 legno',
          priceDelta: 22.0,
        ),
        Variant(
          id: '15x15_allu',
          name: '15x15 alluminio',
          priceDelta: 0.0,
        ),
        Variant(
          id: '20x30_allu',
          name: '20x30 alluminio',
          priceDelta: 6.0,
        ),
        Variant(
          id: '30x40_allu',
          name: '30x40 alluminio',
          priceDelta: 22.0,
        ),
        Variant(
          id: 'decor_allu',
          name: 'Pannello decor alluminio',
          priceDelta: 22.0,
        ),
      ],
    ),
    Product(
      id: 'pannello_appoggio',
      category: 'fotoregalo',
      name: 'Pannelli da appoggio',
      description: 'Pannelli da scrivania con base.',
      basePrice: 21.9,
      icon: Icons.image_outlined,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: '20x30_legno',
          name: '20x30 legno',
          priceDelta: 13.0,
        ),
        Variant(
          id: '20x25_legno',
          name: '20x25 legno',
          priceDelta: 8.0,
        ),
        Variant(
          id: '13x18_legno',
          name: '13x18 legno',
          priceDelta: 0.0,
        ),
      ],
    ),
    Product(
      id: 'varie',
      category: 'fotoregalo',
      name: 'Altri prodotti',
      description: 'Una selezione di gadget personalizzabili.',
      basePrice: 11.0,
      icon: Icons.widgets,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: 'portachiavi',
          name: 'Portachiavi (varie forme)',
          priceDelta: 4.0,
        ),
        Variant(
          id: 'borraccia_plastica',
          name: 'Borraccia plastica 500ml',
          priceDelta: 4.0,
        ),
        Variant(
          id: 'borraccia_acciaio',
          name: 'Borraccia acciaio 500ml',
          priceDelta: 14.0,
        ),
        Variant(
          id: 'scatola_cuore',
          name: 'Scatola cuore',
          priceDelta: 7.0,
        ),
        Variant(
          id: 'cover_smartphone',
          name: 'Cover smartphone',
          priceDelta: 10.5,
        ),
        Variant(
          id: 'mini_tshirt',
          name: 'Mini t-shirt',
          priceDelta: 0.0,
        ),
        Variant(
          id: 'parasole',
          name: 'Parasole auto',
          priceDelta: 4.0,
        ),
        Variant(
          id: 'calza_natalizia',
          name: 'Calza natalizia',
          priceDelta: 7.0,
        ),
        Variant(
          id: 'decorazione',
          name: 'Decorazione alluminio',
          priceDelta: 0.0,
        ),
        Variant(
          id: 'felpa',
          name: 'Felpa con cappuccio',
          priceDelta: 24.9,
        ),
        Variant(
          id: 'ciondolo',
          name: 'Ciondolo (varie forme)',
          priceDelta: 4.0,
        ),
        Variant(
          id: 'ciondolo_targhetta',
          name: 'Ciondolo targhetta alluminio',
          priceDelta: 7.0,
        ),
      ],
    ),
    Product(
      id: 'crystal_parallel',
      category: 'crystal',
      name: 'Parallelepipedo',
      description: 'Cristallo a parallelepipedo con incisione laser 3D dei soggetti.',
      basePrice: 59.99,
      icon: Icons.auto_awesome,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: '40x60x40',
          name: '40x60x40 mm (1 soggetto)',
          priceDelta: 0.0,
        ),
        Variant(
          id: '50x80x50',
          name: '50x80x50 mm (max 2 sogg.)',
          priceDelta: 10.0,
        ),
        Variant(
          id: '60x90x60',
          name: '60x90x60 mm (max 3 sogg.)',
          priceDelta: 40.0,
        ),
        Variant(
          id: '70x100x70',
          name: '70x100x70 mm (max 4 sogg.)',
          priceDelta: 80.0,
        ),
        Variant(
          id: '80x130x80',
          name: '80x130x80 mm (max 5 sogg.)',
          priceDelta: 110.0,
        ),
      ],
    ),
    Product(
      id: 'crystal_cuore',
      category: 'crystal',
      name: 'Cuore',
      description: 'Cristallo a forma di cuore con incisione laser 3D.',
      basePrice: 61.0,
      icon: Icons.favorite,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: '70x65x40',
          name: '70x65x40 mm (max 1 sogg.)',
          priceDelta: 0.0,
        ),
        Variant(
          id: '80x65x35',
          name: '80x65x35 mm (max 2 sogg.)',
          priceDelta: 0.0,
        ),
        Variant(
          id: '100x90x60',
          name: '100x90x60 mm (max 3 sogg.)',
          priceDelta: 30.0,
        ),
      ],
    ),
    Product(
      id: 'crystal_cubo',
      category: 'crystal',
      name: 'Cubo',
      description: 'Cristallo a cubo con incisione laser 3D.',
      basePrice: 49.99,
      icon: Icons.auto_awesome,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: '50x50x50',
          name: '50x50x50 mm (max 1 sogg.)',
          priceDelta: 0.0,
        ),
        Variant(
          id: '60x60x60',
          name: '60x60x60 mm (max 2 sogg.)',
          priceDelta: 24.01,
        ),
        Variant(
          id: '80x80x80',
          name: '80x80x80 mm (max 3 sogg.)',
          priceDelta: 41.01,
        ),
        Variant(
          id: '100x100x100',
          name: '100x100x100 mm (max 3 sogg.)',
          priceDelta: 99.01,
        ),
      ],
    ),
    Product(
      id: 'crystal_basi',
      category: 'crystal',
      name: 'Basi LED',
      description: 'Basi luminose con LED per esporre il tuo cristallo.',
      basePrice: 8.0,
      icon: Icons.wb_sunny,
      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),
      variants: [
        Variant(
          id: 'base_2',
          name: 'Base 2 LED 70x60x20',
          priceDelta: 7.9,
        ),
        Variant(
          id: 'base_6',
          name: 'Base 6 LED 100x60x20',
          priceDelta: 9.0,
        ),
        Variant(
          id: 'base_8',
          name: 'Base 8 LED 144x110x25',
          priceDelta: 11.0,
        ),
        Variant(
          id: 'base_12',
          name: 'Base 12 LED 144x110x25',
          priceDelta: 71.0,
        ),
        Variant(
          id: 'alimentatore',
          name: 'Alimentatore',
          priceDelta: 0.0,
        ),
      ],
    ),
  ];

  static List<Product> byCategory(String categoryId) =>
      products.where((p) => p.category == categoryId).toList();

  static Product byId(String id) =>
      products.firstWhere((p) => p.id == id);

  static Category categoryById(String id) =>
      categories.firstWhere((c) => c.id == id);

  static const Map<String, String> categoryImageTags = {};
  static const Map<String, String> productImageTags = {};
  static String tagFor(String categoryId, [String? productId]) => '';
}
