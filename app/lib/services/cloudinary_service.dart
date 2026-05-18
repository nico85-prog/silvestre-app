import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Servizio di upload foto su Cloudinary tramite upload preset UNSIGNED.
///
/// L'API Secret NON deve mai stare nell'app client.
/// Lo cloud name + il preset name sono pubblici per design.
class CloudinaryService {
  static const String cloudName = 'dcag1ztpq';
  static const String uploadPreset = 'silvestre_uploads';

  static String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// Carica un'immagine direttamente dalla memoria dell'app.
  /// Ritorna la URL pubblica della foto su CDN Cloudinary.
  ///
  /// [userId] viene usato come folder (uploads/{userId}/) per isolare i file
  /// per utente. Il preset deve essere configurato con folder = uploads/$(uid).
  static Future<CloudinaryUploadResult> uploadBytes({
    required Uint8List bytes,
    required String fileName,
    required String userId,
    String? folderSuffix,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
    request.fields['upload_preset'] = uploadPreset;
    // Bypass preset folder template ($(uid) doesn't substitute in unsigned uploads)
    // by setting public_id with full path. Cloudinary places it accordingly.
    final ts = DateTime.now().millisecondsSinceEpoch;
    final base = fileName.split('.').first.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    final pathSuffix = folderSuffix == null ? '' : '/$folderSuffix';
    request.fields['public_id'] =
        'silvestre/$userId$pathSuffix/${ts}_$base';
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw CloudinaryException(
        'Upload fallito (${response.statusCode}): ${response.body}',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return CloudinaryUploadResult(
      publicId: data['public_id'] as String,
      url: data['secure_url'] as String,
      width: (data['width'] as num).toInt(),
      height: (data['height'] as num).toInt(),
      bytes: (data['bytes'] as num).toInt(),
      format: data['format'] as String,
    );
  }

  /// Genera una URL Cloudinary con trasformazioni on-the-fly (resize, crop, ecc.).
  ///
  /// Esempio: thumbnail 200x200:
  ///   transformedUrl(publicId: 'uploads/u_123/IMG_001', width: 200, height: 200)
  ///   -> https://res.cloudinary.com/dcag1ztpq/image/upload/w_200,h_200,c_fill/uploads/u_123/IMG_001
  static String transformedUrl({
    required String publicId,
    int? width,
    int? height,
    String? cropMode = 'fill',
    int quality = 80,
    String format = 'auto',
  }) {
    final params = <String>[];
    if (width != null) params.add('w_$width');
    if (height != null) params.add('h_$height');
    if (cropMode != null && (width != null || height != null)) {
      params.add('c_$cropMode');
    }
    params.add('q_$quality');
    params.add('f_$format');

    final transform = params.join(',');
    return 'https://res.cloudinary.com/$cloudName/image/upload/$transform/$publicId';
  }
}

class CloudinaryUploadResult {
  final String publicId;
  final String url;
  final int width;
  final int height;
  final int bytes;
  final String format;

  const CloudinaryUploadResult({
    required this.publicId,
    required this.url,
    required this.width,
    required this.height,
    required this.bytes,
    required this.format,
  });
}

class CloudinaryException implements Exception {
  final String message;
  CloudinaryException(this.message);
  @override
  String toString() => message;
}
