import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';

/// Section that lets the customer pick photos from device, uploads them to
/// Cloudinary unsigned preset, and exposes the public URLs to the parent.
class PhotoPickerSection extends StatefulWidget {
  final List<String> initialUrls;
  final ValueChanged<List<String>> onChanged;
  final String? subtitle;

  const PhotoPickerSection({
    super.key,
    this.initialUrls = const [],
    required this.onChanged,
    this.subtitle,
  });

  @override
  State<PhotoPickerSection> createState() => _PhotoPickerSectionState();
}

class _PhotoPickerSectionState extends State<PhotoPickerSection> {
  late final List<String> _urls = List.from(widget.initialUrls);
  final Set<String> _uploading = {};
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUpload() async {
    final user = authState.currentUser;
    if (user == null) return;

    final List<XFile> picked = await _picker.pickMultiImage(
      imageQuality: 90,
      maxWidth: 4000,
    );
    if (picked.isEmpty) return;

    for (final x in picked) {
      final tempKey = 'tmp_${DateTime.now().microsecondsSinceEpoch}_${x.name}';
      setState(() => _uploading.add(tempKey));

      try {
        final bytes = await x.readAsBytes();
        final result = await CloudinaryService.uploadBytes(
          bytes: bytes,
          fileName: x.name,
          userId: user.id,
        );
        if (!mounted) return;
        setState(() {
          _uploading.remove(tempKey);
          _urls.add(result.url);
        });
        widget.onChanged(List.from(_urls));
      } catch (e) {
        if (!mounted) return;
        setState(() => _uploading.remove(tempKey));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload fallito: $e')),
        );
      }
    }
  }

  void _remove(int index) {
    setState(() => _urls.removeAt(index));
    widget.onChanged(List.from(_urls));
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    final hasContent = _urls.isNotEmpty || _uploading.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library_outlined, color: palette.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasContent
                      ? 'Foto caricate (${_urls.length})'
                      : 'Carica le tue foto',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              if (hasContent)
                IconButton(
                  tooltip: 'Aggiungi altre',
                  icon: Icon(Icons.add_a_photo_outlined,
                      color: palette.primary),
                  onPressed: _pickAndUpload,
                ),
            ],
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(widget.subtitle!,
                style: TextStyle(fontSize: 12, color: palette.textSecondary)),
          ],
          const SizedBox(height: 12),
          if (!hasContent)
            InkWell(
              onTap: _pickAndUpload,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: palette.primary,
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined,
                        size: 40, color: palette.primary),
                    const SizedBox(height: 6),
                    Text(
                      'Tocca per caricare',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: palette.primary),
                    ),
                    Text(
                      'JPG, PNG, HEIC — max 15 MB cad.',
                      style: TextStyle(
                          fontSize: 12, color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                ..._urls.asMap().entries.map((e) {
                  return _PhotoThumb(
                    url: e.value,
                    onRemove: () => _remove(e.key),
                  );
                }),
                for (final _ in _uploading)
                  Container(
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: palette.border),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: palette.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;

  const _PhotoThumb({required this.url, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
