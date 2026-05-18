import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Termini di Servizio')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.warning),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: palette.warning),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'TESTO DI ESEMPIO — non valido legalmente. Da sostituire prima del rilascio.',
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _h(context, 'Oggetto'),
          _p(context,
              'Questi termini regolano l\'uso dell\'applicazione Silvestre Fotoservizi e '
              'la vendita di prodotti di stampa fotografica con ritiro in negozio.'),
          _h(context, 'Account'),
          _p(context,
              'Per usare l\'app devi avere almeno 14 anni e accettare questi termini '
              'e l\'informativa privacy.'),
          _h(context, 'Prodotti personalizzati e diritto di recesso'),
          _p(context,
              'I prodotti realizzati su tue specifiche (stampe foto, fotolibri, calendari, '
              'tele, magneti, gadget) sono ESCLUSI dal diritto di recesso di 14 giorni '
              '(art. 59 lett. c, D.Lgs. 206/2005 — Codice del Consumo). Una volta inviato '
              'l\'ordine non potrai più annullarlo.'),
          _h(context, 'Garanzia legale'),
          _p(context,
              'Resta valida la garanzia legale di conformità di 24 mesi su difetti di '
              'stampa, materiali o lavorazione. Contatta il negozio per esercitarla.'),
          _h(context, 'Caricamento foto'),
          _p(context,
              'Caricando foto dichiari di esserne proprietario o di avere il consenso '
              'delle persone ritratte. È vietato caricare contenuti che violino la legge '
              'o diritti di terzi. I contenuti pedopornografici saranno segnalati alle '
              'autorità.'),
          _h(context, 'Pagamento e ritiro'),
          _p(context,
              'Puoi pagare in negozio al ritiro oppure online (se attivo, tramite '
              'provider PCI-DSS certificato). Il ritiro avviene presso la sede di '
              'Frattamaggiore.'),
          _h(context, 'Limitazione di responsabilità'),
          _p(context,
              'Silvestre Fotoservizi non è responsabile per i contenuti delle foto '
              'caricate dagli utenti. La responsabilità è limitata al valore dell\'ordine.'),
          _h(context, 'Risoluzione delle controversie'),
          _p(context,
              'Per controversie puoi rivolgerti al negozio, oppure utilizzare la '
              'piattaforma ODR della Commissione Europea: '
              'ec.europa.eu/consumers/odr. Foro competente: Napoli Nord.'),
          _h(context, 'Modifiche'),
          _p(context,
              'I termini possono essere aggiornati. Sarai informato delle modifiche '
              'sostanziali e potrai accettarle o cancellare l\'account.'),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _h(BuildContext ctx, String t) {
    final p = Theme.of(ctx).extension<SilvestrePalette>()!;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        t,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: p.primary,
        ),
      ),
    );
  }

  Widget _p(BuildContext ctx, String t) {
    final p = Theme.of(ctx).extension<SilvestrePalette>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(t,
          style: TextStyle(color: p.textPrimary, fontSize: 14, height: 1.45)),
    );
  }
}
