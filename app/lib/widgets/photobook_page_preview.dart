import 'package:flutter/material.dart';
import '../models/photobook.dart';
import '../services/photobook_layout.dart';
import '../theme/app_theme.dart';

/// Renders a single photobook page using its template + photo URLs.
/// Layout-only: no editing, no gestures. Reusable in editor and order detail.
class PhotobookPagePreview extends StatelessWidget {
  final PhotobookPage page;
  final void Function(int slotIndex)? onTapSlot;
  final bool showBookShadow;

  const PhotobookPagePreview({
    super.key,
    required this.page,
    this.onTapSlot,
    this.showBookShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final template = PageTemplates.byId(page.templateId);

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: showBookShadow
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              for (int i = 0; i < template.slots.length; i++)
                _slotWidget(
                  template.slots[i].toRect(size),
                  i < page.photoUrls.length ? page.photoUrls[i] : null,
                  i,
                  palette,
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _slotWidget(
      Rect rect, String? url, int index, SilvestrePalette palette) {
    final inner = url == null
        ? Container(
            color: palette.surface,
            alignment: Alignment.center,
            child: Icon(Icons.add_photo_alternate_outlined,
                color: palette.textSecondary, size: 18),
          )
        : Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: Colors.grey.shade300),
          );

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: GestureDetector(
        onTap: onTapSlot == null ? null : () => onTapSlot!(index),
        child: ClipRect(child: inner),
      ),
    );
  }
}

/// Grid of small photobook page thumbnails. Tap one to view full-screen.
class PhotobookThumbnailGrid extends StatelessWidget {
  final List<PhotobookPage> pages;

  const PhotobookThumbnailGrid({super.key, required this.pages});

  void _openFullPreview(BuildContext context, int initialIndex) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _PhotobookFullPreview(
        pages: pages,
        initialIndex: initialIndex,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    if (pages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border),
        ),
        child: Text('Fotolibro vuoto.',
            style: TextStyle(color: palette.textSecondary)),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: pages.length,
      itemBuilder: (context, i) {
        return InkWell(
          onTap: () => _openFullPreview(context, i),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: palette.border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(5)),
                    child: PhotobookPagePreview(page: pages[i]),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  color: palette.surface,
                  child: Text(
                    'Pag ${i + 1}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PhotobookFullPreview extends StatefulWidget {
  final List<PhotobookPage> pages;
  final int initialIndex;
  const _PhotobookFullPreview({
    required this.pages,
    this.initialIndex = 0,
  });

  @override
  State<_PhotobookFullPreview> createState() => _PhotobookFullPreviewState();
}

class _PhotobookFullPreviewState extends State<_PhotobookFullPreview> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _current = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Pagina ${_current + 1} / ${widget.pages.length}'),
      ),
      body: Center(
        child: PageView.builder(
          controller: _controller,
          itemCount: widget.pages.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.all(20),
            child:
                PhotobookPagePreview(page: widget.pages[i], showBookShadow: true),
          ),
        ),
      ),
    );
  }
}
