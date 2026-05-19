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
            'Versa il 20% di caparra ora (carta o Satispay). Il saldo lo paghi al ritiro.',
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
  // Caparra: usata SOLO quando method=inStore.
  // depositAmount > 0 = 20% versato online; saldo restante in negozio al ritiro.
  final double depositAmount;
  final PaymentMethod? depositMethod;
  final String? depositTransactionId;

  const PaymentResult({
    required this.method,
    this.transactionId,
    required this.paidNow,
    this.lastFour,
    this.depositAmount = 0,
    this.depositMethod,
    this.depositTransactionId,
  });

  Map<String, dynamic> toFirestore() => {
        'method': method.name,
        'transactionId': transactionId,
        'paidNow': paidNow,
        'lastFour': lastFour,
        if (depositAmount > 0) 'depositAmount': depositAmount,
        if (depositMethod != null) 'depositMethod': depositMethod!.name,
        if (depositTransactionId != null)
          'depositTransactionId': depositTransactionId,
      };
}

/// Percentuale caparra obbligatoria per "Paga in negozio".
const double kDepositPercentage = 0.20;
