import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Stato dei contatti marketing (collection Firestore marketing_contacts).
/// Caricabile SOLO da utenti staff (Firestore rules bloccano i customer).
class MarketingContact {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String optInStatus; // 'pending' | 'yes' | 'no'
  final DateTime? optInSentAt;
  final DateTime? optInRepliedAt;
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
  Future<void> markOptInNo(String contactId) async {
    await _db.collection('marketing_contacts').doc(contactId).update({
      'optInStatus': 'no',
      'optInRepliedAt': FieldValue.serverTimestamp(),
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
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final marketingContactsState = MarketingContactsState();
