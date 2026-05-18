"""
sync_listini.py — legge Listini/catalogo.csv e rigenera app/lib/data/mock_catalog.dart

Workflow:
1. Apri Listini/catalogo.csv in Excel
2. Modifica/aggiungi/togli righe (una riga = una variante prodotto)
3. Salva il CSV (mantenere separatore ;)
4. Lancia deploy.bat → questo script gira automaticamente

Schema CSV (separatore ;):
  category_id;category_name;category_tagline;category_icon;
  product_id;product_name;product_description;product_icon;
  variant_id;variant_name;price
"""
import csv
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV_PATH = os.path.join(ROOT, "Listini", "catalogo.csv")
OUT_PATH = os.path.join(ROOT, "app", "lib", "data", "mock_catalog.dart")


def to_id(s):
    """Normalize string into safe Dart identifier (alphanum + underscore)."""
    s = re.sub(r"[^a-zA-Z0-9_]", "_", s).strip("_").lower()
    return s or "x"


def parse_price(s):
    """Accepts '19,90' or '19.90' or '€ 19,90' → 19.90"""
    s = re.sub(r"[€\s]", "", s.strip())
    s = s.replace(",", ".")
    try:
        return float(s)
    except ValueError:
        raise ValueError(f"Prezzo non valido: '{s}'")


def dart_str(s):
    """Escape a string for Dart single-quoted literal.
    Non-ASCII characters are escaped to \\uXXXX so the .dart source is
    pure ASCII — robust against tooling that mis-reads encoding."""
    s = s.replace("\\", "\\\\").replace("'", r"\'").replace("\n", r"\n")
    out = []
    for ch in s:
        cp = ord(ch)
        if cp < 0x80:
            out.append(ch)
        elif cp <= 0xFFFF:
            out.append(f"\\u{cp:04x}")
        else:
            # Astral plane: encode as surrogate pair
            cp -= 0x10000
            high = 0xD800 + (cp >> 10)
            low = 0xDC00 + (cp & 0x3FF)
            out.append(f"\\u{high:04x}\\u{low:04x}")
    return "".join(out)


def main():
    if not os.path.exists(CSV_PATH):
        print(f"ERRORE: {CSV_PATH} non trovato.")
        sys.exit(1)

    # utf-8-sig: gestisce automaticamente UTF-8 con o senza BOM.
    # Il BOM è essenziale per far aprire correttamente il CSV in Excel italiano.
    with open(CSV_PATH, encoding="utf-8-sig") as f:
        reader = csv.DictReader(f, delimiter=";")
        rows = [r for r in reader if r.get("category_id", "").strip()]

    # Aggregate by category → product → variants
    categories = {}  # cat_id → dict
    for row in rows:
        cid = row["category_id"].strip()
        pid = row["product_id"].strip()
        if cid not in categories:
            categories[cid] = {
                "id": cid,
                "name": row["category_name"].strip(),
                "tagline": row["category_tagline"].strip(),
                "icon": row.get("category_icon", "category").strip() or "category",
                "products": {},
            }
        prods = categories[cid]["products"]
        if pid not in prods:
            prods[pid] = {
                "id": pid,
                "name": row["product_name"].strip(),
                "description": row["product_description"].strip(),
                "icon": row.get("product_icon", "shopping_bag").strip() or "shopping_bag",
                "variants": [],
                "base_price": None,
            }
        price = parse_price(row["price"])
        prods[pid]["variants"].append({
            "id": to_id(row["variant_id"].strip()),
            "name": row["variant_name"].strip(),
            "price": price,
        })

    # Compute base_price = lowest, deltas as (price - base)
    for cat in categories.values():
        for prod in cat["products"].values():
            prices = [v["price"] for v in prod["variants"]]
            base = min(prices)
            prod["base_price"] = base
            for v in prod["variants"]:
                v["delta"] = round(v["price"] - base, 2)

    # Generate Dart
    out = []
    out.append("// AUTO-GENERATED FILE — non modificare a mano.")
    out.append("// Genera da: Listini/catalogo.csv via docs/sync_listini.py")
    out.append("// Per modificare prezzi/prodotti, edita il CSV e fai deploy.")
    out.append("")
    out.append("import 'package:flutter/material.dart';")
    out.append("import '../models/product.dart';")
    out.append("")
    out.append("class MockCatalog {")
    out.append("  static const List<Category> categories = [")
    for cat in categories.values():
        out.append("    Category(")
        out.append(f"      id: '{dart_str(cat['id'])}',")
        out.append(f"      name: '{dart_str(cat['name'])}',")
        out.append(f"      tagline: '{dart_str(cat['tagline'])}',")
        out.append(f"      icon: Icons.{cat['icon']},")
        out.append("    ),")
    out.append("  ];")
    out.append("")
    out.append("  static final List<Product> products = [")
    for cat in categories.values():
        for prod in cat["products"].values():
            out.append("    Product(")
            out.append(f"      id: '{dart_str(prod['id'])}',")
            out.append(f"      category: '{dart_str(cat['id'])}',")
            out.append(f"      name: '{dart_str(prod['name'])}',")
            out.append(f"      description: '{dart_str(prod['description'])}',")
            out.append(f"      basePrice: {prod['base_price']},")
            out.append(f"      icon: Icons.{prod['icon']},")
            out.append("      editorConfig: const EditorConfig(canvasWidthMm: 200, canvasHeightMm: 200),")
            out.append("      variants: [")
            for v in prod["variants"]:
                out.append("        Variant(")
                out.append(f"          id: '{dart_str(v['id'])}',")
                out.append(f"          name: '{dart_str(v['name'])}',")
                out.append(f"          priceDelta: {v['delta']},")
                out.append("        ),")
            out.append("      ],")
            out.append("    ),")
    out.append("  ];")
    out.append("")
    out.append("  static List<Product> byCategory(String categoryId) =>")
    out.append("      products.where((p) => p.category == categoryId).toList();")
    out.append("")
    out.append("  static Product byId(String id) =>")
    out.append("      products.firstWhere((p) => p.id == id);")
    out.append("")
    out.append("  static Category categoryById(String id) =>")
    out.append("      categories.firstWhere((c) => c.id == id);")
    out.append("")
    out.append("  static const Map<String, String> categoryImageTags = {};")
    out.append("  static const Map<String, String> productImageTags = {};")
    out.append("  static String tagFor(String categoryId, [String? productId]) => '';")
    out.append("}")

    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    with open(OUT_PATH, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out) + "\n")

    total_variants = sum(len(p["variants"]) for c in categories.values() for p in c["products"].values())
    print(f"OK: {OUT_PATH}")
    print(f"  Categorie:   {len(categories)}")
    print(f"  Prodotti:    {sum(len(c['products']) for c in categories.values())}")
    print(f"  Varianti:    {total_variants}")


if __name__ == "__main__":
    main()
