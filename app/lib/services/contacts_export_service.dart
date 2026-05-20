// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Genera un CSV dei contatti marketing correnti su Firestore e lo
/// scarica come file sul dispositivo dell'operatore.
///
/// Schema CSV: nome;telefono;email;stato;data_consenso;data_invio_softoptin;fonte
/// Separatore ; (italiano), BOM UTF-8 per compatibilita' Excel.
class ContactsExportService {
  static Future<int> exportAllToCsv() async {
    final db = FirebaseFirestore.instance;
    final snap = await db
        .collection('marketing_contacts')
        .orderBy('name')
        .get();

    final buf = StringBuffer();
    buf.write('\uFEFF'); // BOM UTF-8 per Excel
    buf.writeln(
        'nome;telefono;email;stato;data_consenso;data_invio_softoptin;fonte');

    for (final doc in snap.docs) {
      final d = doc.data();
      final name = _csv((d['name'] as String?) ?? '');
      final phone = _csv((d['phone'] as String?) ?? '');
      final email = _csv((d['email'] as String?) ?? '');
      final status =
          _statusLabel((d['optInStatus'] as String?) ?? 'pending');
      final repliedAt = (d['optInRepliedAt'] as Timestamp?)?.toDate();
      final sentAt = (d['optInSentAt'] as Timestamp?)?.toDate();
      final source = _csv((d['source'] as String?) ?? '');
      buf.writeln([
        name,
        phone,
        email,
        status,
        _fmtDate(repliedAt),
        _fmtDate(sentAt),
        source,
      ].join(';'));
    }

    _downloadWeb(buf.toString());
    return snap.docs.length;
  }

  static String _csv(String s) {
    if (s.contains(';') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static String _statusLabel(String s) => switch (s) {
        'yes' => 'Acconsentito',
        'no' => 'Rifiutato',
        'pending' => 'Pending',
        _ => s,
      };

  static String _fmtDate(DateTime? d) => d == null
      ? ''
      : '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/${d.year}';

  static void _downloadWeb(String content) {
    final today = DateTime.now()
        .toIso8601String()
        .split('T')
        .first
        .replaceAll('-', '');
    final fileName = 'contatti_silvestre_$today.csv';
    final bytes = utf8.encode(content);
    final blob =
        html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    html.document.body!.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }
}
