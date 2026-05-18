import '../models/photobook.dart';

/// Registry of available page layout templates.
class PageTemplates {
  static const List<PageTemplate> all = [
    // ---- 1 photo ----
    PageTemplate(
      id: '1_full',
      name: 'Pieno',
      slots: [PhotoSlot(0, 0, 1, 1)],
    ),
    PageTemplate(
      id: '1_centered',
      name: 'Centrato',
      slots: [PhotoSlot(0.08, 0.12, 0.84, 0.76)],
    ),

    // ---- 2 photos ----
    PageTemplate(
      id: '2_horizontal',
      name: '2 sopra/sotto',
      slots: [
        PhotoSlot(0, 0, 1, 0.495),
        PhotoSlot(0, 0.505, 1, 0.495),
      ],
    ),
    PageTemplate(
      id: '2_vertical',
      name: '2 fianco a fianco',
      slots: [
        PhotoSlot(0, 0, 0.495, 1),
        PhotoSlot(0.505, 0, 0.495, 1),
      ],
    ),

    // ---- 3 photos ----
    PageTemplate(
      id: '3_one_left_two_right',
      name: '1 grande + 2',
      slots: [
        PhotoSlot(0, 0, 0.595, 1),
        PhotoSlot(0.605, 0, 0.395, 0.495),
        PhotoSlot(0.605, 0.505, 0.395, 0.495),
      ],
    ),
    PageTemplate(
      id: '3_one_top_two_bottom',
      name: '1 sopra + 2 sotto',
      slots: [
        PhotoSlot(0, 0, 1, 0.595),
        PhotoSlot(0, 0.605, 0.495, 0.395),
        PhotoSlot(0.505, 0.605, 0.495, 0.395),
      ],
    ),

    // ---- 4 photos ----
    PageTemplate(
      id: '4_grid',
      name: 'Griglia 2x2',
      slots: [
        PhotoSlot(0, 0, 0.495, 0.495),
        PhotoSlot(0.505, 0, 0.495, 0.495),
        PhotoSlot(0, 0.505, 0.495, 0.495),
        PhotoSlot(0.505, 0.505, 0.495, 0.495),
      ],
    ),
    PageTemplate(
      id: '4_one_big_three_strip',
      name: '1 grande + 3 piccole',
      slots: [
        PhotoSlot(0, 0, 1, 0.66),
        PhotoSlot(0, 0.67, 0.328, 0.33),
        PhotoSlot(0.336, 0.67, 0.328, 0.33),
        PhotoSlot(0.672, 0.67, 0.328, 0.33),
      ],
    ),

    // ---- 6 photos ----
    PageTemplate(
      id: '6_grid_3x2',
      name: 'Griglia 3x2',
      slots: [
        PhotoSlot(0, 0, 0.328, 0.495),
        PhotoSlot(0.336, 0, 0.328, 0.495),
        PhotoSlot(0.672, 0, 0.328, 0.495),
        PhotoSlot(0, 0.505, 0.328, 0.495),
        PhotoSlot(0.336, 0.505, 0.328, 0.495),
        PhotoSlot(0.672, 0.505, 0.328, 0.495),
      ],
    ),
  ];

  static PageTemplate byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.first);

  static List<PageTemplate> forSlotCount(int n) =>
      all.where((t) => t.slotCount == n).toList();
}

/// Auto-layout algorithm: distribute [photoUrls] across [pageCount] pages,
/// picking a template per page based on how many photos land on it.
///
/// Strategy:
///   - photos per page = ceil(N/pages) but clamped to known template sizes
///   - alternate among templates of the same slot count for variety
class PhotobookLayoutEngine {
  static const _allowedCounts = [1, 2, 3, 4, 6];

  /// Pre-compute how many photos go on each page.
  /// Tries to balance evenly while keeping per-page counts within
  /// available template sizes.
  static List<int> _distribute(int total, int pages) {
    if (pages <= 0) return [];
    if (total <= 0) return List.filled(pages, 0);

    final perPageRaw = total / pages;
    int perPageRounded = perPageRaw.ceil();
    // snap to nearest allowed count >= perPageRounded
    perPageRounded = _allowedCounts
        .firstWhere((c) => c >= perPageRounded, orElse: () => 6);

    final result = List<int>.filled(pages, 0);
    int remaining = total;
    for (int i = 0; i < pages && remaining > 0; i++) {
      final take = remaining >= perPageRounded ? perPageRounded : remaining;
      // also snap take to nearest allowed count
      final snapped = _allowedCounts
          .lastWhere((c) => c <= take, orElse: () => 1);
      result[i] = snapped;
      remaining -= snapped;
    }
    // Any leftovers? push into last page if possible (overflow into next allowed)
    int idx = 0;
    while (remaining > 0 && idx < pages) {
      final spaceLeft = 6 - result[idx];
      if (spaceLeft > 0) {
        final extra = _allowedCounts
            .lastWhere((c) => c <= result[idx] + remaining,
                orElse: () => result[idx]);
        if (extra > result[idx]) {
          remaining -= (extra - result[idx]);
          result[idx] = extra;
        }
      }
      idx++;
    }
    return result;
  }

  /// Choose a template for a given slot count, alternating among options
  /// so subsequent pages don't look identical.
  static PageTemplate _pickTemplate(int slotCount, int pageIndex) {
    final candidates = PageTemplates.forSlotCount(slotCount);
    if (candidates.isEmpty) {
      // Fallback to closest available
      final closest = _allowedCounts
          .firstWhere((c) => c >= slotCount, orElse: () => 1);
      return PageTemplates.forSlotCount(closest).first;
    }
    return candidates[pageIndex % candidates.length];
  }

  /// Generates a list of [PhotobookPage] from given photos and page count.
  /// If photos are fewer than pages, fills remaining pages with empty layouts (1 slot).
  static List<PhotobookPage> autoFill({
    required List<String> photoUrls,
    required int pageCount,
  }) {
    final pages = <PhotobookPage>[];
    if (pageCount <= 0) return pages;

    final distribution = _distribute(photoUrls.length, pageCount);
    int cursor = 0;
    for (int i = 0; i < pageCount; i++) {
      final n = distribution[i];
      if (n == 0) {
        // empty page, single slot waiting for a photo
        final tpl = PageTemplates.byId('1_centered');
        pages.add(PhotobookPage(
          templateId: tpl.id,
          photoUrls: List<String?>.filled(tpl.slotCount, null),
        ));
        continue;
      }
      final tpl = _pickTemplate(n, i);
      final slotPhotos = <String?>[];
      for (int s = 0; s < tpl.slotCount; s++) {
        slotPhotos
            .add(cursor < photoUrls.length ? photoUrls[cursor++] : null);
      }
      pages.add(PhotobookPage(templateId: tpl.id, photoUrls: slotPhotos));
    }
    return pages;
  }
}
