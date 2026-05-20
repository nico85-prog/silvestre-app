enum PaymentMethod {
  bankTransfer, // Bonifico Istantaneo (manual verification) — UNICO metodo online
  inStore,      // Pay at pickup (con caparra 20% via bonifico)
}

extension PaymentMethodX on PaymentMethod {
  String get key => name;

  String get label => switch (this) {
        PaymentMethod.bankTransfer => 'Bonifico Istantaneo',
        PaymentMethod.inStore => 'Paga in negozio',
      };

  String get shortLabel => switch (this) {
        PaymentMethod.bankTransfer => 'Bonifico',
        PaymentMethod.inStore => 'In negozio',
      };

  String get description => switch (this) {
        PaymentMethod.bankTransfer =>
            'Versa l\'importo dal tuo conto e carica la ricevuta. 0% commissioni.',
        PaymentMethod.inStore =>
            'Versa il 20% di caparra ora via bonifico. Il saldo lo paghi al ritiro.',
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
  // Per ordini full-bonifico è il proof del pagamento totale; per ordini
  // inStore con caparra è il proof della caparra (20%).
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
        // Per ordini inStore con caparra-bonifico anche serve verifica
        if (method == PaymentMethod.inStore && depositAmount > 0)
          'verified': verified,
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

/// Caparra minima in euro (sotto questa soglia non ha senso fare bonifico).
const double kDepositMinAmount = 0.50;
