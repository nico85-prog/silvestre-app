import 'package:url_launcher/url_launcher.dart';

/// Apertura nativa dei canali di messaggistica con testo pre-compilato.
/// L'operatore preme "Invia" nell'app nativa per consegnare effettivamente.
/// Zero backend, zero costi, funziona ovunque (web apre WhatsApp Web).
class MessagingService {
  /// Formato internazionale richiesto da WhatsApp (es. 393331234567).
  /// Gestisce tutte le variazioni che il cliente potrebbe inserire:
  ///   +39 350 123 4567, +393501234567, 39 350 123 4567,
  ///   0039 350 1234567, 350-1234567, 350.1234567, 3501234567
  /// Ritorna stringa VUOTA se il numero non è valido per WhatsApp
  /// (vuoto, troppo corto, solo whitespace).
  static String normalizePhoneForWhatsApp(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return '';
    // Strip TUTTO tranne le cifre
    var n = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    // 00 prefix internazionale → rimuovi
    if (n.startsWith('00')) n = n.substring(2);
    // Mobile italiano senza prefisso (es. 350...) → aggiungi 39
    if (n.length >= 9 && n.length <= 11 && n.startsWith('3') &&
        !n.startsWith('39')) {
      n = '39$n';
    }
    // Validazione minima: numero internazionale plausibile (8+ digits)
    if (n.length < 8) return '';
    return n;
  }

  static Future<bool> sendWhatsApp({
    required String phone,
    required String message,
  }) async {
    final p = normalizePhoneForWhatsApp(phone);
    if (p.isEmpty) {
      // Numero non valido — non lanciare URL rotto
      return false;
    }
    // Usa api.whatsapp.com (più robusto su browser/PWA rispetto a wa.me)
    final url = Uri.parse(
        'https://api.whatsapp.com/send?phone=$p&text=${Uri.encodeComponent(message)}');
    try {
      final ok = await launchUrl(url,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank');
      if (ok) return true;
    } catch (_) {}
    return launchUrl(url,
        mode: LaunchMode.platformDefault, webOnlyWindowName: '_blank');
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
