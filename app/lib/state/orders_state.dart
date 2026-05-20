import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/payment.dart';

class OrdersState extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<CustomerOrder> _orders = [];
  StreamSubscription? _sub;
  String? _watchingUid;
  bool _watchingAll = false;

  List<CustomerOrder> get orders => List.unmodifiable(_orders);

  /// Subscribes to current user's orders.
  void watchForUser(String userId) {
    if (_watchingUid == userId && !_watchingAll) return;
    _sub?.cancel();
    _watchingUid = userId;
    _watchingAll = false;
    _sub = _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(_onSnapshot, onError: (_) {
      _orders = [];
      notifyListeners();
    });
  }

  /// Subscribes to ALL orders (operator view).
  void watchAll() {
    if (_watchingAll) return;
    _sub?.cancel();
    _watchingAll = true;
    _watchingUid = null;
    _sub = _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(_onSnapshot, onError: (_) {
      _orders = [];
      notifyListeners();
    });
  }

  void stopWatching() {
    _sub?.cancel();
    _sub = null;
    _watchingUid = null;
    _watchingAll = false;
    _orders = [];
    notifyListeners();
  }

  void _onSnapshot(QuerySnapshot snap) {
    _orders = snap.docs
        .map((d) => CustomerOrder.fromFirestore(d.id, d.data() as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  List<CustomerOrder> forUser(String userId) =>
      _orders.where((o) => o.userId == userId).toList();

  Future<String> submitOrder({
    required String userId,
    required List<CartItem> items,
    String? customerNote,
    String? customerName,
    String? customerPhone,
    PaymentResult? payment,
  }) async {
    // Bonifico: usa la causale (= pickupCode pre-generato dalla sheet) per
    // far combaciare l'ordine con quello che il cliente ha scritto sul
    // bonifico. Altrimenti genera codice nuovo come al solito.
    final pickupCode = (payment?.method == PaymentMethod.bankTransfer &&
            payment?.transactionId != null)
        ? payment!.transactionId!
        : 'SLV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final order = CustomerOrder(
      id: '',
      userId: userId,
      items: items,
      status: OrderStatus.submitted,
      pickupCode: pickupCode,
      total: items.fold(0, (s, i) => s + i.lineTotal),
      createdAt: DateTime.now(),
      customerNote: customerNote,
      customerName: customerName,
      customerPhone: customerPhone,
      payment: payment?.toFirestore(),
    );
    await _db.collection('orders').add(order.toFirestore());
    return pickupCode;
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    final updates = <String, dynamic>{
      'status': status.name,
      if (status == OrderStatus.readyForPickup)
        'readyAt': Timestamp.now(),
    };
    await _db.collection('orders').doc(orderId).update(updates);
  }

  /// Operatore conferma di aver verificato il bonifico istantaneo sul conto.
  /// Aggiorna payment.verified=true e payment.paidNow=true così l'ordine
  /// risulta pagato a tutti gli effetti.
  Future<void> verifyBankTransfer(String orderId) async {
    await _db.collection('orders').doc(orderId).update({
      'payment.verified': true,
      'payment.paidNow': true,
    });
  }

  /// Crea una richiesta di lavoro personalizzato (preventivo).
  /// L'ordine parte in stato quoteRequested e non ha items/total finché
  /// l'operatore non fa preventivo e cliente accetta.
  Future<String> submitCustomRequest({
    required String userId,
    required String title,
    required String description,
    required List<String> photoUrls,
    String? customerName,
    String? customerPhone,
  }) async {
    final pickupCode =
        'SLV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final order = CustomerOrder(
      id: '',
      userId: userId,
      items: const [],
      status: OrderStatus.quoteRequested,
      pickupCode: pickupCode,
      total: 0,
      createdAt: DateTime.now(),
      customerName: customerName,
      customerPhone: customerPhone,
      customRequestTitle: title,
      customRequestDescription: description,
      customRequestPhotoUrls: photoUrls,
    );
    await _db.collection('orders').add(order.toFirestore());
    return pickupCode;
  }

  /// L'operatore manda il preventivo (importo, tempi, nota).
  Future<void> sendQuote({
    required String orderId,
    required double amount,
    required String eta,
    String? operatorNote,
  }) async {
    await _db.collection('orders').doc(orderId).update({
      'status': OrderStatus.quoted.name,
      'quoteAmount': amount,
      'quoteEta': eta,
      'quoteOperatorNote': operatorNote,
      'total': amount,
    });
  }

  /// Cerca un ordine in stato 'quoted' per il dato pickupCode e userId.
  /// Usato dal cliente che inserisce il codice ricevuto via WhatsApp.
  Future<CustomerOrder?> findQuoteByCode({
    required String pickupCode,
    required String userId,
  }) async {
    final snap = await _db
        .collection('orders')
        .where('pickupCode', isEqualTo: pickupCode.trim().toUpperCase())
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: OrderStatus.quoted.name)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return CustomerOrder.fromFirestore(snap.docs.first.id, snap.docs.first.data());
  }

  /// Il cliente accetta il preventivo dopo aver pagato → submitted.
  /// Salva anche il PaymentResult.
  Future<void> acceptQuote(String orderId, {PaymentResult? payment}) async {
    final updates = <String, dynamic>{
      'status': OrderStatus.submitted.name,
    };
    if (payment != null) {
      updates['payment'] = payment.toFirestore();
    }
    await _db.collection('orders').doc(orderId).update(updates);
  }

  /// Il cliente declina il preventivo → ordine cancellato.
  Future<void> declineQuote(String orderId) async {
    await _db.collection('orders').doc(orderId).update({
      'status': OrderStatus.cancelled.name,
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final ordersState = OrdersState();
