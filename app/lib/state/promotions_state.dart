import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Stato delle campagne promozionali (collection promotions/).
/// Una promozione = 1 documento. Per WhatsApp manual batch teniamo l'array
/// degli ID dei contatti gia' inviati per supportare resume cross-sessione.
class Promotion {
  final String id;
  final String title;
  final String details;
  final String cost;
  final DateTime? validFrom;
  final DateTime? validTo;
  final List<String> photoUrls;
  final String channel; // 'whatsapp' (promo standard) | 'soft_optin' | 'fcm' (futuro)
  final String status; // 'draft' | 'in_progress' | 'completed' | 'cancelled'
  final List<String> recipientIds;
  final List<String> sentIds;
  final DateTime createdAt;
  final String createdBy;

  const Promotion({
    required this.id,
    required this.title,
    required this.details,
    required this.cost,
    this.validFrom,
    this.validTo,
    this.photoUrls = const [],
    required this.channel,
    required this.status,
    this.recipientIds = const [],
    this.sentIds = const [],
    required this.createdAt,
    required this.createdBy,
  });

  factory Promotion.fromFirestore(String id, Map<String, dynamic> d) =>
      Promotion(
        id: id,
        title: (d['title'] as String?) ?? '',
        details: (d['details'] as String?) ?? '',
        cost: (d['cost'] as String?) ?? '',
        validFrom: (d['validFrom'] as Timestamp?)?.toDate(),
        validTo: (d['validTo'] as Timestamp?)?.toDate(),
        photoUrls:
            ((d['photoUrls'] as List?)?.cast<String>() ?? const []),
        channel: (d['channel'] as String?) ?? 'whatsapp',
        status: (d['status'] as String?) ?? 'draft',
        recipientIds:
            ((d['recipientIds'] as List?)?.cast<String>() ?? const []),
        sentIds:
            ((d['sentIds'] as List?)?.cast<String>() ?? const []),
        createdAt:
            (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        createdBy: (d['createdBy'] as String?) ?? '',
      );

  int get sentCount => sentIds.length;
  int get totalCount => recipientIds.length;
  int get remainingCount => totalCount - sentCount;
  double get progress => totalCount == 0 ? 0 : sentCount / totalCount;

  String get statusLabel => switch (status) {
        'draft' => 'Bozza',
        'in_progress' => 'In corso',
        'completed' => 'Completata',
        'cancelled' => 'Annullata',
        _ => status,
      };
}

class PromotionsState extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Promotion> _promotions = [];
  StreamSubscription? _sub;

  List<Promotion> get promotions => List.unmodifiable(_promotions);
  List<Promotion> get inProgress =>
      _promotions.where((p) => p.status == 'in_progress').toList();

  void watchAll() {
    if (_sub != null) return;
    _sub = _db
        .collection('promotions')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snap) {
      _promotions = snap.docs
          .map((d) => Promotion.fromFirestore(d.id, d.data()))
          .toList();
      notifyListeners();
    }, onError: (_) {
      _promotions = [];
      notifyListeners();
    });
  }

  void stopWatching() {
    _sub?.cancel();
    _sub = null;
    _promotions = [];
    notifyListeners();
  }

  /// Crea una nuova campagna WhatsApp con i destinatari snapshot.
  Future<String> createWhatsAppCampaign({
    required String title,
    required String details,
    required String cost,
    DateTime? validFrom,
    DateTime? validTo,
    List<String> photoUrls = const [],
    required List<String> recipientIds,
    required String operatorUid,
  }) async {
    final doc = await _db.collection('promotions').add({
      'title': title,
      'details': details,
      'cost': cost,
      'validFrom': validFrom == null ? null : Timestamp.fromDate(validFrom),
      'validTo': validTo == null ? null : Timestamp.fromDate(validTo),
      'photoUrls': photoUrls,
      'channel': 'whatsapp',
      'status': 'in_progress',
      'recipientIds': recipientIds,
      'sentIds': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': operatorUid,
    });
    return doc.id;
  }

  /// Crea una campagna SOFT OPT-IN: template fisso (non modificabile),
  /// destinatari = solo ⚪ Nuovi (optInStatus=pending AND optInSentAt=null).
  /// Su ogni invio anche markOptInSent (lato marketingContactsState).
  Future<String> createSoftOptInCampaign({
    required List<String> recipientIds,
    required String operatorUid,
  }) async {
    final doc = await _db.collection('promotions').add({
      'title': 'Soft Opt-in',
      'details': 'Richiesta consenso marketing',
      'cost': '',
      'channel': 'soft_optin',
      'status': 'in_progress',
      'recipientIds': recipientIds,
      'sentIds': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': operatorUid,
    });
    return doc.id;
  }

  /// Marca un contatto come inviato. Idempotente via arrayUnion.
  Future<void> markSent(String promotionId, String contactId) async {
    await _db.collection('promotions').doc(promotionId).update({
      'sentIds': FieldValue.arrayUnion([contactId]),
    });
  }

  /// Quando sentCount == totalCount, marca completata.
  Future<void> markCompleted(String promotionId) async {
    await _db.collection('promotions').doc(promotionId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Annulla campagna (l'operatore decide di interrompere).
  Future<void> cancel(String promotionId) async {
    await _db.collection('promotions').doc(promotionId).update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final promotionsState = PromotionsState();
