import 'package:flutter/widgets.dart';

/// Light-weight i18n: map-based lookup with IT default + EN.
/// Catalog descriptions stay IT (from CSV); only UI strings translated.

const _it = <String, String>{};

const _en = <String, String>{
  // Welcome / auth
  'Le tue foto, stampate con cura dal 1970.':
      'Your photos, printed with care since 1970.',
  'Accedi': 'Sign in',
  'Crea un account': 'Create account',
  'Crea il tuo account': 'Create your account',
  'Bentornato': 'Welcome back',
  'Email': 'Email',
  'Password': 'Password',
  'Telefono (obbligatorio)': 'Phone (required)',
  'Riceverai un messaggio WhatsApp quando l\'ordine sara\' pronto al ritiro.':
      'You will receive a WhatsApp message when your order is ready for pickup.',
  'Password dimenticata?': 'Forgot password?',
  'Esci': 'Sign out',
  'Non hai un account?': "Don't have an account?",
  'Registrati': 'Sign up',

  // Home / catalog
  'Cosa vuoi creare oggi?': 'What would you like to create today?',
  'Scegli un prodotto e parti dalle tue foto':
      'Pick a product and start from your photos',
  'Inizia ora': 'Get started',
  'Lavoro personalizzato': 'Custom job',
  'Non trovi quello che cerchi? Descrivilo a noi: ti rispondiamo con un preventivo su misura.':
      "Can't find what you're looking for? Describe it: we'll send you a custom quote.",

  // Product detail
  'Scegli il formato': 'Choose the format',
  'Quantità': 'Quantity',
  'Le tue foto': 'Your photos',
  'Componi il tuo fotolibro': 'Design your photobook',
  'Aggiungi': 'Add',
  'Indietro': 'Back',
  'Carica le foto da stampare/utilizzare per questo prodotto.':
      'Upload the photos you want printed/used for this product.',
  'Carica le foto da stampare. La quantità si imposta automaticamente al numero di foto (modificabile).':
      'Upload the photos to print. Quantity is auto-set to photo count (editable).',

  // Cart / orders
  'Il tuo carrello': 'Your cart',
  'Il carrello è vuoto': 'Your cart is empty',
  'Torna al catalogo e scegli i tuoi prodotti.':
      'Go back to catalog and pick your products.',
  'Nota per il negozio (opzionale)': 'Note for the shop (optional)',
  'Es. preferisco carta opaca, ritiro venerdì':
      'E.g. I prefer matte paper, pickup on Friday',
  'Ritiro in negozio': 'Pickup in store',
  'Invia ordine — Paga in negozio': 'Submit order — Pay in store',
  'Totale': 'Total',
  'Ordine inviato!': 'Order submitted!',
  'Il negozio ha ricevuto il tuo ordine. Pagamento e ritiro in negozio.':
      'The shop has received your order. Payment and pickup in store.',
  'Codice ritiro': 'Pickup code',
  'Trovi il dettaglio nella tab Ordini.':
      'Find the details in the Orders tab.',
  'Ho capito': 'Got it',

  // Navigation
  'Catalogo': 'Catalog',
  'Ordini': 'Orders',
  'Account': 'Account',
  'Carrello': 'Cart',

  // Account
  'Tema': 'Theme',
  'Cambia tema': 'Change theme',
  'Lingua': 'Language',
  'Italiano': 'Italian',
  'Inglese': 'English',

  // Operator
  'Dashboard': 'Dashboard',
  'Calendario': 'Calendar',
  'Impostazioni': 'Settings',
  'OPERATORE': 'OPERATOR',
  'Avvia lavorazione': 'Start production',
  'Segna come pronto per il ritiro': 'Mark as ready for pickup',
  'Cliente ha ritirato': 'Customer picked up',
  'Annulla ordine': 'Cancel order',
};

class _LocaleState extends ChangeNotifier {
  Locale _locale = const Locale('it');
  Locale get locale => _locale;

  void setLocale(Locale l) {
    if (_locale == l) return;
    _locale = l;
    notifyListeners();
  }

  void toggle() {
    _locale = _locale.languageCode == 'it'
        ? const Locale('en')
        : const Locale('it');
    notifyListeners();
  }
}

final localeState = _LocaleState();

/// Translate [key] to the active locale. Falls back to key (IT default).
String tr(String key) {
  if (localeState.locale.languageCode == 'en') {
    return _en[key] ?? key;
  }
  return _it[key] ?? key;
}
