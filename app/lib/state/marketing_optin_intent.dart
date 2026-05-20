/// Intercetta il parametro URL `?optin=marketing` (scansione QR negozio).
///
/// Quando un cliente scansiona il QR in negozio l'app si apre con
/// `https://silvestre-fotoservizi.web.app/?optin=marketing`. Vogliamo:
///  - Se l'utente NON è registrato in app → RegisterScreen pre-spunta
///    la box marketing
///  - Se l'utente è GIÀ registrato → AuthGate mostra un dialog
///    "Vuoi attivare le promozioni?" e aggiorna acceptedMarketing
///
/// Singleton statico per semplicità (un solo intent in fly).
/// Consume-once: dopo il primo utilizzo non si riapplica al riavvio.
class MarketingOptInIntent {
  static bool _pending = false;
  static bool _consumed = false;

  /// Da chiamare in main() prima di runApp(). Sicuro su tutte le piattaforme
  /// (Uri.base è sempre disponibile, su mobile sarà vuoto).
  static void detectFromUrl() {
    try {
      final params = Uri.base.queryParameters;
      if (params['optin'] == 'marketing') {
        _pending = true;
      }
    } catch (_) {
      // ignora qualsiasi errore di parsing URL
    }
  }

  /// True se l'intent è ancora da consumare.
  static bool peek() => _pending && !_consumed;

  /// Marca come consumato. Ritorna true se era effettivamente in pending.
  static bool consume() {
    if (_pending && !_consumed) {
      _consumed = true;
      return true;
    }
    return false;
  }

  /// Test helper.
  static void resetForTesting() {
    _pending = false;
    _consumed = false;
  }
}
