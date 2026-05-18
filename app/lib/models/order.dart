import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'cart_item.dart';

enum OrderStatus {
  quoteRequested,   // Cliente ha richiesto preventivo per lavoro personalizzato
  quoted,           // Operatore ha mandato preventivo (in attesa accettazione cliente)
  submitted,
  inProduction,
  readyForPickup,
  pickedUp,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get key => name;

  static OrderStatus fromKey(String? key) {
    return OrderStatus.values.firstWhere(
      (s) => s.name == key,
      orElse: () => OrderStatus.submitted,
    );
  }

  String get label => switch (this) {
        OrderStatus.quoteRequested => 'Preventivo richiesto',
        OrderStatus.quoted => 'Preventivo pronto',
        OrderStatus.submitted => 'Ricevuto',
        OrderStatus.inProduction => 'In lavorazione',
        OrderStatus.readyForPickup => 'Pronto per il ritiro',
        OrderStatus.pickedUp => 'Ritirato',
        OrderStatus.cancelled => 'Annullato',
      };

  IconData get icon => switch (this) {
        OrderStatus.quoteRequested => Icons.question_mark,
        OrderStatus.quoted => Icons.request_quote_outlined,
        OrderStatus.submitted => Icons.receipt_long_outlined,
        OrderStatus.inProduction => Icons.precision_manufacturing_outlined,
        OrderStatus.readyForPickup => Icons.local_mall_outlined,
        OrderStatus.pickedUp => Icons.check_circle_outline,
        OrderStatus.cancelled => Icons.cancel_outlined,
      };

  Color colorOn(BuildContext context) {
    final p = Theme.of(context).extension<SilvestrePalette>()!;
    return switch (this) {
      OrderStatus.quoteRequested => p.secondary,
      OrderStatus.quoted => p.warning,
      OrderStatus.submitted => p.warning,
      OrderStatus.inProduction => p.primary,
      OrderStatus.readyForPickup => p.success,
      OrderStatus.pickedUp => p.textSecondary,
      OrderStatus.cancelled => p.error,
    };
  }
}

class CustomerOrder {
  final String id;
  final String userId;
  final List<CartItem> items;
  final OrderStatus status;
  final String pickupCode;
  final double total;
  final DateTime createdAt;
  final DateTime? readyAt;
  final String? customerNote;
  final String? customerName;
  final String? customerPhone;
  final Map<String, dynamic>? payment;
  // Lavoro personalizzato — campi opzionali
  final String? customRequestTitle;
  final String? customRequestDescription;
  final List<String> customRequestPhotoUrls;
  final double? quoteAmount;
  final String? quoteEta;
  final String? quoteOperatorNote; // {method, transactionId?, paidNow, lastFour?}

  const CustomerOrder({
    required this.id,
    required this.userId,
    required this.items,
    required this.status,
    required this.pickupCode,
    required this.total,
    required this.createdAt,
    this.readyAt,
    this.customerNote,
    this.customerName,
    this.customerPhone,
    this.payment,
    this.customRequestTitle,
    this.customRequestDescription,
    this.customRequestPhotoUrls = const [],
    this.quoteAmount,
    this.quoteEta,
    this.quoteOperatorNote,
  });

  bool get isCustomRequest => customRequestTitle != null;

  CustomerOrder copyWith({OrderStatus? status, DateTime? readyAt}) =>
      CustomerOrder(
        id: id,
        userId: userId,
        items: items,
        status: status ?? this.status,
        pickupCode: pickupCode,
        total: total,
        createdAt: createdAt,
        readyAt: readyAt ?? this.readyAt,
        customerNote: customerNote,
        customerName: customerName,
        customerPhone: customerPhone,
        payment: payment,
        customRequestTitle: customRequestTitle,
        customRequestDescription: customRequestDescription,
        customRequestPhotoUrls: customRequestPhotoUrls,
        quoteAmount: quoteAmount,
        quoteEta: quoteEta,
        quoteOperatorNote: quoteOperatorNote,
      );

  int get itemCount => items.fold(0, (s, i) => s + i.quantity);

  String get paymentMethodKey =>
      (payment?['method'] as String?) ?? 'inStore';
  bool get isPaidOnline => (payment?['paidNow'] as bool?) ?? false;

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'items': items.map((i) => i.toFirestore()).toList(),
        'status': status.name,
        'pickupCode': pickupCode,
        'total': total,
        'createdAt': Timestamp.fromDate(createdAt),
        'readyAt': readyAt == null ? null : Timestamp.fromDate(readyAt!),
        'customerNote': customerNote,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'payment': payment,
        'customRequestTitle': customRequestTitle,
        'customRequestDescription': customRequestDescription,
        'customRequestPhotoUrls': customRequestPhotoUrls,
        'quoteAmount': quoteAmount,
        'quoteEta': quoteEta,
        'quoteOperatorNote': quoteOperatorNote,
      };

  factory CustomerOrder.fromFirestore(String id, Map<String, dynamic> data) {
    return CustomerOrder(
      id: id,
      userId: data['userId'] as String,
      items: (data['items'] as List)
          .map((e) => CartItem.fromFirestore(e as Map<String, dynamic>))
          .toList(),
      status: OrderStatusX.fromKey(data['status'] as String?),
      pickupCode: data['pickupCode'] as String,
      total: (data['total'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      readyAt: (data['readyAt'] as Timestamp?)?.toDate(),
      customerNote: data['customerNote'] as String?,
      customerName: data['customerName'] as String?,
      customerPhone: data['customerPhone'] as String?,
      payment: (data['payment'] as Map?)?.cast<String, dynamic>(),
      customRequestTitle: data['customRequestTitle'] as String?,
      customRequestDescription: data['customRequestDescription'] as String?,
      customRequestPhotoUrls: (data['customRequestPhotoUrls'] as List?)
              ?.cast<String>() ??
          const [],
      quoteAmount: (data['quoteAmount'] as num?)?.toDouble(),
      quoteEta: data['quoteEta'] as String?,
      quoteOperatorNote: data['quoteOperatorNote'] as String?,
    );
  }
}
