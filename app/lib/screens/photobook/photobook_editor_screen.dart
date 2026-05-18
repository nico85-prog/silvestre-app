import 'package:flutter/material.dart';
import '../../models/photobook.dart';
import '../../models/product.dart';
import '../../services/photobook_layout.dart';
import '../../state/auth_state.dart';
import '../../services/cloudinary_service.dart';
import '../../theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';

class PhotobookEditorScreen extends StatefulWidget {
  final Product product;
  final Variant variant;
  final List<String> initialPhotoUrls;
  final List<PhotobookPage>? initialPages;

  const PhotobookEditorScreen({
    super.key,
    required this.product,
    required this.variant,
    this.initialPhotoUrls = const [],
    this.initialPages,
  });

  @override
  State<PhotobookEditorScreen> createState() => _PhotobookEditorScreenState();
}

class _PhotobookEditorScreenState extends State<PhotobookEditorScreen> {
  late final List<String> _photos = List.from(widget.initialPhotoUrls);
  late List<PhotobookPage> _pages = widget.initialPages ?? const [];
  int _currentPage = 0;
  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();
  final Set<String> _uploading = {};

  int get _pageCount =>
      widget.product.editorConfig.pageCount ?? widget.variant.attributes['pageCount'] as int? ?? 20;

  @override
  void initState() {
    super.initState();
    if (_pages.isEmpty) {
      _autoFill();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _autoFill() {
    setState(() {
      _pages = PhotobookLayoutEngine.autoFill(
        photoUrls: _photos,
        pageCount: _pageCount,
      );
    });
  }

  Future<void> _addPhotos() async {
    final user = authState.currentUser;
    if (user == null) return;
    final picked = await _picker.pickMultiImage(imageQuality: 90, maxWidth: 4000);
    for (final x in picked) {
      final tempKey = 'tmp_${DateTime.now().microsecondsSinceEpoch}_${x.name}';
      setState(() => _uploading.add(tempKey));
      try {
        final bytes = await x.readAsBytes();
        final r = await CloudinaryService.uploadBytes(
          bytes: bytes,
          fileName: x.name,
          userId: user.id,
          folderSuffix: 'photobook_${widget.product.id}',
        );
        if (!mounted) return;
        setState(() {
          _uploading.remove(tempKey);
          _photos.add(r.url);
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _uploading.remove(tempKey));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload fallito: $e')),
        );
      }
    }
  }

  Future<void> _swapSlot(int slotIndex) async {
    final url = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoChooserSheet(
        photos: _photos,
        currentUrl: _pages[_currentPage].photoUrls[slotIndex],
      ),
    );
    if (url == null) return;
    setState(() {
      _pages[_currentPage] =
          _pages[_currentPage].withPhoto(slotIndex, url.isEmpty ? null : url);
    });
  }

  Future<void> _changeTemplate() async {
    final tpl = await showModalBottomSheet<PageTemplate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _TemplateChooserSheet(),
    );
    if (tpl == null) return;
    setState(() {
      _pages[_currentPage] = _pages[_currentPage].withTemplate(tpl);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Fotolibro · ${_currentPage + 1}/$_pageCount'),
        actions: [
          IconButton(
            tooltip: 'Auto-impagina con le foto attuali',
            icon: const Icon(Icons.auto_awesome),
            onPressed: _photos.isEmpty ? null : _autoFill,
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              PhotobookResult(photos: _photos, pages: _pages),
            ),
            child: const Text('Salva',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Photo strip
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: palette.surface,
              border: Border(bottom: BorderSide(color: palette.border)),
            ),
            child: Row(
              children: [
                _AddPhotoTile(onTap: _addPhotos, palette: palette),
                const SizedBox(width: 8),
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length + _uploading.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      if (i < _photos.length) {
                        return _StripThumb(url: _photos[i]);
                      }
                      return Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: palette.border),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: palette.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _pages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Carica almeno una foto e poi premi ✨ in alto per auto-impaginare.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: palette.textSecondary),
                      ),
                    ),
                  )
                : PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, i) => _PagePreview(
                      page: _pages[i],
                      onTapSlot: i == _currentPage ? _swapSlot : null,
                    ),
                  ),
          ),
          // Bottom controls
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: palette.surface,
              border: Border(top: BorderSide(color: palette.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Pagina precedente',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage == 0
                      ? null
                      : () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Pagina ${_currentPage + 1} di ${_pages.length}',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary),
                      ),
                      Text(
                        _pages.isEmpty
                            ? ''
                            : '${_pages[_currentPage].photoUrls.length} foto',
                        style: TextStyle(
                            fontSize: 11, color: palette.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Pagina successiva',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage >= _pages.length - 1
                      ? null
                      : () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                ),
                IconButton(
                  tooltip: 'Cambia layout pagina',
                  icon: const Icon(Icons.dashboard_customize_outlined),
                  onPressed: _pages.isEmpty ? null : _changeTemplate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final VoidCallback onTap;
  final SilvestrePalette palette;
  const _AddPhotoTile({required this.onTap, required this.palette});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: palette.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: palette.primary, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                color: palette.primary, size: 20),
            const SizedBox(height: 2),
            Text('Foto',
                style: TextStyle(
                  color: palette.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      ),
    );
  }
}

class _StripThumb extends StatelessWidget {
  final String url;
  const _StripThumb({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 64,
          height: 64,
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}

class _PagePreview extends StatelessWidget {
  final PhotobookPage page;
  final void Function(int slotIndex)? onTapSlot;

  const _PagePreview({required this.page, this.onTapSlot});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final template = PageTemplates.byId(page.templateId);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                for (int i = 0; i < template.slots.length; i++)
                  _slotWidget(
                    template.slots[i].toRect(size),
                    page.photoUrls[i],
                    i,
                    palette,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _slotWidget(
      Rect rect, String? url, int index, SilvestrePalette palette) {
    final inner = url == null
        ? Container(
            color: palette.surface,
            alignment: Alignment.center,
            child: Icon(Icons.add_photo_alternate_outlined,
                color: palette.textSecondary),
          )
        : Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                Container(color: Colors.grey.shade300),
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

class _PhotoChooserSheet extends StatelessWidget {
  final List<String> photos;
  final String? currentUrl;
  const _PhotoChooserSheet({required this.photos, this.currentUrl});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Scegli foto per questo riquadro',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: palette.textPrimary)),
          const SizedBox(height: 14),
          if (photos.isEmpty)
            Text('Nessuna foto disponibile. Carica foto dalla strip in alto.',
                style: TextStyle(color: palette.textSecondary))
          else
            SizedBox(
              height: 360,
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: photos.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return InkWell(
                      onTap: () => Navigator.pop(context, ''),
                      child: Container(
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: palette.border),
                        ),
                        child: Center(
                          child: Icon(Icons.do_not_disturb_alt,
                              color: palette.textSecondary),
                        ),
                      ),
                    );
                  }
                  final url = photos[i - 1];
                  final isCurrent = url == currentUrl;
                  return InkWell(
                    onTap: () => Navigator.pop(context, url),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCurrent ? palette.primary : palette.border,
                          width: isCurrent ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(url, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TemplateChooserSheet extends StatelessWidget {
  const _TemplateChooserSheet();

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Layout pagina',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: palette.textPrimary)),
          const SizedBox(height: 14),
          SizedBox(
            height: 280,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: PageTemplates.all.length,
              itemBuilder: (_, i) {
                final t = PageTemplates.all[i];
                return InkWell(
                  onTap: () => Navigator.pop(context, t),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: palette.border),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: LayoutBuilder(builder: (_, c) {
                              final s =
                                  Size(c.maxWidth, c.maxHeight);
                              return Container(
                                color: Colors.white,
                                child: Stack(
                                  children: [
                                    for (final slot in t.slots)
                                      Positioned.fromRect(
                                        rect: slot.toRect(s),
                                        child: Container(
                                            color: palette.primary
                                                .withValues(alpha: 0.4)),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${t.slotCount}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PhotobookResult {
  final List<String> photos;
  final List<PhotobookPage> pages;
  const PhotobookResult({required this.photos, required this.pages});
}
