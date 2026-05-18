import 'package:flutter_test/flutter_test.dart';
import 'package:silvestre_app/services/photobook_layout.dart';

void main() {
  group('PhotobookLayoutEngine.autoFill', () {
    test('returns empty list when pageCount=0', () {
      final pages = PhotobookLayoutEngine.autoFill(
        photoUrls: ['a', 'b'],
        pageCount: 0,
      );
      expect(pages, isEmpty);
    });

    test('fills pages with placeholder slots when no photos provided', () {
      final pages = PhotobookLayoutEngine.autoFill(
        photoUrls: [],
        pageCount: 5,
      );
      expect(pages.length, 5);
      for (final p in pages) {
        // Empty pages get a single empty slot
        expect(p.photoUrls.length, 1);
        expect(p.photoUrls.first, isNull);
      }
    });

    test('20 photos in 20 pages = 1 photo per page', () {
      final photos = List.generate(20, (i) => 'photo_$i');
      final pages = PhotobookLayoutEngine.autoFill(
        photoUrls: photos,
        pageCount: 20,
      );
      expect(pages.length, 20);
      // First photo on first page, last on last
      expect(pages.first.photoUrls.first, 'photo_0');
      // Each page should have its single photo
      final allUrls = pages.expand((p) => p.photoUrls).whereType<String>().toList();
      expect(allUrls.length, 20);
      expect(allUrls.toSet(), photos.toSet());
    });

    test('40 photos in 20 pages = 2 per page', () {
      final photos = List.generate(40, (i) => 'p$i');
      final pages = PhotobookLayoutEngine.autoFill(
        photoUrls: photos,
        pageCount: 20,
      );
      expect(pages.length, 20);
      // Most pages should have 2 slots
      final counts = pages.map((p) => p.photoUrls.length).toList();
      expect(counts.where((c) => c == 2).length, greaterThanOrEqualTo(15));
      // All photos used
      final used = pages.expand((p) => p.photoUrls).whereType<String>().toList();
      expect(used.length, 40);
    });

    test('5 photos in 20 pages = some pages empty', () {
      final photos = List.generate(5, (i) => 'p$i');
      final pages = PhotobookLayoutEngine.autoFill(
        photoUrls: photos,
        pageCount: 20,
      );
      expect(pages.length, 20);
      final used = pages.expand((p) => p.photoUrls).whereType<String>().toList();
      expect(used.length, 5);
      // Some pages have null slots
      final emptyPages = pages.where((p) => p.photoUrls.every((u) => u == null)).length;
      expect(emptyPages, greaterThan(0));
    });

    test('120 photos in 20 pages = 6 per page max', () {
      final photos = List.generate(120, (i) => 'p$i');
      final pages = PhotobookLayoutEngine.autoFill(
        photoUrls: photos,
        pageCount: 20,
      );
      expect(pages.length, 20);
      // Each page should accept 6 (max template size)
      for (final p in pages) {
        expect(p.photoUrls.length, lessThanOrEqualTo(6));
      }
    });

    test('chosen templates have matching slot count', () {
      final photos = List.generate(30, (i) => 'p$i');
      final pages = PhotobookLayoutEngine.autoFill(
        photoUrls: photos,
        pageCount: 10,
      );
      for (final p in pages) {
        final tpl = PageTemplates.byId(p.templateId);
        expect(tpl.slotCount, p.photoUrls.length,
            reason: 'Template slots must equal page photo array length');
      }
    });

    test('alternates templates of same slot count for variety', () {
      // 12 photos in 6 pages = 2 per page
      // Should use both 2_horizontal and 2_vertical templates
      final photos = List.generate(12, (i) => 'p$i');
      final pages = PhotobookLayoutEngine.autoFill(
        photoUrls: photos,
        pageCount: 6,
      );
      final templateIds = pages.map((p) => p.templateId).toSet();
      // Should have at least 2 different templates (alternation)
      expect(templateIds.length, greaterThanOrEqualTo(2));
    });
  });

  group('PageTemplates registry', () {
    test('has templates for all common slot counts', () {
      for (final n in [1, 2, 3, 4, 6]) {
        expect(PageTemplates.forSlotCount(n), isNotEmpty,
            reason: 'No template for slot count $n');
      }
    });

    test('all templates have slots in 0..1 bounds', () {
      for (final t in PageTemplates.all) {
        for (final s in t.slots) {
          expect(s.x, inInclusiveRange(0, 1));
          expect(s.y, inInclusiveRange(0, 1));
          expect(s.x + s.width, lessThanOrEqualTo(1.01),
              reason: '${t.id}: slot extends past right');
          expect(s.y + s.height, lessThanOrEqualTo(1.01),
              reason: '${t.id}: slot extends past bottom');
        }
      }
    });

    test('byId returns fallback when not found', () {
      final t = PageTemplates.byId('non_existent_template_xyz');
      expect(t, isNotNull);
    });
  });
}
