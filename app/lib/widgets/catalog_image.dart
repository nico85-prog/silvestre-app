import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/catalog_images_state.dart';
import '../theme/app_theme.dart';
import 'product_image.dart';

/// Mostra l'immagine del catalogo per [imageKey] (es. "stampa_classica"
/// o "cat_stampa"). Legge da catalog_images Firestore (cache locale).
/// Se non disponibile, fallback su ProductImage placeholder.
class CatalogImage extends StatelessWidget {
  final String imageKey;
  final IconData fallbackIcon;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final bool showAttribution;

  const CatalogImage({
    super.key,
    required this.imageKey,
    this.fallbackIcon = Icons.image_outlined,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.showAttribution = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final radius = borderRadius ?? BorderRadius.circular(12);

    return AnimatedBuilder(
      animation: catalogImagesState,
      builder: (context, _) {
        final info = catalogImagesState.byKey(imageKey);
        if (info == null || info.url.isEmpty) {
          return ProductImage(
            seed: imageKey,
            borderRadius: borderRadius,
            fallbackIcon: fallbackIcon,
          );
        }
        return Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: radius,
                child: Image.network(
                  info.url,
                  fit: fit,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: palette.surface,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: palette.primary,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stack) => ProductImage(
                    seed: imageKey,
                    borderRadius: borderRadius,
                    fallbackIcon: fallbackIcon,
                  ),
                ),
              ),
            ),
            if (showAttribution && info.photographer.isNotEmpty)
              Positioned(
                left: 6,
                bottom: 6,
                child: _AttributionChip(info: info),
              ),
          ],
        );
      },
    );
  }
}

class _AttributionChip extends StatelessWidget {
  final CatalogImageInfo info;
  const _AttributionChip({required this.info});

  Future<void> _open() async {
    final url = info.pexelsPageUrl.isNotEmpty
        ? info.pexelsPageUrl
        : info.photographerUrl;
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _open,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt, size: 11, color: Colors.white),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '${info.photographer} · Pexels',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
