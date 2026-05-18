import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProductImage extends StatelessWidget {
  final String seed;
  final String? categoryId;
  final String? tag;
  final int width;
  final int height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;

  const ProductImage({
    super.key,
    required this.seed,
    this.categoryId,
    this.tag,
    this.width = 1200,
    this.height = 800,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.image_outlined,
  });

  static const Map<String, List<String>> _byCategory = {
    'print': [
      'sea,beach,sunset',
      'mountain,landscape,nature',
      'children,kids,playing',
      'travel,adventure,explore',
      'flowers,garden,spring',
      'event,party,wedding',
      'aperitif,cocktail,sunset',
      'friends,group,smile',
    ],
    'photobook': [
      'wedding,bride,romance',
      'family,memories,smile',
      'travel,vacation,trip',
      'children,birthday,joy',
      'newborn,baby,tender',
      'friends,group,laughter',
      'honeymoon,couple,sunset',
    ],
    'calendar': [
      'mountain,landscape,scenic',
      'sea,beach,ocean',
      'flowers,nature,spring',
      'sunset,sunrise,sky',
      'forest,wilderness,trees',
      'autumn,leaves,foliage',
      'winter,snow,mountain',
    ],
    'canvas': [
      'mountain,panorama,dramatic',
      'sea,seascape,horizon',
      'sunset,golden,sky',
      'forest,misty,atmospheric',
      'desert,dunes,minimal',
      'sky,clouds,abstract',
      'city,skyline,night',
      'flowers,macro,bokeh',
    ],
    'magnet': [
      'breakfast,coffee,morning',
      'family,kitchen,cooking',
      'children,smile,candid',
      'pet,dog,cute',
      'pet,cat,cozy',
      'picnic,outdoor,friends',
      'birthday,cake,party',
      'travel,memories,polaroid',
    ],
    'gift': [
      'family,hug,bonding',
      'christmas,present,cozy',
      'birthday,celebration,smile',
      'couple,love,romance',
      'friends,laughter,fun',
      'mother,daughter,tender',
      'grandparents,grandchildren',
      'sunset,beach,candid',
    ],
  };

  static const List<String> _fallbackPool = [
    'sea,beach,sunset',
    'mountain,landscape,nature',
    'children,kids,family',
    'event,party,wedding',
    'aperitif,cocktail,bar',
    'lounge,interior,cozy',
    'friends,youth,smile',
  ];

  String get _resolvedTag {
    if (tag != null) return tag!;
    final pool = _byCategory[categoryId] ?? _fallbackPool;
    return pool[seed.hashCode.abs() % pool.length];
  }

  int get _lock => seed.hashCode.abs() % 100000;

  String get _url =>
      'https://loremflickr.com/$width/$height/$_resolvedTag/?lock=$_lock';

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final radius = borderRadius ?? BorderRadius.circular(12);

    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        _url,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: palette.surface,
            alignment: Alignment.center,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: palette.primary,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stack) => Container(
          color: palette.primary.withValues(alpha: 0.12),
          alignment: Alignment.center,
          child: Icon(fallbackIcon, color: palette.primary, size: 32),
        ),
      ),
    );
  }
}
