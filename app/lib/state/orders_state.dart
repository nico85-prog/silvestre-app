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
    final pickupCode =
        'SLV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
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

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final ordersState = OrdersState();
