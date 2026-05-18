import 'package:flutter/material.dart';

class Product {
  final String id;
  final String category;
  final String name;
  final String description;
  final double basePrice;
  final List<Variant> variants;
  final IconData icon;
  final EditorConfig editorConfig;

  const Product({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.variants,
    required this.icon,
    required this.editorConfig,
  });

  double priceForVariant(String variantId) {
    final v = variants.firstWhere((v) => v.id == variantId);
    return basePrice + v.priceDelta;
  }
}

class Variant {
  final String id;
  final String name;
  final double priceDelta;
  final Map<String, dynamic> attributes;

  const Variant({
    required this.id,
    required this.name,
    this.priceDelta = 0,
    this.attributes = const {},
  });
}

class EditorConfig {
  final double canvasWidthMm;
  final double canvasHeightMm;
  final double bleedMm;
  final int minDpi;
  final int? pageCount;

  const EditorConfig({
    required this.canvasWidthMm,
    required this.canvasHeightMm,
    this.bleedMm = 3,
    this.minDpi = 200,
    this.pageCount,
  });
}

class Category {
  final String id;
  final String name;
  final String tagline;
  final IconData icon;

  const Category({
    required this.id,
    required this.name,
    required this.tagline,
    required this.icon,
  });
}
