import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Stato dei contatti marketing (collection Firestore marketing_contacts).
/// Caricabile SOLO da utenti staff (Firestore rules bloccano i customer).
/// Motivo del rifiuto (rejectionReason). Stabilisce se il cliente è
/// resettabile o no per finalità GDPR.
class RejectionReason {
  /// Cliente ha scritto STOP esplicitamente su WhatsApp. NON resettabile.
  static const String stop = 'stop';

  /// Cliente registrato in app senza spuntare marketing o ha tolto il
  /// consenso dalle Impostazioni. NON resettabile (scelta esplicita).
  static const String appDecline = 'app_decline';

  /// 30 giorni senza risposta al soft opt-in → cron auto-mark. Resettabile.
  static const String noReply30d = 'no_reply_30d';

  /// Operatore ha cliccato STOP manualmente nell'inbox SENZA evidenza
  /// che il cliente abbia scritto STOP (es. "non risponderà più").
  /// Resettabile con warning.
  static const String manualOperator = 'manual_operator';

  /// Record pre-feature, motivo sconosciuto. Resettabile con warning.
  static const String legacy = 'legacy';

  /// True se il cliente può essere riportato in ⚪ Nuovi.
  static bool isResettable(String? reason) =>
      reason == noReply30d || reason == manualOperator || reason == legacy ||
      reason == null;

  /// Label in chiaro per l'UI.
  static String label(String? reason) => switch (reason) {
        stop => 'Cliente ha scritto STOP esplicitamente',
        appDecline => 'Cliente ha rifiutato il marketing in app',
        noReply30d => 'Nessuna risposta dopo 30 giorni',
        manualOperator => 'Marcato come no dall\'operatore',
        legacy => 'Motivo non tracciato (record vecchio)',
        _ => 'Motivo non specificato',
      };
}

class MarketingContact {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String optInStatus; // 'pending' | 'yes' | 'no'
  final DateTime? optInSentAt;
  final DateTime? optInRepliedAt;
  final String? rejectionReason; // see RejectionReason.*
  final String source;
  final DateTime? createdAt;

  const MarketingContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.optInStatus,
    this.optInSentAt,
    this.optInRepliedAt,
    this.rejectionReason,
    required this.source,
    this.createdAt,
  });

  factory MarketingContact.fromFirestore(String id, Map<String, dynamic> d) =>
      MarketingContact(
        id: id,
        name: (d['name'] as String?) ?? '',
        phone: (d['phone'] as String?) ?? '',
        email: (d['email'] as String?) ?? '',
        optInStatus: (d['optInStatus'] as String?) ?? 'pending',
        optInSentAt: (d['optInSentAt'] as Timestamp?)?.toDate(),
        optInRepliedAt: (d['optInRepliedAt'] as Timestamp?)?.toDate(),
        rejectionReason: d['rejectionReason'] as String?,
        source: (d['source'] as String?) ?? '',
        createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      );

  /// True quando il contatto è candidato a soft opt-in (mai contattato).
  bool get isNew => optInStatus == 'pending' && optInSentAt == null;

  /// True quando il soft opt-in è stato inviato ma cliente non ha risposto.
  bool get isAwaiting =>
      optInStatus == 'pending' && optInSentAt != null;

  /// True quando il cliente ha dato consenso (puo' ricevere promo).
  bool get isOptedIn => optInStatus == 'yes';

  /// True quando il cliente ha rifiutato/scaduto (no future contact).
  bool get isRejected => optInStatus == 'no';
}

class MarketingContactsState extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<MarketingContact> _contacts = [];
  StreamSubscription? _sub;
  bool _loading = false;
  String? _error;

  List<MarketingContact> get contacts => List.unmodifiable(_contacts);
  bool get loading => _loading;
  String? get error => _error;

  // Stats helpers
  int get totalCount => _contacts.length;
  int get optedInCount =>
      _contacts.where((c) => c.optInStatus == 'yes').length;
  int get newCount => _contacts.where((c) => c.isNew).length;
  int get awaitingCount =>
      _contacts.where((c) => c.isAwaiting).length;
  int get rejectedCount =>
      _contacts.where((c) => c.optInStatus == 'no').length;

  void watchAll() {
    if (_sub != null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    _sub = _db
        .collection('marketing_contacts')
        .orderBy('name')
        .snapshots()
        .listen((snap) {
      _contacts = snap.docs
          .map((d) => MarketingContact.fromFirestore(d.id, d.data()))
          .toList();
      _loading = false;
      _error = null;
      notifyListeners();
    }, onError: (e) {
      _loading = false;
      _error = e.toString();
      _contacts = [];
      notifyListeners();
    });
  }

  void stopWatching() {
    _sub?.cancel();
    _sub = null;
    _contacts = [];
    _loading = false;
    notifyListeners();
  }

  /// Operatore conferma "SI ricevuto" su WhatsApp per il contatto.
  Future<void> markOptInYes(String contactId) async {
    await _db.collection('marketing_contacts').doc(contactId).update({
      'optInStatus': 'yes',
      'optInRepliedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Operatore conferma "STOP ricevuto" o vuole bloccare il contatto.
  /// [reason] e' un valore di RejectionReason.* che determina se il
  /// contatto sara' resettabile in futuro.
  Future<void> markOptInNo(String contactId,
      {String reason = RejectionReason.manualOperator}) async {
    await _db.collection('marketing_contacts').doc(contactId).update({
      'optInStatus': 'no',
      'optInRepliedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason,
    });
  }

  /// Marca soft opt-in inviato (passa da 'Nuovo' a 'In attesa').
  Future<void> markOptInSent(String contactId) async {
    await _db.collection('marketing_contacts').doc(contactId).update({
      'optInSentAt': FieldValue.serverTimestamp(),
    });
  }

  /// Riporta un contatto allo stato iniziale ⚪ Nuovo: optInStatus=pending,
  /// optInSentAt=null. Usato per ri-includere contatti dopo un periodo,
  /// es. dopo che la scadenza 30gg li ha messi in 🔴.
  ///
  /// USO RESPONSABILE: per i 🔴 che hanno detto STOP esplicitamente,
  /// questo è una violazione GDPR. Solo l'operatore sa il motivo del
  /// rifiuto: l'UI deve mostrare un warning chiaro prima di permettere
  /// il reset dei 🔴.
  Future<void> resetToNuovo(String contactId) async {
    await _db.collection('marketing_contacts').doc(contactId).update({
      'optInStatus': 'pending',
      'optInSentAt': null,
      'optInRepliedAt': null,
      'rejectionReason': FieldValue.delete(),
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final marketingContactsState = MarketingContactsState();
