import 'package:url_launcher/url_launcher.dart';

/// Apertura nativa dei canali di messaggistica con testo pre-compilato.
/// L'operatore preme "Invia" nell'app nativa per consegnare effettivamente.
/// Zero backend, zero costi, funziona ovunque (web apre WhatsApp Web).
class MessagingService {
  /// Formato internazionale richiesto da WhatsApp (es. 393331234567).
  /// Per default assume IT (+39) se il numero inizia con 3 senza prefisso.
  static String normalizePhoneForWhatsApp(String phone) {
    var n = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (n.startsWith('+')) n = n.substring(1);
    if (!n.startsWith('39') && n.startsWith('3')) n = '39$n';
    return n;
  }

  static Future<bool> sendWhatsApp({
    required String phone,
    required String message,
  }) async {
    final p = normalizePhoneForWhatsApp(phone);
    final url = Uri.parse(
        'https://wa.me/$p?text=${Uri.encodeComponent(message)}');
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }

  static Future<bool> sendSms({
    required String phone,
    required String message,
  }) async {
    final url = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': message},
    );
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }

  static Future<bool> sendEmail({
    required String email,
    required String subject,
    required String body,
  }) async {
    final url = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': subject, 'body': body},
    );
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }

  static Future<bool> callPhone(String phone) async {
    final url = Uri(scheme: 'tel', path: phone);
    return launchUrl(url);
  }
}
