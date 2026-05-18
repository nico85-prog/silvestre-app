enum PaymentMethod {
  card,      // Stripe (online card)
  satispay,  // Satispay Business
  inStore,   // Pay at pickup
}

extension PaymentMethodX on PaymentMethod {
  String get key => name;

  String get label => switch (this) {
        PaymentMethod.card => 'Carta di credito',
        PaymentMethod.satispay => 'Satispay',
        PaymentMethod.inStore => 'Paga in negozio',
      };

  String get shortLabel => switch (this) {
        PaymentMethod.card => 'Carta',
        PaymentMethod.satispay => 'Satispay',
        PaymentMethod.inStore => 'In negozio',
      };

  String get description => switch (this) {
        PaymentMethod.card =>
            'Visa, Mastercard, Amex, postpay. Sicuro via Stripe.',
        PaymentMethod.satispay =>
            'Pagamento istantaneo dall\'app Satispay.',
        PaymentMethod.inStore =>
            'Paghi al momento del ritiro in negozio.',
      };

  static PaymentMethod fromKey(String? k) =>
      PaymentMethod.values.firstWhere(
        (m) => m.name == k,
        orElse: () => PaymentMethod.inStore,
      );
}

class PaymentResult {
  final PaymentMethod method;
  final String? transactionId;
  final bool paidNow;
  final String? lastFour; // for card display

  const PaymentResult({
    required this.method,
    this.transactionId,
    required this.paidNow,
    this.lastFour,
  });

  Map<String, dynamic> toFirestore() => {
        'method': method.name,
        'transactionId': transactionId,
        'paidNow': paidNow,
        'lastFour': lastFour,
      };
}
