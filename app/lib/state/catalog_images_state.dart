import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CatalogImageInfo {
  final String url;
  final String thumbUrl;
  final String photographer;
  final String photographerUrl;
  final String pexelsPageUrl;
  final String alt;

  const CatalogImageInfo({
    required this.url,
    required this.thumbUrl,
    required this.photographer,
    required this.photographerUrl,
    required this.pexelsPageUrl,
    required this.alt,
  });

  factory CatalogImageInfo.fromFirestore(Map<String, dynamic> d) =>
      CatalogImageInfo(
        url: d['url'] as String? ?? '',
        thumbUrl: d['thumbUrl'] as String? ?? d['url'] as String? ?? '',
        photographer: d['photographer'] as String? ?? '',
        photographerUrl: d['photographerUrl'] as String? ?? '',
        pexelsPageUrl: d['pexelsPageUrl'] as String? ?? '',
        alt: d['alt'] as String? ?? '',
      );
}

class CatalogImagesState extends ChangeNotifier {
  final Map<String, CatalogImageInfo> _byKey = {};
  bool _loaded = false;
  bool _loading = false;

  CatalogImageInfo? byKey(String key) => _byKey[key];
  bool get loaded => _loaded;

  Future<void> load() async {
    if (_loading || _loaded) return;
    _loading = true;
    try {
      final snap =
          await FirebaseFirestore.instance.collection('catalog_images').get();
      for (final doc in snap.docs) {
        _byKey[doc.id] = CatalogImageInfo.fromFirestore(doc.data());
      }
      _loaded = true;
      notifyListeners();
    } catch (_) {
      // fallisce silente — l'app cade su ProductImage placeholder
    } finally {
      _loading = false;
    }
  }
}

final catalogImagesState = CatalogImagesState();
