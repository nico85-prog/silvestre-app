enum PaymentMethod {
  card,         // Stripe (online card)
  satispay,     // Satispay Business
  bankTransfer, // Bonifico Istantaneo (manual verification)
  inStore,      // Pay at pickup (con caparra 20%)
}

extension PaymentMethodX on PaymentMethod {
  String get key => name;

  String get label => switch (this) {
        PaymentMethod.card => 'Carta di credito',
        PaymentMethod.satispay => 'Satispay',
        PaymentMethod.bankTransfer => 'Bonifico Istantaneo',
        PaymentMethod.inStore => 'Paga in negozio',
      };

  String get shortLabel => switch (this) {
        PaymentMethod.card => 'Carta',
        PaymentMethod.satispay => 'Satispay',
        PaymentMethod.bankTransfer => 'Bonifico',
        PaymentMethod.inStore => 'In negozio',
      };

  String get description => switch (this) {
        PaymentMethod.card =>
            'Visa, Mastercard, Amex, postpay. Sicuro via Stripe.',
        PaymentMethod.satispay =>
            'Pagamento istantaneo dall\'app Satispay.',
        PaymentMethod.bankTransfer =>
            'Versa l\'importo dal tuo conto e carica la ricevuta. L\'ordine parte dopo verifica.',
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
  // Bonifico Istantaneo: URL della ricevuta caricata dal cliente (Cloudinary).
  // Operatore verifica manualmente il bonifico sul conto bancario e
  // conferma in app → payment.verified passa a true.
  final String? proofUrl;
  final bool verified;

  const PaymentResult({
    required this.method,
    this.transactionId,
    required this.paidNow,
    this.lastFour,
    this.depositAmount = 0,
    this.depositMethod,
    this.depositTransactionId,
    this.proofUrl,
    this.verified = false,
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
        if (proofUrl != null) 'proofUrl': proofUrl,
        if (method == PaymentMethod.bankTransfer) 'verified': verified,
      };
}

/// Dati bonifico del negozio. Hard-coded come default ma sovrascrivibili
/// da settings/payment in Firestore se in futuro cambia conto/banca.
class BankAccount {
  final String iban;
  final String holder;
  final String bankName;

  const BankAccount({
    required this.iban,
    required this.holder,
    required this.bankName,
  });
}

const BankAccount kShopBankAccount = BankAccount(
  iban: 'IT51E0329601601000064537440',
  holder: 'Antonio Silvestre',
  bankName: 'Banca Fideuram',
);

/// Percentuale caparra obbligatoria per "Paga in negozio".
const double kDepositPercentage = 0.20;

/// Caparra minima in euro (sotto questa soglia, Stripe rifiuta la transazione).
const double kDepositMinAmount = 0.50;
