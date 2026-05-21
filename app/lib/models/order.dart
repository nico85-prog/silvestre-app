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

/// Metodo di consegna scelto dal cliente.
enum DeliveryMethod {
  pickup,    // Ritiro in negozio (default, gratis)
  shipping,  // Spedizione a domicilio in Italia (costo aggiuntivo configurabile)
}

extension DeliveryMethodX on DeliveryMethod {
  String get key => name;

  String get label => switch (this) {
        DeliveryMethod.pickup => 'Ritiro in negozio',
        DeliveryMethod.shipping => 'Spedisci a domicilio',
      };

  static DeliveryMethod fromKey(String? k) =>
      DeliveryMethod.values.firstWhere(
        (m) => m.name == k,
        orElse: () => DeliveryMethod.pickup,
      );
}

/// Indirizzo di spedizione (solo se DeliveryMethod.shipping).
/// Nome, cognome, telefono pre-compilati dal profilo (non editabili).
class ShippingAddress {
  final String fullName;     // dal profilo (read-only)
  final String phone;        // dal profilo (read-only)
  final String street;       // editabile
  final String streetNumber; // editabile
  final String zipCode;      // editabile
  final String city;         // editabile
  final String province;     // editabile, 2 lettere (es. NA)
  final String? notes;       // opzionale (citofono, piano, orari)

  const ShippingAddress({
    required this.fullName,
    required this.phone,
    required this.street,
    required this.streetNumber,
    required this.zipCode,
    required this.city,
    required this.province,
    this.notes,
  });

  Map<String, dynamic> toFirestore() => {
        'fullName': fullName,
        'phone': phone,
        'street': street,
        'streetNumber': streetNumber,
        'zipCode': zipCode,
        'city': city,
        'province': province,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };

  factory ShippingAddress.fromFirestore(Map<String, dynamic> d) =>
      ShippingAddress(
        fullName: (d['fullName'] as String?) ?? '',
        phone: (d['phone'] as String?) ?? '',
        street: (d['street'] as String?) ?? '',
        streetNumber: (d['streetNumber'] as String?) ?? '',
        zipCode: (d['zipCode'] as String?) ?? '',
        city: (d['city'] as String?) ?? '',
        province: (d['province'] as String?) ?? '',
        notes: d['notes'] as String?,
      );

  /// Indirizzo formattato su una riga per UI compatta.
  String get oneLine =>
      '$street $streetNumber, $zipCode $city ($province)';
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
  // Consegna: pickup (default) o shipping. Se shipping, shippingAddress
  // contiene l'indirizzo + shippingCost il costo extra applicato.
  final DeliveryMethod deliveryMethod;
  final ShippingAddress? shippingAddress;
  final double shippingCost; // 0 per pickup

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
    this.deliveryMethod = DeliveryMethod.pickup,
    this.shippingAddress,
    this.shippingCost = 0,
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
        deliveryMethod: deliveryMethod,
        shippingAddress: shippingAddress,
        shippingCost: shippingCost,
      );

  int get itemCount => items.fold(0, (s, i) => s + i.quantity);

  String get paymentMethodKey =>
      (payment?['method'] as String?) ?? 'inStore';
  bool get isPaidOnline => (payment?['paidNow'] as bool?) ?? false;

  /// True quando l'ordine è stato pagato via bonifico ma l'operatore non
  /// ha ancora verificato sul conto. UI deve evidenziarlo come "da verificare".
  bool get isPendingBankTransfer =>
      paymentMethodKey == 'bankTransfer' &&
      !((payment?['verified'] as bool?) ?? false);

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
        'deliveryMethod': deliveryMethod.name,
        if (shippingAddress != null)
          'shippingAddress': shippingAddress!.toFirestore(),
        if (shippingCost > 0) 'shippingCost': shippingCost,
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
      deliveryMethod:
          DeliveryMethodX.fromKey(data['deliveryMethod'] as String?),
      shippingAddress: (data['shippingAddress'] as Map?) == null
          ? null
          : ShippingAddress.fromFirestore(
              (data['shippingAddress'] as Map).cast<String, dynamic>()),
      shippingCost: (data['shippingCost'] as num?)?.toDouble() ?? 0,
    );
  }
}
