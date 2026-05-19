import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SilvestrePalette>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Informativa Privacy')),
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
                    'TESTO DI ESEMPIO — non valido legalmente. Da sostituire con '
                    'la versione redatta da avvocato o servizio tipo Iubenda prima del rilascio.',
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
          _h(context, 'Titolare del trattamento'),
          _p(context,
              'Silvestre Fotoservizi S.a.s. — Via Vittorio Emanuele III, 205, '
              '80027 Frattamaggiore (NA). Email: fotosilvestre1970@gmail.com — '
              'Tel: +39 335 169 7903.'),
          _h(context, 'Dati raccolti'),
          _p(context,
              'Email, nome e cognome, telefono (opzionale), foto caricate per gli ordini, '
              'cronologia ordini, dati tecnici (IP, dispositivo).'),
          _h(context, 'Finalità del trattamento'),
          _p(context, 'I tuoi dati vengono trattati per:'),
          _bullet(context, 'Gestire la tua registrazione e l\'accesso al servizio.'),
          _bullet(context, 'Eseguire gli ordini di stampa e consegnarli in negozio.'),
          _bullet(context,
              'Inviare comunicazioni di servizio (conferma ordini, pronto per il ritiro).'),
          _bullet(context,
              'Inviarti offerte e novità SOLO se hai dato consenso marketing.'),
          _bullet(context,
              'Adempiere a obblighi fiscali e legali (fatturazione, contabilità).'),
          _h(context, 'Conservazione dei dati'),
          _p(context,
              'Foto caricate: cancellate automaticamente 30 giorni dopo il ritiro. '
              'Dati ordine: 10 anni per obblighi fiscali. Account: fino a richiesta '
              'di cancellazione.'),
          _h(context, 'I tuoi diritti (artt. 15-22 GDPR)'),
          _bullet(context, 'Accesso ai tuoi dati'),
          _bullet(context, 'Rettifica dei dati errati'),
          _bullet(context, 'Cancellazione (diritto all\'oblio)'),
          _bullet(context, 'Portabilità (esporta in JSON)'),
          _bullet(context, 'Limitazione e opposizione al trattamento'),
          _bullet(context, 'Revoca dei consensi prestati'),
          _bullet(context, 'Reclamo al Garante della Privacy (gpdp.it)'),
          _p(context,
              'Esercita i tuoi diritti scrivendo a fotosilvestre1970@gmail.com oppure '
              'usando le funzioni nella schermata Account dell\'app.'),
          _h(context, 'Destinatari dei dati'),
          _p(context,
              'I tuoi dati sono trattati internamente. Possono essere condivisi con: '
              'Google/Firebase (hosting, autenticazione, storage), provider di pagamento '
              '(Stripe, Satispay) se scegli il pagamento online. Tutti hanno DPA conformi '
              'al GDPR.'),
          _h(context, 'Trasferimento extra-UE'),
          _p(context,
              'Alcuni server Firebase si trovano negli USA. Il trasferimento avviene '
              'sulla base del Data Privacy Framework e di Standard Contractual Clauses.'),
          _h(context, 'Minori'),
          _p(context,
              'Il servizio è destinato a maggiori di 14 anni. Per i minori sotto i 14 '
              'anni serve consenso del genitore.'),
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

  Widget _bullet(BuildContext ctx, String t) {
    final p = Theme.of(ctx).extension<SilvestrePalette>()!;
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: TextStyle(color: p.primary)),
          Expanded(
            child: Text(t,
                style: TextStyle(
                    color: p.textPrimary, fontSize: 14, height: 1.45)),
          ),
        ],
      ),
    );
  }
}
