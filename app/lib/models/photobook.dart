import 'package:flutter/material.dart';

/// One photo "slot" on a page, in normalized 0..1 coordinates
/// relative to the page rectangle.
class PhotoSlot {
  final double x;
  final double y;
  final double width;
  final double height;
  const PhotoSlot(this.x, this.y, this.width, this.height);

  Rect toRect(Size pageSize) => Rect.fromLTWH(
        x * pageSize.width,
        y * pageSize.height,
        width * pageSize.width,
        height * pageSize.height,
      );
}

/// A reusable page layout template.
class PageTemplate {
  final String id;
  final String name;
  final List<PhotoSlot> slots;
  final bool landscapeFriendly;

  const PageTemplate({
    required this.id,
    required this.name,
    required this.slots,
    this.landscapeFriendly = true,
  });

  int get slotCount => slots.length;
}

/// A single page in a photobook: which template + which photos in each slot.
class PhotobookPage {
  final String templateId;
  final List<String?> photoUrls; // null = empty slot

  const PhotobookPage({required this.templateId, required this.photoUrls});

  PhotobookPage withPhoto(int slotIndex, String? url) {
    final copy = List<String?>.from(photoUrls);
    if (slotIndex >= 0 && slotIndex < copy.length) {
      copy[slotIndex] = url;
    }
    return PhotobookPage(templateId: templateId, photoUrls: copy);
  }

  PhotobookPage withTemplate(PageTemplate template) {
    // Keep up to template.slotCount photos
    final newPhotos = List<String?>.generate(
      template.slotCount,
      (i) => i < photoUrls.length ? photoUrls[i] : null,
    );
    return PhotobookPage(templateId: template.id, photoUrls: newPhotos);
  }

  Map<String, dynamic> toFirestore() => {
        'templateId': templateId,
        'photoUrls': photoUrls,
      };

  factory PhotobookPage.fromFirestore(Map<String, dynamic> data) =>
      PhotobookPage(
        templateId: data['templateId'] as String,
        photoUrls: (data['photoUrls'] as List).cast<String?>(),
      );
}
